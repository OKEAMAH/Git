// SPDX-FileCopyrightText: 2024 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use std::{
    cell::RefCell,
    collections::{HashMap, HashSet},
    sync::Mutex,
};

use super::{Snapshot, StorageBackend, StorageError, WriteBatch};

#[derive(Debug, thiserror::Error)]
pub enum EphemeralStorageError {
    #[error("Failed to acquire lock")]
    AcquireLock,
}

impl From<EphemeralStorageError> for StorageError {
    fn from(value: EphemeralStorageError) -> Self {
        Self::Internal(Box::new(value))
    }
}

pub type InnerStore = HashMap<(&'static str, Vec<u8>), Vec<u8>>;

#[derive(Debug, Default)]
pub struct EphemeralStorage {
    data: Mutex<RefCell<InnerStore>>,
}

#[derive(Debug)]
pub struct EphemeralSnapshot {
    pub data: InnerStore,
}

#[derive(Debug, Default)]
pub struct EphemeralWriteBatch {
    pub data: Vec<(&'static str, Vec<u8>, Option<Vec<u8>>)>,
}

impl StorageBackend for EphemeralStorage {
    type Snapshot = EphemeralSnapshot;
    type WriteBatch = EphemeralWriteBatch;

    // This is very inefficient, not supposed to be used outside of testing env
    fn snapshot(
        &self,
        scopes: impl IntoIterator<Item = &'static str>,
    ) -> Result<Self::Snapshot, StorageError> {
        let scopes: HashSet<&'static str> = scopes.into_iter().collect();
        Ok(EphemeralSnapshot {
            data: self
                .data
                .lock()
                .map_err(|_| EphemeralStorageError::AcquireLock)?
                .borrow()
                .iter()
                .filter_map(|((s, k), v)| {
                    if scopes.contains(s) {
                        Some(((*s, k.clone()), v.clone()))
                    } else {
                        None
                    }
                })
                .collect::<InnerStore>(),
        })
    }

    fn batch(&self) -> Result<Self::WriteBatch, StorageError> {
        Ok(EphemeralWriteBatch::default())
    }

    fn write(&self, batch: Self::WriteBatch) -> Result<(), StorageError> {
        let data = self
            .data
            .lock()
            .map_err(|_| EphemeralStorageError::AcquireLock)?;

        batch.data.into_iter().for_each(|(s, k, v)| {
            if let Some(v) = v {
                data.borrow_mut().insert((s, k), v);
            } else {
                data.borrow_mut().remove(&(s, k));
            }
        });

        Ok(())
    }
}

impl Snapshot for EphemeralSnapshot {
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
