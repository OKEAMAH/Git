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

use super::{Type, TypeExt};

impl<Ext: TypeExt> Type<Ext> {
    pub fn is_comparable(&self) -> bool {
        use Type::*;
        match self {
            Address(_) => true,
            Bool(_) => true,
            Bytes(_) => true,
            ChainId(_) => true,
            Int(_) => true,
            Key(_) => true,
            KeyHash(_) => true,
            Mutez(_) => true,
            Nat(_) => true,
            Never(_) => true,
            Option(_, ty) => ty.is_comparable(),
            Or(_, l, r) => l.is_comparable() && r.is_comparable(),
            Pair(_, l, r) => l.is_comparable() && r.is_comparable(),
            Signature(_) => true,
            String(_) => true,
            Timestamp(_) => true,
            Unit(_) => true,
            _ => false,
        }
    }
}
