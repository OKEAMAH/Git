// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error("BCS encoding error: {0}")]
    BcsEncodingError(#[from] bcs::Error),

    #[error("Pre-block client error: {0}")]
    PreBlocksClientError(#[source] Box<dyn std::error::Error>),
}

impl From<Error> for tonic::Status {
    fn from(value: Error) -> Self {
        tonic::Status::internal(value.to_string())
    }
}
