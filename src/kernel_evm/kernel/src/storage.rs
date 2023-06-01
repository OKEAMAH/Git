// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
// SPDX-FileCopyrightText: 2023 Functori <contact@functori.com>
//
// SPDX-License-Identifier: MIT
#![allow(dead_code)]

use hex::ToHex;
use tezos_smart_rollup_core::MAX_FILE_CHUNK_SIZE;
use tezos_smart_rollup_debug::debug_msg;
use tezos_smart_rollup_host::path::*;
use tezos_smart_rollup_host::runtime::{Runtime, ValueType};
use tezos_smart_rollup_storage::storage::Storage;

use crate::error::StorageCommitmentStatus::{Begin, Commit, Rollback};
use crate::error::StorageError::{StorageCommitment, StorageInitialisation};
use crate::error::StorageInitialisationError::{Base, EVMBlockInit, TxReceiptInit};
use crate::error::{Error, StorageError};
use evm_execution::account_storage::store_write_all;
use tezos_ethereum::block::L2Block;
use tezos_ethereum::transaction::{
    TransactionHash, TransactionObject, TransactionReceipt, TransactionStatus,
    TransactionType, TRANSACTION_HASH_SIZE,
};
use tezos_ethereum::wei::Wei;

use primitive_types::{H160, H256, U256};

const SMART_ROLLUP_ADDRESS: RefPath =
    RefPath::assert_from(b"/metadata/smart_rollup_address");

const EVM_STORAGE: RefPath = RefPath::assert_from(b"/evm");

const BLOCKS: RefPath = RefPath::assert_from(b"/blocks");
const CURRENT_BLOCK: RefPath = RefPath::assert_from(b"/blocks/current");
const BLOCKS_NUMBER: RefPath = RefPath::assert_from(b"/number");
const BLOCKS_HASH: RefPath = RefPath::assert_from(b"/hash");
const BLOCKS_TRANSACTIONS: RefPath = RefPath::assert_from(b"/transactions");

const TRANSACTIONS_RECEIPTS: RefPath = RefPath::assert_from(b"/transactions_receipts");
const TRANSACTION_RECEIPT_HASH: RefPath = RefPath::assert_from(b"/hash");
const TRANSACTION_RECEIPT_INDEX: RefPath = RefPath::assert_from(b"/index");
const TRANSACTION_RECEIPT_BLOCK_HASH: RefPath = RefPath::assert_from(b"/block_hash");
const TRANSACTION_RECEIPT_BLOCK_NUMBER: RefPath = RefPath::assert_from(b"/block_number");
const TRANSACTION_RECEIPT_FROM: RefPath = RefPath::assert_from(b"/from");
const TRANSACTION_RECEIPT_TO: RefPath = RefPath::assert_from(b"/to");
const TRANSACTION_RECEIPT_CONTRACT_ADDRESS: RefPath =
    RefPath::assert_from(b"/contract_address");
const TRANSACTION_CUMULATIVE_GAS_USED: RefPath =
    RefPath::assert_from(b"/cumulative_gas_used");
const TRANSACTION_RECEIPT_TYPE: RefPath = RefPath::assert_from(b"/type");
const TRANSACTION_RECEIPT_STATUS: RefPath = RefPath::assert_from(b"/status");

const EVM_TRANSACTIONS_OBJECTS: RefPath =
    RefPath::assert_from(b"/evm/transactions_objects");
const TRANSACTION_OBJECT_BLOCK_HASH: RefPath = RefPath::assert_from(b"/block_hash");
const TRANSACTION_OBJECT_BLOCK_NUMBER: RefPath = RefPath::assert_from(b"/block_number");
const TRANSACTION_OBJECT_FROM: RefPath = RefPath::assert_from(b"/from");
const TRANSACTION_OBJECT_GAS_USED: RefPath = RefPath::assert_from(b"/gas_used");
const TRANSACTION_OBJECT_GAS_PRICE: RefPath = RefPath::assert_from(b"/gas_price");
const TRANSACTION_OBJECT_HASH: RefPath = RefPath::assert_from(b"/hash");
const TRANSACTION_OBJECT_INPUT: RefPath = RefPath::assert_from(b"/input");
const TRANSACTION_OBJECT_NONCE: RefPath = RefPath::assert_from(b"/nonce");
const TRANSACTION_OBJECT_TO: RefPath = RefPath::assert_from(b"/to");
const TRANSACTION_OBJECT_INDEX: RefPath = RefPath::assert_from(b"/index");
const TRANSACTION_OBJECT_VALUE: RefPath = RefPath::assert_from(b"/value");
const TRANSACTION_OBJECT_V: RefPath = RefPath::assert_from(b"/v");
const TRANSACTION_OBJECT_R: RefPath = RefPath::assert_from(b"/r");
const TRANSACTION_OBJECT_S: RefPath = RefPath::assert_from(b"/s");

