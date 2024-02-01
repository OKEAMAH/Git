// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

//! DSN node entrypoint

pub mod shutdown;

use dsn_core::storage::ephemeral::EphemeralStorage;
use dsn_protocol::{protocol, ProtocolConfig};
use dsn_rpc::{RpcConfig, RpcServer};
use futures::future::try_join_all;
use log::{info, LevelFilter};

#[tokio::main]
async fn main() {
    env_logger::builder()
        .filter(None, LevelFilter::Debug)
        .init();

    info!("DSN node is launching...");

    let shutdown = shutdown::Shutdown::new();
    let storage = EphemeralStorage::default();

    let proto_cfg = ProtocolConfig::default();
    let (mut proto_runner, proto_client) = protocol(storage, proto_cfg, shutdown.subscribe());

    let rpc_cfg = RpcConfig::default();
    let mut rpc_server = RpcServer::new(proto_client, rpc_cfg, shutdown.subscribe());

    let proto_handle = tokio::spawn(async move { proto_runner.run().await });
    let rpc_handle = tokio::spawn(async move { rpc_server.run().await });
    let shutdown_handle = tokio::spawn(async move { shutdown.run().await });

    try_join_all([proto_handle, rpc_handle, shutdown_handle])
        .await
        .unwrap();
}
