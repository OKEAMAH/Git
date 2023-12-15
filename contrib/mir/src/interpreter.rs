/******************************************************************************/
/*                                                                            */
/* SPDX-License-Identifier: MIT                                               */
/* Copyright (c) [2023] Serokell <hi@serokell.io>                             */
/*                                                                            */
/******************************************************************************/

use num_bigint::{BigInt, BigUint};
use num_traits::{Signed, Zero};
use typed_arena::Arena;

use crate::ast::annotations::NO_ANNS;
use crate::ast::*;
use crate::context::Ctx;
use crate::gas::{interpret_cost, OutOfGas};
use crate::irrefutable_match::irrefutable_match;
use crate::lexer::Prim;
use crate::stack::*;
use crate::typechecker::typecheck_value;

#[derive(Debug, PartialEq, Eq, Clone, thiserror::Error)]
pub enum InterpretError {
    #[error(transparent)]
    OutOfGas(#[from] OutOfGas),
    #[error("mutez overflow")]
    MutezOverflow,
    #[error("failed with: {1:?} of type {0:?}")]
    FailedWith(Type, TypedValue),
}

#[derive(Debug, PartialEq, Eq, thiserror::Error)]
pub enum ContractInterpretError {
    #[error("failed typechecking input: {0}")]
    TcError(#[from] crate::typechecker::TcError),
    #[error("runtime failure while running the contract: {0}")]
    InterpretError(#[from] crate::interpreter::InterpretError),
}

impl ContractScript {
    /// Interpret a typechecked contract script using the provided parameter and
    /// storage. Parameter and storage are given as `Micheline`, as this
    /// allows ensuring they satisfy the types expected by the script.
    pub fn interpret(
        &self,
        ctx: &mut crate::context::Ctx,
        parameter: Micheline,
        storage: Micheline,
    ) -> Result<(impl Iterator<Item = OperationInfo>, TypedValue), ContractInterpretError> {
        let in_ty = Type::new_pair(self.parameter.clone(), self.storage.clone());
        let in_val = &[parameter, storage];
        let in_val = Micheline::App(Prim::Pair, in_val, NO_ANNS);
        let tc_val = typecheck_value(&in_val, ctx, &in_ty)?;
        let mut stack = stk![tc_val];
        self.code.interpret(ctx, &mut stack)?;
        use TypedValue as V;
        match stack.pop().expect("empty execution stack") {
            V::Pair(p) => match *p {
                (V::List(vec), storage) => Ok((
                    vec.into_iter()
                        .map(|x| (*irrefutable_match!(x; V::Operation))),
                    storage,
                )),
                (v, _) => panic!("expected `list operation`, got {:?}", v),
            },
            v => panic!("expected `pair 'a 'b`, got {:?}", v),
        }
    }
}

impl Instruction {
    /// Interpret the instruction with the given `Ctx` and input stack. Note the
    /// interpreter assumes the instruction can execute on the provided stack,
    /// otherwise this function will panic.
    ///
    /// # Panics
    ///
    /// When the instruction can't be executed on the provided stack.
    pub fn interpret(&self, ctx: &mut Ctx, stack: &mut IStack) -> Result<(), InterpretError> {
        interpret_one(self, ctx, stack)
    }
}

fn interpret(
    ast: &Vec<Instruction>,
    ctx: &mut Ctx,
    stack: &mut IStack,
) -> Result<(), InterpretError> {
    for i in ast {
        i.interpret(ctx, stack)?;
    }
    ctx.gas.consume(interpret_cost::INTERPRET_RET)?;
    Ok(())
}

#[track_caller]
fn unreachable_state() -> ! {
    // If the typechecking of the program being interpreted was successful and if this is reached
    // during interpreting, then the typechecking should be broken, and needs to be fixed.
    panic!("Unreachable state reached during interpreting, possibly broken typechecking!")
}

fn interpret_one(i: &Instruction, ctx: &mut Ctx, stack: &mut IStack) -> Result<(), InterpretError> {
    use Instruction as I;
    use TypedValue as V;

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
            crate::irrefutable_match::irrefutable_match!(
                stack.pop().unwrap_or_else(|| unreachable_state());
                $($args)*
                )
        };
    }

