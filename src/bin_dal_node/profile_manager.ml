(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Marigold <contact@marigold.dev>                        *)
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

module Slot_set = Set.Make (Int)
module Pkh_set = Signature.Public_key_hash.Set

(** The set of slots tracked by the slot producer profile and pkh tracked by the attestor.
    Uses a set to remove duplicates in the profiles provided by the user. *)
type operator_sets = {producers : Slot_set.t; attestors : Pkh_set.t}

(** A profile context stores profile-specific data used by the daemon.  *)
type t = Bootstrap | Operator of operator_sets

let empty = Operator {producers = Slot_set.empty; attestors = Pkh_set.empty}

let bootstrap_profile = Bootstrap

let init_attestor operator_sets number_of_slots gs_worker pkh =
  if Pkh_set.mem pkh operator_sets.attestors then operator_sets
  else (
    List.iter
      (fun slot_index ->
        Join Gossipsub.{slot_index; pkh}
        |> Gossipsub.Worker.(app_input gs_worker))
      Utils.Infix.(0 -- (number_of_slots - 1)) ;
    {operator_sets with attestors = Pkh_set.add pkh operator_sets.attestors})

let init_producer operator_sets slot_index =
  {
    operator_sets with
    producers = Slot_set.add slot_index operator_sets.producers;
  }

let add_operator_profiles t proto_parameters gs_worker
    (operator_profiles : Services.Types.operator_profiles) =
  match t with
  | Bootstrap -> None
  | Operator operator_sets ->
      let operator_sets =
        List.fold_left
          (fun operator_sets operator ->
            match operator with
            | Services.Types.Attestor pkh ->
                init_attestor
                  operator_sets
                  proto_parameters.Dal_plugin.number_of_slots
                  gs_worker
                  pkh
            | Producer {slot_index} -> init_producer operator_sets slot_index)
          operator_sets
          operator_profiles
      in
      Some (Operator operator_sets)

let validate_slot_indexes t ~number_of_slots =
  let open Result_syntax in
  match t with
  | Bootstrap -> return_unit
  | Operator o -> (
      match
        Slot_set.find_first (fun i -> i < 0 || i >= number_of_slots) o.producers
      with
      | Some slot_index ->
          tzfail (Errors.Invalid_slot_index {slot_index; number_of_slots})
      | None -> return_unit)

(* TODO https://gitlab.com/tezos/tezos/-/issues/5934
   We need a mechanism to ease the tracking of newly added/removed topics. *)
let join_topics_for_producer gs_worker committee producers =
  Slot_set.iter
    (fun slot_index ->
      Signature.Public_key_hash.Map.iter
        (fun pkh _shards ->
          let topic = Gossipsub.{slot_index; pkh} in
          if not (Gossipsub.Worker.is_subscribed gs_worker topic) then
            Join topic |> Gossipsub.Worker.(app_input gs_worker))
        committee)
    producers

(* FIXME: https://gitlab.com/tezos/tezos/-/issues/5934
   We need a mechanism to ease the tracking of newly added/removed topics.
   Especially important for bootstrap nodes as the cross product can grow quite large. *)
let join_topics_for_bootstrap proto_parameters gs_worker committee =
  (* Join topics for all combinations of (all slots) * (all pkh in comittee) *)
  for slot_index = 0 to proto_parameters.Dal_plugin.number_of_slots - 1 do
    Signature.Public_key_hash.Map.iter
      (fun pkh _shards ->
        let topic = Gossipsub.{slot_index; pkh} in
        if not (Gossipsub.Worker.is_subscribed gs_worker topic) then
          Join topic |> Gossipsub.Worker.(app_input gs_worker))
      committee
  done

let on_new_head t proto_parameters gs_worker committee =
  match t with
  | Bootstrap -> join_topics_for_bootstrap proto_parameters gs_worker committee
  | Operator {producers; attestors = _} ->
      join_topics_for_producer gs_worker committee producers

let get_profiles t =
  match t with
  | Bootstrap -> Services.Types.Bootstrap
  | Operator {producers; attestors} ->
      let producer_profiles =
        Slot_set.fold
          (fun slot_index acc -> Services.Types.Producer {slot_index} :: acc)
          producers
          []
      in
      let attestor_profiles =
        Pkh_set.fold
          (fun pkh acc -> Services.Types.Attestor pkh :: acc)
          attestors
          producer_profiles
      in
      Services.Types.Operator (attestor_profiles @ producer_profiles)

let get_attestable_slots ~shard_indices store proto_parameters ~attested_level =
  let open Lwt_result_syntax in
  let expected_number_of_shards = List.length shard_indices in
  if expected_number_of_shards = 0 then return Services.Types.Not_in_committee
  else
    let published_level =
      (* FIXME: https://gitlab.com/tezos/tezos/-/issues/4612
         Correctly compute [published_level] in case of protocol changes, in
         particular a change of the value of [attestation_lag]. *)
      Int32.(
        sub attested_level (of_int proto_parameters.Dal_plugin.attestation_lag))
    in
    let are_shards_stored slot_index =
      let*! r =
        Slot_manager.get_commitment_by_published_level_and_index
          ~level:published_level
          ~slot_index
          store
      in
      let open Errors in
      match r with
      | Error `Not_found -> return false
      | Error (#decoding as e) -> fail (e :> [Errors.decoding | Errors.other])
      | Ok commitment ->
          Store.Shards.are_shards_available
            store.shard_store
            commitment
            shard_indices
          |> Errors.other_lwt_result
    in
    let all_slot_indexes =
      Utils.Infix.(0 -- (proto_parameters.number_of_slots - 1))
    in
    let* flags = List.map_es are_shards_stored all_slot_indexes in
    return (Services.Types.Attestable_slots {slots = flags; published_level})
