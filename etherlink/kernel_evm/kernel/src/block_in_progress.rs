// SPDX-FileCopyrightText: 2023 Marigold <contact@marigold.dev>
// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
// SPDX-FileCopyrightText: 2023 Functori <contact@functori.com>
//
// SPDX-License-Identifier: MIT

use crate::apply::{TransactionObjectInfo, TransactionReceiptInfo};
use crate::error::Error;
use crate::error::TransferError::CumulativeGasUsedOverflow;
use crate::inbox::Transaction;
use crate::safe_storage::KernelRuntime;
use crate::storage;
use crate::storage::{EVM_TRANSACTIONS_OBJECTS, EVM_TRANSACTIONS_RECEIPTS};
use crate::tick_model;
use anyhow::Context;
use ethereum::Log;
use evm_execution::account_storage::EVM_ACCOUNTS_PATH;
use primitive_types::{H160, H256, U256};
use revm_primitives::{ExecutionResult::Success, Output::Create};
use rlp::{Decodable, DecoderError, Encodable};
use std::collections::VecDeque;
use tezos_ethereum::block::{BlockConstants, L2Block};
use tezos_ethereum::rlp_helpers::*;
use tezos_ethereum::transaction::{
    IndexedLog, TransactionObject, TransactionReceipt, TransactionStatus,
    TransactionType, TRANSACTION_HASH_SIZE,
};
use tezos_ethereum::Bloom;
use tezos_evm_logging::{log, Level::*};
use tezos_smart_rollup_encoding::timestamp::Timestamp;
use tezos_smart_rollup_host::path::RefPath;
use tezos_smart_rollup_host::runtime::Runtime;

#[derive(Debug, PartialEq, Clone)]
/// Container for all data needed during block computation
pub struct BlockInProgress {
    /// block number
    pub number: U256,
    /// queue containing the transactions to execute
    tx_queue: VecDeque<Transaction>,
    /// list of transactions executed without issue
    valid_txs: Vec<[u8; TRANSACTION_HASH_SIZE]>,
    /// gas accumulator
    pub cumulative_gas: U256,
    /// index for next transaction
    pub index: u32,
    /// gas price for transactions in the block being created
    pub gas_price: U256,
    /// hash of the parent
    pub parent_hash: H256,
    /// Cumulative number of ticks used
    pub estimated_ticks: u64,
    /// logs bloom filter
    pub logs_bloom: Bloom,
    /// offset for the first log of the next transaction
    pub logs_offset: u64,
    /// Timestamp
    pub timestamp: Timestamp,
}

impl Encodable for BlockInProgress {
    fn rlp_append(&self, stream: &mut rlp::RlpStream) {
        stream.begin_list(10);
        stream.append(&self.number);
        append_queue(stream, &self.tx_queue);
        append_txs(stream, &self.valid_txs);
        stream.append(&self.cumulative_gas);
        stream.append(&self.index);
        stream.append(&self.gas_price);
        stream.append(&self.parent_hash);
        stream.append(&self.logs_bloom);
        stream.append(&self.logs_offset);
        append_timestamp(stream, self.timestamp);
    }
}

fn append_queue(stream: &mut rlp::RlpStream, queue: &VecDeque<Transaction>) {
    stream.begin_list(queue.len());
    for transaction in queue {
        stream.append(transaction);
    }
}

fn append_txs(stream: &mut rlp::RlpStream, valid_txs: &Vec<[u8; TRANSACTION_HASH_SIZE]>) {
    stream.begin_list(valid_txs.len());
    valid_txs.iter().for_each(|tx| {
        stream.append_iter(*tx);
    })
}

