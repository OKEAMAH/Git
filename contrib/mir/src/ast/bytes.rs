/******************************************************************************/
/*                                                                            */
/* SPDX-License-Identifier: MIT                                               */
/* Copyright (c) [2023] Serokell <hi@serokell.io>                             */
/*                                                                            */
/******************************************************************************/

#[cfg(test)]
use crate::ast::TypedValue;

#[cfg(test)]
#[track_caller]
pub fn mk_0x(hex: &str) -> TypedValue {
    TypedValue::Bytes(hex::decode(hex).unwrap_or_else(|e| panic!("Invalid hex: {e}")))
}
