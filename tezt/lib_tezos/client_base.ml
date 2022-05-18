(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2020 Nomadic Labs <contact@nomadic-labs.com>                *)
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

open Runnable.Syntax

type endpoint = Node of Node.t | Proxy_server of Proxy_server.t

type media_type = Json | Binary | Any

let rpc_port = function
  | Node n -> Node.rpc_port n
  | Proxy_server ps -> Proxy_server.rpc_port ps

type mode =
  | Client of endpoint option * media_type option
  | Mockup
  | Light of float * endpoint list
  | Proxy of endpoint

type mockup_sync_mode = Asynchronous | Synchronous

type normalize_mode = Readable | Optimized | Optimized_legacy

type t = {
  path : string;
  admin_path : string;
  name : string;
  color : Log.Color.t;
  base_dir : string;
  mutable additional_bootstraps : Account.key list;
  mutable mode : mode;
}

let name t = t.name

let base_dir t = t.base_dir

let additional_bootstraps t = t.additional_bootstraps

let get_mode t = t.mode

let set_mode mode t = t.mode <- mode

let next_name = ref 1

let fresh_name () =
  let index = !next_name in
  incr next_name ;
  "client" ^ string_of_int index

let () = Test.declare_reset_function @@ fun () -> next_name := 1

let runner endpoint =
  match endpoint with
  | Node node -> Node.runner node
  | Proxy_server ps -> Proxy_server.runner ps

let address ?(hostname = false) ?from peer =
  match from with
  | None -> Runner.address ~hostname (runner peer)
  | Some endpoint ->
      Runner.address ~hostname ?from:(runner endpoint) (runner peer)

let set_additional_bootstraps client additional_bootstraps =
  client.additional_bootstraps <- additional_bootstraps

let create_with_mode ?(path = Constant.tezos_client)
    ?(admin_path = Constant.tezos_admin_client) ?name
    ?(color = Log.Color.FG.blue) ?base_dir mode =
  let name = match name with None -> fresh_name () | Some name -> name in
  let base_dir =
    match base_dir with None -> Temp.dir name | Some dir -> dir
  in
  let additional_bootstraps = [] in
  {path; admin_path; name; color; base_dir; additional_bootstraps; mode}

let create ?path ?admin_path ?name ?color ?base_dir ?endpoint ?media_type () =
  create_with_mode
    ?path
    ?admin_path
    ?name
    ?color
    ?base_dir
    (Client (endpoint, media_type))

let base_dir_arg client = ["--base-dir"; client.base_dir]

(* To avoid repeating unduly the sources file name, we create a function here
   to get said file name as string.
   Do not call it from a client in Mockup or Client (nominal) mode. *)
let sources_file client =
  match client.mode with
  | Mockup | Client _ | Proxy _ -> assert false
  | Light _ -> client.base_dir // "sources.json"

let mode_to_endpoint = function
  | Client (None, _) | Mockup | Light (_, []) -> None
  | Client (Some endpoint, _) | Light (_, endpoint :: _) | Proxy endpoint ->
      Some endpoint

(* [?endpoint] can be used to override the default node stored in the client.
   Mockup nodes do not use [--endpoint] at all: RPCs are mocked up.
   Light mode needs a file (specified with [--sources] on the CLI)
   that contains a list of endpoints.
*)
let endpoint_arg ?(endpoint : endpoint option) client =
  let either o1 o2 = match (o1, o2) with Some _, _ -> o1 | _ -> o2 in
  (* pass [?endpoint] first: it has precedence over client.mode *)
  match either endpoint (mode_to_endpoint client.mode) with
  | None -> []
  | Some e ->
      ["--endpoint"; sf "http://%s:%d" (address ~hostname:true e) (rpc_port e)]

let media_type_arg client =
  match client with
  | Client (_, Some media_type) -> (
      match media_type with
      | Json -> ["--media-type"; "json"]
      | Binary -> ["--media-type"; "binary"]
      | Any -> ["--media-type"; "any"])
  | _ -> []

let mode_arg client =
  match client.mode with
  | Client _ -> []
  | Mockup -> ["--mode"; "mockup"]
  | Light _ -> ["--mode"; "light"; "--sources"; sources_file client]
  | Proxy _ -> ["--mode"; "proxy"]

let write_sources_file ~min_agreement ~uris client =
  (* Create a services.json file in the base directory with correctly
     JSONified data *)
  Lwt_io.with_file ~mode:Lwt_io.Output (sources_file client) (fun oc ->
      let obj =
        `O
          [
            ("min_agreement", `Float min_agreement);
            ("uris", `A (List.map (fun s -> `String s) uris));
          ]
      in
      Lwt_io.fprintf oc "%s" @@ Ezjsonm.value_to_string obj)

let init ?path ?admin_path ?name ?color ?base_dir ?endpoint ?media_type () =
  let client =
    create ?path ?admin_path ?name ?color ?base_dir ?endpoint ?media_type ()
  in
  Account.write Constant.all_secret_keys ~base_dir:client.base_dir ;
  return client

