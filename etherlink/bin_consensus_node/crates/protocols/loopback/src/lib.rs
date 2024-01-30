// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

//! Loopback protocol

pub mod client;
pub mod error;
pub mod runner;
mod state;

use std::sync::Arc;

use dsn_core::{
    storage::StorageBackend,
    types::{PreBlock, Transaction},
};
use serde::{Deserialize, Serialize};
use state::LoopbackState;
use tokio::sync::{broadcast, mpsc};

pub const DEFAULT_COMMIT_DELAY_MS: u64 = 500;
pub const DEFAUT_MAX_PRE_BLOCK_TXS_COUNT: usize = 200;
pub const DEFAUT_MAX_PRE_BLOCK_TXS_SIZE: usize = 86400;
pub const PRE_BLOCKS_CHANNEL_CAPACITY: usize = 128;
pub const MEMPOOL_CHANNEL_CAPACITY: usize = 1024;

#[derive(Debug)]
pub struct LoopbackRunner<S: StorageBackend> {
    state: LoopbackState<S>,
    tx_pre_blocks: broadcast::Sender<PreBlock>,
    rx_mempool: mpsc::Receiver<Transaction>,
    rx_shutdown: broadcast::Receiver<()>,
    config: LoopbackConfig,
}

#[derive(Debug)]
pub struct LoopbackClient<S: StorageBackend> {
    state: LoopbackState<S>,
    rx_pre_blocks: broadcast::Receiver<PreBlock>,
    tx_mempool: mpsc::Sender<Transaction>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct LoopbackConfig {
    pub commit_delay_ms: u64,
    pub max_pre_block_txs_count: usize,
    pub max_pre_block_txs_size: usize,
}

impl Default for LoopbackConfig {
    fn default() -> Self {
        Self {
            commit_delay_ms: DEFAULT_COMMIT_DELAY_MS,
            max_pre_block_txs_count: DEFAUT_MAX_PRE_BLOCK_TXS_COUNT,
            max_pre_block_txs_size: DEFAUT_MAX_PRE_BLOCK_TXS_SIZE,
        }
    }
}

pub fn loopback<S: StorageBackend>(
    storage: Arc<S>,
    config: LoopbackConfig,
    rx_shutdown: broadcast::Receiver<()>,
) -> (LoopbackRunner<S>, LoopbackClient<S>) {
    let (tx_mempool, rx_mempool) = mpsc::channel(MEMPOOL_CHANNEL_CAPACITY);
    let (tx_pre_blocks, rx_pre_blocks) = broadcast::channel(PRE_BLOCKS_CHANNEL_CAPACITY);

    let state = LoopbackState::new(storage);

    let runner = LoopbackRunner::new(
        state.clone(),
        tx_pre_blocks,
        rx_mempool,
        rx_shutdown,
        config,
    );

    let client = LoopbackClient::new(state, rx_pre_blocks, tx_mempool);

    (runner, client)
}
