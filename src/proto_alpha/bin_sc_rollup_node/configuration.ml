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

open Protocol.Alpha_context

type mode = Observer | Batcher | Maintenance | Operator | Custom

type purpose = Publish | Add_messages | Cement | Timeout | Refute

let purposes = [Publish; Add_messages; Cement; Timeout; Refute]

module Operator_purpose_map = Map.Make (struct
  type t = purpose

  let compare = Stdlib.compare
end)

type operators = Signature.Public_key_hash.t Operator_purpose_map.t

type t = {
  data_dir : string;
  sc_rollup_address : Sc_rollup.t;
  sc_rollup_node_operators : operators;
  rpc_addr : string;
  rpc_port : int;
  reconnection_delay : float;
  fee_parameter : Injection.fee_parameter;
  mode : mode;
  loser_mode : Loser_mode.t;
  dal_node_addr : string;
  dal_node_port : int;
}

let default_data_dir =
  Filename.concat (Sys.getenv "HOME") ".tezos-sc-rollup-node"

let storage_dir = "storage"

let context_dir = "context"

let default_storage_dir data_dir = Filename.concat data_dir storage_dir

let default_context_dir data_dir = Filename.concat data_dir context_dir

let relative_filename data_dir = Filename.concat data_dir "config.json"

let filename config = relative_filename config.data_dir

let default_rpc_addr = "127.0.0.1"

let default_rpc_port = 8932

let default_reconnection_delay = 2.0 (* seconds *)

let default_dal_node_addr = "127.0.0.1"

let default_dal_node_port = 10732

(* TODO: https://gitlab.com/tezos/tezos/-/issues/2794
   the below default values have been copied from
   `src/proto_alpha/lib_client/client_proto_args.ml`, but
   we need to check whether these values are sensible for the rollup
   node.
*)
let default_minimal_fees =
  match Tez.of_mutez 100L with None -> assert false | Some t -> t

let default_minimal_nanotez_per_gas_unit = Q.of_int 100

let default_minimal_nanotez_per_byte = Q.of_int 1000

let default_force_low_fee = false

let default_fee_cap =
  match Tez.of_string "1.0" with None -> assert false | Some t -> t

let default_burn_cap =
  match Tez.of_string "0" with None -> assert false | Some t -> t

let default_fee_parameter =
  {
    Injection.minimal_fees = default_minimal_fees;
    minimal_nanotez_per_byte = default_minimal_nanotez_per_byte;
    minimal_nanotez_per_gas_unit = default_minimal_nanotez_per_gas_unit;
    force_low_fee = default_force_low_fee;
    fee_cap = default_fee_cap;
    burn_cap = default_burn_cap;
  }

let string_of_purpose = function
  | Publish -> "publish"
  | Add_messages -> "add_messages"
  | Cement -> "cement"
  | Timeout -> "timeout"
  | Refute -> "refute"

let purpose_of_string = function
  | "publish" -> Some Publish
  | "add_messages" -> Some Add_messages
  | "cement" -> Some Cement
  | "timeout" -> Some Timeout
  | "refute" -> Some Refute
  | _ -> None

let purpose_of_string_exn s =
  match purpose_of_string s with
  | Some p -> p
  | None -> invalid_arg ("purpose_of_string " ^ s)

