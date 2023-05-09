// SPDX-FileCopyrightText: 2023 TriliTech <contact@trili.tech>
//
// SPDX-License-Identifier: MIT

use serde::{Deserialize, Serialize};

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
}
