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
open Alpha_context

module Empty_header = struct
  type t = unit

  let name = "empty"

  let encoding = Data_encoding.unit

  let fixed_size = 0
end

module Add_empty_header = struct
  module Header = Empty_header

  let header _ = ()
end

module Make_hash_index_key (H : Environment.S.HASH) =
Indexed_store.Make_index_key (struct
  include Indexed_store.Make_fixed_encodable (H)

  let equal = H.equal
end)

module Make_fixed_index_key (E : sig
  include Indexed_store.ENCODABLE_VALUE

  val equal : t -> t -> bool
end) =
Indexed_store.Make_index_key (struct
  include Indexed_store.Make_fixed_encodable (E)

  let equal = E.equal
end)

type state_info = {
  num_messages : Z.t;
  num_ticks : Z.t;
  initial_tick : Sc_rollup.Tick.t;
}

(** Extraneous state information for the PVM *)
module StateInfo =
  Indexed_store.Make_simple_indexed_file
    (struct
      let name = "state_info"
    end)
    (Tezos_store_shared.Block_key)
    (struct
      type t = state_info

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

      include Add_empty_header
    end)

module StateHistoryRepr = struct
  type event = {
    tick : Sc_rollup.Tick.t;
    block_hash : Tezos_crypto.Block_hash.t;
    predecessor_hash : Tezos_crypto.Block_hash.t;
    level : Raw_level.t;
  }

  module TickMap = Map.Make (Sc_rollup.Tick)

  type t = event TickMap.t

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

(* FIXME: inefficient *)
module StateHistory = struct
  include Indexed_store.Make_singleton (StateHistoryRepr)

  let insert (store : rw t) event =
    let open Lwt_result_syntax in
    let open StateHistoryRepr in
    let* history = read store in
    let history =
      match history with
      | None -> StateHistoryRepr.TickMap.empty
      | Some history -> history
    in
    write store (TickMap.add event.tick event history)

  let event_of_largest_tick_before store tick =
    let open Lwt_result_syntax in
    let open StateHistoryRepr in
    let* history = read store in
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
  Indexed_store.Make_simple_indexed_file
    (struct
      let name = "messages"
    end)
    (Tezos_store_shared.Block_key)
    (struct
      type t = Sc_rollup.Inbox_message.t list

      let name = "messages"

      let encoding =
        Data_encoding.(list @@ dynamic_size Sc_rollup.Inbox_message.encoding)

      module Header = Indexed_store.Make_fixed_encodable (struct
        type t = int

        let name = "number_of_messages"

        let encoding = Data_encoding.int31
      end)

      let header = List.length
    end)

(** Inbox state for each block *)
module Inboxes =
  Indexed_store.Make_simple_indexed_file
    (struct
      let name = "inboxes"
    end)
    (Tezos_store_shared.Block_key)
    (struct
      type t = Sc_rollup.Inbox.t

      let name = "inbox"

      let encoding = Sc_rollup.Inbox.encoding

      module Header = Indexed_store.Make_fixed_encodable (struct
        type t = Raw_level.t

        let name = "inbox_level"

        let encoding = Raw_level.encoding
      end)

      let header = Sc_rollup.Inbox.inbox_level
    end)

(** Message history for the inbox at a given block *)
module Histories =
  (* FIXME: inefficient, keep history skip list in map instead *)
    Indexed_store.Make_simple_indexed_file
      (struct
        let name = "histories"
      end)
      (Tezos_store_shared.Block_key)
    (struct
      include Sc_rollup.Inbox.History

      let name = "inbox_history"

      include Add_empty_header
    end)

(** payloads history for the inbox at a given block *)
module Payloads_histories =
  (* FIXME: inefficient, recompute in proof production payload history instead *)
    Indexed_store.Make_simple_indexed_file
      (struct
        let name = "payloads_histories"
      end)
      (Make_hash_index_key (Sc_rollup.Inbox_merkelized_payload_hashes.Hash))
    (struct
      include Sc_rollup.Inbox_merkelized_payload_hashes.History

      let name = "payloads_history"

      include Add_empty_header
    end)

