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
    for (dst, src) in bs_sized.iter_mut().take(size_of::<usize>()).zip(bs) {
        *dst = *src
    }
    usize::from_le_bytes(bs_sized)
}

#[cfg(test)]
mod test_message_processing {
    use tezos_smart_rollup_mock::MockHost;

    use super::*;

    fn test_on_sample(param: &[u8], expected_res: &[u8]) {
        let mut host = MockHost::default();
        host.store_write_all(STORAGE_PATH, &[0; size_of::<usize>()])
            .unwrap();
        process_external_message(&mut host, param).unwrap();
        assert_eq!(host.store_read_all(STORAGE_PATH).unwrap(), expected_res);
    }

    #[test]
    fn test_processing_on_samples() {
        test_on_sample(b"\x00", b"\0\0\0\0\0\0\0\0");
        test_on_sample(b"\x01", b"\x01\0\0\0\0\0\0\0");
        test_on_sample(&[10], &[55, 0, 0, 0, 0, 0, 0, 0]);
        test_on_sample(&[15], &[98, 2, 0, 0, 0, 0, 0, 0]);
    }
}
