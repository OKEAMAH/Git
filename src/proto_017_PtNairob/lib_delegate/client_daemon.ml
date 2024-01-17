(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2018 Dynamic Ledger Solutions, Inc. <contact@tezos.com>     *)
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

let rec retry (cctxt : #Protocol_client_context.full) ?max_delay ~delay ~factor
    ~tries f x =
  f x >>= function
  | Ok _ as r -> Lwt.return r
  | Error
      (RPC_client_errors.Request_failed {error = Connection_failed _; _} :: _)
    as err
    when tries > 0 -> (
      cctxt#message "Connection refused, retrying in %.2f seconds..." delay
      >>= fun () ->
      Lwt.pick
        [
          (Lwt_unix.sleep delay >|= fun () -> `Continue);
          (Lwt_exit.clean_up_starts >|= fun _ -> `Killed);
        ]
      >>= function
      | `Killed -> Lwt.return err
      | `Continue ->
          let next_delay = delay *. factor in
          let delay =
            Option.fold
              ~none:next_delay
              ~some:(fun max_delay -> Float.min next_delay max_delay)
              max_delay
          in
          retry cctxt ?max_delay ~delay ~factor ~tries:(tries - 1) f x)
  | Error _ as err -> Lwt.return err

let rec retry_on_disconnection (cctxt : #Protocol_client_context.full) f =
  f () >>= function
  | Ok () -> return_unit
  | Error (Baking_errors.Node_connection_lost :: _) ->
      cctxt#warning
        "Lost connection with the node. Retrying to establish connection..."
      >>= fun () ->
      (* Wait forever when the node stops responding... *)
      Client_confirmations.wait_for_bootstrapped
        ~retry:(retry cctxt ~max_delay:10. ~delay:1. ~factor:1.5 ~tries:max_int)
        cctxt
      >>=? fun () -> retry_on_disconnection cctxt f
  | Error err ->
      cctxt#error "Unexpected error: %a. Exiting..." pp_print_trace err

let await_protocol_start (cctxt : #Protocol_client_context.full) ~chain =
  cctxt#message "Waiting for protocol %s to start..." Protocol.name
  >>= fun () -> Node_rpc.await_protocol_activation cctxt ~chain ()

let may_start_profiler baking_dir =
  let parse_profiling_env_var () =
    match Sys.getenv_opt "PROFILING" with
    | None -> (None, None)
    | Some var -> (
        match String.split_on_char ':' var with
        | [] -> (None, None)
        | [x] -> (Some (String.lowercase_ascii x), None)
        | x :: l ->
            let output_dir = String.concat "" l in
            if not (Sys.file_exists output_dir && Sys.is_directory output_dir)
            then
              Stdlib.failwith
                "Profiling output is not a directory or does not exist."
            else (Some (String.lowercase_ascii x), Some output_dir))
  in
  match parse_profiling_env_var () with
  | None, _ -> ()
  | ( Some (("true" | "on" | "yes" | "terse" | "detailed" | "verbose") as mode),
      output_dir ) ->
      let max_lod =
        match mode with
        | "detailed" -> Profiler.Detailed
        | "verbose" -> Profiler.Verbose
        | _ -> Profiler.Terse
      in
      let output_dir =
        match output_dir with
        | None -> baking_dir
        | Some output_dir -> output_dir
      in
      let profiler_maker ~name =
        Profiler.instance
          Tezos_base_unix.Simple_profiler.auto_write_to_txt_file
          Filename.Infix.((output_dir // name) ^ "_profiling.txt", max_lod)
      in
      Baking_profiler.init profiler_maker ;
      RPC_profiler.init profiler_maker
  | _ -> ()

module Baker = struct
  let run (cctxt : Protocol_client_context.full) ?minimal_fees
      ?minimal_nanotez_per_gas_unit ?minimal_nanotez_per_byte ?liquidity_baking
      ?extra_operations ?dal_node_endpoint ?pre_emptive_forge_time ?force_apply
      ?context_path ?state_recorder ~chain ~keep_alive delegates =
    let process () =
      Config_services.user_activated_upgrades cctxt
      >>=? fun user_activated_upgrades ->
      Shell_services.Chain.chain_id cctxt ~chain:cctxt#chain ()
      >>=? fun chain_id ->
      Protocol.Alpha_services.Constants.all cctxt (`Hash chain_id, `Head 0)
      >>=? fun constants ->
      (let block_time_s =
         Int64.to_float
           (Protocol.Alpha_context.Period.to_seconds
              constants.parametric.minimal_block_delay)
       in
       match Option.map Q.to_float pre_emptive_forge_time with
       | Some t ->
           if t >= block_time_s then
             failwith
               "pre-emptive-forge-time must be less than current block time \
                (<= %f seconds)"
               block_time_s
           else return (t, block_time_s)
       | None -> return (Float.mul 0.15 block_time_s, block_time_s))
      >>=? fun (pre_emptive_forge_time, block_time_s) ->
      let msg =
        if pre_emptive_forge_time <> 0. then
          cctxt#message
            "pre-emptive-forge-time optimization set to %fs. Operation \
             inclusion window is ~%fs. Caution: Setting this too high may \
             result in reduced block proposal rewards."
            pre_emptive_forge_time
            (Float.sub block_time_s pre_emptive_forge_time)
        else Lwt.return_unit
      in
      Lwt.map (fun () -> ok pre_emptive_forge_time) msg
      >>=? fun pre_emptive_forge_time ->
      let pre_emptive_forge_time =
        Time.System.Span.of_seconds_exn pre_emptive_forge_time
      in
      let config =
        Baking_configuration.make
          ?minimal_fees
          ?minimal_nanotez_per_gas_unit
          ?minimal_nanotez_per_byte
          ?liquidity_baking
          ?extra_operations
          ?dal_node_endpoint
          ~pre_emptive_forge_time
          ?force_apply
          ?context_path
          ~user_activated_upgrades
          ?state_recorder
          ()
      in
      cctxt#message
        "Baker v%a (%s) for %a started."
        Tezos_version.Version.pp
        Tezos_version_value.Current_git_info.version
        Tezos_version_value.Current_git_info.abbreviated_commit_hash
        Protocol_hash.pp_short
        Protocol.hash
      >>= fun () ->
      let canceler = Lwt_canceler.create () in
      let _ =
        Lwt_exit.register_clean_up_callback ~loc:__LOC__ (fun _ ->
            cctxt#message "Shutting down the baker..." >>= fun () ->
            Lwt_canceler.cancel canceler >>= fun _ -> Lwt.return_unit)
      in
      let () = may_start_profiler cctxt#get_base_dir in
      Baking_profiler.record "initialization" ;
      Baking_scheduling.run cctxt ~canceler ~chain ~constants config delegates
    in
    Client_confirmations.wait_for_bootstrapped
      ~retry:(retry cctxt ~delay:1. ~factor:1.5 ~tries:5)
      cctxt
    >>=? fun () ->
    await_protocol_start cctxt ~chain >>=? fun () ->
    if keep_alive then retry_on_disconnection cctxt process else process ()
end

module Accuser = struct
  let run (cctxt : #Protocol_client_context.full) ~chain ~preserved_levels
      ~keep_alive =
    let process () =
      cctxt#message
        "Accuser v%a (%s) for %a started."
        Tezos_version.Version.pp
        Tezos_version_value.Current_git_info.version
        Tezos_version_value.Current_git_info.abbreviated_commit_hash
        Protocol_hash.pp_short
        Protocol.hash
      >>= fun () ->
      Client_baking_blocks.monitor_applied_blocks
        ~next_protocols:(Some [Protocol.hash])
        cctxt
        ~chains:[chain]
        ()
      >>=? fun (valid_blocks_stream, _) ->
      let canceler = Lwt_canceler.create () in
      let _ =
        Lwt_exit.register_clean_up_callback ~loc:__LOC__ (fun _ ->
            cctxt#message "Shutting down the accuser..." >>= fun () ->
            Lwt_canceler.cancel canceler >>= fun _ -> Lwt.return_unit)
      in
      Client_baking_denunciation.create
        cctxt
        ~canceler
        ~preserved_levels
        valid_blocks_stream
    in
    Client_confirmations.wait_for_bootstrapped
      ~retry:(retry cctxt ~delay:1. ~factor:1.5 ~tries:5)
      cctxt
    >>=? fun () ->
    await_protocol_start cctxt ~chain >>=? fun () ->
    if keep_alive then retry_on_disconnection cctxt process else process ()
end

module VDF = struct
  let run (cctxt : Protocol_client_context.full) ~chain ~keep_alive =
    let open Lwt_result_syntax in
    let process () =
      let*! () =
        cctxt#message
          "VDF daemon v%a (%s) for %a started."
          Tezos_version.Version.pp
          Tezos_version_value.Current_git_info.version
          Tezos_version_value.Current_git_info.abbreviated_commit_hash
          Protocol_hash.pp_short
          Protocol.hash
      in
      let* chain_id = Shell_services.Chain.chain_id cctxt ~chain () in
      let* constants =
        Protocol.Alpha_services.Constants.all cctxt (`Hash chain_id, `Head 0)
      in
      let canceler = Lwt_canceler.create () in
      let _ =
        Lwt_exit.register_clean_up_callback ~loc:__LOC__ (fun _ ->
            let*! () = cctxt#message "Shutting down the VDF daemon..." in
            let*! _ = Lwt_canceler.cancel canceler in
            Lwt.return_unit)
      in
      Baking_vdf.start_vdf_worker cctxt ~canceler constants chain
    in
    let* () =
      Client_confirmations.wait_for_bootstrapped
        ~retry:(retry cctxt ~delay:1. ~factor:1.5 ~tries:5)
        cctxt
    in
    let* () = await_protocol_start cctxt ~chain in
    if keep_alive then retry_on_disconnection cctxt process else process ()
end
