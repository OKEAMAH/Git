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
    Component:  Protocol (Michelson mock counter instructions)
    Invocation: dune exec src/proto_alpha/lib_protocol/test/integration/michelson/main.exe \
                  -- --file test_mock_counter_instructions.ml
    Subject:    This module tests that Michelson instructions related to mock counter are correct.
*)

open Protocol
open Alpha_context
open Lwt_result_syntax

let make_context () =
  let* block, _ = Context.init1 () in
  let* incr = Incremental.begin_construction block in
  return (Incremental.alpha_ctxt incr)

let test_mock_counter_get () =
  let open Lwt_result_wrap_syntax in
  let* context = make_context () in
  let* result, _ =
    Contract_helpers.run_script
      context
      ~storage:"0"
      ~parameter:"Unit"
      {| { parameter unit; storage int; code { DROP; GET_COUNTER; NIL operation; PAIR } } |}
      ()
  in
  let*@ _, expected_value = Mock_counter.get_value context in
  match Micheline.root result.storage with
  | Int (_, result_storage) when Z.equal result_storage expected_value ->
      return_unit
  | _ ->
      failwith
        "Expected storage to be %a, but got %a"
        Z.pp_print
        expected_value
        Micheline_printer.print_expr
        (Micheline_printer.printable
           Michelson_v1_primitives.string_of_prim
           result.storage)

let test_mock_counter_update () =
  let open Lwt_result_wrap_syntax in
  let* context = make_context () in
  let* result, _ =
    Contract_helpers.run_script
      context
      ~storage:"0"
      ~parameter:"Unit"
      {| 
          { parameter unit; 
            storage int; 
            code 
              { DROP; 
                GET_COUNTER;
                PUSH int 17;
                ADD;
                SET_COUNTER;
                GET_COUNTER;
                NIL operation;
                PAIR } }
      |}
      ()
  in
  let*@ _, past_value = Mock_counter.get_value context in
  let expected_value = Z.add past_value (Z.of_int 17) in
  match Micheline.root result.storage with
  | Int (_, result_storage) when Z.equal result_storage expected_value ->
      return_unit
  | _ ->
      failwith
        "Expected storage to be %a, but got %a"
        Z.pp_print
        expected_value
        Micheline_printer.print_expr
        (Micheline_printer.printable
           Michelson_v1_primitives.string_of_prim
           result.storage)

let tests =
  [
    Tztest.tztest
      "GET_COUNTER gives current value of mock counter"
      `Quick
      test_mock_counter_get;
    Tztest.tztest
      "SET_COUNTER set a new value for the mock counter"
      `Quick
      test_mock_counter_update;
  ]

let () =
  Alcotest_lwt.run
    ~__FILE__
    Protocol.name
    [("mock counter instructions", tests)]
  |> Lwt_main.run
