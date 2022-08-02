(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
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

open Alpha_context

module Manager = struct
  type error +=
    | Manager_restriction of Signature.Public_key_hash.t * Operation_hash.t
    | Inconsistent_sources
    | Inconsistent_counters
    | Incorrect_reveal_position
    | Insufficient_gas_for_manager
    | Gas_quota_exceeded_init_deserialize
    | Tx_rollup_feature_disabled
    | Sc_rollup_feature_disabled

  let () =
    register_error_kind
      `Temporary
      ~id:"validate_operation.manager_restriction"
      ~title:"Manager restriction"
      ~description:
        "An operation with the same manager has already been validated in the \
         current block."
      ~pp:(fun ppf (d, hash) ->
        Format.fprintf
          ppf
          "Manager %a already has the operation %a in the current block."
          Signature.Public_key_hash.pp
          d
          Operation_hash.pp
          hash)
      Data_encoding.(
        obj2
          (req "manager" Signature.Public_key_hash.encoding)
          (req "hash" Operation_hash.encoding))
      (function
        | Manager_restriction (manager, hash) -> Some (manager, hash)
        | _ -> None)
      (fun (manager, hash) -> Manager_restriction (manager, hash)) ;
    let inconsistent_sources_description =
      "The operation batch includes operations from different sources."
    in
    register_error_kind
      `Permanent
      ~id:"validate_operation.inconsistent_sources"
      ~title:"Inconsistent sources in operation batch"
      ~description:inconsistent_sources_description
      ~pp:(fun ppf () ->
        Format.fprintf ppf "%s" inconsistent_sources_description)
      Data_encoding.empty
      (function Inconsistent_sources -> Some () | _ -> None)
      (fun () -> Inconsistent_sources) ;
    let inconsistent_counters_description =
      "Inconsistent counters in operation. Counters of an operation must be \
       successive."
    in
    register_error_kind
      `Permanent
      ~id:"validate_operation.inconsistent_counters"
      ~title:"Inconsistent counters in operation"
      ~description:inconsistent_counters_description
      ~pp:(fun ppf () ->
        Format.fprintf ppf "%s" inconsistent_counters_description)
      Data_encoding.empty
      (function Inconsistent_counters -> Some () | _ -> None)
      (fun () -> Inconsistent_counters) ;
    let incorrect_reveal_description =
      "Incorrect reveal operation position in batch: only allowed in first \
       position."
    in
    register_error_kind
      `Permanent
      ~id:"validate_operation.incorrect_reveal_position"
      ~title:"Incorrect reveal position"
      ~description:incorrect_reveal_description
      ~pp:(fun ppf () -> Format.fprintf ppf "%s" incorrect_reveal_description)
      Data_encoding.empty
      (function Incorrect_reveal_position -> Some () | _ -> None)
      (fun () -> Incorrect_reveal_position) ;
    register_error_kind
      `Permanent
      ~id:"validate_operation.insufficient_gas_for_manager"
      ~title:"Not enough gas for initial manager cost"
      ~description:
        (Format.asprintf
           "Gas limit is too low to cover the initial cost of manager \
            operations: at least %a gas required."
           Gas.pp_cost
           Michelson_v1_gas.Cost_of.manager_operation)
      Data_encoding.empty
      (function Insufficient_gas_for_manager -> Some () | _ -> None)
      (fun () -> Insufficient_gas_for_manager) ;
    let gas_deserialize_description =
      "Gas limit was not high enough to deserialize the transaction parameters \
       or origination script code or initial storage etc., making the \
       operation impossible to parse within the provided gas bounds."
    in
    register_error_kind
      `Permanent
      ~id:"validate_operation.gas_quota_exceeded_init_deserialize"
      ~title:"Not enough gas for initial deserialization of script expressions"
      ~description:gas_deserialize_description
      ~pp:(fun ppf () -> Format.fprintf ppf "%s" gas_deserialize_description)
      Data_encoding.empty
      (function Gas_quota_exceeded_init_deserialize -> Some () | _ -> None)
      (fun () -> Gas_quota_exceeded_init_deserialize) ;
    register_error_kind
      `Permanent
      ~id:"validate_operation.tx_rollup_is_disabled"
      ~title:"Tx rollup is disabled"
      ~description:"Cannot originate a tx rollup as it is disabled."
      ~pp:(fun ppf () ->
        Format.fprintf
          ppf
          "Cannot apply a tx rollup operation as it is disabled. This feature \
           will be enabled in a future proposal")
      Data_encoding.unit
      (function Tx_rollup_feature_disabled -> Some () | _ -> None)
      (fun () -> Tx_rollup_feature_disabled) ;
    let scoru_disabled_description =
      "Smart contract rollups will be enabled in a future proposal."
    in
    register_error_kind
      `Permanent
      ~id:"validate_operation.sc_rollup_disabled"
      ~title:"Smart contract rollups are disabled"
      ~description:scoru_disabled_description
      ~pp:(fun ppf () -> Format.fprintf ppf "%s" scoru_disabled_description)
      Data_encoding.unit
      (function Sc_rollup_feature_disabled -> Some () | _ -> None)
      (fun () -> Sc_rollup_feature_disabled)
end
