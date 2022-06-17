(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs. <contact@nomadic-labs.com>               *)
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

(** The cryptographic primitives for the data availability layer (DAL). *)
module type S = sig
  (** Commitment to a polynomial. *)
  type commitment

  (** Proof of degree. *)
  type proof_degree

  (** Proof of evaluation at multiple points. *)
  type proof_multi

  module Encoding : sig
    val commitment_encoding : commitment Data_encoding.t

    val proof_degree_encoding : proof_degree Data_encoding.t

    val proof_multi_encoding : proof_multi Data_encoding.t
  end

  (** Length of the erasure-encoded slot in terms of scalar elements. *)
  val erasure_encoding_length : int

  (** [verify_degree commitment proof n] returns true if and only if the
      committed polynomial has degree less than [n]. *)
  val verify_degree :
    commitment ->
    proof_degree ->
    int ->
    (bool, [> `Degree_exceeds_srs_length of string]) Result.t

  (** [verify_slot_segment cm ~slot_segment ~offset proof] returns true if the
      [slot_segment] is correct. *)
  val verify_slot_segment :
    commitment -> slot_segment:bytes -> offset:int -> proof_multi -> bool
end

(** Parameters of the DAL relevant to the cryptographic primitives. *)
module type Constants = sig
  (** Redundancy factor of the erasure code. *)
  val redundancy_factor : int

  (** Size in bytes of a slot. *)
  val slot_size : int

  (** Size in bytes of a slot segment. *)
  val slot_segment_size : int

  (** Each erasure-encoded slot splits evenly into the given amount of shards. *)
  val shards_amount : int
end

module Make : functor (C : Constants) -> S
