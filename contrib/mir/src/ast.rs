/******************************************************************************/
/*                                                                            */
/* SPDX-License-Identifier: MIT                                               */
/* Copyright (c) [2023] Serokell <hi@serokell.io>                             */
/*                                                                            */
/******************************************************************************/

pub mod comparable;
pub mod michelson_address;
pub mod michelson_list;
pub mod or;
pub mod overloads;

use std::collections::BTreeMap;
pub use tezos_crypto_rs::hash::ChainId;
use typed_arena::Arena;

use crate::{
    gas::{tc_cost, Gas, OutOfGas},
    lexer::Prim,
};

pub use michelson_address::{Address, AddressError};
pub use michelson_list::MichelsonList;
pub use or::Or;

#[derive(Debug, Clone, Eq, PartialEq)]
pub enum Micheline<'a> {
    Int(i128),
    String(String),
    Bytes(Vec<u8>),
    App(Prim, &'a [Micheline<'a>], Vec<&'a str>),
    Seq(&'a [Micheline<'a>]),
}

#[derive(Debug, Clone, Eq, PartialEq)]
pub enum Type {
    Nat,
    Int,
    Bool,
    Mutez,
    String,
    Unit,
    Pair(Box<(Type, Type)>),
    Option(Box<Type>),
    List(Box<Type>),
    Operation,
    Map(Box<(Type, Type)>),
    Or(Box<(Type, Type)>),
    Contract(Box<Type>),
    Address,
    ChainId,
}

#[derive(Debug, Clone, Copy, Eq, PartialEq)]
enum TypeProperty {
    Comparable,
    Passable,
    Storable,
    Pushable,
    Packable,
    BigMapValue,
    Duplicable,
}

impl Type {
    #[inline(always)]
    fn prop(&self, gas: &mut Gas, prop: TypeProperty) -> Result<bool, OutOfGas> {
        use Type::*;
        gas.consume(tc_cost::TYPE_PROP_STEP)?;
        Ok(match self {
            Nat | Int | Bool | Mutez | String | Unit | Address | ChainId => true,
            Operation => match prop {
                TypeProperty::Comparable
                | TypeProperty::Passable
                | TypeProperty::Storable
                | TypeProperty::Pushable
                | TypeProperty::Packable
                | TypeProperty::BigMapValue => false,
                TypeProperty::Duplicable => true,
            },
            Pair(p) | Or(p) => p.0.prop(gas, prop)? && p.1.prop(gas, prop)?,
            Option(x) => x.prop(gas, prop)?,
            List(x) => match prop {
                TypeProperty::Comparable => false,
                TypeProperty::Passable
                | TypeProperty::Storable
                | TypeProperty::Pushable
                | TypeProperty::Packable
                | TypeProperty::BigMapValue
                | TypeProperty::Duplicable => x.prop(gas, prop)?,
            },
            Map(p) => match prop {
                TypeProperty::Comparable => false,
                TypeProperty::Passable
                | TypeProperty::Storable
                | TypeProperty::Pushable
                | TypeProperty::Packable
                | TypeProperty::BigMapValue
                | TypeProperty::Duplicable => p.1.prop(gas, prop)?,
            },
            Contract(_) => match prop {
                TypeProperty::Passable | TypeProperty::Packable | TypeProperty::Duplicable => true,
                TypeProperty::Comparable
                | TypeProperty::Storable
                | TypeProperty::Pushable
                | TypeProperty::BigMapValue => false,
            },
        })
    }

    pub fn is_comparable(&self, gas: &mut Gas) -> Result<bool, OutOfGas> {
        self.prop(gas, TypeProperty::Comparable)
    }

    pub fn is_passable(&self, gas: &mut Gas) -> Result<bool, OutOfGas> {
        self.prop(gas, TypeProperty::Passable)
    }

    pub fn is_storable(&self, gas: &mut Gas) -> Result<bool, OutOfGas> {
        self.prop(gas, TypeProperty::Storable)
    }

