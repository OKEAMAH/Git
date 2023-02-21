// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
//
// SPDX-License-Identifier: MIT

use crate::account::OwnedHash;
use crate::wei::Wei;

use rlp::{Decodable, DecoderError, Rlp, RlpIterator};

/// Decoder helpers

fn next<'a, 'v>(decoder: &mut RlpIterator<'a, 'v>) -> Result<Rlp<'a>, DecoderError> {
    decoder.next().ok_or(DecoderError::RlpIncorrectListLen)
}

fn decode_field<T: Decodable>(
    decoder: &Rlp<'_>,
    field_name: &'static str,
) -> Result<T, DecoderError> {
    let custom_err = |_: DecoderError| (DecoderError::Custom(field_name));
    decoder.as_val().map_err(custom_err)
}

fn decode_data<'a>(decoder: &Rlp<'a>, field_name: &'static str) -> Result<&'a [u8], DecoderError> {
    let custom_err = |_: DecoderError| (DecoderError::Custom(field_name));
    decoder.data().map_err(custom_err)
}

// Ethereum Legacy transaction representation.
pub struct LegacyTransaction {
    pub nonce: u64,
    pub gas_price: u64,
    pub gas_limit: u64,
    pub destination: Option<OwnedHash>,
    pub value: Wei,
    pub data: Vec<u8>,
    pub v: Vec<u8>,
    pub r: Vec<u8>,
    pub s: Vec<u8>,
}

impl Decodable for LegacyTransaction {
    fn decode(decoder: &Rlp<'_>) -> Result<Self, DecoderError> {
        if decoder.is_list() && decoder.item_count() == Ok(9) {
            let mut it = decoder.iter();
            let nonce: u64 = decode_field(&next(&mut it)?, "nonce")?;
            let gas_price: u64 = decode_field(&next(&mut it)?, "gas_price")?;
            let gas_limit: u64 = decode_field(&next(&mut it)?, "gas_limit")?;
            let destination: OwnedHash = decode_field(&next(&mut it)?, "destination")?;
            let value: Wei = Wei::from_bytes_le(decode_data(&next(&mut it)?, "value")?);
            let data: Vec<u8> = decode_field(&next(&mut it)?, "data")?;
            let v = decode_field(&next(&mut it)?, "v")?;
            let r = decode_field(&next(&mut it)?, "r")?;
            let s = decode_field(&next(&mut it)?, "s")?;
            Ok(Self {
                nonce,
                gas_price,
                gas_limit,
                destination: if destination.is_empty() {
                    None
                } else {
                    Some(destination)
                },
                value,
                data,
                v,
                r,
                s,
            })
        } else {
            Err(DecoderError::RlpExpectedToBeList)
        }
    }
}