    match i {
        I::Add(overload) => match overload {
            overloads::Add::IntInt => {
                let o1 = pop!(V::Int);
                let o2 = pop!(V::Int);
                ctx.gas.consume(interpret_cost::add_num(&o1, &o2)?)?;
                let sum = o1 + o2;
                stack.push(V::Int(sum));
            }
            overloads::Add::NatNat => {
                let o1 = pop!(V::Nat);
                let o2 = pop!(V::Nat);
                ctx.gas.consume(interpret_cost::add_num(&o1, &o2)?)?;
                let sum = o1 + o2;
                stack.push(V::Nat(sum));
            }
            overloads::Add::IntNat => {
                let o1 = pop!(V::Int);
                let o2 = pop!(V::Nat);
                ctx.gas.consume(interpret_cost::add_num(&o1, &o2)?)?;
                let sum = o1 + BigInt::from(o2);
                stack.push(V::Int(sum));
            }
            overloads::Add::NatInt => {
                let o1 = pop!(V::Nat);
                let o2 = pop!(V::Int);
                ctx.gas.consume(interpret_cost::add_num(&o1, &o2)?)?;
                let sum = BigInt::from(o1) + o2;
                stack.push(V::Int(sum));
            }
            overloads::Add::MutezMutez => {
                let o1 = pop!(V::Mutez);
                let o2 = pop!(V::Mutez);
                ctx.gas.consume(interpret_cost::ADD_TEZ)?;
                let sum = o1.checked_add(o2).ok_or(InterpretError::MutezOverflow)?;
                stack.push(V::Mutez(sum));
            }
        },
        I::And(overload) => match overload {
            overloads::And::Bool => {
                let o1 = pop!(V::Bool);
                let o2 = irrefutable_match!(&mut stack[0]; V::Bool);
                ctx.gas.consume(interpret_cost::AND_BOOL)?;
                *o2 &= o1;
            }
            overloads::And::NatNat => {
                let o1 = pop!(V::Nat);
                let o2 = irrefutable_match!(&mut stack[0]; V::Nat);
                ctx.gas.consume(interpret_cost::and_num(&o1, o2)?)?;
                *o2 &= o1;
            }
            overloads::And::IntNat => {
                let o1 = pop!(V::Int);
                let o2 = pop!(V::Nat);
                ctx.gas.consume(interpret_cost::and_num(&o1, &o2)?)?;
                let res = BigUint::try_from(o1 & BigInt::from(o2))
                    // safe, `neg` & `pos` = `pos`
                    .unwrap();
                stack.push(V::Nat(res));
            }
            overloads::And::Bytes => {
                let mut o1 = pop!(V::Bytes);
                let o2 = irrefutable_match!(&mut stack[0]; V::Bytes);
                ctx.gas.consume(interpret_cost::and_bytes(&o1, o2)?)?;

                // The resulting vector length is the smallest length among the
                // operands, so to reuse memory we put the smallest vector to
                // the result (`o2`).
                if o1.len() < o2.len() {
                    std::mem::swap(&mut o1, o2)
                }
                for (b1, b2) in std::iter::zip(o1.into_iter().rev(), o2.iter_mut().rev()) {
                    *b2 &= b1;
                }
            }
        },
        I::Or(overload) => match overload {
            overloads::Or::Bool => {
                let o1 = pop!(V::Bool);
                let o2 = irrefutable_match!(&mut stack[0]; V::Bool);
                ctx.gas.consume(interpret_cost::OR_BOOL)?;
                *o2 |= o1;
            }
            overloads::Or::Nat => {
                let o1 = pop!(V::Nat);
                let o2 = irrefutable_match!(&mut stack[0]; V::Nat);
                ctx.gas.consume(interpret_cost::or_num(&o1, o2)?)?;
                *o2 |= o1;
            }
            overloads::Or::Bytes => {
                let mut o1 = pop!(V::Bytes);
                let o2 = irrefutable_match!(&mut stack[0]; V::Bytes);
                ctx.gas.consume(interpret_cost::or_bytes(&o1, o2)?)?;

                // The resulting vector length is the largest length among the
                // operands, so to reuse memory we put the largest vector to
                // the result (`o2`).
                if o1.len() > o2.len() {
                    std::mem::swap(&mut o1, o2)
                }
                for (b1, b2) in std::iter::zip(o1.into_iter().rev(), o2.iter_mut().rev()) {
                    *b2 |= b1;
                }
            }
        },
        I::Xor(overloads) => match overloads {
            overloads::Xor::Bool => {
                let o1 = pop!(V::Bool);
                let o2 = irrefutable_match!(&mut stack[0]; V::Bool);
                ctx.gas.consume(interpret_cost::XOR_BOOL)?;
                *o2 ^= o1;
            }
            overloads::Xor::Nat => {
                let o1 = pop!(V::Nat);
                let o2 = irrefutable_match!(&mut stack[0]; V::Nat);
                ctx.gas.consume(interpret_cost::xor_nat(&o1, o2)?)?;
                *o2 ^= o1;
            }
            overloads::Xor::Bytes => {
                let mut o1 = pop!(V::Bytes);
                let o2 = irrefutable_match!(&mut stack[0]; V::Bytes);

                // The resulting vector length is the largest length among the
                // operands, so to reuse memory we put the largest vector to
                // the result (`o2`).
                if o1.len() > o2.len() {
                    std::mem::swap(&mut o1, o2)
                }
                for (b1, b2) in std::iter::zip(o1.into_iter().rev(), o2.iter_mut().rev()) {
                    *b2 ^= b1;
                }
            }
        },
        I::Not(overload) => match overload {
            overloads::Not::Bool => {
                let o = irrefutable_match!(&mut stack[0]; V::Bool);
                ctx.gas.consume(interpret_cost::NOT_BOOL)?;
                *o = !*o;
            }
            overloads::Not::Int => {
                let o = pop!(V::Int);
                ctx.gas.consume(interpret_cost::not_num(&o)?)?;
                stack.push(V::Int(!o));
            }
            overloads::Not::Nat => {
                let o = pop!(V::Nat);
                ctx.gas.consume(interpret_cost::not_num(&o)?)?;
                stack.push(V::Int(!BigInt::from(o)))
            }
            overloads::Not::Bytes => {
                let o = irrefutable_match!(&mut stack[0]; V::Bytes);
                ctx.gas.consume(interpret_cost::not_bytes(o)?)?;
                for b in o.iter_mut() {
                    *b = !*b
                }
            }
        },
        I::Dip(opt_height, nested) => {
            ctx.gas.consume(interpret_cost::dip(*opt_height)?)?;
            let protected_height: u16 = opt_height.unwrap_or(1);
            let mut protected = stack.split_off(protected_height as usize);
            interpret(nested, ctx, stack)?;
            ctx.gas.consume(interpret_cost::undip(protected_height)?)?;
            stack.append(&mut protected);
        }
        I::Drop(opt_height) => {
            ctx.gas.consume(interpret_cost::drop(*opt_height)?)?;
            let drop_height: usize = opt_height.unwrap_or(1) as usize;
            stack.drop_top(drop_height);
        }
        I::Dup(opt_height) => {
            ctx.gas.consume(interpret_cost::dup(*opt_height)?)?;
            let dup_height: usize = opt_height.unwrap_or(1) as usize;
            stack.push(stack[dup_height - 1].clone());
        }
        I::Gt => {
            ctx.gas.consume(interpret_cost::GT)?;
            let i = pop!(V::Int);
            stack.push(V::Bool(i.is_positive()));
        }
        I::Eq => {
            ctx.gas.consume(interpret_cost::EQ)?;
            let i = pop!(V::Int);
            stack.push(V::Bool(i.is_zero()));
        }
        I::Le => {
            ctx.gas.consume(interpret_cost::LE)?;
            let i = pop!(V::Int);
            stack.push(V::Bool(!i.is_positive()));
        }
        I::If(nested_t, nested_f) => {
            ctx.gas.consume(interpret_cost::IF)?;
            if pop!(V::Bool) {
                interpret(nested_t, ctx, stack)?;
            } else {
                interpret(nested_f, ctx, stack)?;
            }
        }
        I::IfNone(when_none, when_some) => {
            ctx.gas.consume(interpret_cost::IF_NONE)?;
            match pop!(V::Option) {
                Some(x) => {
                    stack.push(*x);
                    interpret(when_some, ctx, stack)?
                }
                None => interpret(when_none, ctx, stack)?,
            }
        }
        I::IfCons(when_cons, when_nil) => {
            ctx.gas.consume(interpret_cost::IF_CONS)?;
            let lst = irrefutable_match!(&mut stack[0]; V::List);
            match lst.uncons() {
                Some(x) => {
                    stack.push(x);
                    interpret(when_cons, ctx, stack)?
                }
                None => {
                    pop!();
                    interpret(when_nil, ctx, stack)?;
                }
            }
        }
        I::IfLeft(when_left, when_right) => {
            ctx.gas.consume(interpret_cost::IF_LEFT)?;
            let or = *pop!(V::Or);
            match or {
                Or::Left(x) => {
                    stack.push(x);
                    interpret(when_left, ctx, stack)?
                }
                Or::Right(x) => {
                    stack.push(x);
                    interpret(when_right, ctx, stack)?;
                }
            }
        }
        I::Int => {
            let i = pop!(V::Nat);
            ctx.gas.consume(interpret_cost::INT_NAT)?;
            stack.push(V::Int(i.into()));
        }
        I::Loop(nested) => {
            ctx.gas.consume(interpret_cost::LOOP_ENTER)?;
            loop {
                ctx.gas.consume(interpret_cost::LOOP)?;
                if pop!(V::Bool) {
                    interpret(nested, ctx, stack)?;
                } else {
                    ctx.gas.consume(interpret_cost::LOOP_EXIT)?;
                    break;
                }
            }
        }
        I::Iter(overload, nested) => {
            ctx.gas.consume(interpret_cost::ITER)?;
            match overload {
                overloads::Iter::List => {
                    let lst = pop!(V::List);
                    for i in lst {
                        ctx.gas.consume(interpret_cost::PUSH)?;
                        stack.push(i);
                        interpret(nested, ctx, stack)?;
                    }
                }
                overloads::Iter::Map => {
                    let map = pop!(V::Map);
                    for (k, v) in map {
                        ctx.gas.consume(interpret_cost::PUSH)?;
                        stack.push(V::new_pair(k, v));
                        interpret(nested, ctx, stack)?;
                    }
                }
            }
        }
        I::Push(v) => {
            ctx.gas.consume(interpret_cost::PUSH)?;
            stack.push(v.clone());
        }
        I::Swap => {
            ctx.gas.consume(interpret_cost::SWAP)?;
            stack.swap(0, 1);
        }
        I::Failwith(ty) => {
            let x = pop!();
            return Err(InterpretError::FailedWith(ty.clone(), x));
        }
        I::Unit => {
            ctx.gas.consume(interpret_cost::UNIT)?;
            stack.push(V::Unit);
        }
        I::Car => {
            ctx.gas.consume(interpret_cost::CAR)?;
            let (l, _) = *pop!(V::Pair);
            stack.push(l);
        }
        I::Cdr => {
            ctx.gas.consume(interpret_cost::CDR)?;
            let (_, r) = *pop!(V::Pair);
            stack.push(r);
        }
        I::Pair => {
            ctx.gas.consume(interpret_cost::PAIR)?;
            let l = pop!();
            let r = pop!();
            stack.push(V::new_pair(l, r));
        }
        I::Unpair => {
            ctx.gas.consume(interpret_cost::UNPAIR)?;
            let (l, r) = *pop!(V::Pair);
            stack.push(r);
            stack.push(l);
        }
        I::ISome => {
            ctx.gas.consume(interpret_cost::SOME)?;
            let v = pop!();
            stack.push(V::new_option(Some(v)));
        }
        I::None => {
            ctx.gas.consume(interpret_cost::NONE)?;
            stack.push(V::new_option(None));
        }
        I::Compare => {
            let l = pop!();
            let r = pop!();
            ctx.gas.consume(interpret_cost::compare(&l, &r)?)?;
            let cmp = l.partial_cmp(&r).expect("comparison failed") as i8;
            stack.push(V::Int(cmp.into()));
        }
        I::Amount => {
            ctx.gas.consume(interpret_cost::AMOUNT)?;
            stack.push(V::Mutez(ctx.amount));
        }
        I::Nil => {
            ctx.gas.consume(interpret_cost::NIL)?;
            stack.push(V::List(MichelsonList::new()));
        }
        I::Cons => {
            ctx.gas.consume(interpret_cost::CONS)?;
            let elt = pop!();
            let mut lst = pop!(V::List);
            // NB: this is slightly better than lists on average, but needs to
            // be benchmarked.
            lst.cons(elt);
            stack.push(V::List(lst));
        }
        I::Get(overload) => match overload {
            overloads::Get::Map => {
                let key = pop!();
                let map = pop!(V::Map);
                ctx.gas.consume(interpret_cost::map_get(&key, map.len())?)?;
                let result = map.get(&key);
                stack.push(V::new_option(result.cloned()));
            }
        },
        I::Update(overload) => match overload {
            overloads::Update::Map => {
                let key = pop!();
                let opt_new_val = pop!(V::Option);
                let mut map = pop!(V::Map);
                ctx.gas
                    .consume(interpret_cost::map_update(&key, map.len())?)?;
                match opt_new_val {
                    None => map.remove(&key),
                    Some(val) => map.insert(key, *val),
                };
                stack.push(V::Map(map));
            }
        },
        I::ChainId => {
            ctx.gas.consume(interpret_cost::CHAIN_ID)?;
            stack.push(V::ChainId(ctx.chain_id.clone()));
        }
        I::ISelf(entrypoint) => {
            ctx.gas.consume(interpret_cost::SELF)?;
            stack.push(V::Contract(Address {
                hash: ctx.self_address.clone(),
                entrypoint: entrypoint.clone(),
            }));
        }
        I::Pack => {
            ctx.gas.consume(interpret_cost::PACK)?;
            let v = pop!();
            let arena = Arena::new();
            // In the Tezos implementation they also charge gas for the pass
            // that strips locations. We don't have it.
            let mich = typed_value_to_value_optimized_legacy(&arena, v);
            ctx.gas
                .consume(interpret_cost::micheline_encoding(&mich)?)?;
            let encoded = mich.encode_for_pack();
            stack.push(V::Bytes(encoded));
        }
        I::CheckSignature => {
            let key = pop!(V::Key);
            let sig = pop!(V::Signature);
            let msg = pop!(V::Bytes);
            ctx.gas
                .consume(interpret_cost::check_signature(&key, &msg)?)?;
            stack.push(V::Bool(sig.check(&key, &msg)));
        }
        I::TransferTokens => {
            let param = pop!();
            let mutez_amount = pop!(V::Mutez);
            let contract_address = pop!(V::Contract);
            let counter = ctx.operation_counter();
            ctx.gas.consume(interpret_cost::TRANSFER_TOKENS)?;
            stack.push(V::new_operation(
                Operation::TransferTokens(TransferTokens {
                    param,
                    amount: mutez_amount,
                    destination_address: contract_address,
                }),
                counter,
            ));
        }
        I::SetDelegate => {
            let opt_keyhash = pop!(V::Option).map(|kh| irrefutable_match!(*kh; V::KeyHash));
            let counter: u128 = ctx.operation_counter();
            ctx.gas.consume(interpret_cost::SET_DELEGATE)?;
            stack.push(V::new_operation(
                Operation::SetDelegate(SetDelegate(opt_keyhash)),
                counter,
            ))
        }
        I::Address => {
            ctx.gas.consume(interpret_cost::ADDRESS)?;
            let address = pop!(V::Contract);
            stack.push(V::Address(address));
        }
        I::Slice(overload) => {
            fn validate_bounds(
                offset: BigUint,
                length: BigUint,
                actual_length: usize,
            ) -> Option<std::ops::Range<usize>> {
                // If `offset` or `offset + length` are greater than `usize::MAX`, `SLICE` will return `None`.
                // But in reality, slicing a string of length greater than `usize::MAX` would
                // exhaust the gas before execution gets here.
                let start: usize = offset.try_into().ok()?;
                let end: usize = start.checked_add(length.try_into().ok()?)?;

                // `str::get` performs bounds checks, but Michelson's bounds checks
                // are stricter than rust's.
                // E.g. rust allows `String::from("").get(0..0)`, but michelson doesn't.
                // For that reason, we have to perform this additional check here.
                if start >= actual_length {
                    None
                } else {
                    Some(start..end)
                }
            }

            let offset = pop!(V::Nat);
            let length = pop!(V::Nat);
            let result = match overload {
                overloads::Slice::String => {
                    let str = pop!(V::String);

                    ctx.gas.consume(interpret_cost::slice(str.len())?)?;
                    validate_bounds(offset, length, str.len())
                        .and_then(|range| str.get(range))
                        .map(|str| V::String(str.to_string()))
                }
                overloads::Slice::Bytes => {
                    let bytes = pop!(V::Bytes);

                    ctx.gas.consume(interpret_cost::slice(bytes.len())?)?;
                    validate_bounds(offset, length, bytes.len())
                        .and_then(|range| bytes.get(range))
                        .map(|bytes| V::Bytes(bytes.to_owned()))
                }
            };
            stack.push(V::new_option(result));
        }
        I::Seq(nested) => interpret(nested, ctx, stack)?,
    }
    Ok(())
}

#[cfg(test)]
mod interpreter_tests {
    use std::collections::BTreeMap;

