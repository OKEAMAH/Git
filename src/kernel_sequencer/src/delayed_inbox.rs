// SPDX-FileCopyrightText: 2023 Marigold <contact@marigold.dev>
// SPDX-FileCopyrightText: 2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use tezos_crypto_rs::PublicKeySignatureVerifier;
use tezos_data_encoding::enc::BinWriter;
use tezos_data_encoding::nom::NomReader;
use tezos_smart_rollup_debug::debug_msg;
use tezos_smart_rollup_encoding::smart_rollup::SmartRollupAddress;
use tezos_smart_rollup_host::{
    input::Message,
    metadata::{RollupMetadata, RAW_ROLLUP_ADDRESS_SIZE},
    runtime::{Runtime, RuntimeError},
};

use crate::{
    message::{Framed, KernelMessage, Sequence, SequencerMsg, SetSequencer},
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
#[derive(Debug, BinWriter, NomReader)]
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
                        KernelMessage::Sequencer(Framed {
                            destination,
                            payload: SequencerMsg::Sequence(sequence),
                        }) => {
                            let _ = handle_sequence_message(
                                host,
                                sequence,
                                destination,
                                delayed_inbox_queue,
                                pending_inbox_queue,
                                pending_inbox_index,
                                &raw_rollup_address,
                                state,
                                msg.level,
                            );
                        }
                        KernelMessage::Sequencer(Framed {
                            destination,
                            payload: SequencerMsg::SetSequencer(set_sequence),
                        }) => handle_set_sequencer_message(
                            set_sequence,
                            destination,
                            &raw_rollup_address,
                        ),
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
            None => return handle_pending_inbox(host, pending_inbox_queue),
        }
    }
}

