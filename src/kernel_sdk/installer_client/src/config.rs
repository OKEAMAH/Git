// SPDX-FileCopyrightText: 2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use std::{ffi::OsString, path::Path};

use installer_config::{
    binary::{InstallerConfigInstruction, InstallerConfigProgram, RefRawPath},
    yaml::{ConfigConversionError, InstallerConfig},
};
use std::fs::File;
use tezos_smart_rollup_encoding::dac::PreimageHash;
use tezos_smart_rollup_host::path::{Path as OtherPath, RefPath};
use thiserror::Error;

#[derive(Debug, Error)]
pub enum Error {
    #[error("Unable to read config file: {0}.")]
    ConfigFile(std::io::Error),
    #[error("Unable to parse config file: {0}.")]
    ConfigParse(serde_yaml::Error),
    #[error("Unable to convert config to a valid program: {0}.")]
    YamlConfigInvalid(#[from] ConfigConversionError),
}

// Path that we write the kernel to, before upgrading.
const PREPARE_KERNEL_PATH: RefPath = RefPath::assert_from(b"/installer/kernel/boot.wasm");

// Path of currently running kernel.
const KERNEL_BOOT_PATH: RefPath = RefPath::assert_from(b"/kernel/boot.wasm");

pub fn create_installer_config(
    root_hash: &PreimageHash,
    setup_file: Option<OsString>,
) -> Result<InstallerConfigProgram, Error> {
    let mut reveal_instructions = vec![
        InstallerConfigInstruction::reveal_instr(
            root_hash,
            RefRawPath(PREPARE_KERNEL_PATH.as_bytes()),
        ),
        InstallerConfigInstruction::move_instr(
            RefRawPath(PREPARE_KERNEL_PATH.as_bytes()),
            RefRawPath(KERNEL_BOOT_PATH.as_bytes()),
        ),
    ];

    let setup_program: InstallerConfigProgram = match setup_file {
        None => InstallerConfigProgram::new(vec![]),
        Some(setup_file) => {
            let setup_file =
                File::open(Path::new(&setup_file)).map_err(Error::ConfigFile)?;
            let yaml_config: InstallerConfig =
                InstallerConfig::from_reader(setup_file).map_err(Error::ConfigParse)?;
            yaml_config.try_into()?
        }
    };

    reveal_instructions.extend(setup_instructions);

    Ok(InstallerConfigProgram::new(reveal_instructions))
}
