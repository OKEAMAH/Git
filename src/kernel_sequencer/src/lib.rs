// SPDX-FileCopyrightText: 2023 Marigold <contact@marigold.dev>
//
// SPDX-License-Identifier: MIT

mod delayed_inbox;
mod message;
mod queue;
pub mod routing;
mod sequencer_macro;
pub mod sequencer_runtime;

pub use routing::FilterBehavior;

#[cfg(feature = "sequencer-example")]
pub mod example {
    use crate::{sequencer_kernel_entry, FilterBehavior};
    use tezos_smart_rollup_host::runtime::Runtime;

    pub fn kernel_loop<Host: Runtime>(_host: &mut Host) {}

    sequencer_kernel_entry!(kernel_loop, FilterBehavior::OnlyThisRollup);
}
