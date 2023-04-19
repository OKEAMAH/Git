// SPDX-FileCopyrightText: 2022-2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

//! Transaction layers
//!
//! Account storage is kept in layers - one on top of another. The bottom layer
//! holds the "original" values for each account.
//!
//! Each time a transaction is created with `begin_transaction`, a new layer
//! is added to the top of the layer stack. `rollback` will delete the top layer,
//! and `commit` moves the top layer back into the previous one (overwriting it).
//!
//! This allows transactions to be arbitrarily nested.

use crate::StorageError;
use core::marker::PhantomData;
use tezos_smart_rollup_host::path::{concat, OwnedPath, Path};
use tezos_smart_rollup_host::runtime::{Runtime, RuntimeError, ValueType};

fn has_subtree_res(v: Result<Option<ValueType>, RuntimeError>) -> bool {
    use ValueType::*;

    matches!(v, Ok(Some(Subtree | ValueWithSubtree)))
}

/// A mergeable object is able to consume (and merge with) another object
/// of the same type as self.
pub trait Mergeable {
    /// Consume and merge with `other`.
    fn merge(&mut self, other: Self);
}

/// A layer represents a single transaction. If a transaction has a sub-transaction
/// in progress, then this will be represented by another layer on top of it. If a
/// transaction is rolled back, its layer should be discarded. To commit a transaction,
/// have the layer below it consume said transaction layer.
pub trait Layer<T: From<OwnedPath>> {
    /// Construct a default layer at the given location. This is used to construct
    /// the base layer for durable storage.
    fn with_path(name: &impl Path) -> Self;

    /// Create a copy "self" layer.
    ///
    /// The layer copy represents a transaction taking place within the
    /// transaction represented by "self". When a transaction completes,
    /// the copy layer should be either deleted or merged into the layer
    /// below.
    fn make_copy(
        &self,
        host: &mut impl Runtime,
        name: &impl Path,
    ) -> Result<Self, StorageError>
    where
        Self: std::marker::Sized;

    /// Merge changes in given layer into "self" layer.
    ///
    /// Apply all changes in given layer to "self". This also deletes the
    /// given layer from storage. This function assumes that the given
    /// layer was created with the `make_copy` function.
    fn consume(
        &mut self,
        host: &mut impl Runtime,
        layer: Self,
    ) -> Result<(), StorageError>;

    /// Create a new empty account
    ///
    /// Create a new account in the current layer. Note that any data
    /// associated with the new account will only be written to storage,
    /// when the object representing said account does so. Returns `None`
    /// if the account alread exists.
    fn new_account(
        &mut self,
        host: &impl Runtime,
        id: &impl Path,
    ) -> Result<Option<T>, StorageError>;

    /// Get existing account
    ///
    /// Get an account from "self" layer. This checks that there is data
    /// associated with the account in the storage layer. Returns `None`,
    /// if there is no such data.
    fn get_account(
        &self,
        host: &impl Runtime,
        id: &impl Path,
    ) -> Result<Option<T>, StorageError>;

    /// Return existing account or create a new one.
    ///
    /// Creates a new account if there is no data associated with the
    /// account in "self" storage layer. Note that if a new account is
    /// created, the account object is responsible for writing data to
    /// storage as per `new_account`.
    fn get_or_create_account(
        &self,
        host: &impl Runtime,
        id: &impl Path,
    ) -> Result<T, StorageError>;

    /// Delete an account from the "self" layer.
    fn delete_account(
        &mut self,
        host: &mut impl Runtime,
        id: &impl Path,
    ) -> Result<(), StorageError>;

    /// Discard "self" layer.
    ///
    /// This removes all changes done to the "self" layer. This effectively
    /// cancels the changes done in the current transaction, ie, a rollback.
    fn discard(self, host: &mut impl Runtime) -> Result<(), StorageError>;
}

/// A storage layer with no transaction context.
pub struct StorageLayer<T: From<OwnedPath>> {
    pub path: OwnedPath,
    phantom: PhantomData<T>,
}

impl<T: From<OwnedPath>> From<OwnedPath> for StorageLayer<T> {
    fn from(p: OwnedPath) -> Self {
        Self::with_path(&p)
    }
}

impl<T: From<OwnedPath>> Layer<T> for StorageLayer<T> {
    fn with_path(name: &impl Path) -> Self {
        Self {
            path: OwnedPath::from(name),
            phantom: PhantomData,
        }
    }

    fn make_copy(
        &self,
        host: &mut impl Runtime,
        name: &impl Path,
    ) -> Result<Self, StorageError> {
        let copy = Self {
            path: OwnedPath::from(name),
            phantom: PhantomData,
        };

        if let Ok(Some(_)) = host.store_has(&copy.path) {
            Err(StorageError::StorageInUse)
        } else if let Ok(Some(_)) = host.store_has(&self.path) {
            host.store_copy(&self.path, &copy.path)?;
            Ok(copy)
        } else {
            // Nothing to do as current layers durable storage is empty
            // and durable storage area for copy is empty as well.
            Ok(copy)
        }
    }

