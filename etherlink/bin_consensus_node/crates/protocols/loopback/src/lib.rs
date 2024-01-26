// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

//! Loopback ordering protocol

use async_trait::async_trait;
use dsn_api::PreBlocksApi;
use dsn_pre_block::{PreBlock, PreBlockHeader};
use tokio::sync::broadcast;

#[derive(Debug, thiserror::Error)]
pub enum Error {

}

pub struct LoopbackProtocol {

}

#[async_trait]
impl PreBlocksApi for LoopbackProtocol {
    type Error = crate::Error;

    async fn get_latest_pre_block_header(&self) -> Result<PreBlockHeader, Self::Error> {
        todo!()
    }

    async fn get_pre_block(&self, id: u64) -> Result<PreBlock, Self::Error> {
        todo!()
    }

    fn subscribe_pre_blocks(&self) -> Result<broadcast::Receiver<PreBlock>, Self::Error> {
        todo!()
    }
}
