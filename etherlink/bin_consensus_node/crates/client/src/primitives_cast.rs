// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use crate::proto;
use dsn_core::types::{PreBlock, PreBlockHeader, Transaction};

impl TryFrom<PreBlockHeader> for proto::PreBlockHeader {
    type Error = crate::RpcError;

    fn try_from(value: PreBlockHeader) -> Result<Self, Self::Error> {
        Ok(Self {
            id: value.id,
            metadata: bcs::to_bytes(&value.metadata)?,
        })
    }
}

impl From<proto::Transaction> for Transaction {
    fn from(value: proto::Transaction) -> Self {
        Self(value.transaction)
    }
}

impl From<Transaction> for proto::Transaction {
    fn from(value: Transaction) -> Self {
        Self {
            transaction: value.0,
        }
    }
}

impl TryFrom<PreBlock> for proto::PreBlock {
    type Error = crate::RpcError;

    fn try_from(value: PreBlock) -> Result<Self, Self::Error> {
        Ok(Self {
            header: Some(value.header.try_into()?),
            transactions: value.transactions.into_iter().map(|tx| tx.into()).collect(),
        })
    }
}
