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

let rec retry_on_disconnection (cctxt : #Protocol_client_context.full) f =
  let open Lwt_result_syntax in
  let*! result = f () in
  match result with
  | Ok () -> return_unit
  | Error (Baking_errors.Node_connection_lost :: _) ->
      let*! () =
        cctxt#warning
          "Lost connection with the node. Retrying to establish connection..."
      in
      (* Wait forever when the node stops responding... *)
      let* () =
        Client_confirmations.wait_for_bootstrapped
          ~retry:
            (Baking_scheduling.retry
               cctxt
               ~max_delay:10.
               ~delay:1.
               ~factor:1.5
               ~tries:max_int)
          cctxt
      in
      retry_on_disconnection cctxt f
  | Error err ->
      cctxt#error "Unexpected error: %a. Exiting..." pp_print_trace err

let await_protocol_start (cctxt : #Protocol_client_context.full) ~chain =
  let open Lwt_result_syntax in
  let*! () =
    cctxt#message "Waiting for protocol %s to start..." Protocol.name
  in
  Node_rpc.await_protocol_activation cctxt ~chain ()

let may_start_profiler baking_dir =
  match Option.map String.lowercase_ascii @@ Sys.getenv_opt "PROFILING" with
  | Some (("true" | "on" | "yes" | "terse" | "detailed" | "verbose") as mode) ->
      let max_lod =
        match mode with
        | "detailed" -> Profiler.Detailed
        | "verbose" -> Profiler.Verbose
        | _ -> Profiler.Terse
      in
      let profiler_maker ~name =
        Profiler.instance
          Tezos_base_unix.Simple_profiler.auto_write_to_file
          Filename.Infix.((baking_dir // name) ^ "_profiling.txt", max_lod)
      in
      Baking_profiler.init profiler_maker
  | _ -> ()

module Baker = struct
  let run (cctxt : Protocol_client_context.full) ?minimal_fees
      ?minimal_nanotez_per_gas_unit ?minimal_nanotez_per_byte ?votes
      ?extra_operations ?dal_node_endpoint ?force_apply ?context_path ~chain
      ~keep_alive delegates =
    let open Lwt_result_syntax in
    let process () =
      let* user_activated_upgrades =
        Config_services.user_activated_upgrades cctxt
      in
      let config =
        Baking_configuration.make
          ?minimal_fees
          ?minimal_nanotez_per_gas_unit
          ?minimal_nanotez_per_byte
          ?votes
          ?extra_operations
          ?dal_node_endpoint
          ?force_apply
          ?context_path
          ~user_activated_upgrades
          ()
      in
      let*! () =
        cctxt#message
          "Baker v%a (%s) for %a started."
          Tezos_version.Version.pp
          Tezos_version_value.Current_git_info.version
          Tezos_version_value.Current_git_info.abbreviated_commit_hash
          Protocol_hash.pp_short
          Protocol.hash
      in
      let canceler = Lwt_canceler.create () in
      let _ =
        Lwt_exit.register_clean_up_callback ~loc:__LOC__ (fun _ ->
            let*! () = cctxt#message "Shutting down the baker..." in
            let*! _ = Lwt_canceler.cancel canceler in
            Lwt.return_unit)
      in
      let () = may_start_profiler cctxt#get_base_dir in
      Baking_profiler.record "initialization" ;
      Baking_scheduling.run cctxt ~canceler ~chain config delegates
    in
    let* () =
      Client_confirmations.wait_for_bootstrapped
        ~retry:(Baking_scheduling.retry cctxt ~delay:1. ~factor:1.5 ~tries:5)
        cctxt
    in
    let* () = await_protocol_start cctxt ~chain in
    if keep_alive then retry_on_disconnection cctxt process else process ()
end

module Accuser = struct
  let run (cctxt : #Protocol_client_context.full) ~chain ~preserved_levels
      ~keep_alive =
    let open Lwt_result_syntax in
    let process () =
      let*! () =
        cctxt#message
          "Accuser v%a (%s) for %a started."
          Tezos_version.Version.pp
          Tezos_version_value.Current_git_info.version
          Tezos_version_value.Current_git_info.abbreviated_commit_hash
          Protocol_hash.pp_short
          Protocol.hash
      in
      let* valid_blocks_stream, _ =
        Client_baking_blocks.monitor_applied_blocks
          ~next_protocols:(Some [Protocol.hash])
          cctxt
          ~chains:[chain]
          ()
      in
      let canceler = Lwt_canceler.create () in
      let _ =
        Lwt_exit.register_clean_up_callback ~loc:__LOC__ (fun _ ->
            let*! () = cctxt#message "Shutting down the accuser..." in
            let*! _ = Lwt_canceler.cancel canceler in
            Lwt.return_unit)
      in
      Client_baking_denunciation.create
        cctxt
        ~canceler
        ~preserved_levels
        valid_blocks_stream
    in
    let* () =
      Client_confirmations.wait_for_bootstrapped
        ~retry:(Baking_scheduling.retry cctxt ~delay:1. ~factor:1.5 ~tries:5)
        cctxt
    in
    let* () = await_protocol_start cctxt ~chain in
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
        ~retry:(Baking_scheduling.retry cctxt ~delay:1. ~factor:1.5 ~tries:5)
        cctxt
    in
    let* () = await_protocol_start cctxt ~chain in
    if keep_alive then retry_on_disconnection cctxt process else process ()
end
