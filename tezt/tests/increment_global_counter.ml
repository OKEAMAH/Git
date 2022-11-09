(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
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
   Component: Shared global counter test
   Invocation:
     dune exec tezt/tests/main.exe -- --file increment_global_counter.ml
   Subject: Tests for testing global counter operations.
*)

let test_increment_global_counter_twice =
  Protocol.register_test
    ~__FILE__
    ~title:"Increase global counter twice"
    ~tags:["global_counter"; "shared_global_counter"]
    ~supports:(Protocol.From_protocol 016)
  @@ fun protocol ->
  let* _, client = Client.init_with_protocol ~protocol `Client () in
  let to_int x =
    let x1 = String.trim x in
    int_of_string @@ String.sub x1 1 (String.length x1 - 2)
  in
  let inc_by_one ~src expected_val_after =
    let* () = Client.increment_global_counter ~src client in
    let* () = Client.bake_for_and_wait client in
    let* val1 = Client.get_global_counter client in
    Check.(to_int val1 = expected_val_after)
      Check.int
      ~error_msg:
        ("Unexpected shared global counter value. Expected %R. Got %L");
    unit
  in
  let* () = inc_by_one ~src:"bootstrap1" 1 in
  let* () = inc_by_one ~src:"bootstrap2" 2 in
  unit

let register ~protocols = test_increment_global_counter_twice protocols