// SPDX-FileCopyrightText: 2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use crate::binary::owned::{OwnedConfigInstruction, OwnedConfigProgram};
use crate::yaml::YamlConfig;
use hex::FromHexError;
use tezos_smart_rollup_core::PREIMAGE_HASH_SIZE;
use tezos_smart_rollup_encoding::dac::PreimageHash;
use tezos_smart_rollup_host::path::{OwnedPath, PathError};
use thiserror::Error;

use crate::yaml::{YamlInstr, Value};

// This module contains a conversion functions from YamlInstr/YamlConfig to binary counterparts.

#[derive(Debug, Error, PartialEq)]
pub enum ConfigConversionError {
    #[error("Unable to convert hex to bytes: {0}.")]
    Hex(FromHexError),
    #[error("Invalid preimage hash size: {0}")]
    InvalidRevealHashSize(usize),
    #[error("Invalid reveal path: {0}")]
    PathError(PathError),
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

impl TryFrom<Value> for Vec<u8> {
    type Error = ConfigConversionError;

    fn try_from(value: Value) -> Result<Self, Self::Error> {
        use super::IntEncoding::*;
        use super::StringEncoding::*;
        fn to_bytes<T, const N: usize>(
            x: T,
            f: impl FnOnce(T) -> [u8; N],
        ) -> Result<Vec<u8>, ConfigConversionError> {
            Ok(f(x).to_vec())
        }

        match value {
            Value::String(s, Hex) => {
                hex::decode(s.as_str()).map_err(ConfigConversionError::Hex)
            }
            Value::String(s, Base58) => FromBase58Check::from_base58check(s.as_str())
                .map_err(ConfigConversionError::Base58),
            Value::I32(x, LittleEndian) => to_bytes(x, i32::to_le_bytes),
            Value::I32(x, BigEndian) => to_bytes(x, i32::to_be_bytes),
            Value::U32(x, LittleEndian) => to_bytes(x, u32::to_le_bytes),
            Value::U32(x, BigEndian) => to_bytes(x, u32::to_be_bytes),
            Value::U8(x) => to_bytes(x, u8::to_be_bytes),
        }
    }
}

impl TryFrom<YamlConfig> for OwnedConfigProgram {
    type Error = ConfigConversionError;

    fn try_from(config: YamlConfig) -> Result<Self, Self::Error> {
        config
            .instructions
            .into_iter()
            .map(|instr| match instr {
                YamlInstr::Move(args) => move_instr_str(args.from, args.to),
                YamlInstr::Reveal(args) => reveal_instr_hex(args.reveal, args.to),
                YamlInstr::Set(args) =>
            })
            .collect::<Result<Vec<OwnedConfigInstruction>, Self::Error>>()
            .map(OwnedConfigProgram)
    }
}

#[cfg(test)]
mod test {
    use crate::{
        binary::owned::OwnedConfigProgram,
        yaml::{move_instr_str, reveal_instr_hex, ConfigConversionError, YamlConfig},
    };
    use std::fs::read_to_string;

    #[test]
    fn convert_valid_config() {
        let source_yaml = read_to_string("tests/resources/config_example1.yaml").unwrap();
        let instrs = serde_yaml::from_str::<YamlConfig>(&source_yaml).unwrap();

        assert_eq!(
            instrs.try_into(),
            Ok(OwnedConfigProgram(vec![
                move_instr_str("/hello/path".to_owned(), "/to/path".to_owned()).unwrap(),
                reveal_instr_hex(
                    "a1b2c3a1b2c3a1b2c3a1b2c3a1b2c3a1b2c3a1b2c3a1b2c3a1b2c3a1b2c3a1b2c3"
                        .to_owned(),
                    "/path".to_owned()
                )
                .unwrap()
            ]))
        );
    }

    #[test]
    fn convert_invalid_reveal_hash_size() {
        let source_yaml =
            read_to_string("tests/resources/config_example2_invalid_hash.yaml").unwrap();
        let instrs = serde_yaml::from_str::<YamlConfig>(&source_yaml).unwrap();

        assert_eq!(
            instrs.try_into(),
            Err::<OwnedConfigProgram, ConfigConversionError>(
                ConfigConversionError::InvalidRevealHashSize(7)
            )
        );
    }
}