/// The size of an address. Size in bytes.
const ADDRESS_SIZE: usize = 20;
/// The size of a 256 bit hash. Size in bytes.
const HASH_MAX_SIZE: usize = 32;
/// The size of status. Size in bytes.
const TRANSACTION_RECEIPT_STATUS_SIZE: usize = 1;
/// The size of type of the transaction. Size in bytes.
const TRANSACTION_RECEIPT_TYPE_SIZE: usize = 1;
/// The size of one 256 bit word. Size in bytes
pub const WORD_SIZE: usize = 32usize;

// We can read/store at most [128] transaction hashes per block.
// TRANSACTION_HASH_SIZE * 128 = 4096.
const MAX_TRANSACTION_HASHES: usize = TRANSACTION_HASH_SIZE * 128;

// This function should be used when it makes sense that the value
// stored under [path] can be empty.
fn store_read_empty_safe<Host: Runtime>(
    host: &mut Host,
    path: &OwnedPath,
    offset: usize,
    max_bytes: usize,
) -> Result<Vec<u8>, Error> {
    let stored_value_size = host.store_value_size(path)?;

    if stored_value_size == 0 {
        Ok(vec![])
    } else {
        host.store_read(path, offset, max_bytes)
            .map_err(Error::from)
    }
}

fn store_read_slice<Host: Runtime, T: Path>(
    host: &mut Host,
    path: &T,
    buffer: &mut [u8],
    expected_size: usize,
) -> Result<(), Error> {
    let size = Runtime::store_read_slice(host, path, 0, buffer)?;
    if size == expected_size {
        Ok(())
    } else {
        Err(Error::Storage(StorageError::InvalidLoadValue {
            expected: expected_size,
            actual: size,
        }))
    }
}

pub fn read_smart_rollup_address<Host: Runtime>(
    host: &mut Host,
) -> Result<[u8; 20], Error> {
    let mut buffer = [0u8; 20];
    store_read_slice(host, &SMART_ROLLUP_ADDRESS, &mut buffer, 20)?;
    Ok(buffer)
}

pub fn store_smart_rollup_address<Host: Runtime>(
    host: &mut Host,
    smart_rollup_address: &[u8; 20],
) -> Result<(), Error> {
    host.store_write(&SMART_ROLLUP_ADDRESS, smart_rollup_address, 0)
        .map_err(Error::from)
}

/// Read a single unsigned 256 bit value from storage at the path given.
fn read_u256(host: &impl Runtime, path: &OwnedPath) -> Result<U256, Error> {
    let bytes = host.store_read(path, 0, WORD_SIZE)?;
    Ok(Wei::from_little_endian(&bytes))
}

/// Read a single address value from storage at the path given.
fn read_address(host: &impl Runtime, path: &OwnedPath) -> Result<H160, Error> {
    let bytes = host.store_read(path, 0, ADDRESS_SIZE)?;
    Ok(H160::from_slice(&bytes))
}

fn write_u256(
    host: &mut impl Runtime,
    path: &OwnedPath,
    value: U256,
) -> Result<(), Error> {
    let mut bytes: [u8; WORD_SIZE] = value.into();
    value.to_little_endian(&mut bytes);
    host.store_write(path, &bytes, 0).map_err(Error::from)
}

pub fn object_path(object_hash: &TransactionHash) -> Result<OwnedPath, Error> {
    let hash = hex::encode(object_hash);
    let raw_object_path: Vec<u8> = format!("/{}", &hash).into();
    let object_path = OwnedPath::try_from(raw_object_path)?;
    concat(&EVM_TRANSACTIONS_OBJECTS, &object_path).map_err(Error::from)
}

