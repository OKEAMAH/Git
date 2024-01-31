// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

//! DSN core types.

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Transaction(pub Vec<u8>);

#[derive(Debug, Default, Clone, Serialize, Deserialize)]
pub struct PreBlockMetadata {
    pub author: u16,
}

#[derive(Debug, Default, Clone, Serialize, Deserialize)]
pub struct PreBlockHeader {
    pub id: u64,
    pub metadata: PreBlockMetadata,
}

#[derive(Debug, Default, Clone, Serialize, Deserialize)]
pub struct PreBlock {
    pub header: PreBlockHeader,
    pub transactions: Vec<Transaction>,
}

impl Transaction {
    pub fn size(&self) -> usize {
        self.0.len()
    }
}
