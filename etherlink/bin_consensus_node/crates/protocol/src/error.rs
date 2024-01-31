// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

//! Protocol specific errors.

use dsn_core::{api::ApiError, storage::StorageError, types::Transaction};
use tokio::sync::mpsc;

#[derive(Debug, thiserror::Error)]
pub enum ProtocolError {
    #[error("Failed to send transaction: {0}")]
    TransactionSend(#[from] mpsc::error::SendError<Transaction>),

    #[error("Storage backend error: {0}")]
    StorageBackend(#[from] StorageError),

    #[error("BCS encoding error: {0}")]
    BcsEncoding(#[from] bcs::Error),

    #[error("Latest pre-block header not found")]
    MissingPreBlockHead,

    #[error("Pre-block #{0} not found")]
    PreBlockNotFound(u64),
}

impl From<ProtocolError> for ApiError {
    fn from(value: ProtocolError) -> Self {
        match value {
            ProtocolError::PreBlockNotFound(_) => Self::ItemNotFound,
            err => Self::Internal(Box::new(err)),
        }
    }
}
