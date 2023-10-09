/******************************************************************************/
/*                                                                            */
/* SPDX-License-Identifier: MIT                                               */
/* Copyright (c) [2023] Serokell <hi@serokell.io>                             */
/*                                                                            */
/******************************************************************************/

use crate::ast::*;
use crate::gas;
use crate::gas::{Gas, OutOfGas};
use crate::stack::*;

/// Typechecker error type.
#[derive(Debug, PartialEq, Eq)]
pub enum TcError {
    GenericTcError,
    StackTooShort,
    StacksNotEqual,
    OutOfGas,
    FailNotInTail,
}

impl From<OutOfGas> for TcError {
    fn from(_: OutOfGas) -> Self {
        TcError::OutOfGas
    }
}

#[allow(dead_code)]
pub fn typecheck(
    ast: AST,
    gas: &mut Gas,
    stack: &mut TypeStack,
) -> Result<TypecheckedAST, TcError> {
    ast.into_iter()
        .map(|i| typecheck_instruction(i, gas, stack))
        .collect()
}

fn typecheck_instruction(
    i: ParsedInstruction,
    gas: &mut Gas,
    stack_opt: &mut TypeStack,
) -> Result<TypecheckedInstruction, TcError> {
    use Instruction as I;
    use Type as T;

    let stack: &mut Stack<Type> = match stack_opt {
        Some(s) => s,
        None => {
            return Err(TcError::FailNotInTail);
        }
    };

    gas.consume(gas::tc_cost::INSTR_STEP)?;

    Ok(match i {
        I::Add(..) => match stack.as_slice() {
            [.., T::Nat, T::Nat] => {
                stack.pop();
                I::Add(overloads::Add::NatNat)
            }
            [.., T::Int, T::Int] => {
                stack.pop();
                I::Add(overloads::Add::IntInt)
            }
            [.., T::Mutez, T::Mutez] => {
                stack.pop();
                I::Add(overloads::Add::MutezMutez)
            }
            _ => unimplemented!(),
        },
        I::Dip(opt_height, nested) => {
            let protected_height = opt_height.unwrap_or(1) as usize;

            gas.consume(gas::tc_cost::dip_n(&opt_height)?)?;

            ensure_stack_len(stack, protected_height)?;
            // Here we split off the protected portion of the stack, typecheck the code with the
            // remaining unprotected part, then append the protected portion back on top.
            let mut protected = stack.split_off(protected_height);
            let nested = typecheck(nested, gas, stack_opt)?;
            match stack_opt {
                None => return Err(TcError::FailNotInTail),
                Some(stack) => {
                    stack.append(&mut protected);
                }
            };
            I::Dip(opt_height, nested)
        }
        I::Drop(opt_height) => {
            let drop_height: usize = opt_height.unwrap_or(1) as usize;
            gas.consume(gas::tc_cost::drop_n(&opt_height)?)?;
            ensure_stack_len(&stack, drop_height)?;
            stack.drop_top(drop_height);
            I::Drop(opt_height)
        }
        I::Dup(Some(0)) => {
            // DUP instruction requires an argument that is > 0.
            return Err(TcError::GenericTcError);
        }
        I::Dup(opt_height) => {
            let dup_height: usize = opt_height.unwrap_or(1) as usize;
            ensure_stack_len(stack, dup_height)?;
            stack.push(stack[dup_height - 1].clone());
            I::Dup(opt_height)
        }
        I::Gt => match stack.pop() {
            Some(T::Int) => {
                stack.push(T::Bool);
                I::Gt
            }
            _ => return Err(TcError::GenericTcError),
        },
        I::If(nested_t, nested_f) => match stack.pop() {
            // Check if top is bool
            Some(T::Bool) => {
                // Clone the stack so that we have a copy to run one branch on.
                // We can run the other branch on the live stack.
                let mut t_stack_opt: TypeStack = Some(stack.clone());
                let nested_t = typecheck(nested_t, gas, &mut t_stack_opt)?;
                let nested_f = typecheck(nested_f, gas, stack_opt)?;
                // If both stacks are same after typecheck, all is good.
                ensure_stack_opts_eq(gas, &mut t_stack_opt, stack_opt)?;
                if stack_opt.is_none() {
                    // Replace stack with other branche's stack if it's failed, as
                    // one branch might've been successful.
                    *stack_opt = t_stack_opt
                }
                I::If(nested_t, nested_f)
            }
            _ => return Err(TcError::GenericTcError),
        },
        I::Int => match stack.pop() {
            Some(T::Nat) => {
                stack.push(Type::Int);
                I::Int
            }
            _ => return Err(TcError::GenericTcError),
        },
        I::Loop(nested) => {
            let mut live = stack.clone();
            // Check if top is bool and bind the tail to `t`.
            match stack.pop() {
                Some(T::Bool) => {}
                _ => return Err(TcError::GenericTcError),
            };
            let nested = typecheck(nested, gas, stack_opt)?;
            match stack_opt {
                None => {
                    live.pop();
                    *stack_opt = Some(live)
                }
                Some(stack) => {
                    // If the starting stack and result stack match
                    // then the typecheck is complete. pop the bool
                    // off the original stack to form the final result.
                    ensure_stacks_eq(gas, &live, &stack)?;
                    stack.pop();
                }
            };
            I::Loop(nested)
        }
        I::Push(t, v) => {
            typecheck_value(gas, &t, &v)?;
            stack.push(t.to_owned());
            I::Push(t, v)
        }
        I::Swap => {
            ensure_stack_len(stack, 2)?;
            stack.swap(0, 1);
            I::Swap
        }
        I::Failwith => {
            ensure_stack_len(stack, 1)?;
            *stack_opt = None;
            I::Failwith
        }
    })
}

