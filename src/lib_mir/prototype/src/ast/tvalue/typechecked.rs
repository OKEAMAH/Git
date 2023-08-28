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

use crate::ast::{ext::typechecked::TValueMeta, tvalue::Pair, TValue, Typechecked};

impl TValue<Typechecked> {
    pub fn is_comparable(&self) -> bool {
        use TValue::*;
        match self {
            Address(..) => true,
            Bool(..) => true,
            Bytes(..) => true,
            ChainId(..) => true,
            Int(..) => true,
            Key(..) => true,
            KeyHash(..) => true,
            Mutez(..) => true,
            Nat(..) => true,
            Never(..) => true,
            Signature(..) => true,
            String(..) => true,
            Timestamp(..) => true,
            Unit(..) => true,
            Option(meta, ..) => meta.comparable,
            Or(meta, ..) => meta.comparable,
            Pair(meta, ..) => meta.comparable,
            _ => false,
        }
    }

    pub fn new_pair_tc(l: Self, r: Self) -> Self {
        TValue::Pair(
            TValueMeta {
                comparable: l.is_comparable() && r.is_comparable(),
            },
            Pair(Box::new(l), Box::new(r)),
        )
    }

    pub fn new_list_tc(elts: Vec<Self>) -> Self {
        TValue::new_list((), elts)
    }
}
