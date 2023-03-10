(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Trili Tech, <contact@trili.tech>                       *)
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

type t = unit tzresult Lwt.t * Tezos_rpc__RPC_context.stopper

(** [make_stream_daemon handler streamed_call] calls [handler] on each newly
      received value from [streamed_call].

      It returns a couple [(p, stopper)] where [p] is a promise resolving when the
      stream closes and [stopper] a function closing the stream.
  *)
let make_stream_daemon handle streamed_call =
  let open Lwt_result_syntax in
  let* stream, stopper = streamed_call in
  let rec go () =
    let*! tok = Lwt_stream.get stream in
    match tok with
    | None -> return_unit
    | Some element ->
        let*! r = handle stopper element in
        let*! () =
          match r with
          | Ok () -> Lwt.return_unit
          | Error trace ->
              let*! () = Event.(emit daemon_error) trace in
              Lwt.return_unit
        in
        go ()
  in
  return (go (), stopper)

let resolve_plugin_and_set_ready ctxt =
  (* Monitor heads and try resolve the DAC protocol plugin corresponding to
     the protocol of the targeted node. *)
  (* FIXME: https://gitlab.com/tezos/tezos/-/issues/3605
     Handle situtation where plugin is not found *)
  let open Lwt_result_syntax in
  let cctxt = Node_context.get_tezos_node_cctxt ctxt in
  let handler stopper (_block_hash, (_block_header : Tezos_base.Block_header.t))
      =
    let* protocols =
      Tezos_shell_services.Chain_services.Blocks.protocols cctxt ()
    in
    let*! dac_plugin = Dac_manager.resolve_plugin protocols in
    match dac_plugin with
    | Some dac_plugin ->
        Node_context.set_ready ctxt dac_plugin ;
        let*! () = Event.(emit node_is_ready ()) in
        stopper () ;
        return_unit
    | None -> return_unit
  in
  let handler stopper el =
    match Node_context.get_status ctxt with
    | Starting -> handler stopper el
    | Ready _ -> return_unit
  in
  let*! () = Event.(emit layer1_node_tracking_started ()) in
  make_stream_daemon
    handler
    (Tezos_shell_services.Monitor_services.heads cctxt `Main)

let new_head ctxt =
  let cctxt = Node_context.get_tezos_node_cctxt ctxt in
  (* Monitor heads and store published slot headers indexed by block hash. *)
  let open Lwt_result_syntax in
  let handler _stopper (block_hash, (header : Tezos_base.Block_header.t)) =
    match Node_context.get_status ctxt with
    | Starting -> return_unit
    | Ready _ ->
        let block_level = header.shell.level in
        let*! () =
          Event.(emit layer1_node_new_head (block_hash, block_level))
        in
        return_unit
  in
  let*! () = Event.(emit layer1_node_tracking_started ()) in
  (* FIXME: https://gitlab.com/tezos/tezos/-/issues/3517
      If the layer1 node reboots, the rpc stream breaks.*)
  make_stream_daemon
    handler
    (Tezos_shell_services.Monitor_services.heads cctxt `Main)

(** This handler will be invoked only when a [coordinator_cctxt] is specified
      in the DAC node configuration. The DAC node tries to subscribes to the
      stream of root hashes via the streamed GET /monitor/root_hashes RPC call
      to the dac node corresponding to [coordinator_cctxt]. *)
let new_root_hash ctxt coordinator_cctxt =
  let open Lwt_result_syntax in
  let handler dac_plugin remote_store _stopper root_hash =
    let*! () = Event.emit_new_root_hash_received dac_plugin root_hash in
    let*! payload_result =
      Pages_encoding.Merkle_tree.V0.Remote.deserialize_payload
        dac_plugin
        ~page_store:remote_store
        root_hash
    in
    match payload_result with
    | Ok _ ->
        let*! () =
          Event.emit_received_root_hash_processed dac_plugin root_hash
        in
        return ()
    | Error errs ->
        (* TODO: https://gitlab.com/tezos/tezos/-/issues/4930.
           Improve handling of errors. *)
        let*! () =
          Event.emit_processing_root_hash_failed dac_plugin root_hash errs
        in
        return ()
  in
  let*? dac_plugin = Node_context.get_dac_plugin ctxt in
  let remote_store =
    Page_store.(
      Remote.init
        {
          cctxt = coordinator_cctxt;
          page_store = Node_context.get_page_store ctxt;
        })
  in
  let*! () = Event.(emit subscribed_to_root_hashes_stream ()) in
  make_stream_daemon
    (handler dac_plugin remote_store)
    (Monitor_services.root_hashes coordinator_cctxt dac_plugin)

let handlers (Node_context.Ex ctxt as node_ctxt) =
  match Node_context.mode ctxt with
  | Node_context.Modal.Coordinator _ -> [new_head node_ctxt]
  | Node_context.Modal.Committee_member ctxt ->
      let coordinator_cctxt =
        Node_context.Committee_member.coordinator_cctxt ctxt
      in
      [new_head node_ctxt; new_root_hash node_ctxt coordinator_cctxt]
  | Node_context.Modal.Observer ctxt ->
      let coordinator_cctxt = Node_context.Observer.coordinator_cctxt ctxt in
      [new_head node_ctxt; new_root_hash node_ctxt coordinator_cctxt]
  | Node_context.Modal.Legacy ctxt ->
      let coordinator_cctxt_opt = Node_context.Legacy.coordinator_cctxt ctxt in
      let root_hash_handler =
        coordinator_cctxt_opt
        |> Option.map (fun coordinator_cctxt ->
               new_root_hash node_ctxt coordinator_cctxt)
        |> Option.to_list
      in
      [new_head node_ctxt] @ root_hash_handler