// WrappedStorage for SDK's storage to make all the transactional storage
// benefit from begin/commit/rollback mechanism
pub struct WStorage<T: From<OwnedPath>>(Storage<T>);

impl<T: From<OwnedPath>> WStorage<T> {
    pub fn begin(&mut self, host: &mut impl Runtime) -> Result<(), Error> {
        self.0
            .begin_transaction(host)
            .map_err(|e| Error::Storage(StorageCommitment(Begin(e))))
    }

    pub fn commit(&mut self, host: &mut impl Runtime) -> Result<(), Error> {
        self.0
            .commit_transaction(host)
            .map_err(|e| Error::Storage(StorageCommitment(Commit(e))))
    }

    pub fn rollback(&mut self, host: &mut impl Runtime) -> Result<(), Error> {
        self.0
            .rollback_transaction(host)
            .map_err(|e| Error::Storage(StorageCommitment(Rollback(e))))
    }
}

pub struct EVM {
    pub path: OwnedPath,
}

impl From<OwnedPath> for EVM {
    fn from(path: OwnedPath) -> Self {
        Self { path }
    }
}

impl EVM {
    // ======================== L2Block ======================== //

    fn read_l2block_transactions<Host: Runtime>(
        &mut self,
        host: &mut Host,
    ) -> Result<Vec<TransactionHash>, Error> {
        let path = concat(&self.path, &BLOCKS_TRANSACTIONS)?;

        let transactions_bytes =
            store_read_empty_safe(host, &path, 0, MAX_TRANSACTION_HASHES)?;

        Ok(transactions_bytes
            .chunks(TRANSACTION_HASH_SIZE)
            .filter_map(|tx_hash_bytes: &[u8]| -> Option<TransactionHash> {
                tx_hash_bytes.try_into().ok()
            })
            .collect::<Vec<TransactionHash>>())
    }

    pub fn read_l2block_number<Host: Runtime>(
        &mut self,
        host: &mut Host,
    ) -> Result<U256, Error> {
        let path = concat(&self.path, &BLOCKS_NUMBER)?;
        let mut buffer = [0_u8; 8];
        store_read_slice(host, &path, &mut buffer, 8)?;
        Ok(U256::from_little_endian(&buffer))
    }

    fn read_l2block_nodebug<Host: Runtime>(
        &mut self,
        host: &mut Host,
    ) -> Result<L2Block, Error> {
        let number = self.read_l2block_number(host)?;
        let transactions = self.read_l2block_transactions(host)?;

        Ok(L2Block::new(number, transactions))
    }

    pub fn read_l2block<Host: Runtime>(
        &mut self,
        host: &mut Host,
    ) -> Result<L2Block, Error> {
        match self.read_l2block_nodebug(host) {
            Ok(block) => {
                debug_msg!(
                    host,
                    "Reading block {} at number {} containing {} transaction(s).\n",
                    block.hash.as_bytes().encode_hex::<String>(),
                    block.number,
                    block.transactions.len()
                );

                Ok(block)
            }
            Err(e) => {
                debug_msg!(
                    host,
                    "Block reading failed for path {:?} because {:?}\n",
                    self.path,
                    e
                );
                Err(e)
            }
        }
    }

    fn store_l2block_number<Host: Runtime>(
        &mut self,
        host: &mut Host,
        block_number: &U256,
    ) -> Result<(), Error> {
        let path = concat(&self.path, &BLOCKS_NUMBER)?;
        let mut le_block_number: [u8; 32] = [0; 32];
        block_number.to_little_endian(&mut le_block_number);
        host.store_write(&path, &le_block_number, 0)
            .map_err(Error::from)
    }

    fn store_l2block_hash<Host: Runtime>(
        &mut self,
        host: &mut Host,
        block_hash: &H256,
    ) -> Result<(), Error> {
        let path = concat(&self.path, &BLOCKS_HASH)?;
        host.store_write(&path, block_hash.as_bytes(), 0)
            .map_err(Error::from)
    }

    fn store_l2block_transactions<Host: Runtime>(
        &mut self,
        host: &mut Host,
        block_transactions: &[TransactionHash],
    ) -> Result<(), Error> {
        let path = concat(&self.path, &BLOCKS_TRANSACTIONS)?;
        let block_transactions = &block_transactions.concat()[..];
        // TODO: use `store_write_all` when available
        host.store_write(&path, block_transactions, 0)
            .map_err(Error::from)
    }

