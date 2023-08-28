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

use super::stack::{stk, Stack};
use crate::ast::tvalue::comparable::ComparableError;
use crate::ast::{
    ext::typechecked::TValueMeta, tvalue, tvalue::Or, Instr, InstrExt, Parsed, TValue, Type,
    Typechecked, UValue, UValueExt,
};
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
    Pair0,
    Pair1,
    Unpair0,
    Unpair1,
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
      simp Car(meta) [1] => { [Type::Pair((), l, _)] => copy [*l] },
      simp Cdr(meta) [1] => { [Type::Pair((), _, r)] => copy [*r] },
      simp Pair(meta) [2] => { [l, r] => copy [Type::new_pair((), l, r)] },
      simp Unpair(meta) [1] => { [Type::Pair(_, l, r)] => copy [*l, *r] },
      simp Push((ty, val)) [0] => { [] => (typecheck_value(*val, &ty)?) [ty] },
      simp Nil(ty) [0] => { [] => (()) [Type::new_list((), ty)] },
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
      simp Drop(meta) [1] => { [_] => copy [] },
      simp Swap(meta) [2] => { [l, r] => copy [r, l] },
      simp Compare(meta) [2] => {
        [l, r] if l == r && l.is_comparable() => copy [Type::Int(())]
      },
      simp Gt(meta) [1] => { [Type::Int(..)] => copy [Type::Bool(())] },
      simp Le(meta) [1] => { [Type::Int(..)] => copy [Type::Bool(())] },
      raw DropN(meta, n) [n] => copy; {
        inp.drain_top(n);
      },
      raw Dup(meta) [1] => copy; { inp.push(inp.top().unwrap().clone()) },
      raw DupN(_, 0) [0] => { Err(TcError::BadInstr(BadInstr::Dup0)) },
      raw DupN(meta, n) [n] => copy; {
        inp.push(inp.get(n).unwrap().clone());
      },
      raw Dip(meta, instrs) [1] => {
        let tc_instrs = inp.protect(1, |inp1| typecheck(instrs, inp1))?;
        Ok(Dip(meta, tc_instrs))
      },
      raw DipN(meta, n, instrs) [n] => {
        let tc_instrs = inp.protect(n, |inp1| typecheck(instrs, inp1))?;
        Ok(DipN(meta, n, tc_instrs))
      },
      raw PairN(_, 0) [0] => { Err(TcError::BadInstr(BadInstr::Pair0)) },
      raw PairN(_, 1) [0] => { Err(TcError::BadInstr(BadInstr::Pair1)) },
      raw PairN(meta, n) [n] => copy; {
        let res = inp.drain_top(n).reduce(|acc, e| Type::new_pair((), e, acc)).unwrap();
        inp.push(res);
      },
      raw UnpairN(_, 0) [0] => { Err(TcError::BadInstr(BadInstr::Unpair0)) },
      raw UnpairN(_, 1) [0] => { Err(TcError::BadInstr(BadInstr::Unpair1)) },
      raw UnpairN(meta, n) [1] => copy; {
        let pair = inp.pop().unwrap();
        inp.reserve(n);
        fill_unpair_n(n - 1, inp, pair)?;
      },
      raw Dig(meta, 0) [0] => copy; { }, // nop
      raw Dig(meta, n) [n] => copy; {
        let elt = inp.remove(n);
        inp.push(elt);
      },
      raw Dug(meta, 0) [0] => copy; { }, // nop
      raw Dug(meta, n) [n] => copy; {
        let elt = inp.pop().unwrap();
        inp.insert(n, elt);
      },
      simp Failwith(meta) [1] => { [v] if v.is_packable() => copy [!] },
      simp Never(meta) [1] => { [Type::Never(..)] => copy [!] },
      simp Unit(meta) [0] => { [] => copy [Type::Unit(())] },
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

