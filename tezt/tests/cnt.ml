(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Trilitech <contact@trili.tech>                         *)
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
   Component:    Protocol
   Invocation:   dune exec tezt/tests/main.exe -- --file cnt.ml
   Subject:      Test the internal counter with baking
*)
let test_cnt =
  Protocol.register_test
    ~__FILE__
    ~title:"Increasing intrernal counter with RPC"
    ~tags:["cnt"; "rpc"]
    ~supports:(Protocol.From_protocol 019)
  @@ fun protocol ->
  let* _, client =
    Client.init_with_protocol
      ~nodes_args:[Synchronisation_threshold 0]
      ~protocol
      `Client
      ()
  in
  let* new_counter =
    Client.cnt ~src:"bootstrap1" ?burn_cap:(Some (Tez.of_int 100)) client
  in
  Check.(
    (new_counter = 1l)
      int32
      ~__LOC__
      ~error_msg:"Expected the counter %R instead of %L") ;
  let* () = Client.bake_for_and_wait client in
  let* new_counter =
    Client.cnt ~src:"bootstrap1" ?burn_cap:(Some (Tez.of_int 100)) client
  in
  (* updating the counter again *)
  Check.(
    (new_counter = 2l)
      int32
      ~__LOC__
      ~error_msg:"Expected the counter %R instead of %L") ;
  let* () = Client.bake_for_and_wait client in
  unit

let register ~protocols = test_cnt protocols
