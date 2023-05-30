(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022-2023 TriliTech <contact@trili.tech>                    *)
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

let force_switch () =
  Tezos_clic.switch
    ~long:"force"
    ~doc:"Overwrites the configuration file when it exists."
    ()

let sc_rollup_address_param x =
  Smart_rollup_alias.Address.param
    ~name:"smart-rollup-address"
    ~desc:"The smart rollup address"
    x

let sc_rollup_address_arg () =
  Tezos_clic.arg
    ~long:"rollup"
    ~placeholder:"smart-rollup-address"
    ~doc:"The smart rollup address (required when no configuration file exists)"
    (Smart_rollup_alias.Address.parameter ())

let rpc_addr_arg component =
  let default = Configuration.default_rpc_addr in
  Tezos_clic.arg
    ~long:"rpc-addr"
    ~placeholder:"rpc-address|ip"
    ~doc:
      (Format.sprintf
         "The address the %s listens to. Default value is %s"
         component
         default)
    Client_proto_args.string_parameter

let metrics_addr_arg component =
  Tezos_clic.arg
    ~long:"metrics-addr"
    ~placeholder:
      "ADDR:PORT or :PORT (by default ADDR is localhost and PORT is 9933)"
    ~doc:(Format.sprintf "The address of the %s metrics server." component)
    Client_proto_args.string_parameter

let dac_observer_endpoint_arg () =
  Tezos_clic.arg
    ~long:"dac-observer"
    ~placeholder:"dac-observer-endpoint"
    ~doc:
      (Format.sprintf
         "The address of the DAC observer node from which the smart rollup \
          node downloads preimages requested through the reveal channel.")
    (Tezos_clic.parameter (fun _ s -> Lwt.return_ok (Uri.of_string s)))

let dac_timeout_arg =
  Tezos_clic.arg
    ~long:"dac-timeout"
    ~placeholder:"seconds"
    ~doc:
      "Timeout in seconds for which the DAC observer client will wait for a \
       preimage"
    Client_proto_args.z_parameter

let rpc_port_arg =
  let default = Configuration.default_rpc_port |> string_of_int in
  Tezos_clic.arg
    ~long:"rpc-port"
    ~placeholder:"rpc-port"
    ~doc:
      (Format.sprintf
         "The port the smart rollup node listens to. Default value is %s"
         default)
    Client_proto_args.int_parameter

let data_dir_arg =
  let default = Configuration.default_data_dir in
  Tezos_clic.default_arg
    ~long:"data-dir"
    ~placeholder:"data-dir"
    ~doc:
      (Format.sprintf
         "The path to the smart rollup node data directory. Default value is %s"
         default)
    ~default
    Client_proto_args.string_parameter

let reconnection_delay_arg () =
  let default =
    Format.sprintf "%.1f" Configuration.default_reconnection_delay
  in
  let doc =
    Format.asprintf
      "The first reconnection delay, in seconds, to wait before reconnecting \
       to the Tezos node. The default delay is %s.\n\
       The actual delay varies to follow a randomized exponential backoff \
       (capped to 1.5h): [1.5^reconnection_attempt * delay ± 50%%]."
      default
  in
  Tezos_clic.arg
    ~long:"reconnection-delay"
    ~placeholder:"delay"
    ~doc
    (Tezos_clic.parameter (fun _ p ->
         try return (float_of_string p) with _ -> failwith "Cannot read float"))

let injector_retention_period_arg =
  Tezos_clic.arg
    ~long:"injector-retention-period"
    ~placeholder:"blocks"
    ~doc:
      (Format.sprintf
         "The number of blocks the injector keeps in memory. Decrease to free \
          memory, and increase to be able to query information about included \
          messages for longer. Default value is %d"
         Configuration.default_injector.retention_period)
  @@ Tezos_clic.map_parameter Client_proto_args.int_parameter ~f:(fun p ->
         if p > Configuration.max_injector_retention_period || p < 0 then
           Format.ksprintf
             Stdlib.failwith
             "injector-retention-period should be a positive number smaller \
              than %d"
             Configuration.max_injector_retention_period ;
         p)

let injector_attempts_arg =
  Tezos_clic.arg
    ~long:"injector-attempts"
    ~placeholder:"number"
    ~doc:
      (Format.sprintf
         "The number of attempts that the injector will make to inject an \
          operation when it fails. Default value is %d"
         Configuration.default_injector.attempts)
  @@ Tezos_clic.map_parameter Client_proto_args.int_parameter ~f:(fun p ->
         if p < 0 then
           Format.ksprintf
             Stdlib.failwith
             "injector-attempts should be positive" ;
         p)

let injection_ttl_arg =
  Tezos_clic.arg
    ~long:"injection-ttl"
    ~placeholder:"number"
    ~doc:
      (Format.sprintf
         "The number of blocks after which an operation that is injected but \
          never included is retried. Default value is %d"
         Configuration.default_injector.injection_ttl)
  @@ Tezos_clic.map_parameter Client_proto_args.int_parameter ~f:(fun p ->
         if p < 1 then Stdlib.failwith "injection-ttl should be > 1" ;
         p)

let log_kernel_debug_arg () =
  Tezos_clic.switch
    ~long:"log-kernel-debug"
    ~doc:"Log the kernel debug output to kernel.log in the data directory"
    ()

let log_kernel_debug_file_arg =
  Tezos_clic.arg
    ~long:"log-kernel-debug-file"
    ~placeholder:"file"
    ~doc:""
    Client_proto_args.string_parameter

let boot_sector_file_arg () =
  Tezos_clic.arg
    ~long:"boot-sector-file"
    ~placeholder:"file"
    ~doc:
      "Path to the boot sector. The argument is optional, if the rollup node \
       was originated via the smart rollup originate operation, the rollup \
       node will fetch the boot sector itself. This argument is required only \
       if it's a bootstrapped smart rollup."
    (Tezos_clic.parameter (fun _ path ->
         let open Lwt_result_syntax in
         let*! exists = Lwt_unix.file_exists path in
         if exists then return path
         else failwith "Boot sector not found at path %S" path))
