// SPDX-FileCopyrightText: 2023 Marigold <contact@marigold.dev>
// SPDX-FileCopyrightText: 2023 Functori <contact@functori.com>
// SPDX-FileCopyrightText: 2022-2023 TriliTech <contact@trili.tech>
// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
//
// SPDX-License-Identifier: MIT

use evm_execution::account_storage::{account_path, EthereumAccountStorage};
use evm_execution::handler::ExecutionOutcome;
use evm_execution::precompiles::PrecompileBTreeMap;
use evm_execution::run_transaction;
use primitive_types::{H160, U256};
use tezos_ethereum::block::BlockConstants;
use tezos_ethereum::transaction::TransactionHash;
use tezos_ethereum::tx_common::EthereumTransactionCommon;
use tezos_ethereum::tx_signature::TxSignature;
use tezos_evm_logging::{log, Level::*};
use tezos_smart_rollup_host::runtime::Runtime;

use crate::error::Error;
use crate::inbox::{Deposit, Transaction, TransactionContent};
use crate::indexable_storage::IndexableStorage;
use crate::storage::index_account;
use crate::CONFIG;

// This implementation of `Transaction` is used to share the logic of
// transaction receipt and transaction object making. The functions
// `make_receipt_info` and `make_object_info` use these functions to build
// the associated infos.
impl Transaction {
    fn to(&self) -> Option<H160> {
        match &self.content {
            TransactionContent::Deposit(Deposit { receiver, .. }) => Some(*receiver),
            TransactionContent::Ethereum(transaction) => transaction.to,
        }
    }

    fn data(&self) -> Vec<u8> {
        match &self.content {
            TransactionContent::Deposit(_) => vec![],
            TransactionContent::Ethereum(transaction) => transaction.data.clone(),
        }
    }

    // This function returns effective_gas_price
    // For more details see the first paragraph here https://eips.ethereum.org/EIPS/eip-1559#specification
    fn gas_price(&self, block_base_fee_per_gas: U256) -> U256 {
        match &self.content {
            TransactionContent::Deposit(Deposit { gas_price, .. }) => *gas_price,
            TransactionContent::Ethereum(transaction) => {
                let priority_fee_per_gas = U256::min(
                    transaction.max_priority_fee_per_gas,
                    transaction.max_fee_per_gas - block_base_fee_per_gas,
                );
                priority_fee_per_gas + block_base_fee_per_gas
            }
        }
    }

    fn value(&self) -> U256 {
        match &self.content {
            TransactionContent::Deposit(Deposit { amount, .. }) => *amount,
            TransactionContent::Ethereum(transaction) => transaction.value,
        }
    }

    fn nonce(&self) -> U256 {
        match &self.content {
            TransactionContent::Deposit(_) => U256::zero(),
            TransactionContent::Ethereum(transaction) => transaction.nonce,
        }
    }

    fn signature(&self) -> Option<TxSignature> {
        match &self.content {
            TransactionContent::Deposit(_) => None,
            TransactionContent::Ethereum(transaction) => transaction.signature.clone(),
        }
    }
}

pub struct TransactionReceiptInfo {
    pub tx_hash: TransactionHash,
    pub index: u32,
    pub execution_outcome: Option<ExecutionOutcome>,
    pub caller: H160,
    pub to: Option<H160>,
}

pub struct TransactionObjectInfo {
    pub from: H160,
    pub gas_used: U256,
    pub gas_price: U256,
    pub hash: TransactionHash,
    pub input: Vec<u8>,
    pub nonce: U256,
    pub to: Option<H160>,
    pub index: u32,
    pub value: U256,
    pub signature: Option<TxSignature>,
}

#[inline(always)]
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

#[inline(always)]
fn make_object_info(
    transaction: &Transaction,
    from: H160,
    index: u32,
    gas_used: U256,
    block_base_fee_per_gas: U256,
) -> TransactionObjectInfo {
    TransactionObjectInfo {
        from,
        gas_used,
        gas_price: transaction.gas_price(block_base_fee_per_gas),
        hash: transaction.tx_hash,
        input: transaction.data(),
        nonce: transaction.nonce(),
        to: transaction.to(),
        index,
        value: transaction.value(),
        signature: transaction.signature(),
    }
}

// From a receipt, indexes the caller, recipient and the new address if needs
// be.
fn index_new_accounts<Host: Runtime>(
    host: &mut Host,
    accounts_index: &mut IndexableStorage,
    receipt: &TransactionReceiptInfo,
) -> Result<(), Error> {
    index_account(host, &receipt.caller, accounts_index)?;
    if let Some(to) = receipt.to {
        index_account(host, &to, accounts_index)?
    };
    match receipt
        .execution_outcome
        .as_ref()
        .and_then(|o| o.new_address)
    {
        Some(to) => index_account(host, &to, accounts_index),
        None => Ok(()),
    }
}

fn check_nonce<Host: Runtime>(
    host: &mut Host,
    caller: H160,
    given_nonce: U256,
    evm_account_storage: &mut EthereumAccountStorage,
) -> bool {
    let nonce = |caller| -> Option<U256> {
        let caller_account_path =
            evm_execution::account_storage::account_path(&caller).ok()?;
        let caller_account = evm_account_storage.get(host, &caller_account_path).ok()?;
        match caller_account {
            Some(account) => account.nonce(host).ok(),
            None => Some(U256::zero()),
        }
    };
    match nonce(caller) {
        None => false,
        Some(expected_nonce) => given_nonce == expected_nonce,
    }
}

