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
    pub fn is_packable(&self) -> bool {
        use Type::*;
        match self {
            Address(_) => true,
            Bls12381Fr(_) => true,
            Bls12381G1(_) => true,
            Bls12381G2(_) => true,
            Bool(_) => true,
            Bytes(_) => true,
            ChainId(_) => true,
            Contract(_, _) => true,
            Int(_) => true,
            Key(_) => true,
            KeyHash(_) => true,
            Lambda(_, _, _) => true,
            List(_, ty) => ty.is_packable(),
            Map(_, _, ty) => ty.is_packable(),
            Mutez(_) => true,
            Nat(_) => true,
            Never(_) => true,
            Option(_, ty) => ty.is_packable(),
            Or(_, ty1, ty2) => ty1.is_packable() && ty2.is_packable(),
            Pair(_, ty1, ty2) => ty1.is_packable() && ty2.is_packable(),
            SaplingTransaction(_, _) => true,
            Set(_, ty) => ty.is_packable(),
            Signature(_) => true,
            String(_) => true,
            Timestamp(_) => true,
            Unit(_) => true,
            Operation(..) => false,
            Ticket(..) => false,
            BigMap(..) => false,
            SaplingState(..) => false,
            Ext(..) => false,
        }
    }
}
