// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use async_trait::async_trait;
use dsn_api::PreBlocksApi;
use dsn_pre_block::PreBlock;
use log::error;
use std::sync::Arc;
use tokio::sync::{broadcast, mpsc};
use tokio_stream::wrappers::ReceiverStream;
use tonic::{Request, Response, Status};

use crate::proto::{self, pre_blocks_server};

#[derive(Debug)]
pub struct PreBlocksService<Client: PreBlocksApi> {
    client: Arc<Client>,
}

impl<Client: PreBlocksApi> PreBlocksService<Client> {
    pub fn new(client: Arc<Client>) -> Self {
        Self { client }
    }
}

#[async_trait]
impl<Client: PreBlocksApi> pre_blocks_server::PreBlocks for PreBlocksService<Client> {
    type LiveQueryPreBlocksStream = ReceiverStream<Result<proto::PreBlock, Status>>;

    async fn get_latest_pre_block_header(
        &self,
        _request: Request<proto::Empty>,
    ) -> tonic::Result<Response<proto::PreBlockHeader>, Status> {
        let header = self
            .client
            .get_latest_pre_block_header()
            .await
            .map_err(|e| Status::internal(e.to_string()))?;
        Ok(Response::new(header.try_into()?))
    }

    async fn live_query_pre_blocks(
        &self,
        request: Request<proto::PreBlocksRequest>,
    ) -> tonic::Result<Response<Self::LiveQueryPreBlocksStream>> {
        let (tx, rx) = mpsc::channel(128);
        let mut query = LiveQueryPreBlocks {
            from_id: request.into_inner().from_id,
            tx_results: tx,
            rx_updates: self
                .client
                .subscribe_pre_blocks()
                .map_err(|e| Status::internal(e.to_string()))?,
            client: self.client.clone(),
        };

        tokio::spawn(async move { query.run().await });

        Ok(Response::new(ReceiverStream::new(rx)))
    }
}

#[derive(Debug)]
struct LiveQueryPreBlocks<Client: PreBlocksApi> {
    pub from_id: u64,
    pub client: Arc<Client>,
    pub rx_updates: broadcast::Receiver<PreBlock>,
    pub tx_results: mpsc::Sender<Result<proto::PreBlock, Status>>,
}

impl<Client: PreBlocksApi> LiveQueryPreBlocks<Client> {
    async fn send(&self, pre_block: PreBlock) -> Result<(), Status> {
        let result: proto::PreBlock = pre_block.try_into()?;
        self.tx_results
            .send(Ok(result))
            .await
            .map_err(|_| Status::aborted("client disconnected"))
    }

    async fn run_inner(&mut self) -> Result<(), Status> {
        let header = self
            .client
            .get_latest_pre_block_header()
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        let mut next_id = self.from_id;

        while next_id < header.id {
            let pre_block = self
                .client
                .get_pre_block(next_id)
                .await
                .map_err(|e| Status::internal(e.to_string()))?;

            self.send(pre_block).await?;
            next_id += 1;
        }

        while let Ok(pre_block) = self.rx_updates.recv().await {
            if pre_block.header.id < next_id {
                continue;
            }
            if pre_block.header.id > next_id {
                return Err(Status::internal("Non-sequential pre-block stream"));
            }

            self.send(pre_block).await?;
            next_id += 1;
        }

        Err(Status::internal("pre-block stream is closed / lagged"))
    }

    pub async fn run(&mut self) {
        if let Err(err) = self.run_inner().await {
            error!("Live query failed with: {}", err);
            if !self.tx_results.is_closed() {
                let _ = self.tx_results.send(Err(err)).await;
            }
        }
    }
}
