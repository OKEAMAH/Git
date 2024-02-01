// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use dsn_core::api::DsnApi;
use dsn_core::types::PreBlock;
use log::error;
use tokio::sync::mpsc;
use tonic::Status;

use crate::proto;

#[derive(Debug)]
pub struct LiveQueryPreBlocks<Client: DsnApi> {
    pub from_id: u64,
    pub client: Client,
    pub tx_results: mpsc::Sender<Result<proto::PreBlock, Status>>,
}

impl<Client: DsnApi> LiveQueryPreBlocks<Client> {
    async fn send_pre_block(&self, pre_block: PreBlock) -> Result<(), Status> {
        let result: proto::PreBlock = pre_block.try_into()?;
        self.tx_results
            .send(Ok(result))
            .await
            .map_err(|_| Status::aborted("client disconnected"))
    }

    async fn inner_run(&mut self) -> Result<(), Status> {
        let mut next_id = self.from_id;
        let max_count = 1024;

        loop {
            let pre_blocks = self
                .client
                .get_pre_blocks(next_id, max_count)
                .await
                .map_err(|e| Status::internal(e.to_string()))?;

            let batch_len = pre_blocks.len();

            for pre_block in pre_blocks {
                self.send_pre_block(pre_block).await?;
            }

            next_id += batch_len as u64;

            if batch_len < max_count {
                break;
            } else {
                self.client
                    .clear_queue()
                    .await
                    .map_err(|e| Status::internal(e.to_string()))?;
            }
        }

        loop {
            let pre_block = self
                .client
                .next_pre_block()
                .await
                .map_err(|e| Status::internal(e.to_string()))?;

            if pre_block.header.id < next_id {
                continue;
            }
            if pre_block.header.id > next_id {
                return Err(Status::internal("Non-sequential pre-block stream"));
            }

            self.send_pre_block(pre_block).await?;
            next_id += 1;
        }
    }

    pub async fn run(&mut self) {
        if let Err(err) = self.inner_run().await {
            error!("Live query failed with: {}", err);
            if !self.tx_results.is_closed() {
                let _ = self.tx_results.send(Err(err)).await;
            }
        }
    }
}
