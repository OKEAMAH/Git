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
   nb identities : 2
   advice selectors : None
   equations : TODO
*)
module AddMod25519 : Base_sig = struct
  module M = Plompiler.AddMod25519 (L)

  let q_label = "q_mod_add_" ^ M.label

  let ( %! ) n m = Z.div_rem n m |> snd

  let nb_used_wires = (2 * M.nb_limbs) + 1 + List.length M.moduli

  let bs_mod_m = List.init M.nb_limbs (fun i -> Z.pow M.base i %! M.modulus)

  (* There are as many identities as moduli + 1, as we also have an identity
     on the native modulus *)
  let identity = (q_label, 1 + List.length M.moduli)

  let index_com = None

  let nb_advs = 0

  let nb_buffers = 3

  let gx_composition = true

  let equations ~q:q_mod_arith ~wires ~wires_g ?precomputed_advice:_ () =
    if Scalar.is_zero q_mod_arith then
      Scalar.zero :: List.map (Fun.const Scalar.zero) M.moduli
    else if not (Scalar.(is_one) q_mod_arith) then
      failwith "AddMod25519.equations : q_add_mod_25519 must be zero or one."
    else
      (* z = (x + y) mod m
         let n = nb_limbs - 1 and k = |moduli|

          x0 ... xn y0 .. yn qm t1 ... tk
          z0 ... zn
      *)
      let xs = List.init M.nb_limbs (fun i -> wires.(i)) in
      let ys = List.init M.nb_limbs (fun i -> wires.(M.nb_limbs + i)) in
      let zs = List.init M.nb_limbs (fun i -> wires_g.(i)) in
      let qm = wires.(2 * M.nb_limbs) in
      let ts =
        List.mapi (fun i _ -> wires.((2 * M.nb_limbs) + 1 + i)) M.moduli
      in
      let t_infos =
        List.map2 (fun tj (t_min, _) -> Some (tj, t_min)) ts M.ts_bounds_add
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
            + negate (qm * of_z (M.modulus %! mj))
            + negate (of_z Z.(M.qm_min_add * M.modulus %! mj))
            + negate ((tj + of_z tj_min) * of_z mj)
          in
          Scalar.(q_mod_arith * id_mj))
        (Scalar.order :: M.moduli)
        (None :: t_infos)

  let blinds =
    List.init nb_used_wires (fun i ->
        (wire_name i, if i < M.nb_limbs then [|1; 1|] else [|1; 0|]))
    |> SMap.of_list

  let prover_identities ~prefix_common ~prefix ~public:_ ~domain :
      prover_identities =
   fun evaluations ->
    let domain_size = Domain.length domain in
    let tmps, ids = get_buffers ~nb_buffers ~nb_ids:(snd identity) in
    let ({q; wires} : witness) =
      get_evaluations ~q_label ~blinds ~prefix ~prefix_common evaluations
    in
    let q_mod_arith = q in
    let xs = List.init M.nb_limbs (fun i -> wires.(i)) in
    let ys = List.init M.nb_limbs (fun i -> wires.(M.nb_limbs + i)) in
    let qm = wires.(2 * M.nb_limbs) in
    let ts = List.mapi (fun i _ -> wires.((2 * M.nb_limbs) + 1 + i)) M.moduli in
    let t_infos =
      List.map2 (fun tj (t_min, _) -> Some (tj, t_min)) ts M.ts_bounds_add
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
            ~linear_coeffs:(Scalar.(negate (of_z (M.modulus %! mj))) :: tj_coeff)
            ~add_constant:
              Scalar.(
                negate
                  (of_z Z.((M.qm_min_add * M.modulus %! mj) + (tj_min * mj))))
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
      ((Scalar.order, None) :: List.combine M.moduli t_infos)
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
    (q_label, 2) :: List.init nb_used_wires (fun i -> (wire_name i, 2))
    |> SMap.of_list

  let cs ~q:q_mod_arith ~wires ~wires_g ?precomputed_advice:_ () =
    ignore q_mod_arith ;
    ignore wires ;
    ignore wires_g ;
    failwith "TODO"
end
