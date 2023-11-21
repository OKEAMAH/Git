/******************************************************************************/
/*                                                                            */
/* SPDX-License-Identifier: MIT                                               */
/* Copyright (c) [2023] Serokell <hi@serokell.io>                             */
/*                                                                            */
/******************************************************************************/

use std::collections::BTreeMap;
use std::num::TryFromIntError;

use crate::ast::*;
use crate::context::Ctx;
use crate::gas;
use crate::gas::OutOfGas;
use crate::irrefutable_match::irrefutable_match;
use crate::lexer::Prim;
use crate::stack::*;

/// Typechecker error type.
#[derive(Debug, PartialEq, Eq, thiserror::Error)]
pub enum TcError {
    #[error("type stacks not equal: {0:?} != {1:?}")]
    StacksNotEqual(TypeStack, TypeStack, StacksNotEqualReason),
    #[error(transparent)]
    OutOfGas(#[from] OutOfGas),
    #[error("FAIL instruction is not in tail position")]
    FailNotInTail,
    #[error("numeric conversion failed: {0}")]
    NumericConversion(#[from] TryFromIntError),
    #[error(transparent)]
    TypesNotEqual(#[from] TypesNotEqual),
    #[error("DUP 0 is forbidden")]
    Dup0,
    #[error("value {0:?} is invalid for type {1:?}")]
    InvalidValueForType(Value, Type),
    #[error("value {0:?} is invalid element for container type {1:?}")]
    InvalidEltForMap(Value, Type),
    #[error("sequence elements must be in strictly ascending order for type {0:?}")]
    ElementsNotSorted(Type),
    #[error("type not comparable: {0:?}")]
    TypeNotComparable(Type),
    #[error("sequence elements must contain no duplicate keys for type {0:?}")]
    DuplicateElements(Type),
    #[error("no matching overload for {instr} on stack {stack:?}{}", .reason.as_ref().map_or("".to_owned(), |x| format!(", reason: {}", x)))]
    NoMatchingOverload {
        instr: Prim,
        stack: TypeStack,
        reason: Option<NoMatchingOverloadReason>,
    },
    #[error("type not packable: {0:?}")]
    TypeNotPackable(Type),
}

#[derive(Debug, PartialEq, Eq, thiserror::Error)]
pub enum NoMatchingOverloadReason {
    #[error("stack too short, expected {expected}")]
    StackTooShort { expected: usize },
    #[error(transparent)]
    TypesNotEqual(#[from] TypesNotEqual),
    #[error("expected pair 'a 'b, but got {0:?}")]
    ExpectedPair(Type),
    #[error("expected option 'a, but got {0:?}")]
    ExpectedOption(Type),
    #[error("type not comparable: {0:?}")]
    TypeNotComparable(Type),
}

#[derive(Debug, PartialEq, Eq, thiserror::Error)]
pub enum StacksNotEqualReason {
    #[error(transparent)]
    TypesNotEqual(#[from] TypesNotEqual),
    #[error("lengths are different: {0} != {1}")]
    LengthsDiffer(usize, usize),
}

#[derive(Debug, PartialEq, Eq, thiserror::Error)]
#[error("types not equal: {0:?} != {1:?}")]
pub struct TypesNotEqual(Type, Type);

#[allow(dead_code)]
impl ContractScript<ParsedStage> {
    pub fn typecheck(
        self,
        ctx: &mut crate::context::Ctx,
    ) -> Result<ContractScript<TypecheckedStage>, crate::typechecker::TcError> {
        let ContractScript {
            parameter, storage, ..
        } = self;
        let mut stack = tc_stk![Type::new_pair(parameter.clone(), storage.clone())];
        let code = self.code.typecheck(ctx, &mut stack)?;
        unify_stacks(
            ctx,
            &mut tc_stk![Type::new_pair(
                Type::new_list(Type::Operation),
                storage.clone()
            )],
            stack,
        )?;
        Ok(ContractScript {
            code,
            parameter,
            storage,
        })
    }
}

#[allow(dead_code)]
pub fn typecheck(
    ast: ParsedAST,
    ctx: &mut Ctx,
    opt_stack: &mut FailingTypeStack,
) -> Result<TypecheckedAST, TcError> {
    ast.into_iter()
        .map(|i| i.typecheck(ctx, opt_stack))
        .collect()
}

impl ParsedInstruction {
    pub fn typecheck(
        self,
        ctx: &mut Ctx,
        opt_stack: &mut FailingTypeStack,
    ) -> Result<TypecheckedInstruction, TcError> {
        typecheck_instruction(self, ctx, opt_stack)
    }
}

macro_rules! nothing_to_none {
    () => {
        None
    };
    ($e:expr) => {
        Some($e)
    };
}

fn typecheck_instruction(
    i: ParsedInstruction,
    ctx: &mut Ctx,
    opt_stack: &mut FailingTypeStack,
) -> Result<TypecheckedInstruction, TcError> {
    use Instruction as I;
    use NoMatchingOverloadReason as NMOR;
    use Type as T;

    let stack = opt_stack.access_mut(TcError::FailNotInTail)?;

    // helper to reduce boilerplate. Usage:
    // `pop!()` force-pops the top elements from the stack (panics if nothing to
    // pop), returning it
    // `let x = pop!()` is roughly equivalent to `let x = stack.pop().unwrap()`
    // but with a clear error message
    // `pop!(T::Foo)` force-pops the stack and unwraps `T::Foo(x)`, returning
    // `x`
    // `let x = pop!(T::Foo)` is roughly equivalent to `let T::Foo(x) = pop!()
    // else {panic!()}` but with a clear error message
    // `pop!(T::Bar, x, y, z)` force-pops the stack, unwraps `T::Bar(x, y, z)`
    // and binds those to `x, y, z` in the surrounding scope
    // `pop!(T::Bar, x, y, z)` is roughly equivalent to `let T::Bar(x, y, z) =
    // pop!() else {panic!()}` but with a clear error message.
    macro_rules! pop {
        ($($args:tt)*) => {
            irrefutable_match!(
              stack.pop().expect("pop from empty stack!");
              $($args)*
            )
        };
    }

    // Error handling when stack isn't matched for an instruction. Two forms:
    // no_overload!(instr, len <n>) -- when stack is too short, where <n> is expected length
    // no_overload!(instr, <expr>) -- otherwise, where <expr> is Into<NoMatchingOverloadReason>,
    // and is optional.
    macro_rules! no_overload {
        ($instr:ident, len $expected_len:expr) => {
            {
                return Err(TcError::NoMatchingOverload {
                    instr: Prim::$instr,
                    stack: stack.clone(),
                    reason: Some(NoMatchingOverloadReason::StackTooShort {
                        expected: $expected_len
                    }),
                })
            }
        };
        ($instr:ident$(, $reason:expr)?) => {
            {
                return Err(TcError::NoMatchingOverload {
                    instr: Prim::$instr,
                    stack: stack.clone(),
                    reason: nothing_to_none!($($reason.into())?)
                })
            }
        };
    }

    ctx.gas.consume(gas::tc_cost::INSTR_STEP)?;

    Ok(match (i, stack.as_slice()) {
        (I::Add(..), [.., T::Nat, T::Nat]) => {
            pop!();
            I::Add(overloads::Add::NatNat)
        }
        (I::Add(..), [.., T::Int, T::Int]) => {
            pop!();
            I::Add(overloads::Add::IntInt)
        }
        (I::Add(..), [.., T::Nat, T::Int]) => {
            pop!();
            stack[0] = T::Int;
            I::Add(overloads::Add::IntNat)
        }
        (I::Add(..), [.., T::Int, T::Nat]) => {
            pop!();
            I::Add(overloads::Add::NatInt)
        }
        (I::Add(..), [.., T::Mutez, T::Mutez]) => {
            pop!();
            I::Add(overloads::Add::MutezMutez)
        }
        (I::Add(..), [.., _, _]) => no_overload!(ADD),
        (I::Add(..), [_] | []) => no_overload!(ADD, len 2),

        (I::Dip(opt_height, nested), ..) => {
            let protected_height = opt_height.unwrap_or(1) as usize;

            ctx.gas.consume(gas::tc_cost::dip_n(&opt_height)?)?;

            ensure_stack_len(Prim::DIP, stack, protected_height)?;
            // Here we split off the protected portion of the stack, typecheck the code with the
            // remaining unprotected part, then append the protected portion back on top.
            let mut protected = stack.split_off(protected_height);
            let nested = typecheck(nested, ctx, opt_stack)?;
            opt_stack
                .access_mut(TcError::FailNotInTail)?
                .append(&mut protected);
            I::Dip(opt_height, nested)
        }

        (I::Drop(opt_height), ..) => {
            let drop_height: usize = opt_height.unwrap_or(1) as usize;
            ctx.gas.consume(gas::tc_cost::drop_n(&opt_height)?)?;
            ensure_stack_len(Prim::DROP, stack, drop_height)?;
            stack.drop_top(drop_height);
            I::Drop(opt_height)
        }

        // DUP instruction requires an argument that is > 0.
        (I::Dup(Some(0)), ..) => return Err(TcError::Dup0),
        (I::Dup(opt_height), ..) => {
            let dup_height: usize = opt_height.unwrap_or(1) as usize;
            ensure_stack_len(Prim::DUP, stack, dup_height)?;
            stack.push(stack[dup_height - 1].clone());
            I::Dup(opt_height)
        }

        (I::Gt, [.., T::Int]) => {
            stack[0] = T::Bool;
            I::Gt
        }
        (I::Gt, [.., t]) => no_overload!(GT, TypesNotEqual(T::Int, t.clone())),
        (I::Gt, []) => no_overload!(GT, len 1),

        (I::If(nested_t, nested_f), [.., T::Bool]) => {
            // pop the bool off the stack
            pop!();
            // Clone the stack so that we have a copy to run one branch on.
            // We can run the other branch on the live stack.
            let mut f_opt_stack = opt_stack.clone();
            let nested_t = typecheck(nested_t, ctx, opt_stack)?;
            let nested_f = typecheck(nested_f, ctx, &mut f_opt_stack)?;
            // If stacks unify after typecheck, all is good.
            unify_stacks(ctx, opt_stack, f_opt_stack)?;
            I::If(nested_t, nested_f)
        }
        (I::If(..), [.., t]) => no_overload!(IF, TypesNotEqual(T::Bool, t.clone())),
        (I::If(..), []) => no_overload!(IF, len 1),

        (I::IfNone(when_none, when_some), [.., T::Option(..)]) => {
            // Extract option type
            let ty = pop!(T::Option);
            // Clone the some_stack as we need to push a type on top of it
            let mut some_stack: TypeStack = stack.clone();
            some_stack.push(*ty);
            let mut some_opt_stack = FailingTypeStack::Ok(some_stack);
            let when_none = typecheck(when_none, ctx, opt_stack)?;
            let when_some = typecheck(when_some, ctx, &mut some_opt_stack)?;
            // If stacks unify, all is good
            unify_stacks(ctx, opt_stack, some_opt_stack)?;
            I::IfNone(when_none, when_some)
        }
        (I::IfNone(..), [.., t]) => no_overload!(IF_NONE, NMOR::ExpectedOption(t.clone())),
        (I::IfNone(..), []) => no_overload!(IF_NONE, len 1),

        (I::Int, [.., T::Nat]) => {
            stack[0] = Type::Int;
            I::Int
        }
        (I::Int, [.., _]) => no_overload!(INT),
        (I::Int, []) => no_overload!(INT, len 1),

        (I::Loop(nested), [.., T::Bool]) => {
            // copy stack for unifying with it later
            let opt_copy = FailingTypeStack::Ok(stack.clone());
            // Pop the bool off the top
            pop!();
            // Typecheck body with the current stack
            let nested = typecheck(nested, ctx, opt_stack)?;
            // If the starting stack and result stack unify, all is good.
            unify_stacks(ctx, opt_stack, opt_copy)?;
            // pop the remaining bool off (if not failed)
            opt_stack.access_mut(()).ok().map(Stack::pop);
            I::Loop(nested)
        }
        (I::Loop(..), [.., ty]) => no_overload!(LOOP, TypesNotEqual(T::Bool, ty.clone())),
        (I::Loop(..), []) => no_overload!(LOOP, len 1),

        (I::Push((t, v)), ..) => {
            let v = typecheck_value(ctx, &t, v)?;
            stack.push(t);
            I::Push(v)
        }

        (I::Swap, [.., _, _]) => {
            stack.swap(0, 1);
            I::Swap
        }
        (I::Swap, [] | [_]) => no_overload!(SWAP, len 2),

        (I::Failwith, [.., _]) => {
            let ty = pop!();
            ensure_packable(ty)?;
            // mark stack as failed
            *opt_stack = FailingTypeStack::Failed;
            I::Failwith
        }
        (I::Failwith, []) => no_overload!(FAILWITH, len 1),

        (I::Unit, ..) => {
            stack.push(T::Unit);
            I::Unit
        }

        (I::Car, [.., T::Pair(..)]) => {
            let (l, _) = *pop!(T::Pair);
            stack.push(l);
            I::Car
        }
        (I::Car, [.., ty]) => no_overload!(CAR, NMOR::ExpectedPair(ty.clone())),
        (I::Car, []) => no_overload!(CAR, len 1),

        (I::Cdr, [.., T::Pair(..)]) => {
            let (_, r) = *pop!(T::Pair);
            stack.push(r);
            I::Cdr
        }
        (I::Cdr, [.., ty]) => no_overload!(CDR, NMOR::ExpectedPair(ty.clone())),
        (I::Cdr, []) => no_overload!(CDR, len 1),

        (I::Pair, [.., _, _]) => {
            let (l, r) = (pop!(), pop!());
            stack.push(Type::new_pair(l, r));
            I::Pair
        }
        (I::Pair, [] | [_]) => no_overload!(PAIR, len 2),

        (I::ISome, [.., _]) => {
            let ty = pop!();
            stack.push(T::new_option(ty));
            I::ISome
        }
        (I::ISome, []) => no_overload!(SOME, len 1),

        (I::Compare, [.., u, t]) => {
            ensure_ty_eq(ctx, t, u).map_err(|e| match e {
                TcError::TypesNotEqual(e) => TcError::NoMatchingOverload {
                    instr: Prim::COMPARE,
                    stack: stack.clone(),
                    reason: Some(e.into()),
                },
                e => e,
            })?;
            if !t.is_comparable() {
                return Err(TcError::NoMatchingOverload {
                    instr: Prim::COMPARE,
                    stack: stack.clone(),
                    reason: Some(NoMatchingOverloadReason::TypeNotComparable(t.clone())),
                });
            }
            pop!();
            stack[0] = T::Int;
            I::Compare
        }
        (I::Compare, [] | [_]) => no_overload!(COMPARE, len 2),

        (I::Amount, ..) => {
            stack.push(T::Mutez);
            I::Amount
        }

        (I::Nil(ty), ..) => {
            stack.push(T::new_list(ty));
            I::Nil(())
        }

        (I::Get(..), [.., T::Map(..), _]) => {
            let kty_ = pop!();
            let (kty, vty) = *pop!(T::Map);
            ensure_ty_eq(ctx, &kty, &kty_)?;
            // can only fail if the typechecker is invoked on invalid types,
            // i.e. where `map` key is non-comparable
            ensure_comparable(&kty)?;
            stack.push(T::new_option(vty));
            I::Get(overloads::Get::Map)
        }
        (I::Get(..), [.., _, _]) => no_overload!(GET),
        (I::Get(..), [] | [_]) => no_overload!(GET, len 2),

        (I::Update(..), [.., T::Map(m), T::Option(vty_new), kty_]) => {
            let (kty, vty) = m.as_ref();
            ensure_ty_eq(ctx, kty, kty_)?;
            ensure_ty_eq(ctx, vty, vty_new)?;
            // can only fail if the typechecker is invoked on invalid types,
            // i.e. where `map` key is non-comparable
            ensure_comparable(kty)?;
            pop!();
            pop!();
            I::Update(overloads::Update::Map)
        }
        (I::Update(..), [.., _, _, _]) => no_overload!(UPDATE),
        (I::Update(..), [] | [_] | [_, _]) => no_overload!(UPDATE, len 3),

        (I::Seq(nested), ..) => I::Seq(typecheck(nested, ctx, opt_stack)?),
    })
}

impl Value {
    pub fn typecheck(self, ctx: &mut Ctx, t: &Type) -> Result<TypedValue, TcError> {
        typecheck_value(ctx, t, self)
    }
}

fn typecheck_value(ctx: &mut Ctx, t: &Type, v: Value) -> Result<TypedValue, TcError> {
    use Type::*;
    use TypedValue as TV;
    use Value as V;
    ctx.gas.consume(gas::tc_cost::VALUE_STEP)?;
    Ok(match (t, v) {
        (Nat, V::Number(n)) => TV::Nat(n.try_into()?),
        (Int, V::Number(n)) => TV::Int(n),
        (Bool, V::Boolean(b)) => TV::Bool(b),
        (Mutez, V::Number(n)) if n >= 0 => TV::Mutez(n.try_into()?),
        (String, V::String(s)) => TV::String(s),
        (Unit, V::Unit) => TV::Unit,
        (Pair(pt), V::Pair(pv)) => {
            let (tl, tr) = pt.as_ref();
            let (vl, vr) = *pv;
            let l = typecheck_value(ctx, tl, vl)?;
            let r = typecheck_value(ctx, tr, vr)?;
            TV::new_pair(l, r)
        }
        (Option(ty), V::Option(v)) => match v {
            Some(v) => {
                let v = typecheck_value(ctx, ty, *v)?;
                TV::new_option(Some(v))
            }
            None => TV::new_option(None),
        },
        (List(ty), V::Seq(vs)) => {
            let lst: Result<Vec<TypedValue>, TcError> = vs
                .into_iter()
                .map(|v| typecheck_value(ctx, ty, v))
                .collect();
            TV::List(lst?)
        }
        (Map(m), V::Seq(vs)) => {
            let (tk, tv) = m.as_ref();
            // can only fail if the typechecker is invoked on invalid
            // types, i.e. where `map` key is non-comparable
            ensure_comparable(tk)?;
            let tc_elt = |v: Value| -> Result<(TypedValue, TypedValue), TcError> {
                match v {
                    Value::Elt(e) => {
                        let (k, v) = *e;
                        let k = typecheck_value(ctx, tk, k)?;
                        let v = typecheck_value(ctx, tv, v)?;
                        Ok((k, v))
                    }
                    _ => Err(TcError::InvalidEltForMap(v, t.clone())),
                }
            };
            let elts: Vec<(TypedValue, TypedValue)> =
                vs.into_iter().map(tc_elt).collect::<Result<_, TcError>>()?;
            if elts.len() > 1 {
                let mut prev = &elts[0].0;
                for i in &elts[1..] {
                    ctx.gas.consume(gas::interpret_cost::compare(prev, &i.0)?)?;
                    match prev.cmp(&i.0) {
                        std::cmp::Ordering::Less => (),
                        std::cmp::Ordering::Equal => {
                            return Err(TcError::DuplicateElements(t.clone()))
                        }
                        std::cmp::Ordering::Greater => {
                            return Err(TcError::ElementsNotSorted(t.clone()))
                        }
                    }
                    prev = &i.0;
                }
            }
            ctx.gas
                .consume(gas::tc_cost::construct_map(tk.size_for_gas(), elts.len())?)?;
            // Unfortunately, `BTreeMap` doesn't expose methods to build from an already-sorted
            // slice/vec/iterator. FWIW, Rust docs claim that its sorting algorithm is "designed to
            // be very fast in cases where the slice is nearly sorted", so hopefully it doesn't add
            // too much overhead.
            let map: BTreeMap<TypedValue, TypedValue> = elts.into_iter().collect();
            TV::Map(map)
        }
        (t, v) => return Err(TcError::InvalidValueForType(v, t.clone())),
    })
}

/// Ensures type stack is at least of the required length, otherwise returns
/// `Err(StackTooShort)`.
fn ensure_stack_len(instr: Prim, stack: &TypeStack, l: usize) -> Result<(), TcError> {
    if stack.len() >= l {
        Ok(())
    } else {
        Err(TcError::NoMatchingOverload {
            instr,
            stack: stack.clone(),
            reason: Some(NoMatchingOverloadReason::StackTooShort { expected: l }),
        })
    }
}

fn ensure_packable(ty: Type) -> Result<(), TcError> {
    if ty.is_packable() {
        Ok(())
    } else {
        Err(TcError::TypeNotPackable(ty))
    }
}

fn ensure_comparable(ty: &Type) -> Result<(), TcError> {
    if ty.is_comparable() {
        Ok(())
    } else {
        Err(TcError::TypeNotComparable(ty.clone()))
    }
}

/// Tries to unify two stacks, putting the result in `dest`. If stacks can't be
/// unified, i.e. neither stack is failed and stacks are not equal, returns
/// `Err(StacksNotEqual)`. If it runs out of gas, returns `Err(OutOfGas)`
/// instead.
///
/// Failed stacks unify with anything.
fn unify_stacks(
    ctx: &mut Ctx,
    dest: &mut FailingTypeStack,
    aux: FailingTypeStack,
) -> Result<(), TcError> {
    match &dest {
        FailingTypeStack::Ok(stack1) => {
            if let FailingTypeStack::Ok(stack2) = aux {
                if stack1.len() != stack2.len() {
                    return Err(TcError::StacksNotEqual(
                        stack1.clone(),
                        stack2.clone(),
                        StacksNotEqualReason::LengthsDiffer(stack1.len(), stack2.len()),
                    ));
                }
                for (ty1, ty2) in stack1.iter().zip(stack2.iter()) {
                    ensure_ty_eq(ctx, ty1, ty2).map_err(|e| match e {
                        TcError::TypesNotEqual(e) => {
                            TcError::StacksNotEqual(stack1.clone(), stack2.clone(), e.into())
                        }
                        err => err,
                    })?;
                }
            }
        }
        FailingTypeStack::Failed => {
            // if main stack is failing, assign aux to main, as aux may be OK
            *dest = aux;
        }
    }
    Ok(())
}

fn ensure_ty_eq(ctx: &mut Ctx, ty1: &Type, ty2: &Type) -> Result<(), TcError> {
    ctx.gas
        .consume(gas::tc_cost::ty_eq(ty1.size_for_gas(), ty2.size_for_gas())?)?;
    if ty1 != ty2 {
        Err(TypesNotEqual(ty1.clone(), ty2.clone()).into())
    } else {
        Ok(())
    }
}

#[cfg(test)]
mod typecheck_tests {
    use crate::gas::Gas;
    use crate::parser::*;
    use crate::typechecker::*;
    use Instruction::*;

    #[test]
    fn test_dup() {
        let mut stack = tc_stk![Type::Nat];
        let expected_stack = tc_stk![Type::Nat, Type::Nat];
        let mut ctx = Ctx::default();
        assert_eq!(
            typecheck_instruction(Dup(Some(1)), &mut ctx, &mut stack),
            Ok(Dup(Some(1)))
        );
        assert_eq!(stack, expected_stack);
        assert_eq!(ctx.gas.milligas(), Gas::default().milligas() - 440);
    }

    #[test]
    fn test_dup_n() {
        let mut stack = tc_stk![Type::Int, Type::Nat];
        let expected_stack = tc_stk![Type::Int, Type::Nat, Type::Int];
        let mut ctx = Ctx::default();
        assert_eq!(
            typecheck_instruction(Dup(Some(2)), &mut ctx, &mut stack),
            Ok(Dup(Some(2)))
        );
        assert_eq!(stack, expected_stack);
        assert_eq!(ctx.gas.milligas(), Gas::default().milligas() - 440);
    }

    #[test]
    fn test_swap() {
        let mut stack = tc_stk![Type::Nat, Type::Int];
        let expected_stack = tc_stk![Type::Int, Type::Nat];
        let mut ctx = Ctx::default();
        assert_eq!(typecheck_instruction(Swap, &mut ctx, &mut stack), Ok(Swap));
        assert_eq!(stack, expected_stack);
        assert_eq!(ctx.gas.milligas(), Gas::default().milligas() - 440);
    }

    #[test]
    fn test_int() {
        let mut stack = tc_stk![Type::Nat];
        let expected_stack = tc_stk![Type::Int];
        let mut ctx = Ctx::default();
        assert_eq!(typecheck_instruction(Int, &mut ctx, &mut stack), Ok(Int));
        assert_eq!(stack, expected_stack);
        assert_eq!(ctx.gas.milligas(), Gas::default().milligas() - 440);
    }

    #[test]
    fn test_drop() {
        let mut stack = tc_stk![Type::Nat];
        let expected_stack = tc_stk![];
        let mut ctx = Ctx::default();
        assert_eq!(
            typecheck(vec![Drop(None)], &mut ctx, &mut stack),
            Ok(vec![Drop(None)])
        );
        assert_eq!(stack, expected_stack);
        assert_eq!(ctx.gas.milligas(), Gas::default().milligas() - 440);
    }

    #[test]
    fn test_drop_n() {
        let mut stack = tc_stk![Type::Nat, Type::Int];
        let expected_stack = tc_stk![];
        let mut ctx = Ctx::default();
        assert_eq!(
            typecheck_instruction(Drop(Some(2)), &mut ctx, &mut stack),
            Ok(Drop(Some(2)))
        );
        assert_eq!(stack, expected_stack);
        assert_eq!(ctx.gas.milligas(), Gas::default().milligas() - 440 - 2 * 50);
    }

    #[test]
    fn test_push() {
        let mut stack = tc_stk![Type::Nat];
        let expected_stack = tc_stk![Type::Nat, Type::Int];
        let mut ctx = Ctx::default();
        assert_eq!(
            typecheck_instruction(Push((Type::Int, Value::Number(1))), &mut ctx, &mut stack),
            Ok(Push(TypedValue::Int(1)))
        );
        assert_eq!(stack, expected_stack);
        assert_eq!(ctx.gas.milligas(), Gas::default().milligas() - 440 - 100);
    }

    #[test]
    fn test_gt() {
        let mut stack = tc_stk![Type::Int];
        let expected_stack = tc_stk![Type::Bool];
        let mut ctx = Ctx::default();
        assert_eq!(typecheck_instruction(Gt, &mut ctx, &mut stack), Ok(Gt));
        assert_eq!(stack, expected_stack);
        assert_eq!(ctx.gas.milligas(), Gas::default().milligas() - 440);
    }

    #[test]
    fn test_dip() {
        let mut stack = tc_stk![Type::Int, Type::Bool];
        let expected_stack = tc_stk![Type::Int, Type::Nat, Type::Bool];
        let mut ctx = Ctx::default();
        assert_eq!(
            typecheck_instruction(
                Dip(Some(1), parse("{PUSH nat 6}").unwrap()),
                &mut ctx,
                &mut stack
            ),
            Ok(Dip(Some(1), vec![Push(TypedValue::Nat(6))]))
        );
        assert_eq!(stack, expected_stack);
        assert_eq!(
            ctx.gas.milligas(),
            Gas::default().milligas() - 440 - 440 - 100 - 50
        );
    }

    #[test]
    fn test_add_int_int() {
        let mut stack = tc_stk![Type::Int, Type::Int];
        let expected_stack = tc_stk![Type::Int];
        let mut ctx = Ctx::default();
        assert_eq!(
            typecheck_instruction(Add(()), &mut ctx, &mut stack),
            Ok(Add(overloads::Add::IntInt))
        );
        assert_eq!(stack, expected_stack);
        assert_eq!(ctx.gas.milligas(), Gas::default().milligas() - 440);
    }

    #[test]
    fn test_add_nat_nat() {
        let mut stack = tc_stk![Type::Nat, Type::Nat];
        let expected_stack = tc_stk![Type::Nat];
        let mut ctx = Ctx::default();
        assert_eq!(
            typecheck_instruction(Add(()), &mut ctx, &mut stack),
            Ok(Add(overloads::Add::NatNat))
        );
        assert_eq!(stack, expected_stack);
        assert_eq!(ctx.gas.milligas(), Gas::default().milligas() - 440);
    }

    #[test]
    fn test_add_mutez_mutez() {
        let mut stack = tc_stk![Type::Mutez, Type::Mutez];
        let expected_stack = tc_stk![Type::Mutez];
        let mut ctx = Ctx::default();
        assert_eq!(
            typecheck_instruction(Add(()), &mut ctx, &mut stack),
            Ok(Add(overloads::Add::MutezMutez))
        );
        assert_eq!(stack, expected_stack);
        assert_eq!(ctx.gas.milligas(), Gas::default().milligas() - 440);
    }

    #[test]
    fn test_loop() {
        let mut stack = tc_stk![Type::Int, Type::Bool];
        let expected_stack = tc_stk![Type::Int];
        let mut ctx = Ctx::default();
        assert_eq!(
            typecheck_instruction(
                Loop(parse("{PUSH bool True}").unwrap()),
                &mut ctx,
                &mut stack
            ),
            Ok(Loop(vec![Push(TypedValue::Bool(true))]))
        );
        assert_eq!(stack, expected_stack);
        assert_eq!(
            ctx.gas.milligas(),
            Gas::default().milligas() - 440 - 440 - 100 - 60 * 2
        );
    }

    #[test]
    fn test_loop_stacks_not_equal_length() {
        let mut stack = tc_stk![Type::Int, Type::Bool];
        let mut ctx = Ctx::default();
        assert_eq!(
            typecheck_instruction(
                Loop(parse("{PUSH int 1; PUSH bool True}").unwrap()),
                &mut ctx,
                &mut stack
            )
            .unwrap_err(),
            TcError::StacksNotEqual(
                stk![Type::Int, Type::Int, Type::Bool],
                stk![Type::Int, Type::Bool],
                StacksNotEqualReason::LengthsDiffer(3, 2)
            )
        );
    }

    #[test]
    fn test_loop_stacks_not_equal_types() {
        let mut stack = tc_stk![Type::Int, Type::Bool];
        let mut ctx = Ctx::default();
        assert_eq!(
            typecheck_instruction(
                Loop(parse("{DROP; PUSH bool False; PUSH bool True}").unwrap()),
                &mut ctx,
                &mut stack
            )
            .unwrap_err(),
            TcError::StacksNotEqual(
                stk![Type::Bool, Type::Bool],
                stk![Type::Int, Type::Bool],
                TypesNotEqual(Type::Bool, Type::Int).into()
            )
        );
    }

    #[test]
    fn test_failwith() {
        assert_eq!(
            typecheck_instruction(Failwith, &mut Ctx::default(), &mut tc_stk![Type::Int]),
            Ok(Failwith)
        );
    }

    #[test]
    fn test_failed_stacks() {
        macro_rules! test_fail {
            ($code:expr) => {
                assert_eq!(
                    typecheck(parse($code).unwrap(), &mut Ctx::default(), &mut tc_stk![]),
                    Err(TcError::FailNotInTail)
                );
            };
        }
        test_fail!("{ PUSH int 1; FAILWITH; PUSH int 1 }");
        test_fail!("{ PUSH int 1; DIP { PUSH int 1; FAILWITH } }");
        test_fail!("{ PUSH bool True; IF { PUSH int 1; FAILWITH } { PUSH int 1; FAILWITH }; GT }");
        macro_rules! test_ok {
            ($code:expr) => {
                assert!(
                    typecheck(parse($code).unwrap(), &mut Ctx::default(), &mut tc_stk![]).is_ok()
                );
            };
        }
        test_ok!("{ PUSH bool True; IF { PUSH int 1; FAILWITH } { PUSH int 1 }; GT }");
        test_ok!("{ PUSH bool True; IF { PUSH int 1 } { PUSH int 1; FAILWITH }; GT }");
        test_ok!("{ PUSH bool True; IF { PUSH int 1; FAILWITH } { PUSH int 1; FAILWITH } }");
        test_ok!("{ PUSH bool True; LOOP { PUSH int 1; FAILWITH }; PUSH int 1 }");
    }

    #[test]
    fn string_values() {
        assert_eq!(
            typecheck_value(
                &mut Ctx::default(),
                &Type::String,
                Value::String("foo".to_owned())
            ),
            Ok(TypedValue::String("foo".to_owned()))
        )
    }

    #[test]
    fn push_string_value() {
        let mut stack = tc_stk![];
        assert_eq!(
            typecheck(
                parse(r#"{ PUSH string "foo"; }"#).unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Ok(vec![Push(TypedValue::String("foo".to_owned()))])
        );
        assert_eq!(stack, tc_stk![Type::String]);
    }

    #[test]
    fn push_unit_value() {
        let mut stack = tc_stk![];
        assert_eq!(
            typecheck(
                parse("{ PUSH unit Unit; }").unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Ok(vec![Push(TypedValue::Unit)])
        );
        assert_eq!(stack, tc_stk![Type::Unit]);
    }

    #[test]
    fn unit_instruction() {
        let mut stack = tc_stk![];
        assert_eq!(
            typecheck(parse("{ UNIT }").unwrap(), &mut Ctx::default(), &mut stack),
            Ok(vec![Unit])
        );
        assert_eq!(stack, tc_stk![Type::Unit]);
    }

    #[test]
    fn push_pair_value() {
        let mut stack = tc_stk![];
        assert_eq!(
            typecheck(
                parse("{ PUSH (pair int nat bool) (Pair -5 3 False) }").unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Ok(vec![Push(TypedValue::new_pair(
                TypedValue::Int(-5),
                TypedValue::new_pair(TypedValue::Nat(3), TypedValue::Bool(false))
            ))])
        );
        assert_eq!(
            stack,
            tc_stk![Type::new_pair(
                Type::Int,
                Type::new_pair(Type::Nat, Type::Bool)
            )]
        );
    }

    #[test]
    fn push_option_value() {
        let mut stack = tc_stk![];
        assert_eq!(
            typecheck(
                parse("{ PUSH (option nat) (Some 3) }").unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Ok(vec![Push(TypedValue::new_option(Some(TypedValue::Nat(3))))])
        );
        assert_eq!(stack, tc_stk![Type::new_option(Type::Nat)]);
    }

    #[test]
    fn push_option_none_value() {
        let mut stack = tc_stk![];
        assert_eq!(
            typecheck(
                parse("{ PUSH (option nat) None }").unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Ok(vec![Push(TypedValue::new_option(None))])
        );
        assert_eq!(stack, tc_stk![Type::new_option(Type::Nat)]);
    }

    #[test]
    fn car() {
        let mut stack = tc_stk![];
        assert_eq!(
            typecheck(
                parse("{ PUSH (pair int nat bool) (Pair -5 3 False); CAR }").unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Ok(vec![
                Push(TypedValue::new_pair(
                    TypedValue::Int(-5),
                    TypedValue::new_pair(TypedValue::Nat(3), TypedValue::Bool(false))
                )),
                Car
            ])
        );
        assert_eq!(stack, tc_stk![Type::Int]);
    }

    #[test]
    fn cdr() {
        let mut stack = tc_stk![];
        assert_eq!(
            typecheck(
                parse("{ PUSH (pair int nat bool) (Pair -5 3 False); CDR }").unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Ok(vec![
                Push(TypedValue::new_pair(
                    TypedValue::Int(-5),
                    TypedValue::new_pair(TypedValue::Nat(3), TypedValue::Bool(false))
                )),
                Cdr
            ])
        );
        assert_eq!(stack, tc_stk![Type::new_pair(Type::Nat, Type::Bool)]);
    }

    #[test]
    fn car_fail() {
        let mut stack = tc_stk![Type::Unit];
        assert_eq!(
            typecheck(parse("{ CAR }").unwrap(), &mut Ctx::default(), &mut stack),
            Err(TcError::NoMatchingOverload {
                instr: Prim::CAR,
                stack: stk![Type::Unit],
                reason: Some(NoMatchingOverloadReason::ExpectedPair(Type::Unit)),
            })
        );
    }

    #[test]
    fn cdr_fail() {
        let mut stack = tc_stk![Type::Unit];
        assert_eq!(
            typecheck(parse("{ CDR }").unwrap(), &mut Ctx::default(), &mut stack),
            Err(TcError::NoMatchingOverload {
                instr: Prim::CDR,
                stack: stk![Type::Unit],
                reason: Some(NoMatchingOverloadReason::ExpectedPair(Type::Unit)),
            })
        );
    }

    #[test]
    fn pair() {
        let mut stack = tc_stk![Type::Int, Type::Nat]; // NB: nat is top
        assert_eq!(
            typecheck(parse("{ PAIR }").unwrap(), &mut Ctx::default(), &mut stack),
            Ok(vec![Pair])
        );
        assert_eq!(stack, tc_stk![Type::new_pair(Type::Nat, Type::Int)]);
    }

    #[test]
    fn pair_car() {
        let mut stack = tc_stk![Type::Int, Type::Nat]; // NB: nat is top
        assert_eq!(
            typecheck(
                parse("{ PAIR; CAR }").unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Ok(vec![Pair, Car])
        );
        assert_eq!(stack, tc_stk![Type::Nat]);
    }

    #[test]
    fn pair_cdr() {
        let mut stack = tc_stk![Type::Int, Type::Nat]; // NB: nat is top
        assert_eq!(
            typecheck(
                parse("{ PAIR; CDR }").unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Ok(vec![Pair, Cdr])
        );
        assert_eq!(stack, tc_stk![Type::Int]);
    }

    #[test]
    fn if_none() {
        let mut stack = tc_stk![Type::new_option(Type::Int)];
        assert_eq!(
            typecheck(
                parse("{ IF_NONE { PUSH int 5; } {} }").unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Ok(vec![IfNone(vec![Push(TypedValue::Int(5))], vec![])])
        );
        assert_eq!(stack, tc_stk![Type::Int]);
    }

    #[test]
    fn if_none_fail() {
        let mut stack = tc_stk![Type::Int];
        assert_eq!(
            typecheck(
                parse("{ IF_NONE { PUSH int 5; } {} }").unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Err(TcError::NoMatchingOverload {
                instr: Prim::IF_NONE,
                stack: stk![Type::Int],
                reason: Some(NoMatchingOverloadReason::ExpectedOption(Type::Int)),
            })
        );
    }

    #[test]
    fn some() {
        let mut stack = tc_stk![Type::Int];
        assert_eq!(
            typecheck(parse("{ SOME }").unwrap(), &mut Ctx::default(), &mut stack),
            Ok(vec![ISome])
        );
        assert_eq!(stack, tc_stk![Type::new_option(Type::Int)]);
    }

    #[test]
    fn compare_int() {
        let mut stack = tc_stk![Type::Int, Type::Int];
        assert_eq!(
            typecheck(
                parse("{ COMPARE }").unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Ok(vec![Compare])
        );
        assert_eq!(stack, tc_stk![Type::Int]);
    }

    #[test]
    fn compare_int_fail() {
        let mut stack = tc_stk![Type::Int, Type::Nat];
        assert_eq!(
            typecheck(
                parse("{ COMPARE }").unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Err(TcError::NoMatchingOverload {
                instr: Prim::COMPARE,
                stack: stk![Type::Int, Type::Nat],
                reason: Some(TypesNotEqual(Type::Nat, Type::Int).into())
            })
        );
    }

    #[test]
    fn amount() {
        let mut stack = tc_stk![];
        assert_eq!(
            typecheck(
                parse("{ AMOUNT }").unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Ok(vec![Amount])
        );
        assert_eq!(stack, tc_stk![Type::Mutez]);
    }

    #[test]
    fn push_int_list() {
        let mut stack = tc_stk![];
        assert_eq!(
            typecheck(
                parse("{ PUSH (list int) { 1; 2; 3 }}").unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Ok(vec![Push(TypedValue::List(vec![
                TypedValue::Int(1),
                TypedValue::Int(2),
                TypedValue::Int(3),
            ]))])
        );
        assert_eq!(stack, tc_stk![Type::new_list(Type::Int)]);
    }

    #[test]
    fn push_int_list_fail() {
        let mut stack = tc_stk![];
        assert_eq!(
            typecheck(
                parse("{ PUSH (list int) { 1; Unit; 3 }}").unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Err(TcError::InvalidValueForType(Value::Unit, Type::Int))
        );
    }

    #[test]
    fn nil() {
        let mut stack = tc_stk![];
        assert_eq!(
            typecheck(
                parse("{ NIL int }").unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Ok(vec![Nil(())])
        );
        assert_eq!(stack, tc_stk![Type::new_list(Type::Int)]);
    }

    #[test]
    fn nil_operation() {
        let mut stack = tc_stk![];
        assert_eq!(
            typecheck(
                parse("{ NIL operation }").unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Ok(vec![Nil(())])
        );
        assert_eq!(stack, tc_stk![Type::new_list(Type::Operation)]);
    }

    #[test]
    fn failwith_operation() {
        let mut stack = tc_stk![Type::new_list(Type::Operation)];
        assert_eq!(
            typecheck(
                parse("{ FAILWITH }").unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Err(TcError::TypeNotPackable(Type::new_list(Type::Operation)))
        );
    }

    #[test]
    fn push_map() {
        let mut stack = tc_stk![];
        assert_eq!(
            typecheck(
                parse(r#"{ PUSH (map int string) { Elt 1 "foo"; Elt 2 "bar" } }"#).unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Ok(vec![Push(TypedValue::Map(BTreeMap::from([
                (TypedValue::Int(1), TypedValue::String("foo".to_owned())),
                (TypedValue::Int(2), TypedValue::String("bar".to_owned()))
            ])))])
        );
        assert_eq!(stack, tc_stk![Type::new_map(Type::Int, Type::String)]);
    }

    #[test]
    fn push_map_unsorted() {
        let mut stack = tc_stk![];
        assert_eq!(
            typecheck(
                parse(r#"{ PUSH (map int string) { Elt 2 "foo"; Elt 1 "bar" } }"#).unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Err(TcError::ElementsNotSorted(Type::new_map(
                Type::Int,
                Type::String
            )))
        );
    }

    #[test]
    fn push_map_incomparable() {
        let mut stack = tc_stk![];
        assert_eq!(
            typecheck(
                parse(r#"{ PUSH (map (list int) string) { Elt { 2 } "foo"; Elt { 1 } "bar" } }"#)
                    .unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Err(TcError::TypeNotComparable(Type::new_list(Type::Int)))
        );
    }

    #[test]
    fn push_map_incomparable_empty() {
        let mut stack = tc_stk![];
        assert_eq!(
            typecheck(
                parse(r#"{ PUSH (map (list int) string) { } }"#).unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Err(TcError::TypeNotComparable(Type::new_list(Type::Int)))
        );
    }

    #[test]
    fn push_map_wrong_key_type() {
        let mut stack = tc_stk![];
        assert_eq!(
            typecheck(
                parse(r#"{ PUSH (map int string) { Elt "1" "foo"; Elt 2 "bar" } }"#).unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Err(TcError::InvalidValueForType(
                Value::String("1".to_owned()),
                Type::Int
            ))
        );
    }

    #[test]
    fn push_map_wrong_elt() {
        let mut stack = tc_stk![];
        assert_eq!(
            typecheck(
                parse(r#"{ PUSH (map int string) { Elt 1 "foo"; "bar" } }"#).unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Err(TcError::InvalidEltForMap(
                Value::String("bar".to_owned()),
                Type::new_map(Type::Int, Type::String)
            ))
        );
    }

    #[test]
    fn push_map_duplicate_key() {
        let mut stack = tc_stk![];
        assert_eq!(
            typecheck(
                parse(r#"{ PUSH (map int string) { Elt 1 "foo"; Elt 1 "bar" } }"#).unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Err(TcError::DuplicateElements(Type::new_map(
                Type::Int,
                Type::String
            )))
        );
    }

    #[test]
    fn get_map() {
        let mut stack = tc_stk![Type::new_map(Type::Int, Type::String), Type::Int];
        assert_eq!(
            typecheck(parse("{ GET }").unwrap(), &mut Ctx::default(), &mut stack),
            Ok(vec![Get(overloads::Get::Map)])
        );
        assert_eq!(stack, tc_stk![Type::new_option(Type::String)]);
    }

    #[test]
    fn get_map_incomparable() {
        let mut stack = tc_stk![
            Type::new_map(Type::new_list(Type::Int), Type::String),
            Type::new_list(Type::Int)
        ];
        assert_eq!(
            typecheck(parse("{ GET }").unwrap(), &mut Ctx::default(), &mut stack),
            Err(TcError::TypeNotComparable(Type::new_list(Type::Int))),
        );
    }

    #[test]
    fn get_map_wrong_type() {
        let mut stack = tc_stk![Type::new_map(Type::Int, Type::String), Type::Nat];
        assert_eq!(
            typecheck(parse("{ GET }").unwrap(), &mut Ctx::default(), &mut stack),
            Err(TypesNotEqual(Type::Int, Type::Nat).into()),
        );
    }

    #[test]
    fn update_map() {
        let mut stack = tc_stk![
            Type::new_map(Type::Int, Type::String),
            Type::new_option(Type::String),
            Type::Int
        ];
        assert_eq!(
            typecheck(
                parse("{ UPDATE }").unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Ok(vec![Update(overloads::Update::Map)])
        );
        assert_eq!(stack, tc_stk![Type::new_map(Type::Int, Type::String)]);
    }

    #[test]
    fn update_map_wrong_ty() {
        let mut stack = tc_stk![
            Type::new_map(Type::Int, Type::String),
            Type::new_option(Type::Nat),
            Type::Int
        ];
        assert_eq!(
            typecheck(
                parse("{ UPDATE }").unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Err(TypesNotEqual(Type::String, Type::Nat).into())
        );
    }

    #[test]
    fn update_map_incomparable() {
        let mut stack = tc_stk![
            Type::new_map(Type::new_list(Type::Int), Type::String),
            Type::new_option(Type::String),
            Type::new_list(Type::Int)
        ];
        assert_eq!(
            typecheck(
                parse("{ UPDATE }").unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Err(TcError::TypeNotComparable(Type::new_list(Type::Int),))
        );
    }

    #[test]
    fn seq() {
        let mut stack = tc_stk![Type::Int, Type::Nat];
        assert_eq!(
            typecheck(
                parse("{ { PAIR }; {{ CAR; }}; {}; {{{}}}; {{{{{DROP}}}}} }").unwrap(),
                &mut Ctx::default(),
                &mut stack
            ),
            Ok(vec![
                Seq(vec![Pair]),
                Seq(vec![Seq(vec![Car])]),
                Seq(vec![]),
                Seq(vec![Seq(vec![Seq(vec![])])]),
                Seq(vec![Seq(vec![Seq(vec![Seq(vec![Seq(vec![Drop(None)])])])])])
            ])
        );
        assert_eq!(stack, tc_stk![]);
    }

    #[test]
    fn add_int_nat() {
        let mut stack = tc_stk![Type::Nat, Type::Int];
        assert_eq!(
            typecheck(parse("{ ADD }").unwrap(), &mut Ctx::default(), &mut stack),
            Ok(vec![Add(overloads::Add::IntNat)])
        );
        assert_eq!(stack, tc_stk![Type::Int]);
    }

    #[test]
    fn add_nat_int() {
        let mut stack = tc_stk![Type::Int, Type::Nat];
        assert_eq!(
            typecheck(parse("{ ADD }").unwrap(), &mut Ctx::default(), &mut stack),
            Ok(vec![Add(overloads::Add::NatInt)])
        );
        assert_eq!(stack, tc_stk![Type::Int]);
    }

    #[track_caller]
    fn too_short_test(instr: ParsedInstruction, prim: Prim, len: usize) {
        for n in 0..len {
            let mut ctx = Ctx::default();
            assert_eq!(
                typecheck_instruction(instr.clone(), &mut ctx, &mut tc_stk![Type::Unit; n]),
                Err(TcError::NoMatchingOverload {
                    instr: prim,
                    stack: stk![Type::Unit; n],
                    reason: Some(NoMatchingOverloadReason::StackTooShort { expected: len })
                })
            );
        }
    }

    #[test]
    fn test_add_short() {
        too_short_test(Add(()), Prim::ADD, 2);
    }

    #[test]
    fn test_add_mismatch() {
        let mut stack = tc_stk![Type::String, Type::String];
        let mut ctx = Ctx::default();
        assert_eq!(
            typecheck_instruction(Add(()), &mut ctx, &mut stack),
            Err(TcError::NoMatchingOverload {
                instr: Prim::ADD,
                stack: stk![Type::String, Type::String],
                reason: None
            })
        );
    }

    #[test]
    fn test_dup0() {
        let mut stack = tc_stk![];
        let mut ctx = Ctx::default();
        assert_eq!(
            typecheck_instruction(Dup(Some(0)), &mut ctx, &mut stack),
            Err(TcError::Dup0)
        );
    }

    #[test]
    fn test_gt_mismatch() {
        let mut stack = tc_stk![Type::String];
        let mut ctx = Ctx::default();
        assert_eq!(
            typecheck_instruction(Gt, &mut ctx, &mut stack),
            Err(TcError::NoMatchingOverload {
                instr: Prim::GT,
                stack: stk![Type::String],
                reason: Some(TypesNotEqual(Type::Int, Type::String).into())
            })
        );
    }

    #[test]
    fn test_gt_short() {
        too_short_test(Gt, Prim::GT, 1);
    }

    #[test]
    fn test_if_mismatch() {
        let mut stack = tc_stk![Type::String];
        let mut ctx = Ctx::default();
        assert_eq!(
            typecheck_instruction(If(vec![], vec![]), &mut ctx, &mut stack),
            Err(TcError::NoMatchingOverload {
                instr: Prim::IF,
                stack: stk![Type::String],
                reason: Some(TypesNotEqual(Type::Bool, Type::String).into())
            })
        );
    }

    #[test]
    fn test_if_short() {
        too_short_test(If(vec![], vec![]), Prim::IF, 1);
    }

    #[test]
    fn test_if_none_short() {
        too_short_test(IfNone(vec![], vec![]), Prim::IF_NONE, 1);
    }

    #[test]
    fn test_int_short() {
        too_short_test(Int, Prim::INT, 1);
    }

    #[test]
    fn test_int_mismatch() {
        let mut stack = tc_stk![Type::String];
        let mut ctx = Ctx::default();
        assert_eq!(
            typecheck_instruction(Int, &mut ctx, &mut stack),
            Err(TcError::NoMatchingOverload {
                instr: Prim::INT,
                stack: stk![Type::String],
                reason: None,
            })
        );
    }

    #[test]
    fn test_loop_short() {
        too_short_test(Loop(vec![]), Prim::LOOP, 1);
    }

    #[test]
    fn test_loop_mismatch() {
        let mut stack = tc_stk![Type::String];
        let mut ctx = Ctx::default();
        assert_eq!(
            typecheck_instruction(Loop(vec![]), &mut ctx, &mut stack),
            Err(TcError::NoMatchingOverload {
                instr: Prim::LOOP,
                stack: stk![Type::String],
                reason: Some(TypesNotEqual(Type::Bool, Type::String).into()),
            })
        );
    }

    #[test]
    fn test_swap_short() {
        too_short_test(Swap, Prim::SWAP, 2);
    }

    #[test]
    fn test_pair_short() {
        too_short_test(Pair, Prim::PAIR, 2);
    }

    #[test]
    fn test_get_short() {
        too_short_test(Get(()), Prim::GET, 2);
    }

    #[test]
    fn test_update_short() {
        too_short_test(Update(()), Prim::UPDATE, 3);
    }

    #[test]
    fn test_failwith_short() {
        too_short_test(Failwith, Prim::FAILWITH, 1);
    }

    #[test]
    fn test_car_short() {
        too_short_test(Car, Prim::CAR, 1);
    }

    #[test]
    fn test_cdr_short() {
        too_short_test(Cdr, Prim::CDR, 1);
    }

    #[test]
    fn test_some_short() {
        too_short_test(ISome, Prim::SOME, 1);
    }

    #[test]
    fn test_compare_short() {
        too_short_test(Compare, Prim::COMPARE, 2);
    }

    #[test]
    fn test_compare_gas_exhaustion() {
        let mut ctx = Ctx {
            gas: Gas::new(gas::tc_cost::INSTR_STEP),
            ..Ctx::default()
        };
        assert_eq!(
            typecheck_instruction(Compare, &mut ctx, &mut tc_stk![Type::Unit, Type::Unit]),
            Err(TcError::OutOfGas(OutOfGas))
        );
    }

    #[test]
    fn test_compare_incomparable() {
        let mut ctx = Ctx::default();
        assert_eq!(
            typecheck_instruction(
                Compare,
                &mut ctx,
                &mut tc_stk![Type::Operation, Type::Operation]
            ),
            Err(TcError::NoMatchingOverload {
                instr: Prim::COMPARE,
                stack: stk![Type::Operation, Type::Operation],
                reason: Some(NoMatchingOverloadReason::TypeNotComparable(Type::Operation)),
            })
        );
    }

    #[test]
    fn test_get_mismatch() {
        let mut ctx = Ctx::default();
        assert_eq!(
            typecheck_instruction(Get(()), &mut ctx, &mut tc_stk![Type::Unit, Type::Unit]),
            Err(TcError::NoMatchingOverload {
                instr: Prim::GET,
                stack: stk![Type::Unit, Type::Unit],
                reason: None,
            })
        );
    }

    #[test]
    fn test_update_mismatch() {
        let mut ctx = Ctx::default();
        assert_eq!(
            typecheck_instruction(
                Update(()),
                &mut ctx,
                &mut tc_stk![Type::Unit, Type::Unit, Type::Unit]
            ),
            Err(TcError::NoMatchingOverload {
                instr: Prim::UPDATE,
                stack: stk![Type::Unit, Type::Unit, Type::Unit],
                reason: None,
            })
        );
    }
}
