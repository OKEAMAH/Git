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

module Fr = Bls12_381.Fr
module Fr_generation = Tezos_bls12_381_polynomial_internal__Fr_carray
module Poly = Polynomial.MakeUnivariate (Fr)

module Domain = Tezos_bls12_381_polynomial_internal__Domain.Domain_unsafe

module Poly_c = Tezos_bls12_381_polynomial_internal__Polynomial.Polynomial_impl

let p_of_c : Poly_c.t -> Poly.t =
 fun poly -> Poly_c.to_sparse_coefficients poly |> Poly.of_coefficients

let test_copy_polynomial () =
  let poly = Poly_c.generate_biased_random_polynomial (Random.int 100) in
  assert (Poly_c.equal poly (Poly_c.copy poly))

let test_erase () =
  let poly = Poly_c.generate_biased_random_polynomial (Random.int 100) in
  Poly_c.erase poly ;
  assert (Poly_c.equal poly Poly_c.zero)

let test_get_zero () =
  let p = Poly_c.zero in
  assert (Fr.(Poly_c.get p 0 = zero)) ;
  Helpers.must_fail (fun () -> ignore @@ Poly_c.get p (-1)) ;
  Helpers.must_fail (fun () -> ignore @@ Poly_c.get p 1)

let test_get_one () =
  let p = Poly_c.one in
  assert (Fr.(Poly_c.get p 0 = one)) ;
  Helpers.must_fail (fun () -> ignore @@ Poly_c.get p (-1)) ;
  Helpers.must_fail (fun () -> ignore @@ Poly_c.get p 1)

let test_get_random () =
  let module Poly_c =
    Tezos_bls12_381_polynomial_internal__Polynomial.Polynomial_impl
  in
  let module C_array = Tezos_bls12_381_polynomial_internal__Fr_carray in
  let degree = 1 + Random.int 100 in
  let p = Poly_c.of_coefficients [(Fr.one, degree)] in
  assert (Poly_c.length p = degree + 1) ;
  Helpers.repeat 10 (fun () ->
      assert (Fr.eq (Poly_c.get p (Random.int (Poly_c.length p - 1))) Fr.zero)) ;
  Helpers.(
    repeat 10 (fun () ->
        let i = Random.int 10 in
        must_fail (fun () -> ignore @@ Poly_c.get p (-i - 1)) ;
        must_fail (fun () -> ignore @@ Poly_c.get p (Poly_c.length p + i))))

let test_one () =
  let p = Poly_c.one in
  let expected = Poly.one in
  assert (Poly.equal (p_of_c p) expected)

let test_degree () =
  let p1 = Poly_c.generate_biased_random_polynomial (Random.int 100) in
  assert (Poly_c.degree p1 = Poly.degree_int (p_of_c p1))

let test_add () =
  let p1 = Poly_c.generate_biased_random_polynomial (Random.int 100) in
  let p2 = Poly_c.generate_biased_random_polynomial (Random.int 100) in
  let res = Poly_c.add p1 p2 in
  let expected_res = Poly.add (p_of_c p1) (p_of_c p2) in
  assert (Poly.equal (p_of_c res) expected_res)

let test_add_inplace () =
  let p1 = Poly_c.generate_biased_random_polynomial (Random.int 100) in
  let p2 = Poly_c.generate_biased_random_polynomial (Random.int 100) in
  let expected_res = Poly.add (p_of_c p1) (p_of_c p2) in
  let res = Poly_c.(allocate (max (length p1) (length p2))) in
  Poly_c.add_inplace res p1 p2 ;
  assert (Poly.equal (p_of_c res) expected_res)

let test_sub () =
  let p1 = Poly_c.generate_biased_random_polynomial (Random.int 100) in
  let p2 = Poly_c.generate_biased_random_polynomial (Random.int 100) in
  let res = Poly_c.sub p1 p2 in
  let expected_res = Poly.sub (p_of_c p1) (p_of_c p2) in
  assert (Poly.equal (p_of_c res) expected_res)

