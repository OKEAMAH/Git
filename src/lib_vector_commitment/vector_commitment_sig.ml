(*****************************************************************************)
(*                                                                           *)
(* MIT License                                                               *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
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

module type Parameters = sig
  (** 2^[log_nb_leaves] is the number of elements in [leaves].
       [log_nb_leaves] should be divisible by 2. *)
  val log_nb_leaves : int
end

module type Vector_commitment = sig
  (** Representation of data that we prove membership of *)
  type leaves

  (** Representaion of data that we use for changing the [leaves] *)
  type update

  (** Generates [leaves] of size 2^[log_nb_leaves] uniformly at random. *)
  val generate_leaves : unit -> leaves

  (** [generate_update size] generates uniformly at random [size]
      different elements that will be modified in the tree. *)
  val generate_update : size:int -> update

  (** Writes a tree in the file.
      The root of the tree is the commitment to [leaves]. *)
  val create_tree : file_name:string -> leaves -> unit

  (** Applies [update] to the [leaves] and recomputes a tree in the file.
      For Merkle Tree, [update] is a collection of indices and new values.
      For Verkle Tree, [update] is a collection of indices and difference
      between new and old values. *)
  val apply_update : file_name:string -> update -> unit

  module Internal_test : sig
    (** The structure is used for commiting and proving to [leaves],
        which we store in the file but for testing we need it to be in memory. *)
    type tree

    (** This is a commitment to [leaves]. *)
    type root

    (** Constructs a [tree] from [leaves]. *)
    val create_tree_memory : leaves -> tree

    (** Applies [update] to the [leaves] in place and
        DOESN'T recompute a tree or commitment. *)
    val apply_update_leaves : leaves -> update -> unit

    (** Returns a commitment to [leaves] from the file. *)
    val read_root : file_name:string -> root

    (** Returns a commitment to [leaves] from the [tree]. *)
    val read_root_memory : tree -> root

    (** Returns an OCaml representation for [tree] that we store in the file. *)
    val read_tree : file_name:string -> tree

    (** Prints a tree from the file. *)
    val print_tree : file_name:string -> unit

    (** Prints a tree. *)
    val print_tree_memory : tree -> unit

    val compare_root : root -> root -> bool
  end
end

module type Make_Vector_commitment = functor (P : Parameters) ->
  Vector_commitment
