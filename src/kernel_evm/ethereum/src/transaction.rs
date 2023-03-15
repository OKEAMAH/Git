// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
//
// SPDX-License-Identifier: MIT

use clarity::Transaction as EthTransaction;
use primitive_types::U256;

use crate::eth_gen::{Address, BlockHash, L2Level, OwnedHash};

pub const TRANSACTION_HASH_SIZE: usize = 32;
pub type TransactionHash = [u8; TRANSACTION_HASH_SIZE];

pub type RawTransaction = EthTransaction;
pub type RawTransactions = Vec<RawTransaction>;

pub enum TransactionType {
    Legacy,
    Eip2930,
    Eip1559,
}

pub enum TransactionStatus {
    Success,
    Failure,
}

/// Transaction receipt, see https://ethereum.org/en/developers/docs/apis/json-rpc/#eth_gettransactionreceipt
pub struct TransactionReceipt {
    /// Hash of the transaction.
    pub hash: TransactionHash,
    /// Integer of the transactions index position in the block.
    pub index: u32,
    /// Hash of the block where this transaction was in.
    pub block_hash: BlockHash,
    /// Block number where this transaction was in.
    pub block_number: L2Level,
    /// Address of the sender.
    pub from: Address,
    /// Address of the receiver. null when its a contract creation transaction.
    pub to: Option<Address>,
    /// The total amount of gas used when this transaction was executed in the block
    pub cumulative_gas_used: U256,
    /// The sum of the base fee and tip paid per unit of gas.
    pub effective_gas_price: U256,
    /// The amount of gas used by this specific transaction alone.
    pub gas_used: U256,
    /// The contract address created, if the transaction was a contract creation, otherwise null.
    pub contract_address: Option<OwnedHash>,
    // The two following fields can be ignored for now
    // pub logs : unit,
    // pub logs_bloom : unit,
    pub type_: TransactionType,
    /// Transaction status
    pub status: TransactionStatus,
}
