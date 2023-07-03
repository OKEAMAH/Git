// SPDX-FileCopyrightText: 2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use kernel_sequencer::sequencer_kernel_entry;
use tezos_smart_rollup_debug::debug_msg;
use tezos_smart_rollup_encoding::{inbox::InboxMessage, michelson::MichelsonUnit};
use tezos_smart_rollup_host::{path::RefPath, runtime::Runtime};

const CONCAT_PATH: RefPath = RefPath::assert_from("/concat".as_bytes());

pub fn kernel_loop<Host: Runtime>(host: &mut Host) {
    while let Ok(Some(message)) = host.read_input() {
        debug_msg!(
            host,
            "Processing MessageData {} at level {}",
            message.id,
            message.level
        );

        match InboxMessage::<MichelsonUnit>::parse(message.as_ref()) {
            Err(_e) => Ok(debug_msg!(host, "Parsing error")),
            Ok((_, InboxMessage::External(s))) => match host.store_read_all(&CONCAT_PATH) {
                Err(_) => host.store_write(&CONCAT_PATH, s, 0),
                Ok(result) => host.store_write(&CONCAT_PATH, s, result.len()),
            },
            Ok((_, _)) => Ok(debug_msg!(host, "Ignore internal messages")),
        }
        .unwrap();

        if let Err(e) = host.mark_for_reboot() {
            debug_msg!(host, "Could not mark host for reboot: {}", e);
        }
    }
}

sequencer_kernel_entry!(
    kernel_loop,
    kernel_sequencer::FilterBehavior::OnlyThisRollup
);
