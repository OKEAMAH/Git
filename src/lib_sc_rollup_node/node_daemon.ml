(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Functori, <contact@functori.com>                       *)
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

module type PROTO_CONTEXT = sig
  module Daemon : Protocol_daemon_sig.S

  val node_ctxt : Daemon.Node_context.rw
end

type state = {
  data_dir : string;
  log_kernel_debug_file : string option;
  cctxt : Client_context.full;
  l1 : Layer_1.t;
  configuration : Configuration.t;
  mutable protocol : Protocol_hash.t;
  mutable proto_level : int;
  mutable proto_ctxt : (module PROTO_CONTEXT);
  mutable rpc_server : Tezos_rpc_http_server.RPC_server.server;
}

module Layer1 = struct
  module Blocks_cache =
    Aches_lwt.Lache.Make_option
      (Aches.Rache.Transfer (Aches.Rache.LRU) (Block_hash))

  type headers_cache = Block_header.shell_header Blocks_cache.t

  (** Global block headers cache for the smart rollup node. *)
  let headers_cache : headers_cache = Blocks_cache.create 32

  include Octez_crawler.Layer_1

  let cache_shell_header hash header =
    Blocks_cache.put headers_cache hash (Lwt.return_some header)

  let iter_heads l1_ctxt f =
    iter_heads l1_ctxt @@ fun (hash, {shell; _}) ->
    cache_shell_header hash shell ;
    f (hash, shell)

  let first l1_ctxt =
    let open Lwt_option_syntax in
    let+ hash, {shell; _} = first l1_ctxt in
    cache_shell_header hash shell ;
    (hash, shell)

  let get_predecessor state (hash, level) =
    let open Lwt_result_syntax in
    let open (val state.proto_ctxt) in
    let open Daemon in
    let* pred = Node_context.get_l2_predecessor node_ctxt hash in
    match pred with
    | Some p -> return p
    | None ->
        (* [head] is not already known in the L2 chain *)
        get_predecessor state.l1 (hash, level)

  let get_tezos_reorg_for_new_head state old_head new_head =
    let open Lwt_result_syntax in
    let get_reorg =
      get_tezos_reorg_for_new_head
        state.l1
        ~get_old_predecessor:(get_predecessor state)
    in
    let*! reorg = get_reorg old_head new_head in
    match reorg with
    | Error trace
      when TzTrace.fold
             (fun yes error ->
               yes
               ||
               match error with
               | Octez_crawler.Layer_1.Cannot_find_predecessor _ -> true
               | _ -> false)
             false
             trace ->
        (* The reorganization could not be computed entirely because of missing
           info on the Layer 1. We fallback to just the new chain as there is no
           real treatment for rolledback blocks so far. *)
        let old_head =
          match old_head with `Head (_, l) | `Level l -> `Level l
        in
        get_reorg old_head new_head
    | reorg -> Lwt.return reorg

  (** [fetch_tezos_shell_header cctxt hash] returns a block shell header of
      [hash]. Looks for the block in the blocks cache first, and fetches it from
      the L1 node otherwise. *)
  let fetch_tezos_shell_header cctxt hash =
    let open Lwt_syntax in
    let errors = ref None in
    let fetch hash =
      let* shell_header =
        Tezos_shell_services.Shell_services.Blocks.Header.shell_header
          cctxt
          ~chain:`Main
          ~block:(`Hash (hash, 0))
          ()
      in
      match shell_header with
      | Error errs ->
          errors := Some errs ;
          return_none
      | Ok shell_header -> return_some shell_header
    in
    let+ shell_header =
      Blocks_cache.bind_or_put headers_cache hash fetch Lwt.return
    in
    match (shell_header, !errors) with
    | None, None ->
        (* This should not happen if {!find_in_cache} behaves correctly,
           i.e. calls {!fetch} for cache misses. *)
        error_with
          "Fetching Tezos block %a failed unexpectedly"
          Block_hash.pp
          hash
    | None, Some errs -> Error errs
    | Some shell_header, _ -> Ok shell_header
end

let stop_daemon state =
  let open Lwt_result_syntax in
  let open (val state.proto_ctxt) in
  let*! () = Tezos_rpc_http_server.RPC_server.shutdown state.rpc_server in
  let* () = Daemon.stop_workers node_ctxt in
  let* () = Daemon.Node_context.close node_ctxt in
  return_unit

let initial_state_of_head ~data_dir ?log_kernel_debug_file cctxt l1
    configuration (hash, header) =
  let open Lwt_result_syntax in
  let* {current_protocol; _} =
    Tezos_shell_services.Shell_services.Blocks.protocols
      cctxt
      ~chain:cctxt#chain
      ~block:(`Hash (hash, 0))
      ()
  in
  let*? proto_daemon =
    Protocol_daemons.proto_daemon_for_protocol current_protocol
  in
  let module Current_proto_daemon = (val proto_daemon) in
  let* node_ctxt =
    Current_proto_daemon.Node_context.init
      cctxt
      ~head:hash
      ~data_dir
      ?log_kernel_debug_file
      Read_write
      configuration
  in
  let* () = Current_proto_daemon.start_workers configuration node_ctxt in
  let rpc_server =
    Current_proto_daemon.RPC_server.init configuration node_ctxt
  in
  let*! () =
    let open Tezos_rpc_http_server in
    let Configuration.{rpc_addr; rpc_port; _} = configuration in
    let rpc_addr = P2p_addr.of_string_exn rpc_addr in
    let host = Ipaddr.V6.to_string rpc_addr in
    let node = `TCP (`Port rpc_port) in
    RPC_server.launch
      ~host
      rpc_server
      ~callback:(RPC_server.resto_callback rpc_server)
      node
  in
  let proto_level = header.Block_header.proto_level in
  let module Proto_context = struct
    module Daemon = Current_proto_daemon

    let node_ctxt = node_ctxt
  end in
  return
    {
      data_dir;
      log_kernel_debug_file;
      cctxt = (cctxt :> Client_context.full);
      l1;
      configuration;
      protocol = current_protocol;
      proto_level;
      proto_ctxt = (module Proto_context);
      rpc_server;
    }

