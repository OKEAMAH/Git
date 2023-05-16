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

(* Testing
   -------
   Component: Mock_counter
   Invocation: dune exec tezt/tests/main.exe -- --file mock_counter.ml
   Subject: Tests for the client's mock_counter commands
*)

let get_mock_counter_pp value =
  "Value of the mock counter: " ^ Int.to_string value ^ "\n"

let test_update_mock_counter =
  Protocol.register_test
    ~__FILE__
    ~title:"Update mock counter twice"
    ~tags:["mock_counter"]
    ~supports:(Protocol.From_protocol 018)
  @@ fun protocol ->
  let test_value1 = 17 in
  let* _, client = Client.init_with_protocol ~protocol `Client () in
  let* () = Client.mock_counter_update ~src:"bootstrap1" test_value1 client in
  let* () = Client.bake_for_and_wait client in
  let* value1 = Client.mock_counter_get client in
  Check.(value1 = get_mock_counter_pp test_value1)
    Check.string
    ~error_msg:"Wrong mock counter value. Expected %R. Got %L" ;
  let test_value2 = 100 in
  let* () = Client.mock_counter_update ~src:"bootstrap2" test_value2 client in
  let* () = Client.bake_for_and_wait client in
  let* value2 = Client.mock_counter_get client in
  Check.(value2 = get_mock_counter_pp (test_value1 + test_value2))
    Check.string
    ~error_msg:"Wrong mock counter value. Expected %R. Got %L " ;
  unit

let register ~protocols = test_update_mock_counter protocols
