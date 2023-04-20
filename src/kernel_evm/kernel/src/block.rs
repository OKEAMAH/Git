// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
//
// SPDX-License-Identifier: MIT

use crate::blueprint::Queue;
use crate::error::Error;
use crate::helpers::address_to_hash;
use crate::inbox::Transaction;
use crate::storage;
use tezos_ethereum::address::EthereumAddress;
use tezos_ethereum::signatures::EthereumTransactionCommon;
use tezos_smart_rollup_host::path::OwnedPath;
use tezos_smart_rollup_host::runtime::Runtime;

use primitive_types::U256;
use tezos_ethereum::account::Account;
use tezos_ethereum::eth_gen::{BlockHash, L2Level, OwnedHash, BLOCK_HASH_SIZE};
use tezos_ethereum::transaction::{
    TransactionHash, TransactionReceipt, TransactionStatus, TransactionType,
};

use tezos_ethereum::wei::Wei;

pub struct L2Block {
    // This choice of a L2 block representation is totally
    // arbitrarily based on what is an Ethereum block and is
    // subject to change.
    pub number: L2Level,
    pub hash: BlockHash,
    pub parent_hash: BlockHash,
    pub nonce: U256,
    pub sha3_uncles: OwnedHash,
    pub logs_bloom: Option<OwnedHash>,
    pub transactions_root: OwnedHash,
    pub state_root: OwnedHash,
    pub receipts_root: OwnedHash,
    pub miner: OwnedHash,
    pub difficulty: U256,
    pub total_difficulty: U256,
    pub extra_data: OwnedHash,
    pub size: U256,
    pub gas_limit: U256,
    pub gas_used: U256,
    pub timestamp: U256,
    pub transactions: Vec<TransactionHash>,
    pub uncles: Vec<OwnedHash>,
}

impl L2Block {
    const DUMMY_QUANTITY: U256 = U256::zero();
    const DUMMY_HASH: &str = "0000000000000000000000000000000000000000";

    fn dummy_hash() -> OwnedHash {
        L2Block::DUMMY_HASH.into()
    }

    fn dummy_block_hash() -> BlockHash {
        [0; BLOCK_HASH_SIZE]
    }

    pub fn new(number: L2Level, transactions: Vec<TransactionHash>) -> Self {
        let hash: BlockHash = {
            let number: U256 = number.into();
            number.into()
        };
        L2Block {
            number,
            hash,
            parent_hash: L2Block::dummy_block_hash(),
            nonce: L2Block::DUMMY_QUANTITY,
            sha3_uncles: L2Block::dummy_hash(),
            logs_bloom: None,
            transactions_root: L2Block::dummy_hash(),
            state_root: L2Block::dummy_hash(),
            receipts_root: L2Block::dummy_hash(),
            miner: L2Block::dummy_hash(),
            difficulty: L2Block::DUMMY_QUANTITY,
            total_difficulty: L2Block::DUMMY_QUANTITY,
            extra_data: L2Block::dummy_hash(),
            size: L2Block::DUMMY_QUANTITY,
            gas_limit: L2Block::DUMMY_QUANTITY,
            gas_used: L2Block::DUMMY_QUANTITY,
            timestamp: L2Block::DUMMY_QUANTITY,
            transactions,
            uncles: Vec::new(),
        }
    }
}

fn get_tx_sender(
    tx: &EthereumTransactionCommon,
) -> Result<(OwnedPath, EthereumAddress), Error> {
    let address = tx.caller();
    // We reencode in hexadecimal, since the accounts hash are encoded in
    // hexadecimal in the storage.
    let hash = address_to_hash(address);
    let path = storage::account_path(&hash)?;
    Ok((path, address))
}

fn get_tx_receiver(
    tx: &EthereumTransactionCommon,
) -> Result<(OwnedPath, EthereumAddress), Error> {
    let hash = address_to_hash(tx.to);
    let path = storage::account_path(&hash)?;
    Ok((path, tx.to))
}