let protocol_migration
    ({data_dir; log_kernel_debug_file; cctxt; l1; configuration; _} as state)
    (hash, header) =
  let open Lwt_result_syntax in
  (* Stop the daemon for the previous protocol *)
  let* () = stop_daemon state in
  Format.eprintf
    "Migrating from %d to %d@."
    state.proto_level
    header.Block_header.proto_level ;
  (* And start the one for the current protocol *)
  let* new_state =
    initial_state_of_head
      ~data_dir
      ?log_kernel_debug_file
      cctxt
      l1
      configuration
      (hash, header)
  in
  state.protocol <- new_state.protocol ;
  state.proto_level <- new_state.proto_level ;
  state.rpc_server <- new_state.rpc_server ;
  state.proto_ctxt <- new_state.proto_ctxt ;
  return_unit

let process_head state ((_hash, header) as head) =
  let open Lwt_result_syntax in
  let* () =
    when_ (state.proto_level <> header.Block_header.proto_level) @@ fun () ->
    protocol_migration state head
  in
  let open (val state.proto_ctxt) in
  Daemon.process_block node_ctxt head

let on_layer_1_head state ((hash, header) as head) =
  let open Lwt_result_syntax in
  let open (val state.proto_ctxt) in
  let* old_head = Daemon.Node_context.last_processed_block node_ctxt in
  let old_head =
    match old_head with
    | Some (hash, level) -> `Head (hash, level)
    | None ->
        (* if no head has been processed yet, we want to handle all blocks
           since, and including, the rollup origination. *)
        let origination_level =
          Daemon.Node_context.origination_level node_ctxt
        in
        `Level (Int32.pred origination_level)
  in
  let stripped_head = (hash, header.Block_header.level) in
  let* reorg =
    Layer1.get_tezos_reorg_for_new_head state old_head stripped_head
  in
  let get_header block_hash =
    if Block_hash.equal block_hash hash then return head
    else
      let+ header = Layer1.fetch_tezos_shell_header state.cctxt block_hash in
      (block_hash, header)
  in
  let*! () = Node_daemon_event.processing_heads_iteration reorg.new_chain in
  let* () =
    List.iter_es
      (fun (block, _level) ->
        let* header = get_header block in
        process_head state header)
      reorg.new_chain
  in
  let* () = Daemon.on_layer_1_head_extra node_ctxt head in
  let*! () = Node_daemon_event.new_heads_processed reorg.new_chain in
  return_unit

