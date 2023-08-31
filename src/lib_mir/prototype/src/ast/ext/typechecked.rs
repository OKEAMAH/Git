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

use crate::ast::{InstrExt, TValue, TValueExt};

pub enum Typechecked {}

impl InstrExt for Typechecked {
    type Push = TValue<Typechecked>;
    type Add = fn(TValue<Typechecked>, TValue<Typechecked>) -> TValue<Typechecked>;
    type Drop = ();
    type DropN = ();
    type Dup = ();
    type DupN = ();
    type Dip = ();
    type DipN = ();
    type Swap = ();
    type If = ();
    type Nest = ();
    type Loop = ();
    type Gt = ();
    type Le = ();
    type Int = ();
    type Mul = fn(TValue<Typechecked>, TValue<Typechecked>) -> TValue<Typechecked>;
}

impl TValueExt for Typechecked {
    type Int = ();
    type Nat = ();
    type Bool = ();
}
