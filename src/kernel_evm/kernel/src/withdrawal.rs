// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
//
// SPDX-License-Identifier: MIT

use primitive_types::U256;
use tezos_crypto_rs::hash::ContractKt1Hash;
use tezos_data_encoding::enc::BinWriter;
use tezos_smart_rollup_core::MAX_OUTPUT_SIZE;
use tezos_smart_rollup_debug::Runtime;
use tezos_smart_rollup_encoding::{
    contract::Contract::{self, Originated},
    entrypoint::Entrypoint,
    michelson::{ticket::UnitTicket, MichelsonContract, MichelsonPair, MichelsonUnit},
    outbox::{OutboxMessage, OutboxMessageTransaction},
};

use crate::error::Error;

pub fn withdraw<Host: Runtime>(
    host: &mut Host,
    receiver: Contract,
    l1_bridge: ContractKt1Hash,
    amount: U256,
) -> Result<(), Error> {
    let destination = Originated(l1_bridge);
    let entrypoint = Entrypoint::try_from(String::from("withdraw")).unwrap();

    let ticket =
        UnitTicket::new(destination.clone(), MichelsonUnit, amount.as_u64()).unwrap();
    let parameters = MichelsonPair::<UnitTicket, MichelsonContract>(
        ticket,
        MichelsonContract(receiver),
    );

    let withdrawal = OutboxMessageTransaction {
        parameters,
        entrypoint,
        destination,
    };
    let outbox = OutboxMessage::AtomicTransactionBatch(vec![withdrawal].into());

    let mut outbox_bytes = Vec::with_capacity(MAX_OUTPUT_SIZE);
    outbox.bin_write(&mut outbox_bytes).unwrap();

    host.write_output(&outbox_bytes).map_err(Error::from)
}