let daemonize state = Layer1.iter_heads state.l1 (on_layer_1_head state)

let degraded_mode_on_block state ((_hash, header) as head) =
  let open Lwt_result_syntax in
  let* () =
    when_ (state.proto_level <> header.Block_header.proto_level) @@ fun () ->
    protocol_migration state head
  in
  let open (val state.proto_ctxt) in
  Daemon.degraded_mode_on_block head

let degraded_refutation_mode state =
  let open Lwt_result_syntax in
  let open (val state.proto_ctxt) in
  let* () = Daemon.enter_degraded_mode node_ctxt in
  Layer1.iter_heads state.l1 (degraded_mode_on_block state)

let install_finalizer state =
  let open Lwt_syntax in
  Lwt_exit.register_clean_up_callback ~loc:__LOC__ @@ fun _exit_status ->
  let open (val state.proto_ctxt) in
  let message = state.cctxt#message in
  let* () = message "Shutting down RPC server@." in
  let* () = Tezos_rpc_http_server.RPC_server.shutdown state.rpc_server in
  let* () = message "Shutting down workers@." in
  let* (_ : unit tzresult) = Daemon.stop_workers node_ctxt in
  let* (_ : unit tzresult) = Daemon.Node_context.close node_ctxt in
  Tezos_base_unix.Internal_event_unix.close ()

let start_metrics_server (configuration : Configuration.t) =
  Lwt.dont_wait
    (fun () ->
      let open Lwt_syntax in
      let* r = Metrics.metrics_serve configuration.metrics_addr in
      match r with
      | Ok () -> Lwt.return_unit
      | Error err ->
          Node_events.(metrics_ended (Format.asprintf "%a" pp_print_trace err)))
    (fun exn -> Node_events.(metrics_ended_dont_wait (Printexc.to_string exn)))

let error_is_lost_game err =
  let has_suffix ~suffix s =
    let x = String.length suffix in
    let n = String.length s in
    n >= x && String.sub s (n - x) x = suffix
  in
  let err_id_str =
    let open Option_syntax in
    let err_json =
      Data_encoding.Json.construct Error_monad.error_encoding err
    in
    let* err_id = Ezjsonm.find_opt err_json ["id"] in
    Ezjsonm.decode_string err_id
  in
  match err_id_str with
  | None -> false
  | Some err_id_str -> has_suffix err_id_str ~suffix:"sc_rollup.node.lost_game"

let run ~data_dir ?log_kernel_debug_file (configuration : Configuration.t)
    (cctxt : #Client_context.full) =
  let open Lwt_result_syntax in
  Random.self_init () (* Initialize random state (for reconnection delays) *) ;
  let open Configuration in
  let* () =
    (* Check that the operators are valid keys. *)
    Operator_purpose_map.iter_es
      (fun _purpose operator ->
        let+ _pkh, _pk, _skh = Client_keys.get_key cctxt operator in
        ())
      configuration.sc_rollup_node_operators
  in
  let* l1 =
    Layer1.start
      ~name:"sc_rollup_node"
      ~reconnection_delay:configuration.reconnection_delay
      cctxt
  in
  let*! head = Layer1.first l1 in
  let*? head =
    match head with
    | None -> error_with "Could not obtain head from stream"
    | Some h -> ok h
  in
  let* state =
    initial_state_of_head
      ~data_dir
      ?log_kernel_debug_file
      cctxt
      l1
      configuration
      head
  in
  let (_ : Lwt_exit.clean_up_callback_id) = install_finalizer state in
  start_metrics_server configuration ;
  let*! () =
    Node_daemon_event.node_is_ready
      ~rpc_addr:configuration.rpc_addr
      ~rpc_port:configuration.rpc_port
  in
  protect ~on_error:(fun e ->
      if List.exists error_is_lost_game e then (
        Format.eprintf "%!%a@.Exiting.@." pp_print_trace e ;
        let*! _ = Lwt_exit.exit_and_wait 1 in
        return_unit)
      else
        let*! () = Node_daemon_event.error e in
        degraded_refutation_mode state)
  @@ fun () -> daemonize state
