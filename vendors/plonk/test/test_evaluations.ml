module Fr = Bls12_381.Fr
module SMap = Plonk.SMap
module Domain = Polynomial.Domain
module P = Polynomial.Polynomial
module Eval = Plonk.Evaluations_map.Make (Polynomial.Evaluations)
module Fr_gen = Polynomial__Fr_generation.Make (Fr)
open Eval

let test_linear () =
  let p_1 = P.generate_random_polynomial 10 in
  let p_2 = P.generate_random_polynomial 10 in
  let domain = Domain.build ~log:6 in
  let eval1 = evaluation_fft domain p_1 in
  let eval2 = evaluation_fft domain p_2 in
  let (cst, linear_coeff_1, linear_coeff_2) =
    (Fr.random (), Fr.random (), Fr.random ())
  in
  let p_1_comp =
    let caml = P.to_dense_coefficients p_1 in
    let pow_g = Fr_gen.powers (Array.length caml) (Domain.get domain 1) in
    Array.map2 Fr.mul caml pow_g |> P.of_dense
  in
  let expected_res =
    P.(
      mul_by_scalar linear_coeff_1 p_1_comp
      + mul_by_scalar linear_coeff_2 p_2
      + mul_by_scalar cst P.one)
  in
  let evaluations = SMap.of_list [("1", eval1); ("2", eval2)] in
  let evaluations =
    linear_update_map
      ~evaluations
      ~poly_names:["1"; "2"]
      ~add_constant:cst
      ~linear_coeffs:[linear_coeff_1; linear_coeff_2]
      ~composition_gx:([1; 0], 64)
      ~name_result:"res"
      ()
  in
  let res = SMap.find "res" evaluations |> interpolation_fft domain in
  assert (P.equal res expected_res)

let test_mul () =
  let p_1 = P.generate_random_polynomial 10 in
  let p_2 = P.generate_random_polynomial 10 in
  let domain = Domain.build ~log:6 in
  let eval1 = evaluation_fft domain p_1 in
  let eval2 = evaluation_fft domain p_2 in
  let p_2_comp =
    let caml = P.to_dense_coefficients p_2 in
    let pow_g = Fr_gen.powers (Array.length caml) (Domain.get domain 1) in
    Array.map2 Fr.mul caml pow_g |> P.of_dense
  in
  let evaluations = SMap.of_list [("1", eval1); ("2", eval2)] in
  let evaluations =
    mul_update_map
      ~evaluations
      ~poly_names:["1"; "2"]
      ~composition_gx:([0; 1], 64)
      ~name_result:"res"
      ()
  in
  let expected_res = P.mul p_1 p_2_comp in
  let res = SMap.find "res" evaluations |> interpolation_fft domain in
  assert (P.equal res expected_res)

let tests =
  [
    Alcotest.test_case "test_linear" `Quick test_linear;
    Alcotest.test_case "test_mul" `Quick test_mul;
  ]
