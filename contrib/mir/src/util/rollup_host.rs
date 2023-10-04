//! A layer on top of Runtime of tezos_smart_rollup package that provides more
//! user-friendly API.

use tezos_smart_rollup::{
    host::{HostError, RuntimeError},
    prelude::Runtime,
    storage::path::Path,
};
use tezos_smart_rollup_host::runtime::ValueType;

enum StorageError {
    KeyNotFound,
}

enum HostErrorCategory {
    /// Likely some programmer's mistake
    Internal(HostError),
    /// E.g. key not found.
    Storage(StorageError),
    /// Error related to inbox or outbox.
    Message,
}

/// Splits the errors into categories, so that we can handle them easily.
fn host_error_category(err: HostError) -> HostErrorCategory {
    use HostError::*;
    use HostErrorCategory::*;
    match err {
        StoreKeyTooLarge => Internal(err),
        StoreInvalidKey => Internal(err),
        StoreNotAValue => Storage(StorageError::KeyNotFound),
        StoreInvalidAccess => Internal(err),
        StoreValueSizeExceeded => Internal(err),
        MemoryInvalidAccess => Internal(err),
        InputOutputTooLarge => Internal(err),
        GenericInvalidAccess => Internal(err),
        StoreReadonlyValue => Internal(err),
        StoreNotANode => Storage(StorageError::KeyNotFound),
        FullOutbox => Message,
    }
}

/// In the majority of the cases getting [HostError] indicates either a
/// programmer mistake (e.g. invalid key constructed), or that something went
/// utterly wrong (we probably can consider [HostError::GenericInvalidAccess] to
/// be from this category).
///
/// Still use this method with care; e.g. [HostError::StoreNotAValue] can
/// indicate a normal condition.
fn panic_with_host_err(err: HostError) -> ! {
    panic!("An error when working with host functions: {err}")
}

/// Provides higher-level host operations, this is a layer on top of [Runtime].
///
/// This trait exists only to allow dot notation.
trait Host {
    fn store_get(&self, path: &impl Path) -> Option<Vec<u8>>;
    fn store_insert(&mut self, path: &impl Path, contents: &[u8]);
    fn store_has(&self, path: &impl Path) -> bool;
    fn store_has_subtree(&self, path: &impl Path) -> bool;
    fn store_get_type(&self, path: &impl Path) -> Option<ValueType>;
    fn store_delete(&mut self, path: &impl Path);
}

impl<T: Runtime> Host for T {
    /// NB (@martoon) [optimization]: This API is implemented on top of
    /// tezos_smart_rollup's `Runtime`, but my impression is that it does not
    /// really suit our purposes well:
    /// 1. Instead of being more elaborate on which errors can be throw and
    ///    which cannot, it just rethrows all and adds its own options.
    ///
    ///    It does not attempt at distinguishing checked and unchecked errors.
    ///
    ///    Moreover, it adds ambiguity: `HostError` has its own errors for "key
    ///    not found", and `RuntimeError` additionally declares a dedicated
    ///    constructor for that.
    ///
    /// 2. In case of reading methods, the implementation always checks for the
    ///    key presence first (instead of relying on error codes). This is an
    ///    extra work with memory, and this way we give up on atomicity too
    ///    easliy (in case it matters).

    /// Read a value from the durable storage,
    ///
    /// This is a very high-level function. It is dedicated for reading entire,
    /// possibly large, values, but does not allow reading only a slice of data.
    fn store_get(&self, path: &impl Path) -> Option<Vec<u8>> {
        self.store_read_all(path)
            .map_err(|err| match err {
                RuntimeError::PathNotFound => (),
                RuntimeError::HostErr(err) => match host_error_category(err) {
                    HostErrorCategory::Internal(_) => panic_with_host_err(err),
                    // This case is actually unlikely, store_read_all manually
                    // checks for element presence first
                    HostErrorCategory::Storage(StorageError::KeyNotFound) => (),
                    HostErrorCategory::Message => unreachable!(),
                },
                RuntimeError::DecodingError => unreachable!(),
                RuntimeError::StoreListIndexOutOfBounds => unreachable!(),
            })
            .ok()
    }

    /// Write a value to durable storage.
    fn store_insert(&mut self, path: &impl Path, content: &[u8]) {
        self.store_write_all(path, content)
            .unwrap_or_else(|err| match err {
                RuntimeError::HostErr(err) => match host_error_category(err) {
                    HostErrorCategory::Internal(_) => panic_with_host_err(err),
                    HostErrorCategory::Storage(StorageError::KeyNotFound) => unreachable!(),
                    HostErrorCategory::Message => unreachable!(),
                },
                RuntimeError::PathNotFound => unreachable!(),
                RuntimeError::DecodingError => unreachable!(),
                RuntimeError::StoreListIndexOutOfBounds => unreachable!(),
            })
    }

    // Get what is stored under the given key, if any.
    //
    // In most cases you don't want to use this function, `store_has` should
    // suffice.
    fn store_get_type(&self, path: &impl Path) -> Option<ValueType> {
        self.store_has(path).unwrap_or_else(|err| match err {
            RuntimeError::HostErr(err) => panic_with_host_err(err),
            RuntimeError::PathNotFound => unreachable!(),
            RuntimeError::DecodingError => unreachable!(),
            RuntimeError::StoreListIndexOutOfBounds => unreachable!(),
        })
    }

    // Check whether a value is stored under given key.
    fn store_has(&self, path: &impl Path) -> bool {
        match self.store_get_type(path) {
            None => false,
            Some(ValueType::Value) | Some(ValueType::ValueWithSubtree) => true,
            Some(ValueType::Subtree) => false,
        }
    }

    // Check whether a subtree is stored under given key.
    fn store_has_subtree(&self, path: &impl Path) -> bool {
        match self.store_get_type(path) {
            None => false,
            Some(ValueType::Subtree) | Some(ValueType::ValueWithSubtree) => true,
            Some(ValueType::Value) => false,
        }
    }

    // Delete a *value*.
    fn store_delete(&mut self, path: &impl Path) {
        self.store_delete_value(path)
            .unwrap_or_else(|err| match err {
                RuntimeError::HostErr(err) => panic_with_host_err(err),
                RuntimeError::PathNotFound => unreachable!(),
                RuntimeError::DecodingError => unreachable!(),
                RuntimeError::StoreListIndexOutOfBounds => unreachable!(),
            })
    }
}

#[cfg(test)]
mod test_storage {
    use tezos_smart_rollup_host::path::RefPath;
    use tezos_smart_rollup_mock::MockHost;

    use super::*;

    #[test]
    fn test_insertion() {
        let mut host = MockHost::default();
        host.store_insert(&RefPath::assert_from(b"/key/1"), b"abc");
        let val = host.store_get(&RefPath::assert_from(b"/key/1"));
        assert_eq!(val, Some(b"abc".clone().into_iter().collect()))
    }
}
