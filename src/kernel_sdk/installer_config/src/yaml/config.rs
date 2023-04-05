// SPDX-FileCopyrightText: 2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use std::io::Read;

use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, PartialEq, Debug, Clone)]
#[serde(deny_unknown_fields)]
pub(crate) struct CopyArgs {
    pub(crate) from: String,
    pub(crate) to: String,
}

#[derive(Serialize, Deserialize, PartialEq, Debug, Clone)]
#[serde(deny_unknown_fields)]
pub(crate) struct MoveArgs {
    pub(crate) from: String,
    pub(crate) to: String,
}

#[derive(PartialEq, Debug, Clone)]
pub enum StringEncoding {
    Hex,
    Base58,
}

impl StringEncoding {
    fn to_str(&self) -> &'static str {
        match self {
            StringEncoding::Hex => "hex",
            StringEncoding::Base58 => "b58",
        }
    }
}

#[derive(PartialEq, Debug, Clone)]
pub enum IntEncoding {
    BigEndian,
    LittleEndian,
}

impl IntEncoding {
    fn to_str(&self) -> &'static str {
        match self {
            IntEncoding::BigEndian => "be",
            IntEncoding::LittleEndian => "le",
        }
    }
}

#[derive(Serialize, Deserialize, PartialEq, Debug, Clone)]
#[serde(try_from = "raw_encodings::ValueSerDeser")]
#[serde(into = "raw_encodings::ValueSerDeser")]
pub enum Value {
    I32(i32, IntEncoding),
    U32(u32, IntEncoding),
    U8(u8),
    String(String, StringEncoding),
}

#[derive(Serialize, Deserialize, PartialEq, Debug, Clone)]
#[serde(deny_unknown_fields)]
pub(crate) struct SetArgs {
    pub(crate) set: String,
    pub(crate) value: Value,
}

#[derive(Serialize, Deserialize, PartialEq, Debug, Clone)]
#[serde(deny_unknown_fields)]
pub struct RevealArgs {
    // Hash in hex form
    pub reveal: String,
    // Path
    pub to: String,
}

#[derive(Serialize, Deserialize, PartialEq, Debug, Clone)]
#[serde(try_from = "raw_encodings::InstrSerDeser")]
#[serde(into = "raw_encodings::InstrSerDeser")]
pub(crate) enum Instr {
    Copy(CopyArgs),
    Move(MoveArgs),
    Delete(String),

    // Uncomment this
    // #[serde(untagged)]
    // when this one is merged https://github.com/serde-rs/serde/pull/2403
    Set(SetArgs),

    // Uncomment this
    // #[serde(untagged)]
    // when this one is merged https://github.com/serde-rs/serde/pull/2403
    Reveal(RevealArgs),
}

#[derive(Serialize, Deserialize, PartialEq, Debug)]
pub struct InstallerConfig {
    pub(crate) instructions: Vec<Instr>,
}

impl InstallerConfig {
    pub fn from_string(s: &str) -> serde_yaml::Result<InstallerConfig> {
        serde_yaml::from_str(s)
    }

    pub fn from_reader<R: Read>(rdr: R) -> serde_yaml::Result<InstallerConfig> {
        serde_yaml::from_reader(rdr)
    }
}

mod raw_encodings {
    use super::*;
    use serde_yaml::Number as YamlNumber;

    #[derive(Serialize, Deserialize, PartialEq, Debug, Clone)]
    #[serde(untagged)]
    enum Literal {
        Number(YamlNumber),
        String(String),
    }

    #[derive(Serialize, Deserialize, PartialEq, Debug, Clone)]
    #[serde(deny_unknown_fields)]
    pub(super) struct ValueSerDeser {
        literal: Literal,
        #[serde(rename = "type")]
        type_: String,
    }

    fn to_u8(v: YamlNumber) -> Result<u8, String> {
        if v.is_u64() {
            Ok(v.as_u64().unwrap() as u8)
        } else {
            Err(format!("byte should be a positive number, got: {}", v))
        }
    }

    fn to_u32(v: YamlNumber) -> Result<u32, String> {
        if v.is_u64() {
            Ok(v.as_u64().unwrap() as u32)
        } else {
            Err(format!("u32 should be a positive number, got: {}", v))
        }
    }

    fn to_i32(n: YamlNumber) -> Result<i32, String> {
        if n.is_u64() && n.as_u64().unwrap() <= i32::max_value() as u64 {
            Ok(n.as_u64().unwrap() as i32)
        } else if n.is_i64() && n.as_i64().unwrap() >= i32::min_value() as i64 {
            Ok(n.as_i64().unwrap() as i32)
        } else {
            Err(format!("{} doesn't fit into i32 boundaries", n))
        }
    }

