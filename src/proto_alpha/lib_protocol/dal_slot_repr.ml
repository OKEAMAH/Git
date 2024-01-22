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

type parameters = Dal.parameters = {
  redundancy_factor : int;
  page_size : int;
  slot_size : int;
  number_of_shards : int;
}

let parameters_encoding = Dal.parameters_encoding

module Commitment = struct
  (* DAL/FIXME https://gitlab.com/tezos/tezos/-/issues/3389

     It is not clear whether the size of the slot associated to the
     commitment should be given here. *)
  type t = Dal.commitment

  let equal = Dal.Commitment.equal

  let encoding = Dal.Commitment.encoding

  let pp = Dal.Commitment.pp

  let zero = Dal.Commitment.zero

  let of_b58check_opt = Dal.Commitment.of_b58check_opt
end

module Commitment_proof = struct
  type t = Dal.commitment_proof

  let encoding = Dal.Commitment_proof.encoding

  let zero = Dal.Commitment_proof.zero
end

module Header = struct
  type id = {published_level : Raw_level_repr.t; index : Dal_slot_index_repr.t}

  type t = {id : id; commitment : Commitment.t}

  let slot_id_equal {published_level; index} s2 =
    Raw_level_repr.equal published_level s2.published_level
    && Dal_slot_index_repr.equal index s2.index

  let equal {id; commitment} s2 =
    slot_id_equal id s2.id && Commitment.equal commitment s2.commitment

  let id_encoding =
    let open Data_encoding in
    conv
      (fun {published_level; index} -> (published_level, index))
      (fun (published_level, index) -> {published_level; index})
      (obj2
         (req "level" Raw_level_repr.encoding)
         (req "index" Dal_slot_index_repr.encoding))

  let encoding =
    let open Data_encoding in
    conv
      (fun {id; commitment} -> (id, commitment))
      (fun (id, commitment) -> {id; commitment})
      (merge_objs id_encoding (obj1 (req "commitment" Commitment.encoding)))

  let pp_id fmt {published_level; index} =
    Format.fprintf
      fmt
      "published_level: %a, index: %a"
      Raw_level_repr.pp
      published_level
      Dal_slot_index_repr.pp
      index

  let pp fmt {id; commitment = c} =
    Format.fprintf fmt "id:(%a), commitment: %a" pp_id id Commitment.pp c

  let verify_commitment cryptobox commitment proof =
    Ok (Dal.verify_commitment cryptobox commitment proof)
end

module Slot_index = Dal_slot_index_repr

module Page = struct
  type content = Bytes.t

  type slot_index = Dal_slot_index_repr.t

  let pages_per_slot = Dal.pages_per_slot

  module Index = struct
    type t = int

    let zero = 0

    let encoding = Data_encoding.int16

    let pp = Format.pp_print_int

    let compare = Compare.Int.compare

    let equal = Compare.Int.equal
  end

  type t = {slot_id : Header.id; page_index : Index.t}

  type proof = Dal.page_proof

  let encoding =
    let open Data_encoding in
    conv
      (fun {slot_id = {published_level; index}; page_index} ->
        (published_level, index, page_index))
      (fun (published_level, index, page_index) ->
        {slot_id = {published_level; index}; page_index})
      (obj3
         (req "published_level" Raw_level_repr.encoding)
         (req "slot_index" Slot_index.encoding)
         (req "page_index" Index.encoding))

  let equal {slot_id; page_index} p =
    Header.slot_id_equal slot_id p.slot_id
    && Index.equal page_index p.page_index

  let proof_encoding = Dal.page_proof_encoding

  let content_encoding = Data_encoding.(bytes Hex)

  let pp fmt {slot_id = {published_level; index}; page_index} =
    Format.fprintf
      fmt
      "(published_level: %a, slot_index: %a, page_index: %a)"
      Raw_level_repr.pp
      published_level
      Slot_index.pp
      index
      Index.pp
      page_index

  let pp_proof fmt proof =
    Data_encoding.Json.pp
      fmt
      (Data_encoding.Json.construct proof_encoding proof)
end

