// SPDX-FileCopyrightText: 2023 Marigold <contact@marigold.dev>
// SPDX-FileCopyrightText: 2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use tezos_data_encoding::nom::NomReader;
use tezos_data_encoding_derive::BinWriter;
use tezos_smart_rollup_debug::debug_msg;
use tezos_smart_rollup_host::{
    input::Message,
    metadata::{RollupMetadata, RAW_ROLLUP_ADDRESS_SIZE},
    path::RefPath,
    runtime::{Runtime, RuntimeError},
};

use crate::{
    message::{Framed, KernelMessage, Sequence, SetSequencer},
    queue::Queue,
    routing::FilterBehavior,
};

const DELAYED_INBOX_PATH: RefPath = RefPath::assert_from(b"/delayed-inbox");

/// Message added to the delayed inbox
#[derive(BinWriter)]
pub struct UserMessage {
    timeout_level: u32,
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
) -> Result<Option<Message>, RuntimeError> {
    let RollupMetadata {
        raw_rollup_address, ..
    } = host.reveal_metadata();
    let mut queue = Queue::new(host, DELAYED_INBOX_PATH.into())?;
    loop {
        let msg = host.read_input()?;
        match msg {
            None => return Ok(None), // No more messages to be processed
            Some(msg) => {
                let payload = msg.as_ref();
                let message = KernelMessage::nom_read(payload);
                match message {
                    Ok((_, KernelMessage::Message(payload))) => {
                        let _ = handle_message(
                            host,
                            &mut queue,
                            timeout_window,
                            payload,
                            msg.level,
                            filter_behavior,
                            &raw_rollup_address,
                        );
                    }
                    Ok((_, KernelMessage::Sequence(framed))) => {
                        handle_sequence_message(host, framed, &raw_rollup_address)
                    }
                    Ok((_, KernelMessage::SetSequencer(framed))) => {
                        handle_set_sequencer_message(framed, &raw_rollup_address)
                    }
                    Err(_) => {}
                }
            }
        }
    }
}

/// Handle Sequence message
fn handle_sequence_message(
    host: &impl Runtime,
    framed: Framed<Sequence>,
    rollup_address: &[u8; RAW_ROLLUP_ADDRESS_SIZE],
) {
    let Framed {
        destination,
        payload: _,
    } = framed;

    if destination.hash().as_ref() == rollup_address {
        debug_msg!(
            host,
            "Received a sequence message {:?} targeting our rollup",
            framed.payload
        );
        // process the sequence
    }
}

fn handle_set_sequencer_message(
    framed: Framed<SetSequencer>,
    rollup_address: &[u8; RAW_ROLLUP_ADDRESS_SIZE],
) {
    let Framed {
        destination,
        payload: _,
    } = framed;

    if destination.hash().as_ref() == rollup_address {
        // process the set sequencer message
    }
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