// Update an account with the given balance and nonce (if one is given), and
// initialize it if it doesn't already appear in the storage.
fn update_account<Host: Runtime>(
    host: &mut Host,
    account_path: &OwnedPath,
    balance: Wei,
    nonce: Option<U256>, // if none is given, only the balance is updated. This
                         // avoids updating the storage with the same value.
) -> Result<(), Error> {
    if storage::has_account(host, account_path)? {
        storage::store_balance(host, account_path, balance)?;
        if let Some(nonce) = nonce {
            storage::store_nonce(host, account_path, nonce)?
        };
        Ok(())
    } else {
        let account = Account::with_assets(balance);
        storage::store_account(host, &account, account_path)
    }
}

fn make_receipt(
    block: &L2Block,
    tx: &Transaction,
    status: TransactionStatus,
    index: u32,
    sender: EthereumAddress,
    to: EthereumAddress,
) -> TransactionReceipt {
    TransactionReceipt {
        hash: tx.tx_hash,
        index,
        block_hash: block.hash,
        block_number: block.number,
        from: sender,
        to: Some(to),
        cumulative_gas_used: U256::zero(),
        effective_gas_price: U256::zero(),
        gas_used: U256::zero(),
        contract_address: None,
        type_: TransactionType::Legacy,
        status,
    }
}

// invariant: the transaction is valid
fn apply_transaction<Host: Runtime>(
    host: &mut Host,
    block: &L2Block,
    transaction: &Transaction,
    index: u32,
) -> Result<TransactionReceipt, Error> {
    let (sender_path, sender_address) = get_tx_sender(&transaction.tx)?;
    let sender_balance =
        storage::read_account_balance(host, &sender_path).unwrap_or_else(|_| Wei::zero());
    let sender_nonce =
        storage::read_account_nonce(host, &sender_path).unwrap_or(U256::zero());
    let value: U256 = transaction.tx.value;
    let (dst_path, dst_address) = get_tx_receiver(&transaction.tx)?;

    // First pay for the gas
    let src_balance_without_gas = sender_balance - transaction.tx.gas_price;
    // The gas is paid even if there's not enough balance for the total
    // transaction
    let (src_balance, status) = if src_balance_without_gas < value {
        (src_balance_without_gas, TransactionStatus::Failure)
    } else {
        (src_balance_without_gas - value, TransactionStatus::Success)
    };
    update_account(
        host,
        &sender_path,
        src_balance,
        Some(sender_nonce + U256::one()),
    )?;

    if status == TransactionStatus::Success {
        let dst_balance = storage::read_account_balance(host, &dst_path)
            .unwrap_or_else(|_| Wei::zero());
        update_account(host, &dst_path, dst_balance + value, None)?;
    };
    Ok(make_receipt(
        block,
        transaction,
        status,
        index,
        sender_address,
        dst_address,
    ))
}

// This function is only available in nightly, hence the need for redefinition
fn try_collect<T, E>(vec: Vec<Result<T, E>>) -> Result<Vec<T>, E> {
    let mut new_vec = Vec::new();
    for v in vec {
        match v {
            Ok(v) => new_vec.push(v),
            Err(e) => return Err(e),
        }
    }
    Ok(new_vec)
}

fn apply_transactions<Host: Runtime>(
    host: &mut Host,
    block: &L2Block,
    transactions: &[Transaction],
) -> Result<Vec<TransactionReceipt>, Error> {
    try_collect(
        transactions
            .iter()
            .enumerate()
            .map(|(index, tx)| (apply_transaction(host, block, tx, index as u32)))
            .collect(),
    )
}

pub fn produce<Host: Runtime>(host: &mut Host, queue: Queue) -> Result<(), Error> {
    for proposal in queue.proposals {
        let current_level = storage::read_current_block_number(host)?;
        let next_level = current_level + 1;
        let transaction_hashes =
            proposal.transactions.iter().map(|tx| tx.tx_hash).collect();
        let valid_block = L2Block::new(next_level, transaction_hashes);
        storage::store_current_block(host, &valid_block)?;
        let receipts = apply_transactions(host, &valid_block, &proposal.transactions)?;
        storage::store_transaction_receipts(host, &receipts)?;
    }
    Ok(())
}
