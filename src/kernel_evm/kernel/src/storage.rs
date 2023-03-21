// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
//
// SPDX-License-Identifier: MIT
#![allow(dead_code)]

use host::path::*;
use host::rollup_core::RawRollupCore;
use host::runtime::{load_value_slice, Runtime, ValueType};

use std::str::from_utf8;

use crate::block::L2Block;
use crate::error::Error;
use tezos_ethereum::account::*;
use tezos_ethereum::eth_gen::{BlockHash, Hash, L2Level};
use tezos_ethereum::transaction::{TransactionHash, TransactionReceipt, TRANSACTION_HASH_SIZE};
use tezos_ethereum::wei::Wei;

use primitive_types::U256;

const SMART_ROLLUP_ADDRESS: RefPath = RefPath::assert_from(b"/metadata/smart_rollup_address");

const EVM_ACCOUNTS: RefPath = RefPath::assert_from(b"/eth_accounts");

const EVM_ACCOUNT_BALANCE: RefPath = RefPath::assert_from(b"/balance");
const EVM_ACCOUNT_NONCE: RefPath = RefPath::assert_from(b"/nonce");
const EVM_ACCOUNT_CODE_HASH: RefPath = RefPath::assert_from(b"/code_hash");

const EVM_CURRENT_BLOCK: RefPath = RefPath::assert_from(b"/evm/blocks/current");
const EVM_BLOCKS: RefPath = RefPath::assert_from(b"/evm/blocks");
const EVM_BLOCKS_NUMBER: RefPath = RefPath::assert_from(b"/number");
const EVM_BLOCKS_HASH: RefPath = RefPath::assert_from(b"/hash");
const EVM_BLOCKS_TRANSACTIONS: RefPath = RefPath::assert_from(b"/transactions");

const TRANSACTIONS_RECEIPTS: RefPath = RefPath::assert_from(b"/transactions_receipts");
const TRANSACTION_RECEIPT_HASH: RefPath = RefPath::assert_from(b"/hash");
const TRANSACTION_RECEIPT_INDEX: RefPath = RefPath::assert_from(b"/index");
const TRANSACTION_RECEIPT_BLOCK_HASH: RefPath = RefPath::assert_from(b"/block_hash");
const TRANSACTION_RECEIPT_BLOCK_NUMBER: RefPath = RefPath::assert_from(b"/block_number");
const TRANSACTION_RECEIPT_FROM: RefPath = RefPath::assert_from(b"/from");
const TRANSACTION_RECEIPT_TO: RefPath = RefPath::assert_from(b"/to");
const TRANSACTION_RECEIPT_TYPE: RefPath = RefPath::assert_from(b"/type");
const TRANSACTION_RECEIPT_STATUS: RefPath = RefPath::assert_from(b"/status");

const HASH_MAX_SIZE: usize = 32;

// We can read/store a maximum of [64] transaction hashes at once.
// TRANSACTION_HASH_SIZE * 64 = 2048.
const MAX_TRANSACTION_HASHES_AT_ONCE: usize = TRANSACTION_HASH_SIZE * 64;

// Arbitrary number of transaction per block, that can be adjusted later.
const MAX_TRANSACTION_NUMBER: usize = 256;

pub fn read_smart_rollup_address<Host: Runtime + RawRollupCore>(
    host: &mut Host,
) -> Result<[u8; 20], Error> {
    let mut buffer = [0u8; 20];

    match load_value_slice(host, &SMART_ROLLUP_ADDRESS, &mut buffer) {
        Ok(20) => Ok(buffer),
        _ => Err(Error::Generic),
    }
}

pub fn store_smart_rollup_address<Host: Runtime + RawRollupCore>(
    host: &mut Host,
    smart_rollup_address: &[u8; 20],
) -> Result<(), Error> {
    host.store_write(&SMART_ROLLUP_ADDRESS, smart_rollup_address, 0)
        .map_err(Error::from)
}

/// The size of one 256 bit word. Size in bytes
pub const WORD_SIZE: usize = 32usize;

/// Read a single unsigned 256 bit value from storage at the path given.
fn read_u256(host: &impl Runtime, path: &OwnedPath) -> Result<U256, Error> {
    let bytes = host.store_read(path, 0, WORD_SIZE).map_err(Error::from)?;
    Ok(Wei::from_little_endian(&bytes))
}

