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

macro_rules! match_instr {

    (@simp_body $id:ident; $args:tt; $finp:expr; $inp:expr; copy; $tail:tt) => {
        {
            let res = $id$args;
            $crate::interpreter::macros::match_instr!(@simp_body_cont $finp; $inp; $tail; res)
        }
    };
    (@simp_body $id:ident; $args:tt; $finp:expr; $inp:expr; $attr:tt; $tail:tt) => {
        {
            let res = $id$attr;
            $crate::interpreter::macros::match_instr!(@simp_body_cont $finp; $inp; $tail; res)
        }
    };
    (@simp_body $id:ident; $args:tt; $finp:expr; $inp:expr ; $tail:block) => {
      {
        let (res, arr) = $tail;
        $crate::interpreter::macros::match_instr!(@simp_body_cont $finp; $inp; arr; res);
      }
    };
    (@simp_body $id:ident; $args:tt; $finp:expr; $inp:expr ; $tail:tt) => {
        {
            $crate::interpreter::macros::match_instr!(@simp_body_cont $finp; $inp; $tail;);
        }
    };
    (@simp_body_cont $finp:expr; $inp:expr; [!]; $($res:expr)?) => {
        {
            $finp.fail();
            $(Ok($res))?
        }
    };
    (@simp_body_cont $finp:expr; $inp:expr; $new_stk:expr; $($res:expr)?) => {
        {
            let it = $new_stk.into_iter().rev();
            $inp.extend(it);
            $(Ok($res))?
        }
    };
    (@helper { $no_overload:expr; $item_ty:ty; $finp:expr; $inp:expr; $sz:literal }
      simp $id:ident $args:tt => { $( $stk:pat $(if $cond:expr)? =>
        $tail1:tt $([$($tail2:tt)*])? ),* $(,)*
      }
    ) => {
        {
          use $crate::interpreter::macros::match_instr;
          let bx: [$item_ty; $sz] = seq_macro::seq!(N in 0..$sz { [ #($inp.pop().unwrap(),)* ] });
          #[allow(unreachable_patterns)]
          match bx {
            $(
              $stk $(if $cond)? =>
                match_instr!(@simp_body $id; $args; $finp; $inp; $tail1 $(; [$($tail2)*])?),
            )*
            _ => $no_overload,
          }
        }
    };
    (@helper {$($_:tt)*} raw $id:ident $args:tt => ($($attr:expr),* $(,)*) ; $blk:block) => {
      { $blk; Ok($id($($attr),*)) }
    };
    (@helper {$($_:tt)*} raw $id:ident $args:tt => copy ; $blk:block) => {
      { $blk; Ok($id$args) }
    };
    (@helper {$($_:tt)*} raw $id:ident $args:tt => $blk:block) => { $blk };
    (@one_instr $no_stk_err:expr; $no_overload:expr; $i:ident; $finp:expr; $inp:ident: $item_ty:ty; $($kind:ident $id:ident $args:tt [$sz:expr] $(if $cond:expr)? => $($blk:tt);*),* $(,)*) => {
        match $i {
          $(
            $id$args $(if $cond)? => {
              use $crate::interpreter::macros::match_instr;
              if $sz as usize > $inp.len() {
                $no_stk_err;
              }
              match_instr!(@helper {$no_overload; $item_ty; $finp; $inp; $sz} $kind $id $args => $($blk);*)
            }
          ),*
        }
    };
    (; $($defn:tt)*) => {
      $crate::interpreter::macros::match_instr!(@one_instr {}; $($defn)*)
    };
    ($no_stk_err:expr; $($defn:tt)*) => {
      $crate::interpreter::macros::match_instr!(@one_instr
        return Err($no_stk_err);
        $($defn)*
      )
    };
}

pub(super) use match_instr;
