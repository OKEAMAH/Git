// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

//! DSN API trait.
//!
//! These is the public interface that have to be implemented
//! by the local protocol clients.
//!
//! It allows to decouple remote clients (e.g. RPC users) from
//! the particular protocol, storage, network backends.

use crate::types::{PreBlock, PreBlockHeader, Transaction};
use async_trait::async_trait;

#[derive(Debug, thiserror::Error)]
pub enum ApiError {
    #[error("Internal API error: {0}")]
    Internal(#[source] Box<dyn std::error::Error>),

    #[error("Shutdown in progress")]
    ShutdownInProgress,

    #[error("Item not found")]
    ItemNotFound,
}

#[async_trait]
pub trait DsnApi: Clone + Sync + Send + 'static {
    async fn submit_transaction(&self, transaction: Transaction) -> Result<(), ApiError>;
    async fn get_pre_blocks_head(&self) -> Result<PreBlockHeader, ApiError>;
    async fn get_pre_blocks(
        &self,
        from_id: u64,
        max_count: usize,
    ) -> Result<Vec<PreBlock>, ApiError>;
    async fn next_pre_block(&mut self) -> Result<PreBlock, ApiError>;
    async fn clear_queue(&mut self) -> Result<(), ApiError>;
}
