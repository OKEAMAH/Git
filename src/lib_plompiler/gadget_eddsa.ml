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

module Make
    (Curve : Mec.CurveSig.AffineEdwardsT) (H : sig
      module P : Hash_sig.P_HASH

      module V : Hash_sig.HASH
    end) =
struct
  module Curve = Curve
  open Lang_core

  module P : sig
    type sk = Curve.Scalar.t

    type pk = Curve.t

    type signature = {r : Curve.t; s : bool list}

    type msg = S.t

    val neuterize : sk -> pk

    val sign : ?compressed:bool -> sk -> msg -> signature

    val verify :
      ?compressed:bool ->
      msg:msg ->
      pk:pk ->
      signature:signature ->
      unit ->
      bool
  end = struct
    module H = H.P

    type sk = Curve.Scalar.t

    type pk = Curve.t

    type signature = {r : Curve.t; s : bool list}

    type msg = S.t

    (* Compute the expanded keys for the EdDSA signature *)
    let expand_keys sk =
      (* h = (h_0, h_1, .., h_{2b-1}) <- H (sk) *)
      let h =
        let sk = Curve.Scalar.to_z sk |> S.of_z in
        H.direct ~input_length:1 [|sk|] |> S.to_bytes
      in
      let b = Bytes.length h / 2 in
      let h_low = Bytes.sub h 0 b in
      let h_high = Bytes.sub h b b in
      (* Curve.cofactor = 2^c *)
      (* c <= n < b *)
      (* TODO: compute s <- 2^n + \sum_i h_i * 2^i for c <= i < n *)
      let s = Curve.Scalar.of_bytes_exn h_low in
      (* pk <- [s]G *)
      let pk = Curve.mul Curve.one s in
      let prefix = S.of_bytes_exn h_high in
      (s, pk, prefix)

    let neuterize sk =
      let _s, pk, _prefix = expand_keys sk in
      pk

    let bls_scalar_to_curve_scalar s = Curve.Scalar.of_z (S.to_z s)

    (* S.t and Curve.t are the same but Curve.t is abstract *)
    let to_bls_scalar s = S.of_z (Curve.Base.to_z s)

    (* NOTE: H.direct returns a Bls12_381.Fr scalar *)
    (* h <- H (compressed (R) || compressed (pk) || msg ) mod Curve.Scalar.order *)
    let compute_h ?(compressed = false) msg pk r =
      ignore compressed ;
      let r_u = Curve.get_u_coordinate r |> to_bls_scalar in
      let r_v = Curve.get_v_coordinate r |> to_bls_scalar in
      let pk_u = Curve.get_u_coordinate pk |> to_bls_scalar in
      let pk_v = Curve.get_v_coordinate pk |> to_bls_scalar in
      H.direct ~input_length:5 [|r_u; r_v; pk_u; pk_v; msg|]
      |> bls_scalar_to_curve_scalar

    let sign ?(compressed = false) sk msg =
      let s, pk, prefix = expand_keys sk in
      (* r <- H (prefix || msg) *)
      let r = H.direct [|prefix; msg|] |> bls_scalar_to_curve_scalar in
      (* R <- [r]G *)
      let sig_r = Curve.mul Curve.one r in
      (* h <- H (compressed (R) || compressed (pk) || msg ) *)
      let h = compute_h ~compressed msg pk sig_r in
      (* s <- (r + h * s) mod Curve.Scalar.order *)
      let sig_s =
        Curve.Scalar.(r + (h * s))
        |> Curve.Scalar.to_z
        |> Utils.bool_list_of_z ~nb_bits:(Z.numbits Curve.Scalar.order)
      in
      {r = sig_r; s = sig_s}

    (* The fact that s < l is enforced by the fact that s is a Curve.Scalar.t ;
       the fact that pk & r are on curve is enforced by the fact they are Curve.t *)
    let verify ?(compressed = false) ~msg ~pk ~signature () =
      (* h <- H (compressed (R) || compressed (pk) || msg ) *)
      let h = compute_h ~compressed msg pk signature.r in
      let sig_s = Curve.Scalar.of_z @@ Utils.bool_list_to_z signature.s in
      (* [s]G =?= R + [h]pk *)
      Curve.(eq (mul Curve.one sig_s) (add signature.r (mul pk h)))
  end

  open Lang_stdlib
  open Gadget_edwards

  module V : functor (L : LIB) -> sig
    open L
    open MakeAffine(Curve)(L)

    (* TODO make abstract once compression is done with encodings *)
    type pk = point

    type signature = {r : point repr; s : bool list repr}

    module Encoding : sig
      open L.Encodings

      val pk_encoding : (Curve.t, pk repr, pk) encoding

      val signature_encoding : (P.signature, signature, pk * bool list) encoding
    end

    val verify :
      ?compressed:bool ->
      g:point repr ->
      msg:scalar repr ->
      pk:pk repr ->
      signature:signature ->
      unit ->
      bool repr t
  end =
  functor
    (L : LIB)
    ->
    struct
      open L
      include MakeAffine (Curve) (L)

      open H.V (L)

      type pk = point

      type signature = {r : point repr; s : bool list repr}

      module Encoding = struct
        open L.Encodings

        let point_encoding =
          let curve_base_to_s c = Lang_core.S.of_z @@ Curve.Base.to_z c in
          let curve_base_of_s c = Curve.Base.of_z @@ Lang_core.S.to_z c in
          with_implicit_bool_check is_on_curve
          @@ conv
               (fun r -> of_pair r)
               (fun (u, v) -> pair u v)
               (fun c ->
                 ( curve_base_to_s @@ Curve.get_u_coordinate c,
                   curve_base_to_s @@ Curve.get_v_coordinate c ))
               (fun (u, v) ->
                 Curve.from_coordinates_exn
                   ~u:(curve_base_of_s u)
                   ~v:(curve_base_of_s v))
               (obj2_encoding scalar_encoding scalar_encoding)

        let pk_encoding = point_encoding

        let signature_encoding =
          conv
            (fun {r; s} -> (r, s))
            (fun (r, s) -> {r; s})
            (fun ({r; s} : P.signature) -> (r, s))
            (fun (r, s) -> {r; s})
            (obj2_encoding point_encoding (atomic_list_encoding bool_encoding))
      end

      (* NOTE: digest returns a Bls12_381.Fr scalar *)
      (* h <- H (compressed (R) || compressed (pk) || msg ) *)
      let compute_h ?(compressed = false) msg pk r : scalar repr t =
        ignore compressed ;
        with_label ~label:"EdDSA.compute_h"
        @@
        let r_x = get_x_coordinate r in
        let r_y = get_y_coordinate r in
        let pk_x = get_x_coordinate pk in
        let pk_y = get_y_coordinate pk in
        digest ~input_length:5 @@ to_list [r_x; r_y; pk_x; pk_y; msg]

      (* TODO: now msg is just one scalar, it will probably be a list of scalars *)
      (* assert s < Curve.Scalar.order *)
      (* reduce h modulo Curve.Scalar.order *)
      (* assert r & pk are on curve *)
      let verify ?(compressed = false) ~g ~msg ~pk ~signature () =
        with_label ~label:"EdDSA.verify"
        @@
        let {r; s} = signature in
        (* h <- H (compressed (R) || compressed (pk) || msg ) *)
        let* h = compute_h ~compressed msg pk r in
        (* NOTE: we do not reduce a result of compute_h modulo Curve.Scalar.order *)
        let* h = bits_of_scalar ~nb_bits:(Z.numbits S.order) h in
        with_label ~label:"EdDSA.scalar_mul"
        (* It would be better to compute R = sg - h Pk using multiexp *)
        (* [s]G =?= R + [h]pk <==> R =?= [s]G - [h]pk *)
        @@ let* sg = scalar_mul s g in
           let* hpk = scalar_mul h pk in
           let* rhpk = add r hpk in
           with_label ~label:"EdDSA.check" @@ equal sg rhpk
    end
end