    fn consume(
        &mut self,
        host: &mut impl Runtime,
        layer: StorageLayer<T>,
    ) -> Result<(), StorageError> {
        if let Ok(Some(_)) = host.store_has(&layer.path) {
            // The layer we consume has content, so move it
            host.store_move(&layer.path, &self.path)
                .map_err(StorageError::from)
        } else if let Ok(Some(_)) = host.store_has(&self.path) {
            // The layer we consume has no content, so delete the "self" layer
            // as it should equal the consumed layer after this call
            host.store_delete(&self.path).map_err(StorageError::from)
        } else {
            // Both self layer and consumed layer are empty, so do nothing
            Ok(())
        }
    }

    fn new_account(
        &mut self,
        host: &impl Runtime,
        id: &impl Path,
    ) -> Result<Option<T>, StorageError> {
        let account_path = concat(&self.path, id)?;

        if has_subtree_res(host.store_has(&account_path)) {
            Ok(None)
        } else {
            Ok(Some(T::from(account_path)))
        }
    }

    fn get_account(
        &self,
        host: &impl Runtime,
        id: &impl Path,
    ) -> Result<Option<T>, StorageError> {
        let account_path = concat(&self.path, id)?;

        if has_subtree_res(host.store_has(&account_path)) {
            Ok(Some(T::from(account_path)))
        } else {
            Ok(None)
        }
    }

    fn get_or_create_account(
        &self,
        _host: &impl Runtime,
        id: &impl Path,
    ) -> Result<T, StorageError> {
        // We could get rid of the host parameter, but in the future, it would be nice
        // if we had the option of interacting with storage when creating an account.
        let account_path = concat(&self.path, id)?;
        Ok(T::from(account_path))
    }

    fn delete_account(
        &mut self,
        host: &mut impl Runtime,
        id: &impl Path,
    ) -> Result<(), StorageError> {
        let account_path = concat(&self.path, id)?;

        host.store_delete(&account_path).map_err(StorageError::from)
    }

    fn discard(self, host: &mut impl Runtime) -> Result<(), StorageError> {
        if let Ok(Some(_)) = host.store_has(&self.path) {
            host.store_delete(&self.path).map_err(StorageError::from)
        } else {
            Ok(())
        }
    }
}

/// A transaction layer that has context associated with the data in durable storage.
/// This is data associated with the current transaction but not stored in world state
/// nor durable storage.
pub struct StorageLayerWithContext<T: From<OwnedPath>, Context: Mergeable> {
    storage: StorageLayer<T>,
    pub context: Context,
}

impl<T: From<OwnedPath>, C: Mergeable + std::default::Default> From<OwnedPath>
    for StorageLayerWithContext<T, C>
{
    fn from(p: OwnedPath) -> Self {
        Self {
            storage: StorageLayer::from(p),
            context: C::default(),
        }
    }
}

impl<T: From<OwnedPath>, C: Mergeable + std::default::Default> Layer<T>
    for StorageLayerWithContext<T, C>
{
    fn with_path(name: &impl Path) -> Self {
        Self {
            storage: StorageLayer::<T>::with_path(name),
            context: C::default(),
        }
    }

    fn make_copy(
        &self,
        host: &mut impl Runtime,
        name: &impl Path,
    ) -> Result<Self, StorageError> {
        Ok(Self {
            storage: self.storage.make_copy(host, name)?,
            context: C::default(),
        })
    }

    fn consume(
        &mut self,
        host: &mut impl Runtime,
        layer: Self,
    ) -> Result<(), StorageError> {
        self.context.merge(layer.context);
        self.storage.consume(host, layer.storage)
    }

    fn new_account(
        &mut self,
        host: &impl Runtime,
        id: &impl Path,
    ) -> Result<Option<T>, StorageError> {
        self.storage.new_account(host, id)
    }

    fn get_account(
        &self,
        host: &impl Runtime,
        id: &impl Path,
    ) -> Result<Option<T>, StorageError> {
        self.storage.get_account(host, id)
    }

    fn get_or_create_account(
        &self,
        host: &impl Runtime,
        id: &impl Path,
    ) -> Result<T, StorageError> {
        self.storage.get_or_create_account(host, id)
    }

    fn delete_account(
        &mut self,
        host: &mut impl Runtime,
        id: &impl Path,
    ) -> Result<(), StorageError> {
        self.storage.delete_account(host, id)
    }

    fn discard(self, host: &mut impl Runtime) -> Result<(), StorageError> {
        self.storage.discard(host)
    }
}
