/******************************************************************************/
/*                                                                            */
/* SPDX-License-Identifier: MIT                                               */
/* Copyright (c) [2023] Serokell <hi@serokell.io>                             */
/*                                                                            */
/******************************************************************************/

mod rollup;
use rollup::kernel::kernel_entry;
use tezos_smart_rollup::{kernel_entry, prelude::Runtime};

kernel_entry!(rollup::kernel::kernel_entry);

// kernel_entry! does something only on wasm32 target, on others we should deal
// with `kernel_entry` being unused.
#[cfg(not(feature = "wasm32-unknown-unknown"))]
#[allow(dead_code)]
fn consider_kernel_used(host: &mut impl Runtime) -> ! {
    let _ = kernel_entry(host);
    panic!("Should not be called");
}