    pub fn is_pushable(&self, gas: &mut Gas) -> Result<bool, OutOfGas> {
        self.prop(gas, TypeProperty::Pushable)
    }

    pub fn is_duplicable(&self, gas: &mut Gas) -> Result<bool, OutOfGas> {
        self.prop(gas, TypeProperty::Duplicable)
    }

    #[allow(dead_code)] // while we don't have big_maps
    pub fn is_big_map_value(&self, gas: &mut Gas) -> Result<bool, OutOfGas> {
        self.prop(gas, TypeProperty::BigMapValue)
    }

    pub fn is_packable(&self, gas: &mut Gas) -> Result<bool, OutOfGas> {
        self.prop(gas, TypeProperty::Packable)
    }

    /// Returns abstract size of the type representation. Used for gas cost
    /// estimation.
    pub fn size_for_gas(&self) -> usize {
        use Type::*;
        match self {
            Nat | Int | Bool | Mutez | String | Unit | Operation | Address | ChainId => 1,
            Pair(p) | Or(p) | Map(p) => 1 + p.0.size_for_gas() + p.1.size_for_gas(),
            Option(x) | List(x) | Contract(x) => 1 + x.size_for_gas(),
        }
    }

    pub fn new_pair(l: Self, r: Self) -> Self {
        Self::Pair(Box::new((l, r)))
    }

    pub fn new_option(x: Self) -> Self {
        Self::Option(Box::new(x))
    }

    pub fn new_list(x: Self) -> Self {
        Self::List(Box::new(x))
    }

    pub fn new_map(k: Self, v: Self) -> Self {
        Self::Map(Box::new((k, v)))
    }

    pub fn new_or(l: Self, r: Self) -> Self {
        Self::Or(Box::new((l, r)))
    }

    pub fn new_contract(ty: Self) -> Self {
        Self::Contract(Box::new(ty))
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

/// Simple helper for constructing Elt values:
///
/// ```text
/// let val: Value = Elt("foo", 3).into()
/// ```
pub struct Elt<K, V>(pub K, pub V);

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

#[derive(Debug, Clone, Eq, PartialEq)]
pub enum TypedValue {
    Int(i128),
    Nat(u128),
    Mutez(i64),
    Bool(bool),
    String(String),
    Unit,
    Pair(Box<(TypedValue, TypedValue)>),
    Option(Option<Box<TypedValue>>),
    List(MichelsonList<TypedValue>),
    Map(BTreeMap<TypedValue, TypedValue>),
    Or(Box<Or<TypedValue, TypedValue>>),
    Address(Address),
    ChainId(ChainId),
    Contract(Address),
}

impl<'a> Micheline<'a> {
    fn new_pair(arena: &'a Arena<Micheline<'a>>, l: Micheline<'a>, r: Micheline<'a>) -> Self {
        Micheline::App(Prim::Pair, arena.alloc_extend([l, r]), vec![])
    }

    fn new_elt(arena: &'a Arena<Micheline<'a>>, l: Micheline<'a>, r: Micheline<'a>) -> Self {
        Micheline::App(Prim::Elt, arena.alloc_extend([l, r]), vec![])
    }

    fn new_or(arena: &'a Arena<Micheline<'a>>, l: Or<Micheline<'a>, Micheline<'a>>) -> Self {
        match l {
            Or::Left(x) => Micheline::App(Prim::Left, arena.alloc_extend([x]), vec![]),
            Or::Right(x) => Micheline::App(Prim::Right, arena.alloc_extend([x]), vec![]),
        }
    }

    fn new_option(arena: &'a Arena<Micheline<'a>>, l: Option<Micheline<'a>>) -> Self {
        match l {
            Some(l) => Micheline::App(Prim::Some, arena.alloc_extend([l]), vec![]),
            None => Micheline::App(Prim::None, &[], vec![]),
        }
    }
}

pub fn typed_value_to_value_optimized<'a>(
    arena: &'a Arena<Micheline<'a>>,
    tv: TypedValue,
) -> Micheline<'a> {
    use Micheline as V;
    use TypedValue as TV;
    let go = |x| typed_value_to_value_optimized(arena, x);
    match tv {
        TV::Int(i) => V::Int(i),
        TV::Nat(u) => V::Int(u.try_into().unwrap()),
        TV::Mutez(u) => V::Int(u.try_into().unwrap()),
        TV::Bool(true) => V::App(Prim::True, &[], vec![]),
        TV::Bool(false) => V::App(Prim::False, &[], vec![]),
        TV::String(s) => V::String(s),
        TV::Unit => V::App(Prim::Unit, &[], vec![]),
        // This transformation for pairs deviates from the optimized representation of the
        // reference implementation, because reference implementation optimizes the size of combs
        // and uses an untyped representation that is the shortest.
        TV::Pair(b) => V::new_pair(arena, go(b.0), go(b.1)),
        TV::List(l) => V::Seq(arena.alloc_extend(l.into_iter().map(go))),
        TV::Map(m) => V::Seq(
            arena.alloc_extend(
                m.into_iter()
                    .map(|(key, val)| V::new_elt(arena, go(key), go(val))),
            ),
        ),
        TV::Option(x) => V::new_option(arena, x.map(|x| go(*x))),
        TV::Or(x) => V::new_or(arena, x.map(|x| typed_value_to_value_optimized(arena, x))),
        TV::Address(x) => V::Bytes(x.to_bytes_vec()),
        TV::ChainId(x) => V::Bytes(x.into()),
        TV::Contract(x) => typed_value_to_value_optimized(arena, TV::Address(x)),
    }
}

