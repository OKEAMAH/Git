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
    This module is basically a wrapper around [Lazy_map] with key instantiated to string
    that eagerly loads map's keys (but not values) during decoding.
    For the more information see [Tezos_tree_encoding.Lazy_dirs_encoding].
    This behaviour resembles how folders on an OS shown.
*)

(** This module is to work with keys. *)
module Names : Set.S with type elt = String.t

(** This module is to work with the underlying lazy map holding content. *)
module Map : Lazy_map.S with type key = String.t

type 'a t = {names : Names.t; contents : 'a Map.t}

(** [origin dirs] returns the tree of origin of the container, if it exists. *)
val origin : 'a t -> Tezos_tree_encoding.wrapped_tree option

(** [create names contents] creates lazy dirs.
    If [names] is not provided then [Map.loaded_bindings contents] used to initialise names.
    If [contents] is not provided as well then empty lazy_dirs will be created.
    It is responsibility of the caller to supply consistent [names] and [contents],
    for instance, [names] has to be subset of keys of [contents].
*)
val create : ?names:Names.t -> ?contents:'a Map.t -> unit -> 'a t

(** [is_empty dirs] returns true if the container is empty,
    Relies on size of underlying names. *)
val is_empty : 'a t -> bool

(** [find dirs key] retrieves the element at [key]. *)
val find : 'a t -> Names.elt -> 'a option Lwt.t

(** [set dirs key value] sets the element at [key] to [value]. *)
val set : 'a t -> Names.elt -> 'a -> 'a t

(** [remove dirs key] marks the element at [key] as removed,
    this will be synced with the origin during encoding. *)
val remove : 'a t -> Names.elt -> 'a t

(** [list dirs] lists all the keys in alphabetically sorted order. *)
val list : 'a t -> Names.elt list

(** [length dirs] returns number of elements. *)
val length : 'a t -> int

(** [nth_name dirs index] returns [index]-th key.
    Aligns with the order of keys of [list].
*)
val nth_name : 'a t -> int -> Names.elt option

(** [encoding value_enc] returns an encoding for the container wrt
    encoding of the value [value_enc]
*)
val encoding : 'a Tezos_tree_encoding.t -> 'a t Tezos_tree_encoding.t
