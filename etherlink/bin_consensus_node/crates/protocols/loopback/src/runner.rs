// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

//! Loopback protocol

use std::time::Duration;

use dsn_core::storage::StorageBackend;
use dsn_core::types::{PreBlock, PreBlockHeader, Transaction};
use log::{debug, info, warn};
use tokio::sync::{broadcast, mpsc};
use tokio::time::Instant;

use crate::error::LoopbackError;
use crate::state::LoopbackState;
use crate::{LoopbackConfig, LoopbackRunner};

impl<S: StorageBackend> LoopbackRunner<S> {
    pub fn new(
        state: LoopbackState<S>,
        tx_pre_blocks: broadcast::Sender<PreBlock>,
        rx_mempool: mpsc::Receiver<Transaction>,
        rx_shutdown: broadcast::Receiver<()>,
        config: LoopbackConfig,
    ) -> Self {
        Self {
            state,
            tx_pre_blocks,
            rx_mempool,
            rx_shutdown,
            config,
        }
    }

    pub async fn run(&mut self) -> Result<(), LoopbackError> {
        info!(
            "Starting loopback protocol with {} ms commit delay",
            self.config.commit_delay_ms
        );
        let timer_delay = Duration::from_millis(self.config.commit_delay_ms);
        let timer = tokio::time::sleep(timer_delay);
        tokio::pin!(timer);

        let mut pre_block_id = match self.state.get_head() {
            Ok(header) => header.id + 1,
            Err(LoopbackError::MissingPreBlockHead) => 0,
            Err(err) => return Err(err),
        };

        let mut transactions = Vec::with_capacity(self.config.max_pre_block_txs_count);
        let mut txs_count = 0;
        let mut txs_size = 0;

        loop {
            tokio::select! {
                Some(transaction) = self.rx_mempool.recv() => {
                    if txs_count >= self.config.max_pre_block_txs_count {
                        warn!("Transactions are getting delayed because of max count limit overflow");
                        tokio::task::yield_now().await;
                    } else if txs_size >= self.config.max_pre_block_txs_size {
                        warn!("Transactions are getting delayed because of max size limit overflow");
                        tokio::task::yield_now().await;
                    } else {
                        txs_count += 1;
                        txs_size += transaction.size();
                        transactions.push(transaction);
                    }
                },
                () = &mut timer => {
                    debug!("New pre-block #{pre_block_id}: {txs_count} txs of total size {txs_size} B");
                    let pre_block = PreBlock {
                        header: PreBlockHeader {
                            id: pre_block_id,
                            ..Default::default()
                        },
                        transactions: transactions.drain(..).collect(),
                    };

                    if self.tx_pre_blocks.send(pre_block.clone()).is_err() {
                        warn!("All pre-block subscribers are dropped (likely shutdown in progress)");
                        continue
                    }

                    self.state.update_head(pre_block)?;

                    pre_block_id += 1;
                    txs_count = 0;
                    txs_size = 0;

                    timer.as_mut().reset(Instant::now() + timer_delay);
                },
                _ = self.rx_shutdown.recv() => {
                    return Ok(())
                },
            }
        }
    }
}
