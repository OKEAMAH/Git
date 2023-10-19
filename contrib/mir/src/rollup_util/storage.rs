/******************************************************************************/
/*                                                                            */
/* SPDX-License-Identifier: MIT                                               */
/* Copyright (c) [2023] Serokell <hi@serokell.io>                             */
/*                                                                            */
/******************************************************************************/

//! Provides higher-level host operations, this is a layer on top of [Runtime].
//!
//! Things that are related to all the methods:
//!
//! Mind the size limits: values cannot be larger than 2Gb, and keys also have
//! their limit on size. Consider avoiding using arbitrarily-sized path
//! segments in the keys. And we will have to do something about values.
//!
//! There are a few restrictions on keys. Putting it short, the key must use
//! characters from `[A-Za-z0-9.-_]` set, and there are busy keys used by
//! rollup machinery (just avoid `/readonly` and `/kernel` prefixes). For more
//! details, see [tezos_smart_rollup_host::path::PathError].

use tezos_smart_rollup::{host::RuntimeError, prelude::Runtime, storage::path::Path};

// A brief introduction to the durable storage:
//
// Durable storage is a key-value store; however it is also similar to a
// filesystem. So keys look like paths, and you have values (aka files) and
// subtrees (aka directories).
//
// *Unlike* in filesystem:
// * There is no need to create directories manually.
// * Under a key we can have a directory and a value simultanously.
//
// So you don't need to care about directories until you have a case for batch
// delete of values or for counting the number of `/prefix/XXX` keys in the
// storage.
//
// If behaviour of any function is unclear, see the tests at the bottom of this
// module. If your case is not covered, feel free to add it!

/// Turn a [RuntimeError] into panic.
///
/// This must be used only when you have already checked the provided error for
/// all checked errors (i.e. those that are entirely expected in certain
/// circumstances).
///
/// In the majority of the cases getting [HostError] indicates either a
/// programmer mistake (e.g. invalid key constructed, value is oversized), or
/// that something went utterly wrong (we probably can consider
/// [HostError::GenericInvalidAccess] to be from this category). There is no
/// sensible way to recover from these errors, so need to explicitly propagate
/// them.
///
/// Still use this method with care; e.g. [HostError::StoreNotAValue] in theory
/// can indicate a normal condition.
macro_rules! panic_with_runtime_err {
    ( $err:expr ) => {
        panic!("Unexpected error when working with storage: {}", $err)
    };
}

fn is_key_absent_error(err: RuntimeError) -> bool {
    matches!(
        err,
        RuntimeError::PathNotFound
        // PathNotFound is not reliable - it is returned when the inner
        // `store_has` says there is something there, i.e. when either value or
        // subtree or both are there.
        //
        // Oftentimes this is not what we want: for instance, in `store_get` we
        // access only a value. So on running `store_get`, if there is nethier
        // value nor subtree at this key, I will get PathNotFound. If there is
        // only a subtree, I will get `StoreNotAValue`.
        | RuntimeError::HostErr(
            tezos_smart_rollup_host::Error::StoreNotANode
            | tezos_smart_rollup_host::Error::StoreNotAValue)
    )
}

/// NB on implementation (@martoon) [optimization]: This API is implemented
/// on top of tezos_smart_rollup's [Runtime], but my impression is that it
/// does not really suit our purposes well:
/// 1. Instead of being more elaborate on which errors can be throw and
///    which cannot, it just rethrows all and adds its own options.
///
///    It does not attempt at distinguishing checked and unchecked errors.
///
///    Moreover, it adds ambiguity: `HostError` has its own errors for "key
///    not found", and `RuntimeError` additionally declares a dedicated
///    constructor for that (that does not really work well as explained in
///    [is_key_absent_error]).
///
/// 2. In case of reading methods, the implementation always checks for the
///    key presence first (instead of relying on error codes). This sounds
///    like an extra work with memory (however its amount can be nigligible
///    due to cache, needs benchmarking).

/// Read a value from the durable storage,
///
/// This is a high-level function. It is dedicated for reading entire,
/// possibly large, values, but does not allow reading only a slice of data.
pub fn read_all(host: &impl Runtime, path: &impl Path) -> Option<Vec<u8>> {
    host.store_read_all(path)
        .map_err(|err| {
            if !is_key_absent_error(err) {
                panic_with_runtime_err!(err)
            }
        })
        .ok()
}

/// Put a value to the durable storage.
///
/// This is a high-level function. It is dedicated for writing entire,
/// possibly large, values, but does not allow writing only a slice of data.
pub fn write_all<T>(host: &mut impl Runtime, path: &impl Path, content: &T)
where
    T: AsRef<[u8]> + ?Sized,
{
    host.store_write_all(path, content.as_ref())
        .unwrap_or_else(|err| panic_with_runtime_err!(err))
}

#[cfg(test)]
mod test_storage {
    use tezos_smart_rollup_host::path::RefPath;
    use tezos_smart_rollup_mock::MockHost;

    use super::*;

    mod operations_on_values {

        use super::*;

        const PATH: RefPath<'_> = RefPath::assert_from(b"/key/1");

        #[test]
        fn basic_write_all_and_read_all() {
            let mut host = MockHost::default();
            write_all(&mut host, &PATH, "val");
            assert_eq!(read_all(&host, &PATH), Some(b"val".to_vec()));
        }

        #[test]
        fn getting_absent_elements() {
            let host = MockHost::default();
            assert_eq!(read_all(&host, &PATH), None);
        }

        #[test]
        fn overwritting_value() {
            let mut host = MockHost::default();
            write_all(&mut host, &PATH, "val");
            write_all(&mut host, &PATH, "val2");
            assert_eq!(read_all(&host, &PATH), Some(b"val2".to_vec()));
        }
    }

    mod operations_on_subtrees {
        use super::*;

        const VAL_PATH: RefPath<'_> = RefPath::assert_from(b"/rollup/key/0");
        const DIR_PATH: RefPath<'_> = RefPath::assert_from(b"/rollup/key");

        #[test]
        fn directory_is_not_seen_as_value() {
            let mut host = MockHost::default();
            write_all(&mut host, &DIR_PATH, "dir");
            assert_eq!(read_all(&host, &VAL_PATH), None);
        }

        #[test]
        fn can_have_folder_and_value_simultaneously() {
            let mut host = MockHost::default();
            write_all(&mut host, &VAL_PATH, "val");
            write_all(&mut host, &DIR_PATH, "dir");
            assert_eq!(read_all(&host, &VAL_PATH), Some(b"val".to_vec()));
            assert_eq!(read_all(&host, &DIR_PATH), Some(b"dir".to_vec()));
        }
    }
}
