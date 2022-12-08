(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

open Protocol
include Store_sigs
include Store_utils

(** Aggregated collection of messages from the L1 inbox *)
open Alpha_context

module IStore = Irmin_store.Make (struct
  let name = "Tezos smart-contract rollup node"
end)

include Store_utils.Make (IStore)

type 'a store = 'a IStore.t

type 'a t = ([< `Read | `Write > `Read] as 'a) store

type rw = Store_sigs.rw t

type ro = Store_sigs.ro t

let close = IStore.close

let load = IStore.load

let readonly = IStore.readonly

type state_info = {
  num_messages : Z.t;
  num_ticks : Z.t;
  initial_tick : Sc_rollup.Tick.t;
}

(** Extraneous state information for the PVM *)
module StateInfo =
  Make_append_only_map
    (struct
      let path = ["state_info"]
    end)
    (struct
      type key = Tezos_crypto.Block_hash.t

      let to_path_representation = Tezos_crypto.Block_hash.to_b58check
    end)
    (struct
      type value = state_info

      let name = "state_info"

      let encoding =
        let open Data_encoding in
        conv
          (fun {num_messages; num_ticks; initial_tick} ->
            (num_messages, num_ticks, initial_tick))
          (fun (num_messages, num_ticks, initial_tick) ->
            {num_messages; num_ticks; initial_tick})
          (obj3
             (req "num_messages" Data_encoding.z)
             (req "num_ticks" Data_encoding.z)
             (req "initial_tick" Sc_rollup.Tick.encoding))
    end)

module StateHistoryRepr = struct
  type event = {
    tick : Sc_rollup.Tick.t;
    block_hash : Tezos_crypto.Block_hash.t;
    predecessor_hash : Tezos_crypto.Block_hash.t;
    level : Raw_level.t;
  }

  module TickMap = Map.Make (Sc_rollup.Tick)

  type value = event TickMap.t

  let event_encoding =
    let open Data_encoding in
    conv
      (fun {tick; block_hash; predecessor_hash; level} ->
        (tick, block_hash, predecessor_hash, level))
      (fun (tick, block_hash, predecessor_hash, level) ->
        {tick; block_hash; predecessor_hash; level})
      (obj4
         (req "tick" Sc_rollup.Tick.encoding)
         (req "block_hash" Tezos_crypto.Block_hash.encoding)
         (req "predecessor_hash" Tezos_crypto.Block_hash.encoding)
         (req "level" Raw_level.encoding))

  let name = "state_history"

  let encoding =
    let open Data_encoding in
    conv
      TickMap.bindings
      (fun bindings -> TickMap.of_seq (List.to_seq bindings))
      (Data_encoding.list (tup2 Sc_rollup.Tick.encoding event_encoding))
end

module StateHistory = struct
  include
    Make_mutable_value
      (struct
        let path = ["state_history"]
      end)
      (StateHistoryRepr)

  let insert store event =
    let open Lwt_result_syntax in
    let open StateHistoryRepr in
    let*! history = find store in
    let history =
      match history with
      | None -> StateHistoryRepr.TickMap.empty
      | Some history -> history
    in
    set store (TickMap.add event.tick event history)

  let event_of_largest_tick_before store tick =
    let open Lwt_result_syntax in
    let open StateHistoryRepr in
    let*! history = find store in
    match history with
    | None -> return_none
    | Some history -> (
        let events_before, opt_value, _ = TickMap.split tick history in
        match opt_value with
        | Some event -> return (Some event)
        | None ->
            return @@ Option.map snd @@ TickMap.max_binding_opt events_before)
end

(** Unaggregated messages per block *)
module Messages =
  Make_append_only_map
    (struct
      let path = ["messages"]
    end)
    (struct
      type key = Tezos_crypto.Block_hash.t

      let to_path_representation = Tezos_crypto.Block_hash.to_b58check
    end)
    (struct
      type value = Sc_rollup.Inbox_message.t list

      let name = "messages"

      let encoding =
        Data_encoding.(list @@ dynamic_size Sc_rollup.Inbox_message.encoding)
    end)

