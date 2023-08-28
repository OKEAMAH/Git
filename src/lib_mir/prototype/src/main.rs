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
mod interpreter;
use interpreter::{interpret, stack::stk, stack::FStack, typecheck, typecheck_value};

use lalrpop_util::lalrpop_mod;

lalrpop_mod!(pub syntax);

fn main() -> Result<(), typecheck::TcError> {
    let args: Vec<_> = std::env::args().collect();
    if args.len() != 3 {
        println!("Usage: {} <type> <value>", args[0]);
        println!("Code is accepted at standard input");
        return Ok(());
    }
    let stdin: String = std::io::stdin().lines().flatten().collect();

    let parse_time = std::time::Instant::now();
    let code = syntax::InstrSeqParser::new().parse(&stdin).unwrap();
    let vty = syntax::NakedTypeParser::new().parse(&args[1]).unwrap();
    let val = syntax::NakedValueParser::new().parse(&args[2]).unwrap();
    dbg!(parse_time.elapsed());

    let mut ty_stk = FStack::Ok(stk![vty.clone()]);

    let tc_time = std::time::Instant::now();
    let tc_code = typecheck(code, &mut ty_stk)?;
    dbg!(tc_time.elapsed());

    dbg!(ty_stk);

    let tc_val_time = std::time::Instant::now();
    let tc_val = typecheck_value(val, &vty)?;
    dbg!(tc_val_time.elapsed());

    let mut stk = stk![tc_val];
    let int_time = std::time::Instant::now();
    let int_res = interpret::interpret(&tc_code, &mut stk);
    dbg!(int_time.elapsed());

    #[allow(unused_must_use)]
    {
        dbg!(int_res);
    }
    dbg!(stk);
    Ok(())
}