    fn store_l2block_nodebug<Host: Runtime>(
        &mut self,
        host: &mut Host,
        block: &L2Block,
    ) -> Result<(), Error> {
        self.store_l2block_number(host, &block.number)?;
        self.store_l2block_hash(host, &block.hash)?;
        self.store_l2block_transactions(host, &block.transactions)
    }

    pub fn store_l2block<Host: Runtime>(
        &mut self,
        host: &mut Host,
        block: &L2Block,
    ) -> Result<(), Error> {
        match self.store_l2block_nodebug(host, block) {
            Ok(()) => {
                debug_msg!(
                    host,
                    "Storing block {} at number {} containing {} transaction(s).\n",
                    block.hash.as_bytes().encode_hex::<String>(),
                    block.number,
                    block.transactions.len()
                );
                Ok(())
            }
            Err(e) => {
                debug_msg!(host, "Block storing failed: {:?}\n", e);
                Err(e)
            }
        }
    }

    // ======================== TxReceipt ======================== //

    // TODO: This store a transaction receipt with multiple subkeys, it could
    // be stored in a single encoded value. However, this is for now easier
    // for the (OCaml) proxy server to do as is.
    pub fn store_tx_receipt<Host: Runtime>(
        &mut self,
        host: &mut Host,
        receipt: &TransactionReceipt,
    ) -> Result<(), Error> {
        // Transaction hash
        let hash_path = concat(&self.path, &TRANSACTION_RECEIPT_HASH)?;
        host.store_write(&hash_path, &receipt.hash, 0)?;
        // Index
        let index_path = concat(&self.path, &TRANSACTION_RECEIPT_INDEX)?;
        host.store_write(&index_path, &receipt.index.to_le_bytes(), 0)?;
        // Block hash
        let block_hash_path = concat(&self.path, &TRANSACTION_RECEIPT_BLOCK_HASH)?;
        host.store_write(&block_hash_path, receipt.block_hash.as_bytes(), 0)?;
        // Block number
        let block_number_path = concat(&self.path, &TRANSACTION_RECEIPT_BLOCK_NUMBER)?;
        let mut le_receipt_block_number: [u8; 32] = [0; 32];
        receipt
            .block_number
            .to_little_endian(&mut le_receipt_block_number);
        host.store_write(&block_number_path, &le_receipt_block_number, 0)?;
        // From
        let from_path = concat(&self.path, &TRANSACTION_RECEIPT_FROM)?;
        let from: H160 = receipt.from;
        host.store_write(&from_path, from.as_bytes(), 0)?;
        // Type
        let type_path = concat(&self.path, &TRANSACTION_RECEIPT_TYPE)?;
        host.store_write(&type_path, (&receipt.type_).into(), 0)?;
        // Status
        let status_path = concat(&self.path, &TRANSACTION_RECEIPT_STATUS)?;
        host.store_write(&status_path, (&receipt.status).into(), 0)?;
        // To
        if let Some(to) = receipt.to {
            let to_path = concat(&self.path, &TRANSACTION_RECEIPT_TO)?;
            host.store_write(&to_path, to.as_bytes(), 0)?;
        };
        // Contract address
        if let Some(contract_address) = receipt.contract_address {
            let contract_address_path =
                concat(&self.path, &TRANSACTION_RECEIPT_CONTRACT_ADDRESS)?;
            host.store_write(&contract_address_path, contract_address.as_bytes(), 0)?;
        };
        // Cumulative gas used
        let cumulative_gas_used_path =
            concat(&self.path, &TRANSACTION_CUMULATIVE_GAS_USED)?;
        let mut le_receipt_cumulative_gas_used: [u8; 32] = [0; 32];
        receipt
            .cumulative_gas_used
            .to_little_endian(&mut le_receipt_cumulative_gas_used);
        host.store_write(
            &cumulative_gas_used_path,
            &le_receipt_cumulative_gas_used,
            0,
        )?;

        Ok(())
    }