impl TypedValue {
    pub fn new_pair(l: Self, r: Self) -> Self {
        Self::Pair(Box::new((l, r)))
    }

    pub fn new_option(x: Option<Self>) -> Self {
        Self::Option(x.map(Box::new))
    }

    pub fn new_or(x: Or<Self, Self>) -> Self {
        Self::Or(Box::new(x))
    }
}

#[derive(Debug, Eq, PartialEq, Clone)]
pub enum Instruction {
    Add(overloads::Add),
    Dip(Option<u16>, Vec<Self>),
    Drop(Option<u16>),
    Dup(Option<u16>),
    Gt,
    If(Vec<Self>, Vec<Self>),
    IfNone(Vec<Self>, Vec<Self>),
    Int,
    Loop(Vec<Self>),
    Push(TypedValue),
    Swap,
    Failwith(Type),
    Unit,
    Car,
    Cdr,
    Pair,
    /// `ISome` because `Some` is already taken
    ISome,
    Compare,
    Amount,
    Nil,
    Get(overloads::Get),
    Update(overloads::Update),
    Seq(Vec<Self>),
    Unpair,
    Cons,
    IfCons(Vec<Self>, Vec<Self>),
    Iter(overloads::Iter, Vec<Self>),
    IfLeft(Vec<Self>, Vec<Self>),
    ChainId,
    /// `ISelf` because `Self` is a reserved keyword
    ISelf,
}

pub type TypecheckedAST = Vec<Instruction>;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ContractScript {
    pub parameter: Type,
    pub storage: Type,
    pub code: Instruction,
}

#[cfg(test)]
macro_rules! app {
    ($prim:ident [$($args:expr),*]) => {
        Micheline::App($crate::lexer::Prim::$prim, &[$(Micheline::from($args)),*], vec![])
    };
    ($prim:ident) => {
        Micheline::App($crate::lexer::Prim::$prim, &[], vec![])
    };
}

#[cfg(test)]
macro_rules! seq {
    {$($elt:expr);* $(;)*} => {
        Micheline::Seq(&[$(Micheline::from($elt)),*])
    }
}

#[cfg(test)]
pub(crate) use {app, seq};
