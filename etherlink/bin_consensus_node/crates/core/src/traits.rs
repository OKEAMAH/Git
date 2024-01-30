// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use crate::types::{PreBlock, PreBlockHeader, Transaction};
use async_trait::async_trait;

#[derive(Debug, thiserror::Error)]
pub enum ApiError {
    #[error("Internal error: {0}")]
    Internal(#[source] Box<dyn std::error::Error>),

    #[error("Shutdown in progress")]
    Shutdown,

    #[error("Item not found")]
    NotFound,
}

#[async_trait]
pub trait PreBlocksApi: Clone + Sync + Send + 'static {
    async fn get_pre_blocks_head(&self) -> Result<PreBlockHeader, ApiError>;
    async fn get_pre_blocks(
        &self,
        from_id: u64,
        max_count: usize,
    ) -> Result<Vec<PreBlock>, ApiError>;
    async fn next_pre_block(&mut self) -> Result<PreBlock, ApiError>;
    async fn clear_queue(&mut self) -> Result<(), ApiError>;
}

#[async_trait]
pub trait TransactionsApi: Clone + Sync + Send + 'static {
    async fn submit_transaction(&self, transaction: Transaction) -> Result<(), ApiError>;
}
