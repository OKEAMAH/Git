// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
//
// SPDX-License-Identifier: MIT

use crate::blueprint::{Blueprint, Queue, QueueElement};
use crate::blueprint_storage::{store_inbox_blueprint, store_sequencer_blueprint};
use crate::current_timestamp;
use crate::inbox::read_inbox;
use crate::inbox::InboxContent;
use crate::safe_storage::KernelRuntime;
use tezos_crypto_rs::hash::ContractKt1Hash;
use tezos_smart_rollup_host::metadata::RAW_ROLLUP_ADDRESS_SIZE;

fn fetch_inbox_blueprints<Host: KernelRuntime>(
    host: &mut Host,
    smart_rollup_address: [u8; RAW_ROLLUP_ADDRESS_SIZE],
    ticketer: Option<ContractKt1Hash>,
    admin: Option<ContractKt1Hash>,
) -> Result<Queue, anyhow::Error> {
    let InboxContent {
        kernel_upgrade,
        transactions,
        sequencer_blueprints: _,
    } = read_inbox(host, smart_rollup_address, ticketer, admin, None)?;
    let timestamp = current_timestamp(host);
    let blueprint = Blueprint {
        transactions,
        timestamp,
    };
    // Store the blueprint. This will replace the Queue in a future MR.
    // Cloning the blueprint won't be necessary then.
    store_inbox_blueprint(host, blueprint.clone())?;
    Ok(Queue {
        proposals: vec![QueueElement::Blueprint(blueprint)],
        kernel_upgrade,
    })
}

fn fetch_sequencer_blueprints<Host: KernelRuntime>(
    host: &mut Host,
    smart_rollup_address: [u8; RAW_ROLLUP_ADDRESS_SIZE],
    ticketer: Option<ContractKt1Hash>,
    admin: Option<ContractKt1Hash>,
    delayed_bridge: Option<ContractKt1Hash>,
) -> Result<Queue, anyhow::Error> {
    let InboxContent {
        kernel_upgrade,
        transactions,
        sequencer_blueprints,
    } = read_inbox(host, smart_rollup_address, ticketer, admin, delayed_bridge)?;

    // store the transactions in the delayed inbox
    for transaction in transactions {
        host.save_transaction(&transaction)?;
    }

    // Store the blueprints. This will replace the Queue in a future MR.
    for seq_blueprint in &sequencer_blueprints {
        let number = seq_blueprint.number;
        store_sequencer_blueprint(host, seq_blueprint.clone(), number)?
    }
    let proposals: Vec<QueueElement> = sequencer_blueprints
        .into_iter()
        .map(|sb| {
            let blueprint: Blueprint = rlp::decode(&sb.chunk).unwrap();
            QueueElement::Blueprint(blueprint)
        })
        .collect();
    Ok(Queue {
        // TODO: this field will be removed
        proposals,
        kernel_upgrade,
    })
}

pub fn fetch<Host: KernelRuntime>(
    host: &mut Host,
    smart_rollup_address: [u8; RAW_ROLLUP_ADDRESS_SIZE],
    ticketer: Option<ContractKt1Hash>,
    admin: Option<ContractKt1Hash>,
    delayed_bridge: Option<ContractKt1Hash>,
    is_sequencer: bool,
) -> Result<Queue, anyhow::Error> {
    if is_sequencer {
        fetch_sequencer_blueprints(
            host,
            smart_rollup_address,
            ticketer,
            admin,
            delayed_bridge,
        )
    } else {
        fetch_inbox_blueprints(host, smart_rollup_address, ticketer, admin)
    }
}
