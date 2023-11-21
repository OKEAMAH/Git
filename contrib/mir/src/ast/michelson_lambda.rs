/******************************************************************************/
/*                                                                            */
/* SPDX-License-Identifier: MIT                                               */
/* Copyright (c) [2023] Serokell <hi@serokell.io>                             */
/*                                                                            */
/******************************************************************************/

use super::{Instruction, Micheline};

#[derive(Debug, Clone, Eq, PartialEq)]
pub struct Lambda<'a> {
    pub recursive: bool,
    pub micheline_code: Micheline<'a>,
    pub code: Vec<Instruction<'a>>,
}
