(*****************************************************************************)
(*                                                                           *)
(* MIT License                                                               *)
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

(** Module used to handle transcripts, used for applying the Fiat-Shamir heuristic *)
module Transcript : sig
  type t [@@deriving repr]

  val empty : t

  val equal : t -> t -> bool

  val of_srs : len1:int -> len2:int -> Srs.t -> t

  val list_expand : 'a Repr.ty -> 'a list -> t -> t

  val expand : 'a Repr.ty -> 'a -> t -> t
end

module Fr_generation : sig
  val powers : int -> scalar -> scalar array

  val batch : scalar -> scalar list -> scalar

  val build_quadratic_non_residues : int -> scalar array

  val random_fr_list : Transcript.t -> int -> scalar list * Transcript.t

  val random_fr : Transcript.t -> scalar * Transcript.t
end

module FFT : sig
  val select_fft_domain : int -> int * int * int

  val fft : Domain.t -> Bls.Poly.t -> Evaluations.t

  val ifft_inplace : Domain.t -> Evaluations.t -> Bls.Poly.t
end

val diff_next_power_of_two : int -> int

val is_power_of_two : int -> bool

val pad_array : 'a array -> int -> 'a array

val resize_array : 'a array -> int -> 'a array