module Commitments =
  Indexed_store.Make_indexable_removable
    (struct
      let name = "commitments"
    end)
    (Tezos_store_shared.Block_level)
    (Indexed_store.Make_index_value (Indexed_store.Make_fixed_encodable (struct
      type t = Sc_rollup.Commitment.t * Sc_rollup.Commitment.Hash.t

      let name = "commitment_with_hash"

      let encoding =
        Data_encoding.(
          obj2
            (req "commitment" Sc_rollup.Commitment.encoding)
            (req "hash" Sc_rollup.Commitment.Hash.encoding))
    end)))

module Last_stored_commitment_level = Indexed_store.Make_singleton (struct
  type t = Raw_level.t

  let name = "last_stored_commitment_level"

  let encoding = Raw_level.encoding
end)

module Commitments_published_at_level =
  Indexed_store.Make_indexable_removable
    (struct
      let name = "commitments_published_at_level"
    end)
    (Make_hash_index_key (Sc_rollup.Commitment.Hash))
    (Tezos_store_shared.Block_level)

module Contexts =
  Indexed_store.Make_indexable
    (struct
      let name = "contexts"
    end)
    (Tezos_store_shared.Block_key)
    (Indexed_store.Make_index_value (Indexed_store.Make_fixed_encodable (struct
      type t = Context.hash

      let name = "context_hash"

      let encoding = Context.hash_encoding
    end)))

module Block_slot_key = Make_fixed_index_key (struct
  type t = Tezos_crypto.Block_hash.t * Dal.Slot_index.t

  let name = "block_slot_index"

  let encoding =
    let open Data_encoding in
    obj2
      (req "block" Tezos_crypto.Block_hash.encoding)
      (req "slot" Dal.Slot_index.encoding)

  let equal (b1, s1) (b2, s2) = s1 = s2 && Tezos_crypto.Block_hash.(b1 = b2)
end)

module Dal_slots = struct
  let max_slots = 256

  include
    Indexed_store.Make_indexable
      (struct
        let name = "dal_slots"
      end)
      (Tezos_store_shared.Block_key)
      (Indexed_store.Make_index_value (struct
        type t = Dal.Slot_index.t list

        let name = "slots_bitset"

        let encoding =
          let open Data_encoding in
          conv
            (fun l ->
              let buffer = Bytes.make max_slots '\000' in
              match Bitset.from_list (List.map Dal.Slot_index.to_int l) with
              | Error _ -> assert false
              | Ok b ->
                  let bits = Z.to_bits (Bitset.Internal_for_tests.to_z b) in
                  let len = Bitset.occupied_size_in_bits b in
                  assert (len <= max_slots) ;
                  Bytes.blit_string bits 0 buffer 0 len ;
                  buffer)
            (fun b ->
              let bitset =
                (Obj.magic (Z.of_bits (Bytes.unsafe_to_string b)) : Bitset.t)
              in
              let max = Bitset.occupied_size_in_bits bitset in
              List.fold_left
                (fun acc i ->
                  if
                    WithExceptions.Result.get_ok
                      ~loc:__LOC__
                      (Bitset.mem bitset i)
                  then
                    WithExceptions.Option.get
                      ~loc:__LOC__
                      (Dal.Slot_index.of_int i)
                    :: acc
                  else acc)
                []
                (0 -- max))
            Fixed.(bytes max_slots)

        let fixed_size = max_slots
      end))
end

(* Published slot headers per block hash,
   stored as a list of bindings from `Dal_slot_index.t`
   to `Dal.Slot.t`. The encoding function converts this
   list into a `Dal.Slot_index.t`-indexed map. *)
module Dal_slot_headers =
  Indexed_store.Make_indexable
    (struct
      let name = "dal_slot_headers"
    end)
    (Block_slot_key)
    (Indexed_store.Make_index_value (Indexed_store.Make_fixed_encodable (struct
      type t = Dal.Slot.Header.t

      let name = "slot_header"

      let encoding = Dal.Slot.Header.encoding
    end)))

module Dal_slot_pages =
  Indexed_store.Make_simple_indexed_file
    (struct
      let name = "dal_slot_pages"
    end)
    (Block_slot_key)
    (struct
      type t = Dal.Page.content list

      let name = "pages"

      let encoding = Data_encoding.list Dal.Page.content_encoding

      module Header = Indexed_store.Make_fixed_encodable (struct
        type t = int

        let name = "number_of_pages"

        let encoding = Data_encoding.int31
      end)

      let header = List.length
    end)