module Slot_market = struct
  (* DAL/FIXME https://gitlab.com/tezos/tezos/-/issues/3108

     Think harder about this data structure and whether it can be
     optimized. *)

  module Slot_index_map = Map.Make (Dal_slot_index_repr)

  type t = {length : int; slot_headers : Header.t Slot_index_map.t}

  let init ~length =
    if Compare.Int.(length < 0) then
      invalid_arg "Dal_slot_repr.Slot_market.init: length cannot be negative" ;
    let slot_headers = Slot_index_map.empty in
    {length; slot_headers}

  let length {length; _} = length

  let register t new_slot_header =
    let open Header in
    if
      not
        Compare.Int.(
          0 <= Dal_slot_index_repr.to_int new_slot_header.id.index
          && Dal_slot_index_repr.to_int new_slot_header.id.index < t.length)
    then None
    else
      let has_changed = ref false in
      let update = function
        | None ->
            has_changed := true ;
            Some new_slot_header
        | Some x -> Some x
      in
      let slot_headers =
        Slot_index_map.update new_slot_header.id.index update t.slot_headers
      in
      let t = {t with slot_headers} in
      Some (t, !has_changed)

  let candidates t =
    t.slot_headers |> Slot_index_map.to_seq |> Seq.map snd |> List.of_seq
end

