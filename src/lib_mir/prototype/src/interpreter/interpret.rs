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

use num_bigint::BigInt;

use super::stack::Stack;
use crate::ast::{Instr, TValue, Typechecked};

pub fn interpret(
    code: &Vec<Instr<Typechecked>>,
    inp: &mut Stack<TValue<Typechecked>>,
) -> Result<(), RuntimeError> {
    for instr in code {
        interpret_one(instr, inp)?;
    }
    Ok(())
}

#[derive(Debug, PartialEq, Eq)]
pub enum RuntimeError {}

macro_rules! unsafe_match {
    ($pat:pat = $expr:expr => $($rest:tt)*) => {
        if let $pat = $expr {
            $($rest)*
        } else {
            unreachable!();
        }
    }
}

fn interpret_one(
    i: &Instr<Typechecked>,
    inp: &mut Stack<TValue<Typechecked>>,
) -> Result<(), RuntimeError> {
    use Instr::*;
    super::macros::match_instr!(; unreachable!(); i; inp: TValue<Typechecked>;
      simp Push(val) [0] => { [] => [val.clone()] },
      simp Add(func) [2] => { [l, r] => [func(l, r)] },
      simp Mul(func) [2] => { [l, r] => [func(l, r)] },
      simp Int(_) [1] => { [TValue::Nat((), val)] => [TValue::Int((), val.into())] },
      simp Drop(_) [1] => { [_] => [] },
      simp Swap(_) [2] => { [l, r] => [r, l] },
      simp Gt(_) [1] => { [TValue::Int(_, val)] => [TValue::Bool((), val > 0.into())] },
      simp Le(_) [1] => { [TValue::Int(_, val)] => [TValue::Bool((), val <= 0.into())] },
      raw DropN(_, n) [*n] => {
        inp.drain_top(*n);
      },
      raw Dup(_) [1] => { inp.push(inp.top().unwrap().clone()) },
      raw DupN(_, n) [*n] => {
        inp.push(inp.get(*n).unwrap().clone());
      },
      raw Dip(_, instrs) [1] => {
        inp.protect(1, |inp1| interpret(instrs, inp1)).unwrap()?
      },
      raw DipN(_, n, instrs) [*n] => {
        inp.protect(*n, |inp1| interpret(instrs, inp1)).unwrap()?
      },
      raw If(_, b_true, b_false) [1] => {
        if unsafe_match!(TValue::Bool(_, b) = inp.pop().unwrap() => b) {
          interpret(b_true, inp)?;
        } else {
          interpret(b_false, inp)?;
        }
      },
      raw Nest(_, content) [0] => {
        interpret(content, inp)?;
      },
      raw Loop(_, body) [1] => {
        while let Some(TValue::Bool(_, true)) = inp.pop() {
          interpret(body, inp)?;
        }
      }
    );
    Ok(())
}

pub mod add {
    use super::{BigInt, TValue, Typechecked};
    use TValue::*;

    pub fn int_int(a: TValue<Typechecked>, b: TValue<Typechecked>) -> TValue<Typechecked> {
        unsafe_match!((Int(_, av), Int(_, bv)) = (a, b) => Int((), av + bv))
    }
    pub fn nat_int(a: TValue<Typechecked>, b: TValue<Typechecked>) -> TValue<Typechecked> {
        unsafe_match!((Nat(_, av), Int(_, bv)) = (a, b) => Int((), BigInt::from(av) + bv))
    }
    pub fn int_nat(a: TValue<Typechecked>, b: TValue<Typechecked>) -> TValue<Typechecked> {
        unsafe_match!((Int(_, av), Nat(_, bv)) = (a, b) => Int((), av + BigInt::from(bv)))
    }
    pub fn nat_nat(a: TValue<Typechecked>, b: TValue<Typechecked>) -> TValue<Typechecked> {
        unsafe_match!((Nat(_, av), Nat(_, bv)) = (a, b) => Nat((), av + bv))
    }
}
pub mod mul {
    use super::{BigInt, TValue, Typechecked};
    use TValue::*;

    pub fn int_int(a: TValue<Typechecked>, b: TValue<Typechecked>) -> TValue<Typechecked> {
        unsafe_match!((Int(_, av), Int(_, bv)) = (a, b) => Int((), av * bv))
    }
    pub fn nat_int(a: TValue<Typechecked>, b: TValue<Typechecked>) -> TValue<Typechecked> {
        unsafe_match!((Nat(_, av), Int(_, bv)) = (a, b) => Int((), BigInt::from(av) * bv))
    }
    pub fn int_nat(a: TValue<Typechecked>, b: TValue<Typechecked>) -> TValue<Typechecked> {
        unsafe_match!((Int(_, av), Nat(_, bv)) = (a, b) => Int((), av * BigInt::from(bv)))
    }
    pub fn nat_nat(a: TValue<Typechecked>, b: TValue<Typechecked>) -> TValue<Typechecked> {
        unsafe_match!((Nat(_, av), Nat(_, bv)) = (a, b) => Nat((), av * bv))
    }
}