impl Decodable for BlockInProgress {
    fn decode(decoder: &rlp::Rlp<'_>) -> Result<BlockInProgress, rlp::DecoderError> {
        if !decoder.is_list() {
            return Err(DecoderError::RlpExpectedToBeList);
        }
        if decoder.item_count()? != 10 {
            return Err(DecoderError::RlpIncorrectListLen);
        }

        let mut it = decoder.iter();
        let number: U256 = decode_field(&next(&mut it)?, "number")?;
        let tx_queue: VecDeque<Transaction> = decode_queue(&next(&mut it)?)?;
        let valid_txs: Vec<[u8; TRANSACTION_HASH_SIZE]> =
            decode_valid_txs(&next(&mut it)?)?;
        let cumulative_gas: U256 = decode_field(&next(&mut it)?, "cumulative_gas")?;
        let index: u32 = decode_field(&next(&mut it)?, "index")?;
        let gas_price: U256 = decode_field(&next(&mut it)?, "gas_price")?;
        let parent_hash: H256 = decode_field(&next(&mut it)?, "parent_hash")?;
        let logs_bloom: Bloom = decode_field(&next(&mut it)?, "logs_bloom")?;
        let logs_offset: u64 = decode_field(&next(&mut it)?, "logs_offset")?;
        let timestamp = decode_timestamp(&next(&mut it)?)?;
        let estimated_ticks: u64 = 0;
        let bip = Self {
            number,
            tx_queue,
            valid_txs,
            cumulative_gas,
            index,
            gas_price,
            parent_hash,
            estimated_ticks,
            logs_bloom,
            logs_offset,
            timestamp,
        };
        Ok(bip)
    }
}

fn decode_valid_txs(
    decoder: &rlp::Rlp<'_>,
) -> Result<Vec<[u8; TRANSACTION_HASH_SIZE]>, DecoderError> {
    if !decoder.is_list() {
        return Err(DecoderError::RlpExpectedToBeList);
    }
    let mut valid_txs = Vec::with_capacity(decoder.item_count()?);
    for item in decoder.iter() {
        let tx = decode_tx_hash(item)?;
        valid_txs.push(tx);
    }
    Ok(valid_txs)
}

fn decode_queue(decoder: &rlp::Rlp<'_>) -> Result<VecDeque<Transaction>, DecoderError> {
    if !decoder.is_list() {
        return Err(DecoderError::RlpExpectedToBeList);
    }
    let mut queue = VecDeque::with_capacity(decoder.item_count()?);
    for item in decoder.iter() {
        let tx: Transaction = item.as_val()?;
        queue.push_back(tx);
    }
    Ok(queue)
}

impl BlockInProgress {
    pub fn queue_length(&self) -> usize {
        self.tx_queue.len()
    }

    pub fn new_with_ticks(
        number: U256,
        parent_hash: H256,
        gas_price: U256,
        transactions: VecDeque<Transaction>,
        estimated_ticks: u64,
        timestamp: Timestamp,
    ) -> Self {
        Self {
            number,
            tx_queue: transactions,
            valid_txs: Vec::new(),
            cumulative_gas: U256::zero(),
            index: 0,
            gas_price,
            parent_hash,
            estimated_ticks,
            logs_bloom: Bloom::default(),
            logs_offset: 0,
            timestamp,
        }
    }

    // constructor of raw structure, used in tests
    #[cfg(test)]
    pub fn new(
        number: U256,
        gas_price: U256,
        transactions: VecDeque<Transaction>,
    ) -> BlockInProgress {
        Self::new_with_ticks(
            number,
            H256::zero(),
            gas_price,
            transactions,
            0u64,
            Timestamp::from(0i64),
        )
    }

    pub fn from_blueprint(
        blueprint: crate::blueprint::Blueprint,
        current_block_number: U256,
        parent_hash: H256,
        constants: &BlockConstants,
        tick_counter: u64,
    ) -> BlockInProgress {
        // blueprint is turn into a ring to allow popping from the front
        let ring = blueprint.transactions.into();
        BlockInProgress::new_with_ticks(
            current_block_number,
            parent_hash,
            constants.gas_price,
            ring,
            tick_counter,
            blueprint.timestamp,
        )
    }

    fn add_gas(&mut self, gas: U256) -> Result<(), Error> {
        self.cumulative_gas = self
            .cumulative_gas
            .checked_add(gas)
            .ok_or(Error::Transfer(CumulativeGasUsedOverflow))?;
        Ok(())
    }

