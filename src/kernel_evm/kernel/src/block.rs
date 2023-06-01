// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
// SPDX-FileCopyrightText: 2023 Functori <contact@functori.com>
//
// SPDX-License-Identifier: MIT

use crate::blueprint::{Blueprint, Queue};
use crate::error::Error;
use crate::error::StorageError::AccountInitialisation;
use crate::error::TransferError::{
    CumulativeGasUsedOverflow, InvalidCallerAddress, InvalidNonce,
};
use crate::inbox::Transaction;
use crate::storage::EVMStorage;
use evm_execution::account_storage::EthereumAccountStorage;
use evm_execution::handler::ExecutionOutcome;
use evm_execution::precompiles::PrecompileBTreeMap;
use evm_execution::EthereumError::{
    EthereumAccountError, EthereumStorageError, InternalTrapError,
};
use evm_execution::{precompiles, run_transaction};
use tezos_ethereum::transaction::{TransactionHash, TransactionObject};
use tezos_smart_rollup_host::runtime::Runtime;

use primitive_types::{H160, U256};
use tezos_ethereum::block::{BlockConstants, L2Block};
use tezos_ethereum::transaction::{
    TransactionReceipt, TransactionStatus, TransactionType,
};

struct TransactionReceiptInfo {
    tx_hash: TransactionHash,
    index: u32,
    execution_outcome: Option<ExecutionOutcome>,
    caller: H160,
    to: Option<H160>,
}

