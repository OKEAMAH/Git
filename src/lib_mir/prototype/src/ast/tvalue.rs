/******************************************************************************/
/*                                                                            */
/* MIT License                                                                */
/* Copyright (c) 2023 Serokell <hi@serokell.io>                               */
/*                                                                            */
/* Permission is hereby granted, free of charge, to any person obtaining a    */
/* copy of this software and associated documentation files (the "Software"), */
/* to deal in the Software without restriction, including without limitation  */
/* the rights to use, copy, modify, merge, publish, distribute, sublicense,   */
/* and/or sell copies of the Software, and to permit persons to whom the      */
/* Software is furnished to do so, subject to the following conditions:       */
/*                                                                            */
/* The above copyright notice and this permission notice shall be included    */
/* in all copies or substantial portions of the Software.                     */
/*                                                                            */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR */
/* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,   */
/* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL    */
/* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER */
/* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING    */
/* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER        */
/* DEALINGS IN THE SOFTWARE.                                                  */
/*                                                                            */
/******************************************************************************/

use ascii::AsciiString;
use num_bigint::{BigInt, BigUint};
use std::collections::BTreeSet;

use crate::ast::{Instr, InstrExt};

pub mod comparable;
pub mod typechecked;

pub use comparable::Comparable;

super::macros::ttg_extend!(
    #[repr(u8)] // required as we're doing some unsafe shenanigans
    #[allow(dead_code)]
    @derive(Debug, Clone, PartialEq, Eq)
    pub enum TValue<Ext: TValueExt + InstrExt> {
        Unit(),
        Option(Option<Box<Self>>),
        List(Vec<Self>),
        Set(BTreeSet<comparable::Comparable<Self>>),
        Pair(Pair<Box<Self>, Box<Self>>),
        Or(Or<Box<Self>, Box<Self>>),
        Lambda(Vec<Instr<Ext>>),
        Int(BigInt),
        Nat(BigUint),
        String(AsciiString),
        Bytes(Vec<u8>),
        Mutez(u64),
        Bool(bool),

        Key(), // todo
        Signature(), // todo
        ChainId(), // todo
        Operation(), // todo
        Contract(), // todo
        Ticket(), // todo
        Map(), // todo
        BigMap(), // todo
        KeyHash(), // todo
        Bls12381Fr(), // todo
        Bls12381G1(), // todo
        Bls12381G2(), // todo
        Timestamp(), // todo
        Address(), // todo
        SaplingState(), // todo
        SaplingTransaction(), // todo
        Never(), // todo
    }
);

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord)]
pub enum Or<L, R> {
    Left(L),
    Right(R),
}

impl<T> Or<T, T> {
    pub fn map<U, F: Fn(T) -> U>(self, f: F) -> Or<U, U> {
        use Or::*;
        match self {
            Left(x) => Left(f(x)),
            Right(x) => Right(f(x)),
        }
    }

    pub fn as_ref(&self) -> Or<&T, &T> {
        use Or::*;
        match self {
            Left(x) => Left(x),
            Right(x) => Right(x),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord)]
pub struct Pair<L, R>(pub L, pub R);

impl<T> Pair<T, T> {
    pub fn map<U, F: Fn(T) -> U>(self, f: F) -> Pair<U, U> {
        Pair(f(self.0), f(self.1))
    }

    pub fn as_ref(&self) -> Pair<&T, &T> {
        Pair(&self.0, &self.1)
    }
}

impl<Ext: TValueExt + InstrExt> TValue<Ext> {
    pub fn new_pair(meta: <Ext as TValueExt>::Pair, l: Self, r: Self) -> Self {
        Self::Pair(meta, Pair(Box::new(l), Box::new(r)))
    }

    pub fn new_list(meta: <Ext as TValueExt>::List, val: Vec<Self>) -> Self {
        Self::List(meta, val)
    }

    pub fn discriminant(&self) -> u8 {
        // https://doc.rust-lang.org/reference/items/enumerations.html#pointer-casting
        unsafe { *(self as *const Self as *const u8) }
    }
}
