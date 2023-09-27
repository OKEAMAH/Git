//!  This is a logic for demo rollup that eventually should be thrown away.

use crate::{ast::Value, gas, interpreter, parser};
use std::{collections::VecDeque, mem::size_of};
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
    // NB: This is still not a real contract because we do not support pairs
    let code = parser::parse(&FIBONACCI_SRC).map_err(|err| err.to_string())?;
    let param_val = Value::NumberValue(param as i32);
    let mut istack = VecDeque::from([param_val]);
    let mut gas = gas::Gas::default();
    assert!(interpreter::interpret(&code, &mut gas, &mut istack).is_ok());
    match istack.make_contiguous() {
        [Value::NumberValue(res)] => {
            Ok(usize::try_from(*res).map_err(|_| String::from("Too large answer"))?)
        }
        _ => Err(String::from("Unexpected stack form at the end: {stack}")),
    }
}

/// Accepts both undersized and oversized byte arrays to convert to number.
fn free_form_bytes_to_number(bs: &[u8]) -> usize {
    let mut bs_sized = [0; size_of::<usize>()];
    let bs_len = std::cmp::min(bs_sized.len(), bs.len());
    bs_sized[..bs_len].copy_from_slice(&bs[..bs_len]);
    usize::from_le_bytes(bs_sized)
}

#[cfg(test)]
mod test_message_processing {
    use tezos_smart_rollup_mock::MockHost;

    use super::*;

    fn test_on_sample(param: &[u8], expected_res: &[u8]) {
        let mut host = MockHost::default();
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

const FIBONACCI_SRC: &str = "{
    INT ; PUSH int 0 ; DUP 2 ; GT ;
    IF { DIP { PUSH int -1 ; ADD } ;
     PUSH int 1 ;
     DUP 3 ;
     GT ;
     LOOP { SWAP ; DUP 2 ; ADD ; DIP 2 { PUSH int -1 ; ADD } ; DUP 3 ; GT } ;
     DIP { DROP 2 } }
     { DIP { DROP } } }";
