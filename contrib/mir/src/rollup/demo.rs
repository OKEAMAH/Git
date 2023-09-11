//!  This is a logic for demo rollup that eventually should be thrown away.

use std::mem::size_of;
use tezos_smart_rollup::{
    prelude::{debug_msg, Runtime},
    storage::path::RefPath,
};

pub type Error = String;

const STORAGE_PATH: &RefPath = &RefPath::assert_from(b"/storage");

pub fn process_external_message(host: &mut impl Runtime, payload: &[u8]) -> Result<(), Error> {
    let param = free_form_bytes_to_number(payload);
    let is_storage_empty = host
        .store_has(STORAGE_PATH)
        .map_err(|err| err.to_string())?
        .is_none();
    let storage = if is_storage_empty {
        0
    } else {
        free_form_bytes_to_number(
            host.store_read_all(STORAGE_PATH)
                .map_err(|err| err.to_string())?
                .as_ref(),
        )
    };
    // ↑ That's pretty painful, MR with a higher-level API is on the way

    let new_storage = run_fibonacci(param, storage)?;

    host.store_write_all(STORAGE_PATH, &new_storage.to_le_bytes())
        .map_err(|err| err.to_string())?;
    debug_msg!(host, "Computation successful, storage updated");
    Ok(())
}

fn run_fibonacci(param: usize, _storage: usize) -> Result<usize, Error> {
    // TODO: replace with contract interpretation
    let answers: Vec<usize> = vec![
        0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181,
    ];
    answers
        .get(param)
        .copied()
        .ok_or(String::from("Cannot answer for such large number :shrug:"))
}

/// Accepts both undersized and oversized byte arrays to convert to number.
fn free_form_bytes_to_number(bs: &[u8]) -> usize {
    let mut bs_sized = [0; size_of::<usize>()];
    let bs_len = std::cmp::min(bs_sized.len(), bs.len());
    bs_sized[..bs_len].copy_from_slice(&bs[..bs_len]);
    usize::from_le_bytes(bs_sized)
}
