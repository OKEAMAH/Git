// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

#[derive(Debug, thiserror::Error)]
pub enum RpcError {
    #[error(transparent)]
    BcsEncodingError(#[from] bcs::Error),

    #[error(transparent)]
    TonicTransport(#[from] tonic::transport::Error),

    #[error(transparent)]
    AddrParse(#[from] std::net::AddrParseError),

    #[error("Pre-block client error: {0}")]
    PreBlocksClientError(#[source] Box<dyn std::error::Error>),
}

impl From<RpcError> for tonic::Status {
    fn from(value: RpcError) -> Self {
        tonic::Status::internal(value.to_string())
    }
}