    impl TryFrom<ValueSerDeser> for Value {
        type Error = String;

        fn try_from(value: ValueSerDeser) -> Result<Self, Self::Error> {
            use IntEncoding::*;
            use StringEncoding::*;
            match (value.type_.as_str(), value.literal) {
                ("hex", Literal::String(s)) => Ok(Value::String(s, Hex)),
                ("b58", Literal::String(s)) => Ok(Value::String(s, Base58)),
                ("u8", Literal::Number(n)) => to_u8(n).map(Value::U8),
                ("u32_le", Literal::Number(n)) => {
                    to_u32(n).map(|x| Value::U32(x, LittleEndian))
                }
                ("u32_be", Literal::Number(n)) => {
                    to_u32(n).map(|x| Value::U32(x, BigEndian))
                }
                ("i32_le", Literal::Number(n)) => {
                    to_i32(n).map(|x| Value::I32(x, LittleEndian))
                }
                ("i32_be", Literal::Number(n)) => {
                    to_i32(n).map(|x| Value::I32(x, BigEndian))
                }
                (tp, vl) => Err(format!(
                    "Unsupported type {}, or value {:?} has different type",
                    tp, vl
                )),
            }
        }
    }

    #[allow(clippy::from_over_into)]
    impl Into<ValueSerDeser> for Value {
        fn into(self) -> ValueSerDeser {
            use Value::*;
            match self {
                I32(x, enc) => ValueSerDeser {
                    literal: Literal::Number(x.into()),
                    type_: "i32_".to_owned() + enc.to_str(),
                },
                U32(x, enc) => ValueSerDeser {
                    literal: Literal::Number(x.into()),
                    type_: "u32_".to_owned() + enc.to_str(),
                },
                U8(x) => ValueSerDeser {
                    literal: Literal::Number(x.into()),
                    type_: "u32".to_owned(),
                },
                String(s, enc) => ValueSerDeser {
                    literal: Literal::String(s),
                    type_: enc.to_str().to_owned(),
                },
            }
        }
    }

    // The only purpose of this type is
    // to define serialisation and deserialisation easily.
    // Converted back and forth to Instr,
    // this trick is necessary because currently flattening/untagging
    // of enum variants is not supported,
    // see here https://github.com/serde-rs/serde/issues/1402
    // related PR https://github.com/serde-rs/serde/pull/2403
    #[derive(Serialize, Deserialize, PartialEq, Debug)]
    pub(super) struct InstrSerDeser {
        #[serde(skip_serializing_if = "Option::is_none")]
        copy: Option<CopyArgs>,

        #[serde(rename = "move")]
        #[serde(skip_serializing_if = "Option::is_none")]
        move_: Option<MoveArgs>,

        #[serde(skip_serializing_if = "Option::is_none")]
        delete: Option<String>,

        #[serde(flatten)]
        set: Option<SetArgs>,

        #[serde(flatten)]
        reveal: Option<RevealArgs>,
    }

    impl TryFrom<InstrSerDeser> for Instr {
        type Error = String;

        fn try_from(value: InstrSerDeser) -> Result<Self, Self::Error> {
            let sm = value.copy.is_some() as u32
                + value.move_.is_some() as u32
                + value.delete.is_some() as u32
                + value.set.is_some() as u32
                + value.reveal.is_some() as u32;

            if sm == 0 {
                Err("Neither of instructions deserialized".to_owned())
            } else if sm > 1 {
                Err(format!(
                    "More than one instruction deserialized {:#?}",
                    &value
                ))
            } else if value.copy.is_some() {
                Ok(Instr::Copy(value.copy.unwrap()))
            } else if value.move_.is_some() {
                Ok(Instr::Move(value.move_.unwrap()))
            } else if value.delete.is_some() {
                Ok(Instr::Delete(value.delete.unwrap()))
            } else if value.set.is_some() {
                Ok(Instr::Set(value.set.unwrap()))
            } else if value.reveal.is_some() {
                Ok(Instr::Reveal(value.reveal.unwrap()))
            } else {
                Err(format!("Unknown instruction {:#?}", value))
            }
        }
    }

