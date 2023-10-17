use host::path::{concat, OwnedPath, Path, RefPath};
use host::runtime::{Runtime, RuntimeError, ValueType};
use primitive_types::{H160, H256, U256};
use anyhow::{Result, anyhow};
use evm::backend::Basic;

/// The size of one 256 bit word. Size in bytes
const WORD_SIZE: usize = 32_usize;

/// Path where Ethereum accounts are stored
const EVM_ACCOUNTS_PATH: RefPath = RefPath::assert_from(b"/eth_accounts");

/// Path where an account nonce is stored. This should be prefixed with the path to
/// where the account is stored for the world state or for the current transaction.
const NONCE_PATH: RefPath = RefPath::assert_from(b"/nonce");

/// Path where an account balance, ether held, is stored. This should be prefixed with the path to
/// where the account is stored for the world state or for the current transaction.
const BALANCE_PATH: RefPath = RefPath::assert_from(b"/balance");

/// "Internal" accounts - accounts with contract code have a contract code hash.
/// This value is computed when the code is stored and kept for future queries. This
/// path should be prefixed with the path to
/// where the account is stored for the world state or for the current transaction.
const CODE_HASH_PATH: RefPath = RefPath::assert_from(b"/code.hash");

/// "Internal" accounts - accounts with contract code, have their code stored here.
/// This
/// path should be prefixed with the path to
/// where the account is stored for the world state or for the current transaction.
const CODE_PATH: RefPath = RefPath::assert_from(b"/code");

/// The contracts of "internal" accounts have their own storage area. The account
/// location prefixed to this path gives the root path (prefix) to where such storage
/// values are kept. Each index in durable storage gives one complete path to one
/// such 256 bit integer value in storage.
const STORAGE_ROOT_PATH: RefPath = RefPath::assert_from(b"/storage");

fn path_concat(
    path1: &impl Path,
    path2: &impl Path,
) -> Result<OwnedPath> {
    concat(path1, path2).map_err(|err| anyhow!("Could not concat paths: {:?}", err))
}

/// Read a single unsigned 256 bit value from storage at the path given.
fn read_u256(
    host: &impl Runtime,
    path: &impl Path,
) -> Result<Option<U256>> {
    let bytes = host.store_read(path, 0, WORD_SIZE)?;

    if bytes.len() != WORD_SIZE {
        Ok(None)
    } else {
        Ok(Some(U256::from_little_endian(&bytes)))
    }
}

/// Read a single 256 bit hash from storage at the path given.
fn read_h256(
    host: &impl Runtime,
    path: &impl Path,
) -> Result<Option<H256>> {
    let bytes = host.store_read(path, 0, WORD_SIZE)?;

    if bytes.len() != WORD_SIZE {
        Ok(None)
    } else {
        Ok(Some(H256::from_slice(&bytes)))
    }
}

/// Get the path corresponding to an index of H256. This is used to
/// find the path to a value a contract stores in durable storage.
fn path_from_h256(index: &H256) -> Result<OwnedPath> {
    let path_string = alloc::format!("/{}", hex::encode(index.to_fixed_bytes()));
    OwnedPath::try_from(path_string).map_err(|err| anyhow!("path from h256 error: {:?}", err))
}

/// Turn an Ethereum address - a H160 - into a valid path
pub fn account_path(address: &H160) -> Result<OwnedPath> {
    let path_string = alloc::format!("/{}", hex::encode(address.to_fixed_bytes()));
    let path = OwnedPath::try_from(path_string).map_err(|err| anyhow!("account path error: {:?}", err))?;
    path_concat(&EVM_ACCOUNTS_PATH, &path).map_err(|err| anyhow!("Failed to concat paths for account: {:?}", err))
}

pub fn nonce(host: &impl Runtime, address: &H160) -> Result<U256> {
    let path = path_concat(&account_path(address)?, &NONCE_PATH)?;

    match host.store_read(&path, 0, WORD_SIZE) {
        Ok(bytes) => Ok(U256::from_little_endian(&bytes)),
        Err(RuntimeError::PathNotFound) => Ok(U256::zero()),
        Err(err) => Err(anyhow!("Error reading storage: {:?}", err)),
    }
}

pub fn set_nonce(host: &mut impl Runtime, address: &H160, new_nonce: &U256) -> Result<()> {
    let path = path_concat(&account_path(address)?, &NONCE_PATH)?;

    let mut new_value_bytes: [u8; WORD_SIZE] = [0; WORD_SIZE];
    new_nonce.to_little_endian(&mut new_value_bytes);

    host.store_write(&path, &new_value_bytes, 0)
        .map_err(|err| anyhow!("Failed to write nonce bytes: {:?}", err))
}

