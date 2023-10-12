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
//! seghments in the keys. And we will have to do something about values.
//!
//! There are a few restrictions on keys. Putting it short, the key must use
//! characters from `[A-Za-z0-9.-_]` set, and there are busy keys used by
//! rollup machinery (just avoid `/readonly` and `/kernel` prefixes). For more
//! details, see [tezos_smart_rollup_host::path::PathError].

use tezos_smart_rollup::{host::RuntimeError, prelude::Runtime, storage::path::Path};
use tezos_smart_rollup_host::runtime::ValueType;

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

macro_rules! expect_only_key_not_found {
    ($expr:expr) => {
        $expr
            .map_err(|err| {
                if !is_key_absent_error(err) {
                    panic_with_runtime_err!(err)
                }
            })
            .ok()
    };
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
    expect_only_key_not_found!(host.store_read_all(path))
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

/// Get what is stored under the given key, if any.
///
/// In most cases you don't want to use this function, `store_has` should
/// suffice.
pub fn get_entry_type(host: &impl Runtime, path: &impl Path) -> Option<ValueType> {
    host.store_has(path)
        .unwrap_or_else(|err| panic_with_runtime_err!(err))
}

/// Check whether a value is stored under given key.
pub fn has(host: &impl Runtime, path: &impl Path) -> bool {
    matches!(
        get_entry_type(host, path),
        Some(ValueType::Value) | Some(ValueType::ValueWithSubtree)
    )
}

/// Check whether a subtree is stored under given key.
pub fn has_subtree(host: &impl Runtime, path: &impl Path) -> bool {
    matches!(
        get_entry_type(host, path),
        Some(ValueType::Subtree) | Some(ValueType::ValueWithSubtree)
    )
}

/// Delete a value at given path.
///
/// If value is not present, nothing happens.
pub fn delete(host: &mut impl Runtime, path: &impl Path) {
    host.store_delete_value(path)
        .unwrap_or_else(|err| panic_with_runtime_err!(err))
}

/// Delete all the keys that include given path prefix.
///
/// In other words, this removes both the value and the content of the
/// subtree including its subtrees.
///
/// If there is nothing to delete, nothing happens.
pub fn delete_all_with_prefix(host: &mut impl Runtime, path: &impl Path) {
    expect_only_key_not_found!(host.store_delete(path))
        // The "key not found" error is supressed because it's not usually
        // relevant, and this way it is also consistent with the value deleting
        // method.
        .unwrap_or(())
}

/// Count number of elements (files and directories) within the
/// specified directory.
///
/// Elements in the subdirectories are not accounted.
/// If a value is present at exactly the given path, it is accounted.
pub fn count_subkeys(host: &impl Runtime, dir: &impl Path) -> u64 {
    expect_only_key_not_found!(host.store_count_subkeys(dir)).unwrap_or(0)
}

/// Get size of the value in bytes.
pub fn value_size(host: &impl Runtime, path: &impl Path) -> Option<usize> {
    expect_only_key_not_found!(host.store_value_size(path))
}

/// Move the value and the subtree with all its contents.
///
/// Returns whether any value or subtree was present there to be moved.
///
/// If this call moves something, the entire destination subtree is erased
/// as with the [HasDurableStorage::store_delete_all_with_prefix] call
/// before the move.
pub fn move_(host: &mut impl Runtime, from: &impl Path, to: &impl Path) -> bool {
    expect_only_key_not_found!(host.store_move(from, to)).is_some()
}

/// Copy the subtree with all its contents.
///
/// This behaves similarly to [HasDurableStorage::store_move].
///
/// Note: this is told to not perform the immediate values copying, like it
/// is smart and does copy-on-write. But this fact deserves checking.
pub fn copy(host: &mut impl Runtime, from: &impl Path, to: &impl Path) -> bool {
    expect_only_key_not_found!(host.store_copy(from, to)).is_some()
}

#[cfg(test)]
mod test_storage {
    use tezos_smart_rollup_host::path::RefPath;
    use tezos_smart_rollup_mock::MockHost;

    use super::*;

    mod operations_on_values {

        use super::*;

        const PATH: RefPath<'_> = RefPath::assert_from(b"/key/1");
        const PATH_2: RefPath<'_> = RefPath::assert_from(b"/key/2");

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

        #[test]
        fn deletion_works() {
            let mut host = MockHost::default();
            write_all(&mut host, &PATH, "val");
            delete(&mut host, &PATH);
            assert_eq!(read_all(&host, &PATH), None);
        }

        #[test]
        fn deleting_absent_element_is_fine() {
            let mut host = MockHost::default();
            delete(&mut host, &PATH);
            assert_eq!(read_all(&host, &PATH), None);
        }

        #[test]
        fn getting_value_size() {
            let mut host = MockHost::default();
            write_all(&mut host, &PATH, "val");
            assert_eq!(value_size(&host, &PATH), Some(3));
        }

        #[test]
        fn getting_absent_value_size() {
            let host = MockHost::default();
            assert_eq!(value_size(&host, &PATH), None);
        }

        #[test]
        fn move_normal_case() {
            let mut host = MockHost::default();
            write_all(&mut host, &PATH, "val");
            let moved = move_(&mut host, &PATH, &PATH_2);
            assert_eq!(read_all(&host, &PATH), None);
            assert_eq!(read_all(&host, &PATH_2), Some(b"val".to_vec()));
            assert!(moved)
        }

        #[test]
        fn move_absent() {
            let mut host = MockHost::default();
            let moved = move_(&mut host, &PATH, &PATH_2);
            assert!(!moved)
        }

        #[test]
        fn move_destination_busy() {
            let mut host = MockHost::default();
            write_all(&mut host, &PATH, "val1");
            write_all(&mut host, &PATH_2, "val2");
            let moved = move_(&mut host, &PATH, &PATH_2);
            assert_eq!(read_all(&host, &PATH_2), Some(b"val1".to_vec()));
            assert!(moved)
            // ↑ So the value at destination gets overwritten
        }

        #[test]
        fn move_destination_busy_but_move_failed() {
            let mut host = MockHost::default();
            write_all(&mut host, &PATH_2, "val2");
            let moved = move_(&mut host, &PATH, &PATH_2);
            assert!(!moved);
            assert_eq!(read_all(&host, &PATH_2), Some(b"val2".to_vec()));
            // ↑ So the destination is not cleared if there is nothing to move
        }

        #[test]
        fn copy_normal_case() {
            let mut host = MockHost::default();
            write_all(&mut host, &PATH, "val");
            let copied = copy(&mut host, &PATH, &PATH_2);
            assert_eq!(read_all(&host, &PATH), Some(b"val".to_vec()));
            assert_eq!(read_all(&host, &PATH_2), Some(b"val".to_vec()));
            assert!(copied)
        }

        #[test]
        fn copy_absent() {
            let mut host = MockHost::default();
            let copied = copy(&mut host, &PATH, &PATH_2);
            assert!(!copied)
        }
    }

    mod operations_on_subtrees {
        use super::*;

        const VAL_PATH: RefPath<'_> = RefPath::assert_from(b"/rollup/key/0");
        const VAL_PATH_2: RefPath<'_> = RefPath::assert_from(b"/rollup/key/1");
        const DIR_PATH: RefPath<'_> = RefPath::assert_from(b"/rollup/key");
        const SUPER_DIR_PATH: RefPath<'_> = RefPath::assert_from(b"/rollup");

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

        #[test]
        fn delete_directory() {
            let mut host = MockHost::default();
            write_all(&mut host, &VAL_PATH, "val");
            delete_all_with_prefix(&mut host, &DIR_PATH);
            assert_eq!(read_all(&host, &DIR_PATH), None);
        }

        #[test]
        fn delete_directory_recursively() {
            let mut host = MockHost::default();
            write_all(&mut host, &VAL_PATH, "val");
            delete_all_with_prefix(&mut host, &SUPER_DIR_PATH);
            assert_eq!(read_all(&host, &DIR_PATH), None);
        }

        #[test]
        fn delete_value_with_batch_delete() {
            let mut host = MockHost::default();
            write_all(&mut host, &VAL_PATH, "val");
            delete_all_with_prefix(&mut host, &VAL_PATH);
            assert_eq!(read_all(&host, &DIR_PATH), None);
        }

        #[test]
        fn delete_prefix_tolerates_path_boundary() {
            let mut host = MockHost::default();
            write_all(&mut host, &RefPath::assert_from(b"/abc/def"), "val");
            write_all(&mut host, &RefPath::assert_from(b"/abc/defgh"), "xxx");
            delete_all_with_prefix(&mut host, &RefPath::assert_from(b"/abc/def"));
            assert_eq!(
                read_all(&host, &RefPath::assert_from(b"/abc/defgh")),
                Some(b"xxx".to_vec())
            );
        }

        #[test]
        fn move_dir() {
            let mut host = MockHost::default();
            write_all(
                &mut host,
                &RefPath::assert_from(b"/home/my/stuff/0"),
                b"subval",
            );
            write_all(&mut host, &RefPath::assert_from(b"/home/my/0"), "val");
            write_all(&mut host, &RefPath::assert_from(b"/home/my"), "dir");
            move_(
                &mut host,
                &RefPath::assert_from(b"/home/my"),
                &RefPath::assert_from(b"/tmp"),
            );
            assert_eq!(
                read_all(&host, &RefPath::assert_from(b"/tmp")),
                Some(b"dir".to_vec())
            );
            assert_eq!(
                read_all(&host, &RefPath::assert_from(b"/tmp/0")),
                Some(b"val".to_vec())
            );
            assert_eq!(
                read_all(&host, &RefPath::assert_from(b"/tmp/stuff/0")),
                Some(b"subval".to_vec())
            );
        }

        #[test]
        fn move_dir_destination_has_files() {
            let mut host = MockHost::default();
            write_all(
                &mut host,
                &RefPath::assert_from(b"/home/my/stuff/0"),
                b"subval",
            );
            write_all(&mut host, &RefPath::assert_from(b"/home/my/0"), "val");
            write_all(&mut host, &RefPath::assert_from(b"/home/my"), "dir");
            write_all(&mut host, &RefPath::assert_from(b"/tmp"), "target_dir");
            write_all(
                &mut host,
                &RefPath::assert_from(b"/tmp/0"),
                b"overwritten_target_val",
            );
            write_all(
                &mut host,
                &RefPath::assert_from(b"/tmp/1"),
                b"other_target_val",
            );
            move_(
                &mut host,
                &RefPath::assert_from(b"/home/my"),
                &RefPath::assert_from(b"/tmp"),
            );
            assert_eq!(
                read_all(&host, &RefPath::assert_from(b"/tmp")),
                Some(b"dir".to_vec())
            );
            assert_eq!(
                read_all(&host, &RefPath::assert_from(b"/tmp/0")),
                Some(b"val".to_vec())
            );
            assert_eq!(
                read_all(&host, &RefPath::assert_from(b"/tmp/stuff/0")),
                Some(b"subval".to_vec())
            );
            assert_eq!(read_all(&host, &RefPath::assert_from(b"/tmp/1")), None);
            // Hence all values in the subtree, including the value at the
            // target directory itself, are erased
        }

        #[test]
        fn move_dir_erases_value_at_destination() {
            // I.e. even the destination path itself gets erased, not only its
            // subtrees
            let mut host = MockHost::default();
            write_all(&mut host, &RefPath::assert_from(b"/home/my/0"), "val");
            write_all(&mut host, &RefPath::assert_from(b"/tmp"), "target_dir");
            move_(
                &mut host,
                &RefPath::assert_from(b"/home/my"),
                &RefPath::assert_from(b"/tmp"),
            );
            assert_eq!(read_all(&host, &RefPath::assert_from(b"/tmp")), None);
        }

        #[test]
        fn copy_dir() {
            let mut host = MockHost::default();
            write_all(&mut host, &RefPath::assert_from(b"/home/my/0"), "val");
            write_all(&mut host, &RefPath::assert_from(b"/home/my"), "dir");
            copy(
                &mut host,
                &RefPath::assert_from(b"/home/my"),
                &RefPath::assert_from(b"/tmp"),
            );
            assert_eq!(
                read_all(&host, &RefPath::assert_from(b"/tmp")),
                Some(b"dir".to_vec())
            );
            assert_eq!(
                read_all(&host, &RefPath::assert_from(b"/tmp/0")),
                Some(b"val".to_vec())
            );
            assert_eq!(
                read_all(&host, &RefPath::assert_from(b"/home/my")),
                Some(b"dir".to_vec())
            );
            assert_eq!(
                read_all(&host, &RefPath::assert_from(b"/home/my/0")),
                Some(b"val".to_vec())
            );
        }

        #[test]
        fn copy_dir_destination_has_files() {
            let mut host = MockHost::default();
            write_all(&mut host, &RefPath::assert_from(b"/home/my/0"), "val");
            write_all(&mut host, &RefPath::assert_from(b"/tmp/123"), "other_val");
            copy(
                &mut host,
                &RefPath::assert_from(b"/home/my"),
                &RefPath::assert_from(b"/tmp"),
            );
            assert_eq!(read_all(&host, &RefPath::assert_from(b"/tmp/123")), None);
            // Hence values are overwritten
        }

        #[test]
        fn getting_children_number() {
            let mut host = MockHost::default();
            write_all(&mut host, &VAL_PATH, "val");
            write_all(&mut host, &VAL_PATH_2, b"");
            // Apparently this results in the following structure:
            // * SUPER_DIR_PATH
            // ** DIR_PATH
            // *** VAL_PATH
            // *** VAL_PATH_2
            assert_eq!(count_subkeys(&host, &DIR_PATH), 2);
            assert_eq!(count_subkeys(&host, &SUPER_DIR_PATH), 1);
            // ↑ only DIR_PATH is in SUPER_DIR_PATH
        }

        #[test]
        fn getting_children_number_dir_absent() {
            let host = MockHost::default();
            assert_eq!(count_subkeys(&host, &DIR_PATH), 0);
        }

        #[test]
        fn getting_children_number_for_value() {
            let mut host = MockHost::default();
            write_all(&mut host, &VAL_PATH, "val");
            write_all(&mut host, &DIR_PATH, "val");
            assert_eq!(count_subkeys(&host, &DIR_PATH), 2);
            assert_eq!(count_subkeys(&host, &VAL_PATH), 1);
        }
    }

    mod mixed_operations {
        use super::*;

        #[test]
        fn store_has_family() {
            let mut host = MockHost::default();
            const VAL_PATH: RefPath<'_> = RefPath::assert_from(b"/rollup/key/0");
            const VAL_AND_DIR_PATH: RefPath<'_> = RefPath::assert_from(b"/rollup/key");
            const DIR_PATH: RefPath<'_> = RefPath::assert_from(b"/rollup");
            const EMPTY_PATH: RefPath<'_> = RefPath::assert_from(b"/qwe");
            write_all(&mut host, &VAL_PATH, "val");
            write_all(&mut host, &VAL_AND_DIR_PATH, "dir");

            assert_eq!(has(&host, &VAL_PATH), true);
            assert_eq!(has(&host, &VAL_AND_DIR_PATH), true);
            assert_eq!(has(&host, &DIR_PATH), false);
            assert_eq!(has(&host, &EMPTY_PATH), false);

            assert_eq!(has_subtree(&host, &VAL_PATH), false);
            assert_eq!(has_subtree(&host, &VAL_AND_DIR_PATH), true);
            assert_eq!(has_subtree(&host, &DIR_PATH), true);
            assert_eq!(has_subtree(&host, &EMPTY_PATH), false);

            assert_eq!(get_entry_type(&host, &VAL_PATH), Some(ValueType::Value));
            assert_eq!(
                get_entry_type(&host, &VAL_AND_DIR_PATH),
                Some(ValueType::ValueWithSubtree)
            );
            assert_eq!(get_entry_type(&host, &DIR_PATH), Some(ValueType::Subtree));
            assert_eq!(get_entry_type(&host, &EMPTY_PATH), None);
        }
    }
}
