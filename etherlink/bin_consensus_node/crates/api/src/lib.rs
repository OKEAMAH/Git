// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

//! DSN API

use async_trait::async_trait;
use dsn_pre_block::{PreBlock, PreBlockHeader};
use tokio::sync::broadcast;

#[async_trait]
pub trait PreBlocksApi: Sync + Send + 'static {
    type Error: std::error::Error + Send + 'static;

    async fn get_latest_pre_block_header(&self) -> Result<PreBlockHeader, Self::Error>;
    async fn get_pre_block(&self, id: u64) -> Result<PreBlock, Self::Error>;
    fn subscribe_pre_blocks(&self) -> Result<broadcast::Receiver<PreBlock>, Self::Error>;
}