let test_sub_inplace () =
  let p1 = Poly_c.generate_biased_random_polynomial (Random.int 100) in
  let p2 = Poly_c.generate_biased_random_polynomial (Random.int 100) in
  let expected_res = Poly.sub (p_of_c p1) (p_of_c p2) in
  let res = Poly_c.(allocate (max (length p1) (length p2))) in
  Poly_c.sub_inplace res p1 p2 ;
  assert (Poly.equal (p_of_c res) expected_res)

let test_mul () =
  let p1 = Poly_c.generate_biased_random_polynomial (Random.int 100) in
  let p2 = Poly_c.generate_biased_random_polynomial (Random.int 100) in
  let res = Poly_c.mul p1 p2 in
  let expected_res = Poly.polynomial_multiplication (p_of_c p1) (p_of_c p2) in
  assert (Poly.equal (p_of_c res) expected_res) ;
  let dres = Poly_c.degree res in
  let d1 = Poly_c.degree p1 in
  let d2 = Poly_c.degree p2 in
  if d1 = -1 || d2 = -1 then assert (dres = -1) else assert (dres = d1 + d2)

let test_opposite () =
  let p = Poly_c.generate_biased_random_polynomial (Random.int 100) in
  let res = Poly_c.opposite p in
  let expected_res = Poly.opposite (p_of_c p) in
  assert (Poly.equal (p_of_c res) expected_res)

let test_opposite_inplace () =
  let p = Poly_c.generate_biased_random_polynomial (Random.int 100) in
  let expected_res = Poly.opposite (p_of_c p) in
  Poly_c.opposite_inplace p ;
  assert (Poly.equal (p_of_c p) expected_res)

let test_mul_by_scalar () =
  let p = Poly_c.generate_biased_random_polynomial 100 in
  let s = Fr.random () in
  let res = Poly_c.mul_by_scalar s p in
  let expected_res = Poly.mult_by_scalar s (p_of_c p) in
  assert (Poly.equal (p_of_c res) expected_res)

let test_mul_by_scalar_inplace () =
  let p = Poly_c.generate_biased_random_polynomial 100 in
  let s = Fr.random () in
  let expected_res = Poly.mult_by_scalar s (p_of_c p) in
  Poly_c.mul_by_scalar_inplace p s p ;
  assert (Poly.equal (p_of_c p) expected_res)

let test_is_zero () =
  let size = Random.int 100 in
  let poly_zero =
    Poly_c.of_coefficients (List.init size (fun i -> (Fr.copy Fr.zero, i)))
  in
  assert (Poly_c.is_zero poly_zero)

let test_evaluate () =
  let p = Poly_c.generate_biased_random_polynomial 10 in
  let s = Fr.random () in
  let expected_res = Poly.evaluation (p_of_c p) s in
  let res = Poly_c.evaluate p s in
  assert (Fr.eq res expected_res)

(* division by (X^n + c) *)
let test_division_xn_plus_const poly n const =
  let poly_caml = p_of_c poly in
  let poly_xn_plus_const_caml =
    Poly.of_coefficients [(Fr.one, n); (const, 0)]
  in
  let res_q, res_r = Poly_c.division_xn poly n const in
  let res_q_caml = p_of_c res_q in
  let res_r_caml = p_of_c res_r in
  let expected_quotient, expected_reminder =
    Poly.euclidian_division_opt poly_caml poly_xn_plus_const_caml |> Option.get
  in
  assert (Poly.equal res_q_caml expected_quotient) ;
  assert (Poly.equal res_r_caml expected_reminder)

