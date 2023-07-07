// SPDX-FileCopyrightText: 2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use kernel_sequencer::{sequencer_kernel_entry, Framed};
use tezos_data_encoding::nom::{NomReader, NomResult};
use tezos_smart_rollup_debug::debug_msg;
use tezos_smart_rollup_encoding::{
    inbox::{InboxMessage, InternalInboxMessage},
    michelson::MichelsonUnit,
};
use tezos_smart_rollup_host::{
    path::RefPath,
    runtime::{Runtime, RuntimeError},
};

const CONCAT_PATH: RefPath = RefPath::assert_from("/concat".as_bytes());

struct RawBytes(Vec<u8>);

impl NomReader for RawBytes {
    fn nom_read(input: &[u8]) -> NomResult<Self> {
        Ok((&[], RawBytes(Vec::from(input))))
    }
}

fn concat_msg(host: &mut impl Runtime, bytes: &[u8]) -> Result<(), RuntimeError> {
    debug_msg!(
        host,
        "store_write WRITING TO {}, VALUE: {:?}",
        &CONCAT_PATH,
        String::from_utf8(Vec::from(bytes))
    );
    let offset = match host.store_read_all(&CONCAT_PATH) {
        Err(_) => 0,
        Ok(result) => result.len(),
    };

    host.store_write(&CONCAT_PATH, bytes, offset)?;
    host.store_write(&CONCAT_PATH, "; ".as_bytes(), bytes.len() + offset)
}

pub fn kernel_loop<Host: Runtime>(host: &mut Host) {
    while let Ok(Some(message)) = host.read_input() {
        debug_msg!(
            host,
            "Processing MessageData {} at level {} with payload {:?}",
            message.id,
            message.level,
            message.as_ref()
        );

        let result = match InboxMessage::<MichelsonUnit>::parse(message.as_ref()) {
            Err(_e) => Ok(debug_msg!(host, "Parsing error")),
            Ok((_, InboxMessage::External(s))) => match Framed::<RawBytes>::nom_read(s) {
                Err(_err) => Ok(debug_msg!(host, "Couldn't parse Framing headers")),
                Ok((_, raw_bytes)) => concat_msg(host, &raw_bytes.payload.0),
            },
            Ok((_, InboxMessage::Internal(InternalInboxMessage::StartOfLevel))) => {
                concat_msg(host, format!("[SoL {}", message.level).as_bytes())
            }
            Ok((_, InboxMessage::Internal(InternalInboxMessage::InfoPerLevel(_)))) => {
                concat_msg(host, format!("IpL {}", message.level).as_bytes())
            }
            Ok((_, InboxMessage::Internal(InternalInboxMessage::EndOfLevel))) => {
                concat_msg(host, format!("EoL {}]", message.level).as_bytes())
            }
            Ok((_, _)) => Ok(debug_msg!(host, "Ignore Transfer message")),
        };

        if result.is_err() {
            debug_msg!(
                host,
                "Failed to process message with error {}",
                result.unwrap_err()
            );
        }

        if let Err(e) = host.mark_for_reboot() {
            debug_msg!(host, "Could not mark host for reboot: {}", e);
        }
    }
}

sequencer_kernel_entry!(
    kernel_loop,
    kernel_sequencer::FilterBehavior::OnlyThisRollup
);
