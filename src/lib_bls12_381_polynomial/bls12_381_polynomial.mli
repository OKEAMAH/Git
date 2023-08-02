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

type scalar = Bls12_381.Fr.t

module Domain : Domain.Domain_sig with type scalar = scalar

module Polynomial : Polynomial.Polynomial_sig with type scalar = scalar

module type Evaluations_sig =
  Evaluations.Evaluations_sig
    with type scalar = scalar
     and type domain = Domain.t
     and type polynomial = Polynomial.t

module Evaluations :
  Evaluations.Evaluations_sig
    with type scalar = scalar
     and type domain = Domain.t
     and type polynomial = Polynomial.t

module Srs : sig
  module Srs_g1 :
    Srs.S with type polynomial = Polynomial.t and type elt = Bls12_381.G1.t

  module Srs_g2 :
    Srs.S with type polynomial = Polynomial.t and type elt = Bls12_381.G2.t

  type t = Srs_g1.t * Srs_g2.t

  val generate_insecure : int -> int -> t

  val check : t -> unit
end

module G1_carray :
  Ec_carray.EC_carray_sig
    with type elt = Bls12_381.G1.t
     and type domain = Domain.t
     and type evaluations = Evaluations.t

module G2_carray :
  Ec_carray.EC_carray_sig
    with type elt = Bls12_381.G2.t
     and type domain = Domain.t
     and type evaluations = Evaluations.t
