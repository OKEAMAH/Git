// SPDX-FileCopyrightText: 2022-2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

//! External inbox messages - transactions & withdrawals.
//!
//! External inbox messages are the mechanism by which user's interact with the kernel,
//! when either transacting between accounts on the rollup, or withdrawing from the
//! rollup.
//!
//! Mostly equivalent to TORU's [l2_batch](https://gitlab.com/tezos/tezos/-/blob/bbcb6382f1b418ff03283f7f977b32fd681f9099/src/proto_alpha/lib_protocol/tx_rollup_l2_batch.mli), the main differences being:
//! - lack of compact encoding (TODO: [tezos/tezos#3040](https://gitlab.com/tezos/tezos/-/issues/3040))
//! - replaces uses of `Ticket_hash` + `quantity` with `StringTicket`.  In future, either
//!   ticket_hash will be reintroduced, or indexes (with the compact encoding) will be encouraged.

use crypto::hash::ContractTz1Hash;
use crypto::hash::PublicKeyEd25519;
use nom::branch::alt;
use nom::bytes::complete::tag;
use nom::combinator::map;
use nom::sequence::preceded;
use tezos_data_encoding::enc::BinWriter;
use tezos_data_encoding::encoding::HasEncoding;
use tezos_data_encoding::nom::NomReader;
use tezos_data_encoding::nom::NomResult;
use tezos_smart_rollup_encoding::smart_rollup::SmartRollupAddress;

pub mod dac_message;
pub mod sendable;
#[cfg(feature = "testing")]
pub mod testing;
pub mod v1;

/// The envelope around the external message
#[derive(Debug, PartialEq, Eq)]
pub enum ExternalInboxMessageEnvelope<'a> {
    /// Prefixed with tag `0x00`, this is a message in external inbox
    /// to enact kernel operations
    Message {
        /// The intended recipient
        destination: SmartRollupAddress,
        /// All of the rest of the message for further parsing
        payload: &'a [u8],
    },
}

impl<'a> ExternalInboxMessageEnvelope<'a> {
    const EXTERNAL_MESSAGE_TAG: u8 = 0;

    /// Parse the input into an envelope enclosing an external message
    pub fn parse(input: &'a [u8]) -> NomResult<Self> {
        let (payload, destination) = preceded(
            tag([Self::EXTERNAL_MESSAGE_TAG]),
            SmartRollupAddress::nom_read,
        )(input)?;
        Ok((
            &[],
            Self::Message {
                destination,
                payload,
            },
        ))
    }
}

impl<'a> BinWriter for ExternalInboxMessageEnvelope<'a> {
    fn bin_write(&self, output: &mut Vec<u8>) -> tezos_data_encoding::enc::BinResult {
        match self {
            ExternalInboxMessageEnvelope::Message {
                destination,
                payload,
            } => {
                output.extend_from_slice(&[Self::EXTERNAL_MESSAGE_TAG]);
                destination.bin_write(output)?;
                output.extend_from_slice(payload);
                Ok(())
            }
        }
    }
}

/// Upgradeable representation of external inbox messages.
#[derive(Debug, PartialEq, Eq)]
pub enum ParsedExternalInboxMessage<'a> {
    /// Dac message.
    DAC(dac_message::ParsedDacMessage),
    /// Operation list
    OpList(v1::ParsedBatch<'a>),
}

impl<'a> ParsedExternalInboxMessage<'a> {
    const PARSED_DAC_MESSAGE_DAC: u8 = 0;
    const PARSED_BATCH_TAG: u8 = 1;

    /// Parse an external inbox message.
    pub fn parse(input: &'a [u8]) -> NomResult<Self> {
        alt((
            map(
                preceded(tag([Self::PARSED_BATCH_TAG]), v1::ParsedBatch::parse),
                ParsedExternalInboxMessage::OpList,
            ),
            map(
                preceded(
                    tag([Self::PARSED_DAC_MESSAGE_DAC]),
                    dac_message::ParsedDacMessage::nom_read,
                ),
                ParsedExternalInboxMessage::DAC,
            ),
        ))(input)
    }
}

