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

open Lang_core
open Lang_stdlib

module type AFFINE = functor (L : LIB) -> sig
  open L
  module Curve = Mec.Curve.Curve25519.AffineEdwards

  type nat_mod (* for a base field arithmetic *)

  type point = nat_mod * nat_mod

  val point_encoding : (Curve.t, point repr, point) Encodings.encoding

  val input_point : ?kind:input_kind -> Z.t * Z.t -> point repr t

  val is_on_curve : point repr -> bool repr t

  (** Also checks that the point is on the curve (but not necessarily in the
      subgroup). *)
  val from_coordinates : nat_mod repr -> nat_mod repr -> point repr t

  val unsafe_from_coordinates : nat_mod repr -> nat_mod repr -> point repr t

  val get_x_coordinate : point repr -> nat_mod repr

  val get_y_coordinate : point repr -> nat_mod repr

  val bytes_of_point : ?compressed:bool -> point repr -> Bytes.bl repr t

  (** The identity element of the curve (0, 1). *)
  val id : point repr t

  val add : point repr -> point repr -> point repr t

  val cond_add : point repr -> point repr -> bool repr -> point repr t

  val double : point repr -> point repr t

  val scalar_mul : bool list repr -> point repr -> point repr t

  val scalar_order : Z.t

  val base_order : Z.t

  val multi_scalar_mul : bool list list repr -> point list repr -> point repr t
end

