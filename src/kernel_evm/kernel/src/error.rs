// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
// SPDX-FileCopyrightText: 2023 Functori <contact@functori.com>
//
// SPDX-License-Identifier: MIT
use core::str::Utf8Error;
use primitive_types::U256;
use rlp::DecoderError;
use tezos_smart_rollup_host::path::{OwnedPath, PathError};
use tezos_smart_rollup_host::runtime::RuntimeError;
use tezos_smart_rollup_storage::StorageError as TransactionalStorageError;

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
pub enum StorageCommitmentStatus {
    Begin(TransactionalStorageError),
    Commit(TransactionalStorageError),
    Rollback(TransactionalStorageError),
}

#[derive(Debug)]
pub enum StorageInitialisationError {
    Base(TransactionalStorageError),
    EVMBlockInit(TransactionalStorageError),
}

#[derive(Debug)]
pub enum StorageError {
    Path(PathError),
    Runtime(RuntimeError),
    AccountInitialisation,
    GenesisAccountInitialisation,
    StorageCommitment(StorageCommitmentStatus),
    StorageInitialisation(StorageInitialisationError),
    InvalidLoadValue { expected: usize, actual: usize },
    InvalidEncoding { path: OwnedPath, value: Vec<u8> },
}

#[derive(Debug)]
pub enum Error {
    Transfer(TransferError),
    Storage(StorageError),
    InvalidConversion,
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
