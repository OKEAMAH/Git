// SPDX-FileCopyrightText: 2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

mod commands;
mod installer;
mod output;
mod preimages;

use clap::Parser;
use commands::Cli;
use commands::Commands;
use installer_config::binary::{ConfigInstruction, ConfigProgram, RawPath};
use std::path::Path;
use tezos_smart_rollup_host::path::Path as OtherPath;
// use tezos_smart_rollup_host::path::Path;
use tezos_smart_rollup_host::path::RefPath;
use thiserror::Error;

// Path that we write the kernel to, before upgrading.
const PREPARE_KERNEL_PATH: RefPath = RefPath::assert_from(b"/installer/kernel/boot.wasm");

// Path of currently running kernel.
const KERNEL_BOOT_PATH: RefPath = RefPath::assert_from(b"/kernel/boot.wasm");

fn main() -> Result<(), ClientError> {
    match Cli::parse().command {
        Commands::GetRevealInstaller {
            upgrade_to,
            output,
            preimages_dir,
        } => {
            let upgrade_to = Path::new(&upgrade_to);
            let output = Path::new(&output);
            let preimages_dir = Path::new(&preimages_dir);

            let root_hash = preimages::content_to_preimages(upgrade_to, preimages_dir)?;

            let kernel = installer::with_config_program(ConfigProgram(vec![
                ConfigInstruction::reveal_instr(
                    root_hash.as_ref(),
                    RawPath(PREPARE_KERNEL_PATH.as_bytes()),
                ),
                ConfigInstruction::move_instr(
                    RawPath(PREPARE_KERNEL_PATH.as_bytes()),
                    RawPath(KERNEL_BOOT_PATH.as_bytes()),
                ),
            ]));

            output::save_kernel(output, &kernel).map_err(ClientError::SaveInstaller)?;
        }
    }

    Ok(())
}

#[derive(Debug, Error)]
enum ClientError {
    #[error("Error preimaging kernel: {0}")]
    KernelPreimageError(#[from] preimages::Error),
    #[error("Unable to save installer kernel: {0}")]
    SaveInstaller(std::io::Error),
}
