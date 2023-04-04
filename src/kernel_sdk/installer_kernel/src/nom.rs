use tezos_smart_rollup_host::runtime::Runtime;

use crate::KERNEL_BOOT_PATH;

pub fn read_config_program_size(host: &impl Runtime) -> Result<u32, &'static str> {
    let kernel_size = host
        .store_value_size(&KERNEL_BOOT_PATH)
        .map_err(|_| "Couldn't read kernel boot path size")?;
    let config_program_size_start = kernel_size
        .checked_sub(4)
        .ok_or("Substract 4 from kernel_size has failed")?;

    decode_size(host, config_program_size_start)
}

pub fn completed<T>(x: (&[u8], T)) -> T {
    if !x.0.is_empty() {
        panic!("Incomplete parsing");
    }
    x.1
}

pub fn decode_size(host: &impl Runtime, offset: usize) -> Result<u32, &'static str> {
    let mut size_buffer = [0; 4];
    host.store_read_slice(&KERNEL_BOOT_PATH, offset, &mut size_buffer)
        .map_err(|_| "Couldn't read from kernel boot path")?;

    installer_config::binary::size(&size_buffer)
        .map_err(|_| "Couldn't decode size")
        .map(completed)
}
