// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

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

pub trait StorageBackend: std::fmt::Debug + Send + Sync + 'static {
    type Snapshot: Snapshot;
    type WriteBatch: WriteBatch;

    fn snapshot(
        &self,
        scopes: impl IntoIterator<Item = &'static str>,
    ) -> Result<Self::Snapshot, StorageError>;
    fn batch(&self) -> Result<Self::WriteBatch, StorageError>;
    fn write(&self, batch: Self::WriteBatch) -> Result<(), StorageError>;
}
