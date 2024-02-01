// SPDX-FileCopyrightText: 2024 ParallelChain Lab
// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: Apache 2.0
// SPDX-License-Identifier: MIT

//! Storage backend abstraction.
//! Inspired by https://github.com/parallelchain-io/hotstuff_rs
//!
//! This is a convenient intermediate abstraction between typed app-specific stores
//! and raw storage backends (good fit for rocksdb, mdbx, lmdb).
//!
//! The key is that it doesn't try to be generic but optimizes for a scenario
//! when you have very few (single per scope) writers and multiple concurrent readers.
//!
//! This interface also restricts the way you can access the storage. You can either:
//!     1. Perform point-in-time reads (aka snapshot, aka read-only transaction)
//!     2. Do batch writes (multiple inserts and deletes)
//!
//! It is also assumed that the underlying backend supports logical sharding allowing
//! to perform scoped writes and reads (aka column families, aka tables, aka databases).
//!
//! Although this is blocking IO it should not be a problem for embedded storage backends.
//! Still if IO takes much time consider using `tokio::spawn_blocking` for such workloads.

pub mod ephemeral;

#[derive(Debug, thiserror::Error)]
pub enum StorageError {
    #[error("Internal storage error: {0}")]
    Internal(#[source] Box<dyn std::error::Error>),
}

pub trait Snapshot {
    fn get(&self, scope: &'static str, key: &[u8]) -> Result<Option<Vec<u8>>, StorageError>;
}

pub trait WriteBatch {
    fn insert(
        &mut self,
        scope: &'static str,
        key: &[u8],
        value: Vec<u8>,
    ) -> Result<(), StorageError>;
    fn remove(&mut self, scope: &'static str, key: &[u8]) -> Result<(), StorageError>;
}

pub trait StorageBackend: std::fmt::Debug + Send + Sync + Clone + 'static {
    type Snapshot<'a>: Snapshot + 'a;
    type WriteBatch: WriteBatch;

    fn snapshot<'b>(&'b self) -> Result<Self::Snapshot<'_>, StorageError>;
    fn batch(&self) -> Result<Self::WriteBatch, StorageError>;
    fn write(&mut self, batch: Self::WriteBatch) -> Result<(), StorageError>;
}