    pub fn read_tx_receipt<Host: Runtime>(
        &mut self,
        host: &mut Host,
        tx_hash: &TransactionHash,
    ) -> Result<TransactionReceipt, Error> {
        let index_path = concat(&self.path, &TRANSACTION_RECEIPT_INDEX)?;
        let index_raw = host.store_read(&index_path, 0, WORD_SIZE)?;
        let index = u32::from_le_bytes(
            index_raw.try_into().map_err(|_| Error::InvalidConversion)?,
        );

        let block_hash_path = concat(&self.path, &TRANSACTION_RECEIPT_BLOCK_HASH)?;
        let block_hash_raw = host.store_read(&block_hash_path, 0, HASH_MAX_SIZE)?;
        let block_hash = H256::from_slice(block_hash_raw.as_slice());

        let block_number_path = concat(&self.path, &TRANSACTION_RECEIPT_BLOCK_NUMBER)?;
        let block_number = read_u256(host, &block_number_path)?;

        let from_path = concat(&self.path, &TRANSACTION_RECEIPT_FROM)?;
        let from = read_address(host, &from_path)?;

        let cumulative_gas_used_path =
            concat(&self.path, &TRANSACTION_CUMULATIVE_GAS_USED)?;
        let cumulative_gas_used = read_u256(host, &cumulative_gas_used_path)?;

        let type_path = concat(&self.path, &TRANSACTION_RECEIPT_TYPE)?;
        let type_raw = host.store_read(&type_path, 0, TRANSACTION_RECEIPT_TYPE_SIZE)?;
        let type_ = TransactionType::try_from(&type_raw).map_err(|_| {
            Error::Storage(StorageError::InvalidEncoding {
                path: type_path,
                value: type_raw,
            })
        })?;

        let status_path = concat(&self.path, &TRANSACTION_RECEIPT_STATUS)?;
        let raw_status =
            host.store_read(&status_path, 0, TRANSACTION_RECEIPT_STATUS_SIZE)?;
        let status = TransactionStatus::try_from(&raw_status).map_err(|_| {
            Error::Storage(StorageError::InvalidEncoding {
                path: status_path,
                value: raw_status,
            })
        })?;

        // To can be None
        let to_path = concat(&self.path, &TRANSACTION_RECEIPT_TO)?;
        let to = if let Ok(Some(_)) = host.store_has(&to_path) {
            Some(read_address(host, &to_path)?)
        } else {
            None
        };

        // Contract address can be None
        let contract_address_path =
            concat(&self.path, &TRANSACTION_RECEIPT_CONTRACT_ADDRESS)?;
        let contract_address: Option<H160> = if let Ok(Some(_)) =
            host.store_has(&contract_address_path)
        {
            let address_raw = host.store_read(&contract_address_path, 0, ADDRESS_SIZE)?;
            Some(H160::from_slice(&address_raw))
        } else {
            None
        };

        Ok(TransactionReceipt {
            hash: *tx_hash,
            index,
            block_hash,
            block_number,
            from,
            to,
            cumulative_gas_used,
            effective_gas_price: U256::zero(),
            gas_used: U256::zero(),
            contract_address,
            type_,
            status,
        })
    }

    pub fn read_tx_receipt_status<Host: Runtime>(
        &mut self,
        host: &mut Host,
    ) -> Result<TransactionStatus, Error> {
        let status_path = concat(&self.path, &TRANSACTION_RECEIPT_STATUS)?;
        let raw_status = host
            .store_read(&status_path, 0, TRANSACTION_RECEIPT_STATUS_SIZE)
            .map_err(Error::from)?;
        TransactionStatus::try_from(&raw_status).map_err(|_| {
            Error::Storage(StorageError::InvalidEncoding {
                path: status_path,
                value: raw_status,
            })
        })
    }

    pub fn read_tx_receipt_cumulative_gas_used<Host: Runtime>(
        &mut self,
        host: &mut Host,
    ) -> Result<U256, Error> {
        let cumulative_gas_used_path =
            concat(&self.path, &TRANSACTION_CUMULATIVE_GAS_USED)?;
        read_u256(host, &cumulative_gas_used_path)
    }
}

pub struct EVMStorage {
    pub storage: WStorage<EVM>,
}

pub fn init_evm_storage() -> Result<EVMStorage, Error> {
    let storage = WStorage(
        Storage::<EVM>::init(&EVM_STORAGE)
            .map_err(|e| Error::Storage(StorageInitialisation(Base(e))))?,
    );
    Ok(EVMStorage { storage })
}

