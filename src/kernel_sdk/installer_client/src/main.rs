// SPDX-FileCopyrightText: 2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

mod commands;
mod config;
mod installer;
mod output;
mod preimages;

use clap::Parser;
use commands::Cli;
use commands::Commands;
use config::create_installer_config;
use std::path::Path;
use thiserror::Error;

fn main() -> Result<(), ClientError> {
    match Cli::parse().command {
        Commands::GetRevealInstaller {
            upgrade_to,
            output,
            preimages_dir,
            setup_file,
        } => {
            let upgrade_to = Path::new(&upgrade_to);
            let output = Path::new(&output);
            let preimages_dir = Path::new(&preimages_dir);

            let root_hash = preimages::content_to_preimages(upgrade_to, preimages_dir)?;
            let config = create_installer_config(&root_hash, setup_file)?;

            let kernel = installer::with_config_program(config);
            output::save_kernel(output, &kernel).map_err(ClientError::SaveInstaller)?;
        }
    }

    Ok(())
}

#[derive(Debug, Error)]
enum ClientError {
    #[error("Error preimaging kernel: {0}")]
    KernelPreimageError(#[from] preimages::Error),
    #[error("Error configuring kernel: {0}")]
    ConfigError(#[from] config::Error),
    #[error("Unable to save installer kernel: {0}")]
    SaveInstaller(std::io::Error),
}
