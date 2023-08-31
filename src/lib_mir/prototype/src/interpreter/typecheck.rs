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
use num_bigint::TryFromBigIntError;

use super::stack::Stack;
use crate::ast::{Instr, Parsed, TValue, Type, Typechecked, UValue};
use crate::interpreter::interpret::{add, mul};

pub fn typecheck(
    code: Vec<Instr<Parsed>>,
    inp: &mut Stack<Type<Parsed>>,
) -> Result<Vec<Instr<Typechecked>>, TcError> {
    code.into_iter()
        .map(|instr| typecheck_one(instr, inp))
        .collect()
}

#[derive(Debug, PartialEq, Eq)]
pub enum TcError {
    NotEnoughItemsOnStack,
    NoMatchingOverload,
    BadInstr(BadInstr),
    ValueError,
    DeadCode,
    TypeMismatch,
}

#[derive(Debug, PartialEq, Eq)]
pub enum BadInstr {
    Dup0,
}

fn typecheck_one(
    i: Instr<Parsed>,
    inp: &mut Stack<Type<Parsed>>,
) -> Result<Instr<Typechecked>, TcError> {
    use Instr::*;
    if inp.is_failed() {
        Err(TcError::DeadCode)?
    }
    super::macros::match_instr!(TcError::NotEnoughItemsOnStack; Err(TcError::NoMatchingOverload); i;
      inp: Type<Parsed>;
      simp Push((ty, val)) [0] => { [] => (typecheck_value(*val, &ty)?) [ty] },
      simp Add(_) [2] => {
        [Type::Int(_), Type::Int(_)] => (add::int_int as _) [Type::Int(())],
        [Type::Nat(_), Type::Int(_)] => (add::nat_int as _) [Type::Int(())],
        [Type::Int(_), Type::Nat(_)] => (add::int_nat as _) [Type::Int(())],
        [Type::Nat(_), Type::Nat(_)] => (add::nat_nat as _) [Type::Nat(())],
      },
      simp Mul(_) [2] => {
        [Type::Int(_), Type::Int(_)] => (mul::int_int as _) [Type::Int(())],
        [Type::Nat(_), Type::Int(_)] => (mul::nat_int as _) [Type::Int(())],
        [Type::Int(_), Type::Nat(_)] => (mul::int_nat as _) [Type::Int(())],
        [Type::Nat(_), Type::Nat(_)] => (mul::nat_nat as _) [Type::Nat(())],
      },
      simp Int(meta) [1] => { [Type::Nat(())] => copy [Type::Int(())] },
      simp Swap(meta) [2] => { [l, r] => copy [r, l] },
      simp Gt(meta) [1] => { [Type::Int(..)] => copy [Type::Bool(())] },
      simp Le(meta) [1] => { [Type::Int(..)] => copy [Type::Bool(())] },
      simp Drop(meta) [1] => { [_] => copy [] },
      raw DropN(meta, n) [n] => copy; {
        inp.drain_top(n);
      },
      raw Dup(meta) [1] => copy; { inp.push(inp.top().unwrap().clone()) },
      raw DupN(_, 0) [0] => { Err(TcError::BadInstr(BadInstr::Dup0)) },
      raw DupN(meta, n) [n] => copy; {
        inp.push(inp.get(n).unwrap().clone());
      },
      raw Dip(meta, instrs) [1] => {
        let tc_instrs = inp.protect(1, |inp1| typecheck(instrs, inp1)).ok_or(TcError::DeadCode)??;
        Ok(Dip(meta, tc_instrs))
      },
      raw DipN(meta, n, instrs) [n] => {
        let tc_instrs = inp.protect(n, |inp1| typecheck(instrs, inp1)).ok_or(TcError::DeadCode)??;
        Ok(DipN(meta, n, tc_instrs))
      },
      raw If(meta, b_true, b_false) [1] => {
        let cond = inp.pop().unwrap();
        match cond {
          Type::Bool(_) => (),
          _ => Err(TcError::NoMatchingOverload)?,
        }
        let mut inp_copy = inp.clone();
        let b_true_tc = typecheck(b_true, &mut inp_copy)?;
        let b_false_tc = typecheck(b_false, inp)?;
        if inp.is_ok() && inp_copy.is_ok() && inp != &inp_copy {
          Err(TcError::TypeMismatch)?;
        }
        Ok(If(meta, b_true_tc, b_false_tc))
      },
      raw Nest(meta, content) [0] => {
        Ok(Nest(meta, typecheck(content, inp)?))
      },
      raw Loop(meta, body) [1] => {
        // this may look strange, but typing rules are as thus:
        //   instr :: A => bool : A
        // ---------------------------
        // LOOP instr :: bool : A => A
        // Notice output stack of instr is the input stack of LOOP instr.
        // Hence we save the input stack to compare against later.
        let inp_copy = inp.clone();
        let b = inp.pop().unwrap();
        match b {
          Type::Bool(..) => (),
          _ => Err(TcError::NoMatchingOverload)?,
        };
        let body_tc = typecheck(body, inp)?;
        if &inp_copy != inp {
          Err(TcError::TypeMismatch)?;
        }
        inp.pop(); // pops the bool left on the stack after typechecking body
        Ok(Loop(meta, body_tc))
      }
    )
}

macro_rules! tc_val {
    (rec2; $tyname:ident; $res:block) => { $res };
    (rec2; $tyname:ident; $res:tt) => { TValue::$tyname$res };
    (rec1; $val:expr; $tyname:ident; raw $($rest:tt)*) => {
      $($rest)*
    };
    (rec1; $val:expr; $tyname:ident; $($vname:ident $vargs:tt $(if $cond:expr)? => $res:tt ),* $(,)*) => {
      match $val {
        $(UValue::$vname $vargs $(if $cond)? => tc_val!(rec2; $tyname; $res) ,)*
        _ => Err(TcError::ValueError)?,
      }
    };
    ($ty:expr; $val:expr; $( $tyname:ident $tyargs:tt => { $($body:tt)* } ),* $(,)* ) => {
      match $ty {
        $( Type::$tyname $tyargs => tc_val!(rec1; $val; $tyname; $($body)*) ),*
      }
    };
}

impl From<TryFromBigIntError<BigInt>> for TcError {
    fn from(_: TryFromBigIntError<BigInt>) -> Self {
        TcError::ValueError
    }
}

pub fn typecheck_value(
    val: UValue<Parsed>,
    ty: &Type<Parsed>,
) -> Result<TValue<Typechecked>, TcError> {
    let res = tc_val!(ty; val;
        Int(..) => { Int(_, val) => ((), val) },
        Nat(..) => { Int(_, val) => ((), val.try_into()?) },
        Bool(..) => {
            True(..) => ((), true),
            False(..) => ((), false),
        },
    );
    Ok(res)
}
