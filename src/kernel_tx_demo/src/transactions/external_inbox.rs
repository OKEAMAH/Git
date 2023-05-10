// SPDX-FileCopyrightText: 2022-2023 TriliTech <contact@trili.tech>
// SPDX-FileCopyrightText: 2023 Marigold <contact@marigold.dev>
//
// SPDX-License-Identifier: MIT

//! Processing external inbox messages - withdrawals & transactions.

use crate::inbox::dac_message::RevealDacMessageError;
use crate::inbox::v1::verifiable::TransactionError;
use crate::inbox::v1::ParsedBatch;
use crate::inbox::ParsedExternalInboxMessage;
use crate::storage::AccountStorage;
use crate::transactions::withdrawal::Withdrawal;
use crypto::hash::PublicKeyBls;
use crypto::CryptoError;
#[cfg(feature = "debug")]
use tezos_smart_rollup_debug::debug_msg;
use tezos_smart_rollup_host::path::concat;
use tezos_smart_rollup_host::path::OwnedPath;
use tezos_smart_rollup_host::path::PathError;
use tezos_smart_rollup_host::path::RefPath;
use tezos_smart_rollup_host::runtime::Runtime;
use tezos_smart_rollup_host::runtime::RuntimeError;
use thiserror::Error;

// TODO: replace with `dac_committee`, `_-` now allowed in paths by PVM,
//       but `host::path` hasn't been updated yet.
pub(crate) const DAC_COMMITTEE_MEMBER_PATH_PREFIX: RefPath =
    RefPath::assert_from(b"/kernel/dac.committee");

/// Process external message using durable storage directly
pub fn process_external<Host: Runtime>(
    host: &mut Host,
    account_storage: &mut AccountStorage,
    message: &[u8],
) -> Result<Vec<Vec<Withdrawal>>, ProcessExtMsgError> {
    match parse_external(host, message) {
        Some(ParsedExternalInboxMessage::OpList(batch)) => {
            Ok(process_batch_message(host, account_storage, batch))
        }
        None => Err(ProcessExtMsgError::ParseError),
        Some(ParsedExternalInboxMessage::DAC(parsed_dac_message)) => {
            let dac_committee = get_dac_committee(host)?;
            // parsed_dac_message.verify_signature(&dac_committee)?;
            // preallocate with maximum expected size of DAC content
            let mut message = Vec::with_capacity(3_000_000);
            parsed_dac_message.reveal_dac_message(host, &mut message)?;
            match ParsedBatch::parse(&message) {
                Ok((_, batch)) => Ok(process_batch_message(host, account_storage, batch)),
                _ => {
                    #[cfg(feature = "debug")]
                    debug_msg!(host, "Expected DAC message to contain Batch\n");
                    Err(ProcessExtMsgError::UnexpectedExtMsgVariant)
                }
            }
        }
    }
}

/// Process a list of operations.
pub fn process_batch_message<Host: Runtime>(
    host: &mut Host,
    account_storage: &mut AccountStorage,
    batch: ParsedBatch,
) -> Vec<Vec<Withdrawal>> {
    let mut all_withdrawals: Vec<Vec<Withdrawal>> = Vec::new();

    for transaction in batch.operations.into_iter() {
        account_storage.begin_transaction(host).unwrap();
        match transaction.execute(host, account_storage) {
            Ok(withdrawals) => {
                all_withdrawals.push(withdrawals);
            }
            Err(_err) => {
                #[cfg(feature = "debug")]
                debug_msg!(host, "Could not execute transaction: {}\n", _err);
            }
        };
        account_storage.commit(host).unwrap();
    }

    all_withdrawals
}

fn get_dac_committee(host: &impl Runtime) -> Result<Vec<PublicKeyBls>, ProcessExtMsgError> {
    let num_keys = host
        .store_count_subkeys(&DAC_COMMITTEE_MEMBER_PATH_PREFIX)
        .map_err(ProcessExtMsgError::RuntimeGetDacCommittee)?
        .try_into()
        .expect("key count should be non-negative and hold in memory");
    let mut res = Vec::with_capacity(num_keys);
    for idx in 0..num_keys {
        let path = concat(
            &DAC_COMMITTEE_MEMBER_PATH_PREFIX,
            &OwnedPath::try_from(format!("/{idx}")).map_err(ProcessExtMsgError::Path)?,
        )
        .map_err(ProcessExtMsgError::Path)?;
        let mut dac_member = [0; 48];
        host.store_read_slice(&path, 0, &mut dac_member)
            .map_err(LoadDacCommitteeError::RuntimeError)?;
        let pk = PublicKeyBls(dac_member.to_vec());
        res.push(pk);
    }
    Ok(res)
}

/// Parse external message, logging error if it occurs.
fn parse_external<'a>(
    _host: &impl Runtime,
    message: &'a [u8],
) -> Option<ParsedExternalInboxMessage<'a>> {
    match ParsedExternalInboxMessage::parse(message) {
        Ok((remaining, external)) => {
            if !remaining.is_empty() {
                #[cfg(feature = "debug")]
                debug_msg!(
                    _host,
                    "External message had unused remaining bytes: {:?}\n",
                    remaining
                );
            }
            Some(external)
        }
        Err(_err) => {
            #[cfg(feature = "debug")]
            debug_msg!(_host, "Error parsing external message payload {}\n", _err);
            None
        }
    }
}

/// Errors when processing external messages
#[derive(Error, Debug)]
pub enum ProcessExtMsgError {
    /// Parse Error
    #[error("Error parsing external message")]
    ParseError,

    /// Propagate [TransactionError] in the context of dac agg sig verificaiton
    #[error("Dac aggregate signature verification failed: {0}")]
    DacAggregateSigVerficationError(#[from] TransactionError),

    /// Errors when loading roll up id from storage
    #[error("Failed to load rollup id: {0:?}")]
    LoadRollupIdError(RuntimeError),

    /// Errors when loading dac committee from storage
    #[error("Failed to load dac committee: {0}")]
    LoadDacCommitteeError(#[from] LoadDacCommitteeError),

    /// Propogate errors from [RevealDacMessageError]
    #[error(transparent)]
    RevealDacMessageError(#[from] RevealDacMessageError),

    /// External message was the wrong variant
    #[error("Unexpected external message variant")]
    UnexpectedExtMsgVariant,

    /// Runtime failed to fetch DAC committee keys
    #[error("Runtime error while fetching DAC committee keys: {0}")]
    RuntimeGetDacCommittee(RuntimeError),

    /// Store path parsing failed
    #[error("Path error: {0:?}")]
    Path(PathError),
}
/// LoadDacCommitteeError variants
#[derive(Error, Debug)]
pub enum LoadDacCommitteeError {
    /// RuntimeError from host
    #[error("{0:?}")]
    RuntimeError(RuntimeError),

    /// Bls errors from decode
    #[error(transparent)]
    CryptoError(#[from] CryptoError),
}
