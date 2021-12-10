(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2021 Marigold, <team@marigold.dev>                          *)
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

open Tezos_shell_services

let main_exit_callback exit_status =
  let open Lwt_syntax in
  let* () = Event.node_is_shutting_down ~exit_status in
  Internal_event_unix.close ()

let rec connect ?(delay = 3.0) cctxt =
  let open Lwt_syntax in
  let* res = Monitor_services.heads cctxt cctxt#chain in
  match res with
  | Ok (stream, stopper) -> Error_monad.return (stream, stopper)
  | Error _ ->
      let* () = Event.cannot_connect ~delay in
      let* () = Lwt_unix.sleep delay in
      connect ~delay cctxt

let rec run ~data_dir cctxt =
  let open Lwt_result_syntax in
  let* () = Event.starting_node () in
  let* configuration = Configuration.load ~data_dir in
  let Configuration.{rpc_addr; rpc_port; _} = configuration in
  let* _rpc_server = RPC.start configuration in

  let _ =
    (* Register cleaner callback *)
    Lwt_exit.register_clean_up_callback ~loc:__LOC__ main_exit_callback
  in
  let* () = Event.node_is_ready ~rpc_addr ~rpc_port in
  let* () =
    Lwt.catch
      (fun () ->
        let* (block_stream, stopper) = connect ~delay:2.0 cctxt in
        Lwt_stream.iter_s
          (fun (_hash, _header) ->
            stopper () ;
            Lwt.return ())
          block_stream
        >>= Event.connection_lost
        >>= fun () -> run ~data_dir cctxt)
      (fun _exn ->
        (* FIXME: proper error handling for trap exit
            Proper exit instead of propagating exception.
           (Every exception are wrapped into [ Lwt.Resolution_loop.Canceled]
           so discarding the exception seems not problematic at all.) *)
        return_unit)
  in
  Lwt_utils.never_ending ()
