// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use dsn_core::api::DsnApi;
use futures::FutureExt;
use log::{error, info};
use std::sync::Arc;
use tokio::sync::broadcast;
use tonic::transport::Server;

use crate::dsn_service::DsnService;
use crate::proto::dsn_server::DsnServer;
use crate::{RpcConfig, RpcError, RpcServer};

impl<Client: DsnApi> RpcServer<Client> {
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

        let dsn_service = Arc::new(DsnService::new(self.client.clone()));
        let signal = self.rx_shutdown.recv().map(drop);

        Server::builder()
            .add_service(DsnServer::from_arc(dsn_service))
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
