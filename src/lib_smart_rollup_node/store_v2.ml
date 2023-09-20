(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

include Store_sigs
include Store_utils
include Store_v1

let version = Store_version.V2

module Make_hash_index_key (H : Tezos_crypto.Intfs.HASH) =
Indexed_store.Make_index_key (struct
  include Indexed_store.Make_fixed_encodable (H)

  let equal = H.equal
end)

(** Unaggregated messages per block *)
module Messages =
  Indexed_store.Make_indexed_file
    (struct
      let name = "messages"
    end)
    (Make_hash_index_key (Merkelized_payload_hashes_hash))
    (struct
      type t = string list

      let name = "messages_list"

      let encoding = Data_encoding.(list @@ dynamic_size (Variable.string' Hex))

      module Header = struct
        type t = Block_hash.t

        let name = "messages_block"

        let encoding = Block_hash.encoding

        let fixed_size =
          WithExceptions.Option.get ~loc:__LOC__
          @@ Data_encoding.Binary.fixed_length encoding
      end
    end)

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

(** Versioned inboxes *)
module Inboxes =
  Indexed_store.Make_simple_indexed_file
    (struct
      let name = "inboxes"
    end)
    (Make_hash_index_key (Octez_smart_rollup.Inbox.Hash))
    (struct
      type t = Octez_smart_rollup.Inbox.t

      let encoding =
        Data_encoding.conv
          Octez_smart_rollup.Inbox.to_versioned
          Octez_smart_rollup.Inbox.of_versioned
          Octez_smart_rollup.Inbox.versioned_encoding

      let name = "inbox"

      include Add_empty_header
    end)

(** Versioned commitments *)
module Commitments =
  Indexed_store.Make_simple_indexed_file
    (struct
      let name = "commitments"
    end)
    (Make_hash_index_key (Octez_smart_rollup.Commitment.Hash))
    (struct
      type t = Octez_smart_rollup.Commitment.t

      let encoding =
        Data_encoding.conv
          Octez_smart_rollup.Commitment.to_versioned
          Octez_smart_rollup.Commitment.of_versioned
          Octez_smart_rollup.Commitment.versioned_encoding

      let name = "commitment"

      include Add_empty_header
    end)

(** Versioned slot headers *)
module Dal_slots_headers =
  Irmin_store.Make_nested_map
    (struct
      let path = ["dal"; "slot_headers"]
    end)
    (struct
      type key = Block_hash.t

      let to_path_representation = Block_hash.to_b58check
    end)
    (struct
      type key = Octez_smart_rollup.Dal.Slot_index.t

      let encoding = Octez_smart_rollup.Dal.Slot_index.encoding

      let compare = Compare.Int.compare

      let name = "slot_index"
    end)
    (struct
      type value = Octez_smart_rollup.Dal.Slot_header.t

      let name = "slot_header"

      let encoding =
        Data_encoding.conv
          Octez_smart_rollup.Dal.Slot_header.to_versioned
          Octez_smart_rollup.Dal.Slot_header.of_versioned
          Octez_smart_rollup.Dal.Slot_header.versioned_encoding
    end)

(** Versioned Confirmed DAL slots history *)
module Dal_confirmed_slots_history =
  Irmin_store.Make_append_only_map
    (struct
      let path = ["dal"; "confirmed_slots_history"]
    end)
    (struct
      type key = Block_hash.t

      let to_path_representation = Block_hash.to_b58check
    end)
    (struct
      type value = Octez_smart_rollup.Dal.Slot_history.t

      let name = "dal_slot_histories"

      let encoding =
        Data_encoding.conv
          Octez_smart_rollup.Dal.Slot_history.to_versioned
          Octez_smart_rollup.Dal.Slot_history.of_versioned
          Octez_smart_rollup.Dal.Slot_history.versioned_encoding
    end)

(** Versioned Confirmed DAL slots histories cache. *)
module Dal_confirmed_slots_histories =
  (* TODO: https://gitlab.com/tezos/tezos/-/issues/4390
     Store single history points in map instead of whole history. *)
    Irmin_store.Make_append_only_map
      (struct
        let path = ["dal"; "confirmed_slots_histories_cache"]
      end)
      (struct
        type key = Block_hash.t

        let to_path_representation = Block_hash.to_b58check
      end)
    (struct
      type value = Octez_smart_rollup.Dal.Slot_history_cache.t

      let name = "dal_slot_histories"

      let encoding =
        Data_encoding.conv
          Octez_smart_rollup.Dal.Slot_history_cache.to_versioned
          Octez_smart_rollup.Dal.Slot_history_cache.of_versioned
          Octez_smart_rollup.Dal.Slot_history_cache.versioned_encoding
    end)

module Protocols = struct
  type level = First_known of int32 | Activation_level of int32

  type proto_info = {
    level : level;
    proto_level : int;
    protocol : Protocol_hash.t;
  }

  type value = proto_info list

  let level_encoding =
    let open Data_encoding in
    conv
      (function First_known l -> (l, false) | Activation_level l -> (l, true))
      (function l, false -> First_known l | l, true -> Activation_level l)
    @@ obj2 (req "level" int32) (req "activates" bool)

  let proto_info_encoding =
    let open Data_encoding in
    conv
      (fun {level; proto_level; protocol} -> (level, proto_level, protocol))
      (fun (level, proto_level, protocol) -> {level; proto_level; protocol})
    @@ obj3
         (req "level" level_encoding)
         (req "proto_level" int31)
         (req "protocol" Protocol_hash.encoding)

  include Indexed_store.Make_singleton (struct
    type t = value

    let name = "protocols"

    let level_encoding =
      let open Data_encoding in
      conv
        (function
          | First_known l -> (l, false) | Activation_level l -> (l, true))
        (function l, false -> First_known l | l, true -> Activation_level l)
      @@ obj2 (req "level" int32) (req "activates" bool)

    let proto_info_encoding =
      let open Data_encoding in
      conv
        (fun {level; proto_level; protocol} -> (level, proto_level, protocol))
        (fun (level, proto_level, protocol) -> {level; proto_level; protocol})
      @@ obj3
           (req "level" level_encoding)
           (req "proto_level" int31)
           (req "protocol" Protocol_hash.encoding)

    let encoding = Data_encoding.list proto_info_encoding
  end)
end

type 'a store = {
  l2_blocks : 'a L2_blocks.t;
  messages : 'a Messages.t;
  inboxes : 'a Inboxes.t;
  commitments : 'a Commitments.t;
  commitments_published_at_level : 'a Commitments_published_at_level.t;
  l2_head : 'a L2_head.t;
  last_finalized_level : 'a Last_finalized_level.t;
  levels_to_hashes : 'a Levels_to_hashes.t;
  protocols : 'a Protocols.t;
  irmin_store : 'a Irmin_store.t;
}

type 'a t = ([< `Read | `Write > `Read] as 'a) store

type rw = Store_sigs.rw t

type ro = Store_sigs.ro t

let readonly
    ({
       l2_blocks;
       messages;
       inboxes;
       commitments;
       commitments_published_at_level;
       l2_head;
       last_finalized_level;
       levels_to_hashes;
       protocols;
       irmin_store;
     } :
      _ t) : ro =
  {
    l2_blocks = L2_blocks.readonly l2_blocks;
    messages = Messages.readonly messages;
    inboxes = Inboxes.readonly inboxes;
    commitments = Commitments.readonly commitments;
    commitments_published_at_level =
      Commitments_published_at_level.readonly commitments_published_at_level;
    l2_head = L2_head.readonly l2_head;
    last_finalized_level = Last_finalized_level.readonly last_finalized_level;
    levels_to_hashes = Levels_to_hashes.readonly levels_to_hashes;
    protocols = Protocols.readonly protocols;
    irmin_store = Irmin_store.readonly irmin_store;
  }

let close
    ({
       l2_blocks;
       messages;
       inboxes;
       commitments;
       commitments_published_at_level;
       l2_head = _;
       last_finalized_level = _;
       levels_to_hashes;
       protocols = _;
       irmin_store;
     } :
      _ t) =
  let open Lwt_result_syntax in
  let+ () = L2_blocks.close l2_blocks
  and+ () = Messages.close messages
  and+ () = Inboxes.close inboxes
  and+ () = Commitments.close commitments
  and+ () = Commitments_published_at_level.close commitments_published_at_level
  and+ () = Levels_to_hashes.close levels_to_hashes
  and+ () = Irmin_store.close irmin_store in
  ()

let load (type a) (mode : a mode) ~l2_blocks_cache_size data_dir :
    a store tzresult Lwt.t =
  let open Lwt_result_syntax in
  let path name = Filename.concat data_dir name in
  let cache_size = l2_blocks_cache_size in
  let* l2_blocks = L2_blocks.load mode ~path:(path "l2_blocks") ~cache_size in
  let* messages = Messages.load mode ~path:(path "messages") ~cache_size in
  let* inboxes = Inboxes.load mode ~path:(path "inboxes") ~cache_size in
  let* commitments =
    Commitments.load mode ~path:(path "commitments") ~cache_size
  in
  let* commitments_published_at_level =
    Commitments_published_at_level.load
      mode
      ~path:(path "commitments_published_at_level")
  in
  let* l2_head = L2_head.load mode ~path:(path "l2_head") in
  let* last_finalized_level =
    Last_finalized_level.load mode ~path:(path "last_finalized_level")
  in
  let* levels_to_hashes =
    Levels_to_hashes.load mode ~path:(path "levels_to_hashes")
  in
  let* protocols = Protocols.load mode ~path:(path "protocols") in
  let+ irmin_store = Irmin_store.load mode (path "irmin_store") in
  {
    l2_blocks;
    messages;
    inboxes;
    commitments;
    commitments_published_at_level;
    l2_head;
    last_finalized_level;
    levels_to_hashes;
    protocols;
    irmin_store;
  }

let iter_l2_blocks ({l2_blocks; l2_head; _} : _ t) f =
  let open Lwt_result_syntax in
  let* head = L2_head.read l2_head in
  match head with
  | None ->
      (* No reachable head, nothing to do *)
      return_unit
  | Some head ->
      let rec loop hash =
        let* block = L2_blocks.read l2_blocks hash in
        match block with
        | None ->
            (* The block does not exist, the known chain stops here, so do we. *)
            return_unit
        | Some (block, header) ->
            let* () = f {block with header} in
            loop header.predecessor
      in
      loop head.header.block_hash
