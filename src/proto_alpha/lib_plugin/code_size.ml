(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

open Protocol
open Script_typed_ir_size.Internal_for_tests
open Script_ir_translator

type size_record = {
  name : string;
  actual_size : int;
  expected_size : int;
  diff : int;
}

let actual_size item = 8 * Obj.(reachable_words @@ repr item)

let expected_size get item =
  let _, size = get item in
  Saturation_repr.to_int size

let size_record name actual_size expected_size =
  let diff = 1000_000 * (expected_size - actual_size) / actual_size in
  {name; actual_size; expected_size; diff}

let add a b =
  size_record
    a.name
    (a.actual_size + b.actual_size)
    (a.expected_size + b.expected_size)

let view_size_summary name view =
  size_record
    ("view: " ^ Script_string.to_string name)
    (actual_size view)
    (expected_size view_size view)

let code_size_summary (Ex_code (Code script)) =
  let (Lam (instr, code)) = script.code in
  let parts =
    [
      size_record
        "script code size"
        (actual_size code)
        (expected_size Cache_memory_helpers.node_size code);
      size_record
        "script ir size"
        (actual_size instr.kinstr)
        (expected_size kinstr_size instr.kinstr);
      size_record
        "script stack types"
        (actual_size instr.kbef + actual_size instr.kaft)
        (expected_size stack_ty_size instr.kbef
        + expected_size stack_ty_size instr.kaft);
    ]
    @ Script_map.fold
        (fun name view summary -> view_size_summary name view :: summary)
        script.views
        []
  in
  List.append parts
  @@ [
       List.fold_left
         add
         {name = "total"; expected_size = 0; actual_size = 0; diff = 0}
         parts;
     ]

let pp_size_csv fmt {name; actual_size; expected_size; diff} =
  Format.fprintf
    fmt
    "%20s; % 15d; % 20d; %d.%04d\n"
    name
    actual_size
    expected_size
    (diff / 10_000)
    (abs diff mod 10_000)

let pp_summary_csv fmt sizes =
  Format.pp_print_string
    fmt
    "component           ; actual [bytes]; expected_size [bytes]; diff [%]\n" ;
  List.iter (pp_size_csv fmt) sizes
