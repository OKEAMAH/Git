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

module Parameters = struct
  type persistent_state = {
    runner : Runner.t option;
    uri : Uri.t;
    mutable pending_ready : unit option Lwt.u list;
    data_dir : string;
    node : Node.t;
    client : Client.t;
  }

  type session_state = {mutable ready : bool}

  let injector_path = "./octez-injector-server"

  let base_default_name = "injector"

  let default_uri () =
    Uri.make ~scheme:"http" ~host:"127.0.0.1" ~port:(Port.fresh ()) ()

  let default_colors =
    Log.Color.[|BG.green ++ FG.blue; BG.green ++ FG.gray; BG.green ++ FG.blue|]
end

open Parameters
include Daemon.Make (Parameters)

let trigger_ready injector value =
  let pending = injector.persistent_state.pending_ready in
  injector.persistent_state.pending_ready <- [] ;
  List.iter (fun pending -> Lwt.wakeup_later pending value) pending

let set_ready injector =
  (match injector.status with
  | Not_running -> ()
  | Running status -> status.session_state.ready <- true) ;
  trigger_ready injector (Some ())

let handle_readiness injector (event : event) =
  if event.name = "injector_listening.v0" then set_ready injector

let rpc_host injector = Uri.host_with_default injector.persistent_state.uri

let rpc_port injector = Option.get @@ Uri.port injector.persistent_state.uri

let create ?name ?color ?data_dir ?event_pipe ?uri ?runner node client =
  let name = match name with None -> fresh_name () | Some name -> name in
  let uri =
    match uri with None -> Parameters.default_uri () | Some uri -> uri
  in
  let data_dir =
    match data_dir with None -> Temp.dir name | Some dir -> dir
  in
  let injector =
    create
      ~path:injector_path
      ?name:(Some name)
      ?color
      ?event_pipe
      ?runner
      {runner; uri; pending_ready = []; data_dir; node; client}
  in
  on_event injector (handle_readiness injector) ;
  injector

let run injector =
  (match injector.status with
  | Not_running -> ()
  | Running _ -> Test.fail "injector %s is already running" injector.name) ;
  let runner = injector.persistent_state.runner in
  let host =
    Option.value ~default:"127.0.0.1" (Uri.host injector.persistent_state.uri)
  in
  let port_args =
    match Uri.port injector.persistent_state.uri with
    | None -> []
    | Some port -> ["--port"; Int.to_string port]
  in
  let data_dir = injector.persistent_state.data_dir in
  let base_dir_args =
    ["--base-dir"; Client.base_dir injector.persistent_state.client]
  in
  let arguments =
    base_dir_args @ ["run"; "--address"; host] @ port_args
    @ ["--data-dir"; data_dir]
  in
  let on_terminate _ =
    (* Cancel all [Ready] event listeners. *)
    trigger_ready injector None ;
    unit
  in
  run injector {ready = false} arguments ~on_terminate ?runner

let encode_bytes_to_hex_string raw =
  "\"" ^ match Hex.of_bytes raw with `Hex s -> s ^ "\""

module RPC = struct
  let make ?data ?query_string =
    RPC.make
      ?data
      ?query_string
      ~get_host:rpc_host
      ~get_port:rpc_port
      ~get_scheme:(Fun.const "http")

  let inject payload =
    let operation =
      JSON.parse ~origin:"Injector.inject" (encode_bytes_to_hex_string payload)
    in
    let data : RPC_core.data = Data (JSON.unannotate operation) in

    make ~data POST ["inject"] JSON.as_string
end
