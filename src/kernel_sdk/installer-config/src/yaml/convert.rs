// SPDX-FileCopyrightText: 2023-2024 TriliTech <contact@trili.tech>
// SPDX-FileCopyrightText: 2023 Nomadic Labs <contact@nomadic-labs.com>
//
// SPDX-License-Identifier: MIT

use crate::binary::owned::{OwnedBytes, OwnedConfigInstruction, OwnedConfigProgram};
use crate::yaml::YamlConfig;
use hex::FromHexError;
use tezos_smart_rollup_core::PREIMAGE_HASH_SIZE;
use tezos_smart_rollup_encoding::dac::PreimageHash;
use tezos_smart_rollup_host::path::{OwnedPath, PathError};
use thiserror::Error;

use crate::yaml::Instr;

#[derive(Debug, Error)]
pub enum ConfigConversionError {
    #[error("Unable to convert hex to bytes: {0}.")]
    Hex(FromHexError),
    #[error("Invalid preimage hash size: {0}")]
    InvalidRevealHashSize(usize),
    #[error("Invalid reveal path: {0}")]
    PathError(PathError),
    #[error("Unable to convert set for {0} to reveal")]
    SetToReveal(OwnedPath),
}

pub fn reveal_instr_hex(
    hash_hex: String,
    to: String,
) -> Result<OwnedConfigInstruction, ConfigConversionError> {
    let to = OwnedPath::try_from(to).map_err(ConfigConversionError::PathError)?;
    let hash = hex::decode(hash_hex.as_str()).map_err(ConfigConversionError::Hex)?;

    let hash_len = hash.len();
    let hash: [u8; PREIMAGE_HASH_SIZE] = hash
        .try_into()
        .map_err(|_| ConfigConversionError::InvalidRevealHashSize(hash_len))?;

    Ok(OwnedConfigInstruction::reveal_instr(
        PreimageHash::from(&hash),
        to,
    ))
}

pub fn move_instr_str(
    from: String,
    to: String,
) -> Result<OwnedConfigInstruction, ConfigConversionError> {
    let from = OwnedPath::try_from(from).map_err(ConfigConversionError::PathError)?;
    let to = OwnedPath::try_from(to).map_err(ConfigConversionError::PathError)?;
    Ok(OwnedConfigInstruction::move_instr(from, to))
}

pub fn set_instr_hex(
    value: String,
    to: String,
    content_to_preimages: impl Fn(Vec<u8>) -> Option<PreimageHash>,
) -> Result<OwnedConfigInstruction, ConfigConversionError> {
    let to = OwnedPath::try_from(to).map_err(ConfigConversionError::PathError)?;
    let value = hex::decode(value.as_str()).map_err(ConfigConversionError::Hex)?;
    if value.len() > tezos_smart_rollup_core::PREIMAGE_HASH_SIZE {
        match content_to_preimages(value) {
            Some(hash) => Ok(OwnedConfigInstruction::reveal_instr(hash, to)),
            None => Err(ConfigConversionError::SetToReveal(to)),
        }
    } else {
        Ok(OwnedConfigInstruction::set_instr(OwnedBytes(value), to))
    }
}

impl YamlConfig {
    pub fn to_config_program(
        self: YamlConfig,
        content_to_preimages: impl Fn(Vec<u8>) -> Option<PreimageHash>,
    ) -> Result<OwnedConfigProgram, ConfigConversionError> {
        self.instructions
            .into_iter()
            .map(|instr| match instr {
                Instr::Move(args) => move_instr_str(args.from, args.to),
                Instr::Reveal(args) => reveal_instr_hex(args.reveal, args.to),
                Instr::Set(args) => {
                    set_instr_hex(args.value, args.to, &content_to_preimages)
                }
            })
            .collect::<Result<Vec<OwnedConfigInstruction>, ConfigConversionError>>()
            .map(OwnedConfigProgram)
    }
}

#[cfg(test)]
mod test {
    use crate::{
        binary::owned::OwnedConfigProgram,
        yaml::{
            move_instr_str, reveal_instr_hex, set_instr_hex, ConfigConversionError,
            YamlConfig,
        },
    };
    use std::fs::read_to_string;

    fn unreachable_content_to_preimages(_: Vec<u8>) -> Option<super::PreimageHash> {
        panic!()
    }

    #[test]
    fn convert_valid_config() {
        let source_yaml = read_to_string("tests/resources/config_example1.yaml").unwrap();
        let instrs = serde_yaml::from_str::<YamlConfig>(&source_yaml).unwrap();

        assert_eq!(
            instrs
                .to_config_program(unreachable_content_to_preimages)
                .unwrap(),
            OwnedConfigProgram(vec![
                move_instr_str("/hello/path".to_owned(), "/to/path".to_owned()).unwrap(),
                reveal_instr_hex(
                    "a1b2c3a1b2c3a1b2c3a1b2c3a1b2c3a1b2c3a1b2c3a1b2c3a1b2c3a1b2c3a1b2c3"
                        .to_owned(),
                    "/path".to_owned()
                )
                .unwrap(),
                set_instr_hex(
                    "556e20666573746976616c2064652047414454".to_owned(),
                    "/path/machin".to_owned(),
                    unreachable_content_to_preimages
                )
                .unwrap()
            ])
        );
    }

    #[test]
    fn convert_invalid_reveal_hash_size() {
        let source_yaml =
            read_to_string("tests/resources/config_example2_invalid_hash.yaml").unwrap();
        let instrs = serde_yaml::from_str::<YamlConfig>(&source_yaml).unwrap();

        assert!(matches!(
            instrs.to_config_program(unreachable_content_to_preimages),
            Err::<OwnedConfigProgram, ConfigConversionError>(
                ConfigConversionError::InvalidRevealHashSize(7)
            )
        ));
    }
}
