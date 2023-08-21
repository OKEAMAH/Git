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
    http_port : int;
    directory : string;
    mutable pending_ready : unit option Lwt.u list;
  }

  type session_state = {mutable ready : bool}

  let base_default_name = "simple-http"

  let default_colors = Log.Color.[|FG.bright_white; FG.gray|]
end

open Parameters
include Daemon.Make (Parameters)

let port http = http.persistent_state.http_port

let wait http =
  match http.status with
  | Not_running ->
      Test.fail "%s is not running, cannot wait for it to terminate" (name http)
  | Running {process; _} -> Process.wait process

let wait_for_promise ?timeout ?where agent name promise =
  let promise = Lwt.map Result.ok promise in
  let* result =
    match timeout with
    | None -> promise
    | Some timeout ->
        Lwt.pick
          [
            promise;
            (let* () = Lwt_unix.sleep timeout in
             Lwt.return_error ());
          ]
  in
  match result with
  | Ok (Some x) -> return x
  | Ok None ->
      raise (Terminated_before_event {daemon = agent.name; event = name; where})
  | Error () ->
      Format.ksprintf
        failwith
        "Timeout waiting for event %s of %s"
        name
        agent.name

let trigger_ready agent value =
  let pending = agent.persistent_state.pending_ready in
  agent.persistent_state.pending_ready <- [] ;
  List.iter (fun pending -> Lwt.wakeup_later pending value) pending

let set_ready agent =
  (match agent.status with
  | Not_running -> ()
  | Running status -> status.session_state.ready <- true) ;
  trigger_ready agent (Some ())

let handle_raw_stderr http line =
  if line =~ rex {|^Server HTTP on .* port .*|} then set_ready http

let create ?runner ?name ?python_path ?color ?event_pipe ?port ~directory () =
  let path = Option.value ~default:"python" python_path in
  let port = match port with Some port -> port | None -> Port.fresh () in
  let http =
    create
      ~path
      ?name
      ?runner
      ?color
      ?event_pipe
      {runner; pending_ready = []; http_port = port; directory}
  in
  on_stderr http (handle_raw_stderr http) ;
  http

let run ?event_level ?event_sections_levels http =
  if http.status <> Not_running then
    Test.fail "HTTP server %s is already running" http.name ;

  let* () = Helpers.exec ~can_fail:true "pkill" ["-9"; "python"] in

  run
    ?runner:http.persistent_state.runner
    ?event_level
    ?event_sections_levels
    ~capture_stderr:true
    http
    {ready = false}
    [
      "-m";
      "http.server";
      "--bind";
      "::";
      "-d";
      http.persistent_state.directory;
      string_of_int http.persistent_state.http_port;
    ]

let wait_for_ready http =
  match http.status with
  | Running {session_state = {ready = true; _}; _} -> unit
  | Not_running | Running {session_state = {ready = false; _}; _} ->
      let promise, resolver = Lwt.task () in
      http.persistent_state.pending_ready <-
        resolver :: http.persistent_state.pending_ready ;
      wait_for_promise http "HTTP server is ready" promise

let kill http =
  match http.status with
  | Not_running -> Test.fail "%s is not running, cannot kill it" (name http)
  | Running {process; _} -> Process.kill process
