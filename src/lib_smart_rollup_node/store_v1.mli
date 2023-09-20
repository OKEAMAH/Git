(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2023 Functori, <contact@functori.com>                       *)
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

(** This version of the store is used for the rollup nodes for protocols for and
    after Nairobi, i.e. >= 17. *)

open Indexed_store

include module type of struct
  include Store_v0
end

(** Storage for persisting messages downloaded from the L1 node. *)
module Messages :
  INDEXED_FILE
    with type key := Merkelized_payload_hashes_hash.t
     and type value := string list
     and type header := bool * Block_hash.t * Time.Protocol.t * int

module Dal_pages : sig
  type removed_in_v1
end

module Dal_processed_slots : sig
  type removed_in_v1
end

(** [Dal_slots_statuses] is a [Store_utils.Nested_map] used to store the
    attestation status of DAL slots. The values of this storage module have type
    `[`Confirmed | `Unconfirmed]`, depending on whether the content of the slot
    has been attested on L1 or not. If an entry is not present for a
    [(block_hash, slot_index)], this means that the corresponding block is not
    processed yet.
*)
module Dal_slots_statuses :
  Store_sigs.Nested_map
    with type primary_key := Block_hash.t
     and type secondary_key := Dal.Slot_index.t
     and type value := [`Confirmed | `Unconfirmed]
     and type 'a store := 'a Irmin_store.t

type +'a store = {
  l2_blocks : 'a L2_blocks.t;
  messages : 'a Messages.t;
  inboxes : 'a Inboxes.t;
  commitments : 'a Commitments.t;
  commitments_published_at_level : 'a Commitments_published_at_level.t;
  l2_head : 'a L2_head.t;
  last_finalized_level : 'a Last_finalized_level.t;
  levels_to_hashes : 'a Levels_to_hashes.t;
  irmin_store : 'a Irmin_store.t;
}

include Store_sig.S with type 'a store := 'a store