module MakeEdwards25519 : AFFINE =
functor
  (L : LIB)
  ->
  struct
    open L
    module M = Gadget_mod_arith.ArithMod25519 (L)
    module Curve = Mec.Curve.Curve25519.AffineEdwards

    type nat_mod = M.mod_int

    type point = nat_mod * nat_mod

    let is_on_curve p : bool repr t =
      with_label ~label:"Edwards25519.is_on_curve"
      @@
      let u, v = of_pair p in
      let* u2 = M.mul u u in
      let* v2 = M.mul v v in
      (* x_l = u^2 *)
      (* x_r = v^2 *)
      (* 1 * v^2 + (-1) * u^2 = 1 + d * u^2 * v^2 *)
      (* |           |          |   |             *)
      (* ql          qr         qc  qm            *)
      let qm = Curve.Base.to_z Curve.d in
      let* lhs = M.sub v2 u2 in
      let* u2v2 = M.mul u2 v2 in
      let* du2v2 = M.mul_constant u2v2 qm in
      let* rhs = M.add_constant du2v2 Z.one in
      M.equal lhs rhs

    let point_encoding : (Curve.t, point repr, point) Encodings.encoding =
      let open Encodings in
      with_implicit_bool_check is_on_curve
      @@ conv
           of_pair
           (fun (x, y) -> pair x y)
           (fun c ->
             let to_limbs (x : Curve.Base.t) =
               Utils.z_to_limbs ~len:M.nb_limbs ~base:M.base
               @@ Curve.Base.to_z x
               |> List.map S.of_z
             in
             let x = Curve.get_u_coordinate c |> to_limbs in
             let y = Curve.get_v_coordinate c |> to_limbs in
             (x, y))
           (fun (x, y) ->
             let of_limbs (n : S.t list) =
               Utils.z_of_limbs ~base:M.base @@ List.map S.to_z n
               |> Curve.Base.of_z
             in
             Curve.from_coordinates_exn ~u:(of_limbs x) ~v:(of_limbs y))
           (Encodings.obj2_encoding M.mod_int_encoding M.mod_int_encoding)

    let input_point ?(kind = `Private) (x, y) : point repr t =
      let* x = M.input_mod_int ~kind x in
      let* y = M.input_mod_int ~kind y in
      ret (pair x y)

    let from_coordinates u v =
      with_label ~label:"Edwards25519.from_coordinates"
      @@
      let p = pair u v in
      with_bool_check (is_on_curve p) >* ret p

    let unsafe_from_coordinates u v =
      with_label ~label:"Edwards25519.unsafe_from_coordinates" (pair u v |> ret)

    let get_x_coordinate p = of_pair p |> fst

    let get_y_coordinate p = of_pair p |> snd

    (* BSeq.nat_to_bytes_le 32 (pow2 255 * (x % 2) + y) *)
    let bytes_of_point ?(compressed = false) p : Bytes.bl repr t =
      if compressed then
        let px = get_x_coordinate p in
        let py = get_y_coordinate p in
        (* px_bytes is in little-endian *)
        let* px_bytes = M.bytes_of_mod_int px in
        let px0 = List.hd @@ of_list px_bytes in
        let* py_bytes = M.bytes_of_mod_int py in
        ret @@ to_list (px0 :: of_list py_bytes)
      else
        let px = get_x_coordinate p in
        let py = get_y_coordinate p in
        let* px_bytes = M.bytes_of_mod_int px in
        let* py_bytes = M.bytes_of_mod_int py in
        ret @@ Bytes.concat [|px_bytes; py_bytes|]

    let id =
      let* zero = M.zero in
      let* one = M.one in
      unsafe_from_coordinates zero one

    let add p q : point repr t =
      let x1, y1 = of_pair p in
      let x2, y2 = of_pair q in
      let* x1x2 = M.mul x1 x2 in
      let* y1y2 = M.mul y1 y2 in
      let* dx1x2y1y2 =
        let* x1x2y1y2 = M.mul x1x2 y1y2 in
        M.mul_constant x1x2y1y2 (Curve.Base.to_z Curve.d)
      in
      (* x3 = (x1 * y2 + y1 * x2) / (1 + dx1x2y1y2) *)
      let* x3 =
        let* x1y2 = M.mul x1 y2 in
        let* y1x2 = M.mul y1 x2 in
        let* x1y2_plus_y1x2 = M.add x1y2 y1x2 in
        let* one_plus_dx1x2y1y2 = M.add_constant dx1x2y1y2 Z.one in
        M.div x1y2_plus_y1x2 one_plus_dx1x2y1y2
      in
      (* y3 = (y1y2 + x1x2) / (1 - dx1x2y1y2) *)
      let* y3 =
        let* y1y2_plus_x1x2 = M.add y1y2 x1x2 in
        let* minus_dx1x2y1y2 = M.neg dx1x2y1y2 in
        let* one_minus_dx1x2y1y2 = M.add_constant minus_dx1x2y1y2 Z.one in
        M.div y1y2_plus_x1x2 one_minus_dx1x2y1y2
      in
      unsafe_from_coordinates x3 y3

    let point_or_zero p b =
      let* id in
      let* bq = Bool.ifthenelse b p id in
      ret bq

    (* compute R = P + b * Q *)
    let cond_add p q b =
      let* bq = point_or_zero q b in
      add p bq

    let double p = add p p

    let scalar_order : Z.t = Curve.Scalar.order

    let base_order : Z.t = Curve.Base.order

    let scalar_mul s p =
      let* one = Bool.constant true in
      with_label ~label:"Edwards25519.scalar_mul"
      @@
      let rev_s = List.rev (of_list s) in
      let* init = point_or_zero p (List.hd rev_s) in
      foldM
        (fun acc b ->
          let* acc = cond_add acc acc one in
          cond_add acc p b)
        init
        (List.tl rev_s)

    let multi_scalar_mul ls lp =
      let* one = Bool.constant true in
      with_label ~label:"Edwards.multi_scalar_mul"
      @@
      (* Check we apply Shamir's trick on at least 2 points *)
      let () = assert (List.(length (of_list ls) > 1)) in
      (* Converting ls to ls' = [[s_11; ...; s_n1]; ...; [s_1m; ...; s_nm]] *)
      let ls = List.map of_list (of_list ls) |> Utils.transpose |> List.rev in
      let points = of_list lp in
      (* Check we perform scalar multiplications on lists of at least 1 bit *)
      assert (List.(length ls > 0)) ;
      (* Initializing the accumulator with the first round of Shamir's trick *)
      let heads = List.hd ls in
      let* init = point_or_zero (List.hd points) (List.hd heads) in
      let* init = fold2M cond_add init (List.tl points) (List.tl heads) in

      (* Applying Shamir's trick on the rest of the rounds *)
      foldM
        (fun acc lb ->
          let* acc = cond_add acc acc one in
          fold2M cond_add acc points (of_list lb))
        init
        List.(map to_list (tl ls))
  end
