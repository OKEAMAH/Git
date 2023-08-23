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

include Cli.Binary_dependent_args (struct
  let binary_name = "smart rollup node"
end)

let group =
  {
    Tezos_clic.name = "sc_rollup.node";
    title = "Commands related to the smart rollup node.";
  }

let config_init_command =
  let open Lwt_result_syntax in
  let open Tezos_clic in
  let open Cli in
  command
    ~group
    ~desc:"Configure the smart rollup node."
    (args14
       force_switch
       data_dir_arg
       rpc_addr_arg
       rpc_port_arg
       metrics_addr_arg
       loser_mode_arg
       reconnection_delay_arg
       dal_node_endpoint_arg
       injector_retention_period_arg
       injector_attempts_arg
       injection_ttl_arg
       index_buffer_size_arg
       irmin_cache_size_arg
       log_kernel_debug_arg)
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
           injector_retention_period,
           injector_attempts,
           injection_ttl,
           index_buffer_size,
           irmin_cache_size,
           log_kernel_debug )
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
          ~injector_retention_period
          ~injector_attempts
          ~injection_ttl
          ~mode
          ~sc_rollup_address
          ~sc_rollup_node_operators
          ~index_buffer_size
          ~irmin_cache_size
          ~log_kernel_debug
          ~dac_observer_endpoint:None
          ~dac_timeout:None
          ~boot_sector_file:None
      in
      let* () = Configuration.save ~force ~data_dir config in
      let*! () =
        cctxt#message
          "Smart rollup node configuration written in %s"
          (Configuration.config_filename ~data_dir)
      in
      return_unit)

let legacy_run_command =
  let open Tezos_clic in
  let open Lwt_result_syntax in
  let open Cli in
  command
    ~group
    ~desc:"Run the rollup node daemon (deprecated)."
    (args16
       data_dir_arg
       mode_arg
       sc_rollup_address_arg
       rpc_addr_arg
       rpc_port_arg
       metrics_addr_arg
       loser_mode_arg
       reconnection_delay_arg
       dal_node_endpoint_arg
       injector_retention_period_arg
       injector_attempts_arg
       injection_ttl_arg
       index_buffer_size_arg
       irmin_cache_size_arg
       log_kernel_debug_arg
       log_kernel_debug_file_arg)
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
           injector_retention_period,
           injector_attempts,
           injection_ttl,
           index_buffer_size,
           irmin_cache_size,
           log_kernel_debug,
           log_kernel_debug_file )
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
          ~injector_retention_period
          ~injector_attempts
          ~injection_ttl
          ~mode
          ~sc_rollup_address
          ~sc_rollup_node_operators:[]
          ~index_buffer_size
          ~irmin_cache_size
          ~log_kernel_debug
          ~dac_observer_endpoint:None
          ~dac_timeout:None
          ~boot_sector_file:None
      in
      Daemon.run
        ~data_dir
        ~irmin_cache_size:Configuration.default_irmin_cache_size
        ~index_buffer_size:Configuration.default_index_buffer_size
        ?log_kernel_debug_file
        configuration
        (new Protocol_client_context.wrap_full cctxt))

let run_command =
  let open Tezos_clic in
  let open Lwt_result_syntax in
  let open Cli in
  command
    ~group
    ~desc:
      "Run the rollup node daemon. Arguments overwrite values provided in the \
       configuration file."
    (args14
       data_dir_arg
       rpc_addr_arg
       rpc_port_arg
       metrics_addr_arg
       loser_mode_arg
       reconnection_delay_arg
       dal_node_endpoint_arg
       injector_retention_period_arg
       injector_attempts_arg
       injection_ttl_arg
       index_buffer_size_arg
       irmin_cache_size_arg
       log_kernel_debug_arg
       log_kernel_debug_file_arg)
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
           injector_retention_period,
           injector_attempts,
           injection_ttl,
           index_buffer_size,
           irmin_cache_size,
           log_kernel_debug,
           log_kernel_debug_file )
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
          ~injector_retention_period
          ~injector_attempts
          ~injection_ttl
          ~mode:(Some mode)
          ~sc_rollup_address:(Some sc_rollup_address)
          ~sc_rollup_node_operators
          ~index_buffer_size
          ~irmin_cache_size
          ~log_kernel_debug
          ~dac_observer_endpoint:None
          ~dac_timeout:None
          ~boot_sector_file:None
      in
      Daemon.run
        ~data_dir
        ~irmin_cache_size:Configuration.default_irmin_cache_size
        ~index_buffer_size:Configuration.default_index_buffer_size
        ?log_kernel_debug_file
        configuration
        (new Protocol_client_context.wrap_full cctxt))

(** Command to dump the rollup node metrics. *)
let dump_metrics =
  let open Tezos_clic in
  let open Lwt_result_syntax in
  command
    ~group
    ~desc:"dump the rollup node available metrics in CSV format."
    no_options
    (prefixes ["dump-metrics"] @@ stop)
    (fun () (cctxt : Client_context.full) ->
      let*! metrics =
        Prometheus.CollectorRegistry.collect Metrics.sc_rollup_node_registry
      in
      let*! () = cctxt#message "%a@." Metrics.print_csv_metrics metrics in
      return_unit)

let sc_rollup_commands () =
  [config_init_command; run_command; legacy_run_command; dump_metrics]

let select_commands _ctxt _ = Lwt_result_syntax.return (sc_rollup_commands ())

let global_options () =
  let open Client_config in
  Tezos_clic.args11
    (base_dir_arg ())
    (no_base_dir_warnings_switch ())
    (timings_switch ())
    (log_requests_switch ())
    (better_errors ())
    (addr_arg ())
    (port_arg ())
    (tls_switch ())
    (endpoint_arg ())
    (remote_signer_arg ())
    (password_filename_arg ())

module Daemon_node_config = struct
  type t =
    string option
    * bool
    * bool
    * bool
    * bool
    * string option
    * int option
    * bool
    * Uri.t option
    * Uri.t option
    * string option

  let global_options = global_options

  let parse_config_args = Client_config.parse_config_args

  let default_chain = Client_config.default_chain

  let default_block = Client_config.default_block

  let default_base_dir = Client_config.default_base_dir

  let default_media_type = Daemon_config.default_media_type

  let other_registrations = None

  let default_daily_logs_path = None

  let logger = None

  let clic_commands ~base_dir:_ ~config_commands:_ ~builtin_commands:_
      ~other_commands ~require_auth:_ =
    other_commands
end

let () = Client_main_run.run (module Daemon_node_config) ~select_commands