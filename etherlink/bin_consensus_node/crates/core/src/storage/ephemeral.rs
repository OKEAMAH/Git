// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

//! In-memory storage backend.
//! Non-persistent, inefficient, for testing purposes ONLY.

use std::{
    collections::HashMap,
    sync::{Arc, RwLock, RwLockReadGuard},
};

use super::{Snapshot, StorageBackend, StorageError, WriteBatch};

#[derive(Debug, thiserror::Error)]
pub enum EphemeralStorageError {
    #[error("Failed to acquire read lock")]
    AcquireReadLock,

    #[error("Failed to acquire write lock")]
    AcquireWriteLock,
}

impl From<EphemeralStorageError> for StorageError {
    fn from(value: EphemeralStorageError) -> Self {
        Self::Internal(Box::new(value))
    }
}

pub type InnerStore = HashMap<(&'static str, Vec<u8>), Vec<u8>>;

#[derive(Debug, Default, Clone)]
pub struct EphemeralStorage {
    data: Arc<RwLock<InnerStore>>,
}

#[derive(Debug)]
pub struct EphemeralSnapshot<'a> {
    data: RwLockReadGuard<'a, InnerStore>,
}

#[derive(Debug, Default)]
pub struct EphemeralWriteBatch {
    pub data: Vec<(&'static str, Vec<u8>, Option<Vec<u8>>)>,
}

impl StorageBackend for EphemeralStorage {
    type Snapshot<'a> = EphemeralSnapshot<'a>;
    type WriteBatch = EphemeralWriteBatch;

    // NOTE that although this implementation allows multiple concurrent
    // readers, a write lock cannot be acquired until all readers release.
    // Similarly no one can read until a write is in the process.
    fn snapshot<'b>(&'b self) -> Result<Self::Snapshot<'_>, StorageError> {
        Ok(EphemeralSnapshot::new(
            self.data
                .read()
                .map_err(|_| EphemeralStorageError::AcquireReadLock)?,
        ))
    }

    fn batch(&self) -> Result<Self::WriteBatch, StorageError> {
        Ok(EphemeralWriteBatch::default())
    }

    fn write(&mut self, batch: Self::WriteBatch) -> Result<(), StorageError> {
        let mut data = self
            .data
            .write()
            .map_err(|_| EphemeralStorageError::AcquireWriteLock)?;

        batch.data.into_iter().for_each(|(s, k, v)| {
            if let Some(v) = v {
                data.insert((s, k), v);
            } else {
                data.remove(&(s, k));
            }
        });

        Ok(())
    }
}

impl<'a> EphemeralSnapshot<'a> {
    pub fn new(data: RwLockReadGuard<'a, InnerStore>) -> Self {
        Self { data }
    }
}

impl<'a> Snapshot for EphemeralSnapshot<'a> {
    fn get(&self, scope: &'static str, key: &[u8]) -> Result<Option<Vec<u8>>, StorageError> {
        Ok(self.data.get(&(scope, key.to_vec())).cloned())
    }
}

impl WriteBatch for EphemeralWriteBatch {
    fn insert(
        &mut self,
        scope: &'static str,
        key: &[u8],
        value: Vec<u8>,
    ) -> Result<(), StorageError> {
        self.data.push((scope, key.to_vec(), Some(value)));
        Ok(())
    }

    fn remove(&mut self, scope: &'static str, key: &[u8]) -> Result<(), StorageError> {
        self.data.push((scope, key.to_vec(), None));
        Ok(())
    }
}
