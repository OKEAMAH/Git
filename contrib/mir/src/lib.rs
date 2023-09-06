mod rollup;
use tezos_smart_rollup::kernel_entry;

kernel_entry!(rollup::kernel::kernel_entry);
