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

  let zero = Dal.Commitment.zero

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

type t = {
  published_level : Raw_level_repr.t;
  index : Index.t;
  header : Header.t;
}

type slot = t

type slot_index = Index.t

let slot_equal ({published_level; index; header} : t) s2 =
  Raw_level_repr.equal published_level s2.published_level
  && Index.equal index s2.index
  && Header.equal header s2.header

let slot_id_compare ({published_level; index; header = _} : t) s2 =
  let c = Raw_level_repr.compare published_level s2.published_level in
  if Compare.Int.(c <> 0) then c else Index.compare index s2.index

let zero =
  {
    (* We don't expect to have any published slot at level
       Raw_level_repr.root. *)
    published_level = Raw_level_repr.root;
    index = Index.zero;
    header = Header.zero;
  }

module Slot_index = Index

module Page = struct
  type content = string

  type content_opt = content option

  type proof = Dal.segment_proof

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

  type error += Add_element_in_slots_skip_list_violates_ordering

  let () =
    register_error_kind
      `Temporary
      ~id:"Dal_slot_repr.add_element_in_slots_skip_list_violates_ordering"
      ~title:"Add an element in slots skip list that violates ordering"
      ~description:
        "Attempting to add an element on top of the Dal confirmed slots skip \
         list that violates the ordering."
      Data_encoding.unit
      (function
        | Add_element_in_slots_skip_list_violates_ordering -> Some ()
        | _ -> None)
      (fun () -> Add_element_in_slots_skip_list_violates_ordering)

  module Skip_list = struct
    include Skip_list_repr.Make (Skip_list_parameters)

    let next ~compare ~prev_cell ~prev_cell_ptr elt =
      let open Tzresult_syntax in
      let c = compare elt (content prev_cell) in
      let* () =
        error_when
          Compare.Int.(c <= 0)
          Add_element_in_slots_skip_list_violates_ordering
      in
      return @@ next ~prev_cell ~prev_cell_ptr elt
  end

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

    type t = history

    let history_encoding =
      Skip_list.encoding Pointer_hash.encoding slot_encoding

    let equal_history : history -> history -> bool =
      Skip_list.equal Pointer_hash.equal slot_equal

    let encoding = history_encoding

    let equal : t -> t -> bool = equal_history

    let genesis : t = Skip_list.genesis (zero : slot)

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

    let add_confirmed_slot =
      let compare (s1 : slot) s2 =
        Raw_level_repr.compare s1.published_level s2.published_level
      in
      fun (t, cache) slot ->
        let open Tzresult_syntax in
        let prev_cell_ptr = hash_skip_list_cell t in
        let* cache = History_cache.remember prev_cell_ptr t cache in
        let* new_cell =
          Skip_list.next ~compare ~prev_cell:t ~prev_cell_ptr slot
        in
        return (new_cell, cache)

    let add_confirmed_slots (t : t) cache slots =
      List.fold_left_e add_confirmed_slot (t, cache) slots

    let no_history_cache = History_cache.empty ~capacity:0L

    let add_confirmed_slots_no_cache t slots =
      List.fold_left_e add_confirmed_slot (t, no_history_cache) slots >|? fst

    (** FIXME/DAL-REFUTATION: Proofs section *)

    type dal_parameters = Tezos_crypto_dal.Cryptobox.parameters = {
      redundancy_factor : int;
      segment_size : int;
      slot_size : int;
      number_of_shards : int;
    }

    type inclusion_proof = history list

    type proof =
      | Page_confirmed of {
          page_content : Page.content;
          page_proof : Page.proof;
          inc_proof : inclusion_proof;
        }
      | Page_unconfirmed of {prev_inc_proof : inclusion_proof}

    let proof_encoding =
      let open Data_encoding in
      let case_page_confirmed =
        case
          ~title:"dal page confirmed"
          (Tag 0)
          (obj4
             (req "kind" (constant "confirmed"))
             (req "content" string)
             (req "page_proof" Dal.segment_proof_encoding)
             (req "inc_proof" (list history_encoding)))
          (function
            | Page_confirmed {page_content; page_proof; inc_proof} ->
                Some ((), page_content, page_proof, inc_proof)
            | _ -> None)
          (fun ((), page_content, page_proof, inc_proof) ->
            Page_confirmed {page_content; page_proof; inc_proof})
      and case_page_unconfirmed =
        case
          ~title:"dal page unconfirmed"
          (Tag 1)
          (obj2
             (req "kind" (constant "unconfirmed"))
             (req "prev_inc_proof" (list history_encoding)))
          (function
            | Page_unconfirmed {prev_inc_proof} -> Some ((), prev_inc_proof)
            | _ -> None)
          (fun ((), prev_inc_proof) -> Page_unconfirmed {prev_inc_proof})
      in

      union [case_page_confirmed; case_page_unconfirmed]

    let pp_inclusion_proof fmt proof = Format.pp_print_list pp_history fmt proof

    let pp_proof fmt p =
      (* FIXME/DAL: pp inclusion proofs and page_proof *)
      match p with
      | Page_confirmed {page_content; page_proof = _; inc_proof} ->
          Format.fprintf
            fmt
            "Page_confirmed (content=%s, inc_proof:[size=%d | data=%a])"
            page_content
            (List.length inc_proof)
            pp_inclusion_proof
            inc_proof
      | Page_unconfirmed {prev_inc_proof} ->
          Format.fprintf
            fmt
            "Page_unconfirmed (prev_inc_proof:[size=%d | data=%a])"
            (List.length prev_inc_proof)
            pp_inclusion_proof
            prev_inc_proof

    type error += Dal_proof_error of string

    let () =
      let open Data_encoding in
      register_error_kind
        `Permanent
        ~id:"dal_slot_repr.slots_history.proof"
        ~title:
          "Internal error: error occurred during Dal proof production or \
           validation"
        ~description:"A Dal proof error."
        ~pp:(fun ppf e -> Format.fprintf ppf "Dal proof error: %s" e)
        (obj1 (req "error" string))
        (function Dal_proof_error e -> Some e | _ -> None)
        (fun e -> Dal_proof_error e)

    let dal_proof_error reason = Dal_proof_error reason

    let proof_error reason =
      let open Lwt_tzresult_syntax in
      fail @@ dal_proof_error reason

    let verify_page dal_params page_proof page_content page_id slot_header =
      let open Lwt_tzresult_syntax in
      let* dal =
        match Dal.make dal_params with
        | Ok dal -> return dal
        | Error (`Fail s) -> proof_error s
      in
      let _ =
        Dal.verify_segment
          dal
          slot_header
          {
            Dal.content = Bytes.of_string page_content;
            index = page_id.Page.page_index;
          }
          page_proof
      in
      Format.kasprintf
        proof_error
        "Provided content (%s) doesn't match the expected one for page %a in \
         KATE commitment %a."
        page_content
        Page.pp_id
        page_id
        Header.pp
        slot_header

    let check_not_dummy_slots target zero dummy_upper_slot =
      fail_when
        (Compare.Int.( = ) (slot_id_compare target zero) 0
        || Compare.Int.( = ) (slot_id_compare target dummy_upper_slot) 0)
        (dal_proof_error
           "Skip_list.search returned 'Found <dummy_slot>': No existence proof \
            should be constructed with the zero or uppper dummy slot.")

    let push_upper_dummy_slot published_level slots_history history_cache =
      let open Tzresult_syntax in
      let dummy_upper_slot =
        {zero with published_level = Raw_level_repr.succ published_level}
      in
      let* dummy_upper_slots_history, history_cache =
        add_confirmed_slot (slots_history, history_cache) dummy_upper_slot
      in
      let cell_ptr = hash_skip_list_cell dummy_upper_slots_history in
      let* history_cache =
        History_cache.remember cell_ptr dummy_upper_slots_history history_cache
      in
      let deref ptr = History_cache.find ptr history_cache in
      return (dummy_upper_slots_history, dummy_upper_slot, deref)

    let produce_proof dal_params ~page_content_of page_id slots_history
        history_cache =
      let open Lwt_tzresult_syntax in
      let {Page.published_level; slot_index; page_index = _} = page_id in
      let*? dummy_upper_slots_history, dummy_upper_slot, deref =
        push_upper_dummy_slot published_level slots_history history_cache
      in
      let compare target_level target_slot_index (s : slot) =
        Lwt.return
        @@
        let c = Raw_level_repr.compare target_level s.published_level in
        if Compare.Int.(c <> 0) then c
        else Index.compare target_slot_index s.index
      in
      let*! search_result =
        Skip_list.search
          ~deref
          ~compare:(compare published_level slot_index)
          ~cell:dummy_upper_slots_history
      in
      let inc_proof = List.rev search_result.Skip_list.rev_path in
      match search_result.Skip_list.last_cell with
      | Deref_returned_none ->
          proof_error
            "Skip_list.search returned 'Deref_returned_none': Slots history \
             cache is ill-formed or has too few entries."
      | No_exact_or_lower_ptr ->
          proof_error
            "Skip_list.search returned 'No_exact_or_lower_ptr', while it is \
             initialized with a min elt (slot zero)."
      | Found last_slots_history ->
          let target = Skip_list.content last_slots_history in
          let* () = check_not_dummy_slots target zero dummy_upper_slot in
          let* page_content, page_proof = page_content_of page_id in
          let* () =
            verify_page dal_params page_proof page_content page_id target.header
          in
          (* FIXME/DAL-REFUTATION: Why do we return page_content in both the proof and as
             input? *)
          return
            ( Page_confirmed {page_content; page_proof; inc_proof},
              Some page_content )
      | Nearest_lower _lower ->
          return (Page_unconfirmed {prev_inc_proof = inc_proof}, None)

    (* FIXME/DAL: copined from inbox_repr *)
    let verify_inclusion_proof proof a b =
      let assoc = List.map (fun c -> (hash_skip_list_cell c, c)) proof in
      let path = List.split assoc |> fst in
      let deref =
        let open Map.Make (Pointer_hash) in
        let map = of_seq (List.to_seq assoc) in
        fun ptr -> find_opt ptr map
      in
      let cell_ptr = hash_skip_list_cell b in
      let target_ptr = hash_skip_list_cell a in
      fail_unless
        (Skip_list.valid_back_path
           ~equal_ptr:Pointer_hash.equal
           ~deref
           ~cell_ptr
           ~target_ptr
           path)
        (dal_proof_error "verify_proof: invalid Dal inclusion proof")

    let verify_proof dal_params page_id snapshot proof =
      let open Lwt_tzresult_syntax in
      let {Page.published_level; slot_index; page_index = _} = page_id in
      let*? snapshot, dummy_upper_slot, _deref =
        push_upper_dummy_slot published_level snapshot no_history_cache
      in
      match proof with
      | Page_confirmed {page_content; page_proof; inc_proof} ->
          let* target =
            match List.last_opt inc_proof with
            | Some e -> return e
            | None -> proof_error "verify_proof: inc_proof is empty"
          in
          let* () =
            check_not_dummy_slots
              (Skip_list.content target)
              zero
              dummy_upper_slot
          in
          let* () = verify_inclusion_proof inc_proof target snapshot in
          let* () =
            verify_page
              dal_params
              page_proof
              page_content
              page_id
              (Skip_list.content target).header
          in
          (* FIXME/DAL: Not sure this is sufficient. In the input_repr version,
             there are much more checks *)
          return_some (Some page_content)
      | Page_unconfirmed {prev_inc_proof} ->
          let* prev_history, next_history =
            match List.rev prev_inc_proof with
            | prev :: next :: _ -> return (prev, next)
            | _ ->
                (* An unconfirmation proof should contain at least two elements,
                   as
                   - our skip list is initialized with the slot zero
                   - a dummy upper slot is inserted (by produce_proof) before
                   producing the proof.
                   These two slots verify:
                     `zero.published_level < page_id.published_level` AND
                     `page_id.published_level < dummy_upper_slot.published_level`
                   So a proof that the target doesn't exist should include them.
                *)
                proof_error "verify_proof: invalid prev_inc_proof"
          in
          let* () =
            verify_inclusion_proof prev_inc_proof prev_history snapshot
          in
          let* () =
            fail_unless
              (let prev_cell_pointer = Skip_list.back_pointer next_history 0 in
               match prev_cell_pointer with
               | None -> false
               | Some prev_ptr ->
                   Pointer_hash.equal
                     prev_ptr
                     (hash_skip_list_cell prev_history))
              (dal_proof_error "verify_proof: invalid prev_inc_proof")
          in
          let* () =
            fail_unless
              Compare.Int.(
                let fake_target =
                  {published_level; index = slot_index; header = Header.zero}
                in
                slot_id_compare fake_target zero > 0
                || slot_id_compare fake_target dummy_upper_slot < 0)
              (dal_proof_error "verify_proof: invalid prev_inc_proof")
          in
          return_none
  end

  include V1
end

let encoding = slot_encoding

let pp = pp_slot

let equal = slot_equal