fn write_u256(host: &mut impl Runtime, path: &OwnedPath, value: U256) -> Result<(), Error> {
    let mut bytes: [u8; WORD_SIZE] = value.into();
    value.to_little_endian(&mut bytes);
    host.store_write(path, &bytes, 0).map_err(Error::from)
}

fn address_path(address: Hash) -> Result<OwnedPath, Error> {
    let address: &str = from_utf8(address)?;
    let address_path: Vec<u8> = format!("/{}", &address.to_ascii_lowercase()).into();
    OwnedPath::try_from(address_path).map_err(Error::from)
}

pub fn account_path(address: Hash) -> Result<OwnedPath, Error> {
    let address_hash = address_path(address)?;
    concat(&EVM_ACCOUNTS, &address_hash).map_err(Error::from)
}

pub fn block_path(number: L2Level) -> Result<OwnedPath, Error> {
    let number: &str = &number.to_string();
    let raw_number_path: Vec<u8> = format!("/{}", &number).into();
    let number_path = OwnedPath::try_from(raw_number_path).map_err(Error::from)?;
    concat(&EVM_BLOCKS, &number_path).map_err(Error::from)
}
fn receipt_path(receipt: &TransactionReceipt) -> Result<OwnedPath, Error> {
    let hash = hex::encode(receipt.hash);
    let raw_receipt_path: Vec<u8> = format!("/{}", &hash).into();
    let receipt_path = OwnedPath::try_from(raw_receipt_path).map_err(Error::from)?;
    concat(&TRANSACTIONS_RECEIPTS, &receipt_path).map_err(Error::from)
}

pub fn has_account<Host: Runtime>(
    host: &mut Host,
    account_path: &OwnedPath,
) -> Result<bool, Error> {
    match host.store_has(account_path).map_err(Error::from)? {
        Some(ValueType::Subtree | ValueType::ValueWithSubtree) => Ok(true),
        _ => Ok(false),
    }
}

pub fn read_account_nonce<Host: Runtime + RawRollupCore>(
    host: &mut Host,
    account_path: &OwnedPath,
) -> Result<u64, Error> {
    let path = concat(account_path, &EVM_ACCOUNT_NONCE)?;
    let mut buffer = [0_u8; 8];

    match load_value_slice(host, &path, &mut buffer) {
        Ok(8) => Ok(u64::from_le_bytes(buffer)),
        _ => Err(Error::Generic),
    }
}

pub fn read_account_balance<Host: Runtime + RawRollupCore>(
    host: &mut Host,
    account_path: &OwnedPath,
) -> Result<Wei, Error> {
    let path = concat(account_path, &EVM_ACCOUNT_BALANCE)?;
    read_u256(host, &path)
}

pub fn read_account_code_hash<Host: Runtime>(
    host: &mut Host,
    account_path: &OwnedPath,
) -> Result<Vec<u8>, Error> {
    let path = concat(account_path, &EVM_ACCOUNT_CODE_HASH)?;
    host.store_read(&path, 0, HASH_MAX_SIZE)
        .map_err(Error::from)
}

pub fn read_account<Host: Runtime + RawRollupCore>(
    host: &mut Host,
    address: Hash,
) -> Result<Account, Error> {
    let account_path = account_path(address)?;
    let nonce = read_account_nonce(host, &account_path)?;
    let balance = read_account_balance(host, &account_path)?;
    let code_hash = read_account_code_hash(host, &account_path)?;

    Ok(Account {
        nonce,
        balance,
        code_hash,
    })
}

pub fn store_nonce<Host: Runtime + RawRollupCore>(
    host: &mut Host,
    account_path: &OwnedPath,
    nonce: u64,
) -> Result<(), Error> {
    let path = concat(account_path, &EVM_ACCOUNT_NONCE)?;
    host.store_write(&path, &nonce.to_le_bytes(), 0)
        .map_err(Error::from)
}

pub fn store_balance<Host: Runtime + RawRollupCore>(
    host: &mut Host,
    account_path: &OwnedPath,
    balance: Wei,
) -> Result<(), Error> {
    let path = concat(account_path, &EVM_ACCOUNT_BALANCE)?;
    write_u256(host, &path, balance)
}

fn store_code_hash<Host: Runtime + RawRollupCore>(
    host: &mut Host,
    account_path: &OwnedPath,
    code_hash: Hash,
) -> Result<(), Error> {
    let path = concat(account_path, &EVM_ACCOUNT_CODE_HASH)?;
    host.store_write(&path, code_hash, 0).map_err(Error::from)
}