let spawn_command ?log_command ?log_status_on_exit ?log_output
    ?(env = String_map.empty) ?endpoint ?hooks ?(admin = false) client command =
  let env =
    (* Set disclaimer to "Y" if unspecified, otherwise use given value *)
    String_map.update
      "TEZOS_CLIENT_UNSAFE_DISABLE_DISCLAIMER"
      (fun o -> Option.value ~default:"Y" o |> Option.some)
      env
  in
  Process.spawn
    ~name:client.name
    ~color:client.color
    ~env
    ?log_command
    ?log_status_on_exit
    ?log_output
    ?hooks
    (if admin then client.admin_path else client.path)
  @@ endpoint_arg ?endpoint client
  @ media_type_arg client.mode @ mode_arg client @ base_dir_arg client @ command

let url_encode str =
  let buffer = Buffer.create (String.length str * 3) in
  for i = 0 to String.length str - 1 do
    match str.[i] with
    | ('a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '.' | '_' | '-' | '/') as c ->
        Buffer.add_char buffer c
    | c ->
        Buffer.add_char buffer '%' ;
        let c1, c2 = Hex.of_char c in
        Buffer.add_char buffer c1 ;
        Buffer.add_char buffer c2
  done ;
  let result = Buffer.contents buffer in
  Buffer.reset buffer ;
  result

type meth = GET | PUT | POST | PATCH | DELETE

let string_of_meth = function
  | GET -> "get"
  | PUT -> "put"
  | POST -> "post"
  | PATCH -> "patch"
  | DELETE -> "delete"

type path = string list

let string_of_path path = "/" ^ String.concat "/" (List.map url_encode path)

type query_string = (string * string) list

let string_of_query_string = function
  | [] -> ""
  | qs ->
      let qs' = List.map (fun (k, v) -> (url_encode k, url_encode v)) qs in
      "?" ^ String.concat "&" @@ List.map (fun (k, v) -> k ^ "=" ^ v) qs'

let rpc_path_query_to_string ?(query_string = []) path =
  string_of_path path ^ string_of_query_string query_string

module Spawn = struct
  let rpc ?log_command ?log_status_on_exit ?log_output ?(better_errors = false)
      ?endpoint ?hooks ?env ?data ?query_string meth path client :
      JSON.t Runnable.process =
    let process =
      let data =
        Option.fold ~none:[] ~some:(fun x -> ["with"; JSON.encode_u x]) data
      in
      let query_string =
        Option.fold ~none:"" ~some:string_of_query_string query_string
      in
      let path = string_of_path path in
      let full_path = path ^ query_string in
      let better_error = if better_errors then ["--better-errors"] else [] in
      spawn_command
        ?log_command
        ?log_status_on_exit
        ?log_output
        ?endpoint
        ?hooks
        ?env
        client
        (better_error @ ["rpc"; string_of_meth meth; full_path] @ data)
    in
    let parse process =
      let* output = Process.check_and_read_stdout process in
      return (JSON.parse ~origin:(string_of_path path ^ " response") output)
    in
    {value = process; run = parse}
end

let spawn_rpc ?log_command ?log_status_on_exit ?log_output ?better_errors
    ?endpoint ?hooks ?env ?data ?query_string meth path client =
  let*? res =
    Spawn.rpc
      ?log_command
      ?log_status_on_exit
      ?log_output
      ?better_errors
      ?endpoint
      ?hooks
      ?env
      ?data
      ?query_string
      meth
      path
      client
  in
  res

let rpc ?log_command ?log_status_on_exit ?log_output ?better_errors ?endpoint
    ?hooks ?env ?data ?query_string meth path client =
  let*! res =
    Spawn.rpc
      ?log_command
      ?log_status_on_exit
      ?log_output
      ?better_errors
      ?endpoint
      ?hooks
      ?env
      ?data
      ?query_string
      meth
      path
      client
  in
  return res

let spawn_rpc_stream ?log_command ?log_status_on_exit ?log_output ?better_errors
    ?endpoint ?hooks ?env ?data ?query_string meth path client =
  let*? res =
    Spawn.rpc
      ?log_command
      ?log_status_on_exit
      ?log_output
      ?better_errors
      ?endpoint
      ?hooks
      ?env
      ?data
      ?query_string
      meth
      path
      client
  in
  let line_stream = Lwt_io.read_lines (Process.stdout res) in
  let json_stream =
    Lwt_stream.map
      (fun line ->
        Format.eprintf "LINE: %s@." line ;
        JSON.parse ~origin:(string_of_path path ^ " response element") line)
      line_stream
  in
  (json_stream, res)

let rpc_stream ?log_command ?log_status_on_exit ?log_output ?better_errors
    ?endpoint ?hooks ?env ?data ?query_string meth path client
    (on_value : JSON.t -> [`Continue | `Stop] Lwt.t) =
  let stream, process =
    spawn_rpc_stream
      ?log_command
      ?log_status_on_exit
      ?log_output
      ?better_errors
      ?endpoint
      ?hooks
      ?env
      ?data
      ?query_string
      meth
      path
      client
  in
  let rec loop () =
    let* json_opt = Lwt_stream.get stream in
    match json_opt with
    | None ->
        (* Stream closes *)
        unit
    | Some json -> (
        let* res =
          Lwt.catch (fun () -> on_value json) (fun _ -> return `Stop)
        in
        match res with
        | `Stop ->
            Process.terminate process ;
            unit
        | `Continue -> loop ())
  in
  loop ()

let spawn_rpc_list ?endpoint client =
  spawn_command ?endpoint client ["rpc"; "list"]

let rpc_list ?endpoint client =
  spawn_rpc_list ?endpoint client |> Process.check_and_read_stdout
