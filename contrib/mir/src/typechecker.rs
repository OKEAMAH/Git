use crate::ast::*;
use crate::stack::*;
use std::collections::VecDeque;

pub fn typecheck(ast: &AST, stack: &mut Stack) -> bool {
    for i in ast {
        if !typecheck_one(&i, stack) {
            return false;
        }
    }
    return true;
}

fn typecheck_one(i: &Instruction, stack: &mut Stack) -> bool {
    use Instruction::*;
    use Type::*;

    match i {
        Add => match stack[..] {
            [.., Type::Nat, Type::Nat] => {
                stack.pop();
                true
            }
            [.., Type::Int, Type::Int] => {
                stack.pop();
                true
            }
            _ => unimplemented!(),
        },
        DipN(_, nested) | Dip(nested) => {
            let h = {
                // Extract the height of the protected stack if the
                // instruction is DipN, or default to 1 if it is Dip.
                if let DipN(h, _) = i {
                    *h
                } else {
                    1
                }
            };
            let protected_height: usize = usize::try_from(h).unwrap();

            let stack_len = stack.len();
            if stack_len < protected_height {
                false
            } else {
                // Here we split the stack into protected and live segments, and after typechecking
                // nested code with the live segment, we append the protected and the potentially
                // modified live segment as the result stack.
                let mut protected = stack.split_off(stack_len - protected_height);
                if typecheck(nested, stack) {
                    stack.append(&mut protected);
                    true
                } else {
                    false
                }
            }
        }
        DropN(_) | Drop => {
            let h = {
                if let DropN(h) = i {
                    *h
                } else {
                    1
                }
            };
            let drop_height: usize = usize::try_from(h).unwrap();
            if stack.len() >= drop_height {
                *stack = stack.split_off(drop_height);
                true
            } else {
                false
            }
        }
        DupN(0) => {
            // DUP instruction requires an argument that is > 0.
            false
        }
        DupN(_) | Dup => {
            let h = {
                if let DupN(h) = i {
                    *h
                } else {
                    1
                }
            };
            let dup_height: usize = usize::try_from(h).unwrap();
            let stack_len: usize = stack.len();
            if dup_height <= stack_len {
                stack.push(stack.get(stack_len - dup_height).unwrap().to_owned());
                true
            } else {
                false
            }
        }
        Gt => match stack[..] {
            [Type::Int, ..] => {
                stack.pop();
                stack.push(Type::Bool);
                true
            }
            _ => false,
        },
        If(nested_t, nested_f) => match stack.as_slice() {
            // Check if top is bool and bind the tail to `t`.
            [t @ .., Type::Bool] => {
                // Clone the stack so that we have two stacks to run
                // the two branches with.
                let mut t_stack: Stack = Vec::from(t.to_owned());
                let mut f_stack: Stack = Vec::from(t.to_owned());
                if typecheck(nested_t, &mut t_stack) && typecheck(nested_f, &mut f_stack) {
                    // If both stacks are same after typecheck, then make result
                    // stack using one of them and return success.
                    if t_stack == f_stack {
                        *stack = t_stack;
                        true
                    } else {
                        false
                    }
                } else {
                    false
                }
            }
            _ => false,
        },
        Instruction::Int => match stack[..] {
            [.., Type::Nat] => {
                stack.pop();
                stack.push(Type::Int);
                true
            }
            _ => false,
        },
        Loop(nested) => match stack.as_slice() {
            // Check if top is bool and bind the tail to `t`.
            [t @ .., Bool] => {
                let mut live: Stack = Vec::from(t.to_owned());
                // Clone the tail and typecheck the nested body using it.
                if typecheck(nested, &mut live) {
                    match live.as_slice() {
                        // ensure the result stack has a bool on top.
                        [r @ .., Bool] => {
                            // If the starting tail and result tail match
                            // then the typecheck is complete. pop the bool
                            // off the original stack to form the final result.
                            if t == r {
                                stack.pop();
                                true
                            } else {
                                false
                            }
                        }
                        _ => false,
                    }
                } else {
                    false
                }
            }
            _ => false,
        },
        Push(t, v) => {
            if typecheck_value(&t, &v) {
                stack.push(t.to_owned());
                true
            } else {
                false
            }
        }
        Swap => {
            let stack_len = stack.len();
            if stack_len > 1 {
                stack.swap(stack_len - 1, stack_len - 2);
                true
            } else {
                false
            }
        }
    }
}

