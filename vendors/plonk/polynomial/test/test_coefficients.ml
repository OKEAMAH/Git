(*****************************************************************************)
(*                                                                           *)
(* Copyright (c) 2020-2021 Danny Willems <be.danny.willems@gmail.com>        *)
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

let rec non_null_int bound =
  let r = Random.int bound in
  if r = 0 then non_null_int bound else r

let rec repeat n f =
  if n <= 0 then
    let f () = () in
    f
  else (
    f () ;
    repeat (n - 1) f)

module Scalar = Bls12_381.Fr
module Domain = Polynomial__Domain.Domain_unsafe
module Poly = Polynomial__Polynomial_c
module Evaluations = Polynomial__Evaluations_c

let test_split_poly () =
  let expected_poly = Poly.generate_random_polynomial 34 in
  let res = Poly.split 15 10 expected_poly in
  let (reconstructed_poly, _) =
    List.fold_left
      (fun (poly, i) poly_part ->
        ( Poly.(
            poly + (of_coefficients [(Scalar.one, Int.mul 10 i)] * poly_part)),
          Int.sub i 1 ))
      (Poly.zero, List.length res - 1)
      (List.rev res)
  in
  assert (Poly.equal reconstructed_poly expected_poly)

let test_degree_zero_is_infinity () = assert (Poly.degree Poly.zero = -1)

let test_degree_of_constants_is_one () =
  assert (Poly.(degree (constant (Scalar.random ()))) = 0)

let test_degree_int_test_vectors () =
  let vectors =
    [
      (Poly.zero, -1);
      (Poly.of_coefficients [(Scalar.one, 0)], 0);
      (Poly.of_coefficients [(Scalar.one, 10)], 10);
    ]
  in
  List.iter
    (fun (p, expected_result) -> assert (Poly.degree p = expected_result))
    vectors

let test_eval_random_point_zero_polynomial () =
  assert (Scalar.is_zero (Poly.evaluate Poly.zero (Scalar.random ())))

let test_eval_at_zero_of_zero_polynomial () =
  assert (Scalar.is_zero (Poly.evaluate Poly.zero Scalar.zero))

let test_eval_at_zero_point_of_random_constant_polynomial () =
  let constant = Scalar.random () in
  assert (
    Scalar.eq (Poly.evaluate (Poly.constant constant) Scalar.zero) constant)

let test_eval_random_point_constant_polynomial () =
  let constant = Scalar.random () in
  assert (
    Scalar.eq
      (Poly.evaluate (Poly.constant constant) (Scalar.random ()))
      constant)

let test_eval_x_to_random_point () =
  let p = Scalar.random () in
  assert (Scalar.eq (Poly.evaluate (Poly.of_coefficients [(Scalar.one, 1)]) p) p)

let test_vectors1 () =
  let rec generate_non_null () =
    let r = Scalar.random () in
    if Scalar.is_zero r then generate_non_null () else r
  in
  let x = generate_non_null () in
  let zero = Scalar.zero in
  let test_vectors =
    [
      (Poly.zero, [Scalar.zero]);
      (Poly.constant x, [x]);
      (Poly.of_coefficients [(x, 2)], [x; zero; zero]);
      (Poly.of_coefficients [(x, 1)], [x; zero]);
      (Poly.of_coefficients [(x, 3); (x, 1)], [x; zero; x; zero]);
      (Poly.of_coefficients [(x, 4); (x, 1)], [x; zero; zero; x; zero]);
      ( Poly.of_coefficients [(x, 17); (x, 14); (x, 3); (x, 1); (x, 0)],
        [
          x;
          zero;
          zero;
          x;
          zero;
          zero;
          zero;
          zero;
          zero;
          zero;
          zero;
          zero;
          zero;
          zero;
          x;
          zero;
          x;
          x;
        ] );
    ]
  in
  List.iter
    (fun (v, expected_result) ->
      let r = Poly.to_dense_coefficients v in
      assert (
        Array.for_all2 Scalar.eq (Array.of_list (List.rev expected_result)) r))
    test_vectors

let test_vectors2 () =
  let rec generate_non_null () =
    let r = Scalar.random () in
    if Scalar.is_zero r then generate_non_null () else r
  in
  let x = generate_non_null () in
  let zero = Scalar.zero in
  let test_vectors =
    [
      (Poly.zero, [(Scalar.zero, 0)]);
      (Poly.constant x, [(x, 0)]);
      (Poly.of_coefficients [(x, 2)], [(x, 2); (zero, 1); (zero, 0)]);
      (Poly.of_coefficients [(x, 1)], [(x, 1); (zero, 0)]);
      ( Poly.of_coefficients [(x, 3); (x, 1)],
        [(x, 3); (zero, 2); (x, 1); (zero, 0)] );
      ( Poly.of_coefficients [(x, 4); (x, 1)],
        [(x, 4); (zero, 3); (zero, 2); (x, 1); (zero, 0)] );
      ( Poly.of_coefficients [(x, 17); (x, 14); (x, 3); (x, 1); (x, 0)],
        [
          (x, 17);
          (zero, 16);
          (zero, 15);
          (x, 14);
          (zero, 13);
          (zero, 12);
          (zero, 11);
          (zero, 10);
          (zero, 9);
          (zero, 8);
          (zero, 7);
          (zero, 6);
          (zero, 5);
          (zero, 4);
          (x, 3);
          (zero, 2);
          (x, 1);
          (x, 0);
        ] );
    ]
  in
  List.iter
    (fun (v, expected_result) ->
      let r = Poly.to_dense_coefficients v |> Array.to_list in
      let r = List.mapi (fun i e -> (e, i)) r in
      assert (
        List.for_all2
          (fun (e1, p1) (e2, p2) -> Scalar.eq e1 e2 && p1 = p2)
          (List.rev expected_result)
          r))
    test_vectors

