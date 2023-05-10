// SPDX-FileCopyrightText: 2023 Marigold <contact@marigold.dev>
//
// SPDX-License-Identifier: MIT

//! Transaction processor: external message processor

use crate::storage::AccountStorage;
use crate::transactions::external_inbox;
use crate::transactions::withdrawal::process_withdrawals;
use crate::CachedTransactionError;
use crate::MAX_ENVELOPE_CONTENT_SIZE;
use tezos_smart_rollup_debug::debug_msg;
use tezos_smart_rollup_host::runtime::Runtime;

use super::store::cached_message_path;
use super::store::KERNEL_PRIVATE_STATE;
use super::store::PROGRESS_KEY;
use super::utils::read_large_store_chunk;

pub(crate) fn process_next_cached_messages<Host: Runtime>(
    host: &mut Host,
    account_storage: &mut AccountStorage,
) -> Result<(), CachedTransactionError> {
    let progress = if host
        .store_has(&PROGRESS_KEY)
        .map_err(CachedTransactionError::Store)?
        .is_some()
    {
        let mut buf = [0u8; 4];
        host.store_read_slice(&PROGRESS_KEY, 0, &mut buf)
            .map_err(CachedTransactionError::ReadProgress)?;
        u32::from_le_bytes(buf)
    } else {
        0
    };
    let mut payload = [0; MAX_ENVELOPE_CONTENT_SIZE];
    let payload = read_large_store_chunk(
        host,
        &cached_message_path(progress).map_err(CachedTransactionError::Path)?,
        &mut payload,
    )
    .map_err(CachedTransactionError::Store)?;
    if let Err(e) = process_external_message(host, account_storage, payload) {
        // gracefully skip failed message
        debug_msg!(host, "error processing external: {}", e);
    }
    let new_progress = progress + 1;
    let has_next_message = host
        .store_has(
            &cached_message_path(new_progress).map_err(CachedTransactionError::Path)?,
        )
        .map_err(CachedTransactionError::Store)?
        .is_some();
    let has_reboot_left = host.reboot_left().map_err(CachedTransactionError::Reboot)? > 0;
    if has_next_message && has_reboot_left {
        host.store_write(&PROGRESS_KEY, &new_progress.to_le_bytes(), 0)
            .map_err(CachedTransactionError::WriteProgress)?;
        return host
            .mark_for_reboot()
            .map_err(CachedTransactionError::Reboot);
    }
    // At this point, the kernel will move onto the inbox
    // on the next level, so it should clean up the cache
    host.store_delete(&KERNEL_PRIVATE_STATE)
        .map_err(CachedTransactionError::Store)?;
    Ok(())
}

pub(crate) fn process_external_message<Host: Runtime>(
    host: &mut Host,
    account_storage: &mut AccountStorage,
    message: &[u8],
) -> Result<(), CachedTransactionError> {
    external_inbox::process_external(host, account_storage, message)
        .map_err(CachedTransactionError::ProcessExternalMessage)?
        .into_iter()
        .for_each(|withdrawals| process_withdrawals(host, withdrawals));
    Ok(())
}
