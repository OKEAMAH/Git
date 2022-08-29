(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 TriliTech <contact@trili.tech>                         *)
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

type key = string list

type value = bytes

exception Incorrect_tree_type

module type S = sig
  type tree

  val select : Lazy_containers.Lazy_map.tree -> tree

  val wrap : tree -> Lazy_containers.Lazy_map.tree

  val remove : tree -> key -> tree Lwt.t

  val add : tree -> key -> value -> tree Lwt.t

  val add_tree : tree -> key -> tree -> tree Lwt.t

  val find : tree -> key -> value option Lwt.t

  val find_tree : tree -> key -> tree option Lwt.t
end

type 'tree backend = (module S with type tree = 'tree)

let select : type tree. tree backend -> Lazy_containers.Lazy_map.tree -> tree =
 fun (module T) tree -> T.select tree

let wrap : type tree. tree backend -> tree -> Lazy_containers.Lazy_map.tree =
 fun (module T) tree -> T.wrap tree

let remove : type tree. tree backend -> tree -> key -> tree Lwt.t =
 fun (module T) tree key -> T.remove tree key

let add : type tree. tree backend -> tree -> key -> value -> tree Lwt.t =
 fun (module T) tree key value -> T.add tree key value

let add_tree : type tree. tree backend -> tree -> key -> tree -> tree Lwt.t =
 fun (module T) tree key subtree -> T.add_tree tree key subtree

let find : type tree. tree backend -> tree -> key -> value option Lwt.t =
 fun (module T) tree key -> T.find tree key

let find_tree : type tree. tree backend -> tree -> key -> tree option Lwt.t =
 fun (module T) tree key -> T.find_tree tree key

type wrapped_tree = Wrapped_tree : 'tree * 'tree backend -> wrapped_tree

type Lazy_containers.Lazy_map.tree += Wrapped of wrapped_tree

module Wrap : S with type tree = wrapped_tree = struct
  type tree = wrapped_tree

  let remove = function
    | Wrapped_tree (t, b) ->
        fun key ->
          let open Lwt.Syntax in
          let+ t = remove b t key in
          Wrapped_tree (t, b)

  let add = function
    | Wrapped_tree (t, b) ->
        fun key v ->
          let open Lwt.Syntax in
          let+ t = add b t key v in
          Wrapped_tree (t, b)

  let add_tree = function
    | Wrapped_tree (t, b) ->
        fun key (Wrapped_tree (t', b')) ->
          let open Lwt.Syntax in
          let t' = select b (wrap b' t') in
          let+ t = add_tree b t key t' in
          Wrapped_tree (t, b)

  let find_tree = function
    | Wrapped_tree (t, b) -> (
        fun key ->
          let open Lwt.Syntax in
          let+ t' = find_tree b t key in
          match t' with Some t' -> Some (Wrapped_tree (t', b)) | None -> None)

  let find = function
    | Wrapped_tree (t, b) ->
        fun key ->
          let open Lwt.Syntax in
          find b t key

  let select = function
    | Wrapped (Wrapped_tree (_, _) as wt) -> wt
    | _ -> raise Incorrect_tree_type

  let wrap t = Wrapped t
end

let wrapped_backend : wrapped_tree backend = (module Wrap)
