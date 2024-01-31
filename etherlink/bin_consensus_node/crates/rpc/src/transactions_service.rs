// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use async_trait::async_trait;
use dsn_core::api::TransactionsApi;
use tokio_stream::StreamExt;
use tonic::{Request, Response, Status, Streaming};

use crate::proto::{self, transactions_server};

#[derive(Debug)]
pub struct TransactionsService<Client: TransactionsApi> {
    client: Client,
}

impl<Client: TransactionsApi> TransactionsService<Client> {
    pub fn new(client: Client) -> Self {
        Self { client }
    }
}

#[async_trait]
impl<Client: TransactionsApi> transactions_server::Transactions for TransactionsService<Client> {
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
