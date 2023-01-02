(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
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
    Component:    Lib_scoru_wasm protocol input kind
    Invocation:   dune exec  src/lib_scoru_wasm/test/test_scoru_wasm.exe \
                    -- test "Input kind"
    Subject:      Protocol input kind tests for the tezos-scoru-wasm library
*)

open Tztest
open Tezos_scoru_wasm.Pvm_input_kind

let internal_message_kind_gen =
  let open QCheck2.Gen in
  oneofl [Transfer; Start_of_level; End_of_level; Info_per_level]

let input_kind_gen =
  let open QCheck2.Gen in
  oneof
    [
      map (fun kind -> Internal kind) internal_message_kind_gen;
      return External;
      return Other;
    ]

let raw_input_gen =
  let open QCheck2.Gen in
  let has_payload = function
    | Internal (Start_of_level | End_of_level) -> false
    | _ -> true
  in
  let* kind = input_kind_gen in
  let+ input =
    match kind with
    | Other -> string_small
    | _ ->
        let+ payload =
          if has_payload kind then map Option.some string_small else return None
        in
        Internal_for_tests.to_binary_input kind payload
  in
  (kind, input)

let test_decode_raw_messages () =
  let test =
    QCheck2.Test.make raw_input_gen (fun (expected_kind, payload) ->
        try
          let kind = from_raw_input payload in
          kind = expected_kind
        with _ -> expected_kind = Other)
  in
  let res = QCheck_base_runner.run_tests ~verbose:true [test] in
  if res = 0 then Lwt_result_syntax.return_unit
  else failwith "QCheck tests failed"

let tests = [tztest "Input kind decoding" `Quick test_decode_raw_messages]