    use super::*;
    use crate::ast::michelson_address as addr;
    use crate::gas::Gas;
    use Instruction::*;
    use Option::None;
    use TypedValue as V;

    #[track_caller]
    fn mk_0x(hex: &str) -> TypedValue {
        TypedValue::Bytes(hex::decode(hex).unwrap_or_else(|e| panic!("Invalid hex: {e}")))
    }

    #[test]
    fn test_add() {
        let mut stack = stk![V::nat(10), V::nat(20)];
        let expected_stack = stk![V::nat(30)];
        let mut ctx = Ctx::default();
        assert!(interpret_one(&Add(overloads::Add::NatNat), &mut ctx, &mut stack).is_ok());
        assert_eq!(stack, expected_stack);
    }

    #[test]
    fn test_add_mutez() {
        let mut stack = stk![V::Mutez(2i64.pow(62)), V::Mutez(20)];
        let mut ctx = Ctx::default();
        assert!(interpret_one(&Add(overloads::Add::MutezMutez), &mut ctx, &mut stack).is_ok());
        assert_eq!(ctx.gas.milligas(), Gas::default().milligas() - 20);
        assert_eq!(stack, stk![V::Mutez(2i64.pow(62) + 20)]);
        assert_eq!(
            interpret_one(
                &Add(overloads::Add::MutezMutez),
                &mut ctx,
                &mut stk![V::Mutez(2i64.pow(62)), V::Mutez(2i64.pow(62))]
            ),
            Err(InterpretError::MutezOverflow)
        );
        assert_eq!(
            interpret_one(
                &Add(overloads::Add::MutezMutez),
                &mut ctx,
                &mut stk![
                    V::Mutez((2u64.pow(63) - 1).try_into().unwrap()),
                    V::Mutez(1)
                ]
            ),
            Err(InterpretError::MutezOverflow)
        );
        assert_eq!(
            interpret_one(
                &Add(overloads::Add::MutezMutez),
                &mut ctx,
                &mut stk![
                    V::Mutez(1),
                    V::Mutez((2u64.pow(63) - 1).try_into().unwrap())
                ]
            ),
            Err(InterpretError::MutezOverflow)
        );
    }

