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

(* Testing
   -------
   Component:    Node's RPC_process
   Invocation:   dune exec tezt/tests/main.exe -- --file rpc_process.ml
   Subject:      Tests the resilience of the RPC process
*)

let wait_for_RPC_process_pid node =
  let filter json = JSON.(json |> as_int_opt) in
  Node.wait_for node "rpc_process_started.v0" filter

type signal = SIGABRT | SIGINT | SIGKILL | SIGQUIT | SIGTERM

let signal_to_int = function
  | SIGABRT -> Sys.sigabrt
  | SIGINT -> Sys.sigint
  | SIGKILL -> Sys.sigkill
  | SIGQUIT -> Sys.sigquit
  | SIGTERM -> Sys.sigterm

let pp_signal ppf signal =
  let str =
    match signal with
    | SIGABRT -> "sigabrt"
    | SIGINT -> "sigint"
    | SIGKILL -> "sigkill"
    | SIGQUIT -> "sigquit"
    | SIGTERM -> "sigterm"
  in
  Format.fprintf ppf "%s" str

let kill_process ~pid ~signal =
  Log.info "Kill the rpc process (pid %d) with signal %a" pid pp_signal signal ;
  Unix.kill pid (signal_to_int signal)

let head_can_be_requested ~expected_level node =
  let* json = RPC.call node @@ RPC.get_chain_block_header () in
  let v = JSON.(json |-> "level" |> as_int) in
  return (v = expected_level)

let test_kill =
  Protocol.register_test
    ~__FILE__
    ~title:"RPC process kill"
    ~tags:["rpc"; "process"; "kill"]
  @@ fun protocol ->
  let node = Node.create [] in
  let wait_RPC_process_pid = wait_for_RPC_process_pid node in
  let* () = Node.run node [] in
  let* () = Node.wait_for_ready node in
  let* client = Client.init ~endpoint:(Node node) () in
  let* rpc_process_pid = wait_RPC_process_pid in
  Log.info "RPC process is now runnig on pid %d" rpc_process_pid ;
  let* () = Client.activate_protocol_and_wait ~protocol client in
  Log.info "Wait for level 1" ;
  let* (_ : int) = Node.wait_for_level node 1 in
  Log.info "Head can be requested" ;
  let* (_ : bool) = head_can_be_requested ~expected_level:1 node in
  let wait_new_rpc_process_pid = wait_for_RPC_process_pid node in
  let () = kill_process ~pid:rpc_process_pid ~signal:SIGKILL in
  let* new_rpc_process_pid = wait_new_rpc_process_pid in
  Log.info "The new RPC process is now runnig on pid %d" new_rpc_process_pid ;
  Log.info "Head can still be requested" ;
  let* (_ : bool) = head_can_be_requested ~expected_level:1 node in
  unit

let wait_for_RPC_process_sync node =
  let filter json = JSON.(json |> as_int_opt) in
  Node.wait_for node "synchronized.v0" filter

let wait_for_local_rpc_server node =
  Node.wait_for node "starting_local_rpc_server.v0" (fun _ -> Some ())

let test_sync_with_node =
  Protocol.register_test
    ~__FILE__
    ~title:"RPC is sync with node"
    ~tags:["rpc"; "process"; "node"; "sync"]
  @@ fun protocol ->
  let node_arguments = Node.[Synchronisation_threshold 0] in
  (* Default node running with the RPC_process *)
  let* node_rpc_process = Node.init ~name:"node_rpc_process" node_arguments in
  let* () = Node.wait_for_ready node_rpc_process in
  let node_local_rpc =
    Node.create ~local_rpc_server:true ~name:"node_local_rpc" node_arguments
  in
  let waiter_for_local_rpc_server = wait_for_local_rpc_server node_local_rpc in
  let* () = Node.run node_local_rpc node_arguments in
  let* () = Node.wait_for_ready node_local_rpc in
  (* Wait for the event that states that the local RPC server is
     used. *)
  let* () = waiter_for_local_rpc_server in
  let* client = Client.init ~endpoint:(Node node_rpc_process) () in
  let* () = Client.Admin.connect_address ~peer:node_local_rpc client in
  let waiter_for_RPC_process_sync =
    wait_for_RPC_process_sync node_rpc_process
  in
  let* () = Client.activate_protocol_and_wait ~protocol client in
  Log.info
    "Wait for RPC_process sync at level 1 on the %s"
    (Node.name node_rpc_process) ;
  let* (_ : int) = waiter_for_RPC_process_sync in
  Log.info "Wait for level 1 on the %s" (Node.name node_rpc_process) ;
  (* Node.wait_for_level relies on the RPC_process synchronization
     event.*)
  let* (_ : int) = Node.wait_for_level node_rpc_process 1 in
  (* Node.wait_for_level relies on the set_head/branch_switch
     events. *)
  let* (_ : int) = Node.wait_for_level node_local_rpc 1 in
  unit

let register ~protocols =
  test_kill protocols ;
  test_sync_with_node protocols