/// Handle Sequence message
#[allow(clippy::too_many_arguments)]
fn handle_sequence_message<H: Runtime>(
    host: &mut H,
    sequence: Sequence,
    destination: SmartRollupAddress,
    delayed_inbox_queue: &mut Queue,
    pending_inbox_queue: &mut Queue,
    pending_inbox_index: &mut u32,
    rollup_address: &[u8; RAW_ROLLUP_ADDRESS_SIZE],
    state: State,
    level: u32,
) -> Result<(), RuntimeError> {
    let State::Sequenced(sequencer_address) = state else {return Ok(())};

    // Verify if the destination is for this rollup
    let true = destination.hash().as_ref() == rollup_address else {return Ok(())};

    // Get the hash of the message
    let Ok(hash) = sequence.hash(destination) else {return Ok(());};

    // Verify if the signature is correct
    // Verifying the signature also verify if the sequence comes from the right sequencer
    let Ok(true) = sequencer_address.verify_signature(sequence.signature(), hash.as_ref()) else {return Ok(());};

    // Add the message in the pending-outbox
    // The pending inbox will be empty at the end of the shared-inbox (when None is returned by read_input)

    debug_msg!(
        host,
        "Received a sequence message {:?} targeting our rollup",
        &sequence
    );

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

fn handle_set_sequencer_message(
    _set_sequencer: SetSequencer,
    destination: SmartRollupAddress,
    rollup_address: &[u8; RAW_ROLLUP_ADDRESS_SIZE],
) {
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

/// Empty the pending inbox and returns the message
fn handle_pending_inbox<H: Runtime>(
    host: &mut H,
    pending_inbox_queue: &mut Queue,
) -> Result<Option<Message>, RuntimeError> {
    let pending_message = pending_inbox_queue.pop(host)?;
    debug_msg!(host, "PENDING INBOX ELEMENT {:?}\n", &pending_message);
    let Some(PendingUserMessage {id, level, payload}) = pending_message else {return Ok(None)};

    let msg = Message::new(level, id, payload);
    Ok(Some(msg))
}

#[cfg(test)]
mod tests {
    use tezos_crypto_rs::hash::SecretKeyEd25519;
    use tezos_crypto_rs::{blake2b, hash::SeedEd25519};
    use tezos_data_encoding::enc::BinWriter;
    use tezos_data_encoding::{enc, nom::NomReader};
    use tezos_smart_rollup_encoding::public_key::PublicKey;
    use tezos_smart_rollup_encoding::smart_rollup::SmartRollupAddress;
    use tezos_smart_rollup_host::metadata::RollupMetadata;
    use tezos_smart_rollup_host::runtime::Runtime;
    use tezos_smart_rollup_mock::MockHost;

    use crate::message::SequencerMsg;
    use crate::state::State;
    use crate::storage::write_state;
    use crate::{
        message::{Bytes, Framed, Sequence},
        sequencer_runtime::SequencerRuntime,
    };

    #[derive(BinWriter)]
    struct Msg {
        inner: u32,
    }

    impl Msg {
        fn new(inner: u32) -> Self {
            Self { inner }
        }
    }

    fn prepare() -> (MockHost, SecretKeyEd25519) {
        // create a mock host
        let mut mock_host = MockHost::default();
        // generate a secret and public key
        let seed = SeedEd25519::from_base58_check(
            "edsk31vznjHSSpGExDMHYASz45VZqXN4DPxvsa4hAyY8dHM28cZzp6",
        )
        .unwrap();
        let (pk, sk) = seed.keypair().unwrap();
        let pk = PublicKey::Ed25519(pk);
        // set the mode of the kernel to Sequenced
        write_state(&mut mock_host, State::Sequenced(pk)).unwrap();
        (mock_host, sk)
    }

    fn make_sequence(
        sk: SecretKeyEd25519,
        rollup_address: [u8; 20],
        delayed_messages_prefix: u32,
        delayed_messages_suffix: u32,
    ) -> Framed<SequencerMsg> {
        let nonce = 0;

        let mut bytes = Vec::default();
        // add the rollup address
        bytes.append(&mut rollup_address.to_vec());
        enc::u32(&nonce, &mut bytes).unwrap();
        enc::u32(&delayed_messages_suffix, &mut bytes).unwrap();
        enc::u32(&delayed_messages_prefix, &mut bytes).unwrap();
        enc::list(Bytes::bin_write)(Vec::default(), &mut bytes)
            .map_err(|_| ())
            .unwrap();
        let hash = blake2b::digest_256(&bytes).unwrap();

        let signature = sk.sign(hash).unwrap();

        Framed {
            destination: SmartRollupAddress::nom_read(&rollup_address).unwrap().1,
            payload: SequencerMsg::Sequence(Sequence {
                nonce,
                delayed_messages_prefix,
                delayed_messages_suffix,
                messages: Vec::default(),
                signature,
            }),
        }
    }

    /// check if the given message is equal to the given byte representation
    fn assert_external_eq<M: BinWriter>(message: M, payload: &[u8]) {
        let mut bytes = Vec::default();
        message.bin_write(&mut bytes).unwrap();

        match payload {
            [0x01, remaining @ ..] => assert_eq!(bytes, remaining),
            _ => panic!(),
        }
    }

    #[test]
    fn test_add_message() {
        let (mut mock_host, _) = prepare();

        mock_host.add_external(Msg::new(0x01));

        let mut runtime = SequencerRuntime::new(mock_host, crate::FilterBehavior::AllowAll, 1);
        let msg = runtime.read_input().unwrap();

        assert!(msg.is_none())
    }

    #[test]
    fn test_add_sequence() {
        let (mut mock_host, sk) = prepare();
        let RollupMetadata {
            raw_rollup_address, ..
        } = mock_host.reveal_metadata();

        mock_host.add_external(Msg::new(0x01));
        mock_host.add_external(Msg::new(0x02));
        mock_host.add_external(Msg::new(0x03));
        mock_host.add_external(make_sequence(sk, raw_rollup_address, 2, 0));

        let mut runtime = SequencerRuntime::new(mock_host, crate::FilterBehavior::AllowAll, 1);
        let msg1 = runtime.read_input().unwrap().unwrap();
        let msg2 = runtime.read_input().unwrap().unwrap();

        assert_external_eq(Msg::new(0x01), msg1.as_ref());
        assert_external_eq(Msg::new(0x02), msg2.as_ref());
    }

    #[test]
    fn test_sequence_between_messages() {
        let (mut mock_host, sk) = prepare();
        let RollupMetadata {
            raw_rollup_address, ..
        } = mock_host.reveal_metadata();

        mock_host.add_external(Msg::new(0x01));
        mock_host.add_external(make_sequence(sk, raw_rollup_address, 2, 0));
        mock_host.add_external(Msg::new(0x02));

        let mut runtime = SequencerRuntime::new(mock_host, crate::FilterBehavior::AllowAll, 1);
        let msg1 = runtime.read_input().unwrap().unwrap();
        let msg2 = runtime.read_input().unwrap();

        assert_external_eq(Msg::new(0x01), msg1.as_ref());
        assert!(msg2.is_none());
    }
}
