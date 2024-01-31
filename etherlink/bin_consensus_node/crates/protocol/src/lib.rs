// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

//! DSN protocol.
//! 
//! Currently implements a single node "echo" consensus that aggregates
//! incoming transactions into pre-blocks on regular time intervals.

pub mod client;
pub mod error;
pub mod runner;
mod state;

use dsn_core::{
    storage::StorageBackend,
    types::{PreBlock, Transaction},
};
use serde::{Deserialize, Serialize};
use state::ProtocolState;
use tokio::sync::{broadcast, mpsc};

pub const DEFAULT_COMMIT_DELAY_MS: u64 = 500;
pub const DEFAUT_MAX_PRE_BLOCK_TXS_COUNT: usize = 200;
pub const DEFAUT_MAX_PRE_BLOCK_TXS_SIZE: usize = 86400;
pub const PRE_BLOCKS_CHANNEL_CAPACITY: usize = 128;
pub const MEMPOOL_CHANNEL_CAPACITY: usize = 1024;

#[derive(Debug)]
pub struct ProtocolRunner<S: StorageBackend> {
    state: ProtocolState<S>,
    tx_pre_blocks: broadcast::Sender<PreBlock>,
    rx_mempool: mpsc::Receiver<Transaction>,
    rx_shutdown: broadcast::Receiver<()>,
    config: ProtocolConfig,
}

#[derive(Debug)]
pub struct ProtocolClient<S: StorageBackend> {
    state: ProtocolState<S>,
    rx_pre_blocks: broadcast::Receiver<PreBlock>,
    tx_mempool: mpsc::Sender<Transaction>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ProtocolConfig {
    pub commit_delay_ms: u64,
    pub max_pre_block_txs_count: usize,
    pub max_pre_block_txs_size: usize,
}

impl Default for ProtocolConfig {
    fn default() -> Self {
        Self {
            commit_delay_ms: DEFAULT_COMMIT_DELAY_MS,
            max_pre_block_txs_count: DEFAUT_MAX_PRE_BLOCK_TXS_COUNT,
            max_pre_block_txs_size: DEFAUT_MAX_PRE_BLOCK_TXS_SIZE,
        }
    }
}

pub fn protocol<S: StorageBackend>(
    storage: S,
    config: ProtocolConfig,
    rx_shutdown: broadcast::Receiver<()>,
) -> (ProtocolRunner<S>, ProtocolClient<S>) {
    let (tx_mempool, rx_mempool) = mpsc::channel(MEMPOOL_CHANNEL_CAPACITY);
    let (tx_pre_blocks, rx_pre_blocks) = broadcast::channel(PRE_BLOCKS_CHANNEL_CAPACITY);

    let state = ProtocolState::new(storage);

    let runner = ProtocolRunner::new(
        state.clone(),
        tx_pre_blocks,
        rx_mempool,
        rx_shutdown,
        config,
    );

    let client = ProtocolClient::new(state, rx_pre_blocks, tx_mempool);

    (runner, client)
}