(** Inbox state for each block *)
module Inboxes =
  Make_append_only_map
    (struct
      let path = ["inboxes"]
    end)
    (struct
      type key = Tezos_crypto.Block_hash.t

      let to_path_representation = Tezos_crypto.Block_hash.to_b58check
    end)
    (struct
      type value = Sc_rollup.Inbox.t

      let name = "inbox"

      let encoding = Sc_rollup.Inbox.encoding
    end)

(** Message history for the inbox at a given block *)
module Histories =
  Make_append_only_map
    (struct
      let path = ["histories"]
    end)
    (struct
      type key = Tezos_crypto.Block_hash.t

      let to_path_representation = Tezos_crypto.Block_hash.to_b58check
    end)
    (struct
      type value = Sc_rollup.Inbox.History.t

      let name = "inbox_history"

      let encoding = Sc_rollup.Inbox.History.encoding
    end)

(** payloads history for the inbox at a given block *)
module Payloads_histories =
  Make_append_only_map
    (struct
      let path = ["payloads_histories"]
    end)
    (struct
      type key = Sc_rollup.Inbox_merkelized_payload_hashes.Hash.t

      let to_path_representation =
        Sc_rollup.Inbox_merkelized_payload_hashes.Hash.to_b58check
    end)
    (struct
      let name = "payloads_history"

      type value = Sc_rollup.Inbox_merkelized_payload_hashes.History.t

      let encoding = Sc_rollup.Inbox_merkelized_payload_hashes.History.encoding
    end)

module Commitments =
  Make_append_only_map
    (struct
      let path = ["commitments"; "computed"]
    end)
    (struct
      type key = Raw_level.t

      let to_path_representation key = Int32.to_string @@ Raw_level.to_int32 key
    end)
    (struct
      type value = Sc_rollup.Commitment.t * Sc_rollup.Commitment.Hash.t

      let name = "commitment_with_hash"

      let encoding =
        Data_encoding.(
          obj2
            (req "commitment" Sc_rollup.Commitment.encoding)
            (req "hash" Sc_rollup.Commitment.Hash.encoding))
    end)

module Last_stored_commitment_level =
  Make_mutable_value
    (struct
      let path = ["commitments"; "last_stored_level"]
    end)
    (struct
      type value = Raw_level.t

      let name = "raw_level"

      let encoding = Raw_level.encoding
    end)

module Last_published_commitment_level =
  Make_mutable_value
    (struct
      let path = ["commitments"; "last_published_level"]
    end)
    (struct
      type value = Raw_level.t

      let name = "raw_level"

      let encoding = Raw_level.encoding
    end)

module Commitments_published_at_level =
  Make_updatable_map
    (struct
      let path = ["commitments"; "published_at_level"]
    end)
    (struct
      type key = Sc_rollup.Commitment.Hash.t

      let to_path_representation = Sc_rollup.Commitment.Hash.to_b58check
    end)
    (struct
      type value = Raw_level.t

      let name = "raw_level"

      let encoding = Raw_level.encoding
    end)

module Contexts =
  Make_append_only_map
    (struct
      let path = ["contexts"]
    end)
    (struct
      type key = Tezos_crypto.Block_hash.t

      let to_path_representation = Tezos_crypto.Block_hash.to_b58check
    end)
    (struct
      type value = Context.hash

      let name = "context"

      let encoding = Context.hash_encoding
    end)

(* Published slot headers per block hash,
   stored as a list of bindings from `Dal_slot_index.t`
   to `Dal.Slot.t`. The encoding function converts this
   list into a `Dal.Slot_index.t`-indexed map. *)