fn fill_unpair_n(
    n: usize,
    inp: &mut Stack<Type<Parsed>>,
    pair: Type<Parsed>,
) -> Result<(), TcError> {
    if n == 0 {
        inp.push(pair);
    } else if let Type::Pair(_, el, rest) = pair {
        fill_unpair_n(n - 1, inp, *rest)?;
        inp.push(*el);
    } else {
        Err(TcError::NoMatchingOverload)?;
    }
    Ok(())
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

impl From<ComparableError> for TcError {
    fn from(_: ComparableError) -> Self {
        TcError::ValueError
    }
}

fn meta(comparable: bool) -> TValueMeta {
    TValueMeta { comparable }
}

pub fn typecheck_value(
    val: UValue<Parsed>,
    ty: &Type<Parsed>,
) -> Result<TValue<Typechecked>, TcError> {
    let res = tc_val!(ty; val;
        Ext(meta) => { raw meta.absurd() },
        Never(..) => { raw Err(TcError::ValueError)? },
        Int(..) => { Int(_, val) => ((), val) },
        Nat(..) => { Int(_, val) => ((), val.try_into()?) },
        Unit(..) => { Unit(..) => (()) },
        Option(_, ty) => {
            Some(_, val) => {
              let val_ = typecheck_value(*val, ty)?;
              TValue::Option(meta(val_.is_comparable()), Some(Box::new(val_)))
            },
            None(..) => (TValueMeta{comparable: ty.is_comparable()}, None),
        },
        Pair(_, tl, tr) => {
            Pair(_, l, r) => {
              let tcl = typecheck_value(*l, tl)?;
              let tcr = typecheck_value(*r, tr)?;
              let meta = meta(tcl.is_comparable() && tcr.is_comparable());
              TValue::new_pair(meta, tcl, tcr)
            },
        },
        Or(_, tl, tr) => {
            Left(_, v) => {
              let tcl = typecheck_value(*v, tl)?;
              let cmp = tr.is_comparable() && tcl.is_comparable();
              TValue::Or(meta(cmp), Or::Left(Box::new(tcl)))
            },
            Right(_, v) => {
              let tcr = typecheck_value(*v, tr)?;
              let cmp = tl.is_comparable() && tcr.is_comparable();
              TValue::Or(meta(cmp), Or::Right(Box::new(tcr)))
            },
        },
        String(..) => { String(_, v) => ((), v) },
        Bytes(..) => { Bytes(_, v) => ((), v) },
        Mutez(..) => { Int(_, v) => ((), v.try_into()?) },
        Bool(..) => {
            True(..) => ((), true),
            False(..) => ((), false),
        },
        List(_, ty) => {
            Seq(_, elts) => {
                let res = elts
                  .into_iter()
                  .map(|elt| typecheck_value(elt, ty))
                  .collect::<Result<_, TcError>>()?;
                TValue::List((), res)
            }
        },
        Set(_, ty) => {
            Seq(_, elts) => {
                let res = elts
                    .into_iter()
                    .map(|elt| Ok(tvalue::Comparable::try_from(typecheck_value(elt, ty)?)?) )
                    .collect::<Result<_, TcError>>()?;
                TValue::Set((), res)
            }
        },
        Lambda(_, arg, res) => {
            Seq(_, elts) => {
                let mut tystk = stk![arg.as_ref().clone()];
                let tc_body = typecheck(to_instr_seq(elts)?, &mut tystk)?;
                if !tystk.is_failed() && (tystk.len() != 1 || tystk.top().unwrap() != &**res) {
                    Err(TcError::ValueError)?;
                }
                TValue::Lambda((), tc_body)
            },
            LambdaRec(..) => { todo!() },
        },
        // todo
        Key(..) => { raw todo!() },
        Signature(..) => { raw todo!() },
        ChainId(..) => { raw todo!() },
        Operation(..) => { raw todo!() },
        Contract(..) => { raw todo!() },
        Ticket(..) => { raw todo!() },
        Map(..) => { raw todo!() },
        BigMap(..) => { raw todo!() },
        KeyHash(..) => { raw todo!() },
        Bls12381Fr(..) => { raw todo!() },
        Bls12381G1(..) => { raw todo!() },
        Bls12381G2(..) => { raw todo!() },
        Timestamp(..) => { raw todo!() },
        Address(..) => { raw todo!() },
        SaplingState(..) => { raw todo!() },
        SaplingTransaction(..) => { raw todo!() },
    );
    Ok(res)
}

fn to_instr_seq<Ext: UValueExt + InstrExt>(
    elts: Vec<UValue<Ext>>,
) -> Result<Vec<Instr<Ext>>, TcError>
where
    Ext::Nest: Default,
{
    elts.into_iter()
        .map(|elt| match elt {
            UValue::Instr(_, i) => Ok(i),
            UValue::Seq(_, els) => Ok(Instr::Nest(Ext::Nest::default(), to_instr_seq(els)?)),
            _ => Err(TcError::ValueError),
        })
        .collect()
}
