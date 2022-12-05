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

include Services_legacy
open Tezos_crypto_dal

type 'rpc service =
  ('meth, 'prefix, 'params, 'query, 'input, 'output) Tezos_rpc.Service.service
  constraint
    'rpc =
    < meth : 'meth
    ; prefix : 'prefix
    ; params : 'params
    ; query : 'query
    ; input : 'input
    ; output : 'output >

module Types = struct
  type level = int32

  type slot_index = int

  (* Declaration of types used as inputs and/or outputs *)
  type slot_id = {slot_level : level; slot_index : slot_index}

  type header_attestation_status =
    [`Waiting_for_attestations | `Attested | `Unattested]

  type header_status = [`Not_selected | `Unseen | header_attestation_status]

  let header_attestation_status_to_string = function
    | `Waiting_for_attestations -> "waiting_for_attestations"
    | `Attested -> "attested"
    | `Unattested -> "unattested"

  let header_status_to_string = function
    | `Not_selected -> "not_selected"
    | `Unseen -> "unseen"
    | #header_attestation_status as e -> header_attestation_status_to_string e

  let slot_id_encoding =
    (* TODO: https://gitlab.com/tezos/tezos/-/issues/4396
        Reuse protocol encodings. *)
    let open Data_encoding in
    conv
      (fun {slot_level; slot_index} -> (slot_level, slot_index))
      (fun (slot_level, slot_index) -> {slot_level; slot_index})
      (obj2 (req "slot_level" int32) (req "slot_index" uint8))

  let slot_content = Data_encoding.bytes
end

let post_slots :
    < meth : [`POST]
    ; input : Cryptobox.slot
    ; output : Cryptobox.commitment
    ; prefix : unit
    ; params : unit
    ; query : unit >
    service =
  Tezos_rpc.Service.post_service
    ~description:
      "Add a slot in the node's context if not already present. The \
       corresponding commitment is returned."
    ~query:Tezos_rpc.Query.empty
    ~input:Types.slot_content
    ~output:Cryptobox.Commitment.encoding
    Tezos_rpc.Path.(open_root / "slots")

let patch_slot :
    < meth : [`PATCH]
    ; input : Types.slot_id
    ; output : unit
    ; prefix : unit
    ; params : unit * Cryptobox.commitment
    ; query : unit >
    service =
  Tezos_rpc.Service.patch_service
    ~description:"Associate a commitment to a level and a slot index."
    ~query:Tezos_rpc.Query.empty
    ~input:Types.slot_id_encoding
    ~output:Data_encoding.unit
    Tezos_rpc.Path.(open_root / "slots" /: Cryptobox.Commitment.rpc_arg)

let get_slot :
    < meth : [`GET]
    ; input : unit
    ; output : Cryptobox.slot
    ; prefix : unit
    ; params : unit * Cryptobox.commitment
    ; query : unit >
    service =
  Tezos_rpc.Service.get_service
    ~description:
      "Retrieve the content of the slot associated with the given commitment."
    ~query:Tezos_rpc.Query.empty
    ~output:Types.slot_content
    Tezos_rpc.Path.(open_root / "slots" /: Cryptobox.Commitment.rpc_arg)

let get_slot_commitment_proof :
    < meth : [`GET]
    ; input : unit
    ; output : Cryptobox.commitment_proof
    ; prefix : unit
    ; params : unit * Cryptobox.commitment
    ; query : unit >
    service =
  Tezos_rpc.Service.get_service
    ~description:"Compute the proof associated with a commitment"
    ~query:Tezos_rpc.Query.empty
    ~output:Cryptobox.Commitment_proof.encoding
    Tezos_rpc.Path.(
      open_root / "slots" /: Cryptobox.Commitment.rpc_arg / "proof")

let get_slot_level_index_commitment :
    < meth : [`GET]
    ; input : unit
    ; output : Cryptobox.commitment
    ; prefix : unit
    ; params : (unit * Types.level) * Types.slot_index
    ; query : unit >
    service =
  Tezos_rpc.Service.get_service
    ~description:
      "Retrieve the content of the slot associated with the given commitment."
    ~query:Tezos_rpc.Query.empty
    ~output:Cryptobox.Commitment.encoding
    Tezos_rpc.Path.(
      open_root / "slots" / "level" /: Tezos_rpc.Arg.int32 / "slot_index"
      /: Tezos_rpc.Arg.int)
