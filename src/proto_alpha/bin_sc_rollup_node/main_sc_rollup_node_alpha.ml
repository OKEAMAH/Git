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

let sc_rollup_address_param =
  Tezos_clic.param
    ~name:"sc-rollup-address"
    ~desc:"The smart-contract rollup address"
    (Tezos_clic.parameter (fun _ s ->
         match Protocol.Alpha_context.Sc_rollup.Address.of_b58check_opt s with
         | None -> failwith "Invalid smart-contract rollup address"
         | Some addr -> return addr))

let sc_rollup_node_operator_param =
  let open Lwt_result_syntax in
  Tezos_clic.param
    ~name:"operator"
    ~desc:
      (Printf.sprintf
         "Public key hash, or alias, of a smart-contract rollup node operator. \
          An operator can be specialized to a particular purpose by prefixing \
          its key or alias by said purpose, e.g. publish:alias_of_my_operator. \
          The possible purposes are: %s."
         (String.concat ", "
         @@ Configuration.(List.map string_of_purpose purposes)))
  @@ Tezos_clic.parameter
  @@ fun cctxt s ->
  let parse_pkh s =
    let from_alias s = Client_keys.Public_key_hash.find cctxt s in
    let from_key s =
      match Tezos_crypto.Signature.Public_key_hash.of_b58check_opt s with
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
      assert false

let possible_modes = List.map Configuration.string_of_mode Configuration.modes

let mode_parameter =
  Tezos_clic.parameter
    ~autocomplete:(fun _ -> return possible_modes)
    (fun _ m -> Lwt.return (Configuration.mode_of_string m))

let mode_param =
  Tezos_clic.param
    ~name:"mode"
    ~desc:
      (Format.asprintf
         "@[<v 2>The mode for the rollup node (%s)@,%a@]"
         (String.concat ", " possible_modes)
         (Format.pp_print_list (fun fmt mode ->
              Format.fprintf
                fmt
                "- %s: %s"
                (Configuration.string_of_mode mode)
                (Configuration.description_of_mode mode)))
         Configuration.modes)
    mode_parameter

let rpc_addr_arg =
  let default = Configuration.default_rpc_addr in
  Tezos_clic.arg
    ~long:"rpc-addr"
    ~placeholder:"rpc-address|ip"
    ~doc:
      (Format.sprintf
         "The address the smart-contract rollup node listens to. Default value \
          is %s"
         default)
    Client_proto_args.string_parameter

let metrics_addr_arg =
  Tezos_clic.arg
    ~long:"metrics-addr"
    ~placeholder:
      "ADDR:PORT or :PORT (by default ADDR is localhost and PORT is 9932)"
    ~doc:"The address of the smart-contract rollup node metrics server."
    Client_proto_args.string_parameter

let dal_node_addr_arg =
  let default = Configuration.default_dal_node_addr in
  Tezos_clic.arg
    ~long:"dal-node-addr"
    ~placeholder:"dal-node-address|ip"
    ~doc:
      (Format.sprintf
         "The address of the dal node from which the smart-contract rollup \
          node downloads slots. Default value is %s"
         default)
    Client_proto_args.string_parameter

let rpc_port_arg =
  let default = Configuration.default_rpc_port |> string_of_int in
  Tezos_clic.arg
    ~long:"rpc-port"
    ~placeholder:"rpc-port"
    ~doc:
      (Format.sprintf
         "The port the smart-contract rollup node listens to. Default value is \
          %s"
         default)
    Client_proto_args.int_parameter

let dal_node_port_arg =
  let default = Configuration.default_dal_node_port |> string_of_int in
  Tezos_clic.arg
    ~long:"dal-node-port"
    ~placeholder:"dal-node-port"
    ~doc:
      (Format.sprintf
         "The port of the dal node from which the smart-contract rollup node \
          downloads slots from. Default value is %s"
         default)
    Client_proto_args.int_parameter

let data_dir_arg =
  let default = Configuration.default_data_dir in
  Tezos_clic.default_arg
    ~long:"data-dir"
    ~placeholder:"data-dir"
    ~doc:
      (Format.sprintf
         "The path to the smart-contract rollup node data directory. Default \
          value is %s"
         default)
    ~default
    Client_proto_args.string_parameter

let loser_mode =
  Tezos_clic.default_arg
    ~long:"loser-mode"
    ~placeholder:"mode"
    ~default:""
    ~doc:"Set the rollup node failure points (for test only!)."
    (Tezos_clic.parameter (fun _ s ->
         match Loser_mode.make_t2 s with
         | Some t -> return t
         | None -> failwith "Invalid syntax for failure points"))