pub fn store_account<Host: Runtime + RawRollupCore>(
    host: &mut Host,
    account: &Account,
    account_path: &OwnedPath,
) -> Result<(), Error> {
    store_nonce(host, account_path, account.nonce)?;
    store_balance(host, account_path, account.balance)?;
    store_code_hash(host, account_path, &account.code_hash)
}

pub fn read_current_block_number<Host: Runtime + RawRollupCore>(
    host: &mut Host,
) -> Result<u64, Error> {
    let path = concat(&EVM_CURRENT_BLOCK, &EVM_BLOCKS_NUMBER)?;
    let mut buffer = [0_u8; 8];

    match load_value_slice(host, &path, &mut buffer) {
        Ok(8) => Ok(u64::from_le_bytes(buffer)),
        _ => Err(Error::Generic),
    }
}

fn read_chunked_value<Host: Runtime>(
    host: &mut Host,
    path: &OwnedPath,
    max_size: usize,
) -> Result<Vec<u8>, Error> {
    let length = usize::min(host.store_value_size(path)?, max_size);

    let mut buffer = Vec::new();
    let mut offset = 0;

    while offset < length {
        let mut bytes = host
            .store_read(path, offset, MAX_TRANSACTION_HASHES_AT_ONCE)
            .map_err(Error::from)?;

        offset += &bytes.len();
        buffer.append(&mut bytes);
    }
    Ok(buffer)
}

fn read_nth_block_transactions<Host: Runtime>(
    host: &mut Host,
    block_path: &OwnedPath,
) -> Result<Vec<TransactionHash>, Error> {
    let path = concat(block_path, &EVM_BLOCKS_TRANSACTIONS)?;

    let transactions_bytes =
        read_chunked_value(host, &path, MAX_TRANSACTION_NUMBER * TRANSACTION_HASH_SIZE)?;

    Ok(transactions_bytes
        .chunks(TRANSACTION_HASH_SIZE)
        .filter_map(|tx_hash_bytes: &[u8]| -> Option<TransactionHash> {
            tx_hash_bytes.try_into().ok()
        })
        .collect::<Vec<TransactionHash>>())
}

pub fn read_current_block<Host: Runtime + RawRollupCore>(
    host: &mut Host,
) -> Result<L2Block, Error> {
    let number = read_current_block_number(host)?;
    let block_path = block_path(number)?;
    let transactions = read_nth_block_transactions(host, &block_path)?;

    Ok(L2Block::new(number, transactions))
}

fn store_block_number<Host: Runtime + RawRollupCore>(
    host: &mut Host,
    block_path: &OwnedPath,
    block_number: L2Level,
) -> Result<(), Error> {
    let path = concat(block_path, &EVM_BLOCKS_NUMBER)?;
    host.store_write(&path, &u64::to_le_bytes(block_number), 0)
        .map_err(Error::from)
}

fn store_block_hash<Host: Runtime + RawRollupCore>(
    host: &mut Host,
    block_path: &OwnedPath,
    block_hash: &BlockHash,
) -> Result<(), Error> {
    let path = concat(block_path, &EVM_BLOCKS_HASH)?;
    host.store_write(&path, block_hash, 0).map_err(Error::from)
}

fn store_chunked_value<Host: Runtime>(
    host: &mut Host,
    path: &OwnedPath,
    value: &[u8],
    max_size: usize,
) -> Result<(), Error> {
    let length = usize::min(value.len(), max_size);

    let mut offset = 0;

    while offset < length {
        let limit = if offset + MAX_TRANSACTION_HASHES_AT_ONCE < length {
            offset + MAX_TRANSACTION_HASHES_AT_ONCE
        } else {
            length
        };

        let to_write = &value[offset..limit];

        host.store_write(path, to_write, offset)
            .map_err(Error::from)?;
        offset += limit;
    }
    Ok(())
}

fn store_block_transactions<Host: Runtime + RawRollupCore>(
    host: &mut Host,
    block_path: &OwnedPath,
    block_transactions: &[TransactionHash],
) -> Result<(), Error> {
    let path = concat(block_path, &EVM_BLOCKS_TRANSACTIONS)?;
    let block_transactions = &block_transactions.concat()[..];
    host.store_write(&path, block_transactions, 0)
        .map_err(Error::from)
}

