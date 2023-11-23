// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
//
// SPDX-License-Identifier: MIT

use crate::inbox::Transaction;
use primitive_types::U256;
use rlp::{Decodable, DecoderError, Encodable};
use tezos_ethereum::rlp_helpers::{
    self, append_timestamp, append_u256_le, decode_field_u256_le, decode_timestamp,
    FromRlpBytes,
};
use tezos_smart_rollup_encoding::timestamp::Timestamp;
use tezos_smart_rollup_host::runtime::Runtime;

#[derive(PartialEq, Debug, Clone)]
pub struct SequencerBlueprint {
    pub timestamp: Timestamp,
    pub transactions: Vec<Transaction>,
    pub chain_id: U256,
}

impl Encodable for SequencerBlueprint {
    fn rlp_append(&self, stream: &mut rlp::RlpStream) {
        stream.begin_list(3);
        stream.append_list(&self.transactions);
        append_timestamp(stream, self.timestamp);
        append_u256_le(stream, &self.chain_id);
    }
}

impl Decodable for SequencerBlueprint {
    fn decode(decoder: &rlp::Rlp) -> Result<Self, DecoderError> {
        if !decoder.is_list() {
            return Err(DecoderError::RlpExpectedToBeList);
        }
        if decoder.item_count()? != 3 {
            return Err(DecoderError::RlpIncorrectListLen);
        }
        let mut it = decoder.iter();
        let transactions =
            rlp_helpers::decode_list(&rlp_helpers::next(&mut it)?, "transactions")?;
        let timestamp = decode_timestamp(&rlp_helpers::next(&mut it)?)?;
        let chain_id = decode_field_u256_le(&rlp_helpers::next(&mut it)?, "chain_id")?;
        Ok(Self {
            transactions,
            timestamp,
            chain_id,
        })
    }
}

// This is a work in progress, the logic is bound to change
pub fn fetch<Host: Runtime>(
    host: &mut Host,
    chain_id: U256,
) -> anyhow::Result<Vec<SequencerBlueprint>> {
    let _sol = host.read_input()?;
    let _ipl = host.read_input()?;
    let message = host.read_input()?;
    let eol = host.read_input()?;
    match (message, eol) {
        (Some(message), Some(_)) => {
            let bytes = message.as_ref().get(1..).unwrap();
            let seq_blueprint: SequencerBlueprint = FromRlpBytes::from_rlp_bytes(bytes)?;
            if seq_blueprint.chain_id == chain_id {
                Ok(vec![seq_blueprint])
            } else {
                Ok(vec![])
            }
        }
        _ => Ok(vec![]),
    }
}
