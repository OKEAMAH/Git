// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
//
// SPDX-License-Identifier: MIT

use tezos_crypto_rs::hash::{ContractKt1Hash, HashTrait};
use tezos_smart_rollup::{kernel_entry, prelude::Runtime, storage::path::RefPath};

const TICKETER: RefPath = RefPath::assert_from(b"/ticketer");

pub fn entry(rt: &mut (impl Runtime + 'static)) {
    // Override the ticketer
    let ticketer = ContractKt1Hash::from_b58check("tz1dJ21ejKD17t7HKcKkTPuwQphgcSiehTYi").unwrap();
    let data = bincode::serialize(&ticketer).unwrap();
    rt.store_write_all(&TICKETER, data.as_slice()).unwrap();

    // Delegate to Kernel
    loop {
        jstz_kernel::entry(rt)
    }
}

kernel_entry!(entry);
