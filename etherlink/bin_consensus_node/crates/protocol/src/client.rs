// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

//! Local protocol client.

use async_trait::async_trait;
use dsn_core::api::{ApiError, DsnApi};
use dsn_core::{
    storage::StorageBackend,
    types::{PreBlock, PreBlockHeader, Transaction},
};
use tokio::sync::{broadcast, mpsc};

use crate::error::ProtocolError;
use crate::{state::ProtocolState, ProtocolClient};

impl<S: StorageBackend> ProtocolClient<S> {
    pub fn new(
        state: ProtocolState<S>,
        rx_pre_blocks: broadcast::Receiver<PreBlock>,
        tx_mempool: mpsc::Sender<Transaction>,
    ) -> Self {
        Self {
            state,
            rx_pre_blocks,
            tx_mempool,
        }
    }
}

impl<S: StorageBackend> Clone for ProtocolClient<S> {
    fn clone(&self) -> Self {
        Self {
            state: self.state.clone(),
            rx_pre_blocks: self.rx_pre_blocks.resubscribe(),
            tx_mempool: self.tx_mempool.clone(),
        }
    }
}

#[async_trait]
impl<S: StorageBackend> DsnApi for ProtocolClient<S> {
    async fn submit_transaction(&self, transaction: Transaction) -> Result<(), ApiError> {
        self.tx_mempool
            .send(transaction)
            .await
            .map_err(Into::<ProtocolError>::into)
            .map_err(Into::into)
    }

    async fn get_pre_blocks_head(&self) -> Result<PreBlockHeader, ApiError> {
        match self.state.get_head() {
            Ok(value) => Ok(value),
            Err(ProtocolError::MissingPreBlockHead) => Err(ApiError::ItemNotFound),
            Err(err) => Err(err.into()),
        }
    }

    async fn get_pre_blocks(
        &self,
        from_id: u64,
        max_count: usize,
    ) -> Result<Vec<PreBlock>, ApiError> {
        self.state
            .get_pre_blocks(from_id, max_count)
            .map_err(Into::into)
    }

    async fn next_pre_block(&mut self) -> Result<PreBlock, ApiError> {
        self.rx_pre_blocks
            .recv()
            .await
            .map_err(|_| ApiError::ShutdownInProgress)
    }

    async fn clear_queue(&mut self) -> Result<(), ApiError> {
        self.rx_pre_blocks = self.rx_pre_blocks.resubscribe();
        Ok(())
    }
}
