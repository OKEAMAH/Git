// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
//
// SPDX-License-Identifier: MIT

use crate::inbox::Transaction;
use rlp::{Decodable, DecoderError, Encodable, Rlp};
use tezos_ethereum::rlp_helpers::decode_list;
use tezos_ethereum::rlp_helpers::{self, append_timestamp, decode_timestamp};
use tezos_smart_rollup_encoding::timestamp::Timestamp;
use tezos_smart_rollup_host::runtime::Runtime;

#[derive(PartialEq, Debug, Clone)]
pub struct SequencerBlueprint {
    pub timestamp: Timestamp,
    pub transactions: Vec<Transaction>,
}

impl Encodable for SequencerBlueprint {
    fn rlp_append(&self, stream: &mut rlp::RlpStream) {
        stream.begin_list(2);
        stream.append_list(&self.transactions);
        append_timestamp(stream, self.timestamp);
    }
}

impl Decodable for SequencerBlueprint {
    fn decode(decoder: &rlp::Rlp) -> Result<Self, DecoderError> {
        if !decoder.is_list() {
            return Err(DecoderError::RlpExpectedToBeList);
        }
        if decoder.item_count()? != 2 {
            return Err(DecoderError::RlpIncorrectListLen);
        }
        let mut it = decoder.iter();
        let transactions =
            rlp_helpers::decode_list(&rlp_helpers::next(&mut it)?, "transactions")?;
        let timestamp = decode_timestamp(&rlp_helpers::next(&mut it)?)?;
        Ok(Self {
            transactions,
            timestamp,
        })
    }
}

// This is a work in progress, the logic is bound to change
pub fn fetch<Host: Runtime>(host: &mut Host) -> anyhow::Result<Vec<SequencerBlueprint>> {
    let _sol = host.read_input()?;
    let _ipl = host.read_input()?;
    let message = host.read_input()?;
    let eol = host.read_input()?;
    match (message, eol) {
        (Some(message), Some(_)) => {
            let bytes = message.as_ref().get(1..).unwrap();
            let rlp = Rlp::new(bytes);
            let seq_blueprints: Vec<SequencerBlueprint> =
                decode_list(&rlp, "seq_blueprints")?;
            Ok(seq_blueprints)
        }
        _ => Ok(vec![]),
    }
}

#[cfg(test)]
mod tests {
    use super::SequencerBlueprint;
    use crate::inbox::Transaction;
    use crate::inbox::TransactionContent::Ethereum;
    use primitive_types::{H160, U256};
    use rlp::{encode_list, Rlp};
    use tezos_ethereum::rlp_helpers::decode_list;
    use tezos_ethereum::{
        transaction::TRANSACTION_HASH_SIZE, tx_common::EthereumTransactionCommon,
    };
    use tezos_smart_rollup_encoding::timestamp::Timestamp;

    fn sequencer_blueprints_roundtrip(v: Vec<SequencerBlueprint>) {
        let bytes = encode_list(&v);
        let rlp = Rlp::new(&bytes);
        let v2: Vec<SequencerBlueprint> = decode_list(&rlp, "seq_blueprints")
            .expect("Sequencer blueprints should be decodable");
        assert_eq!(v, v2, "Roundtrip failed on {:?}", v)
    }

    fn address_from_str(s: &str) -> Option<H160> {
        let data = &hex::decode(s).unwrap();
        Some(H160::from_slice(data))
    }

    fn tx_(i: u64) -> EthereumTransactionCommon {
        EthereumTransactionCommon {
            type_: tezos_ethereum::transaction::TransactionType::Legacy,
            chain_id: U256::one(),
            nonce: U256::from(i),
            max_priority_fee_per_gas: U256::from(40000000u64),
            max_fee_per_gas: U256::from(40000000u64),
            gas_limit: 21000u64,
            to: address_from_str("423163e58aabec5daa3dd1130b759d24bef0f6ea"),
            value: U256::from(500000000u64),
            data: vec![],
            access_list: vec![],
            signature: None,
        }
    }

    fn dummy_transaction(i: u8) -> Transaction {
        Transaction {
            tx_hash: [i; TRANSACTION_HASH_SIZE],
            content: Ethereum(tx_(i.into())),
        }
    }

    fn dummy_blueprint() -> SequencerBlueprint {
        SequencerBlueprint {
            timestamp: Timestamp::from(42),
            transactions: vec![dummy_transaction(0), dummy_transaction(1)],
        }
    }

    #[test]
    fn roundtrip_rlp() {
        {
            let v = vec![dummy_blueprint(), dummy_blueprint()];
            sequencer_blueprints_roundtrip(v);
        }
    }
}
