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

(**
    This module provides an interface of tree,
    where nodes accessed by a path (list of strings)
    and each intermediate node can hold a value.
    It is lazy decodable and take advantage of [Lazy_dirs].
*)

type tree_source = Origin | From_parent

type 'a t = {
  content : 'a option;
  dirs : 'a t Lazy_dirs.t;
  parent_origin : Tezos_tree_encoding.wrapped_tree;
}

(** [origin fs] returns the tree origin of the container, if it exists. *)
val origin : 'a t -> Tezos_tree_encoding.wrapped_tree option

(** [tree_instance fs] returns either origin tree of the current node
    or a parent's origin. Necessary to be able to encode Lazy_fs to this instance.
*)
val tree_instance : 'a t -> Tezos_tree_encoding.wrapped_tree * tree_source

(** [find_tree fs path] finds a tree node corresponding to the [path]. *)
val find_tree : 'a t -> string list -> 'a t option Lwt.t

(** [find fs path] finds a node value corresponding to the [path]. *)
val find : 'a t -> string list -> 'a option Lwt.t

(** [add_tree fs path subtree] adds a subtree under the given [path]. *)
val add_tree : 'a t -> string list -> 'a t -> 'a t Lwt.t

(** [set fs path value] set a value of the node corresponding to [path] to [value]. *)
val set : 'a t -> string list -> 'a -> 'a t Lwt.t

(** [remove fs path] removes a subtree under the given [path] togehter with its value. *)
val remove : 'a t -> string list -> 'a t Lwt.t

(** [remove_value fs path] removes a subtree's value under the given [path]. *)
val remove_value : 'a t -> string list -> 'a t Lwt.t

(** [count_subtrees fs] returns number of direct subtrees of the given [fs]. *)
val count_subtrees : 'a t -> int

(** [list_subtrees fs] returns subtrees of the given [fs] in alphabetically sorted order. *)
val list_subtrees : 'a t -> string list

(** [nth_name fs index] returns [index]-th subtree of the given [fs].
    Aligns with the order of keys of [list_subtrees].
*)
val nth_name : 'a t -> int -> string option

(** [encoding value_enc] returns an encoding for the container wrt
    encoding of the value [value_enc]
*)
val encoding : 'a Tezos_tree_encoding.t -> 'a t Tezos_tree_encoding.t
