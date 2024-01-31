// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

//! DSN protocol runner implementation.

use std::time::Duration;

use dsn_core::storage::StorageBackend;
use dsn_core::types::{PreBlock, PreBlockHeader, Transaction};
use log::{debug, error, info, warn};
use tokio::sync::{broadcast, mpsc};
use tokio::time::Instant;

use crate::error::ProtocolError;
use crate::state::ProtocolState;
use crate::{ProtocolConfig, ProtocolRunner};

impl<S: StorageBackend> ProtocolRunner<S> {
    pub fn new(
        state: ProtocolState<S>,
        tx_pre_blocks: broadcast::Sender<PreBlock>,
        rx_mempool: mpsc::Receiver<Transaction>,
        rx_shutdown: broadcast::Receiver<()>,
        config: ProtocolConfig,
    ) -> Self {
        Self {
            state,
            tx_pre_blocks,
            rx_mempool,
            rx_shutdown,
            config,
        }
    }

    async fn run_inner(&mut self) -> Result<(), ProtocolError> {
        info!(
            "Starting protocol runner with {} ms commit delay",
            self.config.commit_delay_ms
        );
        let timer_delay = Duration::from_millis(self.config.commit_delay_ms);
        let timer = tokio::time::sleep(timer_delay);
        tokio::pin!(timer);

        let mut pre_block_id = match self.state.get_head() {
            Ok(header) => header.id + 1,
            Err(ProtocolError::MissingPreBlockHead) => 0,
            Err(err) => return Err(err),
        };

        let mut transactions = Vec::with_capacity(self.config.max_pre_block_txs_count);
        let mut txs_count = 0;
        let mut txs_size = 0;

        loop {
            tokio::select! {
                Some(transaction) = self.rx_mempool.recv() => {
                    if txs_count >= self.config.max_pre_block_txs_count {
                        warn!("Transactions are getting delayed because of max count limit hit");
                        tokio::task::yield_now().await;
                    } else if txs_size >= self.config.max_pre_block_txs_size {
                        warn!("Transactions are getting delayed because of max size limit hit");
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
                        warn!("All pre-block subscribers are dropped (shutdown in progress?)");
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

    pub async fn run(&mut self) -> Result<(), ()> {
        match self.run_inner().await {
            Err(err) => {
                error!("Protocol runner failed with {}", err);
                Err(())
            }
            Ok(()) => {
                info!("Protocol runner terminated");
                Ok(())
            }
        }
    }
}
