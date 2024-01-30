// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

//! DSN node entrypoint

use std::sync::Arc;

use dsn_client::rpc_server::{RpcConfig, RpcServer};
use dsn_core::storage::ephemeral::EphemeralStorage;
use futures::future::try_join_all;
use log::{error, info};
use loopback::{loopback, LoopbackConfig};
use tokio::sync::broadcast;

#[tokio::main]
async fn main() {
    env_logger::init();
    info!("DSN node is launching...");

    let (tx_shutdown, _) = broadcast::channel(1);

    let storage = Arc::new(EphemeralStorage::default());
    let lp_cfg = LoopbackConfig::default();
    let (mut lp_runner, lp_client) = loopback(storage, lp_cfg, tx_shutdown.subscribe());

    let rpc_cfg = RpcConfig::default();
    let mut rpc_server = RpcServer::new(lp_client, rpc_cfg, tx_shutdown.subscribe());

    let lp_handle = tokio::spawn(async move {
        if let Err(err) = lp_runner.run().await {
            error!("Loopback runner failed with {}", err);
        }
    });

    let rpc_handle = tokio::spawn(async move {
        if let Err(err) = rpc_server.run().await {
            error!("RPC server failed with {}", err);
        }
    });

    try_join_all(vec![lp_handle, rpc_handle]).await.unwrap();
}
