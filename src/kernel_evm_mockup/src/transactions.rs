// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
//
// SPDX-License-Identifier: MIT

use crate::account::OwnedHash;
use crate::error::Error;
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

// Ethereum EIP 1559 Transaction
pub struct Transaction1559 {
    pub chain_id: u64,
    pub signer_nonce: u64,
    pub max_priority_fee_per_gas: Wei,
    pub max_fee_per_gas: Wei,
    pub gas_limit: u64,
    pub destination: Option<OwnedHash>,
    pub amount: Wei,
    pub payload: Vec<u8>,
    pub access_list: Vec<(OwnedHash, Vec<OwnedHash>)>,
    pub signature_y_parity: bool,
    pub signature_r: Vec<u8>,
    pub signature_s: Vec<u8>,
}

fn decode_access_list(decoder: &Rlp<'_>) -> Result<Vec<(OwnedHash, Vec<OwnedHash>)>, DecoderError> {
    let mut buffer = Vec::new();

    if decoder.is_list() {
        let it = decoder.iter();
        it.fold(Ok(()), |acc, decoder| {
            if decoder.is_list() && decoder.item_count() == Ok(2) && acc == Ok(()) {
                let account = decode_field(&decoder.at(0)?, "account")?;
                let storage_keys: Vec<OwnedHash> = decoder.at(1)?.as_list()?;
                buffer.push((account, storage_keys));
                Ok(())
            } else {
                Err(DecoderError::RlpExpectedToBeList)
            }
        })?
    };
    Ok(buffer)
}

impl Decodable for Transaction1559 {
    fn decode(decoder: &Rlp<'_>) -> Result<Self, DecoderError> {
        if decoder.is_list() && decoder.item_count() == Ok(12) {
            let mut it = decoder.iter();
            let chain_id: u64 = decode_field(&next(&mut it)?, "chain_id")?;
            let signer_nonce: u64 = decode_field(&next(&mut it)?, "signer_nonce")?;
            let max_priority_fee_per_gas = Wei::decode(&next(&mut it)?)?;
            let max_fee_per_gas = Wei::decode(&next(&mut it)?)?;
            let gas_limit: u64 = decode_field(&next(&mut it)?, "gas_limit")?;
            let destination: OwnedHash = decode_field(&next(&mut it)?, "destination")?;
            let amount: Wei = Wei::from_bytes_le(decode_data(&next(&mut it)?, "amount")?);
            let payload: Vec<u8> = decode_field(&next(&mut it)?, "payload")?;
            let access_list = decode_access_list(&next(&mut it)?)?;
            let signature_y_parity = decode_field(&next(&mut it)?, "signature_y_parity")?;
            let signature_r = decode_field(&next(&mut it)?, "signature_r")?;
            let signature_s = decode_field(&next(&mut it)?, "signature_s")?;
            Ok(Self {
                chain_id,
                signer_nonce,
                max_priority_fee_per_gas,
                max_fee_per_gas,
                gas_limit,
                destination: if destination.is_empty() {
                    None
                } else {
                    Some(destination)
                },
                amount,
                payload,
                access_list,
                signature_y_parity,
                signature_r,
                signature_s,
            })
        } else {
            Err(DecoderError::RlpExpectedToBeList)
        }
    }
}

// Ethereum EIP 2930 Transaction
pub struct Transaction2930 {
    pub chain_id: u64,
    pub signer_nonce: u64,
    pub gas_price: Wei,
    pub gas_limit: u64,
    pub destination: Option<OwnedHash>,
    pub amount: Wei,
    pub payload: Vec<u8>,
    pub access_list: Vec<(OwnedHash, Vec<OwnedHash>)>,
    pub signature_y_parity: bool,
    pub signature_r: Vec<u8>,
    pub signature_s: Vec<u8>,
}

impl Decodable for Transaction2930 {
    fn decode(decoder: &Rlp<'_>) -> Result<Self, DecoderError> {
        if decoder.is_list() && decoder.item_count() == Ok(11) {
            let mut it = decoder.iter();
            let chain_id: u64 = decode_field(&next(&mut it)?, "chain_id")?;
            let signer_nonce: u64 = decode_field(&next(&mut it)?, "signer_nonce")?;
            let gas_price = Wei::decode(&next(&mut it)?)?;
            let gas_limit: u64 = decode_field(&next(&mut it)?, "gas_limit")?;
            let destination: OwnedHash = decode_field(&next(&mut it)?, "destination")?;
            let amount: Wei = Wei::from_bytes_le(decode_data(&next(&mut it)?, "amount")?);
            let payload: Vec<u8> = decode_field(&next(&mut it)?, "payload")?;
            let access_list = decode_access_list(&next(&mut it)?)?;
            let signature_y_parity = decode_field(&next(&mut it)?, "signature_y_parity")?;
            let signature_r = decode_field(&next(&mut it)?, "signature_r")?;
            let signature_s = decode_field(&next(&mut it)?, "signature_s")?;
            Ok(Self {
                chain_id,
                signer_nonce,
                gas_price,
                gas_limit,
                destination: if destination.is_empty() {
                    None
                } else {
                    Some(destination)
                },
                amount,
                payload,
                access_list,
                signature_y_parity,
                signature_r,
                signature_s,
            })
        } else {
            Err(DecoderError::RlpExpectedToBeList)
        }
    }
}

pub enum RawTransaction {
    Legacy(LegacyTransaction),
    Eip1559(Transaction1559),
    Eip2930(Transaction2930),
}

impl RawTransaction {
    // It cannot be implemented with the Decodable trait since it expects an RLP
    // encoded value. The prefixed transactions are not RLP compatible.
    pub fn decode(bytes: &[u8]) -> Result<RawTransaction, Error> {
        match bytes.first() {
            None => Err(Error::Generic),
            Some(1_u8) => {
                let decoder = Rlp::new(&bytes[1..]);
                Ok(RawTransaction::Eip2930(Transaction2930::decode(&decoder)?))
            }
            Some(2_u8) => {
                let decoder = Rlp::new(&bytes[1..]);
                Ok(RawTransaction::Eip1559(Transaction1559::decode(&decoder)?))
            }
            Some(_) => {
                let decoder = Rlp::new(bytes);
                Ok(RawTransaction::Legacy(LegacyTransaction::decode(&decoder)?))
            }
        }
    }
}