module Dal_slot_pages =
  Make_nested_map
    (struct
      let path = ["dal"; "slot_pages"]
    end)
    (struct
      type key = Tezos_crypto.Block_hash.t

      let to_path_representation = Tezos_crypto.Block_hash.to_b58check
    end)
    (struct
      type key = Dal.Slot_index.t * Dal.Page.Index.t

      let encoding =
        Data_encoding.(tup2 Dal.Slot_index.encoding Dal.Page.Index.encoding)

      let compare (i1, p1) (i2, p2) =
        Compare.or_else (Dal.Slot_index.compare i1 i2) (fun () ->
            Dal.Page.Index.compare p1 p2)

      let name = "slot_index"
    end)
    (struct
      type value = Dal.Page.content

      let encoding = Dal.Page.content_encoding

      let name = "slot_pages"
    end)

(** stores slots whose data have been considered and pages stored to disk (if
    they are confirmed). *)
module Dal_processed_slots =
  Make_nested_map
    (struct
      let path = ["dal"; "processed_slots"]
    end)
    (struct
      type key = Tezos_crypto.Block_hash.t

      let to_path_representation = Tezos_crypto.Block_hash.to_b58check
    end)
    (struct
      type key = Dal.Slot_index.t

      let encoding = Dal.Slot_index.encoding

      let compare = Dal.Slot_index.compare

      let name = "slot_index"
    end)
    (struct
      type value = [`Confirmed | `Unconfirmed]

      let name = "slot_processing_status"

      let encoding =
        let open Data_encoding in
        let mk_case constr ~tag ~title =
          case
            ~title
            (Tag tag)
            (obj1 (req "kind" (constant title)))
            (fun x -> if x = constr then Some () else None)
            (fun () -> constr)
        in
        union
          ~tag_size:`Uint8
          [
            mk_case `Confirmed ~tag:0 ~title:"Confirmed";
            mk_case `Unconfirmed ~tag:1 ~title:"Unconfirmed";
          ]
    end)

module Dal_slots_headers =
  Make_nested_map
    (struct
      let path = ["dal"; "slot_headers"]
    end)
    (struct
      type key = Tezos_crypto.Block_hash.t

      let to_path_representation = Tezos_crypto.Block_hash.to_b58check
    end)
    (struct
      type key = Dal.Slot_index.t

      let encoding = Dal.Slot_index.encoding

      let compare = Dal.Slot_index.compare

      let name = "slot_index"
    end)
    (struct
      type value = Dal.Slot.Header.t

      let name = "slot_header"

      let encoding = Dal.Slot.Header.encoding
    end)

(* Published slot headers per block hash, stored as a list of bindings from
   `Dal_slot_index.t` to `Dal.Slot.t`. The encoding function converts this
   list into a `Dal.Slot_index.t`-indexed map. Note that the block_hash
   refers to the block where slots headers have been confirmed, not
   the block where they have been published.
*)

(** Confirmed DAL slots history. See documentation of
    {Dal_slot_repr.Slots_history} for more details. *)
module Dal_confirmed_slots_history =
  Make_append_only_map
    (struct
      let path = ["dal"; "confirmed_slots_history"]
    end)
    (struct
      type key = Tezos_crypto.Block_hash.t

      let to_path_representation = Tezos_crypto.Block_hash.to_b58check
    end)
    (struct
      type value = Dal.Slots_history.t

      let name = "dal_slot_histories"

      let encoding = Dal.Slots_history.encoding
    end)

(** Confirmed DAL slots histories cache. See documentation of
    {Dal_slot_repr.Slots_history} for more details. *)
module Dal_confirmed_slots_histories =
  Make_append_only_map
    (struct
      let path = ["dal"; "confirmed_slots_histories_cache"]
    end)
    (struct
      type key = Tezos_crypto.Block_hash.t

      let to_path_representation = Tezos_crypto.Block_hash.to_b58check
    end)
    (struct
      type value = Dal.Slots_history.History_cache.t

      let name = "dal_slot_history_cache"

      let encoding = Dal.Slots_history.History_cache.encoding
    end)