    pub fn register_valid_transaction<Host: Runtime>(
        &mut self,
        transaction: &Transaction,
        object_info: TransactionObjectInfo,
        receipt_info: TransactionReceiptInfo,
        ticks_used: u64,
        host: &mut Host,
    ) -> Result<(), anyhow::Error> {
        // account for gas
        self.add_gas(object_info.gas_used)?;

        // account for transaction ticks
        self.estimated_ticks +=
            tick_model::ticks_of_valid_transaction(transaction, ticks_used);

        // register transaction as done
        self.valid_txs.push(transaction.tx_hash);
        self.index += 1;

        // make receipt
        let receipt = self.make_receipt(receipt_info);
        let receipt_bloom_size: u64 = tick_model::bloom_size(&receipt.logs).try_into()?;
        log!(
            host,
            Debug,
            "[Benchmarking] bloom size: {}",
            receipt_bloom_size
        );
        // extend BIP's logs bloom
        self.logs_bloom.accrue_bloom(&receipt.logs_bloom);

        // store info
        let receipt_size = storage::store_transaction_receipt(host, &receipt)
            .context("Failed to store the receipt")?;
        let obj_size =
            storage::store_transaction_object(host, &self.make_object(object_info))
                .context("Failed to store the transaction object")?;

        // account for registering ticks
        self.estimated_ticks +=
            tick_model::ticks_of_register(receipt_size, obj_size, receipt_bloom_size);

        Ok(())
    }

    pub fn account_for_invalid_transaction(&mut self, tx_data_size: u64) {
        self.estimated_ticks += tick_model::ticks_of_invalid_transaction(tx_data_size);
    }

    fn safe_store_get_hash<Host: KernelRuntime>(
        host: &mut Host,
        path: Option<RefPath>,
    ) -> Result<Vec<u8>, anyhow::Error> {
        match host.store_get_hash(path) {
            Ok(hash) => Ok(hash),
            _ => Ok(L2Block::dummy_hash()),
        }
    }

    pub fn finalize_and_store<Host: KernelRuntime>(
        self,
        host: &mut Host,
    ) -> Result<L2Block, anyhow::Error> {
        let state_root = Self::safe_store_get_hash(host, Some(EVM_ACCOUNTS_PATH))?;
        let receipts_root =
            Self::safe_store_get_hash(host, Some(EVM_TRANSACTIONS_RECEIPTS))?;
        let transactions_root =
            Self::safe_store_get_hash(host, Some(EVM_TRANSACTIONS_OBJECTS))?;
        let new_block = L2Block::new(
            self.number,
            self.valid_txs,
            self.timestamp,
            self.parent_hash,
            self.logs_bloom,
            transactions_root,
            state_root,
            receipts_root,
            self.cumulative_gas,
        );
        storage::store_current_block(host, &new_block)
            .context("Failed to store the current block")?;
        Ok(new_block)
    }

    pub fn pop_tx(&mut self) -> Option<Transaction> {
        self.tx_queue.pop_front()
    }

    pub fn has_tx(&self) -> bool {
        !self.tx_queue.is_empty()
    }

    pub fn would_overflow(&self) -> bool {
        match self.tx_queue.front() {
            Some(transaction) => {
                tick_model::estimate_would_overflow(self.estimated_ticks, transaction)
            }
            None => false, // should not happen, but false is a safe value anyway
        }
    }

    // This is just dumb, but needed for compilation.
    // The good approach is to use the revm_primitivess::Log inside
    // IndexedLog.
    fn revm_log_to_eth_log(log: revm_primitives::Log) -> Log {
        let raw_address: [u8; 20] = <[u8; 20]>::from(log.address.0);
        let address = H160::from(raw_address);
        let topics = log.topics.iter().map(|topic| H256::from(topic.0)).collect();
        let data = log.data.0.to_vec();
        Log {
            address,
            topics,
            data,
        }
    }

