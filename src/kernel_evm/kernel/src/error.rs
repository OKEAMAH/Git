// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
// SPDX-FileCopyrightText: 2023 Functori <contact@functori.com>
// SPDX-FileCopyrightText: 2023 Trilitech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT
use core::str::Utf8Error;
use evm_execution::EthereumError;
use primitive_types::U256;
use rlp::DecoderError;
use tezos_ethereum::signatures::SigError;
use tezos_smart_rollup_host::path::{OwnedPath, PathError};
use tezos_smart_rollup_host::runtime::RuntimeError;

#[derive(Debug)]
pub enum TransferError {
    InvalidCallerAddress,
    InvalidSignature,
    InvalidNonce { expected: U256, actual: U256 },
    NotEnoughBalance,
    CumulativeGasUsedOverflow,
    InvalidAddressFormat(Utf8Error),
}

#[derive(Debug)]
pub enum StorageError {
    Path(PathError),
    Runtime(RuntimeError),
    AccountInitialisation,
    GenesisAccountInitialisation,
    InvalidLoadValue { expected: usize, actual: usize },
    InvalidEncoding { path: OwnedPath, value: Vec<u8> },
}

#[derive(Debug)]
pub enum UpgradeProcessError {
    InvalidUpgradeNonce,
    ConfigSerialisation(tezos_data_encoding::enc::BinError),
}

#[derive(Debug)]
pub enum Error {
    Transfer(TransferError),
    Storage(StorageError),
    InvalidConversion,
    InvalidRunTransaction(EthereumError),
    Simulation(EthereumError),
    UpgradeError(UpgradeProcessError),
    InvalidSignature(SigError),
    InvalidSignatureCheck,
}

impl From<PathError> for Error {
    fn from(e: PathError) -> Self {
        Self::Storage(StorageError::Path(e))
    }
}
impl From<RuntimeError> for Error {
    fn from(e: RuntimeError) -> Self {
        Self::Storage(StorageError::Runtime(e))
    }
}

impl From<TransferError> for Error {
    fn from(e: TransferError) -> Self {
        Self::Transfer(e)
    }
}

impl From<DecoderError> for Error {
    fn from(_: DecoderError) -> Self {
        Self::InvalidConversion
    }
}

impl From<UpgradeProcessError> for Error {
    fn from(e: UpgradeProcessError) -> Self {
        Self::UpgradeError(e)
    }
}
