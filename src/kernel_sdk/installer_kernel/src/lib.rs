// SPDX-FileCopyrightText: 2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

//! Installer kernel for tezos smart rollups.
//!
//! # About
//!
//! When originating a smart rollup, you must supply a kernel - the program to be executed
//! by the rollup. This origination kernel must fit within the size of a Layer-1 operation
//! (about 32KB).
//!
//! Almost all useful kernels are larger than this, however. As a result, it is recommended
//! to use this installer kernel. When originating a rollup, you may use a configured
//! installer kernel - which will then proceed to upgrade to your desired kernel.

#![cfg_attr(all(target_arch = "wasm32", not(feature = "std")), no_std)]
#![forbid(unsafe_code)]

mod instr;
mod nom;
mod preimage;

use core::panic::PanicInfo;
use installer_config::binary::EncodingSize;
use installer_config::binary::{NomReader, RefConfigInstruction};
use nom::{completed, decode_size, read_config_program_size};
use tezos_smart_rollup_host::path::RefPath;
use tezos_smart_rollup_host::runtime::Runtime;

use crate::instr::{handle_instruction, read_instruction};

// Path of currently running kernel.
const KERNEL_BOOT_PATH: RefPath = RefPath::assert_from(b"/kernel/boot.wasm");

// Support 3 levels of hashes pages, and then bottom layer of content.
const MAX_DAC_LEVELS: usize = 4;

#[cfg(all(feature = "entrypoint", target_arch = "wasm32"))]
tezos_smart_rollup_entrypoint::kernel_entry!(installer);

/// Installer.
pub fn installer<Host: Runtime>(host: &mut Host) {
    if let Ok(config_program_size) = read_config_program_size(host) {
        if let Err(e) = install_kernel(host, config_program_size as usize) {
            Runtime::write_debug(host, e)
        }
    } else {
        host.write_debug("Failed to read size of config program")
    }
}

/// Panic handler used when targetting wasm.
///
/// Any error when installing a kernel is fatal, therefore we
/// handle panics by panicking again, which aborts execution.
#[cfg_attr(all(target_arch = "wasm32", not(feature = "std")), panic_handler)]
#[allow(dead_code)]
fn panic(_info: &PanicInfo) -> ! {
    panic!()
}

fn install_kernel(
    host: &mut impl Runtime,
    config_program_size: usize,
) -> Result<(), &'static str> {
    let mut config_instruction_buffer = [0; RefConfigInstruction::MAX_SIZE];

    let kernel_size = host
        .store_value_size(&KERNEL_BOOT_PATH)
        .map_err(|_| "Failed to read kernel boot path size")?;

    let end_offset = kernel_size
        .checked_sub(4)
        .ok_or("Substract 4 from kernel_size has failed")?;
    let mut instr_offset = end_offset
        .checked_sub(config_program_size)
        .ok_or("Couldn't substract config program size")?;
    while instr_offset < end_offset {
        let instr_size = decode_size(host, instr_offset)? as usize;
        instr_offset += 4;
        read_instruction(
            host,
            &mut instr_offset,
            &mut config_instruction_buffer[..instr_size],
        )?;
        let instr =
            RefConfigInstruction::nom_read(&config_instruction_buffer[..instr_size])
                .map_err(|_| "Couldn't decode config instruction")
                .map(completed)?;
        handle_instruction(host, instr)?;
    }

    Ok(())
}
