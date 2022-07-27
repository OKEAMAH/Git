(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
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
    data_dir : string;
    rpc_host : string;
    rpc_port : int;
    mutable pending_ready : unit option Lwt.u list;
  }

  type session_state = {mutable ready : bool}

  let base_default_name = "tezos-dal-node"

  let default_colors = Log.Color.[|FG.gray; FG.magenta; FG.yellow; FG.green|]
end

open Parameters
include Daemon.Make (Parameters)

let wait dal_node =
  match dal_node.status with
  | Not_running ->
      Test.fail
        "DAL node %s is not running, cannot wait for it to terminate"
        (name dal_node)
  | Running {process; _} -> Process.wait process

let name dal_node = dal_node.name

let rpc_host dal_node = dal_node.persistent_state.rpc_host

let rpc_port dal_node = dal_node.persistent_state.rpc_port

let endpoint dal_node =
  Printf.sprintf "http://%s:%d" (rpc_host dal_node) (rpc_port dal_node)

let data_dir dal_node = dal_node.persistent_state.data_dir

let spawn_command dal_node =
  Process.spawn ~name:dal_node.name ~color:dal_node.color dal_node.path

let spawn_config_init dal_node =
  spawn_command
    dal_node
    [
      "init-config";
      "--data-dir";
      data_dir dal_node;
      "--rpc-port";
      string_of_int (rpc_port dal_node);
      "--rpc-addr";
      rpc_host dal_node;
    ]

let init_config dal_node =
  let process = spawn_config_init dal_node in
  let* output = Process.check_and_read_stdout process in
  match output =~* rex "DAL node configuration written in ([^\n]*)" with
  | None -> failwith "DAL node configuration initialization failed"
  | Some filename -> return filename

let check_event ?timeout ?where sc_node name promise =
  let* result =
    match timeout with
    | None -> promise
    | Some timeout ->
        Lwt.pick
          [
            promise;
            (let* () = Lwt_unix.sleep timeout in
             Lwt.return None);
          ]
  in
  match result with
  | None ->
      raise
        (Terminated_before_event {daemon = sc_node.name; event = name; where})
  | Some x -> return x

let trigger_ready dal_node value =
  let pending = dal_node.persistent_state.pending_ready in
  dal_node.persistent_state.pending_ready <- [] ;
  List.iter (fun pending -> Lwt.wakeup_later pending value) pending

let set_ready dal_node =
  (match dal_node.status with
  | Not_running -> ()
  | Running status -> status.session_state.ready <- true) ;
  trigger_ready dal_node (Some ())

let wait_for_ready dal_node =
  match dal_node.status with
  | Running {session_state = {ready = true; _}; _} -> unit
  | Not_running | Running {session_state = {ready = false; _}; _} ->
      let promise, resolver = Lwt.task () in
      dal_node.persistent_state.pending_ready <-
        resolver :: dal_node.persistent_state.pending_ready ;
      check_event dal_node "dal_node_is_ready.v0" promise

let handle_event dal_node {name; value = _} =
  match name with "dal_node_is_ready.v0" -> set_ready dal_node | _ -> ()

let create ?(path = Constant.dal_node) ?name ?color ?data_dir ?event_pipe
    ?(rpc_host = "127.0.0.1") ?rpc_port () =
  let name = match name with None -> fresh_name () | Some name -> name in
  let data_dir =
    match data_dir with None -> Temp.dir name | Some dir -> dir
  in
  let rpc_port =
    match rpc_port with None -> Port.fresh () | Some port -> port
  in
  let dal_node =
    create
      ~path
      ~name
      ?color
      ?event_pipe
      {data_dir; rpc_host; rpc_port; pending_ready = []}
  in
  on_event dal_node (handle_event dal_node) ;
  dal_node

let do_runlike_command ?env node arguments =
  if node.status <> Not_running then
    Test.fail "DAL node %s is already running" node.name ;
  let on_terminate _status =
    trigger_ready node None ;
    unit
  in
  run ?env node {ready = false} arguments ~on_terminate

let run ?env node =
  do_runlike_command
    ?env
    node
    ["run"; "--data-dir"; node.persistent_state.data_dir]

(* FIXME/DAL: This is a temporary way of querying the node without
   dal_client. This aims to be replaced as soon as possible by
   the dedicated client's RPC. *)
let raw_get_rpc dal_node ~url =
  let* rpc = RPC.Curl.get () in
  match rpc with
  | None -> assert false
  | Some curl ->
      let url =
        Printf.sprintf
          "%s/%s"
          (rpc_host dal_node ^ ":" ^ Int.to_string (rpc_port dal_node))
          url
      in
      curl ~url

let raw_post_rpc dal_node ~url data =
  let* rpc = RPC.Curl.post () in
  match rpc with
  | None -> assert false
  | Some curl ->
      let url =
        Printf.sprintf
          "%s/%s"
          (rpc_host dal_node ^ ":" ^ Int.to_string (rpc_port dal_node))
          url
      in
      curl ~url data

let split_slot_rpc dal_node slot =
  let slot =
    JSON.parse ~origin:"dal_node_split_slot_rpc" (Format.sprintf "\"%s\"" slot)
  in
  let* wrapped_result = raw_post_rpc dal_node ~url:"slot/split?fill" slot in
  return (JSON.as_string wrapped_result)

let slot_content_rpc dal_node slot_header =
  let* wrapped_result =
    let url = Format.sprintf "slot/content/%s/?trim" slot_header in
    raw_get_rpc dal_node ~url
  in
  return (JSON.as_string wrapped_result)

let run node =
  let* () = run node in
  let* () = wait_for_ready node in
  return ()