fn store_block<Host: Runtime + RawRollupCore>(
    host: &mut Host,
    block: &L2Block,
    block_path: &OwnedPath,
) -> Result<(), Error> {
    store_block_number(host, block_path, block.number)?;
    store_block_hash(host, block_path, &block.hash)?;
    store_block_transactions(host, block_path, &block.transactions)
}

pub fn store_block_by_number<Host: Runtime + RawRollupCore>(
    host: &mut Host,
    block: &L2Block,
) -> Result<(), Error> {
    let block_path = block_path(block.number)?;
    store_block(host, block, &block_path)
}

pub fn store_current_block<Host: Runtime + RawRollupCore>(
    host: &mut Host,
    block: &L2Block,
) -> Result<(), Error> {
    let current_block_path = OwnedPath::from(EVM_CURRENT_BLOCK);
    // We only need to store current block's number so we avoid the storage of duplicate informations.
    store_block_number(host, &current_block_path, block.number)?;
    // When storing the current block's infos we need to store it under the [evm/blocks/<block_number>]
    store_block_by_number(host, block)
}

// TODO: This store a transaction receipt with multiple subkeys, it could
// be stored in a single encoded value. However, this is for now easier
// for the (OCaml) proxy server to do as is.
fn store_transaction_receipt<Host: Runtime + RawRollupCore>(
    receipt_path: &OwnedPath,
    host: &mut Host,
    receipt: &TransactionReceipt,
) -> Result<(), Error> {
    // Transaction hash
    let hash_path = concat(receipt_path, &TRANSACTION_RECEIPT_HASH)?;
    host.store_write(&hash_path, &receipt.hash, 0)
        .map_err(Error::from)?;
    // Index
    let index_path = concat(receipt_path, &TRANSACTION_RECEIPT_INDEX)?;
    host.store_write(&index_path, &receipt.index.to_le_bytes(), 0)
        .map_err(Error::from)?;
    // Block hash
    let block_hash_path = concat(receipt_path, &TRANSACTION_RECEIPT_BLOCK_HASH)?;
    host.store_write(&block_hash_path, &receipt.block_hash, 0)
        .map_err(Error::from)?;
    // Block number
    let block_number_path = concat(receipt_path, &TRANSACTION_RECEIPT_BLOCK_NUMBER)?;
    host.store_write(
        &block_number_path,
        &u64::to_le_bytes(receipt.block_number),
        0,
    )
    .map_err(Error::from)?;
    // From
    let from_path = concat(receipt_path, &TRANSACTION_RECEIPT_FROM)?;
    host.store_write(&from_path, &receipt.from, 0)
        .map_err(Error::from)?;
    // Type
    let type_path = concat(receipt_path, &TRANSACTION_RECEIPT_TYPE)?;
    host.store_write(&type_path, (&receipt.type_).into(), 0)?;
    // Status
    let status_path = concat(receipt_path, &TRANSACTION_RECEIPT_STATUS)?;
    host.store_write(&status_path, (&receipt.status).into(), 0)?;
    // To
    if let Some(to) = &receipt.to {
        let to_path = concat(receipt_path, &TRANSACTION_RECEIPT_TO)?;
        host.store_write(&to_path, to, 0)?;
    };

    Ok(())
}

pub fn store_transaction_receipts<Host: Runtime + RawRollupCore>(
    host: &mut Host,
    receipts: &[TransactionReceipt],
) -> Result<(), Error> {
    for receipt in receipts {
        let receipt_path = receipt_path(receipt)?;
        store_transaction_receipt(&receipt_path, host, receipt)?;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    use mock_runtime::host::MockHost;

    #[test]
    // Test a value bigger than 2048 can be stored
    fn test_store_and_read_big_value() {
        let mut host = MockHost::default();

        let mut value = [0u8; MAX_TRANSACTION_HASHES_AT_ONCE * 2];

        #[allow(clippy::needless_range_loop)]
        for i in 0..value.len() {
            value[i] = i as u8; // truncates the value
        }

        let path = OwnedPath::from(RefPath::assert_from(b"/big_value"));

        let max_size = MAX_TRANSACTION_HASHES_AT_ONCE * 4;

        match store_chunked_value(&mut host, &path, &value, max_size) {
            Ok(()) => (),
            Err(e) => panic!("Storing the value failed with {:?}", e),
        };

        match read_chunked_value(&mut host, &path, max_size) {
            Ok(read_value) => assert_eq!(read_value, value.to_vec()),
            Err(e) => panic!("Reading the value failed with {:?}", e),
        }
    }
}
