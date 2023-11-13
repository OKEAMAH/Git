/******************************************************************************/
/*                                                                            */
/* SPDX-License-Identifier: MIT                                               */
/* Copyright (c) [2023] Serokell <hi@serokell.io>                             */
/*                                                                            */
/******************************************************************************/

use typed_arena::Arena;

use crate::lexer::Prim;

#[derive(Debug, Clone, Eq, PartialEq)]
pub enum Micheline<'a> {
    Int(i128),
    String(String),
    Bytes(Vec<u8>),
    App(Prim, &'a [Micheline<'a>], Vec<&'a str>),
    Seq(&'a [Micheline<'a>]),
}

impl<'a> Micheline<'a> {
    // Helpers for building the `App` cases with few parameters
    pub fn prim0(prim: Prim) -> Self {
        Micheline::App(prim, &[], vec![])
    }

    pub fn prim1(arena: &'a Arena<Micheline<'a>>, prim: Prim, l: Micheline<'a>) -> Self {
        Micheline::App(prim, arena.alloc_extend([l]), vec![])
    }

    pub fn prim2(
        arena: &'a Arena<Micheline<'a>>,
        prim: Prim,
        l: Micheline<'a>,
        r: Micheline<'a>,
    ) -> Self {
        Micheline::App(prim, arena.alloc_extend([l, r]), vec![])
    }
}

macro_rules! valuefrom {
    ($( <$($gs:ident),*> $ty:ty, $cons:expr );* $(;)*) => {
        $(
        impl<'a, $($gs),*> From<$ty> for Micheline<'a> where $($gs: Into<Micheline<'a>>),* {
            fn from(x: $ty) -> Self {
                $cons(x)
            }
        }
        )*
    };
}

valuefrom! {
  <> i128, Micheline::Int;
  <> bool, |v: bool| { Micheline::App(if v { Prim::True } else { Prim::False }, &[], vec![]) };
  <> String, Micheline::String;
  <> (), |_| Micheline::App(Prim::Unit, &[], vec![]);
  <> Vec<u8>, Micheline::Bytes;
}

impl<'a> From<&str> for Micheline<'a> {
    fn from(s: &str) -> Self {
        Micheline::from(s.to_owned())
    }
}

/// Pattern synonym matching all type primitive applications. Useful for total
/// matches.
macro_rules! micheline_types {
    () => {
        Micheline::App(
            Prim::int
                | Prim::nat
                | Prim::bool
                | Prim::mutez
                | Prim::string
                | Prim::operation
                | Prim::unit
                | Prim::address
                | Prim::chain_id
                | Prim::pair
                | Prim::or
                | Prim::option
                | Prim::list
                | Prim::contract
                | Prim::map,
            ..,
        )
    };
}

/// Pattern synonym matching all Micheline literals. Useful for total
/// matches.
macro_rules! micheline_literals {
    () => {
        Micheline::Int(..) | Micheline::String(..) | Micheline::Bytes(..)
    };
}

/// Pattern synonym matching all field primitive applications. Useful for total
/// matches.
macro_rules! micheline_fields {
    () => {
        Micheline::App(Prim::parameter | Prim::storage | Prim::code, ..)
    };
}

/// Pattern synonym matching all instruction primitive applications. Useful for total
/// matches.
macro_rules! micheline_instructions {
    () => {
        Micheline::App(
            Prim::PUSH
                | Prim::INT
                | Prim::GT
                | Prim::LOOP
                | Prim::DIP
                | Prim::ADD
                | Prim::DROP
                | Prim::IF
                | Prim::IF_CONS
                | Prim::IF_LEFT
                | Prim::IF_NONE
                | Prim::FAILWITH
                | Prim::DUP
                | Prim::UNIT
                | Prim::CAR
                | Prim::CDR
                | Prim::PAIR
                | Prim::SOME
                | Prim::COMPARE
                | Prim::AMOUNT
                | Prim::NIL
                | Prim::GET
                | Prim::UPDATE
                | Prim::UNPAIR
                | Prim::CONS
                | Prim::ITER
                | Prim::CHAIN_ID
                | Prim::SELF
                | Prim::SWAP,
            ..,
        )
    };
}

/// Pattern synonym matching all value constructor primitive applications.
/// Useful for total matches.
macro_rules! micheline_values {
    () => {
        Micheline::App(
            Prim::True
                | Prim::False
                | Prim::Unit
                | Prim::None
                | Prim::Pair
                | Prim::Some
                | Prim::Elt
                | Prim::Left
                | Prim::Right,
            ..,
        )
    };
}

pub(crate) use {
    micheline_fields, micheline_instructions, micheline_literals, micheline_types, micheline_values,
};

#[cfg(test)]
pub mod test_helpers {

    /// Helper to reduce syntactic noise when constructing Micheline applications in tests.
    macro_rules! app {
        ($prim:ident [$($args:expr),* $(,)*]) => {
            $crate::ast::micheline::Micheline::App(
                $crate::lexer::Prim::$prim, &[$($crate::ast::micheline::Micheline::from($args)),*],
                vec![],
            )
        };
        ($prim:ident) => {
            $crate::ast::micheline::Micheline::App($crate::lexer::Prim::$prim, &[], vec![])
        };
    }

    /// Helper to reduce syntactic noise when constructing Micheline sequences in tests.
    macro_rules! seq {
        {$($elt:expr);* $(;)*} => {
            $crate::ast::micheline::Micheline::Seq(&[$($crate::ast::micheline::Micheline::from($elt)),*])
        }
    }

    pub(crate) use {app, seq};
}
