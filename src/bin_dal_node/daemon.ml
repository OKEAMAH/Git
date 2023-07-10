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

(** [resolve_plugin protocols] tries to load [Dal_plugin.T] for either
    [protocols.current_protocol], if it is equal to [protocols.next_protocol],
    or [protocols.next_protocol] otherwise.
    It is an error to use the plugin of [next_protocol] to track a block in
    [current_protocol] when these are distinct. To avoid this error,
    the wrapping polymorphic variant allows to decide whether we should start
    to track the current block or the wait until the next one.  *)
let resolve_plugin
    (protocols : Tezos_shell_services.Chain_services.Blocks.protocols) :
    [ `Current of (module Dal_plugin.T)
    | `Next of (module Dal_plugin.T)
    | `No_plugin ]
    Lwt.t =
  let open Lwt_syntax in
  let* () = Event.(emit resolving_dal_plugin) protocols.next_protocol in
  let plugin_opt =
    if Protocol_hash.equal protocols.current_protocol protocols.next_protocol
    then
      Dal_plugin.get protocols.current_protocol
      |> Option.map (fun plugin -> `Current plugin)
    else
      Dal_plugin.get protocols.next_protocol
      |> Option.map (fun plugin -> `Next plugin)
  in
  match plugin_opt with
  | None ->
      let* () = Event.(emit no_protocol_plugin ()) in
      return `No_plugin
  | Some ((`Current dal_plugin | `Next dal_plugin) as arg) ->
      let (module Dal_plugin : Dal_plugin.T) = dal_plugin in
      let* () = Event.(emit protocol_plugin_resolved) Dal_plugin.Proto.hash in
      return arg

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

let fetch_dal_config cctxt =
  let open Lwt_syntax in
  let* r = Config_services.dal_config cctxt in
  match r with
  | Error e -> return_error e
  | Ok dal_config -> return_ok dal_config

let init_cryptobox dal_config (proto_parameters : Dal_plugin.proto_parameters) =
  let open Lwt_result_syntax in
  let* () =
    let find_srs_files () = Tezos_base.Dal_srs.find_trusted_setup_files () in
    Cryptobox.Config.init_dal ~find_srs_files dal_config
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

  (* [gossipsub_app_messages_validation cryptobox message message_id] allows
     checking whether the given [message] identified by [message_id] is valid
     with the current [cryptobox] parameters. The validity check is done by
     verifying that the shard in the message effectively belongs to the
     commitment given by [message_id]. *)
  let gossipsub_app_messages_validation cryptobox message message_id =
    let open Gossipsub in
    let {share; shard_proof} = message in
    let {commitment; shard_index; _} = message_id in
    let shard = Cryptobox.{share; index = shard_index} in
    match Cryptobox.verify_shard cryptobox commitment shard shard_proof with
    | Ok () -> `Valid
    | Error err ->
        let err =
          match err with
          | `Invalid_degree_strictly_less_than_expected {given; expected} ->
              Format.sprintf
                "Invalid_degree_strictly_less_than_expected. Given: %d, \
                 expected: %d"
                given
                expected
          | `Invalid_shard -> "Invalid_shard"
          | `Shard_index_out_of_range s ->
              Format.sprintf "Shard_index_out_of_range(%s)" s
          | `Shard_length_mismatch -> "Shard_length_mismatch"
        in
        Event.(
          emit__dont_wait__use_with_care
            message_validation_error
            (message_id, err)) ;
        `Invalid
    | exception exn ->
        (* Don't crash if crypto raised an exception. *)
        let err = Printexc.to_string exn in
        Event.(
          emit__dont_wait__use_with_care
            message_validation_error
            (message_id, err)) ;
        `Invalid

  let resolve_plugin_and_set_ready config dal_config ctxt cctxt =
    (* Monitor heads and try resolve the DAL protocol plugin corresponding to
       the protocol of the targeted node. *)
    let open Lwt_result_syntax in
    let handler stopper (block_hash, (block_header : Tezos_base.Block_header.t))
        =
      let block = `Hash (block_hash, 0) in
      let* protocols =
        Tezos_shell_services.Chain_services.Blocks.protocols
          cctxt
          ~block:(`Hash (block_hash, 0))
          ()
      in
      let*! resolved_plugin = resolve_plugin protocols in
      match resolved_plugin with
      | (`Current plugin | `Next plugin) as resolved ->
          let plugin_activation_level =
            match resolved with
            | `Current _ -> block_header.shell.level
            | `Next _ -> Int32.succ block_header.shell.level
          in
          let (module Dal_plugin : Dal_plugin.T) = plugin in
          let* proto_parameters = Dal_plugin.get_constants `Main block cctxt in
          let* cryptobox = init_cryptobox dal_config proto_parameters in
          let* () =
            let+ pctxt =
              List.fold_left_es
                (fun profile_ctxt profile ->
                  Profile_manager.add_profile
                    profile_ctxt
                    proto_parameters
                    (Node_context.get_store ctxt)
                    (Node_context.get_gs_worker ctxt)
                    profile)
                (Node_context.get_profile_ctxt ctxt)
                config.Configuration_file.profiles
            in
            Node_context.set_profile_ctxt ctxt pctxt
          in
          Node_context.set_ready
            ctxt
            plugin
            cryptobox
            proto_parameters
            plugin_activation_level
            block_header.shell.proto_level ;
          (* FIXME: https://gitlab.com/tezos/tezos/-/issues/4441

             The hook below should be called each time cryptobox parameters
             change. *)
          Gossipsub.Worker.Validate_message_hook.set
            (gossipsub_app_messages_validation cryptobox) ;
          let*! () = Event.(emit node_is_ready ()) in
          stopper () ;
          return_unit
      | `No_plugin ->
          (* FIXME: https://gitlab.com/tezos/tezos/-/issues/3605
             Handle situtation where plugin is not found *)
          return_unit
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

  let update_plugin cctxt ctxt current_plugin ~block ~current_proto ~block_proto
      =
    let open Lwt_result_syntax in
    if current_proto <> block_proto then
      let* protocols =
        Tezos_shell_services.Chain_services.Blocks.protocols cctxt ~block ()
      in
      let*! resolved_plugin = resolve_plugin protocols in
      match resolved_plugin with
      | `Next plugin ->
          Node_context.update_plugin_in_ready ctxt plugin block_proto ;
          return (Some plugin)
      | `Current _ ->
          (* We are expecting a protocol change. If we're in this case, there's no
             protocol change. *)
          let*! () = Event.(emit unexpected_protocol_plugin ()) in
          return None
      | `No_plugin ->
          (* An event is emitted by [resolve_plugin]. *)
          return None
    else return (Some current_plugin)

  let new_head ctxt cctxt =
    (* Monitor heads and store published slot headers indexed by block hash. *)
    let open Lwt_result_syntax in
    let handler _stopper (block_hash, (header : Tezos_base.Block_header.t)) =
      match Node_context.get_status ctxt with
      | Starting -> return_unit
      | Ready
          {
            plugin = current_plugin;
            proto_parameters;
            cryptobox;
            shards_proofs_precomputation = _;
            activation_level;
            proto_level;
          } -> (
          let block = `Hash (block_hash, 0) in
          let block_level = header.shell.level in
          if Compare.Int32.(block_level < activation_level) then return_unit
          else
            let* plugin_opt =
              update_plugin
                cctxt
                ctxt
                current_plugin
                ~block
                ~current_proto:proto_level
                ~block_proto:header.shell.proto_level
            in
            match plugin_opt with
            | None -> return_unit
            | Some plugin ->
                let (module Plugin) = plugin in
                let* block_info =
                  Plugin.block_info cctxt ~block ~metadata:`Always
                in
                let* slot_headers =
                  Plugin.get_published_slot_headers block_info
                in
                let* () =
                  Slot_manager.store_slot_headers
                    ~block_level
                    ~block_hash
                    slot_headers
                    (Node_context.get_store ctxt)
                in
                let* () =
                  (* If a slot header was posted to the L1 and we have the corresponding
                     data, post it to gossipsub.

                     FIXME: https://gitlab.com/tezos/tezos/-/issues/5973
                     Should we restrict published slot data to the slots for which
                     we have the producer role?
                  *)
                  List.iter_es
                    (fun (slot_header, status) ->
                      match status with
                      | Dal_plugin.Succeeded ->
                          let Dal_plugin.
                                {slot_index; commitment; published_level} =
                            slot_header
                          in
                          Slot_manager.publish_slot_data
                            ~level_committee:(Node_context.fetch_committee ctxt)
                            (Node_context.get_store ctxt)
                            (Node_context.get_gs_worker ctxt)
                            cryptobox
                            proto_parameters
                            commitment
                            published_level
                            slot_index
                      | Dal_plugin.Failed -> return_unit)
                    slot_headers
                in
                let*? attested_slots =
                  Plugin.attested_slot_headers
                    block_hash
                    block_info
                    ~number_of_slots:proto_parameters.number_of_slots
                in
                let*! () =
                  Slot_manager.update_selected_slot_headers_statuses
                    ~block_level
                    ~attestation_lag:proto_parameters.attestation_lag
                    ~number_of_slots:proto_parameters.number_of_slots
                    attested_slots
                    (Node_context.get_store ctxt)
                in
                let* committee =
                  Node_context.fetch_committee ctxt ~level:block_level
                in
                let () =
                  Profile_manager.on_new_head
                    (Node_context.get_profile_ctxt ctxt)
                    (Node_context.get_gs_worker ctxt)
                    committee
                in
                let*! () =
                  Event.(emit layer1_node_new_head (block_hash, block_level))
                in
                return_unit)
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
          (Node_context.get_store ctxt)
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
          (RPC_server.monitor_shards_rpc n_cctxt))
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

let connect_gossipsub_with_p2p gs_worker transport_layer node_store =
  let open Gossipsub in
  let shards_handler ({shard_store; shards_watcher; _} : Store.node_store) =
    let save_and_notify =
      Store.Shards.save_and_notify shard_store shards_watcher
    in
    fun ({share; _} : message) ({commitment; shard_index; _} : message_id) ->
      Seq.return {Cryptobox.share; index = shard_index}
      |> save_and_notify commitment |> Errors.to_tzresult
  in
  Lwt.dont_wait
    (fun () ->
      Transport_layer_hooks.activate
        gs_worker
        transport_layer
        ~app_messages_callback:(shards_handler node_store))
    (fun exn ->
      "[dal_node] error in Daemon.connect_gossipsub_with_p2p: "
      ^ Printexc.to_string exn
      |> Stdlib.failwith)

let resolve peers =
  List.concat_map_es
    (Tezos_base_unix.P2p_resolve.resolve_addr
       ~default_addr:"::"
       ~default_port:(Configuration_file.default.listen_addr |> snd))
    peers

(* FIXME: https://gitlab.com/tezos/tezos/-/issues/3605
   Improve general architecture, handle L1 disconnection etc
*)
let run ~data_dir configuration_override =
  let open Lwt_result_syntax in
  let log_cfg = Tezos_base_unix.Logs_simple_config.default_cfg in
  let internal_events =
    Tezos_base_unix.Internal_event_unix.make_with_defaults
      ~enable_default_daily_logs_at:Filename.Infix.(data_dir // "daily_logs")
      ~log_cfg
      ()
  in
  let*! () =
    Tezos_base_unix.Internal_event_unix.init ~config:internal_events ()
  in
  let*! () = Event.(emit starting_node) () in
  let* ({network_name; rpc_addr; peers; endpoint; _} as config) =
    let*! result = Configuration_file.load ~data_dir in
    match result with
    | Ok configuration -> return (configuration_override configuration)
    | Error _ ->
        let*! () = Event.(emit data_dir_not_found data_dir) in
        (* Store the default configuration if no configuration were found. *)
        let configuration = configuration_override Configuration_file.default in
        let* () = Configuration_file.save configuration in
        return configuration
  in
  let*! () = Event.(emit configuration_loaded) () in
  (* Create and start a GS worker *)
  let gs_worker =
    let rng =
      let seed =
        Random.self_init () ;
        Random.bits ()
      in
      Random.State.make [|seed|]
    in
    let open Worker_parameters in
    Gossipsub.Worker.(
      make ~events_logging:Logging.event rng limits peer_filter_parameters
      |> start [])
  in
  (* Create a transport (P2P) layer instance. *)
  let* transport_layer =
    let open Transport_layer_parameters in
    let* p2p_config = p2p_config config in
    Gossipsub.Transport_layer.create p2p_config p2p_limits ~network_name
  in
  let* store = Store.init config in
  let cctxt = Rpc_context.make endpoint in
  let*! metrics_server = Metrics.launch config.metrics_addr in
  let ctxt =
    Node_context.init
      config
      store
      gs_worker
      transport_layer
      cctxt
      metrics_server
  in
  let* rpc_server = RPC_server.(start config ctxt) in
  connect_gossipsub_with_p2p gs_worker transport_layer store ;
  let* dal_config = fetch_dal_config cctxt in
  (* Resolve:
     - [peers] from DAL node config file and CLI.
     - [dal_config.bootstrap_peers] from the L1 network config. *)
  let* points = resolve (peers @ dal_config.bootstrap_peers) in
  (* activate the p2p instance. *)
  let*! () =
    Gossipsub.Transport_layer.activate ~additional_points:points transport_layer
  in
  let _ = RPC_server.install_finalizer rpc_server in
  let*! () = Event.(emit rpc_server_is_ready rpc_addr) in
  (* Start daemon to resolve current protocol plugin *)
  let* () =
    daemonize
      [Handler.resolve_plugin_and_set_ready config dal_config ctxt cctxt]
  in
  (* Start never-ending monitoring daemons *)
  daemonize (Handler.new_head ctxt cctxt :: Handler.new_slot_header ctxt)