impl EVMStorage {
    pub fn block(&mut self, host: &mut impl Runtime, path: &U256) -> Result<EVM, Error> {
        let raw_number_path: Vec<u8> = format!("/{}", path).into();
        let number_path = OwnedPath::try_from(raw_number_path)?;
        let path = concat(&BLOCKS, &number_path).map_err(Error::from)?;
        self.storage
            .0
            .get_or_create(host, &path)
            .map_err(|e| Error::Storage(StorageInitialisation(EVMBlockInit(e))))
    }

    fn current_block_number(&mut self, host: &mut impl Runtime) -> Result<U256, Error> {
        let mut current_evm_block = self
            .storage
            .0
            .get_or_create(host, &CURRENT_BLOCK)
            .map_err(|e| Error::Storage(StorageInitialisation(EVMBlockInit(e))))?;

        current_evm_block.read_l2block_number(host)
    }

    pub fn current_block(&mut self, host: &mut impl Runtime) -> Result<EVM, Error> {
        let current_block_number = self.current_block_number(host)?;
        self.block(host, &current_block_number)
    }

    // Note that this function is here to help for an optimisation on storing
    // the current block. As information of the current block needs to be stored
    // under </block_number> path as well, it makes sense to only store the block
    // number under </current>'s path and everything under </block_number>'s one at
    // some point, i.e we don't need to duplicate the information in durable storage.
    //
    // NB: If something wrong happens at some point during all this process this side
    // effect will be rollbacked.
    pub fn set_and_get_current_block(
        &mut self,
        host: &mut impl Runtime,
        block_number: &U256,
    ) -> Result<EVM, Error> {
        let mut evm_block = self
            .storage
            .0
            .get_or_create(host, &CURRENT_BLOCK)
            .map_err(|e| Error::Storage(StorageInitialisation(EVMBlockInit(e))))?;

        evm_block.store_l2block_number(host, block_number)?;

        self.block(host, block_number)
    }

    pub fn tx_receipt(
        &mut self,
        host: &mut impl Runtime,
        path: &TransactionHash,
    ) -> Result<EVM, Error> {
        let hash = hex::encode(path);
        let raw_hash_path: Vec<u8> = format!("/{}", hash).into();
        let hash_path = OwnedPath::try_from(raw_hash_path)?;
        let path = concat(&TRANSACTIONS_RECEIPTS, &hash_path).map_err(Error::from)?;

        self.storage
            .0
            .get_or_create(host, &path)
            .map_err(|e| Error::Storage(StorageInitialisation(TxReceiptInit(e))))
    }
}

pub fn store_transaction_object<Host: Runtime>(
    object_path: &OwnedPath,
    host: &mut Host,
    block_hash: H256,
    block_number: U256,
    object: &TransactionObject,
) -> Result<(), Error> {
    // Block hash
    let block_hash_path = concat(object_path, &TRANSACTION_OBJECT_BLOCK_HASH)?;
    host.store_write(&block_hash_path, block_hash.as_bytes(), 0)?;
    // Block number
    let block_number_path = concat(object_path, &TRANSACTION_OBJECT_BLOCK_NUMBER)?;
    write_u256(host, &block_number_path, block_number)?;
    // From
    let from_path = concat(object_path, &TRANSACTION_OBJECT_FROM)?;
    host.store_write(&from_path, object.from.as_bytes(), 0)?;
    // Gas used
    let gas_used_path = concat(object_path, &TRANSACTION_OBJECT_GAS_USED)?;
    write_u256(host, &gas_used_path, object.gas_used)?;
    // Gas price
    let gas_price_path = concat(object_path, &TRANSACTION_OBJECT_GAS_PRICE)?;
    write_u256(host, &gas_price_path, object.gas_price)?;
    // Input
    let input_path = concat(object_path, &TRANSACTION_OBJECT_INPUT)?;
    store_write_all(host, &input_path, &object.input)?;
    // Nonce
    let nonce_path = concat(object_path, &TRANSACTION_OBJECT_NONCE)?;
    write_u256(host, &nonce_path, object.nonce)?;
    // To
    if let Some(to) = object.to {
        let to_path = concat(object_path, &TRANSACTION_OBJECT_TO)?;
        host.store_write(&to_path, to.as_bytes(), 0)?;
    };
    // Index
    let index_path = concat(object_path, &TRANSACTION_OBJECT_INDEX)?;
    host.store_write(&index_path, &object.index.to_le_bytes(), 0)?;
    // Value
    let value_path = concat(object_path, &TRANSACTION_OBJECT_VALUE)?;
    write_u256(host, &value_path, object.value)?;
    // V
    let v_path = concat(object_path, &TRANSACTION_OBJECT_V)?;
    write_u256(host, &v_path, object.v)?;
    // R
    let r_path = concat(object_path, &TRANSACTION_OBJECT_R)?;
    host.store_write(&r_path, object.r.as_bytes(), 0)?;
    // S
    let s_path = concat(object_path, &TRANSACTION_OBJECT_S)?;
    host.store_write(&s_path, object.s.as_bytes(), 0)?;

    Ok(())
}

