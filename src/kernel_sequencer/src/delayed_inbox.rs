// SPDX-FileCopyrightText: 2023 Marigold <contact@marigold.dev>
// SPDX-FileCopyrightText: 2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use tezos_data_encoding::enc::BinWriter;
use tezos_data_encoding::nom::NomReader;
use tezos_smart_rollup_debug::debug_msg;
use tezos_smart_rollup_host::{
    input::Message,
    metadata::{RollupMetadata, RAW_ROLLUP_ADDRESS_SIZE},
    runtime::{Runtime, RuntimeError},
};

use crate::{
    message::{Framed, KernelMessage, Sequence, SequencerMsg, SetSequencer, UnverifiedSigned},
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

/// Message saved in the pending inbox
#[derive(BinWriter, NomReader)]
pub struct PendingUserMessage {
    level: u32,
    id: u32,
    #[encoding(dynamic, list)]
    payload: Vec<u8>,
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
    pending_inbox_queue: &mut Queue,
    pending_inbox_index: &mut u32,
) -> Result<Option<Message>, RuntimeError> {
    let RollupMetadata {
        raw_rollup_address, ..
    } = host.reveal_metadata();
    loop {
        let msg = host.read_input()?;
        match msg {
            None => return Ok(None), // No more messages to be processed
            Some(msg) => {
                let level = msg.level;
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
                            debug_msg!(host, "Received a sequence message {:?}", &sequencer_msg);

                            let Ok(payload) = extract_payload(
                                sequencer_msg,
                                &raw_rollup_address,
                                state,
                            ) else { continue;};

                            match payload {
                                SequencerMsg::Sequence(sequence) => {
                                    let _ = handle_sequence_message(
                                        host,
                                        sequence,
                                        delayed_inbox_queue,
                                        pending_inbox_queue,
                                        level,
                                        pending_inbox_index,
                                    );
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
    sequencer_msg: UnverifiedSigned<Framed<SequencerMsg>>,
    rollup_address: &[u8; RAW_ROLLUP_ADDRESS_SIZE],
    state: State,
) -> Result<SequencerMsg, RuntimeError> {
    // Check if state is sequenced.
    let State::Sequenced(sequencer_address) = state else {
        return Err(RuntimeError::HostErr(
            tezos_smart_rollup_host::Error::GenericInvalidAccess,
        ));
    };

    let body = sequencer_msg.body(&sequencer_address)?;

    let Framed {
        destination,
        payload,
    } = body;

    // Verify if the destination is for this rollup.
    if destination.hash().as_ref() != rollup_address {
        return Err(RuntimeError::HostErr(
            tezos_smart_rollup_host::Error::GenericInvalidAccess,
        ));
    }

    Ok(payload)
}

fn handle_sequence_message(
    host: &mut impl Runtime,
    sequence: Sequence,
    delayed_inbox_queue: &mut Queue,
    pending_inbox_queue: &mut Queue,
    level: u32,
    pending_inbox_index: &mut u32,
) -> Result<(), RuntimeError> {
    let Sequence {
        delayed_messages_prefix,
        delayed_messages_suffix,
        messages,
        ..
    } = sequence;

    // First pop elements from the delayed inbox indicated by the prefix
    for _ in 0..delayed_messages_prefix {
        // pop the head of the delayed inbox
        let delayed_user_msg: Option<UserMessage> = delayed_inbox_queue.pop(host)?;
        // break the loop if the delayed inbox is empty
        let Some(delayed_user_msg) = delayed_user_msg else {break;};
        // add the payload to the pending inbox
        let UserMessage { payload, .. } = delayed_user_msg;
        pending_inbox_queue.add(
            host,
            &PendingUserMessage {
                level,
                id: *pending_inbox_index,
                payload,
            },
        )?;
        *pending_inbox_index += 1;
    }

    // Then add messages to the pending_inbox_queue
    for bytes in messages {
        pending_inbox_queue.add(
            host,
            &PendingUserMessage {
                level,
                id: *pending_inbox_index,
                payload: bytes.inner,
            },
        )?;
        *pending_inbox_index += 1;
    }

    // Finally, pop elements from the delayed inbox indicated by the suffix
    for _ in 0..delayed_messages_suffix {
        // pop the head of the delayed inbox
        let delayed_user_msg: Option<UserMessage> = delayed_inbox_queue.pop(host)?;
        // break the loop if the delayed inbox is empty
        let Some(delayed_user_msg) = delayed_user_msg else {break;};
        // add the payload to the pending inbox
        let UserMessage { payload, .. } = delayed_user_msg;
        pending_inbox_queue.add(
            host,
            &PendingUserMessage {
                level,
                id: *pending_inbox_index,
                payload,
            },
        )?;
        *pending_inbox_index += 1;
    }

    Ok(())
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
            "Received user message {:?} targeting our rollup, hence, will be added to the delayed inbox",
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