    #[test]
    fn test_and_or_xor() {
        #[track_caller]
        fn check(
            instr: Instruction,
            val1: impl Into<TypedValue>,
            val2: impl Into<TypedValue>,
            expected: impl Into<TypedValue>,
        ) {
            let mut stack = stk![val2.into(), val1.into()];
            let mut ctx = Ctx::default();
            assert!(interpret_one(&instr, &mut ctx, &mut stack).is_ok());
            assert_eq!(stack, stk![expected.into()]);
        }

        use overloads as o;

        check(And(o::And::Bytes), mk_0x("05"), mk_0x("06"), mk_0x("04"));
        check(
            And(o::And::Bytes),
            mk_0x("f00f"),
            mk_0x("1234"),
            mk_0x("1004"),
        );
        check(And(o::And::Bytes), mk_0x("f0"), mk_0x("1234"), mk_0x("30"));
        check(
            And(o::And::Bytes),
            mk_0x("f00ff0"),
            mk_0x("1234"),
            mk_0x("0230"),
        );

        check(Or(o::Or::Bytes), mk_0x("05"), mk_0x("06"), mk_0x("07"));
        check(
            Or(o::Or::Bytes),
            mk_0x("f00f"),
            mk_0x("1234"),
            mk_0x("f23f"),
        );
        check(Or(o::Or::Bytes), mk_0x("f0"), mk_0x("1234"), mk_0x("12f4"));
        check(
            Or(o::Or::Bytes),
            mk_0x("f00ff0"),
            mk_0x("1234"),
            mk_0x("f01ff4"),
        );

        check(Xor(o::Xor::Bytes), mk_0x("05"), mk_0x("06"), mk_0x("03"));
        check(
            Xor(o::Xor::Bytes),
            mk_0x("f00f"),
            mk_0x("1234"),
            mk_0x("e23b"),
        );
        check(
            Xor(o::Xor::Bytes),
            mk_0x("f0"),
            mk_0x("1234"),
            mk_0x("12c4"),
        );
        check(
            Xor(o::Xor::Bytes),
            mk_0x("f00ff0"),
            mk_0x("1234"),
            mk_0x("f01dc4"),
        );
    }

    #[test]
    fn test_not() {
        #[track_caller]
        fn check(
            instr: overloads::Not,
            inp: impl Into<TypedValue>,
            expected: impl Into<TypedValue>,
        ) {
            let mut stack = stk![inp.into()];
            let mut ctx = Ctx::default();
            assert!(interpret_one(&Not(instr), &mut ctx, &mut stack).is_ok());
            assert_eq!(stack, stk![expected.into()]);
        }

        use overloads::Not as on;

        check(on::Bool, V::Bool(false), V::Bool(true));
        check(on::Bool, V::Bool(true), V::Bool(false));

        check(on::Int, V::int(0), V::int(-1));
        check(on::Int, V::int(5), V::int(-6));
        check(on::Int, V::int(-1), V::int(0));
        check(
            on::Int,
            V::Int(BigInt::parse_bytes(b"123456789123456789123456789123456789", 10).unwrap()),
            V::Int(BigInt::parse_bytes(b"-123456789123456789123456789123456790", 10).unwrap()),
        );

        check(on::Nat, V::nat(0), V::int(-1));
        check(on::Nat, V::nat(5), V::int(-6));
        check(
            on::Nat,
            V::Nat(BigUint::parse_bytes(b"123456789123456789123456789123456789", 10).unwrap()),
            V::Int(BigInt::parse_bytes(b"-123456789123456789123456789123456790", 10).unwrap()),
        );

        check(on::Bytes, mk_0x(""), mk_0x(""));
        check(on::Bytes, mk_0x("1234"), mk_0x("edcb"));
    }

    #[test]
    fn test_dip() {
        let mut stack = stk![V::nat(20), V::nat(5), V::nat(10)];
        let expected_stack = stk![V::nat(25), V::nat(10)];
        let mut ctx = Ctx::default();
        assert!(interpret_one(
            &Dip(None, vec![Add(overloads::Add::NatNat)]),
            &mut ctx,
            &mut stack
        )
        .is_ok());
        assert_eq!(stack, expected_stack);
    }

    #[test]
    fn test_dip2() {
        let mut stack = stk![V::nat(20), V::nat(5), V::nat(10)];
        let expected_stack = stk![V::nat(5), V::nat(10)];
        let mut ctx = Ctx::default();
        assert!(interpret_one(&Dip(Some(2), vec![Drop(None)]), &mut ctx, &mut stack).is_ok());
        assert_eq!(stack, expected_stack);
    }

    #[test]
    fn test_drop() {
        let mut stack = stk![V::nat(20), V::nat(5), V::nat(10)];
        let expected_stack = stk![V::nat(20), V::nat(5)];
        let mut ctx = Ctx::default();
        assert!(interpret_one(&Drop(None), &mut ctx, &mut stack).is_ok());
        assert_eq!(stack, expected_stack);
    }

    #[test]
    fn test_drop2() {
        let mut stack = stk![V::nat(20), V::nat(5), V::nat(10)];
        let expected_stack = stk![V::nat(20)];
        let mut ctx = Ctx::default();
        assert!(interpret_one(&Drop(Some(2)), &mut ctx, &mut stack).is_ok());
        assert_eq!(stack, expected_stack);
    }

    #[test]
    fn test_dup() {
        let mut stack = stk![V::nat(20), V::nat(5), V::nat(10)];
        let expected_stack = stk![V::nat(20), V::nat(5), V::nat(10), V::nat(10)];
        let mut ctx = Ctx::default();
        assert!(interpret_one(&Dup(None), &mut ctx, &mut stack).is_ok());
        assert_eq!(stack, expected_stack);
    }

    #[test]
    fn test_dup2() {
        let mut stack = stk![V::nat(20), V::nat(5), V::nat(10)];
        let expected_stack = stk![V::nat(20), V::nat(5), V::nat(10), V::nat(5)];
        let mut ctx = Ctx::default();
        assert!(interpret_one(&Dup(Some(2)), &mut ctx, &mut stack).is_ok());
        assert_eq!(stack, expected_stack);
    }

    #[test]
    fn test_gt() {
        let mut stack = stk![V::int(20), V::int(10)];
        let expected_stack = stk![V::int(20), V::Bool(true)];
        let mut ctx = Ctx::default();
        assert!(interpret_one(&Gt, &mut ctx, &mut stack).is_ok());
        assert_eq!(stack, expected_stack);
    }

    #[test]
    fn test_gt_false() {
        let mut stack = stk![V::int(20), V::int(-10)];
        let expected_stack = stk![V::int(20), V::Bool(false)];
        let mut ctx = Ctx::default();
        assert!(interpret_one(&Gt, &mut ctx, &mut stack).is_ok());
        assert_eq!(stack, expected_stack);
    }

