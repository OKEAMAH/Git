(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs. <contact@nomadic-labs.com>               *)
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

open Parameters

module Events = struct
  include Internal_event.Simple

  let section = ["octez_rpc_server"]

  let daemon_error =
    declare_1
      ~section
      ~name:"octez_rpc_server_daemon_error"
      ~msg:"Daemon thrown an error: {error}"
      ~level:Notice
      ~pp1:Error_monad.pp_print_trace
      ("error", Error_monad.trace_encoding)

  let new_head =
    declare_1
      ~section
      ~name:"new_head"
      ~msg:"New head received ({level})"
      ~level:Notice
      ("level", Data_encoding.int32)

  let synchronized =
    declare_1
      ~section
      ~name:"synchronized"
      ~msg:"Store synchronized up to level {level}"
      ~level:Notice
      ("level", Data_encoding.int32)
end

module Daemon = struct
  (** [make_stream_daemon ~on_head ~head_stream] calls [on_head] on
      each newly received value from [head_stream].

      It returns a couple [(p, stopper)] where [p] is a promise
      resolving when the stream closes and [stopper] a function
      closing the stream. *)
  let make_stream_daemon ~on_head ~head_stream =
    let open Lwt_result_syntax in
    let* head_stream, stopper = head_stream in
    let rec go () =
      let*! tok = Lwt.choose [Lwt_stream.get head_stream] in
      match tok with
      | None -> return_unit
      | Some element ->
          let*! r = on_head stopper element in
          let*! () =
            match r with
            | Ok () -> Lwt.return_unit
            | Error trace ->
                let*! () = Events.(emit daemon_error) trace in
                Lwt.return_unit
          in
          go ()
    in
    return (go ())
end

let handle_new_head _dynamic_store _parameters _stopper
    (_block_hash, (header : Tezos_base.Block_header.t)) =
  let open Lwt_result_syntax in
  let*! () = Events.(emit new_head) header.shell.level in
  (* TODO: Synchronize the store *)
  return_unit

let init dynamic_store parameters =
  let ctx =
    Forward_handler.build_socket_redirection_ctx parameters.rpc_comm_socket_path
  in
  let module CustomRetryClient = struct
    include RPC_client_unix.RetryClient

    let call ?ctx:_ = call ~ctx
  end in
  let module Custom_rpc_client =
    RPC_client.Make (Resto_cohttp_client.Client.OfCohttp (CustomRetryClient)) in
  let rpc_config =
    Custom_rpc_client.
      {
        media_type = Media_type.Command_line.Any;
        endpoint = Uri.of_string Forward_handler.socket_forwarding_uri;
        logger = null_logger;
      }
  in
  let rpc_ctxt =
    new Custom_rpc_client.http_ctxt
      rpc_config
      (Media_type.Command_line.of_command_line rpc_config.media_type)
  in
  Daemon.make_stream_daemon
    ~on_head:(handle_new_head dynamic_store parameters)
    ~head_stream:(Tezos_shell_services.Monitor_services.heads rpc_ctxt `Main)