let add_fallbacks map fallbacks =
  List.fold_left
    (fun map (missing_purpose, fallback_purpose) ->
      if Operator_purpose_map.mem missing_purpose map then
        (* No missing purpose, don't fallback *)
        map
      else
        match Operator_purpose_map.find fallback_purpose map with
        | None ->
            (* Nothing to fallback on *)
            map
        | Some operator -> Operator_purpose_map.add missing_purpose operator map)
    map
    fallbacks

let make_purpose_map ~default bindings =
  let map = Operator_purpose_map.of_seq @@ List.to_seq bindings in
  let map = add_fallbacks map [(Timeout, Refute)] in
  match default with
  | None -> map
  | Some default ->
      List.fold_left
        (fun map purpose ->
          if Operator_purpose_map.mem purpose map then map
          else Operator_purpose_map.add purpose default map)
        map
        purposes

let operator_purpose_map_encoding encoding =
  let open Data_encoding in
  let schema =
    let open Json_schema in
    let v_schema = Data_encoding.Json.schema encoding in
    let v_schema_r = root v_schema in
    let kind =
      Object
        {
          properties =
            List.map
              (fun purpose ->
                (string_of_purpose purpose, v_schema_r, false, None))
              purposes;
          pattern_properties = [];
          additional_properties = None;
          min_properties = 0;
          max_properties = None;
          schema_dependencies = [];
          property_dependencies = [];
        }
    in
    update (element kind) v_schema
  in
  conv
    ~schema
    (fun map ->
      let fields =
        Operator_purpose_map.bindings map
        |> List.map (fun (p, v) ->
               (string_of_purpose p, Data_encoding.Json.construct encoding v))
      in
      `O fields)
    (function
      | `O fields ->
          List.map
            (fun (p, v) ->
              (purpose_of_string_exn p, Data_encoding.Json.destruct encoding v))
            fields
          |> List.to_seq |> Operator_purpose_map.of_seq
      | _ -> assert false)
    Data_encoding.Json.encoding

let operators_encoding =
  operator_purpose_map_encoding Signature.Public_key_hash.encoding

let fee_parameter_encoding =
  let open Data_encoding in
  conv
    (fun {
           Injection.minimal_fees;
           minimal_nanotez_per_byte;
           minimal_nanotez_per_gas_unit;
           force_low_fee;
           fee_cap;
           burn_cap;
         } ->
      ( minimal_fees,
        minimal_nanotez_per_byte,
        minimal_nanotez_per_gas_unit,
        force_low_fee,
        fee_cap,
        burn_cap ))
    (fun ( minimal_fees,
           minimal_nanotez_per_byte,
           minimal_nanotez_per_gas_unit,
           force_low_fee,
           fee_cap,
           burn_cap ) ->
      {
        minimal_fees;
        minimal_nanotez_per_byte;
        minimal_nanotez_per_gas_unit;
        force_low_fee;
        fee_cap;
        burn_cap;
      })
    (obj6
       (dft
          "minimal-fees"
          ~description:"Exclude operations with lower fees"
          Tez.encoding
          default_minimal_fees)
       (dft
          "minimal-nanotez-per-byte"
          ~description:"Exclude operations with lower fees per byte"
          Plugin.Mempool.nanotez_enc
          default_minimal_nanotez_per_byte)
       (dft
          "minimal-nanotez-per-gas-unit"
          ~description:"Exclude operations with lower gas fees"
          Plugin.Mempool.nanotez_enc
          default_minimal_nanotez_per_gas_unit)
       (dft
          "force-low-fee"
          ~description:
            "Don't check that the fee is lower than the estimated default"
          bool
          default_force_low_fee)
       (dft "fee-cap" ~description:"The fee cap" Tez.encoding default_fee_cap)
       (dft
          "burn-cap"
          ~description:"The burn cap"
          Tez.encoding
          default_burn_cap))

let modes = [Observer; Batcher; Maintenance; Operator; Custom]

let string_of_mode = function
  | Observer -> "observer"
  | Batcher -> "batcher"
  | Maintenance -> "maintenance"
  | Operator -> "operator"
  | Custom -> "custom"

let mode_of_string = function
  | "observer" -> Ok Observer
  | "batcher" -> Ok Batcher
  | "maintenance" -> Ok Maintenance
  | "operator" -> Ok Operator
  | "custom" -> Ok Custom
  | _ -> Error [Exn (Failure "Invalid mode")]

let description_of_mode = function
  | Observer -> "Only follows the chain, reconstructs and interprets inboxes"
  | Batcher ->
      "Accepts transactions in its queue and batches them on the L1 (TODO)"
  | Maintenance ->
      "Follows the chain and publishes commitments, cement and refute"
  | Operator -> "Equivalent to maintenance + batcher"
  | Custom ->
      "In this mode, only operations that have a corresponding operator/signer \
       are injected"

let mode_encoding =
  Data_encoding.string_enum
    [
      ("observer", Observer);
      ("batcher", Batcher);
      ("maintenance", Maintenance);
      ("operator", Operator);
      ("custom", Custom);
    ]

let encoding : t Data_encoding.t =
  let open Data_encoding in
  conv
    (fun {
           data_dir;
           sc_rollup_address;
           sc_rollup_node_operators;
           rpc_addr;
           rpc_port;
           reconnection_delay;
           fee_parameter;
           mode;
           loser_mode;
           dal_node_addr;
           dal_node_port;
         } ->
      ( ( data_dir,
          sc_rollup_address,
          sc_rollup_node_operators,
          rpc_addr,
          rpc_port,
          reconnection_delay,
          fee_parameter,
          mode,
          loser_mode ),
        (dal_node_addr, dal_node_port) ))
    (fun ( ( data_dir,
             sc_rollup_address,
             sc_rollup_node_operators,
             rpc_addr,
             rpc_port,
             reconnection_delay,
             fee_parameter,
             mode,
             loser_mode ),
           (dal_node_addr, dal_node_port) ) ->
      {
        data_dir;
        sc_rollup_address;
        sc_rollup_node_operators;
        rpc_addr;
        rpc_port;
        reconnection_delay;
        fee_parameter;
        mode;
        loser_mode;
        dal_node_addr;
        dal_node_port;
      })
    (merge_objs
       (obj9
          (dft
             "data-dir"
             ~description:"Location of the data dir"
             string
             default_data_dir)
          (req
             "sc-rollup-address"
             ~description:"Smart contract rollup address"
             Protocol.Alpha_context.Sc_rollup.Address.encoding)
          (req
             "sc-rollup-node-operator"
             ~description:
               "Operators that sign operations of the smart contract rollup, \
                by purpose"
             operators_encoding)
          (dft "rpc-addr" ~description:"RPC address" string default_rpc_addr)
          (dft "rpc-port" ~description:"RPC port" int16 default_rpc_port)
          (dft
             ~description:
               "The reconnection (to the tezos node) delay in seconds"
             "reconnection_delay"
             float
             default_reconnection_delay)
          (dft
             "fee-parameter"
             ~description:
               "The fee parameter used when injecting operations in L1"
             fee_parameter_encoding
             default_fee_parameter)
          (req
             ~description:"The mode for this rollup node"
             "mode"
             mode_encoding)
          (dft
             "loser-mode"
             ~description:
               "If enabled, the rollup node will issue wrong commitments (for \
                test only!)"
             Loser_mode.encoding
             Loser_mode.no_failures))
       (obj2
          (dft "DAL node address" string default_dal_node_addr)
          (dft "DAL node port" int16 default_dal_node_port)))

let check_mode config =
  let open Result_syntax in
  let check_purposes purposes =
    let missing_operators =
      List.filter
        (fun p ->
          not (Operator_purpose_map.mem p config.sc_rollup_node_operators))
        purposes
    in
    if missing_operators <> [] then
      let mode = string_of_mode config.mode in
      let missing_operators = List.map string_of_purpose missing_operators in
      tzfail
        (Sc_rollup_node_errors.Missing_mode_operators {mode; missing_operators})
    else return_unit
  in
  let narrow_purposes purposes =
    let+ () = check_purposes purposes in
    let sc_rollup_node_operators =
      Operator_purpose_map.filter
        (fun op_purpose _ -> List.mem ~equal:Stdlib.( = ) op_purpose purposes)
        config.sc_rollup_node_operators
    in
    {config with sc_rollup_node_operators}
  in
  match config.mode with
  | Observer -> narrow_purposes []
  | Batcher -> narrow_purposes [Add_messages]
  | Maintenance -> narrow_purposes [Publish; Cement; Refute]
  | Operator -> narrow_purposes [Publish; Cement; Add_messages; Refute]
  | Custom -> return config

let loser_warning_message config =
  if config.loser_mode <> Loser_mode.no_failures then
    Format.printf
      {|
************ WARNING *************
This rollup node is in loser mode.
This should be used for test only!
************ WARNING *************
|}

let save config =
  loser_warning_message config ;
  let open Lwt_syntax in
  let json = Data_encoding.Json.construct encoding config in
  let* () = Lwt_utils_unix.create_dir config.data_dir in
  Lwt_utils_unix.Json.write_file (filename config) json

let load ~data_dir =
  let open Lwt_result_syntax in
  let+ json = Lwt_utils_unix.Json.read_file (relative_filename data_dir) in
  let config = Data_encoding.Json.destruct encoding json in
  loser_warning_message config ;
  config
