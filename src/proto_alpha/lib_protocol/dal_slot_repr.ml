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

module Header = struct
  (* DAL/FIXME https://gitlab.com/tezos/tezos/-/issues/3389

     It is not clear whether the size of the slot associated to the
     commitment should be given here. *)
  type t = Dal.commitment

  let equal = Dal.Commitment.equal

  let encoding = Dal.Commitment.encoding

  let pp ppf commitment =
    Format.fprintf ppf "%s" (Dal.Commitment.to_b58check commitment)
end

module Index = struct
  type t = int

  let max_value = 255

  let encoding = Data_encoding.uint8

  let pp = Format.pp_print_int

  let zero = 0

  let of_int slot_index =
    if Compare.Int.(slot_index <= max_value && slot_index >= zero) then
      Some slot_index
    else None

  let to_int slot_index = slot_index [@@ocaml.inline always]

  let compare = Compare.Int.compare

  let equal = Compare.Int.equal
end

type header = Header.t

let zero = Dal.Commitment.zero

type t = {published_level : Raw_level_repr.t; index : Index.t; header : header}

type slot = t

type slot_index = Index.t

let slot_equal ({published_level; index; header} : t) s2 =
  Raw_level_repr.equal published_level s2.published_level
  && Index.equal index s2.index
  && Header.equal header s2.header

module Slot_index = Index

module Page = struct
  type content = string

  module Index = struct
    type t = int

    let zero = 0

    let encoding = Data_encoding.int16

    let pp = Format.pp_print_int

    let compare = Compare.Int.compare

    let equal = Compare.Int.equal
  end

  type id = {
    published_level : Raw_level_repr.t;
    slot_index : Slot_index.t;
    page_index : Index.t;
  }

  let id_encoding =
    let open Data_encoding in
    conv
      (fun {published_level; slot_index; page_index} ->
        (published_level, slot_index, page_index))
      (fun (published_level, slot_index, page_index) ->
        {published_level; slot_index; page_index})
      (obj3
         (req "published_level" Raw_level_repr.encoding)
         (req "slot_index" Slot_index.encoding)
         (req "page_index" Index.encoding))

  let equal_id {published_level; slot_index; page_index} p =
    Raw_level_repr.equal published_level p.published_level
    && Slot_index.equal slot_index p.slot_index
    && Index.equal page_index p.page_index

  let pp_id fmt {published_level; slot_index; page_index} =
    Format.fprintf
      fmt
      "(published_level: %a, slot_index: %a, page_index: %a)"
      Raw_level_repr.pp
      published_level
      Slot_index.pp
      slot_index
      Index.pp
      page_index
end

let slot_encoding =
  let open Data_encoding in
  conv
    (fun {published_level; index; header} -> (published_level, index, header))
    (fun (published_level, index, header) -> {published_level; index; header})
    (obj3
       (req "level" Raw_level_repr.encoding)
       (req "index" Data_encoding.uint8)
       (req "header" Header.encoding))

let pp_slot fmt {published_level; index; header} =
  Format.fprintf
    fmt
    "published_level: %a index: %a header: %a"
    Raw_level_repr.pp
    published_level
    Format.pp_print_int
    index
    Header.pp
    header

module Slot_market = struct
  (* DAL/FIXME https://gitlab.com/tezos/tezos/-/issues/3108

     Think harder about this data structure and whether it can be
     optimized. *)

  module Slot_index_map = Map.Make (Index)

  type t = {length : int; slots : slot Slot_index_map.t}

  let init ~length =
    if Compare.Int.(length < 0) then
      invalid_arg "Dal_slot_repr.Slot_market.init: length cannot be negative" ;
    let slots = Slot_index_map.empty in
    {length; slots}

  let length {length; _} = length

  let register t new_slot =
    if not Compare.Int.(0 <= new_slot.index && new_slot.index < t.length) then
      None
    else
      let has_changed = ref false in
      let update = function
        | None ->
            has_changed := true ;
            Some new_slot
        | Some x -> Some x
      in
      let slots = Slot_index_map.update new_slot.index update t.slots in
      let t = {t with slots} in
      Some (t, !has_changed)

  let candidates t =
    t.slots |> Slot_index_map.to_seq |> Seq.map snd |> List.of_seq
end