module History = struct
  (* History is represented via a skip list. The content of the cell
     is the list of headers attested for a given level. *)

  module Content_prefix = struct
    let (_prefix : string) = "dash1"

    (* 32 *)
    let b58check_prefix = "\002\224\072\094\219" (* dash1(55) *)

    let size = Some 32

    let name = "dal_skip_list_content"

    let title = "A hash to represent the content of a cell in the skip list"
  end

  module Content_hash = Blake2B.Make (Base58) (Content_prefix)

  (* Pointers of the skip lists are used to encode the content and the
     backpointers. *)
  module Pointer_prefix = struct
    let (_prefix : string) = "dask1"

    (* 32 *)
    let b58check_prefix = "\002\224\072\115\035" (* dask1(55) *)

    let size = Some 32

    let name = "dal_skip_list_pointer"

    let title = "A hash that represents the skip list pointers"
  end

  module Pointer_hash = Blake2B.Make (Base58) (Pointer_prefix)

  module Skip_list_parameters = struct
    let basis = 4
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

  module Content = struct
    type t = {
      published_level : Raw_level_repr.t;
      slot_headers : (Commitment.t * Dal_slot_index_repr.t) list;
    }

    let encoding =
      let open Data_encoding in
      conv
        (fun {published_level; slot_headers} -> (published_level, slot_headers))
        (fun (published_level, slot_headers) -> {published_level; slot_headers})
        (obj2
           (req "published_level" Raw_level_repr.encoding)
           (req
              "slot_headers"
              (list
                 (obj2
                    (req "slot_commitment" Commitment.encoding)
                    (req "slot_index" Dal_slot_index_repr.encoding)))))

    let equal t1 {published_level; slot_headers} =
      Raw_level_repr.equal t1.published_level published_level
      && List.equal
           (fun (c1, i1) (c2, i2) ->
             Dal_slot_index_repr.equal i1 i2 && Commitment.equal c1 c2)
           t1.slot_headers
           slot_headers

    let zero = {published_level = Raw_level_repr.root; slot_headers = []}

    let pp =
      let pp_pair fmt (commitment, index) =
        Format.fprintf
          fmt
          "(%a, %a)"
          Commitment.pp
          commitment
          Dal_slot_index_repr.pp
          index
      in
      fun fmt {published_level; slot_headers} ->
        Format.fprintf
          fmt
          "{published_level:%a; slot_headers:[%a]}"
          Raw_level_repr.pp
          published_level
          (Format.pp_print_list
             ~pp_sep:(fun fmt () -> Format.fprintf fmt ";@ ")
             pp_pair)
          slot_headers
  end

  module Skip_list = struct
    include Skip_list.Make (Skip_list_parameters)

    (** All confirmed DAL slots will be stored in a skip list, where only the
        last cell is remembered in the L1 context. The skip list is used in
        the proof phase of a refutation game to verify whether a given slot
        exists (i.e., confirmed) or not in the skip list. The skip list is
        supposed to be sorted, as its 'search' function explicitly uses a given
        `compare` function during the list traversal to quickly (in log(size))
        reach the target if any.

        In our case, we will add one cell per L1 level to the skip list
        containing the list of attested slots published at that level.

        Below, we redefine the [next] function (that allows adding elements
        on top of the list) to enforce that the constructed skip list is
        well-sorted. We also define a wrapper around the search function to
        guarantee that it can only be called with the adequate compare function.

        The function assumes that the slots indices of the list in [elt] are
        well ordered. *)
    let next ~prev_cell ~prev_cell_ptr elt =
      let open Result_syntax in
      let* () =
        error_unless
          (Compare.Int.( = )
             (Raw_level_repr.compare
                elt.Content.published_level
                (Raw_level_repr.succ
                   (content prev_cell).Content.published_level))
             0)
          Add_element_in_slots_skip_list_violates_ordering
      in
      return @@ next ~prev_cell ~prev_cell_ptr elt

    (** To produce a valid proof, the function [search] below assumes that the
        co-domain of the [deref] function (implemented as a lookup in a provided
        history cache in {!produce_proof_repr} below) should contain all the
        skip list' cells from level [target_level] to level
        [cell.published_level]. *)
    let search ~deref ~cell ~target_level =
      Lwt.search ~deref ~cell ~compare:(fun Content.{published_level; _} ->
          Raw_level_repr.compare published_level target_level)
  end

  module V1 = struct
    (* TODO/DAL: https://gitlab.com/tezos/tezos/-/issues/3765
       Decide how to store attested slots in the skip list's content. *)
    type content = Content.t

    (* A pointer to a cell is the hash of its content and all the back
       pointers. *)
    type hash = Pointer_hash.t

    type history = (content, hash) Skip_list.cell

    type t = history

    let genesis : t = Skip_list.genesis Content.zero

    let history_encoding =
      let open Data_encoding in
      (* The history_encoding is given as a union of two versions of the skip
         list:

         In the first version of the Dal skip list, we were storing one attested
         slot header per cell. So, genesis was of the form [Skip_list.genesis
         slot_header_zero], where [slot_header_zero] is a dummy slot supposed to
         be published at level [Raw_level_repr.root] with a commitment
         [Commitment.zero].

         The new version of Dal skip lists are not compatible with the old ones.
         The legacy case is meant for the transition setting where refutation
         games may have started on the old protocol and are continuing on the
         new one. Since, Dal genesis skip list is snapshotted even if Dal
         feature flag is disabled, we should decode the old genesis cell (in a
         hackish way), and immediately return the new represtation of
         genesis. The second case implements the normal encoding of the (new)
         skip list representation.

         Once the transition is done, the "dal_skip_list_legacy" case with "Tag
         0" could be removed. *)
      union
        ~tag_size:`Uint8
        [
          case
            ~title:"dal_skip_list_legacy"
            (Tag 0)
            (obj2
               (req "kind" (constant "dal_skip_list_legacy"))
               (req "skip_list" (Data_encoding.Fixed.bytes Hex 57)))
            (fun _ -> None)
            (fun ((), _) -> genesis);
          case
            ~title:"dal_skip_list_v2"
            (Tag 1)
            (obj2
               (req "kind" (constant "dal_skip_list_v2"))
               (req
                  "skip_list"
                  (Skip_list.encoding Pointer_hash.encoding Content.encoding)))
            (fun x -> Some ((), x))
            (fun ((), x) -> x);
        ]

    let equal_history : history -> history -> bool =
      Skip_list.equal Pointer_hash.equal Content.equal

    let encoding = history_encoding

    let equal : t -> t -> bool = equal_history

    let hash cell =
      let current_slot = Skip_list.content cell in
      let back_pointers_hashes = Skip_list.back_pointers cell in
      Data_encoding.Binary.to_bytes_exn Content.encoding current_slot
      :: List.map Pointer_hash.to_bytes back_pointers_hashes
      |> Pointer_hash.hash_bytes

    let pp_history fmt (history : history) =
      let history_hash = hash history in
      Format.fprintf
        fmt
        "@[hash : %a@;%a@]"
        Pointer_hash.pp
        history_hash
        (Skip_list.pp ~pp_content:Content.pp ~pp_ptr:Pointer_hash.pp)
        history

    let published_level_of_last_cell t =
      (Skip_list.content t).Content.published_level

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

    (* check that the slots' levels are equal to [published_level] and that teir
       indices are well ordered. *)
    let check_same_level_and__well_ordered published_level = function
      | [] -> true
      | Header.{id = {published_level = pl; index}; _} :: l ->
          Raw_level_repr.equal published_level pl
          && fst
             @@ List.fold_left
                  (fun (well_ordered, idx)
                       Header.{id = {published_level = pl; index = idx'}; _} ->
                    ( well_ordered
                      && Raw_level_repr.equal published_level pl
                      && Compare.Int.( < )
                           (Dal_slot_index_repr.compare idx idx')
                           0,
                      idx' ))
                  (true, index)
                  l

    let add_confirmed_slot_header =
      let sl_genesis_level =
        (Skip_list.content genesis).Content.published_level
      in
      fun (t, cache) published_level slot_headers ->
        let open Result_syntax in
        let* () =
          error_unless
            (check_same_level_and__well_ordered published_level slot_headers)
            Add_element_in_slots_skip_list_violates_ordering
        in
        let prev_cell_ptr = hash t in
        let slot_headers =
          List.map
            (fun Header.{commitment; id = {index; _}} -> (commitment, index))
            slot_headers
        in
        let slot_headers = Content.{published_level; slot_headers} in
        let* cache = History_cache.remember prev_cell_ptr t cache in
        if
          Raw_level_repr.equal
            (Skip_list.content t).published_level
            sl_genesis_level
        then
          (* If this is the first real cell of DAL, replace dummy genesis with
             it. *)
          return (Skip_list.genesis slot_headers, cache)
        else
          let* new_cell =
            Skip_list.next ~prev_cell:t ~prev_cell_ptr slot_headers
          in
          return (new_cell, cache)

    let add_confirmed_slot_headers (t : t) cache published_level slot_headers =
      add_confirmed_slot_header (t, cache) published_level slot_headers

    let add_confirmed_slot_headers_no_cache =
      let open Result_syntax in
      let no_cache = History_cache.empty ~capacity:0L in
      fun t published_level slots ->
        let+ cell, (_ : History_cache.t) =
          add_confirmed_slot_header (t, no_cache) published_level slots
        in
        cell

    (* Dal proofs section *)

    (** An inclusion proof, for a page ID, is a list of the slots' history
        skip list's cells that encodes a minimal path:

        - from a starting cell, which serves as a reference. It is usually
        called 'snapshot' below,

        - to a final cell that have the same published_level than the page. Then
        list of attested (confirmed) slots of that cell then either contain the
        slot ID of the page (slot/page confirmation case) or not (unconfirmation
        case).

         Using the starting cell as a trustable starting point (i.e. maintained
         and provided by L1), and combined with the extra information stored in
         the {!proof} type below, one can verify if a slot (and then a page of
         that slot) is confirmed on L1 or not. *)
    type inclusion_proof = history list

    (** (See the documentation in the mli file to understand what we want to
        prove in game refutation involving Dal and why.)

        A Dal proof is an algebraic datatype with two cases, where we basically
        prove that a Dal page is confirmed on L1 or not. Being 'not confirmed'
        here includes the case where the slot's header is not published and the
        case where the slot's header is published, but the attesters didn't
        confirm the availability of its data.

        To produce a proof representation for a page (see function
        {!produce_proof_repr} below), we assume given:

        - [page_id], identifies the page;

        - [slots_history], a current/recent cell of the slots history skip list.
        Typically, it should be the skip list cell snapshotted when starting the
        refutation game;

       - [history_cache], a sufficiently large slots history cache, to navigate
       back through the successive cells of the skip list. Typically, the cache
       should at least contain the cells starting from the published level of
       the page ID for which we want to generate a proof. Indeed, inclusion
       proofs encode paths through skip lists' cells where the head is the
       reference/snapshot cell and the last element is the target cell inserted
       at the level corresponding to the page's published level). Note that, in
       case the level of the page is far in the past (i.e. the skip list was not
       populated yet) should be handled by the caller ;

        - [page_info], that provides the page's information (the content and the
        slot membership proof) for page_id. In case the page is supposed to be
        confirmed, this argument should contain the page's content and the proof
        that the page is part of the (confirmed) slot whose ID is given in
        [page_id]. In case we want to show that the page is not confirmed, the
        value [page_info] should be [None].

      [dal_parameters] is used when verifying that/if the page is part of
      the candidate slot (if any).

*)
    type proof_repr =
      | Page_confirmed of {
          target_cell : history;
              (** [target_cell] is a cell whose content contains the slot to
                  which the page belongs to. *)
          inc_proof : inclusion_proof;
              (** [inc_proof] is a (minimal) path in the skip list that proves
                  cells inclusion. The head of the list is the [slots_history]
                  provided to produce the proof. The last cell's content is
                  the slot containing the page identified by [page_id],
                  that is: [target_cell]. *)
          page_data : Page.content;
              (** [page_data] is the content of the page. *)
          page_proof : Page.proof;
              (** [page_proof] is the proof that the page whose content is
                  [page_data] is actually the [page_id.page_index]th page of
                  the slot stored in [target_cell] and identified by
                  page_id.slot_id. *)
        }  (** The case where the slot's page is confirmed/attested on L1. *)
      | Page_unconfirmed of {target_cell : history; inc_proof : inclusion_proof}
          (** The case where the slot's page doesn't exist or is not confirmed
              on L1. The fields are similar to {!Page_confirmed} case except
              that the list of attested slots in [target_cell] doesn't cantain
              the page's slot index as the page is not confirmed. In this case,
              there is no page data or page proof to provide as well.

              As said above, in case the level of the page is far in the past
              (i.e. the skip list was not populated yet) should be handled by
              the caller. In fact, the [proof_repr] type here only cover levels
              where a new cell has been added to the skip list. *)

    let proof_repr_encoding =
      let open Data_encoding in
      let case_page_confirmed =
        case
          ~title:"confirmed dal page proof representation"
          (Tag 0)
          (obj5
             (req "kind" (constant "confirmed"))
             (req "target_cell" history_encoding)
             (req "inc_proof" (list history_encoding))
             (req "page_data" (bytes Hex))
             (req "page_proof" Page.proof_encoding))
          (function
            | Page_confirmed {target_cell; inc_proof; page_data; page_proof} ->
                Some ((), target_cell, inc_proof, page_data, page_proof)
            | _ -> None)
          (fun ((), target_cell, inc_proof, page_data, page_proof) ->
            Page_confirmed {target_cell; inc_proof; page_data; page_proof})
      and case_page_unconfirmed =
        case
          ~title:"unconfirmed dal page proof representation"
          (Tag 1)
          (obj3
             (req "kind" (constant "unconfirmed"))
             (req "target_cell" history_encoding)
             (req "inc_proof" (list history_encoding)))
          (function
            | Page_unconfirmed {target_cell; inc_proof} ->
                Some ((), target_cell, inc_proof)
            | _ -> None)
          (fun ((), target_cell, inc_proof) ->
            Page_unconfirmed {target_cell; inc_proof})
      in

      union [case_page_confirmed; case_page_unconfirmed]

    (** Proof's type is set to bytes and not a structural datatype because
        when a proof appears in a tezos operation or in an rpc, a user can not
        reasonably understand the proof, thus it eases the work of people decoding
        the proof by only supporting bytes and not the whole structured proof. *)

    type proof = bytes

    (** DAL/FIXME: https://gitlab.com/tezos/tezos/-/issues/4084
        DAL proof's encoding should be bounded *)
    let proof_encoding = Data_encoding.(bytes Hex)

    type error += Dal_invalid_proof_serialization

    let () =
      register_error_kind
        `Permanent
        ~id:"Dal_slot_repr.invalid_proof_serialization"
        ~title:"Dal invalid proof serialization"
        ~description:"Error occured during dal proof serialization"
        Data_encoding.unit
        (function Dal_invalid_proof_serialization -> Some () | _ -> None)
        (fun () -> Dal_invalid_proof_serialization)

    let serialize_proof proof =
      let open Result_syntax in
      match Data_encoding.Binary.to_bytes_opt proof_repr_encoding proof with
      | None -> tzfail Dal_invalid_proof_serialization
      | Some serialized_proof -> return serialized_proof

    type error += Dal_invalid_proof_deserialization

    let () =
      register_error_kind
        `Permanent
        ~id:"Dal_slot_repr.invalid_proof_deserialization"
        ~title:"Dal invalid proof deserialization"
        ~description:"Error occured during dal proof deserialization"
        Data_encoding.unit
        (function Dal_invalid_proof_deserialization -> Some () | _ -> None)
        (fun () -> Dal_invalid_proof_deserialization)

    let deserialize_proof proof =
      let open Result_syntax in
      match Data_encoding.Binary.of_bytes_opt proof_repr_encoding proof with
      | None -> tzfail Dal_invalid_proof_deserialization
      | Some deserialized_proof -> return deserialized_proof

    let pp_inclusion_proof = Format.pp_print_list pp_history

    let pp_proof ~serialized fmt p =
      if serialized then Format.pp_print_string fmt (Bytes.to_string p)
      else
        match deserialize_proof p with
        | Error msg -> Error_monad.pp_trace fmt msg
        | Ok proof -> (
            match proof with
            | Page_confirmed {target_cell; inc_proof; page_data; page_proof} ->
                Format.fprintf
                  fmt
                  "Page_confirmed (target_cell=%a, data=%s,@ \
                   inc_proof:[size=%d |@ path=%a]@ page_proof:%a)"
                  pp_history
                  target_cell
                  (Bytes.to_string page_data)
                  (List.length inc_proof)
                  pp_inclusion_proof
                  inc_proof
                  Page.pp_proof
                  page_proof
            | Page_unconfirmed {target_cell; inc_proof} ->
                Format.fprintf
                  fmt
                  "Page_unconfirmed (target_cell = %a | inc_proof:[size=%d@ | \
                   path=%a])"
                  pp_history
                  target_cell
                  (List.length inc_proof)
                  pp_inclusion_proof
                  inc_proof)

    type error +=
      | Dal_proof_error of string
      | Unexpected_page_size of {expected_size : int; page_size : int}

    let () =
      let open Data_encoding in
      register_error_kind
        `Permanent
        ~id:"dal_slot_repr.slots_history.dal_proof_error"
        ~title:"Dal proof error"
        ~description:"Error occurred during Dal proof production or validation"
        ~pp:(fun ppf e -> Format.fprintf ppf "Dal proof error: %s" e)
        (obj1 (req "error" (string Plain)))
        (function Dal_proof_error e -> Some e | _ -> None)
        (fun e -> Dal_proof_error e)

    let () =
      let open Data_encoding in
      register_error_kind
        `Permanent
        ~id:"dal_slot_repr.slots_history.unexpected_page_size"
        ~title:"Unexpected page size"
        ~description:
          "The size of the given page content doesn't match the expected one."
        ~pp:(fun ppf (expected, size) ->
          Format.fprintf
            ppf
            "The size of a Dal page is expected to be %d bytes. The given one \
             has %d"
            expected
            size)
        (obj2 (req "expected_size" int16) (req "page_size" int16))
        (function
          | Unexpected_page_size {expected_size; page_size} ->
              Some (expected_size, page_size)
          | _ -> None)
        (fun (expected_size, page_size) ->
          Unexpected_page_size {expected_size; page_size})

    let dal_proof_error reason = Dal_proof_error reason

    let proof_error reason = error @@ dal_proof_error reason

    let check_page_proof dal_params proof data ({Page.page_index; _} as pid)
        commitment =
      let open Result_syntax in
      let* dal =
        match Dal.make dal_params with
        | Ok dal -> return dal
        | Error (`Fail s) -> proof_error s
      in
      let fail_with_error_msg what =
        Format.kasprintf proof_error "%s (page id=%a)." what Page.pp pid
      in
      match Dal.verify_page dal commitment ~page_index data proof with
      | Ok true -> return_unit
      | Ok false ->
          fail_with_error_msg
            "Wrong page content for the given page index and slot commitment"
      | Error `Segment_index_out_of_range ->
          fail_with_error_msg "Segment_index_out_of_range"
      | Error `Page_length_mismatch ->
          tzfail
          @@ Unexpected_page_size
               {
                 expected_size = dal_params.page_size;
                 page_size = Bytes.length data;
               }

    (** The produce_proof function assumes that some invariants hold, such as:
        - The DAL has been activated,
        - The level of page is after DAL activation level.

        Under these assumptions, we recall that we maintain an invariant
        ensuring that we a have a cell in the skip list at every level after DAL
        activation. *)
    let produce_proof_repr dal_params page_id ~page_info ~get_history slots_hist
        =
      let open Lwt_result_syntax in
      let Page.{slot_id = {published_level; index}; page_index = _} = page_id in
      (* We first search for the slots attested at level [published_level]. *)
      let*! search_result =
        Skip_list.search
          ~deref:get_history
          ~target_level:published_level
          ~cell:slots_hist
      in
      (* The search should necessiraly find a cell in the skip list (assuming
         enough cache is given) under the assumptions made when calling
         {!produce_proof_repr}. *)
      match search_result.Skip_list.last_cell with
      | Deref_returned_none ->
          tzfail
          @@ dal_proof_error
               "Skip_list.search returned 'Deref_returned_none': Slots history \
                cache is ill-formed or has too few entries."
      | No_exact_or_lower_ptr ->
          tzfail
          @@ dal_proof_error
               "Skip_list.search returned 'No_exact_or_lower_ptr', while it is \
                initialized with a min elt (slot zero)."
      | Nearest _ ->
          (* This could happen in practice: there is one cell at each level
             after DAL activation. The case where the page's level is before DAL
             activation level should be handled by the caller
             ({!Sc_refutation_proof.produce} in our case). *)
          tzfail
          @@ dal_proof_error
               "Skip_list.search returned Nearest', while all given levels to \
                produce proofs are supposed to be in the skip list."
      | Found target_cell -> (
          let target_slot_opt =
            List.find_opt
              (fun (_commitment, idx) -> Dal_slot_index_repr.equal index idx)
              (Skip_list.content target_cell).Content.slot_headers
          in
          match (page_info, target_slot_opt) with
          | Some (page_data, page_proof), Some (commitment, _index) ->
              (* The case where the slot to which the page is supposed to belong
                 is found and the page's information are given. *)
              let*? () =
                (* We check the page's proof against the commitment. *)
                check_page_proof
                  dal_params
                  page_proof
                  page_data
                  page_id
                  commitment
              in
              let inc_proof = List.rev search_result.Skip_list.rev_path in
              let*? () =
                error_when
                  (List.is_empty inc_proof)
                  (dal_proof_error "The inclusion proof cannot be empty")
              in
              (* All checks succeeded. We return a `Page_confirmed` proof. *)
              return
                ( Page_confirmed {target_cell; inc_proof; page_data; page_proof},
                  Some page_data )
          | None, None ->
              (* The slot corresponding to the given page's index is not found in
                 the attested slots of the page's level, and no information is
                 given for that page. So, we produce a proof that the page is not
                 attested. *)
              let inc_proof = List.rev search_result.Skip_list.rev_path in
              return (Page_unconfirmed {target_cell; inc_proof}, None)
          | None, Some _ ->
              (* Mismatch: case where no page information are given, but the
                 slot is attested. *)
              tzfail
              @@ dal_proof_error
                   "The page ID's slot is confirmed, but no page content and \
                    proof are provided."
          | Some _, None ->
              (* Mismatch: case where page information are given, but the slot
                 is not attested. *)
              tzfail
              @@ dal_proof_error
                   "The page ID's slot is not confirmed, but page content and \
                    proof are provided.")

    let produce_proof dal_params page_id ~page_info ~get_history slots_hist =
      let open Lwt_result_syntax in
      let* proof_repr, page_data =
        produce_proof_repr dal_params page_id ~page_info ~get_history slots_hist
      in
      let*? serialized_proof = serialize_proof proof_repr in
      return (serialized_proof, page_data)

    (* Given a starting cell [snapshot] and a (final) [target], this function
       checks that the provided [inc_proof] encodes a minimal path from
       [snapshot] to [target]. *)
    let verify_inclusion_proof inc_proof ~src:snapshot ~dest:target =
      let assoc = List.map (fun c -> (hash c, c)) inc_proof in
      let path = List.split assoc |> fst in
      let deref =
        let open Map.Make (Pointer_hash) in
        let map = of_seq (List.to_seq assoc) in
        fun ptr -> find_opt ptr map
      in
      let snapshot_ptr = hash snapshot in
      let target_ptr = hash target in
      error_unless
        (Skip_list.valid_back_path
           ~equal_ptr:Pointer_hash.equal
           ~deref
           ~cell_ptr:snapshot_ptr
           ~target_ptr
           path)
        (dal_proof_error "verify_proof_repr: invalid inclusion Dal proof.")

    let verify_proof_repr dal_params page_id snapshot proof =
      let open Result_syntax in
      let Page.{slot_id = Header.{published_level; index}; page_index = _} =
        page_id
      in
      let* target_cell, inc_proof, page_proof_check =
        match proof with
        | Page_confirmed {target_cell; inc_proof; page_data; page_proof} ->
            let page_proof_check =
              Some
                (fun commitment ->
                  (* We check that the page indeed belongs to the target slot at the
                     given page index. *)
                  let* () =
                    check_page_proof
                      dal_params
                      page_proof
                      page_data
                      page_id
                      commitment
                  in
                  (* If the check succeeds, we return the data/content of the
                     page. *)
                  return page_data)
            in
            return (target_cell, inc_proof, page_proof_check)
        | Page_unconfirmed {target_cell; inc_proof} ->
            return (target_cell, inc_proof, None)
      in
      let slot_headers_with_level = Skip_list.content target_cell in
      (* We check that the target cell has the same level than the page we're
         about to prove. *)
      let* () =
        error_when
          Raw_level_repr.(
            slot_headers_with_level.published_level <> published_level)
          (dal_proof_error "verify_proof_repr: published_level mismatch.")
      in
      (* We check that the given inclusion proof indeed links our L1 snapshot to
         the target cell. *)
      let* () =
        verify_inclusion_proof inc_proof ~src:snapshot ~dest:target_cell
      in
      let target_slot_opt =
        List.find_opt
          (fun (_commitment, idx) -> Dal_slot_index_repr.equal index idx)
          slot_headers_with_level.Content.slot_headers
      in
      match (page_proof_check, target_slot_opt) with
      | None, None -> return_none
      | Some page_proof_check, Some (commitment, _idx) ->
          let* page_data = page_proof_check commitment in
          return_some page_data
      | Some _, None ->
          error
          @@ dal_proof_error
               "verify_proof_repr: the unconfirmation proof contains the \
                target slot."
      | None, Some _ ->
          error
          @@ dal_proof_error
               "verify_proof_repr: the confirmation proof doesn't contain the \
                attested slot."

    let verify_proof dal_params page_id snapshot serialized_proof =
      let open Result_syntax in
      let* proof_repr = deserialize_proof serialized_proof in
      verify_proof_repr dal_params page_id snapshot proof_repr

    module Internal_for_tests = struct
      type cell_content = Content.t = {
        published_level : Raw_level_repr.t;
        slot_headers : (Commitment.t * Dal_slot_index_repr.t) list;
      }

      let content = Skip_list.content

      let proof_statement_is serialized_proof expected =
        match deserialize_proof serialized_proof with
        | Error _ -> false
        | Ok proof -> (
            match (expected, proof) with
            | `Confirmed, Page_confirmed _ | `Unconfirmed, Page_unconfirmed _ ->
                true
            | _ -> false)
    end
  end

  include V1
end
