// SPDX-FileCopyrightText: 2023 Marigold <contact@marigold.dev>
// SPDX-FileCopyrightText: 2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use tezos_crypto_rs::PublicKeySignatureVerifier;
use tezos_data_encoding::enc::BinWriter;
use tezos_data_encoding::nom::NomReader;
use tezos_smart_rollup_debug::debug_msg;
use tezos_smart_rollup_host::{
    input::Message,
    metadata::{RollupMetadata, RAW_ROLLUP_ADDRESS_SIZE},
    runtime::{Runtime, RuntimeError},
};

use crate::{
    message::{Framed, KernelMessage, Sequence, SequencerMsg, SetSequencer, Signed},
    queue::Queue,
    routing::FilterBehavior,
    state::{update_state, State},
    storage::read_state,
};

/// Message added to the delayed inbox
#[derive(BinWriter, NomReader)]
pub struct UserMessage {
    pub(crate) timeout_level: u32,
    pub(crate) payload: Vec<u8>,
}

/// Return a message from the inbox
///
/// This function drives the delayed inbox:
///  - add messages to the delayed inbox
///  - process messages from the sequencer
///  - returns message as "normal" message to the user kernel
pub fn read_input<Host: Runtime>(
    host: &mut Host,
    filter_behavior: FilterBehavior,
    timeout_window: u32,
    delayed_inbox_queue: &mut Queue,
) -> Result<Option<Message>, RuntimeError> {
    let RollupMetadata {
        raw_rollup_address, ..
    } = host.reveal_metadata();
    loop {
        let msg = host.read_input()?;
        match msg {
            None => return Ok(None), // No more messages to be processed
            Some(msg) => {
                let payload = msg.as_ref();
                // Verify the state of the delayed inbox on SoL
                if let [0x00, 0x00, ..] = payload {
                    update_state(host, delayed_inbox_queue, msg.level)?;
                }

                // The state can change at each iteration
                let state = read_state(host)?;

                let message = KernelMessage::nom_read(payload);
                match message {
                    Err(_) => {}
                    Ok((_, message)) => match message {
                        KernelMessage::Sequencer(sequencer_msg) => {
                            let Ok(payload) = extract_payload(
                                sequencer_msg,
                                &raw_rollup_address,
                                state,
                            ) else { continue;};

                            match payload {
                                SequencerMsg::Sequence(sequence) => {
                                    handle_sequence_message(host, sequence)
                                }
                                SequencerMsg::SetSequencer(set_sequencer) => {
                                    handle_set_sequencer_message(set_sequencer)
                                }
                            }
                        }
                        KernelMessage::DelayedMessage(user_message) => {
                            let _ = handle_message(
                                host,
                                delayed_inbox_queue,
                                timeout_window,
                                user_message,
                                msg.level,
                                filter_behavior,
                                &raw_rollup_address,
                            );
                        }
                    },
                }
            }
        }
    }
}

/// Extracts the payload of the message sent by the sequencer.
///
/// The destination has to match the current rollup address.
/// The state of the kernel has to be `Sequenced`.
/// The signature has to be valid.
fn extract_payload(
    sequencer_msg: Signed<Framed<SequencerMsg>>,
    rollup_address: &[u8; RAW_ROLLUP_ADDRESS_SIZE],
    state: State,
) -> Result<SequencerMsg, RuntimeError> {
    let Signed {
        body: Framed {
            destination,
            payload: _,
        },
        signature,
    } = &sequencer_msg;

    // Verify if the destination is for this rollup.
    if destination.hash().as_ref() != rollup_address {
        return Err(RuntimeError::HostErr(
            tezos_smart_rollup_host::Error::GenericInvalidAccess,
        ));
    }

    // Check if state is sequenced.
    let State::Sequenced(sequencer_address) = state else {
        return Err(RuntimeError::HostErr(
            tezos_smart_rollup_host::Error::GenericInvalidAccess,
        ));
    };

    // Verify the signature of the message.
    let hash = sequencer_msg.hash()?;
    let signature_is_correct = sequencer_address
        .verify_signature(signature, hash.as_ref())
        .map_err(|_| RuntimeError::HostErr(tezos_smart_rollup_host::Error::GenericInvalidAccess))?;
    if !signature_is_correct {
        return Err(RuntimeError::HostErr(
            tezos_smart_rollup_host::Error::GenericInvalidAccess,
        ));
    }

    Ok(sequencer_msg.body.payload)
}

/// Handle Sequence message
fn handle_sequence_message<H: Runtime>(host: &H, sequence: Sequence) {
    // process the sequence
    debug_msg!(host, "Received {:?} targeting our rollup", sequence);
}

fn handle_set_sequencer_message(_set_sequencer: SetSequencer) {
    // process the set sequencer message
}

/// Handle messages
fn handle_message<H: Runtime>(
    host: &mut H,
    queue: &mut Queue,
    timeout_window: u32,
    user_message: Vec<u8>,
    level: u32,
    filter_behavior: FilterBehavior,
    rollup_address: &[u8; RAW_ROLLUP_ADDRESS_SIZE],
) -> Result<(), RuntimeError> {
    // Check if the message should be included in the delayed inbox
    if filter_behavior.predicate(user_message.as_ref(), rollup_address) {
        debug_msg!(
            host,
            "Received a user message {:?} targeting our rollup, hence, will be added to the delayed inbox",
            user_message
        );

        // add the message to the delayed inbox
        let user_message = UserMessage {
            timeout_level: level + timeout_window,
            payload: user_message,
        };

        queue.add(host, &user_message)?;
    }

    Ok(())
}