/// Represents the `signer` of a layer-2 operation.
///
/// This is either a [`PublicKeyEd25519`] or a [`ContractTz1Hash`] address, whose
/// associated account contains a corresponding Ed25519 public key.
#[derive(Debug, Clone, PartialEq, Eq, HasEncoding, NomReader, BinWriter)]
pub enum Signer {
    /// A signer identified by a ed25519 public key.
    PublicKey(PublicKeyEd25519),
    /// A signer identified by a tz1 address.
    Tz1(ContractTz1Hash),
}

impl Signer {
    /// Return the tz1 account-address of the signer.
    pub fn address(&self) -> Result<ContractTz1Hash, crypto::hash::TryFromPKError> {
        use crypto::PublicKeyWithHash;

        match self {
            Signer::PublicKey(pk) => pk.pk_hash(),
            Signer::Tz1(address) => Ok(address.clone()),
        }
    }
}

#[cfg(test)]
mod test {
    use super::*;
    use crypto::hash::BlsSignature;
    use proptest::prelude::*;
    use tezos_data_encoding::enc::BinWriter;
    use tezos_data_encoding::nom::NomReader;
    use tezos_smart_rollup_encoding::dac::make_preimage_hash;
    use tezos_smart_rollup_encoding::dac::PreimageHash;
    use tezos_smart_rollup_encoding::testing::make_witnesses;

    proptest! {
        #[test]
        fn encode_decode_signer(signer in Signer::arb(), remaining in any::<Vec<u8>>()) {
            let mut encoded = Vec::new();
            signer
                .bin_write(&mut encoded)
                .expect("encoding should work");

            encoded.extend_from_slice(remaining.as_slice());

            let (remaining_input, decoded_signer) =
                Signer::nom_read(encoded.as_slice()).expect("decoding should work");

            assert_eq!(remaining.as_slice(), remaining_input);
            assert_eq!(signer, decoded_signer);
        }
    }

    #[test]
    fn parse_dac_message() {
        let root_hash = make_preimage_hash("example content".as_bytes()).unwrap();

        // Random aggregated signature generated in tezos.
        let aggregated_signature: [u8; 96] = [
            152, 154, 156, b'V', b'i', b'|', 2, b'\'', b'd', 216, 229, 140, 144, b'8',
            b'x', b'k', b'q', 209, 23, b'6', 217, 21, b';', b' ', b'q', 166, 251, 213,
            b'K', 16, b'.', b'a', 129, b'P', 21, b'x', 162, b'c', b'n', 212, 132, b'\t',
            b'(', b'5', b'H', 253, b'>', 179, 7, 19, 229, 164, b'Z', 158, 197, 220, 200,
            b')', b'\'', b'a', b't', 165, 161, 147, b'8', b'K', 136, b'R', b' ', b']',
            227, b'K', b'G', 227, 225, 169, 244, 19, b'd', 21, 228, 127, 179, 249, 233,
            195, 159, b'[', 163, b'O', b'0', 167, 200, b'#', 213, 243,
        ];
        let witnesses = 1_u8;
        let mut valid_bytes: Vec<u8> = vec![0];
        valid_bytes.extend_from_slice(&root_hash);
        valid_bytes.extend_from_slice(&aggregated_signature);
        valid_bytes.extend_from_slice(&[witnesses]);

        let expected_message =
            ParsedExternalInboxMessage::DAC(dac_message::ParsedDacMessage {
                root_hash: PreimageHash::from(&root_hash),
                aggregated_signature: BlsSignature(aggregated_signature.to_vec()),
                witnesses: make_witnesses(witnesses as usize),
            });
        let (_remaining, actual_message) =
            ParsedExternalInboxMessage::parse(&valid_bytes)
                .expect("The external messsage should be parsable");

        assert_eq!(expected_message, actual_message);
    }
}