pub fn store_transaction_objects<Host: Runtime>(
    host: &mut Host,
    block: &L2Block,
    objects: &[TransactionObject],
) -> Result<(), Error> {
    for object in objects {
        let object_path = object_path(&object.hash)?;
        store_transaction_object(&object_path, host, block.hash, block.number, object)?;
    }
    Ok(())
}

const CHUNKED_TRANSACTIONS: RefPath = RefPath::assert_from(b"/chunked_transactions");
const CHUNKED_TRANSACTION_NUM_CHUNKS: RefPath = RefPath::assert_from(b"/num_chunks");

fn chunked_transaction_path(tx_hash: &TransactionHash) -> Result<OwnedPath, Error> {
    let hash = hex::encode(tx_hash);
    let raw_chunked_transaction_path: Vec<u8> = format!("/{}", hash).into();
    let chunked_transaction_path = OwnedPath::try_from(raw_chunked_transaction_path)?;
    concat(&CHUNKED_TRANSACTIONS, &chunked_transaction_path).map_err(Error::from)
}

fn chunked_transaction_num_chunks_path(
    chunked_transaction_path: &OwnedPath,
) -> Result<OwnedPath, Error> {
    concat(chunked_transaction_path, &CHUNKED_TRANSACTION_NUM_CHUNKS).map_err(Error::from)
}

fn transaction_chunk_path(
    chunked_transaction_path: &OwnedPath,
    i: u16,
) -> Result<OwnedPath, Error> {
    let raw_i_path: Vec<u8> = format!("/{}", i).into();
    let i_path = OwnedPath::try_from(raw_i_path)?;
    concat(chunked_transaction_path, &i_path).map_err(Error::from)
}

fn is_transaction_complete<Host: Runtime>(
    host: &mut Host,
    chunked_transaction_path: &OwnedPath,
    num_chunks: u16,
) -> Result<bool, Error> {
    let n_subkeys = host.store_count_subkeys(chunked_transaction_path)? as u16;
    // `n_subkeys` includes the key `num_chunks`. The transaction is complete if
    // number of chunks = num_chunks - 1, the last chunk is not written on disk
    // and is kept in memory instead.
    Ok(n_subkeys >= num_chunks)
}

fn chunked_transaction_num_chunks_by_path<Host: Runtime>(
    host: &mut Host,
    chunked_transaction_path: &OwnedPath,
) -> Result<u16, Error> {
    let chunked_transaction_num_chunks_path =
        chunked_transaction_num_chunks_path(chunked_transaction_path)?;
    let mut buffer = [0u8; 2];
    store_read_slice(host, &chunked_transaction_num_chunks_path, &mut buffer, 2)?;
    Ok(u16::from_le_bytes(buffer))
}

pub fn chunked_transaction_num_chunks<Host: Runtime>(
    host: &mut Host,
    tx_hash: &TransactionHash,
) -> Result<u16, Error> {
    let chunked_transaction_path = chunked_transaction_path(tx_hash)?;
    chunked_transaction_num_chunks_by_path(host, &chunked_transaction_path)
}

