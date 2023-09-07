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

mod ast;
mod parser;
mod syntax;

fn main() {}

#[cfg(test)]
mod tests {
    use crate::parser;

    #[test]
    fn parser_test_expect_success() {
        let src = "{ INT ; PUSH int 0 ; DUP 2 ; GT ;
       IF { DIP { PUSH int -1 ; ADD } ;
            PUSH int 1 ;
            DUP 3 ;
            GT ;
            LOOP { SWAP ; DUP 2 ; ADD ; DIP 2 { PUSH int -1 ; ADD } ; DUP 3 ; GT } ;
            DIP { DROP 2 } }
          { DIP { DROP } } }";

        // use built in pretty printer to validate the expected AST.
        assert_eq!(format!("{:#?}", parser::parse(&src).unwrap()), EXPECTATION);
    }

    #[test]
    fn parser_test_expect_fail() {
        let src = "{ INT ; PUSH int 0 ; DUP 2 ; GT ;
       IF { DIP { PUSH int -1 ; ADD } ;
            PUSH int 1 ;
            DUP 3
            GT ;
            LOOP { SWAP ; DUP 2 ; ADD ; DIP 2 { PUSH int -1 ; ADD } ; DUP 3 ; GT } ;
            DIP { DROP 2 } }
          { DIP { DROP } } }";

        assert!(Option::is_none(&parser::parse(&src)));
    }
    const EXPECTATION: &str = "[
    Int,
    Push(
        Int,
        NumberValue(
            0,
        ),
    ),
    DupN(
        2,
    ),
    Gt,
    If(
        [
            Dip(
                [
                    Push(
                        Int,
                        NumberValue(
                            -1,
                        ),
                    ),
                    Add,
                ],
            ),
            Push(
                Int,
                NumberValue(
                    1,
                ),
            ),
            DupN(
                3,
            ),
            Gt,
            Loop(
                [
                    Swap,
                    DupN(
                        2,
                    ),
                    Add,
                    DipN(
                        2,
                        [
                            Push(
                                Int,
                                NumberValue(
                                    -1,
                                ),
                            ),
                            Add,
                        ],
                    ),
                    DupN(
                        3,
                    ),
                    Gt,
                ],
            ),
            Dip(
                [
                    DropN(
                        2,
                    ),
                ],
            ),
        ],
        [
            Dip(
                [
                    Drop,
                ],
            ),
        ],
    ),
]";
}