    pub fn make_receipt(
        &mut self,
        receipt_info: TransactionReceiptInfo,
    ) -> TransactionReceipt {
        let TransactionReceiptInfo {
            tx_hash: hash,
            index,
            caller: from,
            to,
            execution_outcome,
            ..
        } = receipt_info;

        let &mut Self {
            number: block_number,
            gas_price: effective_gas_price,
            cumulative_gas,
            logs_offset,
            ..
        } = self;

        match execution_outcome {
            Success {
                logs,
                gas_used,
                output,
                ..
            } => {
                let log_iter = logs.into_iter();
                let logs: Vec<IndexedLog> = log_iter
                    .enumerate()
                    .map(|(i, log)| {
                        let log = Self::revm_log_to_eth_log(log);
                        IndexedLog {
                            log,
                            index: i as u64 + logs_offset,
                        }
                    })
                    .collect();
                self.logs_offset += logs.len() as u64;
                let contract_address = if let Create(_, Some(address)) = output {
                    let raw_address: [u8; 20] = <[u8; 20]>::from(address.0);
                    Some(H160::from(raw_address))
                } else {
                    None
                };
                TransactionReceipt {
                    hash,
                    index,
                    block_number,
                    from,
                    to,
                    cumulative_gas_used: cumulative_gas,
                    effective_gas_price,
                    gas_used: U256::from(gas_used),
                    contract_address,
                    logs_bloom: TransactionReceipt::logs_to_bloom(&logs),
                    logs,
                    type_: TransactionType::Legacy,
                    status: TransactionStatus::Success,
                }
            }
            _ => TransactionReceipt {
                hash,
                index,
                block_number,
                from,
                to,
                cumulative_gas_used: cumulative_gas,
                effective_gas_price,
                gas_used: U256::zero(),
                contract_address: None,
                logs: vec![],
                logs_bloom: Bloom::default(),
                type_: TransactionType::Legacy,
                status: TransactionStatus::Failure,
            },
        }
    }

    pub fn make_object(&self, object_info: TransactionObjectInfo) -> TransactionObject {
        TransactionObject {
            block_number: self.number,
            from: object_info.from,
            gas_used: object_info.gas_used,
            gas_price: object_info.gas_price,
            hash: object_info.hash,
            input: object_info.input,
            nonce: object_info.nonce,
            to: object_info.to,
            index: object_info.index,
            value: object_info.value,
            signature: object_info.signature,
        }
    }
}

#[cfg(test)]
mod tests {

    use super::BlockInProgress;
    use crate::inbox::{Deposit, Transaction, TransactionContent};
    use primitive_types::{H160, H256, U256};
    use rlp::{Decodable, Encodable, Rlp};
    use tezos_ethereum::{
        transaction::{TransactionType, TRANSACTION_HASH_SIZE},
        tx_common::EthereumTransactionCommon,
        tx_signature::TxSignature,
        Bloom,
    };
    use tezos_smart_rollup_encoding::timestamp::Timestamp;

    fn new_sig_unsafe(v: u64, r: H256, s: H256) -> TxSignature {
        TxSignature::new(U256::from(v), r, s).unwrap()
    }

    fn dummy_etc(i: u8) -> EthereumTransactionCommon {
        EthereumTransactionCommon {
            type_: TransactionType::Legacy,
            chain_id: Some(U256::from(i)),
            nonce: U256::from(i),
            max_fee_per_gas: U256::from(i),
            max_priority_fee_per_gas: U256::from(i),
            gas_limit: i.into(),
            to: None,
            value: U256::from(i),
            data: Vec::new(),
            access_list: vec![],
            signature: Some(new_sig_unsafe(
                (36 + i * 2).into(), // need to be consistent with chain_id
                H256::from([i; 32]),
                H256::from([i; 32]),
            )),
        }
    }

    fn dummy_tx_eth(i: u8) -> Transaction {
        Transaction {
            tx_hash: [i; TRANSACTION_HASH_SIZE],
            content: TransactionContent::Ethereum(dummy_etc(i)),
        }
    }

    fn dummy_tx_deposit(i: u8) -> Transaction {
        let deposit = Deposit {
            amount: U256::from(i),
            receiver: H160::from([i; 20]),
        };
        Transaction {
            tx_hash: [i; TRANSACTION_HASH_SIZE],
            content: TransactionContent::Deposit(deposit),
        }
    }