let reconnection_delay_arg =
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
  let default =
    Configuration.default_injector_retention_period |> string_of_int
  in
  Tezos_clic.default_arg
    ~long:"injector-retention-period"
    ~placeholder:"blocks"
    ~doc:
      (Format.sprintf
         "The number of blocks the injector keeps in memory. Decrease to free \
          memory, and increase to be able to query information about included \
          messages for longer. Default value is %s"
         default)
    ~default
  @@ Tezos_clic.map_parameter Client_proto_args.int_parameter ~f:(fun p ->
         if p > Configuration.max_injector_retention_period then
           Format.ksprintf
             Stdlib.failwith
             "injector-retention-period should be smaller than %d"
             Configuration.max_injector_retention_period ;
         p)

let group =
  {
    Tezos_clic.name = "sc_rollup.node";
    title = "Commands related to the smart-contract rollup node.";
  }

let config_init_command =
  let open Lwt_result_syntax in
  let open Tezos_clic in
  command
    ~group
    ~desc:"Configure the smart-contract rollup node."
    (args9
       data_dir_arg
       rpc_addr_arg
       rpc_port_arg
       metrics_addr_arg
       loser_mode
       reconnection_delay_arg
       dal_node_addr_arg
       dal_node_port_arg
       injector_retention_period_arg)
    (prefix "init" @@ mode_param
    @@ prefixes ["config"; "for"]
    @@ sc_rollup_address_param
    @@ prefixes ["with"; "operators"]
    @@ seq_of_param @@ sc_rollup_node_operator_param)
    (fun ( data_dir,
           rpc_addr,
           rpc_port,
           metrics_addr,
           loser_mode,
           reconnection_delay,
           dal_node_addr,
           dal_node_port,
           injector_retention_period )
         mode
         sc_rollup_address
         sc_rollup_node_operators
         cctxt ->
      let open Configuration in
      let purposed_operators, default_operators =
        List.partition_map
          (function
            | `Purpose p_operator -> Left p_operator
            | `Default operator -> Right operator)
          sc_rollup_node_operators
      in
      let default_operator =
        match default_operators with
        | [] -> None
        | [default_operator] -> Some default_operator
        | _ -> Stdlib.failwith "Multiple default operators"
      in
      let sc_rollup_node_operators =
        Configuration.make_purpose_map
          purposed_operators
          ~default:default_operator
      in
      let config =
        {
          sc_rollup_address;
          sc_rollup_node_operators;
          rpc_addr = Option.value ~default:default_rpc_addr rpc_addr;
          rpc_port = Option.value ~default:default_rpc_port rpc_port;
          reconnection_delay =
            Option.value ~default:default_reconnection_delay reconnection_delay;
          dal_node_addr =
            Option.value ~default:default_dal_node_addr dal_node_addr;
          dal_node_port =
            Option.value ~default:default_dal_node_port dal_node_port;
          metrics_addr;
          fee_parameters = Operator_purpose_map.empty;
          mode;
          loser_mode;
          batcher = Configuration.default_batcher;
          injector_retention_period;
        }
      in
      let*? config = check_mode config in
      let* () = save ~data_dir config in
      let*! () =
        cctxt#message
          "Smart-contract rollup node configuration written in %s"
          (config_filename ~data_dir)
      in
      return_unit)

let run_command =
  let open Tezos_clic in
  let open Lwt_result_syntax in
  command
    ~group
    ~desc:"Run the rollup daemon."
    (args7
       data_dir_arg
       rpc_addr_arg
       rpc_port_arg
       dal_node_addr_arg
       dal_node_port_arg
       reconnection_delay_arg
       metrics_addr_arg)
    (prefixes ["run"] @@ stop)
    (fun ( data_dir,
           rpc_addr,
           rpc_port,
           dal_node_addr,
           dal_node_port,
           reconnection_delay,
           metrics_addr )
         cctxt ->
      let* configuration = Configuration.load ~data_dir in
      let configuration =
        Configuration.
          {
            configuration with
            rpc_addr = Option.value ~default:configuration.rpc_addr rpc_addr;
            rpc_port = Option.value ~default:configuration.rpc_port rpc_port;
            dal_node_addr =
              Option.value ~default:configuration.dal_node_addr dal_node_addr;
            dal_node_port =
              Option.value ~default:configuration.dal_node_port dal_node_port;
            reconnection_delay =
              Option.value
                ~default:configuration.reconnection_delay
                reconnection_delay;
            metrics_addr = Option.either metrics_addr configuration.metrics_addr;
          }
      in
      Daemon.run ~data_dir configuration cctxt)

let sc_rollup_commands () =
  List.map
    (Tezos_clic.map_command (new Protocol_client_context.wrap_full))
    [config_init_command; run_command]

let select_commands _ _ =
  return (sc_rollup_commands () @ Client_helpers_commands.commands ())

let () = Client_main_run.run (module Daemon_config) ~select_commands
