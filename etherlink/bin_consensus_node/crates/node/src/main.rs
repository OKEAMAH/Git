// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

//! DSN node entrypoint

use std::sync::Arc;

use dsn_client::rpc_server::RpcServer;
use dsn_loopback::LoopbackProtocol;
use tokio::sync::broadcast;

#[tokio::main]
async fn main() {
    
    let (tx_shutdown, rx_shutdown) = broadcast::channel(1);

    let loopback = Arc::new(LoopbackProtocol {});

    let rpc_server = RpcServer::new(addr, loopback.clone(), rx_shutdown);

}
