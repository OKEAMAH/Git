use tezos_smart_rollup::kernel_entry;
use tezos_smart_rollup::prelude::{debug_msg, Runtime};

kernel_entry!(kernel_entry);

pub fn kernel_entry<Host: Runtime>(host: &mut Host) {
    debug_msg!(host, "Hello Kernel");
}
