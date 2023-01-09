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

let resolve_dal_plugin
    (protocols : Tezos_shell_services.Chain_services.Blocks.protocols) =
  let open Lwt_result_syntax in
  return
  @@ Option.either
       (Dal_plugin.get protocols.current_protocol)
       (Dal_plugin.get protocols.next_protocol)

type error +=
  | Cryptobox_initialisation_failed of string
  | Reveal_data_path_not_a_directory of string
  | Cannot_create_reveal_data_dir of string

let () =
  register_error_kind
    `Permanent
    ~id:"dal.node.cryptobox.initialisation_failed"
    ~title:"Cryptobox initialisation failed"
    ~description:"Unable to initialise the cryptobox parameters"
    ~pp:(fun ppf msg ->
      Format.fprintf
        ppf
        "Unable to initialise the cryptobox parameters. Reason: %s"
        msg)
    Data_encoding.(obj1 (req "error" string))
    (function Cryptobox_initialisation_failed str -> Some str | _ -> None)
    (fun str -> Cryptobox_initialisation_failed str)

let init_cryptobox unsafe_srs (proto_parameters : Dal_plugin.proto_parameters) =
  let open Cryptobox in
  let open Lwt_result_syntax in
  let srs_size =
    if unsafe_srs then Some proto_parameters.cryptobox_parameters.slot_size
    else None
  in
  let* () =
    let find_srs_files () = Tezos_base.Dal_srs.find_trusted_setup_files () in
    Cryptobox.Config.init_dal
      ~find_srs_files
      Cryptobox.Config.{activated = true; srs_size}
  in
  match Cryptobox.make proto_parameters.cryptobox_parameters with
  | Ok cryptobox -> return cryptobox
  | Error (`Fail msg) -> fail [Cryptobox_initialisation_failed msg]

