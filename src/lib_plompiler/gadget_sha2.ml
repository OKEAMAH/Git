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

open Lang_stdlib

module type VARIANT = sig
  val word_size : int

  val sum_constants : int array

  val sigma_constants : int array

  val round_constants : int array

  val loop_bound : int
end

module type SHA2 = functor (L : LIB) -> sig
  open L

  val ch : Bytes.bl repr -> Bytes.bl repr -> Bytes.bl repr -> Bytes.bl repr t

  val maj : Bytes.bl repr -> Bytes.bl repr -> Bytes.bl repr -> Bytes.bl repr t

  val sum_0 : Bytes.bl repr -> Bytes.bl repr t

  val sum_1 : Bytes.bl repr -> Bytes.bl repr t

  val sigma_0 : Bytes.bl repr -> Bytes.bl repr t

  val sigma_1 : Bytes.bl repr -> Bytes.bl repr t
end

module MAKE (V : VARIANT) : SHA2 =
functor
  (L : LIB)
  ->
  struct
    open L

    (* Ch(x, y, z) = (x && y) XOR ( !x && z) *)
    let ch x y z =
      with_label ~label:"Sha2.Ch"
      @@ let* x_and_y = Bytes.band x y in
         let* not_x = Bytes.not x in
         let* not_x_and_z = Bytes.band not_x z in
         let* res = Bytes.xor x_and_y not_x_and_z in
         ret res

    (* Maj(x, y, z) = (x && y) XOR (x && z) XOR (y && z) *)
    let maj x y z =
      with_label ~label:"Sha2.Maj"
      @@ let* x_and_y = Bytes.band x y in
         let* x_and_z = Bytes.band x z in
         let* y_and_z = Bytes.band y z in
         let* tmp = Bytes.xor x_and_y x_and_z in
         let* res = Bytes.xor tmp y_and_z in
         ret res

    (* Sum_0(x) = ROTR^{c0}(x) XOR ROTR^{c1}(x) XOR ROTR^{c2}(x) *)
    let sum_0 x =
      with_label ~label:"Sha2.Sum0"
      @@
      let x0 = Bytes.rotate_right x V.sum_constants.(0) in
      let x1 = Bytes.rotate_right x V.sum_constants.(1) in
      let x2 = Bytes.rotate_right x V.sum_constants.(2) in
      let* tmp = Bytes.xor x0 x1 in
      let* res = Bytes.xor tmp x2 in
      ret res

    (* Sum_1(x) = ROTR^{c3}(x) XOR ROTR^{c4}(x) XOR ROTR^{c5}(x) *)
    let sum_1 x =
      with_label ~label:"Sha2.Sum1"
      @@
      let x0 = Bytes.rotate_right x V.sum_constants.(3) in
      let x1 = Bytes.rotate_right x V.sum_constants.(4) in
      let x2 = Bytes.rotate_right x V.sum_constants.(5) in
      let* tmp = Bytes.xor x0 x1 in
      let* res = Bytes.xor tmp x2 in
      ret res

    (* Sigma_0(x) = ROTR^{d0}(x) XOR ROTR^{d1}(x) XOR SHR^{d2}(x) *)
    let sigma_0 x =
      with_label ~label:"Sha2.Sigma0"
      @@
      let x0 = Bytes.rotate_right x V.sigma_constants.(0) in
      let x1 = Bytes.rotate_right x V.sigma_constants.(1) in
      let* x2 = Bytes.shift_right x V.sigma_constants.(2) in
      let* tmp = Bytes.xor x0 x1 in
      let* res = Bytes.xor tmp x2 in
      ret res

    (* Sigma_1(x) = ROTR^{d3}(x) XOR ROTR^{d4}(x) XOR SHR^{d5}(x) *)
    let sigma_1 x =
      with_label ~label:"Sha2.Sigma1"
      @@
      let x0 = Bytes.rotate_right x V.sigma_constants.(3) in
      let x1 = Bytes.rotate_right x V.sigma_constants.(4) in
      let* x2 = Bytes.shift_right x V.sigma_constants.(5) in
      let* tmp = Bytes.xor x0 x1 in
      let* res = Bytes.xor tmp x2 in
      ret res
  end

module Variant_sha256 : VARIANT = struct
  let word_size = 32

  let sum_constants = [|2; 13; 22; 6; 11; 25|]

  let sigma_constants = [|7; 18; 3; 17; 19; 10|]

  let round_constants = [||]

  let loop_bound = 64
end

module SHA256 = MAKE (Variant_sha256)
