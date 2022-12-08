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

open Protocol
open Alpha_context
open Store_sigs
open Indexed_store

type state_info = {
  num_messages : Z.t;
  num_ticks : Z.t;
  initial_tick : Sc_rollup.Tick.t;
}

(** Extraneous state information for the PVM *)
module StateInfo :
  SIMPLE_INDEXED_FILE
    with type key := Tezos_crypto.Block_hash.t
     and type value := state_info
     and type header := unit

module StateHistoryRepr : sig
  type event = {
    tick : Sc_rollup.Tick.t;
    block_hash : Tezos_crypto.Block_hash.t;
    predecessor_hash : Tezos_crypto.Block_hash.t;
    level : Raw_level.t;
  }

  module TickMap : Map.S with type key := Sc_rollup.Tick.t

  type t = event TickMap.t
end

(** [StateHistory] represents storage for the PVM state history: it is an
    extension of [Store_utils.Mutable_value] whose values are lists of bindings
    indexed by PVM tick numbers, and whose value contains information about the
    block that the PVM was processing when generating the tick.
*)
module StateHistory : sig
  include SINGLETON_STORE with type value := StateHistoryRepr.t

  val insert : rw t -> StateHistoryRepr.event -> unit tzresult Lwt.t

  val event_of_largest_tick_before :
    [> `Read] t ->
    Sc_rollup.Tick.t ->
    StateHistoryRepr.event option tzresult Lwt.t
end

(** Storage for persisting messages downloaded from the L1 node, indexed by
    [Tezos_crypto.Block_hash.t]. *)
module Messages :
  SIMPLE_INDEXED_FILE
    with type key := Tezos_crypto.Block_hash.t
     and type value := Sc_rollup.Inbox_message.t list
     and type header := int

(** Aggregated collection of messages from the L1 inbox *)
module Inboxes :
  SIMPLE_INDEXED_FILE
    with type key := Tezos_crypto.Block_hash.t
     and type value := Sc_rollup.Inbox.t
     and type header := Raw_level.t

(** Histories from the rollup node. **)
module Histories :
  SIMPLE_INDEXED_FILE
    with type key := Tezos_crypto.Block_hash.t
     and type value := Sc_rollup.Inbox.History.t
     and type header := unit

(** messages histories from the rollup node. Each history contains the messages
    of one level. The store is indexed by a level in order to maintain a small
    structure in memory. Only the message history of one level is fetched when
    computing the proof. *)
module Payloads_histories :
  SIMPLE_INDEXED_FILE
    with type key := Sc_rollup.Inbox_merkelized_payload_hashes.Hash.t
     and type value := Sc_rollup.Inbox_merkelized_payload_hashes.History.t
     and type header := unit

(** Storage containing commitments and corresponding commitment hashes that the
    rollup node has knowledge of. *)
module Commitments :
  INDEXABLE_REMOVABLE_STORE
    with type key := Int32.t
     and type value := Sc_rollup.Commitment.t * Sc_rollup.Commitment.Hash.t

(** Storage containing the inbox level of the last commitment produced by the
    rollup node. *)
module Last_stored_commitment_level :
  SINGLETON_STORE with type value := Raw_level.t

(** Storage mapping commitment hashes to the level when they were published by
    the rollup node. It only contains hashes of commitments published by this
    rollup node. *)
module Commitments_published_at_level :
  INDEXABLE_REMOVABLE_STORE
    with type key := Sc_rollup.Commitment.Hash.t
     and type value := Int32.t

(** Storage containing the hashes of contexts retrieved from the L1 node. *)
module Contexts :
  INDEXABLE_STORE
    with type key := Tezos_crypto.Block_hash.t
     and type value := Context.hash

module Dal_slots : sig
  val max_slots : int

  include
    INDEXABLE_STORE
      with type key := Tezos_crypto.Block_hash.t
       and type value := Dal.Slot_index.t list
end

(** Published slot headers per block hash,
    stored as a list of bindings from [Dal_slot_index.t]
    to [Dal.Slot.t]. The encoding function converts this
    list into a [Dal.Slot_index.t]-indexed map. *)
module Dal_slot_headers :
  INDEXABLE_STORE
    with type key := Tezos_crypto.Block_hash.t * Dal.Slot_index.t
     and type value := Dal.Slot.Header.t

module Dal_confirmed_slots_history :
  SIMPLE_INDEXED_FILE
    with type key := Tezos_crypto.Block_hash.t
     and type value := Dal.Slots_history.t
     and type header := unit

(** Confirmed DAL slots histories cache. See documentation of
    {Dal_slot_repr.Slots_history} for more details. *)
module Dal_confirmed_slots_histories :
  SIMPLE_INDEXED_FILE
    with type key := Tezos_crypto.Block_hash.t
     and type value := Dal.Slots_history.History_cache.t
     and type header := unit

(** [Dal_slot_pages] is a [Store_utils.Nested_map] used to store the contents
    of dal slots fetched by the rollup node, as a list of pages. The values of
    this storage module have type `string list`. A value of the form
    [page_contents] refers to a page of a slot that has been confirmed, and
    whose contents are [page_contents].
*)
module Dal_slot_pages :
  SIMPLE_INDEXED_FILE
    with type key := Tezos_crypto.Block_hash.t * Dal.Slot_index.t
     and type value := Dal.Page.content list
     and type header := int

(** [Dal_processed_slots] is a [Store_utils.Nested_map] used to store the processing
    status of dal slots content fetched by the rollup node. The values of
    this storage module have type `[`Confirmed | `Unconfirmed]`, depending on
    whether the content of the slot has been confirmed or not. If an entry is
    not present for a [(block_hash, slot_index)], this either means that it's
    not processed yet.
*)
module Dal_processed_slots :
  INDEXABLE_STORE
    with type key := Tezos_crypto.Block_hash.t * Dal.Slot_index.t
     and type value := [`Confirmed | `Unconfirmed]

module Processed_blocks :
  INDEXABLE_REMOVABLE_STORE
    with type key := Tezos_crypto.Block_hash.t
     and type value := unit

module Head :
  SINGLETON_STORE with type value := Tezos_crypto.Block_hash.t * Int32.t

type +'a store = {
  stateinfo : 'a StateInfo.t;
  statehistory : 'a StateHistory.t;
  messages : 'a Messages.t;
  inboxes : 'a Inboxes.t;
  histories : 'a Histories.t;
  payloads_histories : 'a Payloads_histories.t;
  commitments : 'a Commitments.t;
  last_stored_commitment_level : 'a Last_stored_commitment_level.t;
  commitments_published_at_level : 'a Commitments_published_at_level.t;
  contexts : 'a Contexts.t;
  dal_slots : 'a Dal_slots.t;
  dal_slot_headers : 'a Dal_slot_headers.t;
  dal_slot_pages : 'a Dal_slot_pages.t;
  dal_processed_slots : 'a Dal_processed_slots.t;
  dal_confirmed_slots_history : 'a Dal_confirmed_slots_history.t;
  dal_confirmed_slots_histories : 'a Dal_confirmed_slots_histories.t;
  processed_blocks : 'a Processed_blocks.t;
  last_processed_head : 'a Head.t;
  last_finalized_head : 'a Head.t;
}

(** Type of store. The parameter indicates if the store can be written or only
    read. *)
type 'a t = ([< `Read | `Write > `Read] as 'a) store

(** Read/write store {!t}. *)
type rw = Store_sigs.rw t

(** Read only store {!t}. *)
type ro = Store_sigs.ro t

(** [close store] closes the store. *)
val close : _ t -> unit tzresult Lwt.t

(** [load mode directory] loads a store from the data persisted in [directory].*)
val load : 'a Store_sigs.mode -> string -> 'a store tzresult Lwt.t

(** [readonly store] returns a read-only version of [store]. *)
val readonly : _ t -> ro
