/******************************************************************************/
/*                                                                            */
/* SPDX-License-Identifier: MIT                                               */
/* Copyright (c) [2023] Serokell <hi@serokell.io>                             */
/*                                                                            */
/******************************************************************************/

use super::Instruction;

#[derive(Debug, Clone, Eq, PartialEq)]
pub struct Lambda {
    pub recursive: bool,
    pub code: Vec<Instruction>,
}