let test_multiply_by_zero_is_zero () =
  let r = Poly.generate_random_polynomial (Random.int 1000) in
  assert (Poly.equal (Poly.mul r Poly.zero) Poly.zero) ;
  assert (Poly.equal (Poly.mul Poly.zero r) Poly.zero)

let test_communitativity () =
  let p = Poly.generate_random_polynomial (Random.int 30) in
  let q = Poly.generate_random_polynomial (Random.int 30) in
  assert (Poly.equal (Poly.mul p q) (Poly.mul q p))

let test_distributivity () =
  let a = Scalar.random () in
  let b = Scalar.random () in
  let p = Poly.generate_random_polynomial (Random.int 30) in
  let q = Poly.generate_random_polynomial (Random.int 30) in
  assert (
    Poly.equal
      (Poly.mul (Poly.mul_by_scalar a p) (Poly.mul_by_scalar b q))
      (Poly.mul (Poly.mul_by_scalar a q) (Poly.mul_by_scalar b p))) ;
  assert (
    Poly.equal
      (Poly.mul (Poly.mul_by_scalar Scalar.(a * b) p) q)
      (Poly.mul (Poly.mul_by_scalar Scalar.(a * b) q) p)) ;
  assert (
    Poly.equal
      (Poly.mul p (Poly.mul_by_scalar Scalar.(a * b) q))
      (Poly.mul q (Poly.mul_by_scalar Scalar.(a * b) p))) ;
  assert (
    Poly.equal
      (Poly.mul (Poly.mul_by_scalar a p) (Poly.mul_by_scalar b q))
      Poly.(mul_by_scalar Scalar.(a * b) (mul p q)))

let test_interpolation_fft_with_only_roots ~power () =
  let domain = Domain.build ~log:Z.(log2up (of_int power)) in
  (* only roots *)
  let evaluation_points = Array.init power (fun _i -> Scalar.zero) in
  let results = Evaluations.interpolation_fft2 domain evaluation_points in
  assert (Poly.is_zero results)

let test_evaluation_fft_zero ~power () =
  let domain = Domain.build ~log:Z.(log2up (of_int power)) in
  let polynomial = Poly.zero in
  let results = Evaluations.evaluation_fft2 domain polynomial in
  let expected_results = Array.init power (fun _ -> Scalar.zero) in
  if not (Array.for_all2 Scalar.eq results expected_results) then
    let expected_values =
      String.concat
        "; "
        (List.map Scalar.to_string (expected_results |> Array.to_list))
    in
    let values =
      String.concat "; " (List.map Scalar.to_string (results |> Array.to_list))
    in
    Alcotest.failf "Expected values [%s]\nComputed [%s]" expected_values values

let test_evaluation_fft_constant ~power () =
  let domain = Domain.build ~log:Z.(log2up (of_int power)) in
  let s = Scalar.random () in
  let polynomial = Poly.constant s in
  let results = Evaluations.evaluation_fft2 domain polynomial in
  let expected_results = Array.init power (fun _ -> s) in
  if not (Array.for_all2 Scalar.eq results expected_results) then
    let expected_values =
      String.concat
        "; "
        (List.map Scalar.to_string (expected_results |> Array.to_list))
    in
    let values =
      String.concat "; " (List.map Scalar.to_string (results |> Array.to_list))
    in
    Alcotest.failf "Expected values [%s]\nComputed [%s]" expected_values values

(*   let test_evaluation_fft_random_values_with_larger_polynomial ~generator ~power *)
(*       () = *)
(*     let domain = *)
(*       Polynomial.generate_evaluation_domain (module Scalar) power generator *)
(*     in *)
(*     let polynomial = Poly.generate_random_polynomial (power + Random.int 100) in *)
(*     let expected_results = *)
(*       List.map (fun x -> Poly.evaluate polynomial x) (Array.to_list domain) *)
(*     in *)
(*     let results = Poly.evaluation_fft domain polynomial in *)
(*     if not (List.for_all2 Scalar.eq results expected_results) then *)
(*       let expected_values = *)
(*         String.concat "; " (List.map Scalar.to_string expected_results) *)
(*       in *)
(*       let values = String.concat "; " (List.map Scalar.to_string results) in *)
(*       Alcotest.failf *)
(*         "Expected values [%s]\nComputed [%s]" *)
(*         expected_values *)
(*         values *)

