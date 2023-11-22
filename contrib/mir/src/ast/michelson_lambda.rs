/******************************************************************************/
/*                                                                            */
/* SPDX-License-Identifier: MIT                                               */
/* Copyright (c) [2023] Serokell <hi@serokell.io>                             */
/*                                                                            */
/******************************************************************************/

use std::rc::Rc;

use crate::lexer::Prim;

use super::{annotations::NO_ANNS, Instruction, IntoMicheline, Micheline, Type, TypedValue};

#[derive(Debug, Clone, Eq, PartialEq)]
pub enum Lambda<'a> {
    Lambda {
        micheline_code: Micheline<'a>,
        code: Rc<[Instruction<'a>]>,
    },
    LambdaRec {
        /// Lambda argument type
        in_ty: Type,
        /// Lambda result type
        out_ty: Type,
        micheline_code: Micheline<'a>,
        code: Rc<[Instruction<'a>]>,
    },
}

#[derive(Debug, Clone, Eq, PartialEq)]
pub enum Closure<'a> {
    Lambda(Lambda<'a>),
    Apply {
        /// Captured argument type
        arg_ty: Type,
        /// Captured argument value
        arg_val: Box<TypedValue<'a>>,
        /// Inner closure
        closure: Box<Closure<'a>>,
    },
}

impl<'a> IntoMicheline<'a> for Closure<'a> {
    fn into_micheline(self, arena: &'a typed_arena::Arena<Micheline<'a>>) -> Micheline<'a> {
        match self {
            Closure::Lambda(Lambda::Lambda { micheline_code, .. }) => micheline_code,
            Closure::Lambda(Lambda::LambdaRec { micheline_code, .. }) => {
                Micheline::prim1(arena, Prim::Lambda_rec, micheline_code)
            }
            Closure::Apply {
                arg_ty,
                arg_val,
                closure,
            } => match *closure {
                Closure::Lambda(Lambda::LambdaRec {
                    in_ty,
                    out_ty,
                    micheline_code,
                    ..
                }) => Micheline::seq(
                    arena,
                    [
                        Micheline::prim2(
                            arena,
                            Prim::PUSH,
                            arg_ty.into_micheline(arena),
                            arg_val.into_micheline(arena),
                        ),
                        Micheline::prim0(Prim::PAIR),
                        Micheline::prim3(
                            arena,
                            Prim::LAMBDA_REC,
                            in_ty.into_micheline(arena),
                            out_ty.into_micheline(arena),
                            micheline_code,
                        ),
                        Micheline::App(Prim::SWAP, &[], NO_ANNS),
                        Micheline::App(Prim::EXEC, &[], NO_ANNS),
                    ],
                ),
                Closure::Apply { .. } | Closure::Lambda(Lambda::Lambda { .. }) => Micheline::seq(
                    arena,
                    [
                        Micheline::prim2(
                            arena,
                            Prim::PUSH,
                            arg_ty.into_micheline(arena),
                            arg_val.into_micheline(arena),
                        ),
                        Micheline::App(Prim::PAIR, &[], NO_ANNS),
                        closure.into_micheline(arena),
                    ],
                ),
            },
        }
    }
}

#[cfg(test)]
mod tests {
    use typed_arena::Arena;

    use crate::{
        ast::{
            micheline::{
                test_helpers::{app, seq},
                IntoMicheline,
            },
            TypedValue,
        },
        context::Ctx,
        irrefutable_match::irrefutable_match,
        parser::Parser,
        stk,
    };

    #[test]
    fn apply_micheline() {
        let parser = Parser::new();
        let code = parser.parse("{ LAMBDA (pair int nat unit) unit { DROP; UNIT }; PUSH int 1; APPLY; PUSH nat 2; APPLY }").unwrap();
        let code = code
            .typecheck_instruction(&mut Ctx::default(), None, &[])
            .unwrap();
        let mut stack = stk![];
        code.interpret(&mut Ctx::default(), &mut stack).unwrap();
        let closure = irrefutable_match!(stack.pop().unwrap(); TypedValue::Lambda);
        let arena = Arena::new();
        assert_eq!(
            closure.into_micheline(&arena),
            // checked against octez-client
            // { PUSH nat 2 ; PAIR ; { PUSH int 1 ; PAIR ; { DROP ; UNIT } } }
            seq! {
              app!(PUSH[app!(nat), 2]);
              app!(PAIR);
              seq!{
                app!(PUSH[app!(int), 1]);
                app!(PAIR);
                seq! {
                  app!(DROP);
                  app!(UNIT)
                }
              }
            }
        )
    }

    #[test]
    fn apply_micheline_rec() {
        let parser = Parser::new();
        let code = parser.parse("{ LAMBDA_REC (pair int nat unit) unit { DROP 2; UNIT }; PUSH int 1; APPLY; PUSH nat 2; APPLY }").unwrap();
        let code = code
            .typecheck_instruction(&mut Ctx::default(), None, &[])
            .unwrap();
        let mut stack = stk![];
        code.interpret(&mut Ctx::default(), &mut stack).unwrap();
        let closure = irrefutable_match!(stack.pop().unwrap(); TypedValue::Lambda);
        let arena = Arena::new();
        assert_eq!(
            closure.into_micheline(&arena),
            // checked against octez-client
            //   { PUSH nat 2 ;
            //     PAIR ;
            //     { PUSH int 1 ;
            //       PAIR ;
            //       LAMBDA_REC (pair int nat unit) unit { DROP 2 ; UNIT } ;
            //       SWAP ;
            //       EXEC } }
            seq! {
              app!(PUSH[app!(nat), 2]);
              app!(PAIR);
              seq!{
                app!(PUSH[app!(int), 1]);
                app!(PAIR);
                app!(LAMBDA_REC[app!(pair[app!(int), app!(nat), app!(unit)]), app!(unit), seq!{
                  app!(DROP[2]); app!(UNIT)
                }]);
                app!(SWAP);
                app!(EXEC)
              }
            }
        )
    }
}