pub const MAX_TEZ: i128 = 2i128.pow(63) - 1;

fn typecheck_value(gas: &mut Gas, t: &Type, v: &Value) -> Result<(), TcError> {
    use Type::*;
    use Value::*;
    gas.consume(gas::tc_cost::VALUE_STEP)?;
    match (t, v) {
        (Nat, NumberValue(n)) if *n >= 0 => Ok(()),
        (Int, NumberValue(_)) => Ok(()),
        (Bool, BooleanValue(_)) => Ok(()),
        (Mutez, NumberValue(n)) if *n >= 0 && *n <= MAX_TEZ => Ok(()),
        _ => Err(TcError::GenericTcError),
    }
}

/// Ensures type stack is at least of the required length, otherwise returns
/// `Err(StackTooShort)`.
fn ensure_stack_len(stack: &Stack<Type>, l: usize) -> Result<(), TcError> {
    if stack.len() >= l {
        Ok(())
    } else {
        Err(TcError::StackTooShort)
    }
}

/// Ensures two type stacks compare equal, otherwise returns
/// `Err(StacksNotEqual)`. If runs out of gas, returns `Err(OutOfGas)` instead.
fn ensure_stacks_eq(
    gas: &mut Gas,
    stack1: &Stack<Type>,
    stack2: &Stack<Type>,
) -> Result<(), TcError> {
    if stack1.len() != stack2.len() {
        return Err(TcError::StacksNotEqual);
    }
    for (ty1, ty2) in stack1.iter().zip(stack2.iter()) {
        ensure_ty_eq(gas, ty1, ty2)?;
    }
    Ok(())
}

/// Ensures two optional type stacks compare equal, otherwise returns
/// `Err(StacksNotEqual)`. If runs out of gas, returns `Err(OutOfGas)` instead.
///
/// Failed stacks (represented as None) compare equal with anything
fn ensure_stack_opts_eq<'a>(
    gas: &mut Gas,
    stack1: &'a mut TypeStack,
    stack2: &'a mut TypeStack,
) -> Result<(), TcError> {
    match (stack1, stack2) {
        (Some(s1), Some(s2)) => ensure_stacks_eq(gas, &s1, &s2)?,
        _ => {}
    };
    Ok(())
}

fn ensure_ty_eq(gas: &mut Gas, ty1: &Type, ty2: &Type) -> Result<(), TcError> {
    gas.consume(gas::tc_cost::ty_eq(ty1.size_for_gas(), ty2.size_for_gas())?)?;
    if ty1 != ty2 {
        Err(TcError::StacksNotEqual)
    } else {
        Ok(())
    }
}

#[cfg(test)]
mod typecheck_tests {
    use crate::parser::*;
    use crate::typechecker::*;
    use Instruction::*;

