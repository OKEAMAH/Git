// SPDX-FileCopyrightText: 2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

//! Count outbox messages so we can avoid writing too many outbox
//! messages per level.

use core::mem::size_of;
use tezos_smart_rollup_host::path::RefPath;
use tezos_smart_rollup_host::runtime::RuntimeError;
use tezos_smart_rollup_host::runtime::{Runtime, ValueType};

/// Where we store the outbox message counter
const OUTBOX_COUNTER_PATH: RefPath = RefPath::assert_from(b"/evm/outbox_counter");

/// Number of bytes needed for the counter
const COUNTER_BYTES: usize = size_of::<usize>();

/// Reset the outbox message counter
pub fn reset_outbox_counter(host: &mut impl Runtime) -> Result<(), RuntimeError> {
    host.store_write(&OUTBOX_COUNTER_PATH, &[0_u8; COUNTER_BYTES], 0)
}

/// Increment outbox counter, when we send one outbox messsage
pub fn increment_outbox_counter(host: &mut impl Runtime) -> Result<(), RuntimeError> {
    let old_value = get_outbox_counter(host)?;
    host.store_write(&OUTBOX_COUNTER_PATH, &(old_value + 1).to_be_bytes(), 0)
}

/// Get the number of outbox messages we've written so far
pub fn get_outbox_counter(host: &mut impl Runtime) -> Result<usize, RuntimeError> {
    match host.store_has(&OUTBOX_COUNTER_PATH)? {
        Some(ValueType::Value | ValueType::ValueWithSubtree) => {
            let bytes = host.store_read(&OUTBOX_COUNTER_PATH, 0, COUNTER_BYTES)?;
            Ok(usize::from_be_bytes(
                bytes.try_into().unwrap_or([0_u8; COUNTER_BYTES]),
            ))
        }
        _ => Ok(0_usize),
    }
}
