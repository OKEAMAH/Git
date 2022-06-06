(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Marigold <team@marigold.dev>                           *)
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
   Components: Client
   Invocation: dune exec tezt/tests/main.exe -- check_client_events
   Subject: Test that the client shows the contract events in correct order
*)

let test_emit_event protocol =
  let* node = Node.init [Synchronisation_threshold 0; Connections 0] in
  let* client = Client.init ~endpoint:(Node node) () in
  let* () = Client.activate_protocol ~protocol client in
  let* _ = Node.wait_for_level node 1 in
  let* contract_id =
    Client.originate_contract
      ~alias:"emit_events.tz"
      ~amount:Tez.zero
      ~src:"bootstrap1"
      ~prg:"file:./tezt/tests/contracts/proto_alpha/emit_events.tz"
      ~init:"Unit"
      ~burn_cap:Tez.one
      client
  in
  let* () = Client.bake_for client in
  let* () =
    Client.transfer
      ~gas_limit:100_000
      ~fee:Tez.one
      ~amount:Tez.zero
      ~burn_cap:Tez.one
      ~storage_limit:10000
      ~giver:"bootstrap1"
      ~receiver:contract_id
      ~arg:"Unit"
      ~force:true
      client
  in
  let* () = Client.bake_for client in
  let* first_manager_operation =
    Client.rpc
      Client.GET
      ["chains"; "main"; "blocks"; "head"; "operations"; "3"; "0"]
      client
  in
  let open JSON in
  let first_operation_result =
    first_manager_operation |-> "contents" |=> 0 |-> "metadata"
    |-> "operation_result"
  in
  let events = first_operation_result |-> "events" in
  let event = events |=> 0 in
  assert (
    event |-> "address" |> as_string
    = "ev14AhNYuH5iv4fvjweAdbpqcz67sdjKp9Vkxjq3cUt1A2DkfUbYq") ;
  assert (event |-> "data" |-> "prim" |> as_string = "Right") ;
  assert (event |-> "data" |-> "args" |=> 0 |-> "string" |> as_string = "right") ;
  let event = events |=> 1 in
  assert (
    event |-> "address" |> as_string
    = "ev13PcznZkDuztTvY6xy4TvjdY6mftxLN2kYzV19WFa1nbuzP71mL") ;
  assert (event |-> "data" |-> "prim" |> as_string = "Left") ;
  assert (event |-> "data" |-> "args" |=> 0 |-> "int" |> as_string = "2") ;
  return ()

let check_client_events =
  Protocol.register_test
    ~__FILE__
    ~title:"Events: events from client"
    ~tags:["check_client_events"]
    test_emit_event

let register ~protocols = check_client_events protocols