    #[test]
    fn test_dup() {
        let mut stack = Some(stk![Type::Nat]);
        let expected_stack = Some(stk![Type::Nat, Type::Nat]);
        let mut gas = Gas::new(10000);
        assert_eq!(
            typecheck_instruction(Dup(Some(1)), &mut gas, &mut stack),
            Ok(Dup(Some(1)))
        );
        assert_eq!(stack, expected_stack);
        assert_eq!(gas.milligas(), 10000 - 440);
    }

    #[test]
    fn test_dup_n() {
        let mut stack = Some(stk![Type::Int, Type::Nat]);
        let expected_stack = Some(stk![Type::Int, Type::Nat, Type::Int]);
        let mut gas = Gas::new(10000);
        assert_eq!(
            typecheck_instruction(Dup(Some(2)), &mut gas, &mut stack),
            Ok(Dup(Some(2)))
        );
        assert_eq!(stack, expected_stack);
        assert_eq!(gas.milligas(), 10000 - 440);
    }

    #[test]
    fn test_swap() {
        let mut stack = Some(stk![Type::Nat, Type::Int]);
        let expected_stack = Some(stk![Type::Int, Type::Nat]);
        let mut gas = Gas::new(10000);
        assert_eq!(typecheck_instruction(Swap, &mut gas, &mut stack), Ok(Swap));
        assert_eq!(stack, expected_stack);
        assert_eq!(gas.milligas(), 10000 - 440);
    }

    #[test]
    fn test_int() {
        let mut stack = Some(stk![Type::Nat]);
        let expected_stack = Some(stk![Type::Int]);
        let mut gas = Gas::new(10000);
        assert_eq!(typecheck_instruction(Int, &mut gas, &mut stack), Ok(Int));
        assert_eq!(stack, expected_stack);
        assert_eq!(gas.milligas(), 10000 - 440);
    }

    #[test]
    fn test_drop() {
        let mut stack = Some(stk![Type::Nat]);
        let expected_stack = Some(stk![]);
        let mut gas = Gas::new(10000);
        assert_eq!(
            typecheck(vec![Drop(None)], &mut gas, &mut stack),
            Ok(vec![Drop(None)])
        );
        assert_eq!(stack, expected_stack);
        assert_eq!(gas.milligas(), 10000 - 440);
    }

    #[test]
    fn test_drop_n() {
        let mut stack = Some(stk![Type::Nat, Type::Int]);
        let expected_stack = Some(stk![]);
        let mut gas = Gas::new(10000);
        assert_eq!(
            typecheck_instruction(Drop(Some(2)), &mut gas, &mut stack),
            Ok(Drop(Some(2)))
        );
        assert_eq!(stack, expected_stack);
        assert_eq!(gas.milligas(), 10000 - 440 - 2 * 50);
    }

    #[test]
    fn test_push() {
        let mut stack = Some(stk![Type::Nat]);
        let expected_stack = Some(stk![Type::Nat, Type::Int]);
        let mut gas = Gas::new(10000);
        assert_eq!(
            typecheck_instruction(Push(Type::Int, Value::NumberValue(1)), &mut gas, &mut stack),
            Ok(Push(Type::Int, Value::NumberValue(1)))
        );
        assert_eq!(stack, expected_stack);
        assert_eq!(gas.milligas(), 10000 - 440 - 100);
    }

    #[test]
    fn test_gt() {
        let mut stack = Some(stk![Type::Int]);
        let expected_stack = Some(stk![Type::Bool]);
        let mut gas = Gas::new(10000);
        assert_eq!(typecheck_instruction(Gt, &mut gas, &mut stack), Ok(Gt));
        assert_eq!(stack, expected_stack);
        assert_eq!(gas.milligas(), 10000 - 440);
    }

    #[test]
    fn test_dip() {
        let mut stack = Some(stk![Type::Int, Type::Bool]);
        let expected_stack = Some(stk![Type::Int, Type::Nat, Type::Bool]);
        let mut gas = Gas::new(10000);
        assert_eq!(
            typecheck_instruction(
                Dip(Some(1), parse("{PUSH nat 6}").unwrap()),
                &mut gas,
                &mut stack,
            ),
            Ok(Dip(Some(1), vec![Push(Type::Nat, Value::NumberValue(6))]))
        );
        assert_eq!(stack, expected_stack);
        assert_eq!(gas.milligas(), 10000 - 440 - 440 - 100 - 50);
    }