(* exact division by (X^n + c) *)
let test_division_exact_xn_plus_const poly_non_divisible n const =
  let poly_non_divisible_caml = p_of_c poly_non_divisible in
  let poly_xn_plus_const_caml =
    Poly.of_coefficients [(Fr.one, n); (const, 0)]
  in
  let poly_divisible_caml =
    Poly.(poly_non_divisible_caml * poly_xn_plus_const_caml)
  in
  let poly_divisible =
    Poly_c.of_coefficients (Poly.get_list_coefficients poly_divisible_caml)
  in
  let res_q, res_r = Poly_c.division_xn poly_divisible n const in
  let res_q_caml = p_of_c res_q in
  let res_r_caml = p_of_c res_r in
  let expected_quotient, expected_reminder =
    Poly.euclidian_division_opt poly_divisible_caml poly_xn_plus_const_caml
    |> Option.get
  in
  let poly_xn_plus_const = Poly_c.(of_coefficients [(Fr.one, n); (const, 0)]) in
  assert (Poly.equal res_q_caml expected_quotient) ;
  assert (Poly.equal res_r_caml expected_reminder) ;
  assert (Poly.equal Poly.zero expected_reminder) ;
  assert (Poly_c.(mul_xn res_q n const = poly_divisible)) ;
  assert (Poly_c.(mul res_q poly_xn_plus_const = poly_divisible))

(* division by (X - z) *)
let test_division_x_z () =
  let poly_non_divisible =
    let rec generate () =
      let p = Poly_c.generate_biased_random_polynomial 100 in
      if Poly_c.degree p > 0 then p else generate ()
    in
    generate ()
  in
  let z = Fr.random () in
  let minus_z = Fr.negate z in
  test_division_exact_xn_plus_const poly_non_divisible 1 minus_z ;
  test_division_xn_plus_const poly_non_divisible 1 minus_z

(* division by (X^n - 1), degree a random poly >= 2 * n *)
let test_division_xn_minus_one () =
  let n = 10 in
  let poly_non_divisible =
    let rec generate () =
      let p = Poly_c.generate_biased_random_polynomial 100 in
      if Poly_c.degree p >= 2 * n then p else generate ()
    in
    generate ()
  in
  let minus_one = Fr.(negate one) in
  test_division_exact_xn_plus_const poly_non_divisible n minus_one ;
  test_division_xn_plus_const poly_non_divisible n minus_one

(* division by (X^n - 1), degree a random poly = 2 * n *)
let test_division_xn_minus_one_limit_case () =
  (* We test the limit case in which the size of the polynomial is equal to 2*n
     ie. the degree is equal to 2*n. *)
  let n = 16 in
  let poly_non_divisible = Poly_c.of_coefficients [(Fr.random (), n - 1)] in
  let poly_non_divisible =
    Poly_c.add
      poly_non_divisible
      (Poly_c.generate_biased_random_polynomial (n - 2))
  in
  let minus_one = Fr.(negate one) in
  test_division_exact_xn_plus_const poly_non_divisible n minus_one ;
  test_division_xn_plus_const poly_non_divisible n minus_one

(* division by (X^n - 1), degree a random poly >= n and < 2 * n *)
let test_division_xn_minus_one_lt_2n () =
  let n = 10 in
  let poly_non_divisible =
    let rec generate () =
      let p = Poly_c.generate_biased_random_polynomial 20 in
      let poly_degree = Poly_c.degree p in
      if n <= poly_degree && poly_degree < 2 * n then p else generate ()
    in
    generate ()
  in
  let minus_one = Fr.(negate one) in
  test_division_exact_xn_plus_const poly_non_divisible n minus_one ;
  test_division_xn_plus_const poly_non_divisible n minus_one

(* division by (X^n + 1), degree a random poly >= 2 * n *)
let test_division_xn_plus_one () =
  let n = 10 in
  let poly_non_divisible =
    let rec generate () =
      let p = Poly_c.generate_biased_random_polynomial 100 in
      if Poly_c.degree p >= 2 * n then p else generate ()
    in
    generate ()
  in
  test_division_exact_xn_plus_const poly_non_divisible n Fr.one ;
  test_division_xn_plus_const poly_non_divisible n Fr.one

(* division by (X^n + 1), degree a random poly >= n and < 2 * n *)
let test_division_xn_plus_one_lt_2n () =
  let n = 10 in
  let poly_non_divisible =
    let rec generate () =
      let p = Poly_c.generate_biased_random_polynomial 20 in
      let poly_degree = Poly_c.degree p in
      if n <= poly_degree && poly_degree < 2 * n then p else generate ()
    in
    generate ()
  in
  test_division_exact_xn_plus_const poly_non_divisible n Fr.one ;
  test_division_xn_plus_const poly_non_divisible n Fr.one

