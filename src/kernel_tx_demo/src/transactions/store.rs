// SPDX-FileCopyrightText: 2023 Marigold <contact@marigold.dev>
//
// SPDX-License-Identifier: MIT

//! Important kernel store keys for transaction processors

use tezos_smart_rollup_host::path::{concat, OwnedPath, PathError, RefPath};

pub(crate) const KERNEL_PRIVATE_STATE: RefPath = RefPath::assert_from(b"/kernel/state");
pub(crate) const CACHED_MESSAGES_STORE_PREFIX: RefPath =
    RefPath::assert_from(b"/kernel/state/messages/cache");
// 32-bit unsigned LE counter
pub(crate) const PROGRESS_KEY: RefPath = RefPath::assert_from(b"/kernel/state/progress");

pub(crate) fn cached_message_path(idx: u32) -> Result<OwnedPath, PathError> {
    concat(
        &CACHED_MESSAGES_STORE_PREFIX,
        &OwnedPath::try_from(format!("/{idx}"))?,
    )
}

#[cfg(test)]
mod tests {
    use tezos_smart_rollup_host::path::Path;

    use super::*;

    #[test]
    fn test_cached_message_path() {
        let path = cached_message_path(42).unwrap();
        assert_eq!(path.as_bytes(), b"/kernel/state/messages/cache/42");
    }
}
