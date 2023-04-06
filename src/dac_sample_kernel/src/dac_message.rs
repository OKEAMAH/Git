// SPDX-FileCopyrightText: 2022 Nomadic Labs <contact@nomadic-labs.com>
// SPDX-FileCopyrightText: 2022-2023 TriliTech <contact@trili.tech>

//
// SPDX-License-Identifier: MIT

//! Representation of a DAC message communicating root hashes to the kernel to
//! download pages.

use tezos_crypto_rs::hash::{BlsSignature, PublicKeyBls};
use tezos_data_encoding::enc::BinWriter;
use tezos_data_encoding::encoding::HasEncoding;
use tezos_data_encoding::nom::NomReader;
use tezos_data_encoding::types::Zarith;
use tezos_smart_rollup_encoding::dac::{
    reveal_loop, PreimageHash, V0SliceContentPage, MAX_PAGE_SIZE,
};
use tezos_smart_rollup_host::runtime::Runtime;
use thiserror::Error;

const MAX_DAC_LEVELS: usize = 3;

/// DAC external message is a message sent from DAC to rollups to indicate that there
/// is data ready to be revealed. By the time the kernel receives this message, data
/// should already be available locally and ready to be revealed. The raw structure
/// of the external message is root hash ^ aggregate signature ^ witnesses
#[derive(Debug, PartialEq, Eq, NomReader, Clone, HasEncoding, BinWriter)]
pub struct ParsedDacMessage {
    /// Root page hash
    pub root_hash: PreimageHash,
    /// Aggregated signature of the DAC committee.
    pub aggregated_signature: BlsSignature,
    /// Data_encoding.Bit_set.t is actually a Z.t
    pub witnesses: Zarith,
}

impl ParsedDacMessage {
    /// Verifies that parsed_dac_message is valid against the given dac_committee
    pub fn verify_signature(&self, dac_committee: &[PublicKeyBls]) -> Result<(), String> {
        let root_hash = self.root_hash.as_ref();
        let mut pk_msg_iter = dac_committee.iter().enumerate().filter_map(|(i, member)| {
            if self.witnesses.0.bit(i as u64) {
                Some((root_hash.as_slice(), member))
            } else {
                None
            }
        });
        let is_verified = self
            .aggregated_signature
            .aggregate_verify(&mut pk_msg_iter)
            .map_err(|e| e.to_string())?;
        if !is_verified {
            return Err("Could not verify error".to_string());
        }
        Ok(())
    }

    /// Reveals all message data from referenced by [self.root_hash].
    pub fn reveal_dac_message(
        &self,
        host: &mut impl Runtime,
        result_buf: &mut Vec<u8>,
    ) -> Result<(), RevealDacMessageError> {
        let mut buffer = [0u8; MAX_PAGE_SIZE * MAX_DAC_LEVELS];
        reveal_loop(
            host,
            0,
            self.root_hash.as_ref(),
            buffer.as_mut_slice(),
            MAX_DAC_LEVELS,
            &mut Self::write_content(result_buf),
        )
        .map_err(RevealDacMessageError::RevealLoopError)?;
        Ok(())
    }

    fn write_content<Host: Runtime>(
        buf: &'_ mut Vec<u8>,
    ) -> impl FnMut(&mut Host, V0SliceContentPage) -> Result<(), &'static str> + '_ {
        |_, content| {
            buf.extend_from_slice(content.as_ref());
            Ok(())
        }
    }
}

/// parse_dac_message errors
#[derive(Error, Debug)]
pub enum RevealDacMessageError {
    /// Propagate error from SlicePageError
    #[error("{0:?}")]
    RevealLoopError(&'static str),
}
