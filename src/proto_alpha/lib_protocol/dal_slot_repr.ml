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

  let zero = Dal.Commitment.zero
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

  let ( < ) = Compare.Int.( < )

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

    let add_confirmed_slots_no_cache =
      let no_cache = History_cache.empty ~capacity:0L in
      fun t slots ->
        List.fold_left_e add_confirmed_slot (t, no_cache) slots >|? fst

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
          slot_kate : Header.t;
          inc_proof : inclusion_proof;
        }
      | Page_unconfirmed of {
          prev_confirmed_slot : slot option;
          next_confirmed_slot : slot option;
          next_inc_proof : inclusion_proof;
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
             (req "prev_confirmed_slot" (option slot_encoding))
             (req "next_confirmed_slot" (option slot_encoding))
             (req "inc_proof" (list history_encoding)))
          (function
            | Page_unconfirmed
                {prev_confirmed_slot; next_confirmed_slot; next_inc_proof} ->
                Some
                  ((), prev_confirmed_slot, next_confirmed_slot, next_inc_proof)
            | _ -> None)
          (fun ((), prev_confirmed_slot, next_confirmed_slot, next_inc_proof) ->
            Page_unconfirmed
              {prev_confirmed_slot; next_confirmed_slot; next_inc_proof})
      in

      union [case_page_confirmed; case_page_unconfirmed]

    let pp_slot_opt fmt = function
      | None -> Format.fprintf fmt "<no-slot>"
      | Some s -> Format.fprintf fmt "%a" pp_slot s

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
          {prev_confirmed_slot; next_confirmed_slot; next_inc_proof = _} ->
          Format.fprintf
            fmt
            "Page_unconfirmed (prev_confirmed_slot=%a, \
             next_confirmed_slot=%a,inc_proof=())"
            pp_slot_opt
            prev_confirmed_slot
            pp_slot_opt
            next_confirmed_slot

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

    (** Utility function; we convert all our calls to be consistent with
      [Lwt_tzresult_syntax]. *)
    let option_to_result error_case lwt_opt =
      let open Lwt_syntax in
      let* opt = lwt_opt in
      match opt with None -> error_case | Some x -> return (ok x)

    let lift_ptr_path deref ptr_path =
      let rec aux accu = function
        | [] -> Some (List.rev accu)
        | x :: xs -> Option.bind (deref x) @@ fun c -> aux (c :: accu) xs
      in
      aux [] ptr_path

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

    let check_true bool = fail_unless bool (dal_proof_error "invariant broken")

    let check_false bool = check_true (not bool)

    let produce_proof_aux dal_params page_content_opt page_id slots_history
        history_cache =
      let open Lwt_tzresult_syntax in
      let {Page.published_level; slot_index; page_index = _} = page_id in
      let cell_ptr = hash_skip_list_cell slots_history in
      let*? history_cache =
        History_cache.remember cell_ptr slots_history history_cache
      in
      let deref ptr = History_cache.find ptr history_cache in
      let compare target_level target_slot_index (s : slot) =
        Lwt.return
        @@
        let c = Raw_level_repr.compare target_level s.published_level in
        if Compare.Int.(c <> 0) then c
        else Index.compare target_slot_index s.index
      in
      let*! slot_path =
        Skip_list.search
          ~deref
          ~compare:(compare published_level slot_index)
          ~cell_ptr
      in
      match (slot_path, page_content_opt) with
      | Some _path, `Unattested _ ->
          proof_error
            "found a path to the slot target in the skip list, but failed to \
             retrieve the page's content"
      | None, `Attested _ ->
          (* FIXME/DAL-REFUTATION: We should ignore the page content in this case. *)
          proof_error
            "found no path to the slot target in the skip list, but \n\
            \             retrieved the page's content"
      | Some path, `Attested (page_content, page_proof) ->
          let* inc =
            option_to_result
              (Format.kasprintf
                 proof_error
                 "failed to deref some level in the path")
              (Lwt.return (lift_ptr_path deref path))
          in
          let* last_slots_history (* aka level *) =
            option_to_result
              (Format.kasprintf
                 proof_error
                 "Skip_list.search returned empty list")
              (Lwt.return (List.last_opt inc))
          in
          let target_slot = Skip_list.content last_slots_history in
          let* () =
            verify_page
              dal_params
              page_proof
              page_content
              page_id
              target_slot.header
          in
          (* FIXME/DAL-REFUTATION: Why do we return page_content in both the proof and as
             input? *)
          return
          @@ ( Page_confirmed
                 {page_content; slot_kate = target_slot.header; inc_proof = inc},
               Some page_content )
      | None, `Unattested (prev_confirmed_slot, next_confirmed_slot) ->
          (* FIXME/DAL-REFUTATION:
             This version doesn't handle the case where:
             - the skip list is empty (no slot is confirmed yet)
             - there now no prev_confirmed_slot or next_confirmed_slot
             - we never check that the givel level is consistent wrt. DAL activation
             and SCORU origination (this second part is maybe done in proof_repr?).
          *)
          let check_slot_witness kind s =
            match s with
            | None -> return []
            | Some s ->
                option_to_result
                  (Format.kasprintf
                     proof_error
                     "%s attested slot witness not found in slots history cache"
                     kind)
                  (Skip_list.search
                     ~deref
                     ~compare:(compare s.published_level s.index)
                     ~cell_ptr)
          in
          let ( <|< ) s1 s2 =
            match (s1, s2) with
            | None, None -> assert false
            | Some s1, Some s2 ->
                Raw_level_repr.(s1.published_level < s2.published_level)
                || Raw_level_repr.(s1.published_level = s2.published_level)
                   && Slot_index.(s1.index < s2.index)
            | None, Some _ -> true
            | Some _, None -> true (* XXX *)
          in
          let* prev_path = check_slot_witness "prev" prev_confirmed_slot in
          let* next_path = check_slot_witness "next" next_confirmed_slot in
          let tmp_slot =
            Some {published_level; index = slot_index; header = Header.zero}
          in
          let* () =
            fail_unless
              (prev_confirmed_slot <|< tmp_slot)
              (Format.kasprintf
                 dal_proof_error
                 "prev given attested slot witness %a is greater than or equal \
                  to target page's slot %a"
                 pp_slot_opt
                 prev_confirmed_slot
                 Page.pp_id
                 page_id)
          in
          let* () =
            fail_unless
              (tmp_slot <|< next_confirmed_slot)
              (Format.kasprintf
                 dal_proof_error
                 "next given attested slot witness %a is smaller than or equal \
                  to target page's slot %a"
                 pp_slot_opt
                 next_confirmed_slot
                 Page.pp_id
                 page_id)
          in
          let* next_inc_proof =
            option_to_result
              (Format.kasprintf
                 proof_error
                 "failed to deref some pointer in the path of next witness")
              (Lwt.return (lift_ptr_path deref next_path))
          in
          let next_slots_history () =
            option_to_result
              (Format.kasprintf
                 proof_error
                 "Skip_list.search returned an empty list for next confirmed \
                  slot witness")
              (Lwt.return (List.last_opt next_inc_proof))
          in
          let prev_ptr () =
            option_to_result
              (Format.kasprintf
                 proof_error
                 "Skip_list.search returned an empty list for prev confirmed \
                  slot witness")
              (Lwt.return (List.last_opt prev_path))
          in
          let* () =
            match (prev_path, next_path) with
            | [], [] ->
                let* () = check_true (Option.is_none prev_confirmed_slot) in
                let* () = check_true (Option.is_none next_confirmed_slot) in
                (* This should be handled by case
                   ```
                                  | Some _slots_history, `Unattested (None, None) ->
                   ```
                   in function {!produce_proof} below.
                *)
                proof_error "should be unreachable"
            | [], _ ->
                (* We don't have a prev_slot witness. *)
                let* () = check_true (Option.is_none prev_confirmed_slot) in
                let* () = check_false (Option.is_none next_confirmed_slot) in
                let* next_slots_history = next_slots_history () in
                fail_unless
                  (match Skip_list.back_pointers next_slots_history with
                  | [] -> true
                  | _ -> false)
                  (* FIXME/DAL: This is not true if we decide to put an dummy
                     element in the skip list  to get rid of genesis's option / None. *)
                  (dal_proof_error
                     "If there is no lower slot witness, the upper version is \
                      supposed to be the first cell of the skip list")
            | _, [] ->
                (* We don't have a next_slot witness. *)
                let* () = check_false (Option.is_none prev_confirmed_slot) in
                let* () = check_true (Option.is_none next_confirmed_slot) in
                let* prev_ptr = prev_ptr () in
                let* prev_slots_history =
                  option_to_result
                    (Format.kasprintf
                       proof_error
                       "Finding skip list of prev_ptr failed")
                    (Lwt.return (deref prev_ptr))
                in
                fail_unless
                  (equal_history prev_slots_history slots_history)
                  (dal_proof_error
                     "prev slots history skip list should be equal to \
                      snapshotted skip list if there are no next slots added.")
            | _ :: _, _ :: _ ->
                let* () = check_false (Option.is_none prev_confirmed_slot) in
                let* () = check_false (Option.is_none next_confirmed_slot) in

                let* prev_ptr = prev_ptr () in
                let* next_slots_history = next_slots_history () in
                let* () =
                  match Skip_list.back_pointer next_slots_history 0 with
                  | None -> proof_error "next slot witness has no back-pointers"
                  | Some prev_history_ptr ->
                      fail_unless
                        (Pointer_hash.equal prev_history_ptr prev_ptr)
                        (dal_proof_error
                           "the prev slot witness is not the direct \
                            predecessor of the next slot witness")
                in
                return_unit
          in
          return
          @@ ( Page_unconfirmed
                 {prev_confirmed_slot; next_confirmed_slot; next_inc_proof},
               None )

    let produce_proof dal_params ~page_content_of page_id slots_history
        history_cache =
      let page_content_opt = page_content_of page_id in
      match (slots_history, page_content_opt) with
      | None, `Attested _ ->
          proof_error
            "Cannot provide a confirmation proof while the slots history is \
             empty"
      | None, `Unattested (_, Some _ | Some _, _) ->
          proof_error
            "provided lower/upper slot witness cannot be in an empty skip list"
      | None, `Unattested (None, None) ->
          (* FIXME/DAL: particular case: make a proof of non-confirmation with
             an empty slots_history skip list *)
          return
          @@ ( Page_unconfirmed
                 {
                   prev_confirmed_slot = None;
                   next_confirmed_slot = None;
                   next_inc_proof = assert false (* empty or singleton ? *);
                 },
               None )
      | Some _slots_history, `Unattested (None, None) ->
          proof_error
            "cannot have both lower and upper to None if slots_history is not \
             empty"
      | Some slots_history, _ ->
          produce_proof_aux
            dal_params
            page_content_opt
            page_id
            slots_history
            history_cache
  end

  include V1
end

let encoding = slot_encoding

let pp = pp_slot

let equal = slot_equal
