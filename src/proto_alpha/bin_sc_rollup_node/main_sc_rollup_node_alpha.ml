(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

let group =
  {
    Tezos_clic.name = "sc_rollup.node";
    title = "Commands related to the smart rollup node.";
  }

let component_name = "rollup node"

let possible_modes = List.map Configuration.string_of_mode Configuration.modes

let mode_parameter =
  Tezos_clic.parameter
    ~autocomplete:(fun _ -> return possible_modes)
    (fun _ m -> Lwt.return (Configuration.mode_of_string m))

let mode_doc =
  Format.asprintf
    "The mode for the rollup node (%s)@\n%a"
    (String.concat ", " possible_modes)
    (Format.pp_print_list (fun fmt mode ->
         Format.fprintf
           fmt
           "- %s: %s"
           (Configuration.string_of_mode mode)
           (Configuration.description_of_mode mode)))
    Configuration.modes

let mode_param params =
  Tezos_clic.param ~name:"mode" ~desc:mode_doc mode_parameter params

let mode_arg =
  Tezos_clic.arg
    ~long:"mode"
    ~placeholder:"mode"
    ~doc:(mode_doc ^ "\n(required when no configuration file exists)")
    mode_parameter

let dal_node_endpoint_arg =
  Tezos_clic.arg
    ~long:"dal-node"
    ~placeholder:"dal-node-endpoint"
    ~doc:
      (Format.sprintf
         "The address of the dal node from which the smart rollup node \
          downloads slots. When not provided, the rollup node will not support \
          the DAL. In production, a DAL node must be provided if DAL is \
          enabled and used in the rollup.")
    (Tezos_clic.parameter (fun _ s -> Lwt.return_ok (Uri.of_string s)))

let loser_mode_arg =
  Tezos_clic.arg
    ~long:"loser-mode"
    ~placeholder:"mode"
    ~doc:"Set the rollup node failure points (for test only!)."
    (Tezos_clic.parameter (fun _ s ->
         match Loser_mode.make s with
         | Some t -> return t
         | None -> failwith "Invalid syntax for failure points"))

let sc_rollup_node_operator_param next =
  let open Lwt_result_syntax in
  Tezos_clic.param
    ~name:"operator"
    ~desc:
      (Printf.sprintf
         "Public key hash, or alias, of a smart rollup node operator. An \
          operator can be specialized to a particular purpose by prefixing its \
          key or alias by said purpose, e.g. publish:alias_of_my_operator. The \
          possible purposes are: %s."
         (String.concat ", "
         @@ Configuration.(List.map string_of_purpose purposes)))
    ( Tezos_clic.parameter @@ fun cctxt s ->
      let parse_pkh s =
        let from_alias s = Client_keys.Public_key_hash.find cctxt s in
        let from_key s =
          match Signature.Public_key_hash.of_b58check_opt s with
          | None ->
              failwith "Could not read public key hash for rollup node operator"
          | Some pkh -> return pkh
        in
        Client_aliases.parse_alternatives
          [("alias", from_alias); ("key", from_key)]
          s
      in
      match String.split ~limit:1 ':' s with
      | [_] ->
          let+ pkh = parse_pkh s in
          `Default pkh
      | [purpose; operator_s] -> (
          match Configuration.purpose_of_string purpose with
          | Some purpose ->
              let+ pkh = parse_pkh operator_s in
              `Purpose (purpose, pkh)
          | None ->
              let+ pkh = parse_pkh s in
              `Default pkh)
      | _ ->
          (* cannot happen due to String.split's implementation. *)
          assert false )
    next

let config_init_command =
  let open Lwt_result_syntax in
  let open Tezos_clic in
  let open Cli in
  command
    ~group
    ~desc:"Configure the smart rollup node."
    (args15
       (force_switch ())
       data_dir_arg
       (rpc_addr_arg component_name)
       rpc_port_arg
       (metrics_addr_arg component_name)
       loser_mode_arg
       (reconnection_delay_arg ())
       dal_node_endpoint_arg
       (dac_observer_endpoint_arg ())
       dac_timeout_arg
       injector_retention_period_arg
       injector_attempts_arg
       injection_ttl_arg
       (log_kernel_debug_arg ())
       (boot_sector_file_arg ()))
    (prefix "init" @@ mode_param
    @@ prefixes ["config"; "for"]
    @@ sc_rollup_address_param
    @@ prefixes ["with"; "operators"]
    @@ seq_of_param @@ sc_rollup_node_operator_param)
    (fun ( force,
           data_dir,
           rpc_addr,
           rpc_port,
           metrics_addr,
           loser_mode,
           reconnection_delay,
           dal_node_endpoint,
           dac_observer_endpoint,
           dac_timeout,
           injector_retention_period,
           injector_attempts,
           injection_ttl,
           log_kernel_debug,
           boot_sector_file )
         mode
         sc_rollup_address
         sc_rollup_node_operators
         cctxt ->
      let*? config =
        Configuration.Cli.configuration_from_args
          ~rpc_addr
          ~rpc_port
          ~metrics_addr
          ~loser_mode
          ~reconnection_delay
          ~dal_node_endpoint
          ~dac_observer_endpoint
          ~dac_timeout
          ~injector_retention_period
          ~injector_attempts
          ~injection_ttl
          ~mode
          ~sc_rollup_address
          ~boot_sector_file
          ~sc_rollup_node_operators
          ~log_kernel_debug
      in
      let* () = Configuration.save ~force ~data_dir config in
      let*! () =
        cctxt#message
          "Smart rollup node configuration written in %s"
          (Configuration.config_filename ~data_dir)
      in
      return_unit)

module Daemon_components = struct
  module Batcher = Batcher
  module RPC_server = RPC_server
end

let legacy_run_command =
  let open Tezos_clic in
  let open Lwt_result_syntax in
  let open Cli in
  command
    ~group
    ~desc:"Run the rollup node daemon (deprecated)."
    (args17
       data_dir_arg
       mode_arg
       (sc_rollup_address_arg ())
       (rpc_addr_arg component_name)
       rpc_port_arg
       (metrics_addr_arg component_name)
       loser_mode_arg
       (reconnection_delay_arg ())
       dal_node_endpoint_arg
       (dac_observer_endpoint_arg ())
       dac_timeout_arg
       injector_retention_period_arg
       injector_attempts_arg
       injection_ttl_arg
       (log_kernel_debug_arg ())
       log_kernel_debug_file_arg
       (boot_sector_file_arg ()))
    (prefixes ["run"] @@ stop)
    (fun ( data_dir,
           mode,
           sc_rollup_address,
           rpc_addr,
           rpc_port,
           metrics_addr,
           loser_mode,
           reconnection_delay,
           dal_node_endpoint,
           dac_observer_endpoint,
           dac_timeout,
           injector_retention_period,
           injector_attempts,
           injection_ttl,
           log_kernel_debug,
           log_kernel_debug_file,
           boot_sector_file )
         cctxt ->
      let* configuration =
        Configuration.Cli.create_or_read_config
          ~data_dir
          ~rpc_addr
          ~rpc_port
          ~metrics_addr
          ~loser_mode
          ~reconnection_delay
          ~dal_node_endpoint
          ~dac_observer_endpoint
          ~dac_timeout
          ~injector_retention_period
          ~injector_attempts
          ~injection_ttl
          ~mode
          ~sc_rollup_address
          ~boot_sector_file
          ~sc_rollup_node_operators:[]
          ~log_kernel_debug
      in
      Daemon.run
        ~data_dir
        ?log_kernel_debug_file
        configuration
        (module Daemon_components)
        cctxt)

let run_command =
  let open Tezos_clic in
  let open Lwt_result_syntax in
  let open Cli in
  command
    ~group
    ~desc:
      "Run the rollup node daemon. Arguments overwrite values provided in the \
       configuration file."
    (args15
       data_dir_arg
       (rpc_addr_arg component_name)
       rpc_port_arg
       (metrics_addr_arg component_name)
       loser_mode_arg
       (reconnection_delay_arg ())
       dal_node_endpoint_arg
       (dac_observer_endpoint_arg ())
       dac_timeout_arg
       injector_retention_period_arg
       injector_attempts_arg
       injection_ttl_arg
       (log_kernel_debug_arg ())
       log_kernel_debug_file_arg
       (boot_sector_file_arg ()))
    (prefixes ["run"] @@ mode_param @@ prefixes ["for"]
   @@ sc_rollup_address_param
    @@ prefixes ["with"; "operators"]
    @@ seq_of_param @@ sc_rollup_node_operator_param)
    (fun ( data_dir,
           rpc_addr,
           rpc_port,
           metrics_addr,
           loser_mode,
           reconnection_delay,
           dal_node_endpoint,
           dac_observer_endpoint,
           dac_timeout,
           injector_retention_period,
           injector_attempts,
           injection_ttl,
           log_kernel_debug,
           log_kernel_debug_file,
           boot_sector_file )
         mode
         sc_rollup_address
         sc_rollup_node_operators
         cctxt ->
      let* configuration =
        Configuration.Cli.create_or_read_config
          ~data_dir
          ~rpc_addr
          ~rpc_port
          ~metrics_addr
          ~loser_mode
          ~reconnection_delay
          ~dal_node_endpoint
          ~dac_observer_endpoint
          ~dac_timeout
          ~injector_retention_period
          ~injector_attempts
          ~injection_ttl
          ~mode:(Some mode)
          ~sc_rollup_address:(Some sc_rollup_address)
          ~sc_rollup_node_operators
          ~log_kernel_debug
          ~boot_sector_file
      in
      Daemon.run
        ~data_dir
        ?log_kernel_debug_file
        configuration
        (module Daemon_components)
        cctxt)

(** Command to dump the rollup node metrics. *)
let dump_metrics =
  let open Tezos_clic in
  let open Lwt_result_syntax in
  command
    ~group
    ~desc:"dump the rollup node available metrics in CSV format."
    no_options
    (prefixes ["dump-metrics"] @@ stop)
    (fun () (cctxt : Protocol_client_context.full) ->
      let*! metrics =
        Prometheus.CollectorRegistry.collect Metrics.sc_rollup_node_registry
      in
      let*! () = cctxt#message "%a@." Metrics.print_csv_metrics metrics in
      return_unit)

let sc_rollup_commands () =
  List.map
    (Tezos_clic.map_command (new Protocol_client_context.wrap_full))
    [config_init_command; run_command; legacy_run_command; dump_metrics]

let select_commands _ctxt _ =
  Lwt_result_syntax.return
    (sc_rollup_commands () @ Client_helpers_commands.commands ())

let () = Client_main_run.run (module Daemon_config) ~select_commands
