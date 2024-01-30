// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

//! DSN client

pub mod proto {
    tonic::include_proto!("ordering");
}

pub mod pre_blocks_service;
pub mod primitives_cast;
pub mod rpc_server;
pub mod transactions_service;

pub mod error;
pub use error::RpcError;
pub type Result<T> = std::result::Result<T, error::RpcError>;