    #[test]
    fn test_encode_bip_ethereum() {
        let bip = BlockInProgress {
            number: U256::from(42),
            tx_queue: vec![dummy_tx_eth(1), dummy_tx_eth(8)].into(),
            valid_txs: vec![[2; TRANSACTION_HASH_SIZE], [9; TRANSACTION_HASH_SIZE]],
            cumulative_gas: U256::from(3),
            index: 4,
            gas_price: U256::from(5),
            parent_hash: H256::from([5; 32]),
            estimated_ticks: 99,
            logs_bloom: Bloom::default(),
            logs_offset: 33,
            timestamp: Timestamp::from(0i64),
        };

        let encoded = bip.rlp_bytes();
        let expected = "f9025e2af8e6f871a00101010101010101010101010101010101010101010101010101010101010101f84e01b84bf84901010180018026a00101010101010101010101010101010101010101010101010101010101010101a00101010101010101010101010101010101010101010101010101010101010101f871a00808080808080808080808080808080808080808080808080808080808080808f84e01b84bf84908080880088034a00808080808080808080808080808080808080808080808080808080808080808a00808080808080808080808080808080808080808080808080808080808080808f842a00202020202020202020202020202020202020202020202020202020202020202a00909090909090909090909090909090909090909090909090909090909090909030405a00505050505050505050505050505050505050505050505050505050505050505b901000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000021880000000000000000";

        assert_eq!(hex::encode(encoded), expected);

        let bytes = hex::decode(expected).expect("Should be valid hex string");
        let decoder = Rlp::new(&bytes);
        let decoded =
            BlockInProgress::decode(&decoder).expect("Should have decoded data");

        // the estimated ticks are not stored
        let fresh_bip = BlockInProgress {
            estimated_ticks: 0,
            ..bip
        };
        assert_eq!(decoded, fresh_bip);
    }

    #[test]
    fn test_encode_bip_deposit() {
        let bip = BlockInProgress {
            number: U256::from(42),
            tx_queue: vec![dummy_tx_deposit(1), dummy_tx_deposit(8)].into(),
            valid_txs: vec![[2; TRANSACTION_HASH_SIZE], [9; TRANSACTION_HASH_SIZE]],
            cumulative_gas: U256::from(3),
            index: 4,
            gas_price: U256::from(5),
            parent_hash: H256::from([5; 32]),
            estimated_ticks: 99,
            logs_bloom: Bloom::default(),
            logs_offset: 0,
            timestamp: Timestamp::from(0i64),
        };

        let encoded = bip.rlp_bytes();
        let expected = "f901f02af878f83aa00101010101010101010101010101010101010101010101010101010101010101d802d601940101010101010101010101010101010101010101f83aa00808080808080808080808080808080808080808080808080808080808080808d802d608940808080808080808080808080808080808080808f842a00202020202020202020202020202020202020202020202020202020202020202a00909090909090909090909090909090909090909090909090909090909090909030405a00505050505050505050505050505050505050505050505050505050505050505b901000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080880000000000000000";

        assert_eq!(hex::encode(encoded), expected);

        let bytes = hex::decode(expected).expect("Should be valid hex string");
        let decoder = Rlp::new(&bytes);
        let decoded =
            BlockInProgress::decode(&decoder).expect("Should have decoded data");

        // the estimated ticks are not stored
        let fresh_bip = BlockInProgress {
            estimated_ticks: 0,
            ..bip
        };
        assert_eq!(decoded, fresh_bip);
    }

    #[test]
    fn test_encode_bip_mixed() {
        let bip = BlockInProgress {
            number: U256::from(42),
            tx_queue: vec![dummy_tx_eth(1), dummy_tx_deposit(8)].into(),
            valid_txs: vec![[2; TRANSACTION_HASH_SIZE], [9; TRANSACTION_HASH_SIZE]],
            cumulative_gas: U256::from(3),
            index: 4,
            gas_price: U256::from(5),
            parent_hash: H256::from([5; 32]),
            estimated_ticks: 99,
            logs_bloom: Bloom::default(),
            logs_offset: 4,
            timestamp: Timestamp::from(0i64),
        };

        let encoded = bip.rlp_bytes();
        let expected = "f902272af8aff871a00101010101010101010101010101010101010101010101010101010101010101f84e01b84bf84901010180018026a00101010101010101010101010101010101010101010101010101010101010101a00101010101010101010101010101010101010101010101010101010101010101f83aa00808080808080808080808080808080808080808080808080808080808080808d802d608940808080808080808080808080808080808080808f842a00202020202020202020202020202020202020202020202020202020202020202a00909090909090909090909090909090909090909090909090909090909090909030405a00505050505050505050505050505050505050505050505050505050505050505b901000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004880000000000000000";

        assert_eq!(hex::encode(encoded), expected);

        let bytes = hex::decode(expected).expect("Should be valid hex string");
        let decoder = Rlp::new(&bytes);
        let decoded =
            BlockInProgress::decode(&decoder).expect("Should have decoded data");

        // the estimated ticks are not stored
        let fresh_bip = BlockInProgress {
            estimated_ticks: 0,
            ..bip
        };
        assert_eq!(decoded, fresh_bip);
    }
}