(* division by (X^n + c), degree a random poly >= 2 * n *)
let test_division_xn_plus_c () =
  let n = 10 in
  let poly_non_divisible =
    let rec generate () =
      let p = Poly_c.generate_biased_random_polynomial 100 in
      if Poly_c.degree p >= 2 * n then p else generate ()
    in
    generate ()
  in
  let c = Fr.random () in
  test_division_exact_xn_plus_const poly_non_divisible n c ;
  test_division_xn_plus_const poly_non_divisible n c

(* division by (X^n + c), degree a random poly >= n and < 2 * n *)
let test_division_xn_plus_c_lt_2n () =
  let n = 10 in
  let poly_non_divisible =
    let rec generate () =
      let p = Poly_c.generate_biased_random_polynomial 20 in
      let poly_degree = Poly_c.degree p in
      if n <= poly_degree && poly_degree < 2 * n then p else generate ()
    in
    generate ()
  in
  let c = Fr.random () in
  test_division_exact_xn_plus_const poly_non_divisible n c ;
  test_division_xn_plus_const poly_non_divisible n c

let test_linear () =
  let n = 4 in
  let polys =
    List.init n (fun i ->
        if i = 2 then Poly_c.zero
        else Poly_c.generate_biased_random_polynomial (Random.int 100))
  in
  let coeffs = List.init n (fun _i -> Fr.random ()) in
  let res = Poly_c.linear polys coeffs in
  let expected_res =
    List.fold_left2
      (fun acc coeff poly ->
        Poly.add acc @@ Poly.mult_by_scalar coeff (p_of_c poly))
      Poly.zero
      coeffs
      polys
  in
  assert (Poly.equal (p_of_c res) expected_res)

let test_linear_with_powers () =
  let n = 4 in
  let polys =
    List.init n (fun i ->
        if i = 2 then Poly_c.zero
        else Poly_c.generate_biased_random_polynomial (Random.int 100))
  in
  let coeff = Fr.random () in
  let coeffs = Fr_generation.powers n coeff |> Array.to_list in
  let res1 = Poly_c.linear polys coeffs in
  let res2 = Poly_c.linear_with_powers polys coeff in
  let expected_res =
    List.fold_left2
      (fun acc coeff poly ->
        Poly.add acc @@ Poly.mult_by_scalar coeff (p_of_c poly))
      Poly.zero
      coeffs
      polys
  in
  assert (Poly.equal (p_of_c res1) expected_res) ;
  assert (Poly.equal (p_of_c res2) expected_res)

let test_linear_with_powers_equal_length () =
  let n = 4 in
  let p =
    let rec generate () =
      let p = Poly_c.generate_biased_random_polynomial 100 in
      if Poly_c.degree p > 10 then p else generate ()
    in
    generate ()
  in
  let polys =
    List.init n (fun _ ->
        Poly_c.add p (Poly_c.generate_biased_random_polynomial 10))
  in
  let coeff = Fr.random () in
  let coeffs = Fr_generation.powers n coeff |> Array.to_list in
  let res = Poly_c.linear_with_powers polys coeff in
  let expected_res =
    List.fold_left2
      (fun acc coeff poly ->
        Poly.add acc @@ Poly.mult_by_scalar coeff (p_of_c poly))
      Poly.zero
      coeffs
      polys
  in
  assert (Poly.equal (p_of_c res) expected_res)

