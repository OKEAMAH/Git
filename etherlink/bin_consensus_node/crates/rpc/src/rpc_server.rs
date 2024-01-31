// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use dsn_core::api::{PreBlocksApi, TransactionsApi};
use futures::FutureExt;
use log::{error, info};
use std::sync::Arc;
use tokio::sync::broadcast;
use tonic::transport::Server;

use crate::pre_blocks_service::PreBlocksService;
use crate::proto::pre_blocks_server::PreBlocksServer;
use crate::proto::transactions_server::TransactionsServer;
use crate::transactions_service::TransactionsService;
use crate::{RpcConfig, RpcError, RpcServer};

impl<Client: PreBlocksApi + TransactionsApi> RpcServer<Client> {
    pub fn new(client: Client, config: RpcConfig, rx_shutdown: broadcast::Receiver<()>) -> Self {
        Self {
            client,
            config,
            rx_shutdown,
        }
    }

    async fn run_inner(&mut self) -> Result<(), RpcError> {
        let addr = format!("{}:{}", self.config.host, self.config.port).parse()?;
        info!("Starting RPC server on {}", addr);

        let pre_blocks_service = Arc::new(PreBlocksService::new(self.client.clone()));
        let transactions_service = Arc::new(TransactionsService::new(self.client.clone()));

        let signal = self.rx_shutdown.recv().map(drop);

        Server::builder()
            .add_service(PreBlocksServer::from_arc(pre_blocks_service))
            .add_service(TransactionsServer::from_arc(transactions_service))
            .serve_with_shutdown(addr, signal)
            .await?;

        Ok(())
    }

    pub async fn run(&mut self) -> Result<(), ()> {
        match self.run_inner().await {
            Err(err) => {
                error!("RPC server failed with {}", err);
                Err(())
            }
            Ok(()) => {
                info!("RPC server terminated");
                Ok(())
            }
        }
    }
}
