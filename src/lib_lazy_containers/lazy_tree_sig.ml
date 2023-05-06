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

module type S = sig
  type elt

  type t

  module Set : Set.S with type elt = string

  module Map : Map.S with type key = string

  type tree_source = Origin | From_parent

  (** [origin fs] returns the tree origin of the container, if it exists. *)
  val origin : t -> Tezos_tree_encoding.wrapped_tree option

  (** [tree_instance fs] returns either origin tree of the current node
    or a parent's origin. Necessary to be able to encode Lazy_fs to this instance. *)
  val tree_instance : t -> Tezos_tree_encoding.wrapped_tree * tree_source

  (** [find_tree fs path] finds a tree node corresponding to the [path]. *)
  val find_tree : t -> string list -> t option Lwt.t

  (** [find fs path] finds a node value corresponding to the [path]. *)
  val find_value : t -> string list -> elt option Lwt.t

  (** [add_tree fs path subtree] adds a subtree under the given [path]. *)
  val add_tree : t -> string list -> t -> t Lwt.t

  (** [set fs path value] set a value of the node corresponding to [path] to [value]. *)
  val set : t -> string list -> elt -> t Lwt.t

  (** [remove fs path] removes a subtree under the given [path] togehter with its value. *)
  val remove_tree : t -> string list -> t Lwt.t

  (** [remove_value fs path] removes a subtree's value under the given [path]. *)
  val remove_value : t -> string list -> t Lwt.t

  (** [count_subtrees fs] returns number of direct subtrees of the given [fs]. *)
  val count_subtrees : t -> int Lwt.t

  val hash_value : t -> Tezos_base.TzPervasives.Context_hash.t option Lwt.t

  val hash_tree : t -> Tezos_base.TzPervasives.Context_hash.t option Lwt.t

  val list_subtree_names :
    t -> ?offset:int -> ?length:int -> string list -> string list option Lwt.t

  (** [encoding value_enc] returns an encoding for the container wrt
    encoding of the value [value_enc] *)
  val encoding : t Tezos_tree_encoding.t
end