fn make_receipt_info(
    tx_hash: TransactionHash,
    index: u32,
    execution_outcome: Option<ExecutionOutcome>,
    caller: H160,
    to: Option<H160>,
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
    let to = receipt_info.to;
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

#[inline(always)]
fn make_object(
    transaction: Transaction,
    from: H160,
    index: u32,
    gas_used: U256,
) -> TransactionObject {
    TransactionObject {
        from,
        gas_used,
        gas_price: transaction.tx.gas_price,
        hash: transaction.tx_hash,
        input: transaction.tx.data,
        nonce: transaction.tx.nonce,
        to: transaction.tx.to,
        index,
        value: transaction.tx.value,
        v: transaction.tx.v,
        r: transaction.tx.r,
        s: transaction.tx.s,
    }
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
    caller: H160,
    evm_account_storage: &mut EthereumAccountStorage,
) -> Result<(), Error> {
    let caller_account_path = evm_execution::account_storage::account_path(&caller)
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

fn store_tx_receipts<Host: Runtime>(
    host: &mut Host,
    receipts: &[TransactionReceipt],
    evm_storage: &mut EVMStorage,
) -> Result<(), Error> {
    for receipt in receipts {
        let mut tx_receipt = evm_storage.tx_receipt(host, &receipt.hash)?;
        tx_receipt.store_tx_receipt(host, receipt)?;
    }
    Ok(())
}

// Note that this is not efficient nor "properly" implemented. This
// is a temporary hack to answer to third-party tools that asks
// for transaction objects.
pub fn store_tx_objects<Host: Runtime>(
    host: &mut Host,
    block: &L2Block,
    objects: &[TransactionObject],
    evm_storage: &mut EVMStorage,
) -> Result<(), Error> {
    for object in objects {
        let mut tx_object = evm_storage.tx_object(host, &object.hash)?;
        tx_object.store_tx_object(host, block.hash, block.number, object)?;
    }
    Ok(())
}

fn store_block_and_tx_infos<Host: Runtime>(
    host: &mut Host,
    new_block: &L2Block,
    receipts_infos: Vec<TransactionReceiptInfo>,
    objects: Vec<TransactionObject>,
    evm_storage: &mut EVMStorage,
) -> Result<(), Error> {
    let mut current_block_storage =
        evm_storage.set_and_get_current_block(host, &new_block.number)?;

    match current_block_storage.store_l2block(host, new_block) {
        Ok(()) => match store_tx_receipts(
            host,
            &make_receipts(new_block, receipts_infos)?,
            evm_storage,
        ) {
            Ok(()) => store_tx_objects(host, new_block, &objects, evm_storage),
            tx_receipts_storage_error => tx_receipts_storage_error,
        },
        block_storage_error => block_storage_error,
    }
}

fn compute<Host: Runtime>(
    host: &mut Host,
    proposal: Blueprint,
    block_constants: &BlockConstants,
    next_level: U256,
    precompiles: &PrecompileBTreeMap<Host>,
    evm_storage: &mut EVMStorage,
    evm_account_storage: &mut EthereumAccountStorage,
) -> Result<L2Block, Error> {
    let mut valid_txs = Vec::new();
    let mut objects = Vec::new();
    let mut receipts_infos = Vec::new();
    let transactions = proposal.transactions;

    for (transaction, index) in transactions.into_iter().zip(0u32..) {
        let caller = transaction
            .tx
            .caller()
            .map_err(|_| Error::Transfer(InvalidCallerAddress))?;
        check_nonce(host, transaction.tx.nonce, caller, evm_account_storage)?;
        let receipt_info = match run_transaction(
            host,
            &block_constants,
            evm_account_storage,
            &precompiles,
            transaction.tx.to,
            caller,
            transaction.tx.data.clone(),
            Some(transaction.tx.gas_limit),
            Some(transaction.tx.value),
        ) {
            Ok(outcome) => {
                valid_txs.push(transaction.tx_hash);
                Ok(make_receipt_info(
                    transaction.tx_hash,
                    index,
                    Some(outcome),
                    caller,
                    transaction.tx.to,
                ))
            }
            Err(
                InternalTrapError | EthereumAccountError(_) | EthereumStorageError(_),
            ) => Err(Error::InvalidRunTransaction),
            Err(_) => Ok(make_receipt_info(
                transaction.tx_hash,
                index,
                None,
                caller,
                transaction.tx.to,
            )),
        };

        match receipt_info {
            Ok(receipt_info) => {
                let gas_used = match &receipt_info.execution_outcome {
                    Some(execution_outcome) => execution_outcome.gas_used.into(),
                    None => U256::zero(),
                };
                let object = make_object(transaction, caller, index, gas_used);
                objects.push(object);
                receipts_infos.push(receipt_info)
            }
            Err(run_transaction_error) => {
                // TODO: https://gitlab.com/tezos/tezos/-/issues/5665
                // Because the proposal's state is unclear, and we do not have a sequencer
                // if an error that leads to a durable storage corruption is caught, we
                // invalidate the entire proposal.
                return Err(run_transaction_error);
            }
        }
    }

    let new_block = L2Block::new(next_level, valid_txs);
    store_block_and_tx_infos(host, &new_block, receipts_infos, objects, evm_storage)?;

    Ok(new_block)
}

pub fn produce<Host: Runtime>(
    host: &mut Host,
    queue: Queue,
    evm_storage: &mut EVMStorage,
    evm_account_storage: &mut EthereumAccountStorage,
) -> Result<(), Error> {
    let mut current_evm_block = evm_storage.current_block(host)?;
    let mut current_block = current_evm_block.read_l2block(host)?;
    let precompiles = precompiles::precompile_set::<Host>();

    for proposal in queue.proposals {
        compute(
            host,
            proposal,
            &current_block.constants(),
            current_block.number + 1,
            &precompiles,
            evm_storage,
            evm_account_storage,
        )
        .map(|new_block| current_block = new_block)?;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::blueprint::Blueprint;
    use crate::genesis;
    use crate::inbox::Transaction;
    use crate::storage::init_evm_storage;
    use evm_execution::account_storage::{
        account_path, init_account_storage, EthereumAccountStorage,
    };
    use primitive_types::{H160, H256};
    use std::str::FromStr;
    use tezos_ethereum::signatures::EthereumTransactionCommon;
    use tezos_ethereum::transaction::TRANSACTION_HASH_SIZE;
    use tezos_smart_rollup_mock::MockHost;

    fn address_from_str(s: &str) -> Option<H160> {
        let data = &hex::decode(s).unwrap();
        Some(H160::from_slice(data))
    }
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
        let to = address_from_str("423163e58aabec5daa3dd1130b759d24bef0f6ea");
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

    fn dummy_eth_transaction_deploy() -> EthereumTransactionCommon {
        let nonce = U256::from(0);
        let gas_price = U256::from(40000000000u64);
        let gas_limit = 21000u64;
        let value = U256::zero();
        // corresponding contract is kernel_benchmark/scripts/benchmarks/contracts/storage.sol
        let data: Vec<u8> = hex::decode("608060405234801561001057600080fd5b5061017f806100206000396000f3fe608060405234801561001057600080fd5b50600436106100415760003560e01c80634e70b1dc1461004657806360fe47b1146100645780636d4ce63c14610080575b600080fd5b61004e61009e565b60405161005b91906100d0565b60405180910390f35b61007e6004803603810190610079919061011c565b6100a4565b005b6100886100ae565b60405161009591906100d0565b60405180910390f35b60005481565b8060008190555050565b60008054905090565b6000819050919050565b6100ca816100b7565b82525050565b60006020820190506100e560008301846100c1565b92915050565b600080fd5b6100f9816100b7565b811461010457600080fd5b50565b600081359050610116816100f0565b92915050565b600060208284031215610132576101316100eb565b5b600061014084828501610107565b9150509291505056fea2646970667358221220ec57e49a647342208a1f5c9b1f2049bf1a27f02e19940819f38929bf67670a5964736f6c63430008120033").unwrap();

        let tx = EthereumTransactionCommon {
            chain_id: U256::one(),
            nonce,
            gas_price,
            gas_limit,
            to: None,
            value,
            data,
            v: U256::one(),
            r: H256::zero(),
            s: H256::zero(),
        };

        // corresponding caller's address is 0xaf1276cbb260bb13deddb4209ae99ae6e497f446
        tx.sign_transaction(
            "dcdff53b4f013dbcdc717f89fe3bf4d8b10512aae282b48e01d7530470382701"
                .to_string(),
        )
        .unwrap()
    }

    fn produce_block_with_several_valid_txs(
        host: &mut MockHost,
        evm_storage: &mut EVMStorage,
        evm_account_storage: &mut EthereumAccountStorage,
    ) {
        let _ = genesis::init_block(host, evm_storage);

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

        produce(host, queue, evm_storage, evm_account_storage)
            .expect("The block production failed.")
    }

    fn assert_current_block_reading_validity(
        host: &mut MockHost,
        evm_storage: &mut EVMStorage,
    ) {
        let mut current_evm_block = evm_storage.current_block(host).unwrap();
        match current_evm_block.read_l2block(host) {
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
        let mut evm_storage = init_evm_storage().unwrap();
        let mut evm_account_storage = init_account_storage().unwrap();
        let _ = genesis::init_block(&mut host, &mut evm_storage);

        let tx_hash = [0; TRANSACTION_HASH_SIZE];

        let invalid_tx = Transaction {
            tx_hash,
            tx: dummy_eth_transaction_zero(),
        };

        let transactions: Vec<Transaction> = vec![invalid_tx];
        let queue = Queue {
            proposals: vec![Blueprint { transactions }],
        };

        produce(&mut host, queue, &mut evm_storage, &mut evm_account_storage)
            .expect("The block production failed.");

        let mut tx_receipt = evm_storage.tx_receipt(&mut host, &tx_hash).unwrap();
        let status = tx_receipt
            .read_tx_receipt_status(&mut host)
            .expect("Should have found receipt");
        assert_eq!(TransactionStatus::Failure, status)
    }

    #[test]
    // Test if a valid transaction is producing a receipt with a success status
    fn test_valid_transactions_receipt_status() {
        let mut host = MockHost::default();
        let mut evm_storage = init_evm_storage().unwrap();
        let mut evm_account_storage = init_account_storage().unwrap();
        let _ = genesis::init_block(&mut host, &mut evm_storage);

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
        set_balance(
            &mut host,
            &mut evm_account_storage,
            &sender,
            U256::from(5000000000000000u64),
        );

        produce(&mut host, queue, &mut evm_storage, &mut evm_account_storage)
            .expect("The block production failed.");

        let mut tx_receipt = evm_storage.tx_receipt(&mut host, &tx_hash).unwrap();
        let status = tx_receipt
            .read_tx_receipt_status(&mut host)
            .expect("Should have found receipt");
        assert_eq!(TransactionStatus::Success, status)
    }

    #[test]
    // Test if a valid transaction is producing a receipt with a contract address
    fn test_valid_transactions_receipt_contract_address() {
        let mut host = MockHost::default();
        let mut evm_storage = init_evm_storage().unwrap();
        let mut evm_account_storage = init_account_storage().unwrap();
        let _ = genesis::init_block(&mut host, &mut evm_storage);

        let tx_hash = [0; TRANSACTION_HASH_SIZE];
        let tx = dummy_eth_transaction_deploy();
        assert_eq!(
            H160::from_str("af1276cbb260bb13deddb4209ae99ae6e497f446").unwrap(),
            tx.caller().unwrap()
        );
        let valid_tx = Transaction {
            tx_hash,
            tx: dummy_eth_transaction_deploy(),
        };

        let transactions: Vec<Transaction> = vec![valid_tx];
        let queue = Queue {
            proposals: vec![Blueprint { transactions }],
        };

        let sender = H160::from_str("af1276cbb260bb13deddb4209ae99ae6e497f446").unwrap();
        set_balance(
            &mut host,
            &mut evm_account_storage,
            &sender,
            U256::from(5000000000000000u64),
        );

        produce(&mut host, queue, &mut evm_storage, &mut evm_account_storage)
            .expect("The block production failed.");

        let mut tx_receipt = evm_storage.tx_receipt(&mut host, &tx_hash).unwrap();
        let receipt = tx_receipt
            .read_tx_receipt(&mut host, &tx_hash)
            .expect("should have found receipt");

        assert_eq!(TransactionStatus::Success, receipt.status);
        assert_eq!(
            H160::from_str("af1276cbb260bb13deddb4209ae99ae6e497f446").unwrap(),
            receipt.from
        );
        assert_eq!(
            Some(H160::from_str("d9d427235f5746ffd1d5a0d850e77880a94b668f").unwrap()),
            receipt.contract_address
        );
    }

    #[test]
    // Test if several valid transactions can be performed
    fn test_several_valid_transactions() {
        let mut host = MockHost::default();
        let mut evm_storage = init_evm_storage().unwrap();
        let mut evm_account_storage = init_account_storage().unwrap();

        produce_block_with_several_valid_txs(
            &mut host,
            &mut evm_storage,
            &mut evm_account_storage,
        );

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
        let mut evm_storage = init_evm_storage().unwrap();
        let mut evm_account_storage = init_account_storage().unwrap();
        let _ = genesis::init_block(&mut host, &mut evm_storage);

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
        set_balance(
            &mut host,
            &mut evm_account_storage,
            &sender,
            U256::from(10000000000000000000u64),
        );

        produce(&mut host, queue, &mut evm_storage, &mut evm_account_storage)
            .expect("The block production failed.");

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
        let mut evm_storage = init_evm_storage().unwrap();
        let mut evm_account_storage = init_account_storage().unwrap();
        let _ = genesis::init_block(&mut host, &mut evm_storage);
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
        set_balance(
            &mut host,
            &mut evm_account_storage,
            &sender,
            U256::from(10000000000000000000u64),
        );

        produce(&mut host, queue, &mut evm_storage, &mut evm_account_storage)
            .expect("The block production failed.");

        for transaction in transactions {
            let mut tx_receipt = evm_storage
                .tx_receipt(&mut host, &transaction.tx_hash)
                .unwrap();
            let receipt = tx_receipt
                .read_tx_receipt(&mut host, &transaction.tx_hash)
                .expect("should have found receipt");
            // NB: we do not use any gas for now, hence the following assertion
            assert_eq!(receipt.cumulative_gas_used, base_gas);
        }
    }

    #[test]
    // Test if we're able to read current block (with an empty queue) after
    // a block production
    fn test_read_storage_current_block_after_block_production_with_empty_queue() {
        let mut host = MockHost::default();
        let mut evm_storage = init_evm_storage().unwrap();
        let mut evm_account_storage = init_account_storage().unwrap();
        let _ = genesis::init_block(&mut host, &mut evm_storage);
        let queue = Queue { proposals: vec![] };

        produce(&mut host, queue, &mut evm_storage, &mut evm_account_storage)
            .expect("The block production failed.");

        assert_current_block_reading_validity(&mut host, &mut evm_storage);
    }

    #[test]
    // Test if we're able to read current block (with a filled queue) after
    // a block production
    fn test_read_storage_current_block_after_block_production_with_filled_queue() {
        let mut host = MockHost::default();
        let mut evm_storage = init_evm_storage().unwrap();
        let mut evm_account_storage = init_account_storage().unwrap();

        produce_block_with_several_valid_txs(
            &mut host,
            &mut evm_storage,
            &mut evm_account_storage,
        );

        assert_current_block_reading_validity(&mut host, &mut evm_storage);
    }

    #[test]
    // Test that the same transaction can not be replayed twice
    fn test_replay_attack() {
        let mut host = MockHost::default();
        let mut evm_storage = init_evm_storage().unwrap();
        let mut evm_account_storage = init_account_storage().unwrap();
        let _ = genesis::init_block(&mut host, &mut evm_storage);

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
        set_balance(
            &mut host,
            &mut evm_account_storage,
            &sender,
            U256::from(10000000000000000000u64),
        );

        match produce(&mut host, queue, &mut evm_storage, &mut evm_account_storage) {
            Err(Error::Transfer(InvalidNonce { .. })) => (),
            _ => panic!("An error should be thrown because of a replay attack attempt."),
        }
    }
}
