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

(* DAL/FIXME https://gitlab.com/tezos/tezos/-/issues/3103

   This may be a bit heavy in practice. We could also assume that in
   practice, this bitfield will contain many bits to one. Hence, we
   could consider a better encoding which is smaller in the optimistic
   case. For example:

   1. When all the slots are endorsed, the encoding can be represented
   in one bit.

   2. Otherwise, we can pack slots by [8]. Have a header of [slots/8]
   which is [1] if all the slots in this set are [1], [0]
   otherwise. For all pack with a bit set to [0], we give the explicit
   representation. Hence, if there are [256] slots, and [2] are not
   endorsed, this representation will be of size [32] bits + [16] bits
   = [48] bits which is better than [256] bits. *)

module Slot_index = Dal_slot_repr.Index
module Shard_index = Dal_shard_repr.Index

type t = Slot_indices of Bitset.t

type available_slots = t

let encoding =
  Data_encoding.(
    conv
      (fun (Slot_indices bitset) -> bitset)
      (fun bitset -> Slot_indices bitset)
      Bitset.encoding)

let empty = Slot_indices Bitset.empty

let mem (Slot_indices available_slots) slot_index =
  Bitset.mem available_slots (Slot_index.to_int slot_index)

let is_available available_slots index =
  match mem available_slots index with
  | Ok b -> b
  | Error _ ->
      (* DAL/FIXME https://gitlab.com/tezos/tezos/-/issues/3104

         Should we do something here? *)
      false

let add (Slot_indices available_slots) slot_index =
  let res = Bitset.add available_slots (Slot_index.to_int slot_index) in
  Result.map (fun res -> Slot_indices res) res

let commit available_slots slot_index =
  match add available_slots slot_index with
  | Ok available_slots -> available_slots
  | Error _ ->
      (* DAL/FIXME https://gitlab.com/tezos/tezos/-/issues/3104

         Should we do something here? *)
      available_slots

let occupied_size_in_bits (Slot_indices bitset) =
  Bitset.occupied_size_in_bits bitset

let expected_size_in_bits ~max_index =
  (* We compute an encoding of the data-availability endorsements
     which is a (tight) upper bound of what we expect. *)
  let open Bitset in
  let open Dal_slot_repr.Index in
  match add empty @@ to_int max_index with
  | Error _ -> (* Happens if max_index < 1 *) 0
  | Ok t -> occupied_size_in_bits t

module Accountability = struct
  (* DAL/FIXME https://gitlab.com/tezos/tezos/-/issues/3109

     Think hard about this data structure and whether it needs to be
     optimized.
  *)

  type shard_index_set = Shard_indices of Bitset.t

  let add_shard_index (Shard_indices shard_index_set) shard_index =
    Bitset.add shard_index_set (Dal_shard_repr.Index.to_int shard_index)
    |> function
    | Ok bitset -> Ok (Shard_indices bitset)
    | Error e -> Error e

  let is_shard_available (Shard_indices shard_index_set) shard_index =
    Bitset.mem shard_index_set (Dal_shard_repr.Index.to_int shard_index)

  module Slot_index_map = Map.Make (Dal_slot_repr.Index)

  type t = shard_index_set Slot_index_map.t

  let init ~length =
    if Compare.Int.(length = 0) then Slot_index_map.empty
    else
      let max_index = Dal_slot_repr.Index.of_int (length - 1) in
      match max_index with
      | None ->
          invalid_arg
            "Dal_endorsement_repr.Accountability.init: length cannot be \
             negative or above hard limit of slots"
      | Some max_index ->
          let seq =
            Dal_slot_repr.Index.(zero --> max_index)
            |> List.map (fun index -> (index, Shard_indices Bitset.empty))
            |> List.to_seq
          in
          Slot_index_map.add_seq seq Slot_index_map.empty

  let record_slot_shard_availability bitset shards =
    List.fold_left
      (fun bitset shard ->
        add_shard_index bitset shard |> Result.value ~default:bitset)
      bitset
      shards

  let record_shards_availability (shard_indices_per_slot : t) slots shards =
    Slot_index_map.bindings shard_indices_per_slot
    |> List.map (fun (slot_index, shard_indices_for_slot) ->
           match mem slots slot_index with
           | Error _ ->
               (* slot index is above the length provided at initialisation *)
               (slot_index, shard_indices_for_slot)
           | Ok slot_available ->
               if slot_available then
                 ( slot_index,
                   record_slot_shard_availability shard_indices_for_slot shards
                 )
               else (slot_index, shard_indices_for_slot))
    |> List.to_seq |> Slot_index_map.of_seq

  let is_slot_available (shard_bitset_per_slot : t) ~threshold ~number_of_shards
      index =
    match Dal_shard_repr.Index.of_int (number_of_shards - 1) with
    | None ->
        invalid_arg
          "Dal_endorsement_repr.Accountability.is_slot_available: \
           number_of_shards cannot be negative or above hard limit of shards"
    | Some max_shard_index -> (
        match Slot_index_map.find index shard_bitset_per_slot with
        | None -> false
        | Some shard_index_set ->
            let acc = ref 0 in
            List.iter
              (fun x ->
                match is_shard_available shard_index_set x with
                | Error _ | Ok false -> ()
                | Ok true -> incr acc)
              Dal_shard_repr.Index.(zero --> max_shard_index) ;
            Compare.Int.(!acc >= threshold * number_of_shards / 100))
end
