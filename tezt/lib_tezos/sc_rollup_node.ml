(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
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

module Constant = struct
  let sc_rollup_node = "./tezos-sc-rollup-node-alpha"
end

module Parameters = struct
  type persistent_state = {
    data_dir : string;
    mutable net_port : int;
    advertised_net_port : int option;
    rpc_host : string;
    rpc_port : int;
    node : Node.t;
    mutable pending_ready : unit option Lwt.u list;
  }

  type session_state = {mutable ready : bool}

  let base_default_name = "sc-rollup-node"

  let default_colors = Log.Color.[|FG.gray; FG.magenta; FG.yellow; FG.green|]
end

open Parameters
include Daemon.Make (Parameters)

let check_error ?exit_code ?msg node =
  match node.status with
  | Not_running ->
      Test.fail "node %s is not running, it has no stderr" (name node)
  | Running {process; _} -> Process.check_error ?exit_code ?msg process

let wait node =
  match node.status with
  | Not_running ->
      Test.fail
        "node %s is not running, cannot wait for it to terminate"
        (name node)
  | Running {process; _} -> Process.wait process

let name node = node.name

let net_port node = node.persistent_state.net_port

let advertised_net_port node = node.persistent_state.advertised_net_port

let rpc_host node = node.persistent_state.rpc_host

let rpc_port node = node.persistent_state.rpc_port

let data_dir node = node.persistent_state.data_dir

let starting_port = 1000 + Cli.options.starting_port

let next_port = ref starting_port

let fresh_port () =
  let port = !next_port in
  incr next_port ;
  port

let () = Test.declare_reset_function @@ fun () -> next_port := starting_port

let spawn_command node =
  Process.spawn ~name:node.name ~color:node.color node.path

let spawn_config_init node rollup_address =
  spawn_command
    node
    [
      "config";
      "init";
      "on";
      rollup_address;
      "--data-dir";
      data_dir node;
      "--rpc-addr";
      rpc_host node;
      "--rpc-port";
      string_of_int @@ rpc_port node;
    ]

let config_init node rollup_address =
  let process = spawn_config_init node rollup_address in
  let* output = Process.check_and_read_stdout process in
  match output =~* rex "Configuration written in ([^\n]*)" with
  | None -> failwith "Configuration initialization failed"
  | Some filename -> return filename

module Config_file = struct
  let filename node = sf "%s/config.json" @@ data_dir node

  let read node = JSON.parse_file (filename node)

  let write node config =
    with_open_out (filename node) @@ fun chan ->
    output_string chan (JSON.encode config)

  let update node update = read node |> update |> write node
end

let trigger_ready node value =
  let pending = node.persistent_state.pending_ready in
  node.persistent_state.pending_ready <- [] ;
  List.iter (fun pending -> Lwt.wakeup_later pending value) pending

let set_ready node =
  (match node.status with
  | Not_running -> ()
  | Running status -> status.session_state.ready <- true) ;
  trigger_ready node (Some ())

let handle_event node {name; value = _} =
  match name with "sc_rollup_node_is_ready.v0" -> set_ready node | _ -> ()

let check_event ?where node name promise =
  let* result = promise in
  match result with
  | None ->
      raise (Terminated_before_event {daemon = node.name; event = name; where})
  | Some x -> return x

let wait_for_ready node =
  match node.status with
  | Running {session_state = {ready = true; _}; _} -> unit
  | Not_running | Running {session_state = {ready = false; _}; _} ->
      let (promise, resolver) = Lwt.task () in
      node.persistent_state.pending_ready <-
        resolver :: node.persistent_state.pending_ready ;
      check_event node "sc_rollup_node_is_ready.v0" promise

let create ?(path = Constant.sc_rollup_node) ?name ?color ?data_dir ?event_pipe
    ?net_port ?advertised_net_port ?(rpc_host = "127.0.0.1") ?rpc_port
    (node : Node.t) =
  let name = match name with None -> fresh_name () | Some name -> name in
  let data_dir =
    match data_dir with None -> Temp.dir name | Some dir -> dir
  in
  let net_port =
    match net_port with None -> fresh_port () | Some port -> port
  in
  let rpc_port =
    match rpc_port with None -> fresh_port () | Some port -> port
  in
  let sc_node =
    create
      ~path
      ~name
      ?color
      ?event_pipe
      {
        data_dir;
        net_port;
        advertised_net_port;
        rpc_host;
        rpc_port;
        node;
        pending_ready = [];
      }
  in
  on_event sc_node (handle_event sc_node) ;
  sc_node

let make_arguments node =
  [
    "--endpoint";
    Printf.sprintf
      "http://%s:%d"
      (Node.rpc_host node.persistent_state.node)
      (Node.rpc_port node.persistent_state.node);
  ]

let do_runlike_command node arguments =
  if node.status <> Not_running then
    Test.fail "Smart contract rollup node %s is already running" node.name ;
  let on_terminate _status =
    trigger_ready node None ;
    unit
  in
  let arguments = make_arguments node @ arguments in
  run node {ready = false} arguments ~on_terminate

let run node =
  do_runlike_command node ["run"; "--data-dir"; node.persistent_state.data_dir]

let run node =
  let* () = run node in
  let* () = wait_for_ready node in
  return ()