    #[test]
    fn test_eq() {
        let mut stack = stk![V::int(20), V::int(0)];
        let expected_stack = stk![V::int(20), V::Bool(true)];
        let mut ctx = Ctx::default();
        assert!(interpret_one(&Eq, &mut ctx, &mut stack).is_ok());
        assert_eq!(stack, expected_stack);
    }

    #[test]
    fn test_eq_false() {
        let mut stack = stk![V::int(20), V::int(1)];
        let expected_stack = stk![V::int(20), V::Bool(false)];
        let mut ctx = Ctx::default();
        assert!(interpret_one(&Eq, &mut ctx, &mut stack).is_ok());
        assert_eq!(stack, expected_stack);
    }

    #[test]
    fn test_le() {
        let mut stack = stk![V::int(20), V::int(-1)];
        let expected_stack = stk![V::int(20), V::Bool(true)];
        let mut ctx = Ctx::default();
        assert!(interpret_one(&Le, &mut ctx, &mut stack).is_ok());
        assert_eq!(stack, expected_stack);
    }

    #[test]
    fn test_le_false() {
        let mut stack = stk![V::int(20), V::int(1)];
        let expected_stack = stk![V::int(20), V::Bool(false)];
        let mut ctx = Ctx::default();
        assert!(interpret_one(&Le, &mut ctx, &mut stack).is_ok());
        assert_eq!(stack, expected_stack);
    }

    #[test]
    fn test_if_t() {
        let mut stack = stk![V::int(20), V::int(5), V::Bool(true)];
        let expected_stack = stk![V::int(20)];
        let mut ctx = Ctx::default();
        assert!(interpret_one(
            &If(vec![Drop(None)], vec![Add(overloads::Add::IntInt)]),
            &mut ctx,
            &mut stack,
        )
        .is_ok());
        assert_eq!(stack, expected_stack);
    }

    #[test]
    fn test_if_f() {
        let mut stack = stk![V::int(20), V::int(5), V::Bool(false)];
        let expected_stack = stk![V::int(25)];
        let mut ctx = Ctx::default();
        assert!(interpret_one(
            &If(vec![Drop(None)], vec![Add(overloads::Add::IntInt)]),
            &mut ctx,
            &mut stack,
        )
        .is_ok());
        assert_eq!(stack, expected_stack);
    }

    #[test]
    fn test_int() {
        let mut stack = stk![V::nat(20), V::nat(10)];
        let expected_stack = stk![V::nat(20), V::int(10)];
        let mut ctx = Ctx::default();
        assert!(interpret_one(&Int, &mut ctx, &mut stack).is_ok());
        assert_eq!(stack, expected_stack);
    }

    #[test]
    fn test_push() {
        let mut stack = stk![V::nat(20), V::nat(10)];
        let expected_stack = stk![V::nat(20), V::nat(10), V::nat(0)];
        let mut ctx = Ctx::default();
        assert!(interpret_one(&Push(V::nat(0)), &mut ctx, &mut stack).is_ok());
        assert_eq!(stack, expected_stack);
    }

    #[test]
    fn test_loop_0() {
        let mut stack = stk![V::nat(20), V::nat(10), V::Bool(false)];
        let expected_stack = stk![V::nat(20), V::nat(10)];
        let mut ctx = Ctx::default();
        assert!(interpret_one(
            &Loop(vec![
                Push(V::nat(1)),
                Add(overloads::Add::NatNat),
                Push(V::Bool(false))
            ]),
            &mut ctx,
            &mut stack,
        )
        .is_ok());
        assert_eq!(stack, expected_stack);
    }

    #[test]
    fn test_loop_1() {
        let mut stack = stk![V::nat(20), V::nat(10), V::Bool(true)];
        let expected_stack = stk![V::nat(20), V::nat(11)];
        let mut ctx = Ctx::default();
        assert!(interpret_one(
            &Loop(vec![
                Push(V::nat(1)),
                Add(overloads::Add::NatNat),
                Push(V::Bool(false))
            ]),
            &mut ctx,
            &mut stack,
        )
        .is_ok());
        assert_eq!(stack, expected_stack);
    }

    #[test]
    fn test_loop_many() {
        let mut stack = stk![V::nat(20), V::int(10), V::Bool(true)];
        let expected_stack = stk![V::nat(20), V::int(0)];
        let mut ctx = Ctx::default();
        assert!(interpret_one(
            &Loop(vec![
                Push(V::int(-1)),
                Add(overloads::Add::IntInt),
                Dup(None),
                Gt
            ]),
            &mut ctx,
            &mut stack,
        )
        .is_ok());
        assert_eq!(stack, expected_stack);
    }

    #[test]
    fn test_iter_list_many() {
        let mut stack = stk![
            V::List(vec![].into()),
            V::List((1..5).map(V::int).collect())
        ];
        assert!(interpret_one(
            &Iter(overloads::Iter::List, vec![Cons]),
            &mut Ctx::default(),
            &mut stack,
        )
        .is_ok());
        // NB: walking a list start-to-end and CONSing each element effectively
        // reverses the list.
        assert_eq!(stack, stk![V::List((1..5).rev().map(V::int).collect())]);
    }

    #[test]
    fn test_iter_list_zero() {
        let mut stack = stk![V::Unit, V::List(vec![].into())];
        assert!(interpret_one(
            &Iter(overloads::Iter::List, vec![Drop(None)]),
            &mut Ctx::default(),
            &mut stack,
        )
        .is_ok());
        assert_eq!(stack, stk![V::Unit]);
    }

    #[test]
    fn test_iter_map_many() {
        let mut stack = stk![
            V::List(vec![].into()),
            V::Map(
                vec![
                    (V::int(1), V::nat(1)),
                    (V::int(2), V::nat(2)),
                    (V::int(3), V::nat(3)),
                ]
                .into_iter()
                .collect()
            )
        ];
        assert!(interpret_one(
            &Iter(overloads::Iter::Map, vec![Cons]),
            &mut Ctx::default(),
            &mut stack,
        )
        .is_ok());
        assert_eq!(
            stack,
            stk![V::List(
                // NB: traversing the map start-to-end, we're CONSing to a
                // list, thus the first element of the map is the last element
                // of the list.
                vec![
                    V::new_pair(V::int(3), V::nat(3)),
                    V::new_pair(V::int(2), V::nat(2)),
                    V::new_pair(V::int(1), V::nat(1)),
                ]
                .into()
            )]
        );
    }

    #[test]
    fn test_iter_map_zero() {
        let mut stack = stk![V::int(0), V::Map(BTreeMap::new())];
        assert!(interpret_one(
            &Iter(overloads::Iter::Map, vec![Car, Add(overloads::Add::IntInt)]),
            &mut Ctx::default(),
            &mut stack,
        )
        .is_ok());
        assert_eq!(stack, stk![V::int(0)]);
    }

    #[test]
    fn test_swap() {
        let mut stack = stk![V::nat(20), V::int(10)];
        let expected_stack = stk![V::int(10), V::nat(20)];
        let mut ctx = Ctx::default();
        assert!(interpret_one(&Swap, &mut ctx, &mut stack).is_ok());
        assert_eq!(stack, expected_stack);
    }

    #[test]
    fn test_failwith() {
        assert_eq!(
            interpret_one(
                &Failwith(Type::Nat),
                &mut Ctx::default(),
                &mut stk![V::nat(20)]
            ),
            Err(InterpretError::FailedWith(Type::Nat, V::nat(20)))
        );
    }

    #[test]
    fn push_string_value() {
        let mut stack = stk![];
        assert_eq!(
            interpret(
                &vec![Push(V::String("foo".to_owned()))],
                &mut Ctx::default(),
                &mut stack
            ),
            Ok(())
        );
        assert_eq!(stack, stk![V::String("foo".to_owned())]);
    }