let test_of_sparse_coefficients () =
  let test_vectors =
    [
      [|(Fr.random (), 0)|];
      (* FIXME: repr for zero polynomial *)
      (* [|(Fr.(copy zero), 0)|] *)
      [|(Fr.random (), 0); (Fr.(copy one), 1)|];
      Array.init (1 + Random.int 100) (fun i -> (Fr.random (), i));
      (* with zero coefficients somewhere *)
      [|(Fr.random (), 1)|];
      (let n = 1 + Random.int 100 in
       Array.init n (fun i -> (Fr.random (), (i * 100) + Random.int 100)));
      (* Not in order *)
      [|(Fr.random (), 1); (Fr.random (), 0)|];
      (* random polynomial where we shuffle randomly the coefficients *)
      (let n = 1 + Random.int 100 in
       let p =
         Array.init n (fun i -> (Fr.random (), (i * 100) + Random.int 100))
       in
       Array.fast_sort (fun _ _ -> if Random.bool () then 1 else -1) p ;
       p);
    ]
  in
  List.iter
    (fun coefficients ->
      let polynomial_c = Poly_c.of_coefficients (Array.to_list coefficients) in
      let polynomial = Poly_c.to_sparse_coefficients polynomial_c in
      Array.fast_sort (fun (_, i1) (_, i2) -> Int.compare i1 i2) coefficients ;
      List.iter2
        (fun (x1, i1) (x2, i2) ->
          if not (Fr.eq x1 x2 && i1 = i2) then
            Alcotest.failf
              "Expected output (%s, %d), computed (%s, %d)"
              (Fr.to_string x1)
              i1
              (Fr.to_string x2)
              i2)
        (Array.to_list coefficients)
        polynomial)
    test_vectors

let test_of_dense () =
  let array = Array.init 10 (fun _ -> Fr.random ()) in
  let array_res = Poly_c.of_dense array |> Poly_c.to_dense_coefficients in
  assert (Array.for_all2 Fr.eq array array_res)

let test_of_carray_does_not_allocate_a_full_new_carray () =
  let n = 1 + Random.int 1_000 in
  let array = Array.init n (fun _ -> Fr.random ()) in
  let carray = Tezos_bls12_381_polynomial_internal__Fr_carray.of_array array in
  let polynomial =
    Tezos_bls12_381_polynomial_internal__Polynomial.Polynomial_unsafe.of_carray
      carray
  in
  let two = Fr.of_string "2" in
  Tezos_bls12_381_polynomial_internal__Polynomial.mul_by_scalar_inplace
    polynomial
    two
    polynomial ;
  let poly_values =
    Tezos_bls12_381_polynomial_internal__Polynomial.to_dense_coefficients
      polynomial
  in
  let carray_values =
    Tezos_bls12_381_polynomial_internal__Fr_carray.to_array carray
  in
  assert (Array.for_all2 Fr.eq poly_values carray_values)

let tests =
  let repetitions = 100 in
  List.map
    (fun (name, f) ->
      Alcotest.test_case name `Quick (fun () -> Helpers.repeat repetitions f))
    [
      ("build_erase", test_erase);
      ("get_sparse_coefficients", test_of_sparse_coefficients);
      ("copy", test_copy_polynomial);
      ("get_zero", test_get_zero);
      ("get_one", test_get_one);
      ("get_random", test_get_random);
      ("one", test_one);
      ("degree", test_degree);
      ("add", test_add);
      ("add_inplace", test_add_inplace);
      ("sub", test_sub);
      ("sub_inplace", test_sub_inplace);
      ("mul", test_mul);
      ("opposite", test_opposite);
      ("opposite_inplace", test_opposite_inplace);
      ("mul_by_scalar", test_mul_by_scalar);
      ("mul_by_scalar_inplace", test_mul_by_scalar_inplace);
      ("is_zero", test_is_zero);
      ("evaluate", test_evaluate);
      ("division_x_z", test_division_x_z);
      ("division_xn_minus_one", test_division_xn_minus_one);
      ("division_xn_minus_one_limit_case", test_division_xn_minus_one_limit_case);
      ("division_xn_minus_one_lt_2n", test_division_xn_minus_one_lt_2n);
      ("division_xn_plus_one", test_division_xn_plus_one);
      ("division_xn_plus_one_lt_2n", test_division_xn_plus_one_lt_2n);
      ("division_xn_plus_c", test_division_xn_plus_c);
      ("division_xn_plus_c_lt_2n", test_division_xn_plus_c_lt_2n);
      ("test_linear", test_linear);
      ("test_linear_with_powers", test_linear_with_powers);
      ( "test_linear_with_powers_equal_length",
        test_linear_with_powers_equal_length );
      ("of_dense", test_of_dense);
      ( "of_carray does not copy the carray",
        test_of_carray_does_not_allocate_a_full_new_carray );
    ]
