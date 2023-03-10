(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

(** This module defines benchmarks for the serialization of manager
   operations. Serializing an operation is required for checking its
   signature. The signature check is directly carbonated but the
   serialization is not; it is indirectly carbonated through the
   constant cost of any manager operation
   [Michelson_v1_gas.Cost_of.manager_operation]. These benchmarks are
   thus not used to infer any gas parameter in the protocol but only
   to check that this constant cost largely covers the ressources
   consumed for serialization (for operations whose length stays
   within the protocol limit
   [Constants_repr.max_operation_data_length]). *)

open Protocol
open Alpha_context

let ns = Namespace.make Registration_helpers.ns "operation"

let fv s = Free_variable.of_namespace (ns s)

module type MANAGER_OP_KIND_GEN = sig
  type kind

  val k : kind Kind.manager

  val bounded : bool
end

let serialize (op : _ operation) : bytes =
  let (Operation.Serialized_operation_for_check_signature bytes) =
    Operation.serialize_unsigned_operation op
  in
  bytes

let kind_to_string (type kind) (k : kind Kind.manager) =
  match k with
  | Kind.Reveal_manager_kind -> "reveal"
  | Kind.Transaction_manager_kind -> "transaction"
  | Kind.Origination_manager_kind -> "origination"
  | Kind.Delegation_manager_kind -> "delegation"
  | Kind.Event_manager_kind -> "event"
  | Kind.Register_global_constant_manager_kind -> "register_global_constant"
  | Kind.Set_deposits_limit_manager_kind -> "set_depostits_limit"
  | Kind.Increase_paid_storage_manager_kind -> "increase_paid_storage"
  | Kind.Update_consensus_key_manager_kind -> "update_consensus_key"
  | Kind.Transfer_ticket_manager_kind -> "transfer_ticket"
  | Kind.Dal_publish_slot_header_manager_kind -> "dal_publish_slot_header"
  | Kind.Sc_rollup_originate_manager_kind -> "sc_rollup_originate"
  | Kind.Sc_rollup_add_messages_manager_kind -> "sc_rollup_add_messages"
  | Kind.Sc_rollup_cement_manager_kind -> "sc_rollup_cement"
  | Kind.Sc_rollup_publish_manager_kind -> "sc_rollup_publish"
  | Kind.Sc_rollup_refute_manager_kind -> "sc_rollup_refute"
  | Kind.Sc_rollup_timeout_manager_kind -> "sc_rollup_timeout"
  | Kind.Sc_rollup_execute_outbox_message_manager_kind ->
      "sc_rollup_execute_outbox_message"
  | Kind.Sc_rollup_recover_bond_manager_kind -> "sc_rollup_recover_bond"
  | Kind.Zk_rollup_origination_manager_kind -> "zk_rollup_origination"
  | Kind.Zk_rollup_publish_manager_kind -> "zk_rollup_publish"
  | Kind.Zk_rollup_update_manager_kind -> "zk_rollup_update"

exception Unsupported_kind of string

let kind_to_gen_kind (type kind) (k : kind Kind.manager) =
  match k with
  | Kind.Reveal_manager_kind -> `KReveal (* size of pk *)
  | Kind.Transaction_manager_kind -> `KTransaction (* unbounded *)
  | Kind.Origination_manager_kind -> `KOrigination (* unbounded *)
  | Kind.Delegation_manager_kind -> `KDelegation (* fixed *)
  | Kind.Event_manager_kind ->
      (* There is no such thing as an event external operation; the
         event kind is probably a remainder from the past. *)
      raise (Unsupported_kind (kind_to_string k))
  | Kind.Register_global_constant_manager_kind ->
      `KRegister_global_constant (* unbounded bytes *)
  | Kind.Set_deposits_limit_manager_kind ->
      raise (Unsupported_kind (kind_to_string k)) (* unbounded N *)
  | Kind.Increase_paid_storage_manager_kind ->
      `KIncrease_paid_storage (* unbounded Z *)
  | Kind.Update_consensus_key_manager_kind ->
      raise (Unsupported_kind (kind_to_string k)) (* size of pk *)
  | Kind.Transfer_ticket_manager_kind -> `KTransfer_ticket (* unbounded *)
  | Kind.Dal_publish_slot_header_manager_kind ->
      `KDal_publish_slot_header (* fixed *)
  | Kind.Sc_rollup_originate_manager_kind ->
      `KSc_rollup_originate (* unbounded bytes *)
  | Kind.Sc_rollup_add_messages_manager_kind ->
      `KSc_rollup_add_messages (* unbounded string list *)
  | Kind.Sc_rollup_cement_manager_kind -> `KSc_rollup_cement (* fixed *)
  | Kind.Sc_rollup_publish_manager_kind -> `KSc_rollup_publish (* fixed *)
  | Kind.Sc_rollup_refute_manager_kind -> `KSc_rollup_refute (* ?? *)
  | Kind.Sc_rollup_timeout_manager_kind -> `KSc_rollup_timeout (* fixed *)
  | Kind.Sc_rollup_execute_outbox_message_manager_kind ->
      `KSc_rollup_execute_outbox_message (* unbounded bytes *)
  | Kind.Sc_rollup_recover_bond_manager_kind ->
      `KSc_rollup_recover_bond (* fixed *)
  | Kind.Zk_rollup_origination_manager_kind ->
      raise (Unsupported_kind (kind_to_string k))
  | Kind.Zk_rollup_publish_manager_kind ->
      raise (Unsupported_kind (kind_to_string k))
  | Kind.Zk_rollup_update_manager_kind ->
      raise (Unsupported_kind (kind_to_string k))

module Serializing_manager_operation (G : MANAGER_OP_KIND_GEN) : Benchmark.S =
struct
  let gen_kind = kind_to_gen_kind G.k

  let ns = Namespace.make ns "serialization"

  let name = ns (kind_to_string G.k)

  let info = "Benchmarking Operation_repr.serialize_unsigned_operation"

  type workload = {size : int; serialized_op : bytes; kind : string}

  let workload_encoding : workload Data_encoding.t =
    let open Data_encoding in
    conv
      (fun {size; serialized_op; kind} -> (size, serialized_op, kind))
      (fun (size, serialized_op, kind) -> {size; serialized_op; kind})
      (obj3 (req "size" int31) (req "serialized_op" bytes) (req "kind" string))

  let workload_to_vector {size; serialized_op = _; kind = _} =
    Sparse_vec.String.of_list [("size", float_of_int size)]

  type config = unit

  let config_encoding = Data_encoding.unit

  let default_config = ()

  let tags = [Tags.operation]

  let generate_operation =
    let open QCheck2.Gen in
    let* source = Operation_generator.random_pkh in
    Operation_generator.generator_of ~source gen_kind

  let make_bench rng_state () () =
    let {shell; protocol_data = Operation_data protocol_data} =
      QCheck2.Gen.generate1 ~rand:rng_state generate_operation
    in
    let op : _ operation = {shell; protocol_data} in
    let serialized_op = serialize op in
    let workload : workload =
      {
        size = Bytes.length serialized_op;
        serialized_op;
        kind = kind_to_string G.k;
      }
    in
    let closure () = ignore (Operation.serialize_unsigned_operation op) in
    Generator.Plain {workload; closure}

  let create_benchmarks ~rng_state ~bench_num config =
    List.repeat bench_num (make_bench rng_state config)

  let affine_model =
    Model.make
      ~conv:(fun {size; _} -> (size, ()))
      ~model:
        (Model.affine
           ~name:(ns (Namespace.basename name))
           ~intercept:
             (fv
                (Format.asprintf "%s_serialization_const" (kind_to_string G.k)))
           ~coeff:
             (fv
                (Format.asprintf "%s_serialization_coeff" (kind_to_string G.k))))

  let constant_model =
    Model.make
      ~conv:(fun _ -> ())
      ~model:
        (Model.unknown_const1
           ~name:(ns (Namespace.basename name))
           ~const:
             (fv
                (Format.asprintf "%s_serialization_const" (kind_to_string G.k))))

  let models =
    [
      ( "operation_serialization",
        if G.bounded then constant_model else affine_model );
    ]
end

let () =
  Registration_helpers.register
    (module Serializing_manager_operation (struct
      type kind = Kind.reveal

      let k = Kind.Reveal_manager_kind

      let bounded = true
    end))

let () =
  Registration_helpers.register
    (module Serializing_manager_operation (struct
      type kind = Kind.transaction

      let k = Kind.Transaction_manager_kind

      let bounded = false
    end))

let () =
  Registration_helpers.register
    (module Serializing_manager_operation (struct
      type kind = Kind.origination

      let k = Kind.Origination_manager_kind

      let bounded = false
    end))

let () =
  Registration_helpers.register
    (module Serializing_manager_operation (struct
      type kind = Kind.delegation

      let k = Kind.Delegation_manager_kind

      let bounded = true
    end))

(* let () =
 *   Registration_helpers.register
 *     (module Serializing_manager_operation (struct
 *       type kind = Kind.event
 * 
 *       let k = Kind.Event_manager_kind
 * 
 *       let bounded = false
 *     end)) *)

let () =
  Registration_helpers.register
    (module Serializing_manager_operation (struct
      type kind = Kind.register_global_constant

      let k = Kind.Register_global_constant_manager_kind

      let bounded = false
    end))

(* let () =
 *   Registration_helpers.register
 *     (module Serializing_manager_operation (struct
 *       type kind = Kind.set_deposits_limit
 * 
 *       let k = Kind.Set_deposits_limit_manager_kind
 * 
 *       let bounded = true
 *     end)) *)

let () =
  Registration_helpers.register
    (module Serializing_manager_operation (struct
      type kind = Kind.increase_paid_storage

      let k = Kind.Increase_paid_storage_manager_kind

      let bounded = true
    end))

(* let () =
 *   Registration_helpers.register
 *     (module Serializing_manager_operation (struct
 *       type kind = Kind.update_consensus_key
 * 
 *       let k = Kind.Update_consensus_key_manager_kind
 * 
 *       let bounded = true
 *     end)) *)

let () =
  Registration_helpers.register
    (module Serializing_manager_operation (struct
      type kind = Kind.transfer_ticket

      let k = Kind.Transfer_ticket_manager_kind

      let bounded = false
    end))

let () =
  Registration_helpers.register
    (module Serializing_manager_operation (struct
      type kind = Kind.dal_publish_slot_header

      let k = Kind.Dal_publish_slot_header_manager_kind

      let bounded = true
    end))

let () =
  Registration_helpers.register
    (module Serializing_manager_operation (struct
      type kind = Kind.sc_rollup_originate

      let k = Kind.Sc_rollup_originate_manager_kind

      let bounded = false
    end))

let () =
  Registration_helpers.register
    (module Serializing_manager_operation (struct
      type kind = Kind.sc_rollup_add_messages

      let k = Kind.Sc_rollup_add_messages_manager_kind

      let bounded = false
    end))

let () =
  Registration_helpers.register
    (module Serializing_manager_operation (struct
      type kind = Kind.sc_rollup_cement

      let k = Kind.Sc_rollup_cement_manager_kind

      let bounded = true
    end))

let () =
  Registration_helpers.register
    (module Serializing_manager_operation (struct
      type kind = Kind.sc_rollup_publish

      let k = Kind.Sc_rollup_publish_manager_kind

      let bounded = true
    end))

let () =
  Registration_helpers.register
    (module Serializing_manager_operation (struct
      type kind = Kind.sc_rollup_refute

      let k = Kind.Sc_rollup_refute_manager_kind

      let bounded = false
    end))

let () =
  Registration_helpers.register
    (module Serializing_manager_operation (struct
      type kind = Kind.sc_rollup_timeout

      let k = Kind.Sc_rollup_timeout_manager_kind

      let bounded = true
    end))

let () =
  Registration_helpers.register
    (module Serializing_manager_operation (struct
      type kind = Kind.sc_rollup_execute_outbox_message

      let k = Kind.Sc_rollup_execute_outbox_message_manager_kind

      let bounded = false
    end))

let () =
  Registration_helpers.register
    (module Serializing_manager_operation (struct
      type kind = Kind.sc_rollup_recover_bond

      let k = Kind.Sc_rollup_recover_bond_manager_kind

      let bounded = true
    end))

(* let () =
 *   Registration_helpers.register
 *     (module Serializing_manager_operation (struct
 *       type kind = Kind.zk_rollup_origination
 * 
 *       let k = Kind.Zk_rollup_origination_manager_kind
 * 
 *       let bounded = false
 *     end))
 * 
 * let () =
 *   Registration_helpers.register
 *     (module Serializing_manager_operation (struct
 *       type kind = Kind.zk_rollup_publish
 * 
 *       let k = Kind.Zk_rollup_publish_manager_kind
 * 
 *       let bounded = false
 *     end))
 * 
 * let () =
 *   Registration_helpers.register
 *     (module Serializing_manager_operation (struct
 *       type kind = Kind.zk_rollup_update
 * 
 *       let k = Kind.Zk_rollup_update_manager_kind
 * 
 *       let bounded = false
 *     end)) *)
