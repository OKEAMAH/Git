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
include Store_v0

let version = Store_version.V1

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

      let encoding = Data_encoding.(list @@ dynamic_size Variable.(string' Hex))

      module Header = struct
        type t = bool * Block_hash.t * Time.Protocol.t * int

        let name = "messages_inbox_info"

        let encoding =
          let open Data_encoding in
          obj4
            (req "is_first_block" bool)
            (req "predecessor" Block_hash.encoding)
            (req "predecessor_timestamp" Time.Protocol.encoding)
            (req "num_messages" int31)

        let fixed_size =
          WithExceptions.Option.get ~loc:__LOC__
          @@ Data_encoding.Binary.fixed_length encoding
      end
    end)

module Dal_pages = struct
  type removed_in_v1
end

module Dal_processed_slots = struct
  type removed_in_v1
end

(** Store attestation statuses for DAL slots on L1. *)
module Dal_slots_statuses =
  Irmin_store.Make_nested_map
    (struct
      let path = ["dal"; "slots_statuses"]
    end)
    (struct
      type key = Block_hash.t

      let to_path_representation = Block_hash.to_b58check
    end)
    (struct
      type key = Dal.Slot_index.t

      let encoding = Dal.Slot_index.encoding

      let compare = Compare.Int.compare

      let name = "slot_index"
    end)
    (struct
      (* TODO: https://gitlab.com/tezos/tezos/-/issues/4780.

         Rename Confirm-ed/ation to Attest-ed/ation in the rollup node. *)
      type value = [`Confirmed | `Unconfirmed]

      let name = "slot_status"

      let encoding =
        (* We don't use
           Data_encoding.string_enum because a union is more storage-efficient. *)
        let open Data_encoding in
        union
          ~tag_size:`Uint8
          [
            case
              ~title:"Confirmed"
              (Tag 0)
              (obj1 (req "kind" (constant "Confirmed")))
              (function `Confirmed -> Some () | `Unconfirmed -> None)
              (fun () -> `Confirmed);
            case
              ~title:"Unconfirmed"
              (Tag 1)
              (obj1 (req "kind" (constant "Unconfirmed")))
              (function `Unconfirmed -> Some () | `Confirmed -> None)
              (fun () -> `Unconfirmed);
          ]
    end)

type nonrec 'a store = {
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

let load (type a) (mode : a mode) ~index_buffer_size ~l2_blocks_cache_size
    data_dir : a store tzresult Lwt.t =
  let open Lwt_result_syntax in
  let path name = Filename.concat data_dir name in
  let cache_size = l2_blocks_cache_size in
  let* l2_blocks =
    L2_blocks.load mode ~index_buffer_size ~path:(path "l2_blocks") ~cache_size
  in
  let* messages =
    Messages.load mode ~index_buffer_size ~path:(path "messages") ~cache_size
  in
  let* inboxes =
    Inboxes.load mode ~index_buffer_size ~path:(path "inboxes") ~cache_size
  in
  let* commitments =
    Commitments.load mode ~index_buffer_size ~path:(path "commitments")
  in
  let* commitments_published_at_level =
    Commitments_published_at_level.load
      ~index_buffer_size
      mode
      ~path:(path "commitments_published_at_level")
  in
  let* l2_head = L2_head.load mode ~path:(path "l2_head") in
  let* last_finalized_level =
    Last_finalized_level.load mode ~path:(path "last_finalized_level")
  in
  let* levels_to_hashes =
    Levels_to_hashes.load
      mode
      ~index_buffer_size
      ~path:(path "levels_to_hashes")
  in
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
    irmin_store;
  }

let iter_l2_blocks ?progress _ {l2_blocks; l2_head; _} f =
  let open Lwt_result_syntax in
  let* head = L2_head.read l2_head in
  match head with
  | None ->
      (* No reachable head, nothing to do *)
      return_unit
  | Some head ->
      let track_progress =
        match progress with
        | None -> fun f -> f (fun _ -> Lwt.return_unit)
        | Some message ->
            let progress_bar = Progress_bar.spinner ~message in
            fun f -> Progress_bar.Lwt.with_reporter progress_bar f
      in
      track_progress @@ fun count_progress ->
      let rec loop hash =
        let* block = L2_blocks.read l2_blocks hash in
        match block with
        | None ->
            (* The block does not exist, the known chain stops here, so do we. *)
            return_unit
        | Some (block, header) ->
            let* () = f {block with header} in
            let*! () = count_progress 1 in
            loop header.predecessor
      in
      loop head.header.block_hash

let gc (_ : _ t) ~level:_ = failwith "GC is not implemented for store V1"

let wait_gc_completion (_ : _ t) =
  Lwt.fail_with "GC is not implemented for store V1"
