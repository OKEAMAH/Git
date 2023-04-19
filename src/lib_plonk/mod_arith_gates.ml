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

open Bls
open Identities
module L = Plompiler.LibCircuit
open Gates_common

(* Arithmetic modulo 2^255 - 19 : TODO
   Non Arith
   degree : TODO
   nb identities : TODO
   advice selectors : None
   equations : TODO
*)
module AddMod25519 : Base_sig = struct
  let q_label = "q_mod_arith"

  (* The modulus of the computation, also denoted as m *)
  let modulus = Z.(shift_left one 255 - of_int 19)

  (* The base of the computation, also denoted as B *)
  let base = Z.(shift_left one 85)

  (* Number of limbs to represent an integer modulo m *)
  let nb_limbs = 3

  let _ = assert (Z.(pow base nb_limbs >= modulus))

  let moduli = [base]

  (* We enforce z = (x + y) mod m with the equation:
     \sum_i (B^i mod m) * (x_i + y_i - z_i) = qm * m

     In that case, we can establish the following bounds on qm:
       qm_min =   - (B-1) * \sum_i (B^i mod m) / m
       qm_max = 2 * (B-1) * \sum_i (B^i mod m) / m
  *)

  let sum = List.fold_left Z.add Z.zero

  let ( %! ) n m = Z.div_rem n m |> snd

  (* An alias for modulus *)
  let m = modulus

  let bs_mod_m = List.init nb_limbs (fun i -> Z.pow base i %! m)

  let qm_min = Z.(div (neg (base - one) * sum bs_mod_m) m)

  let qm_max = Z.(div (of_int 2 * (base - one) * sum bs_mod_m) m)

  (* We can thus restrict qm to be in [qm_min, qm_max] or any bigger interval
     (for correctness). In order for the interval to start at 0, let us modify
     the above equation as follows:
     \sum_i (B^i mod m) * (x_i + y_i - z_i) = (qm + qm_min) * m

     Now, we can bound qm in the interval [0, qm_max - qm_min].
     For compatibility with our range-check protocol, we will upper-bound
     the interval by a power of 2^15, the one immediately larger than
     qm_max - qm_min.
  *)

  (* Returns the next multiple of k greater than or equal to the given int *)
  let next_multiple_of k n = k * (1 + ((n - 1) / k))

  let qm_bound =
    Z.(shift_left one (next_multiple_of 15 @@ numbits (qm_max - qm_min)))

  (* Now, assuming qm is restricted in [0, qm_bound), let us bound the amount
     \sum_i (B^i mod m) * (x_i + y_i - z_i) - (qm + qm_min) * m

     lower_bound:   - (B-1) * \sum_i (B^i mod m) - (qm_bound + qm_min) * m
     upper_bound: 2 * (B-1) * \sum_i (B^i mod m) - qm_min * m

     Then, if we define M := native_modulus :: moduli, lcm(M) must be larger
     than (upper_bound - lower_bound) to guarantee that a solution modulo lcm(M)
     implies a solution over the integers.
  *)

  let lower_bound =
    Z.((neg (base - one) * sum bs_mod_m) - ((qm_bound + qm_min) * m))

  let upper_bound = Z.((of_int 2 * (base - one) * sum bs_mod_m) - (qm_min * m))

  let lcm_M_lbound = Z.(upper_bound - lower_bound)

  let _ =
    assert (List.fold_left Z.lcm Z.one (Scalar.order :: moduli) > lcm_M_lbound)

  (* For every mj in M, we need to enforce the equation:
     \sum_i ((B^i mod m) mod mj) * (x_i + y_i - z_i)
       - qm * (m mod mj) - ((qm_min * m) mod mj) = tj * mj

     with the exception of the native modulus p = Scalar.order,
     where we can directly check:
      \sum_i ((B^i mod m) mod p) * (x_i + y_i - z_i)
        - (qm + qm_min) * (m mod p) =_{p} 0

     For the moduli != p, we need to bound the corresponding auxiliary
     variable tj. As before, we will first bound tj in the interval
     [tj_min, tj_max] and then apply a small modification to shift it to
     the interval [0, tj_bound) where tj_bound is the power of 2^15
     immediately above (tj_max - tj_min)
  *)

  let t_bounds =
    List.map
      (fun mj ->
        (* We can establish the following bounds on tj:
           tj_min =
           (- (B-1) * (\sum_i (B^i mod m) mod mj)
            - qm_bound * (m mod mj) - ((qm_min * m) mod mj)) / mj
           tj_max =
           (2 * (B-1) * (\sum_i (B^i mod m) mod mj) - (qm_min * m) mod mj) / mj
        *)
        let qm_min_m_mod_mj = Z.(qm_min * m %! mj) in
        let bs_mod_m_mod_mj = List.map (fun v -> v %! mj) bs_mod_m in
        let sum_bound = Z.((base - one) * sum bs_mod_m_mod_mj) in
        let tj_min =
          Z.(div (neg sum_bound - (qm_bound * (m %! mj)) - qm_min_m_mod_mj) mj)
        in
        let tj_max = Z.(div ((of_int 2 * sum_bound) - qm_min_m_mod_mj) mj) in

        (* We will modify the equation on mj as follows:
           \sum_i ((B^i mod m) mod mj) * (x_i + y_i - z_i)
             - qm * (m mod mj) - ((qm_min * m) mod mj) = (tj + tj_min) * mj

           and bound tj in the interval [0, tj_bound), where tj_bound is the
           smallest power of 2^15 larger than t_max - t_min.
        *)
        let tj_bound =
          Z.(shift_left one (next_multiple_of 15 @@ numbits (tj_max - tj_min)))
        in

        (* Now, assuming tj is restricted to [0, tj_bound), we can bound the
           following amount:
            \sum_i ((B^i mod m) mod mj) * (x_i + y_i - z_i)
              - qm * (m mod mj) - ((qm_min * m) mod mj) - (tj + tj_min) * mj
        *)
        let lower_bound =
          Z.(
            neg sum_bound
            - (qm_bound * (m %! mj))
            - qm_min_m_mod_mj
            - ((tj_bound + tj_min) * mj))
        in
        let upper_bound =
          Z.((of_int 2 * sum_bound) - qm_min_m_mod_mj - (tj_min * mj))
        in

        (* Assert that there will be no wrap-around *)
        assert (Z.(upper_bound - lower_bound < modulus)) ;
        (tj_min, tj_bound))
      moduli

  (* There are as many identities as moduli + 1, as we also have an identity
     on the native modulus *)
  let identity = (q_label, 1 + List.length moduli)

  let index_com = None

  let nb_advs = 0

  let nb_buffers = 3

  let gx_composition = true

  let equations ~q:q_mod_arith ~wires ~wires_g ?precomputed_advice:_ () =
    if Scalar.is_zero q_mod_arith then
      Scalar.zero :: List.map (Fun.const Scalar.zero) moduli
    else if not (Scalar.(is_one) q_mod_arith) then
      failwith "AddMod25519.equations : q_add_mod_25519 must be zero or one."
    else
      (* z = (x + y) mod m
         let n = nb_limbs - 1 and k = |moduli|

          x0 ... xn y0 .. yn qm t1 ... tk
          z0 ... zn
      *)
      let xs = List.init nb_limbs (fun i -> wires.(i)) in
      let ys = List.init nb_limbs (fun i -> wires.(nb_limbs + i)) in
      let zs = List.init nb_limbs (fun i -> wires_g.(i)) in
      let qm = wires.(2 * nb_limbs) in
      let ts = List.mapi (fun i _ -> wires.((2 * nb_limbs) + 1 + i)) moduli in
      let t_infos =
        List.map2 (fun tj (t_min, _) -> Some (tj, t_min)) ts t_bounds
      in
      let sum = List.fold_left Scalar.add Scalar.zero in
      List.map2
        (fun mj t_info ->
          (* \sum_i ((B^i mod m) mod mj) * (x_i + y_i - z_i)
             - qm * (m mod mj) - ((qm_min * m) mod mj) = (tj + tj_min) * mj *)
          let tj, tj_min =
            match t_info with
            | Some (tj, tj_min) -> (tj, tj_min)
            | None -> (Scalar.zero, Z.zero)
          in
          let id_mj =
            let open Scalar in
            sum
              (List.map2
                 (fun bi_mod_m ((xi, yi), zi) ->
                   of_z (bi_mod_m %! mj) * (xi + yi + negate zi))
                 bs_mod_m
                 (List.combine (List.combine xs ys) zs))
            + negate (qm * of_z (modulus %! mj))
            + negate (of_z Z.(qm_min * modulus %! mj))
            + negate ((tj + of_z tj_min) * of_z mj)
          in
          Scalar.(q_mod_arith * id_mj))
        (Scalar.order :: moduli)
        (None :: t_infos)

  let blinds =
    SMap.of_list
    @@ List.init
         ((2 * nb_limbs) + 1 + List.length moduli)
         (fun i -> (wire_name i, if i < nb_limbs then [|1; 1|] else [|1; 0|]))

  let prover_identities ~prefix_common ~prefix ~public:_ ~domain :
      prover_identities =
   fun evaluations ->
    let domain_size = Domain.length domain in
    let tmps, ids = get_buffers ~nb_buffers ~nb_ids:(snd identity) in
    let ({q; wires} : witness) =
      get_evaluations ~q_label ~blinds ~prefix ~prefix_common evaluations
    in
    let q_mod_arith = q in
    let xs = List.init nb_limbs (fun i -> wires.(i)) in
    let ys = List.init nb_limbs (fun i -> wires.(nb_limbs + i)) in
    let qm = wires.(2 * nb_limbs) in
    let ts = List.mapi (fun i _ -> wires.((2 * nb_limbs) + 1 + i)) moduli in
    let t_infos =
      List.map2 (fun tj (t_min, _) -> Some (tj, t_min)) ts t_bounds
    in
    List.mapi
      (fun i (mj, t_info) ->
        (* id_mj :=
           \sum_i ((B^i mod m) mod mj) * (x_i + y_i - z_i)
           - qm * (m mod mj) - ((qm_min * m) mod mj) - (tj + tj_min) * mj *)
        let id_mj_without_sum =
          (* In the case of the native modulus, we can ignore the
             (tj + tj_min) component *)
          let tj, tj_coeff, tj_min =
            match t_info with
            | Some (tj, tj_min) -> ([tj], Scalar.[negate (of_z mj)], tj_min)
            | None -> ([], [], Z.zero)
          in
          Evaluations.linear_c
            ~res:tmps.(0)
            ~evaluations:(qm :: tj)
            ~linear_coeffs:(Scalar.(negate (of_z (m %! mj))) :: tj_coeff)
            ~add_constant:
              Scalar.(negate (of_z Z.((qm_min * m %! mj) + (tj_min * mj))))
            ()
        in
        let id_mj =
          List.fold_left2
            (fun acc bi_mod_m (xi, yi) ->
              (* zi is just xi composed with gX *)
              let zi = xi in
              let xi_plus_yi =
                Evaluations.linear_c ~res:tmps.(1) ~evaluations:[xi; yi] ()
              in
              let xi_plus_yi_minus_zi =
                Evaluations.linear_c
                  ~res:tmps.(2)
                  ~evaluations:[xi_plus_yi; zi]
                  ~linear_coeffs:[one; mone]
                  ~composition_gx:([0; 1], domain_size)
                  ()
              in
              let acc =
                Evaluations.linear_c
                  ~res:tmps.(1)
                  ~evaluations:[acc; xi_plus_yi_minus_zi]
                  ~linear_coeffs:[one; Scalar.of_z @@ (bi_mod_m %! mj)]
                  ()
              in
              Evaluations.copy ~res:tmps.(0) acc)
            id_mj_without_sum
            bs_mod_m
            (List.combine xs ys)
        in
        let identity =
          Evaluations.mul_c ~res:ids.(i) ~evaluations:[q_mod_arith; id_mj] ()
        in
        (prefix @@ q_label ^ "." ^ string_of_int i, identity))
      ((Scalar.order, None) :: List.combine moduli t_infos)
    |> SMap.of_list

  let verifier_identities ~prefix_common ~prefix ~public:_ ~generator:_
      ~size_domain:_ : verifier_identities =
   fun _ answers ->
    let {q; wires; wires_g} =
      get_answers ~q_label ~blinds ~prefix ~prefix_common answers
    in
    List.mapi
      (fun i id -> (prefix @@ q_label ^ "." ^ string_of_int i, id))
      (equations ~q ~wires ~wires_g ())
    |> SMap.of_list

  let polynomials_degree =
    SMap.of_list
      [(wire_name 0, 4); (wire_name 1, 4); (wire_name 2, 4); (q_label, 4)]

  let cs ~q:q_mod_arith ~wires ~wires_g ?precomputed_advice:_ () =
    ignore q_mod_arith ;
    ignore wires ;
    ignore wires_g ;
    failwith "TODO"
end
