// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use async_trait::async_trait;
use dsn_core::api::DsnApi;
use tokio::sync::mpsc;
use tokio_stream::wrappers::ReceiverStream;
use tokio_stream::StreamExt;
use tonic::{Request, Response, Status, Streaming};

use crate::live_query::LiveQueryPreBlocks;
use crate::proto::{self, dsn_server};

#[derive(Debug)]
pub struct DsnService<Client: DsnApi> {
    client: Client,
}

impl<Client: DsnApi> DsnService<Client> {
    pub fn new(client: Client) -> Self {
        Self { client }
    }
}

#[async_trait]
impl<Client: DsnApi> dsn_server::Dsn for DsnService<Client> {
    type LiveQueryPreBlocksStream = ReceiverStream<Result<proto::PreBlock, Status>>;

    async fn get_pre_blocks_head(
        &self,
        _request: Request<proto::Empty>,
    ) -> tonic::Result<Response<proto::PreBlockHeader>, Status> {
        let header = self
            .client
            .get_pre_blocks_head()
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
            client: self.client.clone(),
        };

        tokio::spawn(async move { query.run().await });

        Ok(Response::new(ReceiverStream::new(rx)))
    }

    async fn submit_transaction(
        &self,
        request: Request<proto::Transaction>,
    ) -> Result<Response<proto::Empty>, Status> {
        self.client
            .submit_transaction(request.into_inner().into())
            .await
            .map_err(|e| Status::internal(e.to_string()))?;

        Ok(Response::new(proto::Empty {}))
    }

    async fn submit_transaction_stream(
        &self,
        request: Request<Streaming<proto::Transaction>>,
    ) -> Result<Response<proto::Empty>, Status> {
        let mut rx_transactions = request.into_inner();

        while let Some(res) = rx_transactions.next().await {
            match res {
                Ok(transaction) => {
                    self.client
                        .submit_transaction(transaction.into())
                        .await
                        .map_err(|e| Status::internal(e.to_string()))?;
                }
                Err(err) => {
                    // TODO: better handle client disconnect
                    return Err(err);
                }
            }
        }

        Ok(Response::new(proto::Empty {}))
    }
}