module Handler = struct
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

  let resolve_plugins_and_set_ready config ctxt cctxt =
    (* Monitor heads and try resolve the DAL protocol plugin corresponding to
       the protocol of the targeted node. *)
    (* FIXME: https://gitlab.com/tezos/tezos/-/issues/3605
       Handle situtation where plugin is not found *)
    let open Lwt_result_syntax in
    let handler stopper
        (_block_hash, (_block_header : Tezos_base.Block_header.t)) =
      let* protocols =
        Tezos_shell_services.Chain_services.Blocks.protocols cctxt ()
      in
      let* dal_plugin = resolve_dal_plugin protocols in
      let* dac_plugin = Dac_manager.resolve_plugin protocols in
      match (dal_plugin, dac_plugin) with
      | Some dal_plugin, Some dac_plugin ->
          let (module Dal_plugin : Dal_plugin.T) = dal_plugin in
          let*! () =
            Event.emit_protocol_plugin_resolved Dal_plugin.Proto.hash
          in
          let* proto_parameters =
            Dal_plugin.get_constants cctxt#chain cctxt#block cctxt
          in
          let* cryptobox =
            init_cryptobox config.Configuration.use_unsafe_srs proto_parameters
          in
          Node_context.set_ready
            ctxt
            ~dal_plugin:(module Dal_plugin)
            ~dac_plugin
            cryptobox
            proto_parameters ;
          let*! () = Event.(emit node_is_ready ()) in
          stopper () ;
          return_unit
      | _, _ -> return_unit
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

  let new_head ctxt cctxt =
    (* Monitor heads and store published slot headers indexed by block hash. *)
    let open Lwt_result_syntax in
    let handler _stopper (block_hash, (header : Tezos_base.Block_header.t)) =
      match Node_context.get_status ctxt with
      | Starting -> return_unit
      | Ready {dal_plugin = (module Plugin); proto_parameters; _} ->
          let* block_info =
            Plugin.block_info
              cctxt
              ~block:(`Hash (block_hash, 0))
              ~metadata:`Always
          in
          let* slot_headers = Plugin.get_published_slot_headers block_info in
          let*! () =
            Slot_manager.store_slot_headers
              ~block_level:header.shell.level
              ~block_hash
              slot_headers
              (Node_context.get_store ctxt)
          in
          let*? attested_slots =
            Plugin.attested_slot_headers
              block_hash
              block_info
              ~number_of_slots:proto_parameters.number_of_slots
          in
          let*! () =
            Slot_manager.update_selected_slot_headers_statuses
              ~block_level:header.shell.level
              ~attestation_lag:proto_parameters.attestation_lag
              ~number_of_slots:proto_parameters.number_of_slots
              attested_slots
              (Node_context.get_store ctxt)
          in
          return_unit
    in
    let*! () = Event.(emit layer1_node_tracking_started ()) in
    (* FIXME: https://gitlab.com/tezos/tezos/-/issues/3517
        If the layer1 node reboots, the rpc stream breaks.*)
    make_stream_daemon
      handler
      (Tezos_shell_services.Monitor_services.heads cctxt `Main)

  let new_slot_header ctxt =
    (* Monitor neighbor DAL nodes and download published slots as shards. *)
    let open Lwt_result_syntax in
    let handler n_cctxt Node_context.{cryptobox; _} slot_header =
      let dal_parameters = Cryptobox.parameters cryptobox in
      let downloaded_shard_ids =
        0
        -- ((dal_parameters.number_of_shards / dal_parameters.redundancy_factor)
           - 1)
      in
      let* shards =
        RPC_server_legacy.shards_rpc n_cctxt slot_header downloaded_shard_ids
      in
      let shards = List.to_seq shards in
      let* () =
        Slot_manager.save_shards
          (Node_context.get_store ctxt).shard_store
          (Node_context.get_store ctxt).slots_watcher
          cryptobox
          slot_header
          shards
      in
      return_unit
    in
    let handler n_cctxt _stopper slot_header =
      match Node_context.get_status ctxt with
      | Starting -> return_unit
      | Ready ready_ctxt -> handler n_cctxt ready_ctxt slot_header
    in
    List.map
      (fun n_cctxt ->
        make_stream_daemon
          (handler n_cctxt)
          (RPC_server_legacy.monitor_slot_headers_rpc n_cctxt))
      (Node_context.get_neighbors_cctxts ctxt)
end

let daemonize handlers =
  (* FIXME: https://gitlab.com/tezos/tezos/-/issues/3605
     Improve concurrent tasks by using workers *)
  let open Lwt_result_syntax in
  let* handlers = List.map_es (fun x -> x) handlers in
  let (_ : Lwt_exit.clean_up_callback_id) =
    (* close the stream when an exit signal is received *)
    Lwt_exit.register_clean_up_callback ~loc:__LOC__ (fun _exit_status ->
        List.iter (fun (_, stopper) -> stopper ()) handlers ;
        Lwt.return_unit)
  in
  (let* _ = all (List.map fst handlers) in
   return_unit)
  |> lwt_map_error (List.fold_left (fun acc errs -> errs @ acc) [])

(* FIXME: https://gitlab.com/tezos/tezos/-/issues/3605
   Improve general architecture, handle L1 disconnection etc
*)
let run ~data_dir cctxt =
  let open Lwt_result_syntax in
  let*! () = Event.(emit starting_node) () in
  let* config = Configuration.load ~data_dir in
  let config = {config with data_dir} in
  let* () =
    Dac_manager.Storage.ensure_reveal_data_dir_exists config.dac.reveal_data_dir
  in
  let* dac_accounts = Dac_manager.Keys.get_keys cctxt config in
  let dac_pks_opt, dac_sk_uris =
    dac_accounts
    |> List.map (fun account_opt ->
           match account_opt with
           | None -> (None, None)
           | Some (_pkh, pk_opt, sk_uri) -> (pk_opt, Some sk_uri))
    |> List.split
  in
  let* store = Store.init config in
  let ctxt = Node_context.init config store in

  let* rpc_server =
    RPC_server.(start config cctxt ctxt dac_pks_opt dac_sk_uris)
  in
  let _ = RPC_server.install_finalizer rpc_server in
  let*! () =
    Event.(emit rpc_server_is_ready (config.rpc_addr, config.rpc_port))
  in
  (* Start daemon to resolve current protocol plugin *)
  let* () =
    daemonize [Handler.resolve_plugins_and_set_ready config ctxt cctxt]
  in
  (* Start never-ending monitoring daemons *)
  daemonize (Handler.new_head ctxt cctxt :: Handler.new_slot_header ctxt)
