// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use dsn_core::traits::{PreBlocksApi, TransactionsApi};
use futures::FutureExt;
use log::info;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tokio::sync::broadcast;
use tonic::transport::Server;

use crate::pre_blocks_service::PreBlocksService;
use crate::proto::pre_blocks_server::PreBlocksServer;
use crate::proto::transactions_server::TransactionsServer;
use crate::transactions_service::TransactionsService;
use crate::RpcError;

pub const DEFAULT_RPC_SERVER_HOST: &str = "127.0.0.1";
pub const DEFAULT_RPC_SERVER_PORT: u16 = 8998;

#[derive(Debug, Serialize, Deserialize)]
pub struct RpcConfig {
    host: String,
    port: u16,
}

impl Default for RpcConfig {
    fn default() -> Self {
        Self {
            host: DEFAULT_RPC_SERVER_HOST.into(),
            port: DEFAULT_RPC_SERVER_PORT,
        }
    }
}

#[derive(Debug)]
pub struct RpcServer<Client: PreBlocksApi> {
    config: RpcConfig,
    client: Client,
    rx_shutdown: broadcast::Receiver<()>,
}

impl<Client: PreBlocksApi + TransactionsApi> RpcServer<Client> {
    pub fn new(client: Client, config: RpcConfig, rx_shutdown: broadcast::Receiver<()>) -> Self {
        Self {
            client,
            config,
            rx_shutdown,
        }
    }

    pub async fn run(&mut self) -> Result<(), RpcError> {
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
}
