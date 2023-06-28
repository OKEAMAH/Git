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
type t = {index : int; root : Sc_rollup_reveal_hash.t}

val encoding : t Data_encoding.t

val pp : Format.formatter -> t -> unit

val to_hex : t -> string

val of_hex : string -> t option

(** A Merkle tree module for storing byte-indexed values. *)
module Merkelized_bytes_Blake2B :
  Merkle_list.T
    with type elt = string
     and type h = Sc_rollup_reveal_hash.Blake2B.t

(** [make ~scheme index root] returns a partial reveal consisting
    of the [index] of the Merkle leaf and Merkle tree [root] with
    the given hashing [scheme]. *)
val make :
  'h.
  scheme:'h Sc_rollup_reveal_hash.supported_hashes -> index:int -> root:'h -> t

(** [merkle_list_of_scheme ~scheme] returns a Merkle tree instantiated with the
      given hash function [scheme]. *)
val merkle_list_of_scheme :
  scheme:'h Sc_rollup_reveal_hash.supported_hashes ->
  (module Merkle_list.T with type elt = string and type h = 'h)
