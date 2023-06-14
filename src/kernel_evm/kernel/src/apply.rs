// SPDX-FileCopyrightText: 2023 Marigold <contact@marigold.dev>
// SPDX-FileCopyrightText: 2023 Functori <contact@functori.com>
// SPDX-FileCopyrightText: 2022-2023 TriliTech <contact@trili.tech>
// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
//
// SPDX-License-Identifier: MIT

use evm_execution::account_storage::EthereumAccountStorage;
use evm_execution::handler::ExecutionOutcome;
use evm_execution::precompiles::PrecompileBTreeMap;
use evm_execution::run_transaction;
use evm_execution::EthereumError::{
    EthereumAccountError, EthereumStorageError, InternalTrapError,
};
use primitive_types::{H160, H256, U256};
use tezos_ethereum::block::BlockConstants;
use tezos_ethereum::transaction::TransactionHash;
use tezos_smart_rollup_debug::Runtime;

use crate::error::{Error, TransferError};
use crate::inbox::{Transaction, TransactionContent};

pub trait ApplyTransaction {
    fn caller(&self) -> Result<H160, Error>;

    fn check_nonce<Host: Runtime>(
        &self,
        caller: H160,
        host: &mut Host,
        evm_account_storage: &mut EthereumAccountStorage,
    ) -> bool;

    fn chain_id(&self) -> U256;

    fn to(&self) -> Option<H160>;

    fn data(&self) -> Vec<u8>;

    fn gas_limit(&self) -> u64;

    fn gas_price(&self) -> U256;

    fn value(&self) -> U256;

    fn nonce(&self) -> U256;

    fn v(&self) -> U256;

    fn r(&self) -> H256;

    fn s(&self) -> H256;
}

fn check_nonce_of_caller<Host: Runtime>(
    caller: H160,
    host: &mut Host,
    evm_account_storage: &mut EthereumAccountStorage,
    given_nonce: U256,
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

impl ApplyTransaction for Transaction {
    fn caller(&self) -> Result<H160, Error> {
        match &self.content {
            TransactionContent::Ethereum(transaction) => transaction
                .caller()
                .map_err(|_| Error::Transfer(TransferError::InvalidCallerAddress)),
            TransactionContent::Deposit { .. } => {
                // TODO: Est-ce que H160::zero() ou bien une adresse infiniment remplie?"
                Ok(H160::zero())
            }
        }
    }

    fn check_nonce<Host: Runtime>(
        &self,
        caller: H160,
        host: &mut Host,
        evm_account_storage: &mut EthereumAccountStorage,
    ) -> bool {
        match &self.content {
            TransactionContent::Ethereum(transaction) => check_nonce_of_caller(
                caller,
                host,
                evm_account_storage,
                transaction.nonce,
            ),
            TransactionContent::Deposit { .. } => true,
        }
    }

    fn chain_id(&self) -> U256 {
        match &self.content {
            TransactionContent::Ethereum(transaction) => transaction.chain_id,
            TransactionContent::Deposit { .. } => crate::CHAIN_ID.into(),
        }
    }

    fn to(&self) -> Option<H160> {
        match &self.content {
            TransactionContent::Ethereum(transaction) => transaction.to,
            TransactionContent::Deposit { receiver, .. } => Some(*receiver),
        }
    }

    fn data(&self) -> Vec<u8> {
        match &self.content {
            TransactionContent::Ethereum(transaction) => transaction.data.clone(),
            TransactionContent::Deposit { .. } => vec![],
        }
    }

    fn gas_limit(&self) -> u64 {
        match &self.content {
            TransactionContent::Ethereum(transaction) => transaction.gas_limit,
            TransactionContent::Deposit { .. } => {
                // TODO: le gas limit est constant, peut être juste mettre None
                21_000u64
            }
        }
    }

    fn gas_price(&self) -> U256 {
        match &self.content {
            TransactionContent::Ethereum(transaction) => transaction.gas_price,
            TransactionContent::Deposit { .. } => {
                // TODO: what should we put?
                U256::zero()
            }
        }
    }

    fn value(&self) -> U256 {
        match &self.content {
            TransactionContent::Ethereum(transaction) => transaction.value,
            TransactionContent::Deposit { amount, .. } => *amount,
        }
    }

    fn nonce(&self) -> U256 {
        match &self.content {
            TransactionContent::Ethereum(transaction) => transaction.nonce,
            TransactionContent::Deposit { .. } => {
                // todo: depends if we have a minter address?
                U256::zero()
            }
        }
    }

    fn v(&self) -> U256 {
        match &self.content {
            TransactionContent::Ethereum(transaction) => transaction.v,
            TransactionContent::Deposit { .. } => U256::zero(),
        }
    }

    fn r(&self) -> H256 {
        match &self.content {
            TransactionContent::Ethereum(transaction) => transaction.r,
            TransactionContent::Deposit { .. } => H256::zero(),
        }
    }

    fn s(&self) -> H256 {
        match &self.content {
            TransactionContent::Ethereum(transaction) => transaction.s,
            TransactionContent::Deposit { .. } => H256::zero(),
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
    pub v: U256,
    pub r: H256,
    pub s: H256,
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
    transaction: Transaction,
    from: H160,
    index: u32,
    gas_used: U256,
) -> TransactionObjectInfo {
    TransactionObjectInfo {
        from,
        gas_used,
        gas_price: transaction.gas_price(),
        hash: transaction.tx_hash,
        input: transaction.data(),
        nonce: transaction.nonce(),
        to: transaction.to(),
        index,
        value: transaction.value(),
        v: transaction.v(),
        r: transaction.r(),
        s: transaction.s(),
    }
}

pub fn apply_transaction<Host: Runtime>(
    host: &mut Host,
    block_constants: &BlockConstants,
    precompiles: &PrecompileBTreeMap<Host>,
    transaction: Transaction,
    index: u32,
    evm_account_storage: &mut EthereumAccountStorage,
) -> Result<Option<(TransactionReceiptInfo, TransactionObjectInfo)>, Error> {
    let caller = transaction.caller()?;
    if !transaction.check_nonce(caller, host, evm_account_storage) {
        // Transactions with invalid nonces are ignored.
        return Ok(None);
    }
    let to = transaction.to();
    let call_data = transaction.data();
    let gas_limit = transaction.gas_limit();
    let value = transaction.value();
    let execution_outcome = match run_transaction(
        host,
        block_constants,
        evm_account_storage,
        precompiles,
        to,
        caller,
        call_data,
        Some(gas_limit),
        Some(value),
    ) {
        Ok(outcome) => Some(outcome),
        Err(InternalTrapError | EthereumAccountError(_) | EthereumStorageError(_)) => {
            // TODO: https://gitlab.com/tezos/tezos/-/issues/5665
            // Because the proposal's state is unclear, and we do not have a sequencer
            // if an error that leads to a durable storage corruption is caught, we
            // invalidate the entire proposal.
            return Err(Error::InvalidRunTransaction);
        }
        Err(_) => None,
    };

    let gas_used = match &execution_outcome {
        Some(execution_outcome) => execution_outcome.gas_used.into(),
        None => U256::zero(),
    };

    let receipt_info =
        make_receipt_info(transaction.tx_hash, index, execution_outcome, caller, to);
    let object_info = make_object_info(transaction, caller, index, gas_used);

    Ok(Some((receipt_info, object_info)))
}
