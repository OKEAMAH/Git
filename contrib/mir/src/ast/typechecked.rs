/******************************************************************************/
/*                                                                            */
/* SPDX-License-Identifier: MIT                                               */
/* Copyright (c) [2023] Serokell <hi@serokell.io>                             */
/*                                                                            */
/******************************************************************************/

use super::{Instruction, Stage, Type, TypedValue};

#[derive(Debug, PartialEq, Eq, Clone)]
pub enum TypecheckedStage {}

impl Stage for TypecheckedStage {
    type AddMeta = overloads::Add;
    type PushValue = TypedValue;
    type NilType = ();
    type GetOverload = overloads::Get;
    type UpdateOverload = overloads::Update;
    type FailwithType = Type;
    type IterOverload = overloads::Iter;
}

pub type TypecheckedInstruction = Instruction<TypecheckedStage>;

pub mod overloads {
    #[derive(Debug, PartialEq, Eq, Clone, Copy)]
    pub enum Add {
        IntInt,
        NatNat,
        IntNat,
        NatInt,
        MutezMutez,
    }

    #[derive(Debug, PartialEq, Eq, Clone, Copy)]
    pub enum Get {
        Map,
    }

    #[derive(Debug, PartialEq, Eq, Clone, Copy)]
    pub enum Update {
        Map,
    }

    #[derive(Debug, PartialEq, Eq, Clone, Copy)]
    pub enum Iter {
        List,
        Map,
    }
}
