// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
// SPDX-FileCopyrightText: 2023 Functori <contact@functori.com>
//
// SPDX-License-Identifier: MIT

use crate::blueprint::Queue;
use crate::error::Error;
use crate::error::StorageError::AccountInitialisation;
use crate::error::TransferError::{
    CumulativeGasUsedOverflow, InvalidCallerAddress, InvalidNonce,
};
use crate::storage;
use evm_execution::account_storage::init_account_storage;
use evm_execution::account_storage::EthereumAccountStorage;
use evm_execution::handler::ExecutionOutcome;
use evm_execution::{precompiles, run_transaction};

use tezos_ethereum::address::EthereumAddress;
use tezos_ethereum::transaction::TransactionHash;
use tezos_smart_rollup_host::runtime::Runtime;

use primitive_types::U256;
use tezos_ethereum::block::L2Block;
use tezos_ethereum::transaction::{
    TransactionReceipt, TransactionStatus, TransactionType,
};

struct TransactionReceiptInfo {
    tx_hash: TransactionHash,
    index: u32,
    execution_outcome: Option<ExecutionOutcome>,
    caller: EthereumAddress,
    to: EthereumAddress,
}

fn make_receipt_info(
    tx_hash: TransactionHash,
    index: u32,
    execution_outcome: Option<ExecutionOutcome>,
    caller: EthereumAddress,
    to: EthereumAddress,
) -> TransactionReceiptInfo {
    TransactionReceiptInfo {
        tx_hash,
        index,
        execution_outcome,
        caller,
        to,
    }
}

fn make_receipt(
    block: &L2Block,
    receipt_info: TransactionReceiptInfo,
    cumulative_gas_used: &mut U256,
) -> Result<TransactionReceipt, Error> {
    let hash = receipt_info.tx_hash;
    let index = receipt_info.index;
    let block_hash = block.hash;
    let block_number = block.number;
    let from = receipt_info.caller;
    let to = Some(receipt_info.to);
    let effective_gas_price = block.constants().gas_price;

    let tx_receipt = match receipt_info.execution_outcome {
        Some(outcome) => TransactionReceipt {
            hash,
            index,
            block_hash,
            block_number,
            from,
            to,
            cumulative_gas_used: cumulative_gas_used
                .checked_add(U256::from(outcome.gas_used))
                .ok_or(Error::Transfer(CumulativeGasUsedOverflow))?,
            effective_gas_price,
            gas_used: U256::from(outcome.gas_used),
            contract_address: outcome.new_address,
            type_: TransactionType::Legacy,
            status: if outcome.is_success {
                TransactionStatus::Success
            } else {
                TransactionStatus::Failure
            },
        },
        None => TransactionReceipt {
            hash,
            index,
            block_hash,
            block_number,
            from,
            to,
            cumulative_gas_used: *cumulative_gas_used,
            effective_gas_price,
            gas_used: U256::zero(),
            contract_address: None,
            type_: TransactionType::Legacy,
            status: TransactionStatus::Failure,
        },
    };

    Ok(tx_receipt)
}

fn make_receipts(
    block: &L2Block,
    receipt_infos: Vec<TransactionReceiptInfo>,
) -> Result<Vec<TransactionReceipt>, Error> {
    let mut cumulative_gas_used = U256::zero();
    receipt_infos
        .into_iter()
        .map(|receipt_info| make_receipt(block, receipt_info, &mut cumulative_gas_used))
        .collect()
}

fn check_nonce<Host: Runtime>(
    host: &mut Host,
    tx_nonce: U256,
    caller: EthereumAddress,
    evm_account_storage: &mut EthereumAccountStorage,
) -> Result<(), Error> {
    let caller_account_path =
        evm_execution::account_storage::account_path(&caller.into())
            .map_err(|_| Error::Storage(AccountInitialisation))?;
    let caller_account = evm_account_storage
        .get(host, &caller_account_path)
        .map_err(|_| Error::Storage(AccountInitialisation))?;
    let caller_nonce = match caller_account {
        Some(account) => account
            .nonce(host)
            .map_err(|_| Error::Storage(AccountInitialisation))?,
        None => U256::zero(),
    };
    if tx_nonce != caller_nonce {
        Err(Error::Transfer(InvalidNonce {
            expected: tx_nonce,
            actual: caller_nonce,
        }))
    } else {
        Ok(())
    }
}