(** stores slots whose data have been considered and pages stored to disk (if
    they are confirmed). *)
module Dal_processed_slots =
  Indexed_store.Make_indexable
    (struct
      let name = "dal_processed_slots"
    end)
    (Block_slot_key)
    (Indexed_store.Make_index_value (Indexed_store.Make_fixed_encodable (struct
      type t = [`Confirmed | `Unconfirmed]

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
    end)))

(* Published slot headers per block hash, stored as a list of bindings from
   `Dal_slot_index.t` to `Dal.Slot.t`. The encoding function converts this
   list into a `Dal.Slot_index.t`-indexed map. Note that the block_hash
   refers to the block where slots headers have been confirmed, not
   the block where they have been published.
*)

(** Confirmed DAL slots history. See documentation of
    {Dal_slot_repr.Slots_history} for more details. *)
module Dal_confirmed_slots_history =
  (* FIXME: inefficient, keep history in map instead *)
    Indexed_store.Make_simple_indexed_file
      (struct
        let name = "dal_confirmed_slots_history"
      end)
      (Tezos_store_shared.Block_key)
    (struct
      type t = Dal.Slots_history.t

      let name = "dal_slot_histories"

      let encoding = Dal.Slots_history.encoding

      include Add_empty_header
    end)

(** Confirmed DAL slots histories cache. See documentation of
{Dal_slot_repr.Slots_history} for more details. *)
module Dal_confirmed_slots_histories =
  (* FIXME: inefficient, keep history cache entries in map instead *)
    Indexed_store.Make_simple_indexed_file
      (struct
        let name = "dal_confirmed_slots_histories"
      end)
      (Tezos_store_shared.Block_key)
    (struct
      type t = Dal.Slots_history.History_cache.t

      let name = "dal_slot_history_cache"

      let encoding = Dal.Slots_history.History_cache.encoding

      include Add_empty_header
    end)

module Processed_blocks =
  Indexed_store.Make_indexable_removable
    (struct
      let name = "processed_blocks"
    end)
    (Tezos_store_shared.Block_key)
    (Indexed_store.Make_index_value (Empty_header))

module Head = Indexed_store.Make_singleton (struct
  type t = Tezos_crypto.Block_hash.t * Int32.t

  let name = "head"

  let encoding =
    let open Data_encoding in
    obj2
      (req "hash" Tezos_crypto.Block_hash.encoding)
      (req "level" Data_encoding.int32)
end)

type 'a store = {
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

type 'a t = ([< `Read | `Write > `Read] as 'a) store

type rw = Store_sigs.rw t

type ro = Store_sigs.ro t

let readonly
    ({
       stateinfo;
       statehistory;
       messages;
       inboxes;
       histories;
       payloads_histories;
       commitments;
       last_stored_commitment_level;
       commitments_published_at_level;
       contexts;
       dal_slots;
       dal_slot_headers;
       dal_slot_pages;
       dal_processed_slots;
       dal_confirmed_slots_history;
       dal_confirmed_slots_histories;
       processed_blocks;
       last_processed_head;
       last_finalized_head;
     } :
      _ t) : ro =
  {
    stateinfo = StateInfo.readonly stateinfo;
    statehistory = StateHistory.readonly statehistory;
    messages = Messages.readonly messages;
    inboxes = Inboxes.readonly inboxes;
    histories = Histories.readonly histories;
    payloads_histories = Payloads_histories.readonly payloads_histories;
    commitments = Commitments.readonly commitments;
    last_stored_commitment_level =
      Last_stored_commitment_level.readonly last_stored_commitment_level;
    commitments_published_at_level =
      Commitments_published_at_level.readonly commitments_published_at_level;
    contexts = Contexts.readonly contexts;
    dal_slots = Dal_slots.readonly dal_slots;
    dal_slot_headers = Dal_slot_headers.readonly dal_slot_headers;
    dal_slot_pages = Dal_slot_pages.readonly dal_slot_pages;
    dal_processed_slots = Dal_processed_slots.readonly dal_processed_slots;
    dal_confirmed_slots_history =
      Dal_confirmed_slots_history.readonly dal_confirmed_slots_history;
    dal_confirmed_slots_histories =
      Dal_confirmed_slots_histories.readonly dal_confirmed_slots_histories;
    processed_blocks = Processed_blocks.readonly processed_blocks;
    last_processed_head = Head.readonly last_processed_head;
    last_finalized_head = Head.readonly last_finalized_head;
  }