pub fn balance(host: &impl Runtime, address: &H160) -> Result<U256> {
    let path = path_concat(&account_path(address)?, &BALANCE_PATH)?;

    match host.store_read(&path, 0, WORD_SIZE) {
        Ok(bytes) => Ok(U256::from_little_endian(&bytes)),
        Err(RuntimeError::PathNotFound) => Ok(U256::zero()),
        Err(err) => Err(anyhow!("Error reading storage: {:?}", err)),
    }
}

pub fn account_exists(host: &impl Runtime, address: &H160) -> Result<bool> {
    let path = account_path(address)?;

    if let Some(_) = host.store_has(&path).map_err(|err| anyhow!("Error checking account existence: {:?}", err))? {
        Ok(true)
    } else {
        Ok(false)
    }
}

pub fn account_info(host: &impl Runtime, address: &H160) -> Result<Basic> {
    let nonce = nonce(host, address)?;
    let balance = balance(host, address)?;

    Ok(Basic {
        balance,
        nonce,
    })
}

pub fn set_balance(host: &mut impl Runtime, address: &H160, new_balance: &U256) -> Result<()> {
    let path = path_concat(&account_path(address)?, &BALANCE_PATH)?;

    let mut new_value_bytes: [u8; WORD_SIZE] = [0; WORD_SIZE];
    new_balance.to_little_endian(&mut new_value_bytes);

    host.store_write(&path, &new_value_bytes, 0)
        .map_err(|err| anyhow!("Failed to write balance bytes: {:?}", err))
}

fn storage_path(index: &H256) -> Result<OwnedPath> {
    let path_string = alloc::format!("/{}", hex::encode(index.to_fixed_bytes()));
    OwnedPath::try_from(path_string).map_err(|err| anyhow!("Error creating storage path: {:?}", err))
}

pub fn get_storage(host: &impl Runtime, address: &H160, index: &H256) -> Result<H256> {
    let path = path_concat(&account_path(address)?, &storage_path(index)?)?;

    match host.store_read(&path, 0, WORD_SIZE) {
        Ok(bytes) => Ok(H256::from_slice(&bytes)),
        Err(RuntimeError::PathNotFound) => Ok(H256::zero()),
        Err(err) => Err(anyhow!("Error reading storage: {:?}", err)),
    }
}

pub fn get_storage_opt(host: &impl Runtime, address: &H160, index: &H256) -> Result<Option<H256>> {
    let path = path_concat(&account_path(address)?, &storage_path(index)?)?;

    match host.store_read(&path, 0, WORD_SIZE) {
        Ok(bytes) => Ok(Some(H256::from_slice(&bytes))),
        Err(RuntimeError::PathNotFound) => Ok(None),
        Err(err) => Err(anyhow!("Error reading storage: {:?}", err)),
    }
}

pub fn set_storage(host: &mut impl Runtime, address: &H160, index: &H256, value: &H256) -> Result<()> {
    let path = path_concat(&account_path(address)?, &storage_path(index)?)?;

    let value_bytes = value.to_fixed_bytes();

    host.store_write(&path, &value_bytes, 0).map_err(|err| anyhow!("Failed to write to durable storage: {:?}", err))
}

pub fn get_code(host: &impl Runtime, address: &H160) -> Result<Vec<u8>> {
    let path = path_concat(&account_path(address)?, &CODE_PATH)?;

    match host.store_read_all(&path) {
        Ok(data) => Ok(data),
        Err(RuntimeError::PathNotFound) => Ok(vec![]),
        Err(err) => Err(anyhow!("Error reading code: {:?}", err)),
    }
}

pub fn set_code(host: &mut impl Runtime, address: &H160, code: &Vec<u8>) -> Result<()> {
    let path = path_concat(&account_path(address)?, &CODE_PATH)?;

    if let Some(ValueType::Value | ValueType::ValueWithSubtree) =
        host.store_has(&path)?
    {
        host.store_delete(&path).map_err(|err| anyhow!("Failed to delete code: {:?}", err))?
    }

    host.store_write_all(&path, code).map_err(|err| anyhow!("Failed to write code: {:?}", err))
}

pub fn delete_code(host: &mut impl Runtime, address: &H160) -> Result<()> {
    let path = path_concat(&account_path(address)?, &CODE_PATH)?;

    if let Some(ValueType::Value | ValueType::ValueWithSubtree) =
        host.store_has(&path)?
    {
        host.store_delete(&path).map_err(|err| anyhow!("Failed to delete code: {:?}", err))?
    }

    Ok(())
}