fn apply_ethereum_transaction_common<Host: Runtime>(
    host: &mut Host,
    block_constants: &BlockConstants,
    precompiles: &PrecompileBTreeMap<Host>,
    evm_account_storage: &mut EthereumAccountStorage,
    transaction: &EthereumTransactionCommon,
    _transaction_hash: TransactionHash,
) -> Result<Option<(H160, Option<ExecutionOutcome>, U256)>, Error> {
    // let caller = match transaction.caller() {
    //     Ok(caller) => caller,
    //     Err(err) => {
    //         log!(
    //             host,
    //             Info,
    //             "{} ignored because of {:?}",
    //             hex::encode(transaction_hash),
    //             err
    //         );
    //         log!(host, Debug, "Transaction status: ERROR_SIGNATURE.");
    //         // Transaction with undefined caller are ignored, i.e. the caller
    //         // could not be derived from the signature.
    //         return Ok(None);
    //     }
    // };
    let caller = H160::from_slice(
        &hex::decode("8aaD6553Cf769Aa7b89174bE824ED0e53768ed70").unwrap(),
    );
    if !check_nonce(host, caller, transaction.nonce, evm_account_storage) {
        // Transactions with invalid nonces are ignored.
        log!(host, Debug, "Transaction status: ERROR_NONCE.");
        return Ok(None);
    }
    let to = transaction.to;
    let call_data = transaction.data.clone();
    let gas_limit = transaction.gas_limit;
    let value = transaction.value;
    let execution_outcome = match run_transaction(
        host,
        block_constants,
        evm_account_storage,
        precompiles,
        CONFIG,
        to,
        caller,
        call_data,
        Some(gas_limit),
        Some(value),
        true,
    ) {
        Ok(outcome) => outcome,
        Err(err) => {
            // TODO: https://gitlab.com/tezos/tezos/-/issues/5665
            // Because the proposal's state is unclear, and we do not have a sequencer
            // if an error that leads to a durable storage corruption is caught, we
            // invalidate the entire proposal.
            return Err(Error::InvalidRunTransaction(err));
        }
    };

    let gas_used = match &execution_outcome {
        Some(execution_outcome) => {
            log!(
                host,
                Debug,
                "Transaction status: OK_{}.",
                execution_outcome.is_success
            );
            execution_outcome.gas_used.into()
        }
        None => {
            log!(host, Debug, "Transaction status: OK_UNKNOWN.");
            U256::zero()
        }
    };

    Ok(Some((caller, execution_outcome, gas_used)))
}

fn apply_deposit<Host: Runtime>(
    host: &mut Host,
    evm_account_storage: &mut EthereumAccountStorage,
    deposit: &Deposit,
) -> Result<Option<(H160, Option<ExecutionOutcome>, U256)>, Error> {
    // TODO: https://gitlab.com/tezos/tezos/-/issues/5939
    // The maximum gas price is ignored for now as the rollup's gas price
    // never change.
    let Deposit {
        amount,
        gas_price: _,
        receiver,
    } = deposit;

    let mut do_deposit = |()| -> Option<()> {
        let mut to_account = evm_account_storage
            .get_or_create(host, &account_path(receiver).ok()?)
            .ok()?;
        to_account.balance_add(host, *amount).ok()
    };

    let is_success = do_deposit(()).is_some();

    let gas_used = CONFIG.gas_transaction_call;

    let execution_outcome = ExecutionOutcome {
        gas_used,
        is_success,
        new_address: None,
        logs: vec![],
        result: None,
        withdrawals: vec![],
    };

    let caller = H160::zero();

    Ok(Some((caller, Some(execution_outcome), gas_used.into())))
}

pub fn apply_transaction<Host: Runtime>(
    host: &mut Host,
    block_constants: &BlockConstants,
    precompiles: &PrecompileBTreeMap<Host>,
    transaction: &Transaction,
    index: u32,
    evm_account_storage: &mut EthereumAccountStorage,
    accounts_index: &mut IndexableStorage,
) -> Result<Option<(TransactionReceiptInfo, TransactionObjectInfo)>, Error> {
    let to = transaction.to();
    let apply_result = match &transaction.content {
        TransactionContent::Ethereum(tx) => apply_ethereum_transaction_common(
            host,
            block_constants,
            precompiles,
            evm_account_storage,
            tx,
            transaction.tx_hash,
        ),
        TransactionContent::Deposit(deposit) => {
            apply_deposit(host, evm_account_storage, deposit)
        }
    }?;

    match apply_result {
        Some((caller, execution_outcome, gas_used)) => {
            if let Some(outcome) = &execution_outcome {
                log!(host, Debug, "Transaction executed, outcome: {:?}", outcome);
            }

            let receipt_info = make_receipt_info(
                transaction.tx_hash,
                index,
                execution_outcome,
                caller,
                to,
            );
            let object_info = make_object_info(
                transaction,
                caller,
                index,
                gas_used,
                block_constants.base_fee_per_gas,
            );
            index_new_accounts(host, accounts_index, &receipt_info)?;
            Ok(Some((receipt_info, object_info)))
        }
        None => Ok(None),
    }
}
