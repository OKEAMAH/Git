// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use dsn_api::PreBlocksApi;
use futures::FutureExt;
use std::net::SocketAddr;
use std::sync::Arc;
use tokio::sync::broadcast;
use tonic::transport::Server;

use crate::pre_blocks_service::PreBlocksService;
use crate::proto::pre_blocks_server::PreBlocksServer;

#[derive(Debug)]
pub struct RpcServer<Client: PreBlocksApi> {
    addr: SocketAddr,
    client: Arc<Client>,
    rx_shutdown: broadcast::Receiver<()>,
}

impl<Client: PreBlocksApi> RpcServer<Client> {
    pub fn new(addr: SocketAddr, client: Arc<Client>, rx_shutdown: broadcast::Receiver<()>) -> Self {
        Self {
            addr,
            client,
            rx_shutdown,
        }
    }

    async fn run(&mut self) -> Result<(), Box<tonic::transport::Error>> {
        let pre_blocks_service = Arc::new(PreBlocksService::new(self.client.clone()));
        let signal = self.rx_shutdown.recv().map(drop);

        Server::builder()
            .add_service(PreBlocksServer::from_arc(pre_blocks_service))
            .serve_with_shutdown(self.addr, signal)
            .await?;

        Ok(())
    }
}
