// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use dsn_core::{storage::StorageError, traits::ApiError, types::Transaction};
use tokio::sync::mpsc;

#[derive(Debug, thiserror::Error)]
pub enum LoopbackError {
    #[error("Failed to send transaction: {0}")]
    TransactionSend(#[from] mpsc::error::SendError<Transaction>),

    #[error("Storage backend error: {0}")]
    StorageBackend(#[from] StorageError),

    #[error("BCS encoding error: {0}")]
    BcsEncoding(#[from] bcs::Error),

    #[error("Latest pre-block header not found")]
    MissingPreBlockHead,
}

impl From<LoopbackError> for ApiError {
    fn from(value: LoopbackError) -> Self {
        Self::Internal(Box::new(value))
    }
}