let test_evaluation_fft_random_values_with_smaller_polynomial ~power () =
  let domain = Domain.build ~log:Z.(log2up (of_int power)) in
  let polynomial = Poly.generate_random_polynomial (Random.int (power - 1)) in
  let expected_results =
    Array.map (Poly.evaluate polynomial) (Domain.to_array domain)
  in
  let results = Evaluations.evaluation_fft2 domain polynomial in
  if not (Array.for_all2 Scalar.eq results expected_results) then
    let expected_values =
      String.concat
        "; "
        (List.map Scalar.to_string (expected_results |> Array.to_list))
    in
    let values =
      String.concat "; " (List.map Scalar.to_string (results |> Array.to_list))
    in
    Alcotest.failf "Expected values [%s]\nComputed [%s]" expected_values values

let test_multiply_constant_by_scalar_zero_is_zero () =
  let p1 = Poly.constant (Scalar.random ()) in
  assert (Poly.is_zero (Poly.mul_by_scalar Scalar.zero p1))

let test_multiply_degree_one_by_scalar_zero_is_zero () =
  let p1 = Poly.of_coefficients [(Scalar.of_string "1", 1)] in
  assert (Poly.is_zero (Poly.mul_by_scalar Scalar.zero p1))

let test_property_of_twice_opposite () =
  let p1 = Poly.of_coefficients [(Scalar.of_string "10", 1)] in
  assert (Poly.equal (Poly.opposite (Poly.opposite p1)) p1)

let test_property_opposite_of_constant () =
  let random = Scalar.random () in
  assert (
    Poly.equal
      (Poly.opposite (Poly.constant random))
      (Poly.constant (Scalar.negate random)))

let test_property_opposite_of_zero () =
  assert (Poly.(Poly.opposite Poly.zero = Poly.zero))

let tests =
  Alcotest.
    [
      test_case "split poly" `Quick test_split_poly;
      test_case "degree of zero is infinity" `Quick test_degree_zero_is_infinity;
      test_case "degree of constant is one" `Quick test_degree_zero_is_infinity;
      test_case "degree int test vectors" `Quick test_degree_int_test_vectors;
      test_case
        "evaluation at any point of the zero polynomial"
        `Quick
        (repeat 100 test_eval_random_point_zero_polynomial);
      test_case
        "evaluation at any point of a random constant polynomial"
        `Quick
        (repeat 100 test_eval_random_point_constant_polynomial);
      test_case
        "evaluation at zero of a random constant polynomial"
        `Quick
        (repeat 100 test_eval_at_zero_point_of_random_constant_polynomial);
      test_case
        "evaluation at zero of the zero polynomial"
        `Quick
        (repeat 100 test_eval_at_zero_of_zero_polynomial);
      test_case
        "evaluation at any point of the polynomial X"
        `Quick
        (repeat 100 test_eval_x_to_random_point);
      test_case "test vectors" `Quick (repeat 10 test_vectors1);
      test_case "test vectors" `Quick (repeat 10 test_vectors2);
      test_case
        "test properties nullifier 0 * P = P * 0 = 0"
        `Quick
        (repeat 10 test_multiply_by_zero_is_zero);
      test_case
        "test properties commutativity p * q = p * q"
        `Quick
        (repeat 10 test_communitativity);
      test_case
        "test properties distributivity and communtativity a p * b q = (a * b) \
         (p * q) = (b p) * (a q) = p * (a * b) q"
        `Quick
        (repeat 10 test_distributivity);
      test_case
        "test interpolation with only roots"
        `Quick
        (repeat 10 (test_interpolation_fft_with_only_roots ~power:32));
      test_case
        "test evaluation with zero polynomial"
        `Quick
        (test_evaluation_fft_zero ~power:1024);
      test_case
        "test evaluation with smaller polynomial"
        `Quick
        (repeat
           10
           (test_evaluation_fft_random_values_with_smaller_polynomial
              ~power:1024));
      (*       test_case *)
      (*         "test evaluation with larger polynomial" *)
      (*         `Quick *)
      (*         (repeat *)
      (*            10 *)
      (*            (test_evaluation_fft_random_values_with_larger_polynomial *)
      (*               ~generator *)
      (*               ~power)); *)
      test_case
        "test multiply constant by scalar zero is zero"
        `Quick
        test_multiply_constant_by_scalar_zero_is_zero;
      test_case
        "test multiply degree one by scalar zero is zero"
        `Quick
        test_multiply_degree_one_by_scalar_zero_is_zero;
      test_case
        "test property opposite twice"
        `Quick
        test_property_of_twice_opposite;
      test_case
        "test property opposite of constant"
        `Quick
        test_property_opposite_of_constant;
      test_case
        "test property opposite of zero"
        `Quick
        test_property_opposite_of_zero;
    ]