module Slots_history = struct
  (* History is represented via a skip list. The content of the cell
     is the hash of a merkle proof. *)

  (* A leaf of the merkle tree is a slot. *)
  module Leaf = struct
    type t = slot

    let to_bytes = Data_encoding.Binary.to_bytes_exn slot_encoding
  end

  module Content_prefix = struct
    let _prefix = "dash1"

    (* 32 *)
    let b58check_prefix = "\002\224\072\094\219" (* dash1(55) *)

    let size = Some 32

    let name = "dal_skip_list_content"

    let title = "A hash to represent the content of a cell in the skip list"
  end

  module Content_hash = Blake2B.Make (Base58) (Content_prefix)
  module Merkle_list = Merkle_list.Make (Leaf) (Content_hash)

  (* Pointers of the skip lists are used to encode the content and the
     backpointers. *)
  module Pointer_prefix = struct
    let _prefix = "dask1"

    (* 32 *)
    let b58check_prefix = "\002\224\072\115\035" (* dask1(55) *)

    let size = Some 32

    let name = "dal_skip_list_pointer"

    let title = "A hash that represents the skip list pointers"
  end

  module Pointer_hash = Blake2B.Make (Base58) (Pointer_prefix)

  module Skip_list_parameters = struct
    let basis = 2
  end

  module Skip_list = Skip_list_repr.Make (Skip_list_parameters)

  module V1 = struct
    (* The content of a cell is the hash of all the slot headers
       represented as a merkle list. *)
    (* TODO/DAL: https://gitlab.com/tezos/tezos/-/issues/3765
       Decide how to store attested slots in the skip list's content. *)
    type content = slot

    (* A pointer to a cell is the hash of its content and all the back
       pointers. *)
    type ptr = Pointer_hash.t

    type history = (content, ptr) Skip_list.cell

    type t = history option

    let history_encoding =
      Skip_list.encoding Pointer_hash.encoding slot_encoding

    let equal_history : history -> history -> bool =
      Skip_list.equal Pointer_hash.equal slot_equal

    let encoding = Data_encoding.option history_encoding

    let equal : t -> t -> bool = Option.equal equal_history

    let genesis : t = None

    let hash_skip_list_cell cell =
      let current_slot = Skip_list.content cell in
      let back_pointers_hashes = Skip_list.back_pointers cell in
      Data_encoding.Binary.to_bytes_exn slot_encoding current_slot
      :: List.map Pointer_hash.to_bytes back_pointers_hashes
      |> Pointer_hash.hash_bytes

    let pp_history fmt (history : history) =
      let history_hash = hash_skip_list_cell history in
      Format.fprintf
        fmt
        "@[hash : %a@;%a@]"
        Pointer_hash.pp
        history_hash
        (Skip_list.pp ~pp_content:pp_slot ~pp_ptr:Pointer_hash.pp)
        history

    module History_cache =
      Bounded_history_repr.Make
        (struct
          let name = "dal_slots_cache"
        end)
        (Pointer_hash)
        (struct
          type t = history

          let encoding = history_encoding

          let pp = pp_history

          let equal = equal_history
        end)

    let add_confirmed_slot (t, cache) slot =
      let open Tzresult_syntax in
      match t with
      | None -> return (Some (Skip_list.genesis slot), cache)
      | Some t ->
          let content = slot in
          let prev_cell_ptr = hash_skip_list_cell t in
          let* cache = History_cache.remember prev_cell_ptr t cache in
          return
            ( Skip_list.next ~prev_cell:t ~prev_cell_ptr content |> Option.some,
              cache )

    let add_confirmed_slots t cache slots =
      List.fold_left_e add_confirmed_slot (t, cache) slots

    let add_confirmed_slots_no_cache =
      let no_cache = History_cache.empty ~capacity:0L in
      fun t slots ->
        List.fold_left_e add_confirmed_slot (t, no_cache) slots >|? fst

    (** FIXME/DAL-REFUTATION: Proofs section *)

    type inclusion_proof = history list

    type proof =
      | Page_confirmed of {
          page_content : Page.content;
          slot_kate : Header.t;
          inc_proof : inclusion_proof;
        }
      | Page_unconfirmed of {
          prev_confirmed_slot : slot;
          next_confirmed_slot : slot;
          inc_proof : inclusion_proof;
        }

    let proof_encoding =
      let open Data_encoding in
      let case_page_confirmed =
        case
          ~title:"dal page confirmed"
          (Tag 0)
          (obj4
             (req "kind" (constant "confirmed"))
             (req "content" string)
             (req "slot_kate" Header.encoding)
             (req "inc_proof" (list history_encoding)))
          (function
            | Page_confirmed {page_content; slot_kate; inc_proof} ->
                Some ((), page_content, slot_kate, inc_proof)
            | _ -> None)
          (fun ((), page_content, slot_kate, inc_proof) ->
            Page_confirmed {page_content; slot_kate; inc_proof})
      and case_page_unconfirmed =
        case
          ~title:"dal page unconfirmed"
          (Tag 1)
          (obj4
             (req "kind" (constant "unconfirmed"))
             (req "prev_confirmed_slot" slot_encoding)
             (req "next_confirmed_slot" slot_encoding)
             (req "inc_proof" (list history_encoding)))
          (function
            | Page_unconfirmed
                {prev_confirmed_slot; next_confirmed_slot; inc_proof} ->
                Some ((), prev_confirmed_slot, next_confirmed_slot, inc_proof)
            | _ -> None)
          (fun ((), prev_confirmed_slot, next_confirmed_slot, inc_proof) ->
            Page_unconfirmed
              {prev_confirmed_slot; next_confirmed_slot; inc_proof})
      in

      union [case_page_confirmed; case_page_unconfirmed]

    let pp_proof fmt p =
      (* FIXME/DAL: pp inclusion proofs *)
      match p with
      | Page_confirmed {page_content; slot_kate; inc_proof = _} ->
          Format.fprintf
            fmt
            "Page_confirmed (content=%s, slot's kate= %a, inc_proof=())"
            page_content
            Header.pp
            slot_kate
      | Page_unconfirmed
          {prev_confirmed_slot; next_confirmed_slot; inc_proof = _} ->
          Format.fprintf
            fmt
            "Page_unconfirmed (prev_confirmed_slot=%a, \
             next_confirmed_slot=%a,inc_proof=())"
            pp_slot
            prev_confirmed_slot
            pp_slot
            next_confirmed_slot

    let produce_proof ~page_content_of:_ _page_id slots_history _history_cache =
      match slots_history with
      | None -> assert false (* Cannot produce proof here. skip list is empty *)
      | Some _slots_history -> assert false
  end

  include V1
end

let encoding = slot_encoding

let pp = pp_slot

let equal = slot_equal
