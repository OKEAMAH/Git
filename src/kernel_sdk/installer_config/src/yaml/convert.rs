// SPDX-FileCopyrightText: 2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use hex::FromHexError;
use tezos_crypto_rs::base58::{FromBase58Check, FromBase58CheckError};
use thiserror::Error;

use crate::{
    binary::{ConfigInstructionInitError, InstallerConfigProgram},
    yaml::Instr,
};

use super::{InstallerConfig, Value};

#[derive(Debug, Error)]
pub enum ConfigConversionError {
    #[error("Unable to convert hex to bytes: {0}.")]
    Hex(FromHexError),
    #[error("Unable to convert base58 to bytes: {0}.")]
    Base58(FromBase58CheckError),
    #[error("Unable to create an installer config instruction: {0}.")]
    InvalidInstruction(ConfigInstructionInitError),
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

impl TryFrom<InstallerConfig> for InstallerConfigProgram {
    type Error = ConfigConversionError;

    fn try_from(config: InstallerConfig) -> Result<Self, Self::Error> {
        use crate::binary::InstallerConfigInstruction;

        config
            .instructions
            .into_iter()
            .map(|instr| match instr {
                Instr::Copy(args) => {
                    InstallerConfigInstruction::copy_instr(args.from, args.to)
                        .map_err(ConfigConversionError::InvalidInstruction)
                }
                Instr::Move(args) => {
                    InstallerConfigInstruction::move_instr(args.from, args.to)
                        .map_err(ConfigConversionError::InvalidInstruction)
                }
                Instr::Delete(path) => InstallerConfigInstruction::delete_instr(path)
                    .map_err(ConfigConversionError::InvalidInstruction),

                Instr::Set(args) => args.value.try_into().and_then(|value| {
                    InstallerConfigInstruction::set_instr(args.set, value)
                        .map_err(ConfigConversionError::InvalidInstruction)
                }),
                Instr::Reveal(args) => {
                    Value::String(args.reveal, super::StringEncoding::Hex)
                        .try_into()
                        .and_then(|hash| {
                            InstallerConfigInstruction::reveal_instr(hash, args.to)
                                .map_err(ConfigConversionError::InvalidInstruction)
                        })
                }
            })
            .collect::<Result<Vec<InstallerConfigInstruction>, Self::Error>>()
            .map(InstallerConfigProgram::new)
    }
}