fn typecheck_value(t: &Type, v: &Value) -> bool {
    use Type::*;
    use Value::*;
    match (t, v) {
        (Nat, NumberValue(n)) => n >= &0,
        (Int, NumberValue(_)) => true,
        (Bool, BooleanValue(_)) => true,
        _ => false,
    }
}

#[cfg(test)]
mod typecheck_tests {
    use std::collections::VecDeque;

    use crate::parser::*;
    use crate::typechecker::*;
    use Instruction::*;

    #[test]
    fn test_dup() {
        let mut stack = Vec::from([Type::Nat]);
        let expected_stack = Vec::from([Type::Nat, Type::Nat]);
        typecheck_one(&DupN(1), &mut stack);
        assert!(stack == expected_stack);
    }

    #[test]
    fn test_dup_n() {
        let mut stack = Vec::from([Type::Int, Type::Nat]);
        let expected_stack = Vec::from([Type::Int, Type::Nat, Type::Int]);
        typecheck_one(&DupN(2), &mut stack);
        assert!(stack == expected_stack);
    }

    #[test]
    fn test_swap() {
        let mut stack = Vec::from([Type::Nat, Type::Int]);
        let expected_stack = Vec::from([Type::Int, Type::Nat]);
        typecheck_one(&Swap, &mut stack);
        assert!(stack == expected_stack);
    }

    #[test]
    fn test_int() {
        let mut stack = Vec::from([Type::Nat]);
        let expected_stack = Vec::from([Type::Int]);
        typecheck_one(&Int, &mut stack);
        assert!(stack == expected_stack);
    }

    #[test]
    fn test_drop() {
        let mut stack = Vec::from([Type::Nat]);
        let expected_stack = Vec::from([]);
        typecheck(&parse("{DROP}").unwrap(), &mut stack);
        assert!(stack == expected_stack);
    }

    #[test]
    fn test_drop_n() {
        let mut stack = Vec::from([Type::Nat, Type::Int]);
        let expected_stack = Vec::from([]);
        typecheck_one(&DropN(2), &mut stack);
        assert!(stack == expected_stack);
    }

    #[test]
    fn test_push() {
        let mut stack = Vec::from([Type::Nat]);
        let expected_stack = Vec::from([Type::Nat, Type::Int]);
        typecheck_one(&Push(Type::Int, Value::NumberValue(1)), &mut stack);
        assert!(stack == expected_stack);
    }

    #[test]
    fn test_gt() {
        let mut stack = Vec::from([Type::Int]);
        let expected_stack = Vec::from([Type::Bool]);
        typecheck_one(&Gt, &mut stack);
        assert!(stack == expected_stack);
    }

    #[test]
    fn test_dip() {
        let mut stack = Vec::from([Type::Int, Type::Bool]);
        let expected_stack = Vec::from([Type::Int, Type::Nat, Type::Bool]);
        typecheck_one(&DipN(1, parse("{PUSH nat 6}").unwrap()), &mut stack);
        assert!(stack == expected_stack);
    }

    #[test]
    fn test_add() {
        let mut stack = Vec::from([Type::Int, Type::Int]);
        let expected_stack = Vec::from([Type::Int]);
        typecheck_one(&Add, &mut stack);
        assert!(stack == expected_stack);
    }

    #[test]
    fn test_loop() {
        let mut stack = Vec::from([Type::Int, Type::Bool]);
        let expected_stack = Vec::from([Type::Int]);
        assert!(typecheck_one(
            &Loop(parse("{PUSH bool True}").unwrap()),
            &mut stack
        ));
        assert!(stack == expected_stack);
    }
}