fn store_transaction_chunk_data<Host: Runtime>(
    host: &mut Host,
    transaction_chunk_path: &OwnedPath,
    data: Vec<u8>,
) -> Result<(), Error> {
    match host.store_has(transaction_chunk_path)? {
        Some(ValueType::Value | ValueType::ValueWithSubtree) => Ok(()),
        _ => {
            if data.len() > MAX_FILE_CHUNK_SIZE {
                // It comes from an input so it's maximum 4096 bytes (with the message header).
                let (data1, data2) = data.split_at(MAX_FILE_CHUNK_SIZE);
                host.store_write(transaction_chunk_path, data1, 0)?;
                host.store_write(transaction_chunk_path, data2, MAX_FILE_CHUNK_SIZE)
            } else {
                host.store_write(transaction_chunk_path, &data, 0)
            }?;
            Ok(())
        }
    }
}

fn read_transaction_chunk_data<Host: Runtime>(
    host: &mut Host,
    transaction_chunk_path: &OwnedPath,
) -> Result<Vec<u8>, Error> {
    let data_size = host.store_value_size(transaction_chunk_path)?;

    if data_size > MAX_FILE_CHUNK_SIZE {
        let mut data1 =
            host.store_read(transaction_chunk_path, 0, MAX_FILE_CHUNK_SIZE)?;
        let mut data2 = host.store_read(
            transaction_chunk_path,
            MAX_FILE_CHUNK_SIZE,
            MAX_FILE_CHUNK_SIZE,
        )?;
        let _ = &mut data1.append(&mut data2);
        Ok(data1)
    } else {
        Ok(host.store_read(transaction_chunk_path, 0, MAX_FILE_CHUNK_SIZE)?)
    }
}

fn get_full_transaction<Host: Runtime>(
    host: &mut Host,
    chunked_transaction_path: &OwnedPath,
    num_chunks: u16,
    missing_data: &[u8],
) -> Result<Vec<u8>, Error> {
    let mut buffer = Vec::new();
    for i in 0..num_chunks {
        let transaction_chunk_path = transaction_chunk_path(chunked_transaction_path, i)?;
        // If the transaction is complete and a chunk doesn't exist, it means that it is
        // the last missing chunk, that was not stored in the storage.
        match host.store_has(&transaction_chunk_path)? {
            None => buffer.extend_from_slice(missing_data),
            Some(_) => {
                let mut data =
                    read_transaction_chunk_data(host, &transaction_chunk_path)?;
                let _ = &mut buffer.append(&mut data);
            }
        }
    }
    Ok(buffer)
}

pub fn remove_chunked_transaction_by_path<Host: Runtime>(
    host: &mut Host,
    path: &OwnedPath,
) -> Result<(), Error> {
    host.store_delete(path).map_err(Error::from)
}

pub fn remove_chunked_transaction<Host: Runtime>(
    host: &mut Host,
    tx_hash: &TransactionHash,
) -> Result<(), Error> {
    let chunked_transaction_path = chunked_transaction_path(tx_hash)?;
    remove_chunked_transaction_by_path(host, &chunked_transaction_path)
}

/// Store the transaction chunk in the storage. Returns the full transaction
/// if the last chunk to store is the last missing chunk.
pub fn store_transaction_chunk<Host: Runtime>(
    host: &mut Host,
    tx_hash: &TransactionHash,
    i: u16,
    data: Vec<u8>,
) -> Result<Option<Vec<u8>>, Error> {
    let chunked_transaction_path = chunked_transaction_path(tx_hash)?;
    let num_chunks =
        chunked_transaction_num_chunks_by_path(host, &chunked_transaction_path)?;

    if is_transaction_complete(host, &chunked_transaction_path, num_chunks)? {
        let data =
            get_full_transaction(host, &chunked_transaction_path, num_chunks, &data)?;
        host.store_delete(&chunked_transaction_path)?;
        Ok(Some(data))
    } else {
        let transaction_chunk_path =
            transaction_chunk_path(&chunked_transaction_path, i)?;
        store_transaction_chunk_data(host, &transaction_chunk_path, data)?;

        Ok(None)
    }
}

pub fn create_chunked_transaction<Host: Runtime>(
    host: &mut Host,
    tx_hash: &TransactionHash,
    num_chunks: u16,
) -> Result<(), Error> {
    let chunked_transaction_path = chunked_transaction_path(tx_hash)?;
    let chunked_transaction_num_chunks_path =
        chunked_transaction_num_chunks_path(&chunked_transaction_path)?;
    host.store_write(
        &chunked_transaction_num_chunks_path,
        &u16::to_le_bytes(num_chunks),
        0,
    )
    .map_err(Error::from)
}
