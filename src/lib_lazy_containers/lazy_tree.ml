(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 TriliTech <contact@trili.tech>                         *)
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

module type VALUE = sig
  type t

  val encoding : t Tezos_tree_encoding.t
end

module Make (Value : VALUE) = struct
  open Tezos_tree_encoding

  type tree_source = Origin | From_parent

  type elt = Value.t

  module Map = Map.Make (String)
  module Set = Set.Make (String)

  (* This module keeps a map of direct subtrees,
     basically for each tree "step" storing
     information about corresponding subtree.

     For a "step" a corresponding subtree could be either decoded from an origin,
     hence, a decoded subtree is just kept cached, or alternatively,
     a subtree could be rewritten with new subtree.
     This distinguishment made in order to omit encoding unchanged subtrees.

     Also apart from mantaining this map,
     [length_at_least] is being recomputed accordingly on each change.
     This is a number of existing subtrees, essentially,
     just number of cached subtrees plus number of rewritten ones.
     [length_at_least] is necessary to put off encoding values back to tree
     as long as possible in [is_empty] function,
     which is being extensively used in [remove_tree]/[remove_value] ones.
  *)
  module Subtrees = struct
    type 'a subtree_status = [`Cached of 'a option | `Rewrite of 'a | `Removed]

    type 'a t = {changes : 'a subtree_status Map.t; length_at_least : int}

    let empty = {changes = Map.empty; length_at_least = 0}

    (* Create only cached values out of key-value pairs. *)
    let new_cache cache =
      {
        changes =
          Map.of_seq @@ List.to_seq
          @@ List.map (fun (step, x) -> (step, `Cached x)) cache;
        length_at_least =
          List.length @@ List.filter (fun (_, x) -> Option.is_some x) cache;
      }

    (* Update a step in changes map with `Rewritten
       and recompute length_at_least carefully *)
    let set_subtree step new_subtree subtrees =
      let new_changes = Map.add step (`Rewrite new_subtree) subtrees.changes in
      let new_length_at_least =
        match Map.find_opt step subtrees.changes with
        | None | Some (`Cached None) -> subtrees.length_at_least + 1
        | Some (`Rewrite _) | Some (`Cached (Some _)) ->
            subtrees.length_at_least
        | Some `Removed -> subtrees.length_at_least + 1
      in
      {changes = new_changes; length_at_least = new_length_at_least}

    (* Update a step in changes map with `Removed
       and recompute length_at_least carefully *)
    let remove_subtree step subtrees =
      let new_changes = Map.add step `Removed subtrees.changes in
      let new_length_at_least =
        match Map.find_opt step subtrees.changes with
        | None | Some (`Cached None) | Some `Removed -> subtrees.length_at_least
        | Some (`Rewrite _) | Some (`Cached (Some _)) ->
            subtrees.length_at_least - 1
      in
      {changes = new_changes; length_at_least = new_length_at_least}

    (* Update a step in changes map with `Cached
       and recompute length_at_least carefully.
       When a step is being cached it cannot exist in a changes map.
    *)
    let cache step new_subtree subtrees =
      {
        changes = Map.add step (`Cached new_subtree) subtrees.changes;
        length_at_least =
          (subtrees.length_at_least
          + if Option.is_some new_subtree then 1 else 0);
      }

    let subtrees_diff t =
      List.filter_map (function
          | step, `Removed -> Some (step, None)
          | step, `Rewrite x -> Some (step, Some x)
          | _ -> None)
      @@ Map.bindings t.changes

    let known_values t =
      List.filter_map (function
          | step, `Cached x -> Some (step, x)
          | step, `Rewrite x -> Some (step, Some x)
          | _ -> None)
      @@ Map.bindings t.changes
  end

  (* Those mutable fields look untrustworthy,
      however, it's implemented in this way in order
      to update those fields in read methods.
      It's been done in order to avoid returning from all the read methods
      new instance of the lazy_tree.

      The only questionable aspect when a node is being copied,
      then those mutable fields are shared between two nodes but
      it's more or less safe because the implementation
      written in a way, that whenever we change a node
      (add, remove a subtree or add, remove a value),
      modified node will be copied, what will lead to unbinding
      fields of those two nodes from each other.

      A little bit motivation why [origin], [subtrees], [value] are
      stored here explicitly, instead of using lazy_map:
        1. producers function (encode_subtree & encode_value) return option
           instead of throwing an exception
        2. value and subtrees share common origin
        3. need to keep track of length_at_least,
           in order to implement [is_empty] in more effective way
        4. better control of what should be cached
  *)
  type t = {
    mutable origin : Tezos_tree_encoding.wrapped_tree option;
    mutable subtrees : t Subtrees.t;
    mutable value : Value.t Subtrees.t;
    parent_origin : Tezos_tree_encoding.wrapped_tree;
  }

  let origin t = t.origin

  let tree_instance t =
    Option.fold
      ~none:(t.parent_origin, From_parent)
      ~some:(fun org -> (org, Origin))
      (origin t)

  let create_from_value parent_origin value =
    {
      origin = None;
      subtrees = Subtrees.empty;
      value =
        Option.fold
          ~none:(Subtrees.cache "@" None Subtrees.empty)
          ~some:(fun x -> Subtrees.set_subtree "@" x Subtrees.empty)
          value;
      parent_origin;
    }

  module Encoding = Lazy_tree_encoding.Make (struct
    type nonrec elt = elt

    type nonrec lt = t

    let value_encoding = Value.encoding

    let origin t = t.origin

    let subtrees_diff t = Subtrees.subtrees_diff t.subtrees

    let value t =
      match Subtrees.subtrees_diff t.value with
      | [(_, Some v)] -> `NewValue v
      | [(_, None)] -> `Removed
      | _ -> `NoChange

    let create origin =
      {
        origin = Some origin;
        subtrees = Subtrees.empty;
        value = Subtrees.empty;
        parent_origin = origin;
      }
  end)

  (* This module contains auxiliary methods which are being used in
     implementation of the exposed ones from lazy_tree.
     Most of the methods in Aux are intend to decode/enconde and properly update caches/changes. *)
  module Aux = struct
    (* This function encodes the given lazy_tree to an irmin tree.

       If origin of the tree is known, we encode a tree back to this origin,
       otherwise we will encode to a freshly created non-existing path in the tree.

       The function might return None if the all subkeys have been removed
       in the given tree, what essentially means that final tree is empty *)
    let encode_tree tree =
      let open Lwt.Syntax in
      let Wrapped_tree (underlying, (module M)), origin_soruce =
        tree_instance tree
      in
      let module M_runner = Tezos_tree_encoding.Runner.Make (M) in
      let lazy_tree_encoding = Encoding.lazy_tree () in
      let+ new_underlying =
        match origin_soruce with
        | Origin ->
            Lwt.map Option.some
            @@ M_runner.encode lazy_tree_encoding tree underlying
        | From_parent ->
            let unaccessible_path = ["@@@@"; "unaccessible_path"] in
            let* new_origin =
              M_runner.encode
                (scope unaccessible_path lazy_tree_encoding)
                tree
                underlying
            in
            M.find_tree new_origin unaccessible_path
      in
      Option.map
        (fun new_uderlying -> Wrapped_tree (new_uderlying, (module M)))
        new_underlying

    (* This function encode both addition and deletion changes back to origin
       but retain additions as a cache. *)
    let flush_changes tree =
      let open Lwt.Syntax in
      let+ new_origin = encode_tree tree in
      tree.origin <- new_origin ;
      (* Remove deletions from changes, and turn additions to cached values *)
      tree.subtrees <- Subtrees.new_cache @@ Subtrees.known_values tree.subtrees ;
      tree.value <- Subtrees.new_cache @@ Subtrees.known_values tree.value ;
      new_origin

    let get_or_decode_subtree_general ~decode ~on_decode step origin_opt
        subtrees =
      let open Lwt.Syntax in
      match Map.find_opt step subtrees.Subtrees.changes with
      | None ->
          let+ decoded_subtree =
            match origin_opt with
            | None -> Lwt.return_none
            | Some origin -> decode origin
          in
          on_decode decoded_subtree ;
          decoded_subtree
      | Some `Removed -> Lwt.return_none
      | Some (`Cached value) -> Lwt.return value
      | Some (`Rewrite value) -> Lwt.return_some value

    let get_or_decode_subtree step tree =
      get_or_decode_subtree_general
        ~decode:(fun org -> Encoding.decode_subtree org step)
        ~on_decode:(fun decoded_subtree ->
          (* Cache decoded_subtree, avoid caching an absent subtree *)
          if Option.is_some decoded_subtree then
            tree.subtrees <- Subtrees.cache step decoded_subtree tree.subtrees)
        step
        tree.origin
        tree.subtrees

    let get_or_decode_value tree =
      get_or_decode_subtree_general
        ~on_decode:(fun decoded_subtree ->
          tree.value <- Subtrees.cache "@" decoded_subtree tree.value)
        ~decode:(fun org -> Encoding.decode_value org)
        "@"
        tree.origin
        tree.value

    (* This function aspires to postone encoding back to tree as much as possible *)
    let is_empty tree =
      let open Lwt.Syntax in
      (* There are additions or value exists, meaning NOT EMPTY for sure *)
      if tree.subtrees.length_at_least > 0 || tree.value.length_at_least > 0
      then Lwt.return_false
        (* There is no origin, additions is empty and value is either removed or unknown,
           then the tree IS empty for sure *)
      else if
        Option.is_none (origin tree)
        && tree.subtrees.length_at_least = 0
        && tree.value.length_at_least = 0
      then Lwt.return_true
        (* Otherwise we need to encode changes back to the tree to check if it's empty or not *)
      else
        let* encoded = flush_changes tree in
        match encoded with
        | None -> Lwt.return_true
        | Some encoded -> Lwt.map (fun x -> x = 0) @@ Wrapped.length encoded []
  end

  let rec find_tree tree key =
    let open Lwt.Syntax in
    match key with
    | [] -> Lwt.return_some tree
    | step :: steps -> (
        let* maybe_subtree = Aux.get_or_decode_subtree step tree in
        match maybe_subtree with
        | Some subtree -> find_tree subtree steps
        | None -> Lwt.return_none)

  let find_value tree key =
    let open Lwt.Syntax in
    let* tree = find_tree tree key in
    Option.fold
      ~none:Lwt.return_none
      ~some:(fun tree -> Aux.get_or_decode_value tree)
      tree

  let rec construct_branch parent_origin key inserting_tree =
    match key with
    | [] -> inserting_tree
    | step :: steps ->
        let tree = create_from_value parent_origin None in
        let subtree = construct_branch parent_origin steps inserting_tree in
        {tree with subtrees = Subtrees.set_subtree step subtree tree.subtrees}

  let rec modify_tree tree key f =
    let open Lwt.Syntax in
    match key with
    | [] -> Lwt.return (f @@ Some tree)
    | step :: steps -> (
        let* maybe_subtree = Aux.get_or_decode_subtree step tree in
        match maybe_subtree with
        | Some subtree ->
            let+ modified_subtree = modify_tree subtree steps f in
            {
              tree with
              subtrees =
                Subtrees.set_subtree step modified_subtree tree.subtrees;
            }
        | None ->
            let subtree = construct_branch tree.parent_origin steps (f None) in
            Lwt.return
              {
                tree with
                subtrees = Subtrees.set_subtree step subtree tree.subtrees;
              })

  let add_tree tree key value_tree = modify_tree tree key (fun _ -> value_tree)

  let set tree key value =
    modify_tree tree key @@ function
    | Some subtree ->
        {subtree with value = Subtrees.set_subtree "@" value tree.value}
    | None -> create_from_value tree.parent_origin (Some value)

  let rec remove_generic tree key action =
    let open Lwt.Syntax in
    match (key, action) with
    | [], `Remove_tree -> Lwt.return tree
    | [], `Remove_value ->
        Lwt.return {tree with value = Subtrees.remove_subtree "@" tree.value}
    | [step], `Remove_tree ->
        Lwt.return
          {tree with subtrees = Subtrees.remove_subtree step tree.subtrees}
    | step :: steps, _ -> (
        let* maybe_subtree = Aux.get_or_decode_subtree step tree in
        match maybe_subtree with
        | Some subtree ->
            let* new_subtree = remove_generic subtree steps action in
            let* new_subtree_empty = Aux.is_empty new_subtree in
            if new_subtree_empty then
              (* We remove new_subtree from tree, it shouldn't dangle *)
              let tree =
                {
                  tree with
                  subtrees = Subtrees.remove_subtree step tree.subtrees;
                }
              in
              let+ tree_empty = Aux.is_empty tree in
              if tree_empty then
                (* If [step] was the only child of [tree] and [tree] has no value,
                    then we should remove current node as well *)
                create_from_value subtree.parent_origin None
              else
                (* If [new_tree] is empty: we don't need to store it anymore *)
                tree
            else
              (* Otherwise, just replace old k with new one*)
              Lwt.return
              @@ {
                   tree with
                   subtrees =
                     Subtrees.set_subtree step new_subtree tree.subtrees;
                 }
        | None -> Lwt.return tree)

  let remove_value tree key = remove_generic tree key `Remove_value

  let remove_tree tree key = remove_generic tree key `Remove_tree

  let count_subtrees tree =
    let open Lwt.Syntax in
    (* We have to flush changes in order to keep backward compatibility with irmin. *)
    let* encoded = Aux.flush_changes tree in
    match encoded with
    | None -> Lwt.return 0
    | Some encoded -> Wrapped.length encoded []

  let hash_value tree =
    (* TODO not flush the whole tree, we only need to flush "@" subtree *)
    let open Lwt.Syntax in
    let value_marker = "@" in
    (* We have to flush changes in order to keep backward compatibility with irmin. *)
    let* encoded = Aux.flush_changes tree in
    match encoded with
    | None -> Lwt.return_none
    | Some encoded ->
        let+ value_subtree = Wrapped.find_tree encoded [value_marker] in
        Option.map Wrapped.hash value_subtree

  let hash_tree tree =
    let open Lwt.Syntax in
    (* We have to flush changes in order to keep backward compatibility with irmin. *)
    let* encoded = Aux.flush_changes tree in
    match encoded with
    | None -> Lwt.return_none
    | Some encoded -> Lwt.return @@ Some (Wrapped.hash encoded)

  let list_subtree_names tree ?offset ?length key =
    let open Lwt.Syntax in
    let* tree = find_tree tree key in
    match tree with
    | None -> Lwt.return_none
    | Some tree -> (
        (* We have to flush changes in order to keep backward compatibility with irmin. *)
        let* encoded = Aux.flush_changes tree in
        match encoded with
        | None -> Lwt.return_none
        | Some encoded ->
            Lwt.map (fun x -> Option.some @@ List.map fst x)
            @@ Wrapped.list encoded ?offset ?length [])

  let encoding = Encoding.lazy_tree ()
end

module CBV_lazy_tree = Make (struct
  type t = Immutable_chunked_byte_vector.t

  let encoding = Immutable_chunked_byte_vector.encoding
end)
