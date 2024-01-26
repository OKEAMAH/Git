// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

//! Pre-block type

use dsn_transaction::Transaction;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PreBlockMetadata {
    pub author: u16,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PreBlockHeader {
    pub id: u64,
    pub metadata: PreBlockMetadata,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PreBlock {
    pub header: PreBlockHeader,
    pub transactions: Vec<Transaction>,
}