    #[test]
    fn push_unit_value() {
        let mut stack = stk![];
        assert_eq!(
            interpret(&vec![Push(V::Unit)], &mut Ctx::default(), &mut stack),
            Ok(())
        );
        assert_eq!(stack, stk![V::Unit]);
    }

    #[test]
    fn unit_instruction() {
        let mut stack = stk![];
        let mut ctx = Ctx::default();
        assert!(interpret(&vec![Unit], &mut ctx, &mut stack).is_ok());
        assert_eq!(stack, stk![V::Unit]);
        assert_eq!(
            ctx.gas.milligas(),
            Gas::default().milligas() - interpret_cost::UNIT - interpret_cost::INTERPRET_RET
        );
    }

    #[test]
    fn push_pair() {
        let mut stack = stk![];
        let mut ctx = Ctx::default();
        assert!(interpret(
            &vec![Push(V::new_pair(
                V::int(-5),
                V::new_pair(V::nat(3), V::Bool(false))
            ))],
            &mut ctx,
            &mut stack
        )
        .is_ok());
        assert_eq!(
            stack,
            stk![V::new_pair(
                V::int(-5),
                V::new_pair(V::nat(3), V::Bool(false))
            )]
        );
        assert_eq!(
            ctx.gas.milligas(),
            Gas::default().milligas() - interpret_cost::PUSH - interpret_cost::INTERPRET_RET
        );
    }

    #[test]
    fn push_option() {
        let mut stack = stk![];
        let mut ctx = Ctx::default();
        assert!(interpret(
            &vec![Push(V::new_option(Some(V::int(-5))))],
            &mut ctx,
            &mut stack
        )
        .is_ok());
        assert_eq!(stack, stk![V::new_option(Some(V::int(-5)))]);
        assert_eq!(
            ctx.gas.milligas(),
            Gas::default().milligas() - interpret_cost::PUSH - interpret_cost::INTERPRET_RET
        );
    }

    #[test]
    fn car() {
        let mut stack = stk![];
        let mut ctx = Ctx::default();
        assert!(interpret(
            &vec![
                Push(V::new_pair(
                    V::int(-5),
                    V::new_pair(V::nat(3), V::Bool(false))
                )),
                Car
            ],
            &mut ctx,
            &mut stack
        )
        .is_ok());
        assert_eq!(stack, stk![V::int(-5)]);
        assert_eq!(
            ctx.gas.milligas(),
            Gas::default().milligas()
                - interpret_cost::PUSH
                - interpret_cost::CAR
                - interpret_cost::INTERPRET_RET
        );
    }

    #[test]
    fn cdr() {
        let mut stack = stk![];
        let mut ctx = Ctx::default();
        assert!(interpret(
            &vec![
                Push(V::new_pair(
                    V::new_pair(V::nat(3), V::Bool(false)),
                    V::int(-5),
                )),
                Cdr
            ],
            &mut ctx,
            &mut stack
        )
        .is_ok());
        assert_eq!(stack, stk![V::int(-5)]);
        assert_eq!(
            ctx.gas.milligas(),
            Gas::default().milligas()
                - interpret_cost::PUSH
                - interpret_cost::CDR
                - interpret_cost::INTERPRET_RET
        );
    }

    #[test]
    fn pair() {
        let mut stack = stk![V::nat(42), V::Bool(false)]; // NB: bool is top
        assert!(interpret(&vec![Pair], &mut Ctx::default(), &mut stack).is_ok());
        assert_eq!(stack, stk![V::new_pair(V::Bool(false), V::nat(42))]);
    }

    #[test]
    fn unpair() {
        let mut stack = stk![V::new_pair(V::Bool(false), V::nat(42))];
        assert!(interpret(&vec![Unpair], &mut Ctx::default(), &mut stack).is_ok());
        assert_eq!(stack, stk![V::nat(42), V::Bool(false)]);
    }

    #[test]
    fn pair_car() {
        let mut stack = stk![V::nat(42), V::Bool(false)]; // NB: bool is top
        assert!(interpret(&vec![Pair, Car], &mut Ctx::default(), &mut stack).is_ok());
        assert_eq!(stack, stk![V::Bool(false)]);
    }

    #[test]
    fn pair_cdr() {
        let mut stack = stk![V::nat(42), V::Bool(false)]; // NB: bool is top
        assert!(interpret(&vec![Pair, Cdr], &mut Ctx::default(), &mut stack).is_ok());
        assert_eq!(stack, stk![V::nat(42)]);
    }

    #[test]
    fn if_none_1() {
        let code = vec![IfNone(vec![Push(V::int(5))], vec![])];
        // with Some
        let mut stack = stk![V::new_option(Some(V::int(42)))];
        let mut ctx = Ctx::default();
        assert_eq!(interpret(&code, &mut ctx, &mut stack), Ok(()));
        assert_eq!(stack, stk![V::int(42)]);
        assert_eq!(
            ctx.gas.milligas(),
            Gas::default().milligas() - interpret_cost::IF_NONE - interpret_cost::INTERPRET_RET * 2
        );
    }

    #[test]
    fn if_none_2() {
        let code = vec![IfNone(vec![Push(V::int(5))], vec![])];
        // with None
        let mut stack = stk![V::new_option(None)];
        let mut ctx = Ctx::default();
        assert_eq!(interpret(&code, &mut ctx, &mut stack), Ok(()));
        assert_eq!(stack, stk![V::int(5)]);
        assert_eq!(
            ctx.gas.milligas(),
            Gas::default().milligas()
                - interpret_cost::IF_NONE
                - interpret_cost::PUSH
                - interpret_cost::INTERPRET_RET * 2
        );
    }

    #[test]
    fn if_cons_cons() {
        let code = vec![IfCons(vec![Swap, Drop(None)], vec![Push(V::int(0))])];
        let mut stack = stk![V::List(vec![V::int(1), V::int(2)].into())];
        let mut ctx = Ctx::default();
        assert_eq!(interpret(&code, &mut ctx, &mut stack), Ok(()));
        assert_eq!(stack, stk![V::int(1)]);
        assert_eq!(
            ctx.gas.milligas(),
            Gas::default().milligas()
                - interpret_cost::IF_CONS
                - interpret_cost::SWAP
                - interpret_cost::DROP
                - interpret_cost::INTERPRET_RET * 2
        );
    }

    #[test]
    fn if_cons_nil() {
        let code = vec![IfCons(vec![Swap, Drop(None)], vec![Push(V::int(0))])];
        let mut stack = stk![V::List(vec![].into())];
        let mut ctx = Ctx::default();
        assert_eq!(interpret(&code, &mut ctx, &mut stack), Ok(()));
        assert_eq!(stack, stk![V::int(0)]);
        assert_eq!(
            ctx.gas.milligas(),
            Gas::default().milligas()
                - interpret_cost::IF_CONS
                - interpret_cost::PUSH
                - interpret_cost::INTERPRET_RET * 2
        );
    }

    #[test]
    fn if_left_left() {
        let code = vec![IfLeft(vec![], vec![Drop(None), Push(V::int(0))])];
        let mut stack = stk![V::new_or(or::Or::Left(V::int(1)))];
        let mut ctx = Ctx::default();
        assert_eq!(interpret(&code, &mut ctx, &mut stack), Ok(()));
        assert_eq!(stack, stk![V::int(1)]);
        assert_eq!(
            ctx.gas.milligas(),
            Gas::default().milligas() - interpret_cost::IF_LEFT - interpret_cost::INTERPRET_RET * 2
        );
    }

