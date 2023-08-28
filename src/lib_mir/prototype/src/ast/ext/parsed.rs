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

use crate::ast::{InstrExt, Type, TypeExt, UValue, UValueExt, Void};

pub enum Parsed {}

impl UValueExt for Parsed {
    type Int = ();
    type String = ();
    type Bytes = ();
    type Unit = ();
    type True = ();
    type False = ();
    type Pair = ();
    type Left = ();
    type Right = ();
    type Some = ();
    type None = ();
    type Seq = ();
    type LambdaRec = ();
    type Instr = ();
    type Ext = Void;
}

impl InstrExt for Parsed {
    type Car = ();
    type Cdr = ();
    type Pair = ();
    type Push = (Type<Parsed>, Box<UValue<Parsed>>);
    type Nil = Type<Parsed>;
    type Add = ();
    type Drop = ();
    type DropN = ();
    type Dup = ();
    type DupN = ();
    type Dip = ();
    type DipN = ();
    type Swap = ();
    type Compare = ();
    type PairN = ();
    type Unpair = ();
    type UnpairN = ();
    type Dig = ();
    type Dug = ();
    type Failwith = ();
    type Never = ();
    type If = ();
    type Nest = ();
    type Unit = ();
    type Loop = ();
    type Gt = ();
    type Le = ();
    type Int = ();
    type Mul = ();
}

impl TypeExt for Parsed {
    type Key = ();
    type Unit = ();
    type Signature = ();
    type ChainId = ();
    type Option = ();
    type List = ();
    type Set = ();
    type Operation = ();
    type Contract = ();
    type Ticket = ();
    type Pair = ();
    type Or = ();
    type Lambda = ();
    type Map = ();
    type BigMap = ();
    type Int = ();
    type Nat = ();
    type String = ();
    type Bytes = ();
    type Mutez = ();
    type Bool = ();
    type KeyHash = ();
    type Bls12381Fr = ();
    type Bls12381G1 = ();
    type Bls12381G2 = ();
    type Timestamp = ();
    type Address = ();
    type SaplingState = ();
    type SaplingTransaction = ();
    type Never = ();
    type Ext = Void;
}
