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
use evm_execution::EthereumError::{
    EthereumAccountError, EthereumStorageError, InternalTrapError,
};
use primitive_types::{H160, H256, U256};
use tezos_ethereum::block::BlockConstants;
use tezos_ethereum::signatures::EthereumTransactionCommon;
use tezos_ethereum::transaction::TransactionHash;
use tezos_smart_rollup_debug::{debug_msg, Runtime};

use crate::error::Error;
use crate::inbox::{Deposit, Transaction, TransactionContent};

/// This defines the needed function to apply a transaction.
pub trait ReceiptMaker {
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

impl ReceiptMaker for EthereumTransactionCommon {
    fn chain_id(&self) -> U256 {
        self.chain_id
    }

    fn to(&self) -> Option<H160> {
        self.to
    }

    fn data(&self) -> Vec<u8> {
        self.data.clone()
    }

    fn gas_limit(&self) -> u64 {
        self.gas_limit
    }

    fn gas_price(&self) -> U256 {
        self.gas_price
    }

    fn value(&self) -> U256 {
        self.value
    }

    fn nonce(&self) -> U256 {
        self.nonce
    }

    fn v(&self) -> U256 {
        self.v
    }

    fn r(&self) -> H256 {
        self.r
    }

    fn s(&self) -> H256 {
        self.s
    }
}

impl ReceiptMaker for Deposit {
    fn chain_id(&self) -> U256 {
        crate::CHAIN_ID.into()
    }

    fn to(&self) -> Option<H160> {
        Some(self.receiver)
    }

    fn data(&self) -> Vec<u8> {
        vec![]
    }

    fn gas_limit(&self) -> u64 {
        // TODO: https://gitlab.com/tezos/tezos/-/issues/5936
        // Gas limit for deposit is the same as gas used.
        21_000u64
    }

    fn gas_price(&self) -> U256 {
        self.gas_price
    }

    fn value(&self) -> U256 {
        self.amount
    }

    fn nonce(&self) -> U256 {
        U256::zero()
    }

    fn v(&self) -> U256 {
        U256::zero()
    }

    fn r(&self) -> H256 {
        H256::zero()
    }

    fn s(&self) -> H256 {
        H256::zero()
    }
}

// This implementation simply statically dispatch between variants of
// TransactionContent. This boilerplate code is unfortunately necessary
// to improve the performances.
impl ReceiptMaker for TransactionContent {
    fn chain_id(&self) -> U256 {
        match self {
            Self::Deposit(deposit) => deposit.chain_id(),
            Self::Ethereum(transaction) => transaction.chain_id(),
        }
    }

    fn to(&self) -> Option<H160> {
        match self {
            Self::Deposit(deposit) => deposit.to(),
            Self::Ethereum(transaction) => transaction.to(),
        }
    }

    fn data(&self) -> Vec<u8> {
        match self {
            Self::Deposit(deposit) => deposit.data(),
            Self::Ethereum(transaction) => transaction.data(),
        }
    }

    fn gas_limit(&self) -> u64 {
        match self {
            Self::Deposit(deposit) => deposit.gas_limit(),
            Self::Ethereum(transaction) => transaction.gas_limit(),
        }
    }

    fn gas_price(&self) -> U256 {
        match self {
            Self::Deposit(deposit) => deposit.gas_price(),
            Self::Ethereum(transaction) => transaction.gas_price(),
        }
    }

    fn value(&self) -> U256 {
        match self {
            Self::Deposit(deposit) => deposit.value(),
            Self::Ethereum(transaction) => transaction.value(),
        }
    }

    fn nonce(&self) -> U256 {
        match self {
            Self::Deposit(deposit) => deposit.nonce(),
            Self::Ethereum(transaction) => transaction.nonce(),
        }
    }

    fn v(&self) -> U256 {
        match self {
            Self::Deposit(deposit) => deposit.v(),
            Self::Ethereum(transaction) => transaction.v(),
        }
    }

    fn r(&self) -> H256 {
        match self {
            Self::Deposit(deposit) => deposit.r(),
            Self::Ethereum(transaction) => transaction.r(),
        }
    }

    fn s(&self) -> H256 {
        match self {
            Self::Deposit(deposit) => deposit.s(),
            Self::Ethereum(transaction) => transaction.s(),
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
    transaction: impl ReceiptMaker,
    transaction_hash: TransactionHash,
    from: H160,
    index: u32,
    gas_used: U256,
) -> TransactionObjectInfo {
    TransactionObjectInfo {
        from,
        gas_used,
        gas_price: transaction.gas_price(),
        hash: transaction_hash,
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
    transaction: EthereumTransactionCommon,
    transaction_hash: TransactionHash,
    index: u32,
) -> Result<Option<(TransactionReceiptInfo, TransactionObjectInfo)>, Error> {
    let caller = match transaction.caller() {
        Ok(caller) => caller,
        Err(err) => {
            debug_msg!(
                host,
                "{} ignored because of {:?}\n",
                hex::encode(transaction_hash),
                err
            );
            // Transaction with undefined caller are ignored, i.e. the caller
            // could not be derived from the signature.
            return Ok(None);
        }
    };
    if !check_nonce(host, caller, transaction.nonce(), evm_account_storage) {
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
        make_receipt_info(transaction_hash, index, execution_outcome, caller, to);
    let object_info =
        make_object_info(transaction, transaction_hash, caller, index, gas_used);

    Ok(Some((receipt_info, object_info)))
}

fn apply_deposit<Host: Runtime>(
    host: &mut Host,
    evm_account_storage: &mut EthereumAccountStorage,
    deposit: Deposit,
    transaction_hash: TransactionHash,
    index: u32,
) -> Result<Option<(TransactionReceiptInfo, TransactionObjectInfo)>, Error> {
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
            .get_or_create(host, &account_path(&receiver).ok()?)
            .ok()?;
        to_account.balance_add(host, amount).ok()
    };

    let is_success = do_deposit(()).is_some();
    let gas_used = if is_success {
        // TODO: https://gitlab.com/tezos/tezos/-/issues/5936
        // This is the same as the EvmHandler London configuration, but it
        // should be explicit.
        21_000u64
    } else {
        0u64
    };
    let execution_outcome = ExecutionOutcome {
        gas_used,
        is_success,
        new_address: None,
        logs: vec![],
        result: None,
    };

    let caller = H160::zero();
    let receipt_info = make_receipt_info(
        transaction_hash,
        index,
        Some(execution_outcome),
        caller,
        Some(receiver),
    );
    let object_info =
        make_object_info(deposit, transaction_hash, caller, index, gas_used.into());

    Ok(Some((receipt_info, object_info)))
}

pub fn apply_transaction<Host: Runtime>(
    host: &mut Host,
    block_constants: &BlockConstants,
    precompiles: &PrecompileBTreeMap<Host>,
    transaction: Transaction,
    index: u32,
    evm_account_storage: &mut EthereumAccountStorage,
) -> Result<Option<(TransactionReceiptInfo, TransactionObjectInfo)>, Error> {
    match transaction.content {
        TransactionContent::Ethereum(tx) => apply_ethereum_transaction_common(
            host,
            block_constants,
            precompiles,
            evm_account_storage,
            tx,
            transaction.tx_hash,
            index,
        ),
        TransactionContent::Deposit(deposit) => apply_deposit(
            host,
            evm_account_storage,
            deposit,
            transaction.tx_hash,
            index,
        ),
    }
}