let close
    ({
       stateinfo;
       statehistory = _;
       messages;
       inboxes;
       histories;
       payloads_histories;
       commitments;
       last_stored_commitment_level = _;
       commitments_published_at_level;
       contexts;
       dal_slots;
       dal_slot_headers;
       dal_slot_pages;
       dal_processed_slots;
       dal_confirmed_slots_history;
       dal_confirmed_slots_histories;
       processed_blocks;
       last_processed_head = _;
       last_finalized_head = _;
     } :
      _ t) =
  let open Lwt_result_syntax in
  let+ () = StateInfo.close stateinfo
  and+ () = Messages.close messages
  and+ () = Inboxes.close inboxes
  and+ () = Histories.close histories
  and+ () = Payloads_histories.close payloads_histories
  and+ () = Commitments.close commitments
  and+ () = Commitments_published_at_level.close commitments_published_at_level
  and+ () = Contexts.close contexts
  and+ () = Dal_slots.close dal_slots
  and+ () = Dal_slot_headers.close dal_slot_headers
  and+ () = Dal_slot_pages.close dal_slot_pages
  and+ () = Dal_processed_slots.close dal_processed_slots
  and+ () = Dal_confirmed_slots_history.close dal_confirmed_slots_history
  and+ () = Dal_confirmed_slots_histories.close dal_confirmed_slots_histories
  and+ () = Processed_blocks.close processed_blocks in
  ()

let load (type a) (mode : a mode) data_dir : a store tzresult Lwt.t =
  let open Lwt_result_syntax in
  let path name = Filename.concat data_dir name in
  let cache_size = 10_000 in
  let+ stateinfo = StateInfo.load mode ~path:(path "state_info") ~cache_size
  and+ statehistory = StateHistory.load mode ~path:(path "state_history")
  and+ messages = Messages.load mode ~path:(path "messages") ~cache_size
  and+ inboxes = Inboxes.load mode ~path:(path "inboxes") ~cache_size
  and+ histories = Histories.load mode ~path:(path "histories") ~cache_size
  and+ payloads_histories =
    Payloads_histories.load mode ~path:(path "payload_histories") ~cache_size
  and+ commitments = Commitments.load mode ~path:(path "commitments")
  and+ last_stored_commitment_level =
    Last_stored_commitment_level.load
      mode
      ~path:(path "last_stored_commitment_level")
  and+ commitments_published_at_level =
    Commitments_published_at_level.load
      mode
      ~path:(path "commitments_published_at_level")
  and+ contexts = Contexts.load mode ~path:(path "contexts")
  and+ dal_slots = Dal_slots.load mode ~path:(path "dal_slots")
  and+ dal_slot_headers =
    Dal_slot_headers.load mode ~path:(path "dal_slot_headers")
  and+ dal_slot_pages =
    Dal_slot_pages.load mode ~path:(path "dal_slot_pages") ~cache_size
  and+ dal_processed_slots =
    Dal_processed_slots.load mode ~path:(path "dal_processed_slots")
  and+ dal_confirmed_slots_history =
    Dal_confirmed_slots_history.load
      mode
      ~path:(path "dal_confirmed_slots_history")
      ~cache_size
  and+ dal_confirmed_slots_histories =
    Dal_confirmed_slots_histories.load
      mode
      ~path:(path "dal_confirmed_slots_history")
      ~cache_size
  and+ processed_blocks =
    Processed_blocks.load mode ~path:(path "processed_blocks")
  and+ last_processed_head = Head.load mode ~path:(path "last_processed_head")
  and+ last_finalized_head =
    Head.load mode ~path:(path "last_finalized_head")
  in
  {
    stateinfo;
    statehistory;
    messages;
    inboxes;
    histories;
    payloads_histories;
    commitments;
    last_stored_commitment_level;
    commitments_published_at_level;
    contexts;
    dal_slots;
    dal_slot_headers;
    dal_slot_pages;
    dal_processed_slots;
    dal_confirmed_slots_history;
    dal_confirmed_slots_histories;
    processed_blocks;
    last_processed_head;
    last_finalized_head;
  }
