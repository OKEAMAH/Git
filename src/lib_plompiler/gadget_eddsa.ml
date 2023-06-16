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

module Make = struct
  module Curve = Mec.Curve.Curve25519.AffineEdwards

  module P : sig
    type sk = Bytes.t

    type pk = Curve.t

    type signature = {r : Curve.t; s : bool list}

    type msg = Bytes.t

    val neuterize : sk -> pk

    val sign : sk -> msg -> signature

    val verify : msg:msg -> pk:pk -> signature:signature -> unit -> bool
  end = struct
    module H = Hacl_star.Hacl.SHA2_512

    type sk = Bytes.t

    type pk = Curve.t

    type signature = {r : Curve.t; s : bool list}

    type msg = Bytes.t

    (* Compute the expanded keys for the EdDSA signature *)
    let expand_keys sk =
      assert (Bytes.length sk = 32) ;
      (* h = (h_0, h_1, .., h_{2b-1}) <- H (sk) *)
      let h = H.hash @@ sk in
      let b = Bytes.length h / 2 in
      let h_low = Bytes.sub h 0 b in
      let h_high = Bytes.sub h b b in
      (* Curve.cofactor = 2^c *)
      (* c <= n < b *)
      (* s <- 2^n + \sum_i h_i * 2^i for c <= i < n *)
      Bytes.set_uint8 h_low 0 (Int.logand (Bytes.get_uint8 h_low 0) 248) ;
      Bytes.set_uint8
        h_low
        31
        (Int.logor (Int.logand (Bytes.get_uint8 h_low 31) 127) 64) ;
      (* pk <- [s]G *)
      let s = Curve.Scalar.of_bytes_exn h_low in
      let pk = Curve.mul Curve.one s in
      (s, pk, h_high)

    let neuterize sk =
      let _s, pk, _prefix = expand_keys sk in
      pk

    (* BSeq.nat_to_bytes_le 32 (pow2 255 * (x % 2) + y) *)
    let point_compress (p : Curve.t) : Bytes.t =
      let px = Curve.get_u_coordinate p |> Curve.Base.to_z in
      let px_sign = Z.(px mod of_int 2) in
      let py = Curve.get_v_coordinate p |> Curve.Base.to_z in
      let res = Z.(((one lsl 255) * px_sign) + py) in
      Bytes.of_string @@ Z.to_bits res

    (* h <- H (compressed (R) || compressed (pk) || msg ) mod Curve.Scalar.order *)
    let compute_h msg pk r =
      let r = point_compress r in
      let pk = point_compress pk in
      H.hash (Bytes.concat Bytes.empty [r; pk; msg])
      |> Curve.Scalar.of_bytes_exn

    let sign sk msg =
      let s, pk, prefix = expand_keys sk in
      (* r <- H (prefix || msg) *)
      let r = H.hash (Bytes.cat prefix msg) |> Curve.Scalar.of_bytes_exn in
      (* R <- [r]G *)
      let sig_r = Curve.mul Curve.one r in
      (* h <- H (compressed (R) || compressed (pk) || msg ) *)
      let h = compute_h msg pk sig_r in
      (* s <- (r + h * s) mod Curve.Scalar.order *)
      let sig_s =
        Curve.Scalar.(r + (h * s))
        |> Curve.Scalar.to_z
        |> Utils.bool_list_of_z ~nb_bits:(Z.numbits Curve.Scalar.order)
      in
      {r = sig_r; s = sig_s}

    (* The fact that s < l is enforced by the fact that s is a Curve.Scalar.t ;
       the fact that pk & r are on curve is enforced by the fact they are Curve.t *)
    let verify ~msg ~pk ~signature () =
      (* h <- H (compressed (R) || compressed (pk) || msg ) *)
      let h = compute_h msg pk signature.r in
      let sig_s = Curve.Scalar.of_z @@ Utils.bool_list_to_z signature.s in
      (* [s]G =?= R + [h]pk *)
      Curve.(eq (mul Curve.one sig_s) (add signature.r (mul pk h)))
  end

  open Lang_stdlib

  module V : functor (L : LIB) -> sig
    open L
    open Gadget_edwards25519.MakeEdwards25519(L)

    (* TODO make abstract once compression is done with encodings *)
    type pk = point

    type signature = {r : point repr; s : bool list repr}

    module Encoding : sig
      open L.Encodings

      val pk_encoding : (Curve.t, pk repr, pk) encoding

      val signature_encoding : (P.signature, signature, pk * bool list) encoding
    end

    val verify :
      msg:Bytes.bl repr ->
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
      include Gadget_edwards25519.MakeEdwards25519 (L)
      module H = Gadget_sha2.SHA512 (L)

      type pk = point

      type signature = {r : point repr; s : bool list repr}

      module Encoding = struct
        open L.Encodings

        let pk_encoding = point_encoding

        let signature_encoding =
          conv
            (fun {r; s} -> (r, s))
            (fun (r, s) -> {r; s})
            (fun ({r; s} : P.signature) -> (r, s))
            (fun (r, s) -> {r; s})
            (obj2_encoding point_encoding (atomic_list_encoding bool_encoding))
      end

      let split_exactly (list : bool list repr) size_chunk : bool repr list list
          =
        let nb_chunks = Bytes.length list / size_chunk in
        assert (Bytes.length list = size_chunk * nb_chunks) ;
        List.init nb_chunks (fun i ->
            let array = Array.of_list (of_list list) in
            let array = Array.sub array (i * size_chunk) size_chunk in
            Array.to_list array)

      let bytes_change_endianness (b : Bytes.bl repr) : Bytes.bl repr t =
        assert (Bytes.length b mod 8 = 0) ;
        let lb = split_exactly b 8 |> List.rev |> List.flatten in
        ret @@ to_list lb

      (* h <- H (compressed (R) || compressed (pk) || msg ) *)
      let compute_h msg pk r =
        with_label ~label:"EdDSA.compute_h"
        @@ let* r_bytes = bytes_of_point r in
           let* pk_bytes = bytes_of_point pk in
           let* r_pk_msg =
             bytes_change_endianness @@ Bytes.concat [|msg; pk_bytes; r_bytes|]
           in
           let* h = H.digest r_pk_msg in
           bytes_change_endianness h

      (* assert s < Curve.Scalar.order *)
      (* reduce h modulo Curve.Scalar.order *)
      (* assert r & pk are on curve *)
      let verify ~msg ~pk ~signature () =
        with_label ~label:"EdDSA.verify"
        @@
        let {r; s} = signature in
        ignore s ;
        (* h <- H (compressed (R) || compressed (pk) || msg ) *)
        let* h = compute_h msg pk r in
        (* NOTE: we do not reduce a result of compute_h modulo Curve.Scalar.order *)
        with_label ~label:"EdDSA.scalar_mul"
        (* It would be better to compute R = sg - h Pk using multiexp *)
        (* [s]G =?= R + [h]pk <==> R =?= [s]G - [h]pk *)
        @@ let* base_point in
           let* sg = scalar_mul s base_point in
           let* hpk = scalar_mul h pk in
           let* rhpk = add r hpk in
           with_label ~label:"EdDSA.check" @@ equal sg rhpk
    end
end