pub fn produce<Host: Runtime>(host: &mut Host, queue: Queue) -> Result<(), Error> {
    let mut current_block = storage::read_current_block(host)?;
    let mut evm_account_storage =
        init_account_storage().map_err(|_| Error::Storage(AccountInitialisation))?;
    let precompiles = precompiles::precompile_set::<Host>();

    for proposal in queue.proposals {
        let mut valid_txs = Vec::new();
        let mut receipts_infos = Vec::new();
        let transactions = proposal.transactions;

        for (transaction, index) in transactions.into_iter().zip(0u32..) {
            let caller = transaction
                .tx
                .caller()
                .map_err(|_| Error::Transfer(InvalidCallerAddress))?;
            check_nonce(host, transaction.tx.nonce, caller, &mut evm_account_storage)?;
            let receipt_info = match run_transaction(
                host,
                &current_block.constants(),
                &mut evm_account_storage,
                &precompiles,
                transaction.tx.to.into(),
                caller.into(),
                transaction.tx.data,
                Some(transaction.tx.gas_limit),
                Some(transaction.tx.value),
            ) {
                Ok(outcome) => {
                    valid_txs.push(transaction.tx_hash);
                    make_receipt_info(
                        transaction.tx_hash,
                        index,
                        Some(outcome),
                        caller,
                        transaction.tx.to,
                    )
                }
                Err(_) => make_receipt_info(
                    transaction.tx_hash,
                    index,
                    None,
                    caller,
                    transaction.tx.to,
                ),
            };
            receipts_infos.push(receipt_info)
        }

        let new_block = L2Block::new(current_block.number + 1, valid_txs);
        storage::store_current_block(host, &new_block)?;
        storage::store_transaction_receipts(
            host,
            &make_receipts(&new_block, receipts_infos)?,
        )?;
        current_block = new_block;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::blueprint::Blueprint;
    use crate::genesis;
    use crate::inbox::Transaction;
    use crate::storage::{
        read_transaction_receipt_cumulative_gas_used, read_transaction_receipt_status,
    };
    use evm_execution::account_storage::{account_path, EthereumAccountStorage};
    use primitive_types::{H160, H256};
    use std::str::FromStr;
    use tezos_ethereum::address::EthereumAddress;
    use tezos_ethereum::signatures::EthereumTransactionCommon;
    use tezos_ethereum::transaction::{TransactionStatus, TRANSACTION_HASH_SIZE};
    use tezos_smart_rollup_mock::MockHost;

    fn string_to_h256_unsafe(s: &str) -> H256 {
        let mut v: [u8; 32] = [0; 32];
        hex::decode_to_slice(s, &mut v).expect("Could not parse to 256 hex value.");
        H256::from(v)
    }

    fn set_balance(
        host: &mut MockHost,
        evm_account_storage: &mut EthereumAccountStorage,
        address: &H160,
        balance: U256,
    ) {
        let mut account = evm_account_storage
            .get_or_create(host, &account_path(address).unwrap())
            .unwrap();
        let current_balance = account.balance(host).unwrap();
        if current_balance > balance {
            account
                .balance_remove(host, current_balance - balance)
                .unwrap();
        } else {
            account
                .balance_add(host, balance - current_balance)
                .unwrap();
        }
    }

    fn get_balance(
        host: &mut MockHost,
        evm_account_storage: &mut EthereumAccountStorage,
        address: &H160,
    ) -> U256 {
        let account = evm_account_storage
            .get_or_create(host, &account_path(address).unwrap())
            .unwrap();
        account.balance(host).unwrap()
    }

    fn dummy_eth_gen_transaction(
        nonce: U256,
        v: U256,
        r: H256,
        s: H256,
    ) -> EthereumTransactionCommon {
        let chain_id = U256::one();
        let gas_price = U256::from(40000000u64);
        let gas_limit = 21000u64;
        let to =
            EthereumAddress::from("423163e58aabec5daa3dd1130b759d24bef0f6ea".to_string());
        let value = U256::from(500000000u64);
        let data: Vec<u8> = vec![];
        EthereumTransactionCommon {
            chain_id,
            nonce,
            gas_price,
            gas_limit,
            to,
            value,
            data,
            v,
            r,
            s,
        }
    }

    fn dummy_eth_transaction_zero() -> EthereumTransactionCommon {
        // corresponding caller's address is 0xf95abdf6ede4c3703e0e9453771fbee8592d31e9
        // private key 0xe922354a3e5902b5ac474f3ff08a79cff43533826b8f451ae2190b65a9d26158
        let nonce = U256::zero();
        let v = U256::from(37);
        let r = string_to_h256_unsafe(
            "451d603fc1e73bb8c7afda6d4a0ce635657c812262f8d35aa0400504cec5af03",
        );
        let s = string_to_h256_unsafe(
            "562c20b430d8d137ef6ce0dc46a21f3ed4f810b7d27394af70684900be1a2e07",
        );
        dummy_eth_gen_transaction(nonce, v, r, s)
    }

    fn dummy_eth_transaction_one() -> EthereumTransactionCommon {
        // corresponding caller's address is 0xf95abdf6ede4c3703e0e9453771fbee8592d31e9
        // private key 0xe922354a3e5902b5ac474f3ff08a79cff43533826b8f451ae2190b65a9d26158
        let nonce = U256::one();
        let v = U256::from(37);
        let r = string_to_h256_unsafe(
            "624ebca1a42237859de4f0f90e4d6a6e8f73ed014656929abfe5664a039d1fc5",
        );
        let s = string_to_h256_unsafe(
            "4a08c518537102edd0c3c8c2125ef9ca45d32341a5b829a94b2f2f66e4f43eb0",
        );
        dummy_eth_gen_transaction(nonce, v, r, s)
    }

    fn produce_block_with_several_valid_txs(
        host: &mut MockHost,
        evm_account_storage: &mut EthereumAccountStorage,
    ) {
        let _ = genesis::init_block(host);

        let tx_hash_0 = [0; TRANSACTION_HASH_SIZE];
        let tx_hash_1 = [1; TRANSACTION_HASH_SIZE];

        let transactions = vec![
            Transaction {
                tx_hash: tx_hash_0,
                tx: dummy_eth_transaction_zero(),
            },
            Transaction {
                tx_hash: tx_hash_1,
                tx: dummy_eth_transaction_one(),
            },
        ];

        let queue = Queue {
            proposals: vec![Blueprint { transactions }],
        };

        let sender = H160::from_str("f95abdf6ede4c3703e0e9453771fbee8592d31e9").unwrap();
        set_balance(
            host,
            evm_account_storage,
            &sender,
            U256::from(10000000000000000000u64),
        );

        produce(host, queue).expect("The block production failed.")
    }

    fn assert_current_block_reading_validity(host: &mut MockHost) {
        match storage::read_current_block(host) {
            Ok(_) => (),
            Err(e) => {
                panic!("Block reading failed: {:?}\n", e)
            }
        }
    }

    #[test]
    // Test if the invalid transactions are producing receipts with invalid status
    fn test_invalid_transactions_receipt_status() {
        let mut host = MockHost::default();
        let _ = genesis::init_block(&mut host);

        let tx_hash = [0; TRANSACTION_HASH_SIZE];

        let invalid_tx = Transaction {
            tx_hash,
            tx: dummy_eth_transaction_zero(),
        };

        let transactions: Vec<Transaction> = vec![invalid_tx];
        let queue = Queue {
            proposals: vec![Blueprint { transactions }],
        };

        produce(&mut host, queue).expect("The block production failed.");

        match read_transaction_receipt_status(&mut host, &tx_hash) {
            Ok(TransactionStatus::Failure) => (),
            Ok(TransactionStatus::Success) => {
                panic!("The receipt should have a failing status.")
            }
            Err(_) => panic!("Reading the receipt failed."),
        }
    }

    #[test]
    // Test if a valid transaction is producing a receipt with a success status
    fn test_valid_transactions_receipt_status() {
        let mut host = MockHost::default();
        let _ = genesis::init_block(&mut host);

        let tx_hash = [0; TRANSACTION_HASH_SIZE];

        let valid_tx = Transaction {
            tx_hash,
            tx: dummy_eth_transaction_zero(),
        };

        let transactions: Vec<Transaction> = vec![valid_tx];
        let queue = Queue {
            proposals: vec![Blueprint { transactions }],
        };

        let sender = H160::from_str("f95abdf6ede4c3703e0e9453771fbee8592d31e9").unwrap();
        let mut evm_account_storage = init_account_storage().unwrap();
        set_balance(
            &mut host,
            &mut evm_account_storage,
            &sender,
            U256::from(5000000000000000u64),
        );

        produce(&mut host, queue).expect("The block production failed.");

        match read_transaction_receipt_status(&mut host, &tx_hash) {
            Ok(TransactionStatus::Failure) => {
                panic!("The receipt should have a success status.")
            }
            Ok(TransactionStatus::Success) => (),
            Err(_) => panic!("Reading the receipt failed."),
        }
    }

    #[test]
    // Test if several valid transactions can be performed
    fn test_several_valid_transactions() {
        let mut host = MockHost::default();
        let mut evm_account_storage = init_account_storage().unwrap();

        produce_block_with_several_valid_txs(&mut host, &mut evm_account_storage);

        let dest_address =
            H160::from_str("423163e58aabec5daa3dd1130b759d24bef0f6ea").unwrap();
        let dest_balance =
            get_balance(&mut host, &mut evm_account_storage, &dest_address);

        assert_eq!(dest_balance, U256::from(1000000000u64))
    }

    #[test]
    // Test if several valid proposals can produce valid blocks
    fn test_several_valid_proposals() {
        let mut host = MockHost::default();
        let _ = genesis::init_block(&mut host);

        let tx_hash_0 = [0; TRANSACTION_HASH_SIZE];
        let tx_hash_1 = [1; TRANSACTION_HASH_SIZE];

        let transaction_0 = vec![Transaction {
            tx_hash: tx_hash_0,
            tx: dummy_eth_transaction_zero(),
        }];

        let transaction_1 = vec![Transaction {
            tx_hash: tx_hash_1,
            tx: dummy_eth_transaction_one(),
        }];

        let queue = Queue {
            proposals: vec![
                Blueprint {
                    transactions: transaction_0,
                },
                Blueprint {
                    transactions: transaction_1,
                },
            ],
        };

        let sender = H160::from_str("f95abdf6ede4c3703e0e9453771fbee8592d31e9").unwrap();
        let mut evm_account_storage = init_account_storage().unwrap();
        set_balance(
            &mut host,
            &mut evm_account_storage,
            &sender,
            U256::from(10000000000000000000u64),
        );

        produce(&mut host, queue).expect("The block production failed.");

        let dest_address =
            H160::from_str("423163e58aabec5daa3dd1130b759d24bef0f6ea").unwrap();
        let dest_balance =
            get_balance(&mut host, &mut evm_account_storage, &dest_address);

        assert_eq!(dest_balance, U256::from(1000000000u64))
    }

    #[test]
    // Test transfers gas consumption consistency
    fn test_cumulative_transfers_gas_consumption() {
        let mut host = MockHost::default();
        let _ = genesis::init_block(&mut host);
        let base_gas = U256::from(21000);

        let tx_hash_0 = [0; TRANSACTION_HASH_SIZE];
        let tx_hash_1 = [1; TRANSACTION_HASH_SIZE];

        let transactions = vec![
            Transaction {
                tx_hash: tx_hash_0,
                tx: dummy_eth_transaction_zero(),
            },
            Transaction {
                tx_hash: tx_hash_1,
                tx: dummy_eth_transaction_one(),
            },
        ];

        let queue = Queue {
            proposals: vec![Blueprint {
                transactions: transactions.clone(),
            }],
        };

        let sender = H160::from_str("f95abdf6ede4c3703e0e9453771fbee8592d31e9").unwrap();
        let mut evm_account_storage = init_account_storage().unwrap();
        set_balance(
            &mut host,
            &mut evm_account_storage,
            &sender,
            U256::from(10000000000000000000u64),
        );

        produce(&mut host, queue).expect("The block production failed.");

        for transaction in transactions {
            match read_transaction_receipt_cumulative_gas_used(
                &mut host,
                &transaction.tx_hash,
            ) {
                Ok(cumulative_gas_used) => {
                    assert_eq!(cumulative_gas_used, base_gas)
                }
                Err(_) => panic!("Reading the receipt's cumulative gas used failed."),
            }
        }
    }

    #[test]
    // Test if we're able to read current block (with an empty queue) after
    // a block production
    fn test_read_storage_current_block_after_block_production_with_empty_queue() {
        let mut host = MockHost::default();
        let _ = genesis::init_block(&mut host);
        let queue = Queue { proposals: vec![] };

        produce(&mut host, queue).expect("The block production failed.");

        assert_current_block_reading_validity(&mut host);
    }

    #[test]
    // Test if we're able to read current block (with a filled queue) after
    // a block production
    fn test_read_storage_current_block_after_block_production_with_filled_queue() {
        let mut host = MockHost::default();
        let mut evm_account_storage = init_account_storage().unwrap();

        produce_block_with_several_valid_txs(&mut host, &mut evm_account_storage);

        assert_current_block_reading_validity(&mut host);
    }

    #[test]
    // Test that the same transaction can not be replayed twice
    fn test_replay_attack() {
        let mut host = MockHost::default();
        let _ = genesis::init_block(&mut host);

        let tx = Transaction {
            tx_hash: [0; TRANSACTION_HASH_SIZE],
            tx: dummy_eth_transaction_zero(),
        };

        let transactions = vec![tx.clone(), tx];

        let queue = Queue {
            proposals: vec![
                Blueprint {
                    transactions: transactions.clone(),
                },
                Blueprint { transactions },
            ],
        };

        let sender = H160::from_str("f95abdf6ede4c3703e0e9453771fbee8592d31e9").unwrap();
        let mut evm_account_storage = init_account_storage().unwrap();
        set_balance(
            &mut host,
            &mut evm_account_storage,
            &sender,
            U256::from(10000000000000000000u64),
        );

        match produce(&mut host, queue) {
            Err(Error::Transfer(InvalidNonce { .. })) => (),
            _ => panic!("An error should be thrown because of a replay attack attempt."),
        }
    }
}
