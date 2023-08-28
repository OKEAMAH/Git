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
use crate::ast::{tvalue, Instr, TValue, Typechecked};

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
pub enum RuntimeError {
    Failed(TValue<Typechecked>),
}

fn interpret_one(
    i: &Instr<Typechecked>,
    inp: &mut Stack<TValue<Typechecked>>,
) -> Result<(), RuntimeError> {
    use Instr::*;
    super::macros::match_instr!(; unreachable!(); i; (); inp: TValue<Typechecked>;
      simp Car(_) [1] => { [TValue::Pair(_, tvalue::Pair(l, _))] => [*l] },
      simp Cdr(_) [1] => { [TValue::Pair(_, tvalue::Pair(_, r))] => [*r] },
      simp Pair(_) [2] => { [l, r] => [TValue::new_pair_tc(l, r)] },
      simp Unpair(_) [1] => { [TValue::Pair(_, tvalue::Pair(l, r))] => [*l, *r] },
      simp Push(val) [0] => { [] => [val.clone()] },
      simp Nil(_) [0] => { [] => [TValue::new_list_tc(vec![])] },
      simp Add(func) [2] => { [l, r] => [func(l, r)] },
      simp Mul(func) [2] => { [l, r] => [func(l, r)] },
      simp Int(_) [1] => { [TValue::Nat((), val)] => [TValue::Int((), val.into())] },
      simp Drop(_) [1] => { [_] => [] },
      simp Swap(_) [2] => { [l, r] => [r, l] },
      simp Compare(_) [2] => {
        [l, r] => [compare_impl(&l, &r)]
      },
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
        inp.protect(1, |inp1| interpret(instrs, inp1))?
      },
      raw DipN(_, n, instrs) [*n] => {
        inp.protect(*n, |inp1| interpret(instrs, inp1))?
      },
      raw PairN(_, n) [*n] => {
        let res = inp.drain_top(*n).reduce(|acc, e| TValue::new_pair_tc(e, acc)).unwrap();
        inp.push(res);
      },
      raw UnpairN(_, n) [1] => {
        let pair = inp.pop().unwrap();
        inp.reserve(*n);
        fill_unpair_n(n - 1, inp, pair)?;
      },
      raw Dig(_, 0) [0] => { }, // nop
      raw Dig(_, n) [*n] => {
        let elt = inp.remove(*n);
        inp.push(elt);
      },
      raw Dug(_, 0) [0] => { }, // nop
      raw Dug(_, n) [*n] => {
        let elt = inp.pop().unwrap();
        inp.insert(*n, elt);
      },
      raw Failwith(_) [1] => {
        Err(RuntimeError::Failed(inp.pop().unwrap()))?
      },
      raw Never(..) [1] => {
        unreachable!();
      },
      simp Unit(..) [0] => { [] => [TValue::Unit(())] },
      raw If(_, b_true, b_false) [1] => {
        if let TValue::Bool(_, b) = inp.pop().unwrap() {
          if b {
            interpret(b_true, inp)?;
          } else {
            interpret(b_false, inp)?;
          }
        } else {
          unreachable!();
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

fn compare_impl(one: &TValue<Typechecked>, other: &TValue<Typechecked>) -> TValue<Typechecked> {
    use std::cmp::Ordering::*;
    use tvalue::Comparable;
    let cmp_one = Comparable::try_from(one).expect(&format!("{:?} is comparable", one));
    let cmp_other = other
        .try_into()
        .expect(&format!("{:?} is comparable", other));
    match cmp_one.cmp(&cmp_other) {
        Equal => TValue::Int((), 0.into()),
        Less => TValue::Int((), (-1).into()),
        Greater => TValue::Int((), 1.into()),
    }
}

fn fill_unpair_n(
    n: usize,
    inp: &mut Stack<TValue<Typechecked>>,
    pair: TValue<Typechecked>,
) -> Result<(), RuntimeError> {
    if n == 0 {
        inp.push(pair);
    } else if let TValue::Pair(_, tvalue::Pair(el, rest)) = pair {
        fill_unpair_n(n - 1, inp, *rest)?;
        inp.push(*el);
    } else {
        unreachable!();
    }
    Ok(())
}

macro_rules! unsafe_match {
    ($pat:pat = $expr:expr => $($rest:tt)*) => {
        if let $pat = $expr {
            $($rest)*
        } else {
            unreachable!();
        }
    }
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
