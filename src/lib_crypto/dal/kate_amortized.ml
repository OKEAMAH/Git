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

  external prepare_fft : int -> int -> Scalar.t -> Scalar.t array -> int
    = "caml_fft_prepare_stubs2"

  external fft_inplace2_stubs :
    Scalar.t array -> int -> int -> Scalar.t array -> Scalar.t -> int
    = "caml_fft_fr_inplace_stubs2"

  external fft_inplace3_stubs :
    Scalar.t array -> Scalar.t array -> int -> int -> int
    = "caml_fft_fr_inplace_stubs3"

  external mul_map_inplace3 : Scalar.t array -> Scalar.t -> int -> int
    = "caml_mul_map_fr_inplace_stubs3"

  (*external fft_inplace4_stubs :
    Scalar.t array ->
    Scalar.t array ->
    Scalar.t array ->
    Scalar.t array ->
    int ->
    int = "fft_fr_inplaceRadix4"*)

  (* TODO: avoid float conversions *)
  let log4 a = Float.to_int (floor (Float.of_int (Z.log2 a) /. 2.))

  let prepare_fft ~phi2N ~domlen () =
    Printf.eprintf "\n 24 = " ;
    String.iter
      (fun c -> if c = '1' then Printf.eprintf "1" else Printf.eprintf "0")
      (Z.to_bits @@ Z.of_int 24) ;
    let n = domlen in

    let log4dom = log4 (Z.of_int n) in
    Printf.eprintf "\nn=%d ;%d \n" n log4dom ;

    (* TODO*)
    let len =
      3
      * (((domlen - (domlen / (Z.to_int @@ Z.pow (Z.of_int 4) log4dom))) / 3)
        + 1)
    in

    Printf.eprintf "\n len = %d \n" len ;
    let w = Array.make len Scalar.(copy zero) in
    ignore @@ prepare_fft domlen log4dom phi2N w ;
    w

  let fft_inplace2 ~points ~prepare =
    let n = Array.length points in
    let log4dom = log4 (Z.of_int n) in
    let multiplicative_group_order = Z.(Scalar.order - one) in
    let exponent = Z.divexact multiplicative_group_order (Z.of_int 4) in
    let primroot4th = Scalar.pow (Scalar.of_int 7) exponent in
    ignore @@ fft_inplace2_stubs points n log4dom prepare primroot4th

  let fft_inplace3 ~domain ~points =
    let n = Z.of_int (Array.length points) in
    Printf.eprintf "\n n=%d \n" (Array.length points) ;
    let log2 = Z.log2 n in
    let log4 = log4 n in
    ignore @@ fft_inplace3_stubs points domain log2 log4

  let ifft_inplace3 ~domain ~points =
    let n = Array.length points in
    let logn = Z.log2 (Z.of_int n) in
    let log4 = log4 @@ Z.of_int n in
    let n_inv = Scalar.inverse_exn (Scalar.of_z (Z.of_int n)) in
    ignore @@ fft_inplace3_stubs points domain logn log4 ;
    ignore @@ mul_map_inplace3 points n_inv n

  let build_array w j len =
    Array.init len (fun i -> Scalar.pow w (Z.of_int @@ (j * i)))

  (*let fft_inplace4 ~domain ~points =
    let n' = Array.length points in
    let n = Z.of_int n' in
    Printf.eprintf "\n n=%d ; %d\n" (Array.length points) (Array.length domain) ;
    let log2 = Z.log2 n in
    let _log4 = log4 n in
    let w = Array.get domain 1 in
    ignore
    @@ fft_inplace4_stubs
         points
         domain
         (build_array w 2 n')
         (build_array w 3 n')
         log2*)

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

  let print_array a =
    Printf.eprintf "\n" ;
    Array.iter
      (fun i ->
        if G1.eq i G1.zero then Printf.eprintf " 0 " else Printf.eprintf " x ")
      a ;
    Printf.eprintf "\n"

  let print_array2 a =
    Printf.eprintf "\n" ;
    Array.iter
      (fun i ->
        if Scalar.eq i Scalar.zero then Printf.eprintf " 0 "
        else Printf.eprintf " %s " (Scalar.to_string i))
      a ;
    Printf.eprintf "\n"

  let diff_next_power_of_two x =
    let logx = Z.log2 (Z.of_int x) in
    if 1 lsl logx = x then 0 else (1 lsl (logx + 1)) - x

  let is_pow_of_two x =
    let logx = Z.log2 (Z.of_int x) in
    1 lsl logx = x

  let preprocess_multi_reveals ~chunk_len ~chunk_count ~degree srs1 =
    let l = 1 lsl chunk_len in
    (*let k = chunk_count in*)
    (*let ratio = degree / l in
        let log_inf = Z.log2 (Z.of_int ratio) in
        if 1 lsl log_inf < ratio then log_inf else log_inf + 1
      in*)
    Printf.eprintf "\n k =%d\n" chunk_count ;
    let domain = Domain.build ~log:chunk_count |> Domain.inverse |> inverse in
    let precompute_srsj j =
      let quotient = (degree - j) / l in
      (*let _padding = diff_next_power_of_two (2 * quotient) in*)
      (*Printf.eprintf "\n l=%d step j=%d : " l j ;*)
      let points =
        Array.init (1 lsl chunk_count) (*((2 * quotient) + padding)*) (fun i ->
            if i < quotient then
              (*Printf.eprintf " %d " (degree - j - ((i + 1) * l)) ;*)
              G1.copy srs1.(degree - j - ((i + 1) * l))
            else G1.(copy zero))
      in
      (*print_array points ;*)
      G1.fft_inplace ~domain ~points ;
      (*print_array points ;*)
      points
    in
    (domain, Array.init l precompute_srsj)

  (* Generate proofs of part 3.2. *)

  (** n, r are powers of two, m = 2^(log2(n)-1)
      coefs are f polynomial’s coefficients [f₀, f₁, f₂, …, fm-1]
      domain2m is the set of 2m-th roots of unity, used for Toeplitz computation
      (domain2m, precomputed_srs_part) = preprocess_multi_reveals r n m (srs1, _srs2)
      returns proofs of part 3.2. *)
  let multiple_multi_reveals ~chunk_len ~chunk_count ~degree
      ~preprocess:(domain, precomputed_srs_part) coefs =
    let n = chunk_len + chunk_count in
    assert (2 <= chunk_len) ;
    assert (chunk_len < n) ;
    assert (is_pow_of_two degree) ;
    assert (1 lsl chunk_len < degree) ;
    assert (degree <= 1 lsl n) ;

    (*Printf.eprintf
      "\n chunk count = %d ; len = %d\n"
      chunk_count
      (Array.length domain) ;*)

    (*let len = 1 lsl chunk_count (*Array.length domain2m*) in*)
    let l = 1 lsl chunk_len in
    let domain_size = 1 lsl chunk_count in
    (* we don’t need the first coefficient f₀ *)
    let compute_h_j j buffer buffer_srs =
      let rest = (degree - j) mod l in
      let quotient = (degree - j) / l in
      (* Padding in case quotient is not a power of 2 to get proper fft in
         Toeplitz matrix part. *)
      let padding = diff_next_power_of_two (2 * quotient) in
      (* fm, 0, …, 0, f₁, f₂, …, fm-1 *)
      for i = 0 to domain_size - 1 do
        if i <= quotient + (padding / 2) then buffer.(i) <- Scalar.(copy zero)
        else if i < (2 * quotient) + padding then
          buffer.(i) <-
            Scalar.copy coefs.(rest + ((i - (quotient + padding)) * l))
        else buffer.(i) <- Scalar.(copy zero)
      done ;

      if j <> 0 then buffer.(0) <- Scalar.copy coefs.(degree - j) ;

      Scalar.fft_inplace ~domain ~points:buffer ;
      let v = precomputed_srs_part.(j) in
      for i = 0 to Array.length domain - 1 do
        buffer_srs.(i) <- G1.(add buffer_srs.(i) (mul v.(i) buffer.(i)))
      done
    in

    let t = Sys.time () in
    let buffer = Array.make domain_size Scalar.(copy zero) in
    let hl = Array.make domain_size G1.(copy zero) in

    for j = 0 to l - 1 do
      compute_h_j j buffer hl
    done ;
    (* Toeplitz matrix-vector multiplication *)
    let hl =
      G1.ifft_inplace ~domain:(inverse domain) ~points:hl ;
      Array.sub hl 0 (Array.length domain / 2)
    in
    Printf.eprintf "\n hl %f \n" (Sys.time () -. t) ;
    let t = Sys.time () in
    (* Kate amortized FFT *)
    G1.fft_inplace ~domain ~points:hl ;
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
