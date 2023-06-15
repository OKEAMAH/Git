(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
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

(** The partial reveal instruction allows revealing part of a preimage, contrary
    to the reveal instruction which reveals the entire preimage. This is achieved
    thanks to a vector commitment scheme: a Merkle tree. The Merkle tree leaves
    hold segments (also called pages) of the preimage. The length of a preimage
    page is expected to be 4kiB so that it can fit in a message.

    The partial reveal hash is thus a pair consisting of the root of the Merkle
    tree and the index of a leaf (leaves are ordered from left to right) of the
    tree to reveal and subsequently verify its inclusion in said tree. *)

(** The type of a Merkle tree opening: the Merkle tree root and the index of
    the leaf (leaves are ordered from left to right) to reveal. *)
type u = {index : int; root : Sc_rollup_reveal_hash.t}

val encoding : u Data_encoding.t

val pp : Format.formatter -> u -> unit

val to_hex : u -> string

val of_hex : string -> u option

(** A Merkle tree proof. *)
type proof

val proof_encoding : proof Data_encoding.t

type tree

module type M = sig
  include Merkle_list.T

  val make : index:int -> root:h -> u

  val proof_of_path : path -> proof

  val path_of_proof : proof -> path

  val t_of_tree : tree -> t

  val tree_of_t : t -> tree

  val merkle_tree : elts:elt list -> tree

  val produce_proof : tree:tree -> index:int -> proof tzresult
end

(** A Merkle tree module for storing byte-indexed values. *)
module Merkelized_bytes_Blake2B :
  M with type elt = Bytes.t and type h = Sc_rollup_reveal_hash.Blake2B.t

(** [to_mod hashing_scheme] returns a Merkle tree instantiated with the
      given hash function scheme [hashing_scheme]. *)
val to_mod :
  'h Sc_rollup_reveal_hash.supported_hashes ->
  (module M with type elt = bytes and type h = 'h)

(** [merkle_tree merkle_list ~elts] returns the merkle tree from the given
    leaves [elts]. *)
val merkle_tree :
  (module Merkle_list.T with type elt = bytes and type t = 't) ->
  elts:bytes list ->
  't

(** Same as {!val:merkle_tree}, except it is restricted to the set of Merkle trees
  instantiated with the hashing scheme {!val:Sc_rollup_reveal_hash.t}. *)
val merkle_tree_reveal_hash : elts:bytes list -> u -> tree

(** [merkle_root merkle_list ~tree] returns the merkle tree root from the given
    Merkle tree [merkle_list]. *)
val merkle_root :
  (module Merkle_list.T with type h = 'h and type t = 't) -> tree:'t -> 'h

(** [make index root] returns a reveal hash consisting
    of the [index] of the Merkle leaf and Merkle tree [root]. *)
val make :
  (module M with type elt = bytes and type h = 'h) -> index:int -> root:'h -> u

(** [produce_proof (module MT) ~tree ~index] returns a Merkle proof for the
    opening ([MT.root], [index]). *)
val produce_proof :
  (module M with type elt = bytes and type h = 'h and type t = 't) ->
  tree:'t ->
  index:int ->
  proof tzresult

(** Same as {!val:produce_proof}, except it is restricted to the set of Merkle trees
  instantiated with the hashing scheme {!val:Sc_rollup_reveal_hash.t}. *)
val produce_proof_reveal_hash : tree:tree -> u -> proof tzresult

(** [verify_proof merkle_tree ~proof ~index ~elt ~expected_root] returns true
    if and only if the [proof] testifies that [elt] is the [index]-th leaf of
    the merkle_tree whose root is [expected_root]. *)
val verify_proof :
  (module M with type elt = bytes and type h = 'h and type t = 't) ->
  proof:proof ->
  index:int ->
  elt:bytes ->
  expected_root:'h ->
  bool tzresult

(** Same as {!val:verify_proof}, except it is restricted to the set of Merkle trees
  instantiated with the hashing scheme {!val:Sc_rollup_reveal_hash.t}. *)
val verify_proof_reveal_hash :
  proof:proof ->
  index:int ->
  elt:bytes ->
  expected_root:Sc_rollup_reveal_hash.t ->
  bool tzresult
