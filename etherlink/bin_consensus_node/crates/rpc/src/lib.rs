// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

//! DSN RPC server.

pub mod proto {
    tonic::include_proto!("dsn");
}

pub mod error;
pub mod rpc_server;

mod dsn_service;
mod live_query;
mod primitives_cast;

use dsn_core::api::DsnApi;
pub use error::RpcError;
use serde::{Deserialize, Serialize};
use tokio::sync::broadcast;

pub type Result<T> = std::result::Result<T, error::RpcError>;

pub const DEFAULT_RPC_SERVER_HOST: &str = "127.0.0.1";
pub const DEFAULT_RPC_SERVER_PORT: u16 = 8998;

#[derive(Debug)]
pub struct RpcServer<Client: DsnApi> {
    config: RpcConfig,
    client: Client,
    rx_shutdown: broadcast::Receiver<()>,
}

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
