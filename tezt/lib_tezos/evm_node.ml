(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2023 Functori <contact@functori.com>                        *)
(* Copyright (c) 2023 Marigold <contact@marigold.dev>                        *)
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

module Parameters = struct
  type persistent_state = {
    arguments : string list;
    mutable pending_ready : unit option Lwt.u list;
    version : string;
    rpc_addr : string;
    rpc_port : int;
    rollup_node : Sc_rollup_node.t;
    runner : Runner.t option;
  }

  type session_state = {mutable ready : bool}

  let base_default_name = "evm_node"

  let default_colors = Log.Color.[|FG.magenta|]
end

open Parameters
include Daemon.Make (Parameters)

let string_of_version = function `Development -> "dev" | `Production -> "prod"

let connection_arguments ?version ?rpc_addr ?rpc_port () =
  let open Cli_arg in
  let rpc_port =
    match rpc_port with None -> Port.fresh () | Some port -> port
  in
  ( ["--rpc-port"; string_of_int rpc_port]
    @ optional_arg "rpc-addr" Fun.id rpc_addr
    @ optional_arg "version" string_of_version version,
    Option.value ~default:"127.0.0.1" rpc_addr,
    rpc_port )

let trigger_ready sc_node value =
  let pending = sc_node.persistent_state.pending_ready in
  sc_node.persistent_state.pending_ready <- [] ;
  List.iter (fun pending -> Lwt.wakeup_later pending value) pending

let set_ready evm_node =
  (match evm_node.status with
  | Not_running -> ()
  | Running status -> status.session_state.ready <- true) ;
  trigger_ready evm_node (Some ())

let event_ready_name = "evm_node_is_ready.v0"

let handle_event (evm_node : t) {name; value = _; timestamp = _} =
  if name = event_ready_name then set_ready evm_node else ()

let check_event evm_node name promise =
  let* result = promise in
  match result with
  | None ->
      raise
        (Terminated_before_event
           {daemon = evm_node.name; event = name; where = None})
  | Some x -> return x

let wait_for_ready evm_node =
  match evm_node.status with
  | Running {session_state = {ready = true; _}; _} -> unit
  | Not_running | Running {session_state = {ready = false; _}; _} ->
      let promise, resolver = Lwt.task () in
      evm_node.persistent_state.pending_ready <-
        resolver :: evm_node.persistent_state.pending_ready ;
      check_event evm_node event_ready_name promise

let create ?runner ?version ?rpc_addr ?rpc_port rollup_node =
  let arguments, rpc_addr, rpc_port =
    connection_arguments ?version ?rpc_addr ?rpc_port ()
  in
  let evm_node =
    create
      ~path:Constant.octez_evm_node
      {
        arguments;
        pending_ready = [];
        version =
          (match version with
          | Some version -> string_of_version version
          | None -> string_of_version `Production);
        rpc_addr;
        rpc_port;
        rollup_node;
        runner;
      }
  in
  on_event evm_node (handle_event evm_node) ;
  evm_node

let create ?runner ?version ?rpc_addr ?rpc_port rollup_node =
  create ?runner ?version ?rpc_addr ?rpc_port rollup_node

let rollup_node_endpoint evm_node =
  Sc_rollup_node.endpoint evm_node.persistent_state.rollup_node

let run evm_node =
  let* () =
    run
      evm_node
      {ready = false}
      (["run"; "proxy"; "with"; "endpoint"]
      @ [rollup_node_endpoint evm_node]
      @ evm_node.persistent_state.arguments)
  in
  let* () = wait_for_ready evm_node in
  unit

let spawn_command evm_node args =
  Process.spawn ?runner:evm_node.persistent_state.runner Constant.octez_evm_node
  @@ args

let spawn_run evm_node =
  spawn_command
    evm_node
    (["run"; "proxy"; "with"; "endpoint"]
    @ [rollup_node_endpoint evm_node]
    @ evm_node.persistent_state.arguments)

let endpoint (evm_node : t) =
  Format.sprintf
    "http://%s:%d"
    evm_node.persistent_state.rpc_addr
    evm_node.persistent_state.rpc_port

let init ?runner ?version ?rpc_addr ?rpc_port rollup_node =
  let evm_node = create ?runner ?version ?rpc_addr ?rpc_port rollup_node in
  let* () = run evm_node in
  return evm_node

type request = {method_ : string; parameters : JSON.u}

let request_to_JSON {method_; parameters} : JSON.u =
  `O
    [
      ("jsonrpc", `String "2.0");
      ("method", `String method_);
      ("params", parameters);
      ("id", `String "0");
    ]

let build_request request =
  request_to_JSON request |> JSON.annotate ~origin:"evm_node"

let batch_requests requests =
  `A (List.map request_to_JSON requests) |> JSON.annotate ~origin:"evm_node"

(* We keep both encoding (with a single object or an array of objects) and both
   function on purpose, to ensure both encoding are supported by the server. *)
let call_evm_rpc evm_node request =
  let endpoint = endpoint evm_node in
  Curl.post endpoint (build_request request) |> Runnable.run

let batch_evm_rpc evm_node requests =
  let endpoint = endpoint evm_node in
  Curl.post endpoint (batch_requests requests) |> Runnable.run

let extract_result json = JSON.(json |-> "result")

let extract_error_message json = JSON.(json |-> "error" |-> "message")

let fetch_contract_code evm_node contract_address =
  let* code =
    call_evm_rpc
      evm_node
      {
        method_ = "eth_getCode";
        parameters = `A [`String contract_address; `String "latest"];
      }
  in
  return (extract_result code |> JSON.as_string)

type txpool_slot = {address : string; transactions : (int64 * JSON.t) list}

let txpool_content evm_node =
  let* txpool =
    call_evm_rpc evm_node {method_ = "txpool_content"; parameters = `A []}
  in
  Log.info "Result: %s" (JSON.encode txpool) ;
  let txpool = extract_result txpool in
  let parse field =
    let open JSON in
    let pool = txpool |-> field in
    (* `|->` returns `Null if the field does not exists, and `Null is
       interpreted as the empty list by `as_object`. As such, we must ensure the
       field exists. *)
    if is_null pool then Test.fail "%s must exists" field
    else
      pool |> as_object
      |> List.map (fun (address, transactions) ->
             let transactions =
               transactions |> as_object
               |> List.map (fun (nonce, tx) -> (Int64.of_string nonce, tx))
             in
             {address; transactions})
  in
  return (parse "pending", parse "queued")
