/******************************************************************************/
/*                                                                            */
/* SPDX-License-Identifier: MIT                                               */
/* Copyright (c) [2023] Serokell <hi@serokell.io>                             */
/*                                                                            */
/******************************************************************************/

//! Micheline serialization.

use std::mem::size_of;

use crate::ast::Micheline;

/// Prefix denoting an encoded string.
const STRING_TAG: u8 = 0x01;
/// Prefix denoting an encoded sequence.
const SEQ_TAG: u8 = 0x02;
/// Prefix denoting an encoded bytes sequence.
const BYTES_TAG: u8 = 0x0a;

// Tags for [Michelson::App].
const APP_NO_ARGS_NO_ANNOTS_TAG: u8 = 0x03;
const APP_NO_ARGS_WITH_ANNOTS_TAG: u8 = 0x04;
const APP_ONE_ARG_NO_ANNOTS_TAG: u8 = 0x05;
const APP_ONE_ARG_WITH_ANNOTS_TAG: u8 = 0x06;
const APP_TWO_ARGS_NO_ANNOTS_TAG: u8 = 0x07;
const APP_TWO_ARGS_WITH_ANNOTS_TAG: u8 = 0x08;

/// Length of some container, usually stored as fixed-length number.
type Len = u32;

/// Put length of something.
fn put_len(len: Len, out: &mut Vec<u8>) {
    out.extend_from_slice(&len.to_be_bytes())
}

/// Put bytestring (with its length).
fn put_bytes(bs: &[u8], out: &mut Vec<u8>) {
    out.push(BYTES_TAG);
    put_len(bs.len() as Len, out);
    out.extend_from_slice(bs)
}

/// Put a Michelson string.
fn put_string(s: &str, out: &mut Vec<u8>) {
    out.push(STRING_TAG);
    put_len(s.len() as Len, out);
    out.extend_from_slice(s.as_bytes())
}

/// Put a container.
fn put_seq<V>(list: &[V], out: &mut Vec<u8>, encoder: fn(&V, &mut Vec<u8>)) {
    out.push(SEQ_TAG);
    put_len(0, out); // don't know the right length in advance
    let i = out.len();
    let len_place = (i - size_of::<Len>())..i; // to fill length later
    for val in list {
        encoder(val, out)
    }
    let len_of_written = (out.len() - i) as Len;
    out[len_place].copy_from_slice(&len_of_written.to_be_bytes())
}

/// Recursive encoding function for [Value].
fn encode_micheline<'a>(mich: &'a Micheline<'a>, out: &mut Vec<u8>) {
    use Micheline::*;
    match mich {
        Int(_) => todo!(), // for a later MR
        String(s) => put_string(s, out),
        Bytes(b) => put_bytes(b, out),
        #[allow(clippy::redundant_closure)]
        Seq(s) => put_seq(s, out, |out, mich| encode_micheline(out, mich)),
        App(prim, args, anns) => {
            match (args.len(), anns.is_empty()) {
                (0, true) => out.push(APP_NO_ARGS_NO_ANNOTS_TAG),
                (0, false) => out.push(APP_NO_ARGS_WITH_ANNOTS_TAG),
                (1, true) => out.push(APP_ONE_ARG_NO_ANNOTS_TAG),
                (1, false) => out.push(APP_ONE_ARG_WITH_ANNOTS_TAG),
                (2, true) => out.push(APP_TWO_ARGS_NO_ANNOTS_TAG),
                (2, false) => out.push(APP_TWO_ARGS_WITH_ANNOTS_TAG),
                // TODO: https://gitlab.com/tezos/tezos/-/issues/6646
                _ => todo!("More than 2 arguments in Micheline is not supported at the moment"),
            }
            prim.encode(out);

            for arg in *args {
                encode_micheline(arg, out)
            }
        }
    }
}

impl<'a> Micheline<'a> {
    /// Serialize value.
    #[allow(dead_code)] // Until we add PACK
    fn encode(&self) -> Vec<u8> {
        self.encode_starting_with(&[])
    }

    /// Like [Value::encode], but allows specifying a prefix, useful for
    /// `PACK` implementation.
    fn encode_starting_with(&self, start_bytes: &[u8]) -> Vec<u8> {
        let mut out = Vec::from(start_bytes);
        encode_micheline(self, &mut out);
        out
    }
}
