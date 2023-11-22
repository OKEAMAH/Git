/******************************************************************************/
/*                                                                            */
/* SPDX-License-Identifier: MIT                                               */
/* Copyright (c) [2023] Serokell <hi@serokell.io>                             */
/*                                                                            */
/******************************************************************************/

use std::rc::Rc;

use super::{Instruction, Micheline};

#[derive(Debug, Clone, Eq, PartialEq)]
pub enum Lambda<'a> {
    Lambda {
        micheline_code: Micheline<'a>,
        code: Rc<[Instruction<'a>]>,
    },
    LambdaRec {
        micheline_code: Micheline<'a>,
        code: Rc<[Instruction<'a>]>,
    },
}
