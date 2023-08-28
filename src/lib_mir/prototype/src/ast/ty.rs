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

use num_bigint::BigUint;

pub mod comparable;
pub mod packable;

super::macros::ttg_extend!(
    @derive(Debug, Clone, PartialEq, Eq)
    pub enum Type<Ext: TypeExt> {
        Key(),
        Unit(),
        Signature(),
        ChainId(),
        Option(Box<Self>),
        List(Box<Self>),
        Set(Box<Self>),
        Operation(),
        Contract(Box<Self>),
        Ticket(Box<Self>),
        Pair(Box<Self>, Box<Self>),
        Or(Box<Self>, Box<Self>),
        Lambda(Box<Self>, Box<Self>),
        Map(Box<Self>, Box<Self>),
        BigMap(Box<Self>, Box<Self>),
        Int(),
        Nat(),
        String(),
        Bytes(),
        Mutez(),
        Bool(),
        KeyHash(),
        Bls12381Fr(),
        Bls12381G1(),
        Bls12381G2(),
        Timestamp(),
        Address(),
        SaplingState(BigUint),
        SaplingTransaction(BigUint),
        Never(),
        Ext(),
    }
);

impl<Ext: TypeExt> Type<Ext> {
    pub fn new_pair(meta: Ext::Pair, l: Self, r: Self) -> Self {
        Self::Pair(meta, Box::new(l), Box::new(r))
    }

    pub fn new_or(meta: Ext::Or, l: Self, r: Self) -> Self {
        Self::Or(meta, Box::new(l), Box::new(r))
    }
    pub fn new_lambda(meta: Ext::Lambda, l: Self, r: Self) -> Self {
        Self::Lambda(meta, Box::new(l), Box::new(r))
    }
    pub fn new_map(meta: Ext::Map, l: Self, r: Self) -> Self {
        Self::Map(meta, Box::new(l), Box::new(r))
    }
    pub fn new_big_map(meta: Ext::BigMap, l: Self, r: Self) -> Self {
        Self::BigMap(meta, Box::new(l), Box::new(r))
    }

    pub fn new_list(meta: Ext::List, ty: Self) -> Self {
        Self::List(meta, Box::new(ty))
    }

    pub fn new_option(meta: Ext::Option, ty: Self) -> Self {
        Self::Option(meta, Box::new(ty))
    }

    pub fn new_set(meta: Ext::Set, ty: Self) -> Self {
        Self::Set(meta, Box::new(ty))
    }

    pub fn new_ticket(meta: Ext::Ticket, ty: Self) -> Self {
        Self::Ticket(meta, Box::new(ty))
    }

    pub fn new_contract(meta: Ext::Contract, ty: Self) -> Self {
        Self::Contract(meta, Box::new(ty))
    }
}
