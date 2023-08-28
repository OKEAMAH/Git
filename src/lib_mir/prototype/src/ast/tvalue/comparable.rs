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

use crate::ast::{TValue, Typechecked};

#[repr(transparent)]
#[derive(Debug, Clone, Copy, Eq, PartialEq)]
pub struct Comparable<T>(T);

impl PartialOrd for Comparable<&TValue<Typechecked>> {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.cmp(other))
    }
}

macro_rules! transparent_impl {
    (($($ty:tt)*); ($($pre_acc:tt)*)($($acc:tt)*)) => {
        impl PartialOrd for Comparable<$($ty)*> {
            fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
                Some(self.cmp(other))
            }
        }

        impl Ord for Comparable<$($ty)*> {
            fn cmp(&self, other: &Self) -> std::cmp::Ordering {
                Comparable($($pre_acc)*self.0$($acc)*).cmp(&Comparable($($pre_acc)*other.0$($acc)*))
            }
        }
    };
}

transparent_impl!((TValue<Typechecked>); (&) ());
transparent_impl!((Box<TValue<Typechecked>>); () (.as_ref()));
transparent_impl!((&Box<TValue<Typechecked>>); () (.as_ref()));

impl Ord for Comparable<&TValue<Typechecked>> {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        use std::cmp::Ordering::*;
        use TValue::*;
        macro_rules! cmp_het {
            () => {
                self.0.discriminant().cmp(&other.0.discriminant())
            };
        }
        match (&self.0, &other.0) {
            (Address(_), Address(_)) => todo!(),
            (Address(..), _) => cmp_het!(),

            (Bool(_, v1), Bool(_, v2)) => v1.cmp(v2),
            (Bool(..), _) => cmp_het!(),

            (Bytes(_, v1), Bytes(_, v2)) => v1.cmp(v2),
            (Bytes(..), _) => cmp_het!(),

            (ChainId(..), ChainId(..)) => todo!(),
            (ChainId(..), _) => cmp_het!(),

            (Int(_, v1), Int(_, v2)) => v1.cmp(v2),
            (Int(..), _) => cmp_het!(),

            (Key(..), Key(..)) => todo!(),
            (Key(..), _) => cmp_het!(),

            (KeyHash(..), KeyHash(..)) => todo!(),
            (KeyHash(..), _) => cmp_het!(),

            (Mutez(_, v1), Mutez(_, v2)) => v1.cmp(v2),
            (Mutez(..), _) => cmp_het!(),

            (Nat(_, v1), Nat(_, v2)) => v1.cmp(v2),
            (Nat(..), _) => cmp_het!(),

            (Never(..), Never(..)) => Equal,
            (Never(..), _) => cmp_het!(),

            (Option(_, v1), Option(_, v2)) => v1
                .as_ref()
                .map(Comparable)
                .cmp(&v2.as_ref().map(Comparable)),
            (Option(..), _) => cmp_het!(),

            (Or(_, v1), Or(_, v2)) => v1
                .as_ref()
                .map(Comparable)
                .cmp(&v2.as_ref().map(Comparable)),
            (Or(..), _) => cmp_het!(),

            (Pair(_, v1), Pair(_, v2)) => v1
                .as_ref()
                .map(Comparable)
                .cmp(&v2.as_ref().map(Comparable)),
            (Pair(..), _) => cmp_het!(),

            (Signature(..), Signature(..)) => todo!(),
            (Signature(..), _) => cmp_het!(),

            (String(_, v1), String(_, v2)) => v1.cmp(v2),
            (String(..), _) => cmp_het!(),

            (Timestamp(..), Timestamp(..)) => todo!(),
            (Timestamp(..), _) => cmp_het!(),

            (Unit(..), Unit(..)) => Equal,
            (Unit(..), _) => cmp_het!(),

            // non-comparable
            (List(..), _) => unreachable!(),
            (Set(..), _) => unreachable!(),
            (Operation(..), _) => unreachable!(),
            (Contract(..), _) => unreachable!(),
            (Ticket(..), _) => unreachable!(),
            (Lambda(..), _) => unreachable!(),
            (Map(..), _) => unreachable!(),
            (BigMap(..), _) => unreachable!(),
            (Bls12381Fr(..), _) => unreachable!(),
            (Bls12381G1(..), _) => unreachable!(),
            (Bls12381G2(..), _) => unreachable!(),
            (SaplingState(..), _) => unreachable!(),
            (SaplingTransaction(..), _) => unreachable!(),
        }
    }
}

#[derive(Debug)]
pub struct ComparableError;

impl TryFrom<TValue<Typechecked>> for Comparable<TValue<Typechecked>> {
    type Error = ComparableError;

    fn try_from(value: TValue<Typechecked>) -> Result<Self, Self::Error> {
        if value.is_comparable() {
            Ok(Comparable(value))
        } else {
            Err(ComparableError)
        }
    }
}

impl<'a> TryFrom<&'a TValue<Typechecked>> for Comparable<&'a TValue<Typechecked>> {
    type Error = ComparableError;

    fn try_from(value: &'a TValue<Typechecked>) -> Result<Self, Self::Error> {
        if value.is_comparable() {
            Ok(Comparable(value))
        } else {
            Err(ComparableError)
        }
    }
}

impl From<Comparable<TValue<Typechecked>>> for TValue<Typechecked> {
    fn from(value: Comparable<TValue<Typechecked>>) -> Self {
        value.0
    }
}