    #[test]
    fn if_left_right() {
        let code = vec![IfLeft(vec![], vec![Drop(None), Push(V::int(0))])];
        let mut stack = stk![V::new_or(or::Or::Right(V::Unit))];
        let mut ctx = Ctx::default();
        assert_eq!(interpret(&code, &mut ctx, &mut stack), Ok(()));
        assert_eq!(stack, stk![V::int(0)]);
        assert_eq!(
            ctx.gas.milligas(),
            Gas::default().milligas()
                - interpret_cost::IF_LEFT
                - interpret_cost::DROP
                - interpret_cost::PUSH
                - interpret_cost::INTERPRET_RET * 2
        );
    }

    #[test]
    fn some() {
        let mut stack = stk![V::int(5)];
        let mut ctx = Ctx::default();
        assert!(interpret(&vec![ISome], &mut ctx, &mut stack).is_ok());
        assert_eq!(stack, stk![V::new_option(Some(V::int(5)))]);
        assert_eq!(
            ctx.gas.milligas(),
            Gas::default().milligas() - interpret_cost::SOME - interpret_cost::INTERPRET_RET
        );
    }

    #[test]
    fn none() {
        let mut stack = stk![];
        let mut ctx = Ctx::default();
        assert!(interpret(&vec![Instruction::None], &mut ctx, &mut stack).is_ok());
        assert_eq!(stack, stk![V::new_option(None)]);
        assert_eq!(
            ctx.gas.milligas(),
            Gas::default().milligas() - interpret_cost::NONE - interpret_cost::INTERPRET_RET
        );
    }

    #[test]
    fn compare() {
        macro_rules! test {
            ($expr:tt, $res:tt) => {
                let mut stack = stk!$expr;
                let expected_cost = interpret_cost::compare(&stack[0], &stack[1]).unwrap()
                    + interpret_cost::INTERPRET_RET;
                let mut ctx = Ctx::default();
                assert!(interpret(&vec![Compare], &mut ctx, &mut stack).is_ok());
                assert_eq!(stack, stk!$res);
                assert_eq!(ctx.gas.milligas(), Gas::default().milligas() - expected_cost);
            };
        }
        test!([V::int(5), V::int(6)], [V::int(1)]);
        test!([V::int(5), V::int(5)], [V::int(0)]);
        test!([V::int(6), V::int(5)], [V::int(-1)]);
        test!([V::Bool(true), V::Bool(false)], [V::int(-1)]);
        test!([V::Bool(true), V::Bool(true)], [V::int(0)]);
        test!([V::Bool(false), V::Bool(true)], [V::int(1)]);
        test!([V::Bool(false), V::Bool(false)], [V::int(0)]);
        test!(
            [V::String("foo".to_owned()), V::String("bar".to_owned())],
            [V::int(-1)]
        );
        test!([V::Unit, V::Unit], [V::int(0)]);
        test!(
            [V::new_option(Some(V::int(5))), V::Option(None)],
            [V::int(-1)]
        );
    }

    #[test]
    fn amount() {
        let mut stack = stk![];
        let mut ctx = Ctx::default();
        ctx.amount = 100500;
        assert_eq!(interpret(&vec![Amount], &mut ctx, &mut stack), Ok(()));
        assert_eq!(stack, stk![V::Mutez(100500)]);
        assert_eq!(
            ctx.gas.milligas(),
            Gas::default().milligas() - interpret_cost::INTERPRET_RET - interpret_cost::AMOUNT,
        )
    }

    #[test]
    fn push_int_list() {
        let mut stack = stk![];
        let mut ctx = Ctx::default();
        assert_eq!(
            interpret(
                &vec![Push(V::List(vec![V::int(1), V::int(2), V::int(3),].into()))],
                &mut ctx,
                &mut stack
            ),
            Ok(())
        );
        assert_eq!(
            stack,
            stk![V::List(vec![V::int(1), V::int(2), V::int(3),].into())]
        );
        assert_eq!(
            ctx.gas.milligas(),
            Gas::default().milligas() - interpret_cost::PUSH - interpret_cost::INTERPRET_RET
        );
    }

    #[test]
    fn nil() {
        let mut stack = stk![];
        let mut ctx = Ctx::default();
        assert_eq!(interpret(&vec![Nil], &mut ctx, &mut stack), Ok(()));
        assert_eq!(stack, stk![V::List(vec![].into())]);
        assert_eq!(
            ctx.gas.milligas(),
            Gas::default().milligas() - interpret_cost::NIL - interpret_cost::INTERPRET_RET,
        )
    }

    #[test]
    fn cons() {
        let mut stack = stk![V::List(vec![V::int(321)].into()), V::int(123)];
        let mut ctx = Ctx::default();
        assert_eq!(interpret(&vec![Cons], &mut ctx, &mut stack), Ok(()));
        assert_eq!(stack, stk![V::List(vec![V::int(123), V::int(321)].into())]);
        assert_eq!(
            ctx.gas.milligas(),
            Gas::default().milligas() - interpret_cost::CONS - interpret_cost::INTERPRET_RET,
        )
    }

    #[test]
    fn push_map() {
        let mut stack = stk![];
        let mut ctx = Ctx::default();
        let map = BTreeMap::from([
            (V::int(1), V::String("foo".to_owned())),
            (V::int(2), V::String("bar".to_owned())),
        ]);
        assert_eq!(
            interpret(&vec![Push(V::Map(map.clone()))], &mut ctx, &mut stack),
            Ok(())
        );
        assert_eq!(stack, stk![V::Map(map)]);
        assert_eq!(
            ctx.gas.milligas(),
            Gas::default().milligas() - interpret_cost::PUSH - interpret_cost::INTERPRET_RET
        );
    }

    #[test]
    fn get_map() {
        let mut ctx = Ctx::default();
        let map = BTreeMap::from([
            (V::int(1), V::String("foo".to_owned())),
            (V::int(2), V::String("bar".to_owned())),
        ]);
        let mut stack = stk![V::Map(map), V::int(1)];
        assert_eq!(
            interpret(&vec![Get(overloads::Get::Map)], &mut ctx, &mut stack),
            Ok(())
        );
        assert_eq!(
            stack,
            stk![V::new_option(Some(V::String("foo".to_owned())))]
        );
        assert_eq!(
            ctx.gas.milligas(),
            Gas::default().milligas()
                - interpret_cost::map_get(&V::int(1), 2).unwrap()
                - interpret_cost::INTERPRET_RET
        );
    }

    #[test]
    fn get_map_none() {
        let mut ctx = Ctx::default();
        let map = BTreeMap::from([
            (V::int(1), V::String("foo".to_owned())),
            (V::int(2), V::String("bar".to_owned())),
        ]);
        let mut stack = stk![V::Map(map), V::int(100500)];
        assert_eq!(
            interpret(&vec![Get(overloads::Get::Map)], &mut ctx, &mut stack),
            Ok(())
        );
        assert_eq!(stack, stk![V::Option(None)]);
        assert_eq!(
            ctx.gas.milligas(),
            Gas::default().milligas()
                - interpret_cost::map_get(&V::int(100500), 2).unwrap()
                - interpret_cost::INTERPRET_RET
        );
    }

    #[test]
    fn update_map_insert() {
        let mut ctx = Ctx::default();
        let map = BTreeMap::new();
        let mut stack = stk![
            V::Map(map),
            V::new_option(Some(V::String("foo".to_owned()))),
            V::int(1)
        ];
        assert_eq!(
            interpret(&vec![Update(overloads::Update::Map)], &mut ctx, &mut stack),
            Ok(())
        );
        assert_eq!(
            stack,
            stk![V::Map(BTreeMap::from([(
                V::int(1),
                V::String("foo".to_owned())
            )])),]
        );
        assert_eq!(
            ctx.gas.milligas(),
            Gas::default().milligas()
                - interpret_cost::map_update(&V::int(1), 0).unwrap()
                - interpret_cost::INTERPRET_RET
        );
    }