    #[test]
    fn test_add_int_int() {
        let mut stack = Some(stk![Type::Int, Type::Int]);
        let expected_stack = Some(stk![Type::Int]);
        let mut gas = Gas::new(10000);
        assert_eq!(
            typecheck_instruction(Add(()), &mut gas, &mut stack),
            Ok(Add(overloads::Add::IntInt))
        );
        assert_eq!(stack, expected_stack);
        assert_eq!(gas.milligas(), 10000 - 440);
    }

    #[test]
    fn test_add_nat_nat() {
        let mut stack = Some(stk![Type::Nat, Type::Nat]);
        let expected_stack = Some(stk![Type::Nat]);
        let mut gas = Gas::new(10000);
        assert_eq!(
            typecheck_instruction(Add(()), &mut gas, &mut stack),
            Ok(Add(overloads::Add::NatNat))
        );
        assert_eq!(stack, expected_stack);
        assert_eq!(gas.milligas(), 10000 - 440);
    }

    #[test]
    fn test_add_mutez_mutez() {
        let mut stack = Some(stk![Type::Mutez, Type::Mutez]);
        let expected_stack = Some(stk![Type::Mutez]);
        let mut gas = Gas::new(10000);
        assert_eq!(
            typecheck_instruction(Add(()), &mut gas, &mut stack),
            Ok(Add(overloads::Add::MutezMutez))
        );
        assert_eq!(stack, expected_stack);
        assert_eq!(gas.milligas(), 10000 - 440);
    }

    #[test]
    fn test_loop() {
        let mut stack = Some(stk![Type::Int, Type::Bool]);
        let expected_stack = Some(stk![Type::Int]);
        let mut gas = Gas::new(10000);
        assert_eq!(
            typecheck_instruction(
                Loop(parse("{PUSH bool True}").unwrap()),
                &mut gas,
                &mut stack
            ),
            Ok(Loop(vec![Push(Type::Bool, Value::BooleanValue(true))]))
        );
        assert_eq!(stack, expected_stack);
        assert_eq!(gas.milligas(), 10000 - 440 - 440 - 100 - 60 * 2);
    }

    #[test]
    fn test_loop_stacks_not_equal_length() {
        let mut stack = Some(stk![Type::Int, Type::Bool]);
        let mut gas = Gas::new(10000);
        assert_eq!(
            typecheck_instruction(
                Loop(parse("{PUSH int 1; PUSH bool True}").unwrap()),
                &mut gas,
                &mut stack
            )
            .unwrap_err(),
            TcError::StacksNotEqual
        );
    }

    #[test]
    fn test_loop_stacks_not_equal_types() {
        let mut stack = Some(stk![Type::Int, Type::Bool]);
        let mut gas = Gas::new(10000);
        assert_eq!(
            typecheck_instruction(
                Loop(parse("{DROP; PUSH bool False; PUSH bool True}").unwrap()),
                &mut gas,
                &mut stack
            )
            .unwrap_err(),
            TcError::StacksNotEqual
        );
    }

    #[test]
    fn test_failwith() {
        assert_eq!(
            typecheck_instruction(Failwith, &mut Gas::default(), &mut Some(stk![Type::Int])),
            Ok(Failwith)
        );
    }

    #[test]
    fn test_failed_stacks() {
        macro_rules! test_fail {
            ($code:expr) => {
                assert_eq!(
                    typecheck(
                        parse($code).unwrap(),
                        &mut Gas::default(),
                        &mut Some(stk![])
                    ),
                    Err(TcError::FailNotInTail)
                );
            };
        }
        test_fail!("{ PUSH int 1; FAILWITH; PUSH int 1 }");
        test_fail!("{ PUSH int 1; DIP { PUSH int 1; FAILWITH } }");
        macro_rules! test_ok {
            ($code:expr) => {
                assert!(typecheck(
                    parse($code).unwrap(),
                    &mut Gas::default(),
                    &mut Some(stk![])
                )
                .is_ok());
            };
        }
        test_ok!("{ PUSH bool True; IF { PUSH int 1; FAILWITH } { PUSH int 1 }; GT }");
        test_ok!("{ PUSH bool True; IF { PUSH int 1 } { PUSH int 1; FAILWITH }; GT }");
        test_ok!("{ PUSH bool True; LOOP { PUSH int 1; FAILWITH }; PUSH int 1 }");
    }
}
