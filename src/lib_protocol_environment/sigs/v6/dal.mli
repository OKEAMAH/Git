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

(** Parameters of the DAL relevant to the cryptographic primitives. *)
module type CONSTANTS = sig
  (** Redundancy factor of the erasure code. *)
  val redundancy_factor : int

  (** Size in bytes of a slot, must be a power of two. *)
  val slot_size : int

  (** Size in bytes of a segment, must be a power of two. *)
  val segment_size : int

  (** Each erasure-encoded slot splits evenly into the given amount of shards. *)
  val shards_amount : int
end

module type SRS = sig
  (** A trusted setup. *)
  type srs

  (** FIXME https://gitlab.com/tezos/tezos/-/issues/3390

     This is unsafe but can be used for testing. *)
  val srs :
    redundancy_factor:int ->
    segment_size:int ->
    slot_size:int ->
    shards_amount:int ->
    srs

  (** [load_srs ()] loads a trusted [srs]. If the [srs] is already
     loaded, it is given directly. Otherwise, the trusted [srs] is
     read from some files. The [srs] depends on the [slot_size]
     parameters. Loading the first time an srs is consequently costly
     while the other times would be cheap.

      We assume the [srs] won't change many times. The shell ensures
     that a bounded and small number of [srs] can be loaded at the
     same time. *)
  val load_srs : unit -> srs Error_monad.shell_tzresult
end

module type COMMITMENT = sig
  (** A trusted setup. *)
  type srs

  (** Commitment to a polynomial. *)
  type commitment

  (** An encoding for a commitment. *)
  val commitment_encoding : commitment Data_encoding.t

  (** [commitment_to_bytes commitment] returns a byte representation
     of [commitment]. *)
  val commitment_to_bytes : commitment -> Bytes.t

  (** [commitment_size] is the size in bytes of the commitment. *)
  val commitment_size : int

  (** [commitment_of_bytes_opt bytes] computes a commitment from its
     bytes representation. Returns [None] if [bytes] is not a valid
     representation. *)
  val commitment_of_bytes_opt : Bytes.t -> commitment option

  (** A proof that the polynomial associated to some commitment is
     bounded by a constant. *)
  type commitment_proof

  (** An encoding for the proof of a commitment. *)
  val commitment_proof_encoding : commitment_proof Data_encoding.t

  (** [verify_commitment srs commitment proof] checks whether
     [commitment] is a valid [commitment]. In particular, it check
     that the size of the data committed via [commitment] do not
     exceed [C.slot_size]. The verification time is constant. *)
  val verify_commitment :
    srs ->
    commitment ->
    commitment_proof ->
    (bool, [> `Degree_exceeds_srs_length of string]) Result.t
end

module type SEGMENT = sig
  (** A trusted setup. *)
  type srs

  (** Commitment to a polynomial. *)
  type commitment

  (** The original slot can be split into a list of segments of size
     [segment_size]. A segment is consequently encoded as a pair of an
     [index] and the content of this segment. *)
  type segment = {index : int; content : bytes}

  (** A proof that the evaluation of points of a polynomial is part of
     a commitment. *)
  type segment_proof

  (** An encoding for the proof of a segment. *)
  val segment_proof_encoding : segment_proof Data_encoding.t

  (** [verify_segment commitment segment segment_proof] returns [Ok
     true] if the [proof] certifies that the [slot_segment] is indeed
     included in the slot committed with commitment
     [comitment]. Returns [Ok false] otherwise.

      Fails if the index of the segment is out of range. *)
  val verify_segment :
    srs ->
    commitment ->
    segment ->
    segment_proof ->
    (bool, [> `Slot_segment_index_out_of_range]) Result.t
end

module type VERIFIER = sig
  include SRS

  include COMMITMENT with type srs := srs

  include SEGMENT with type commitment := commitment and type srs := srs
end

module Verifier (C : CONSTANTS) : VERIFIER
