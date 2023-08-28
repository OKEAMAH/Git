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
use num_bigint::BigInt;

use crate::ast::instr::{Instr, InstrExt};

super::macros::ttg_extend!(
    @derive(Debug, Clone, PartialEq, Eq)
    pub enum UValue<Ext: UValueExt + InstrExt> {
        Int(BigInt),
        String(AsciiString),
        Bytes(Vec<u8>),
        Unit(),
        True(),
        False(),
        Pair(Box<Self>, Box<Self>),
        Left(Box<Self>),
        Right(Box<Self>),
        Some(Box<Self>),
        None(),
        Seq(Vec<Self>),
        LambdaRec(Vec<Instr<Ext>>),
        Instr(Instr<Ext>),
        Ext(),
    }
);

impl<Ext: UValueExt + InstrExt> UValue<Ext> {
    pub fn new_pair(meta: <Ext as UValueExt>::Pair, l: Self, r: Self) -> Self {
        Self::Pair(meta, Box::new(l), Box::new(r))
    }

    pub fn new_left(meta: Ext::Left, ty: Self) -> Self {
        Self::Left(meta, Box::new(ty))
    }

    pub fn new_right(meta: Ext::Right, ty: Self) -> Self {
        Self::Right(meta, Box::new(ty))
    }

    pub fn new_some(meta: Ext::Some, ty: Self) -> Self {
        Self::Some(meta, Box::new(ty))
    }
}
