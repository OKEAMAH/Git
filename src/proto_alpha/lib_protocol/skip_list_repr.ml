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

module type S = sig
  type ('content, 'ptr) cell

  val pp :
    pp_ptr:(Format.formatter -> 'ptr -> unit) ->
    pp_content:(Format.formatter -> 'content -> unit) ->
    Format.formatter ->
    ('content, 'ptr) cell ->
    unit

  val equal :
    ('ptr -> 'ptr -> bool) ->
    ('content -> 'content -> bool) ->
    ('content, 'ptr) cell ->
    ('content, 'ptr) cell ->
    bool

  val encoding :
    'ptr Data_encoding.t ->
    'content Data_encoding.t ->
    ('content, 'ptr) cell Data_encoding.t

  val index : (_, _) cell -> int

  val content : ('content, 'ptr) cell -> 'content

  val back_pointer : ('content, 'ptr) cell -> int -> 'ptr option

  val back_pointers : ('content, 'ptr) cell -> 'ptr list

  val genesis : 'content -> ('content, 'ptr) cell

  val next :
    prev_cell:('content, 'ptr) cell ->
    prev_cell_ptr:'ptr ->
    'content ->
    ('content, 'ptr) cell

  val back_path :
    deref:('ptr -> ('content, 'ptr) cell option) ->
    cell_ptr:'ptr ->
    target_index:int ->
    'ptr list option

  val valid_back_path :
    equal_ptr:('ptr -> 'ptr -> bool) ->
    deref:('ptr -> ('content, 'ptr) cell option) ->
    cell_ptr:'ptr ->
    target_ptr:'ptr ->
    'ptr list ->
    bool

  type ('ptr, 'content) search_cell_result =
    | Found of ('ptr, 'content) cell
    | Nearest of {
        lower : ('ptr, 'content) cell;
        upper : ('ptr, 'content) cell option;
      }
    | No_exact_or_lower_ptr
    | Deref_returned_none

  type ('ptr, 'content) search_result = {
    rev_path : ('ptr, 'content) cell list;
    last_cell : ('ptr, 'content) search_cell_result;
  }

  val pp_search_result :
    pp_cell:(Format.formatter -> ('ptr, 'content) cell -> unit) ->
    Format.formatter ->
    ('ptr, 'content) search_result ->
    unit

  val search :
    deref:('ptr -> ('content, 'ptr) cell option) ->
    compare:(('content, 'ptr) cell -> int Lwt.t) ->
    cell:('content, 'ptr) cell ->
    ('content, 'ptr) search_result Lwt.t
end

module Make (Parameters : sig
  val basis : int
end) : S = struct
  let () = assert (Compare.Int.(Parameters.basis >= 2))

  open Parameters

  (*

      A cell of a skip list with some [`content] and back pointers of
      type [`ptr].

      Invariants
      ----------

      - back_pointers[i]
        = Some (pointer to (index - (index mod (basis ** i)) - 1))
          (for all i < length back_pointers)
       - length back_pointers = log basis index

      Notes
      -----

     - The [index] field is not strictly required but helps in making
       the data structure more robust. Indeed, otherwise, we should
       also ask the client to provide the index of the cell to be
       built, which can be error-prone.

     - The back pointers of a cell are chosen from the back pointers of
       its predecessor (except for the genesis cell) and a pointer to this
       predecessor. This locality makes the insertion of new cell very
       efficient in practice.

  *)
  type ('content, 'ptr) cell = {
    content : 'content;
    back_pointers : 'ptr option FallbackArray.t;
    index : int;
  }

  let equal equal_ptr equal_content cell1 cell2 =
    let equal_back_pointers b1 b2 =
      let open FallbackArray in
      Compare.Int.(length b1 = length b2)
      && fst
         @@ fold
              (fun (equal, i) h1 ->
                (equal && Option.equal equal_ptr h1 (get b2 i), i + 1))
              b1
              (true, 0)
    in
    let {content; back_pointers; index} = cell1 in
    equal_content content cell2.content
    && Compare.Int.equal index cell2.index
    && equal_back_pointers back_pointers cell2.back_pointers

  let index cell = cell.index

  let back_pointers_to_list a =
    FallbackArray.fold
      (fun l -> function
        | Some ptr -> ptr :: l
        | None -> (* By [cell] invariants. *) assert false)
      a
      []
    |> List.rev

  let pp ~pp_ptr ~pp_content fmt {content; back_pointers; index} =
    Format.fprintf
      fmt
      {|
       content = %a
       index = %d
       back_pointers = %a
    |}
      pp_content
      content
      index
      (Format.pp_print_list pp_ptr)
      (back_pointers_to_list back_pointers)

  let encoding ptr_encoding content_encoding =
    let of_list =
      FallbackArray.of_list ~fallback:None ~proj:(fun c -> Some c)
    in
    let to_list = back_pointers_to_list in
    let open Data_encoding in
    conv
      (fun {index; content; back_pointers} ->
        (index, content, to_list back_pointers))
      (fun (index, content, back_pointers) ->
        {index; content; back_pointers = of_list back_pointers})
      (obj3
         (req "index" int31)
         (req "content" content_encoding)
         (req "back_pointers" (list ptr_encoding)))

  let content cell = cell.content

  let back_pointers cell = back_pointers_to_list cell.back_pointers

  let genesis content =
    {index = 0; content; back_pointers = FallbackArray.make 0 None}

  let back_pointer cell i = FallbackArray.get cell.back_pointers i

  (* Precondition: i < length cell.back_pointers *)
  let back_pointer_unsafe cell i =
    match FallbackArray.get cell.back_pointers i with
    | Some ptr -> ptr
    | None -> (* By precondition and invariants of cells. *) assert false

  let next ~prev_cell ~prev_cell_ptr content =
    let index = prev_cell.index + 1 in
    let back_pointers =
      let rec aux power accu i =
        if Compare.Int.(index < power) then List.rev accu
        else
          let back_pointer_i =
            if Compare.Int.(index mod power = 0) then prev_cell_ptr
            else
              (* The following call is valid because of
                 - [i < List.length prev_cell.back_pointer]
                   because [log_basis index = log_basis prev_cell.index]
                 - the invariants of [prev_cell] *)
              back_pointer_unsafe prev_cell i
          in
          let accu = back_pointer_i :: accu in
          aux (power * basis) accu (i + 1)
      in
      aux 1 [] 0
    in
    let back_pointers =
      FallbackArray.of_list ~fallback:None ~proj:Option.some back_pointers
    in
    {index; content; back_pointers}

  (* returns the array of [basis^i] forall [i < len (back_pointers cell)] *)
  let list_powers cell =
    let rec aux n prev p =
      if Compare.Int.(n <= 0) then List.rev p
      else aux (n - 1) (basis * prev) (prev :: p)
    in
    FallbackArray.of_list
      ~fallback:0
      ~proj:(fun x -> x)
      (aux (FallbackArray.length cell.back_pointers) 1 [])

  (*
    [back_pointers] are sorted in decreasing order of their pointing cell index
    in the list. So we can do a [binary_search] to find the [cell] with the
    smallest index that is greater than [target] in the list.

    More formally, min({c : cell | c.index >= target.index}) where [c] is one of
    the pointed cells in the array of back pointers of the [cell] parameter.
  *)
  let best_skip cell target_index powers =
    let open FallbackArray in
    let pointed_cell_index i = cell.index - (cell.index mod get powers i) - 1 in
    let rec binary_search start_idx end_idx =
      if Compare.Int.(start_idx >= end_idx) then Some start_idx
      else
        let mid_idx = start_idx + ((end_idx - start_idx) / 2) in
        let mid_cell_index = pointed_cell_index mid_idx in
        if Compare.Int.(mid_cell_index = target_index) then Some mid_idx
        else if Compare.Int.(mid_cell_index < target_index) then
          binary_search start_idx (mid_idx - 1)
        else
          let prev_mid_cell_index = pointed_cell_index (mid_idx + 1) in
          if Compare.Int.(prev_mid_cell_index = target_index) then
            Some (mid_idx + 1)
          else if Compare.Int.(prev_mid_cell_index < target_index) then
            (*
              If (mid_cell_index > target_index) &&
                 (prev_mid_cell_index < target_index)
              then we found the closest cell to the target, which is mid_cell,
              so we return its index [mid_idx] in the array of back_pointers.
            *)
            Some mid_idx
          else binary_search (mid_idx + 1) end_idx
    in
    binary_search 0 (length cell.back_pointers - 1)

  let back_path ~deref ~cell_ptr ~target_index =
    Option.bind (deref cell_ptr) @@ fun cell ->
    let powers = list_powers cell in
    let rec aux path ptr =
      let path = ptr :: path in
      Option.bind (deref ptr) @@ fun cell ->
      let index = cell.index in
      if Compare.Int.(target_index = index) then Some (List.rev path)
      else if Compare.Int.(target_index > index) then None
      else
        Option.bind (best_skip cell target_index powers) @@ fun best_idx ->
        Option.bind (back_pointer cell best_idx) @@ fun ptr -> aux path ptr
    in
    aux [] cell_ptr

  let mem equal x l =
    let open FallbackArray in
    let n = length l in
    let rec aux idx =
      if Compare.Int.(idx >= n) then false
      else
        match get l idx with
        | None -> aux (idx + 1)
        | Some y -> if equal x y then true else aux (idx + 1)
    in
    aux 0

  let assume_some o f = match o with None -> false | Some x -> f x

  let valid_back_path ~equal_ptr ~deref ~cell_ptr ~target_ptr path =
    assume_some (deref target_ptr) @@ fun target ->
    assume_some (deref cell_ptr) @@ fun cell ->
    let target_index = index target
    and cell_index = index cell
    and powers = list_powers cell in
    let rec valid_path index cell_ptr path =
      match (cell_ptr, path) with
      | final_cell, [] ->
          equal_ptr target_ptr final_cell && Compare.Int.(index = target_index)
      | cell_ptr, cell_ptr' :: path ->
          assume_some (deref cell_ptr) @@ fun cell ->
          assume_some (deref cell_ptr') @@ fun cell' ->
          mem equal_ptr cell_ptr' cell.back_pointers
          && assume_some (best_skip cell target_index powers) @@ fun best_idx ->
             assume_some (back_pointer cell best_idx) @@ fun best_ptr ->
             let minimal = equal_ptr best_ptr cell_ptr' in
             let index' = cell'.index in
             minimal && valid_path index' cell_ptr' path
    in
    match path with
    | [] -> false
    | first_cell_ptr :: path ->
        equal_ptr first_cell_ptr cell_ptr && valid_path cell_index cell_ptr path

  type ('ptr, 'content) search_cell_result =
    | Found of ('ptr, 'content) cell
    | Nearest of {
        lower : ('ptr, 'content) cell;
        upper : ('ptr, 'content) cell option;
      }
    | No_exact_or_lower_ptr
    | Deref_returned_none

  type ('ptr, 'content) search_result = {
    rev_path : ('ptr, 'content) cell list;
    last_cell : ('ptr, 'content) search_cell_result;
  }

  let pp_rev_path ~pp_cell =
    Format.pp_print_list ~pp_sep:Format.pp_print_space pp_cell

  let pp_search_cell_result ~pp_cell fmt = function
    | Found ptr -> Format.fprintf fmt "Found(%a)" pp_cell ptr
    | Nearest {lower; upper} ->
        Format.fprintf
          fmt
          "Nearest(lower=%a;upper=%a)"
          pp_cell
          lower
          (Format.pp_print_option pp_cell)
          upper
    | No_exact_or_lower_ptr -> Format.fprintf fmt "No_exact_or_lower_ptr"
    | Deref_returned_none -> Format.fprintf fmt "Deref_returned_none"

  let pp_search_result ~pp_cell fmt {rev_path; last_cell} =
    Format.fprintf
      fmt
      "{rev_path = %a; last_point = %a}"
      (pp_rev_path ~pp_cell)
      rev_path
      (pp_search_cell_result ~pp_cell)
      last_cell

  let search (type ptr) ~(deref : ptr -> ('content, ptr) cell option) ~compare
      ~cell =
    let open Lwt_syntax in
    let ( = ), ( < ), ( > ) = Compare.Int.(( = ), ( < ), ( > )) in
    (* Given a cell, to compute the minimal path, we need to find the
       good back-pointer. This is done linearly with respect to the
       number of back-pointers. This number of back-pointers is
       logarithmic with respect to the number of non-empty
       inboxes. The complexity is consequently in O(log_2^2(n)). Since
       in practice, [n < 2^32], we have at most [1000] calls. Besides,
       the recursive function is tail recursive.

       The linear search could be turned into a dichotomy search if
       necessary. But since this piece of code won't be used in a
       carbonated function, we prefer to keep a simple implementation
       for the moment. *)
    let rec aux rev_path cell ix =
      (* Below, we call the [target] the cell for which [compare target = 0]. *)

      (* Invariant:

         - compare cell > target
         - ix >= 0
         - if cell <> genesis => ix < List.length (back_pointers cell)
         - \exists path' rev_path = cell:path'
      *)
      let back_pointers_length = FallbackArray.length cell.back_pointers in
      if back_pointers_length = 0 then
        (* [cell] is the genesis cell. *)
        return {rev_path; last_cell = No_exact_or_lower_ptr}
      else
        let candidate_ptr =
          match back_pointer cell ix with
          | None ->
              (* At this point we have [cell <> genesis]. Consequently,
                 thanks to the invariant of this function, we have [ix
                 < List.length (back_pointers cell)]. Consequently, the
                 call to [back_pointer] cannot fail. *)
              assert false
          | Some candidate_ptr -> candidate_ptr
        in
        match deref candidate_ptr with
        | None ->
            (* If we cannot dereference a pointer, We stop the search
               and returns the current path. *)
            return {rev_path; last_cell = Deref_returned_none}
        | Some next_cell -> (
            let* comparison = compare next_cell in
            if comparison = 0 then
              (* We have found the target.*)
              let rev_path = next_cell :: rev_path in
              return {rev_path; last_cell = Found next_cell}
            else if comparison > 0 then
              if ix < back_pointers_length - 1 then
                (* There might be a short path by dereferencing the next pointer. *)
                aux rev_path cell (ix + 1)
              else
                (* The last pointer is still above the target. We are on the good track, *)
                let rev_path = next_cell :: rev_path in
                aux rev_path next_cell 0
            else if ix = 0 then
              (* We found a cell lower than the target. *)
              (* The first back pointers gives a cell below the target *)
              let rev_path = next_cell :: rev_path in
              return
                {
                  rev_path;
                  last_cell = Nearest {lower = next_cell; upper = Some cell};
                }
            else
              (* We found a cell lower than the target. *)
              (* The previous pointer was actually the good one. *)
              let good_candidate_ptr =
                match back_pointer cell (ix - 1) with
                | None -> assert false
                | Some candidate_ptr -> candidate_ptr
              in
              match deref good_candidate_ptr with
              | None ->
                  (* We already dereferenced this pointer before. *)
                  assert false
              | Some good_next_cell ->
                  let rev_path = good_next_cell :: rev_path in
                  aux rev_path good_next_cell 0)
    in
    let* comparison = compare cell in
    if Compare.Int.(comparison = 0) then
      (* Particular case where the target is the start cell. *)
      return {rev_path = [cell]; last_cell = Found cell}
    else if Compare.Int.(comparison < 0) then
      return
        {rev_path = [cell]; last_cell = Nearest {lower = cell; upper = None}}
    else aux [cell] cell 0
end
