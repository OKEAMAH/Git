(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 TriliTech <contact@trili.tech>                         *)
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

(** Testing
    -------
    Component:  Protocol Mock_counter_storage
    Invocation: dune exec src/proto_alpha/lib_protocol/test/unit/main.exe \
                  -- --file test_mock_counter_storage.ml
    Subject:    Tests for the Counter onboarding challenge
*)
open Protocol

open Alpha_context
open Lwt_result_syntax

let make_context () =
  let* block, _contract = Context.init1 () in
  let* incr = Incremental.begin_construction block in
  return (Incremental.alpha_ctxt incr)

let test_init () =
  let* ctxt = make_context () in
  let _ =
    let* new_ctxt, _ = Mock_counter.update_value ctxt (Z.of_int 1) in
    let* _, new_value = Mock_counter.get_value new_ctxt in
    assert (new_value = Z.of_int 1) ;
    return_unit
  in
  return_unit

let test_add () =
  let* ctxt = make_context () in
  let _ =
    let* new_ctxt1, _ = Mock_counter.update_value ctxt (Z.of_int 1) in
    let* new_ctxt1, new_value1 = Mock_counter.get_value new_ctxt1 in
    assert (new_value1 = Z.of_int 1) ;
    let* new_ctxt2, _ = Mock_counter.update_value new_ctxt1 (Z.of_int 2) in
    let* _, new_value2 = Mock_counter.get_value new_ctxt2 in
    assert (new_value2 = Z.of_int 3) ;
    return_unit
  in
  return_unit

let tests =
  [
    Tztest.tztest "Initialise mock counter with value" `Quick test_init;
    Tztest.tztest "Initialise mock counter and add value" `Quick test_add;
  ]

let () =
  Alcotest_lwt.run ~__FILE__ Protocol.name [("mock counter tests", tests)]
  |> Lwt_main.run