    #[test]
    fn update_map_update() {
        let mut ctx = Ctx::default();
        let map = BTreeMap::from([(V::int(1), V::String("bar".to_owned()))]);
        let mut stack = stk![
            V::Map(map),
            V::new_option(Some(V::String("foo".to_owned()))),
            V::int(1)
        ];
        assert_eq!(
            interpret(&vec![Update(overloads::Update::Map)], &mut ctx, &mut stack),
            Ok(())
        );
        assert_eq!(
            stack,
            stk![V::Map(BTreeMap::from([(
                V::int(1),
                V::String("foo".to_owned())
            )])),]
        );
        assert_eq!(
            ctx.gas.milligas(),
            Gas::default().milligas()
                - interpret_cost::map_update(&V::int(1), 1).unwrap()
                - interpret_cost::INTERPRET_RET
        );
    }

    #[test]
    fn update_map_remove() {
        let mut ctx = Ctx::default();
        let map = BTreeMap::from([(V::int(1), V::String("bar".to_owned()))]);
        let mut stack = stk![V::Map(map), V::new_option(None), V::int(1)];
        assert_eq!(
            interpret(&vec![Update(overloads::Update::Map)], &mut ctx, &mut stack),
            Ok(())
        );
        assert_eq!(stack, stk![V::Map(BTreeMap::new())]);
        assert_eq!(
            ctx.gas.milligas(),
            Gas::default().milligas()
                - interpret_cost::map_update(&V::int(1), 1).unwrap()
                - interpret_cost::INTERPRET_RET
        );
    }

    #[test]
    fn seq() {
        let mut stack = stk![V::int(1), V::nat(2)];
        assert_eq!(
            interpret(
                &vec![
                    Seq(vec![Pair]),
                    Seq(vec![Seq(vec![Car])]),
                    Seq(vec![]),
                    Seq(vec![Seq(vec![Seq(vec![])])]),
                ],
                &mut Ctx::default(),
                &mut stack
            ),
            Ok(())
        );
        assert_eq!(stack, stk![V::nat(2)]);
    }

    #[test]
    fn add_int_nat() {
        let mut stack = stk![V::nat(123), V::int(456)];
        assert_eq!(
            interpret(
                &vec![Add(overloads::Add::IntNat)],
                &mut Ctx::default(),
                &mut stack
            ),
            Ok(())
        );
        assert_eq!(stack, stk![V::int(579)]);
    }

    #[test]
    fn add_int_nat_2() {
        let mut stack = stk![V::nat(123), V::int(-456)];
        assert_eq!(
            interpret(
                &vec![Add(overloads::Add::IntNat)],
                &mut Ctx::default(),
                &mut stack
            ),
            Ok(())
        );
        assert_eq!(stack, stk![V::int(-333)]);
    }

    #[test]
    fn add_nat_int() {
        let mut stack = stk![V::int(789), V::nat(42)];
        assert_eq!(
            interpret(
                &vec![Add(overloads::Add::NatInt)],
                &mut Ctx::default(),
                &mut stack
            ),
            Ok(())
        );
        assert_eq!(stack, stk![V::int(831)]);
    }

    #[test]
    fn add_nat_int_2() {
        let mut stack = stk![V::int(-789), V::nat(42)];
        assert_eq!(
            interpret(
                &vec![Add(overloads::Add::NatInt)],
                &mut Ctx::default(),
                &mut stack
            ),
            Ok(())
        );
        assert_eq!(stack, stk![V::int(-747)]);
    }

    #[test]
    #[should_panic(
        expected = "Unreachable state reached during interpreting, possibly broken typechecking!"
    )]
    fn trigger_unreachable_state() {
        let mut stack = stk![];
        interpret(
            &vec![Add(overloads::Add::NatInt)],
            &mut Ctx::default(),
            &mut stack,
        )
        .unwrap(); // panics
    }

    #[test]
    fn chain_id_instr() {
        let chain_id = super::ChainId::from_base58_check("NetXynUjJNZm7wi").unwrap();
        let ctx = &mut Ctx::default();
        ctx.chain_id = chain_id.clone();
        let start_milligas = ctx.gas.milligas();
        let stk = &mut stk![];
        assert_eq!(interpret(&vec![Instruction::ChainId], ctx, stk), Ok(()));
        assert_eq!(stk, &stk![V::ChainId(chain_id)]);
        assert_eq!(
            start_milligas - ctx.gas.milligas(),
            interpret_cost::CHAIN_ID + interpret_cost::INTERPRET_RET
        );
    }

    #[test]
    fn self_instr() {
        let stk = &mut stk![];
        let ctx = &mut Ctx::default();
        ctx.self_address = "KT18amZmM5W7qDWVt2pH6uj7sCEd3kbzLrHT".try_into().unwrap();
        assert_eq!(
            interpret(&vec![ISelf(Entrypoint::default())], ctx, stk),
            Ok(())
        );
        assert_eq!(
            stk,
            &stk![V::Contract(
                "KT18amZmM5W7qDWVt2pH6uj7sCEd3kbzLrHT".try_into().unwrap()
            )]
        );
    }

    #[test]
    fn set_delegate() {
        use Instruction as I;
        let sd = super::SetDelegate(Some(
            KeyHash::try_from("tz3h4mjmMieZKSaSBWBC7XmeL6JQ3hucFDcP").unwrap(),
        ));
        let stk = &mut stk![V::new_option(Some(V::KeyHash(sd.0.clone().unwrap())))];
        let ctx = &mut Ctx::default();
        ctx.set_operation_counter(100);
        let start_milligas = ctx.gas.milligas();
        assert_eq!(interpret(&vec![I::SetDelegate], ctx, stk), Ok(()));
        assert_eq!(
            stk,
            &stk![V::new_operation(Operation::SetDelegate(sd), 101)]
        );
        assert_eq!(
            start_milligas - ctx.gas.milligas(),
            interpret_cost::SET_DELEGATE + interpret_cost::INTERPRET_RET
        );
    }

    #[test]
    fn self_instr_ep() {
        let stk = &mut stk![];
        let ctx = &mut Ctx::default();
        ctx.self_address = "KT18amZmM5W7qDWVt2pH6uj7sCEd3kbzLrHT".try_into().unwrap();
        assert_eq!(
            interpret(&vec![ISelf(Entrypoint::try_from("foo").unwrap())], ctx, stk),
            Ok(())
        );
        assert_eq!(
            stk,
            &stk![V::Contract(
                "KT18amZmM5W7qDWVt2pH6uj7sCEd3kbzLrHT%foo"
                    .try_into()
                    .unwrap()
            )]
        );
    }

    #[test]
    fn check_signature() {
        for (key, msg, sig, res) in michelson_signature::tests::signature_fixtures() {
            let mut stack = stk![V::Bytes(msg.to_vec()), V::Signature(sig), V::Key(key)];
            assert_eq!(
                interpret_one(&CheckSignature, &mut Ctx::default(), &mut stack),
                Ok(())
            );
            assert_eq!(stack, stk![V::Bool(res)])
        }
    }

    #[test]
    fn address_instr() {
        let address: addr::Address = "KT18amZmM5W7qDWVt2pH6uj7sCEd3kbzLrHT%some_entrypoint"
            .try_into()
            .unwrap();
        let contract = V::Contract(address.clone());
        let stk = &mut stk![contract];
        let ctx = &mut Ctx::default();
        assert_eq!(interpret(&vec![Address], ctx, stk), Ok(()));
        assert_eq!(stk, &stk![V::Address(address)]);
        assert_eq!(
            ctx.gas.milligas(),
            Gas::default().milligas() - interpret_cost::ADDRESS - interpret_cost::INTERPRET_RET
        );
    }
}
