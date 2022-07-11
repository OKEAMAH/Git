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

(* Implementation of fast amortized Kate proofs
   https://github.com/khovratovich/Kate/blob/master/Kate_amortized.pdf). *)

module Kate_amortized = struct
  module Scalar = Bls12_381.Fr
  module G1 = Bls12_381.G1
  module G2 = Bls12_381.G2
  module GT = Bls12_381.GT
  module Pairing = Bls12_381.Pairing
  module Domain = Bls12_381_polynomial.Polynomial.Domain
  module Polynomial = Bls12_381_polynomial.Polynomial

  type proof = G1.t

  type srs = G1.t list * G2.t

  type commitment = G1.t

  let commit p srs =
    if p = [||] then G1.(copy zero)
    else if Array.(length p > length srs) then
      raise
        (Failure
           (Printf.sprintf
              "Kzg.compute_encoded_polynomial : Polynomial degree, %i, exceeds \
               srs’ length, %i."
              (Array.length p)
              (Array.length srs)))
    else G1.pippenger ~start:0 ~len:(Array.length p) srs p

  let inverse domain =
    let n = Array.length domain in
    Array.init n (fun i ->
        if i = 0 then Bls12_381.Fr.(copy one) else Array.get domain (n - i))

  (* First part of Toeplitz computing trick involving srs. *)
  let build_srs_part_h_list srs domain2m =
    let domain2m = inverse @@ Domain.inverse domain2m in
    assert (Array.length domain2m = Array.length srs) ;
    G1.fft_inplace ~domain:domain2m ~points:srs ;
    srs

  let build_h_list_with_precomputed_srs a_list (domain2m, precomputed_srs) =
    Scalar.fft_inplace ~domain:domain2m ~points:a_list ;
    Array.map2 G1.mul precomputed_srs a_list

  (* Final ifft of Toeplitz computation. *)
  let build_h_list_final u domain2m =
    G1.ifft_inplace ~domain:(inverse domain2m) ~points:u ;
    Array.sub u 0 (Array.length domain2m / 2)

  let diff_next_power_of_two x =
    let logx = Z.log2 (Z.of_int x) in
    if 1 lsl logx = x then 0 else (1 lsl (logx + 1)) - x

  let is_pow_of_two x =
    let logx = Z.log2 (Z.of_int x) in
    1 lsl logx = x

  (* Precompute first part of Toeplitz trick, which doesn't depends on the
     polynomial’s coefficients. *)
  let preprocess_multi_reveals ~chunk_len ~degree srs1 =
    let l = 1 lsl chunk_len in
    let k =
      let ratio = degree / l in
      let log_inf = Z.log2 (Z.of_int ratio) in
      if 1 lsl log_inf < ratio then log_inf else log_inf + 1
    in
    let domain2m = Domain.build ~log:k in
    let precompute_srsj j =
      let quotient = (degree - j) / l in
      let _padding = diff_next_power_of_two (2 * quotient) in
      let srsj =
        Array.init (1 lsl k) (*((2 * quotient) + padding)*) (fun i ->
            if i < quotient then G1.copy srs1.(degree - j - ((i + 1) * l))
            else G1.(copy zero))
      in
      build_srs_part_h_list srsj domain2m
    in
    (domain2m, Array.init l precompute_srsj)

  (* Generate proofs of part 3.2. *)

  (** n, r are powers of two, m = 2^(log2(n)-1)
      coefs are f polynomial’s coefficients [f₀, f₁, f₂, …, fm-1]
      domain2m is the set of 2m-th roots of unity, used for Toeplitz computation
      (domain2m, precomputed_srs_part) = preprocess_multi_reveals r n m (srs1, _srs2)
      returns proofs of part 3.2. *)
  let multiple_multi_reveals ~chunk_len ~chunk_count ~degree
      ~preprocess:(domain2m, precomputed_srs_part) coefs =
    let n = chunk_len + chunk_count in
    assert (2 <= chunk_len) ;
    assert (chunk_len < n) ;
    assert (is_pow_of_two degree) ;
    assert (1 lsl chunk_len < degree) ;
    assert (degree <= 1 lsl n) ;

    let len = Array.length domain2m in
    let l = 1 lsl chunk_len in
    (* we don’t need the first coefficient f₀ *)
    let compute_h_j j =
      let rest = (degree - j) mod l in
      let quotient = (degree - j) / l in
      (* Padding in case quotient is not a power of 2 to get proper fft in
         Toeplitz matrix part. *)
      let padding = diff_next_power_of_two (2 * quotient) in
      (* fm, 0, …, 0, f₁, f₂, …, fm-1 *)
      let a_array =
        Array.init len (fun i ->
            if i <= quotient + (padding / 2) then Scalar.(copy zero)
            else if i < (2 * quotient) + padding then
              Scalar.copy coefs.(rest + ((i - (quotient + padding)) * l))
            else Scalar.(copy zero))
      in
      if j = 0 then a_array.(0) <- Scalar.(copy zero)
      else a_array.(0) <- Scalar.copy coefs.(degree - j) ;
      build_h_list_with_precomputed_srs
        a_array
        (domain2m, precomputed_srs_part.(j))
    in
    let t = Sys.time () in
    let sum = compute_h_j 0 in
    let hl =
      let rec sum_hj j =
        if j = l then ()
        else
          let hj = compute_h_j j in
          (* sum.(i) <- sum.(i) + hj.(i) *)
          Array.iteri (fun i hij -> sum.(i) <- G1.add sum.(i) hij) hj ;
          sum_hj (j + 1)
      in
      sum_hj 1 ;
      build_h_list_final sum domain2m
    in
    Printf.eprintf "\n hl %f \n" (Sys.time () -. t) ;
    let t = Sys.time () in
    let phidomain = Domain.build ~log:chunk_count in
    let phidomain = inverse (Domain.inverse phidomain) in
    G1.fft_inplace ~domain:phidomain ~points:hl ;
    Printf.eprintf "\n last FFT %f \n" (Sys.time () -. t) ;
    hl

  (* h = polynomial such that h(y×domain[i]) = zi. *)
  let interpolation_h_poly y domain z_list =
    let h =
      Scalar.ifft_inplace ~domain:(Domain.inverse domain) ~points:z_list ;
      z_list
    in
    let inv_y = Scalar.inverse_exn y in
    snd
      (Array.fold_left_map
         (fun inv_yi h -> (Scalar.mul inv_yi inv_y, Scalar.mul h inv_yi))
         Scalar.(copy one)
         h)

  let interpolation_h_poly2 y domain z_list =
    let h =
      Scalar.ifft_inplace ~domain:(inverse domain) ~points:z_list ;
      z_list
    in
    let inv_y = Scalar.inverse_exn y in
    snd
      (Array.fold_left_map
         (fun inv_yi h -> (Scalar.mul inv_yi inv_y, Scalar.mul h inv_yi))
         Scalar.(copy one)
         h)

  (* Part 3.2 verifier : verifies that f(w×domain.(i)) = evaluations.(i). *)
  let verify cm_f (srs1, srs2l) domain (w, evaluations) proof =
    let h = interpolation_h_poly w domain evaluations in
    let cm_h = commit h srs1 in
    let l = Domain.length domain in
    let sl_min_yl =
      G2.(add srs2l (negate (mul (copy one) (Scalar.pow w (Z.of_int l)))))
    in
    let diff_commits = G1.(add cm_h (negate cm_f)) in
    Pairing.pairing_check [(diff_commits, G2.(copy one)); (proof, sl_min_yl)]

  let verify2 cm_f (srs1, srs2l) (domain : Scalar.t array) (w, evaluations)
      proof =
    let h = interpolation_h_poly2 w domain evaluations in
    let cm_h = commit h srs1 in
    let l = Array.length domain in
    let sl_min_yl =
      G2.(add srs2l (negate (mul (copy one) (Scalar.pow w (Z.of_int l)))))
    in
    let diff_commits = G1.(add cm_h (negate cm_f)) in
    Pairing.pairing_check [(diff_commits, G2.(copy one)); (proof, sl_min_yl)]
end

module type Kate_amortized_sig = sig
  module Scalar : Ff_sig.PRIME with type t = Bls12_381.Fr.t

  type srs

  type proof

  type commitment

  val commit : Scalar.t list -> srs -> commitment

  module Domain : sig
    type t

    val build : int -> t

    val get : t -> int -> Scalar.t

    val map : (Scalar.t -> Scalar.t) -> t -> Scalar.t array
  end

  (* part 3.2 proofs *)

  val preprocess_multi_reveals :
    chunk_len:int ->
    degree:int ->
    srs ->
    Scalar.t array * commitment array option array

  (** [multiple_multi_reveals_with_preprocessed_srs ~chunk_len:r
      ~chunk_count:(n-r) ~degree:m [f₀, f₁, …, fm-1] precomputed] returns the
      2ⁿ⁻ʳ proofs (each proof stands for for 2ʳ evaluations) for polynomial
      f₀ + f₁X + … as in part 3.2. *)
  val multiple_multi_reveals :
    chunk_len:int ->
    chunk_count:int ->
    degree:int ->
    preprocess:Scalar.t array * commitment array option array ->
    Scalar.t array ->
    proof array

  (** [verify cm_f srs domain (w, evaluations) proof] returns true iff for all i,
     f(w×domain.(i) = evaluations.(i)). *)
  val verify :
    commitment -> srs -> Domain.t -> Scalar.t * Scalar.t array -> proof -> bool

  val verify2 :
    commitment ->
    srs ->
    Scalar.t array ->
    Scalar.t * Scalar.t array ->
    proof ->
    bool
end