    #[allow(clippy::from_over_into)]
    impl Into<InstrSerDeser> for Instr {
        fn into(self) -> InstrSerDeser {
            let default = InstrSerDeser {
                copy: None,
                move_: None,
                delete: None,
                set: None,
                reveal: None,
            };
            match self {
                Instr::Copy(c) => InstrSerDeser {
                    copy: Some(c),
                    ..default
                },
                Instr::Move(m) => InstrSerDeser {
                    move_: Some(m),
                    ..default
                },
                Instr::Delete(d) => InstrSerDeser {
                    delete: Some(d),
                    ..default
                },
                Instr::Set(s) => InstrSerDeser {
                    set: Some(s),
                    ..default
                },
                Instr::Reveal(r) => InstrSerDeser {
                    reveal: Some(r),
                    ..default
                },
            }
        }
    }
}

#[cfg(test)]
mod test {

    use crate::yaml::{
        config::{Instr, SetArgs, Value},
        RevealArgs,
    };

    use super::IntEncoding::*;
    use super::StringEncoding::*;
    use super::{CopyArgs, InstallerConfig, MoveArgs};
    use std::fs::read_to_string;

    #[test]
    fn encode() {
        let instructions = InstallerConfig {
            instructions: vec![
                Instr::Copy(CopyArgs {
                    from: "/hello/path".to_owned(),
                    to: "/to/path".to_owned(),
                }),
                Instr::Move(MoveArgs {
                    from: "/hello/path".to_owned(),
                    to: "/to/path".to_owned(),
                }),
                Instr::Delete("/path".to_owned()),
                Instr::Set(SetArgs {
                    set: "/path".to_owned(),
                    value: Value::U32(1000, LittleEndian),
                }),
                Instr::Reveal(RevealArgs {
                    reveal: "109aefeh".to_owned(),
                    to: "/path".to_owned(),
                }),
            ],
        };
        let yaml = serde_yaml::to_string(&instructions).unwrap();
        let expected = read_to_string("resources/config_example1.yml").unwrap();
        assert_eq!(expected.trim(), yaml.trim());
    }

    #[test]
    fn decode_atoms() {
        let value_b58_yaml = "
        literal: BLpk434sfasdlkfjsad12348
        type: b58
        ";

        let value_b58 = serde_yaml::from_str::<Value>(value_b58_yaml).unwrap();
        assert_eq!(
            value_b58,
            Value::String("BLpk434sfasdlkfjsad12348".to_owned(), Base58)
        );

        let value_u32le_yaml = "
        literal: 100
        type: u32_le
        ";

        let value_b58 = serde_yaml::from_str::<Value>(value_u32le_yaml).unwrap();
        assert_eq!(value_b58, Value::U32(100, LittleEndian));

        let set_yaml = "
        set: /path/to/set/r3
        value:
            literal: 4f3423facd
            type: hex";
        let set = serde_yaml::from_str::<SetArgs>(set_yaml).unwrap();

        assert_eq!(
            set,
            SetArgs {
                set: "/path/to/set/r3".to_owned(),
                value: Value::String("4f3423facd".to_owned(), Hex)
            }
        );
    }

    #[test]
    fn decode_full() {
        let source_yaml = read_to_string("resources/config_example2.yml").unwrap();
        let instrs = serde_yaml::from_str::<InstallerConfig>(&source_yaml).unwrap();
        let expected_instrs = InstallerConfig {
            instructions: vec![
                Instr::Copy(CopyArgs {
                    from: "/from/path".to_owned(),
                    to: "/to/path/hello".to_owned(),
                }),
                Instr::Move(MoveArgs {
                    from: "/move/path/from".to_owned(),
                    to: "/move/path/to".to_owned(),
                }),
                Instr::Delete("/delete/path".to_owned()),
                Instr::Set(SetArgs {
                    set: "/path/to/set".to_owned(),
                    value: Value::I32(50, LittleEndian),
                }),
                Instr::Set(SetArgs {
                    set: "/path/to/set2".to_owned(),
                    value: Value::U32(120, BigEndian),
                }),
                Instr::Set(SetArgs {
                    set: "/path/to/set2".to_owned(),
                    value: Value::String("BLpk434sfasdlkfjsad12348".to_owned(), Base58),
                }),
                Instr::Set(SetArgs {
                    set: "/path/to/set/r3".to_owned(),
                    value: Value::String("4f3423facd".to_owned(), Hex),
                }),
                Instr::Reveal(RevealArgs {
                    reveal: "aea02c3232443".to_owned(),
                    to: "/path/reveal/to".to_owned(),
                }),
            ],
        };
        assert_eq!(expected_instrs, instrs);
    }
}
