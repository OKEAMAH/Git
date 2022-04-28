(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2020 Nomadic Labs. <contact@nomadic-labs.com>               *)
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

open Polynomial.Multivariate
module Scalar = Bls12_381.Fr

module type CONFIG = sig
  module K : Ff_sig.PRIME

  val name : string

  val support : variable list

  val run_qty : int

  val eq : K.t -> K.t -> bool
end

module Q_config : CONFIG = struct
  module K = Scalar

  let name = "Q"

  let support = ["x"; "y"]

  let run_qty = 2000

  (* let equal {Q.num = a_num; den = a_den} {Q.num = b_num; den = b_den} =
     Z.(equal (a_num * b_den) (b_num * a_den))
  *)
  let eq = Scalar.eq
end

module TestEnvironment (Conf : CONFIG) = struct
  module K = Conf.K

  open MultiPoly (K) (Polynomial.Univariate.Make (K))

  let support = Conf.support

  let rec repeat n f () =
    if n < 0 then ()
    else
      let t = Sys.time () in
      f () ;
      Format.printf "Time: %fs\n========\n" (Sys.time () -. t) ;
      repeat (n - 1) f ()

  let many = repeat Conf.run_qty

  let t_q =
    let pp_print fmt x = Format.pp_print_string fmt (K.to_string x) in
    Alcotest.testable pp_print Conf.eq

  (** Monomials *)
  module MonomialTests = struct
    open Monomial
    open MonomialOperators

    let t_mono = Alcotest.testable pp equal

    let x = singleton "x"

    let rec m_of_binds = function
      | [] -> StringMap.empty
      | (v, exp) :: t -> StringMap.add v exp (m_of_binds t)

    let m1 = m_of_binds [("x", 4); ("y", 2); ("z", 1)]

    let m2 = m_of_binds [("x", 2); ("y", 2)]

    let m12 = m_of_binds [("x", 6); ("y", 4); ("z", 1)]

    let rec random_m max_exp () =
      let rec aux = function
        | [] -> []
        | h :: t ->
            if Random.bool () then (h, 1 + Random.int max_exp) :: aux t
            else aux t
      in
      match aux support with [] -> random_m max_exp () | e -> m_of_binds e

    let sample () =
      let r = random_m 40 () in
      Format.printf "%a\n" pp r ;
      r

    let test_compare_one_is_min () =
      let a = sample () in
      Alcotest.(check bool) "compare_one_is_min" true (compare one a < 0)

    let test_equal_not_one () =
      let a = sample () in
      Alcotest.check (Alcotest.neg t_mono) "equal_not_one" one a

    let test_equal_self () =
      let a = sample () in
      Alcotest.check t_mono "equal_self" a a

    let test_mul_one () =
      let a = sample () in
      Alcotest.check t_mono "mul_one" a (a * one)

    let test_mul_sym () =
      let a = sample () in
      let b = sample () in
      Alcotest.check t_mono "mul_sym" (a * b) (b * a)

    let test_mul_distr () =
      let a = sample () in
      let b = sample () in
      let c = sample () in
      Alcotest.check t_mono "mul_distr" (a * (b * c)) (a * b * c)

    let test_mul_example () = Alcotest.check t_mono "mul_example" m12 (m1 * m2)

    let test_deg_singleton () =
      Alcotest.(check int) "deg_singleton:1" 1 (deg (singleton "x") "x") ;
      Alcotest.(check int) "deg_singleton:0" 0 (deg (singleton "y") "x")

    let test_deg_mul () =
      let a = sample () in
      let b = sample () in
      Alcotest.(check int) "deg_mul" (deg (a * b) "x") (deg a "x" + deg b "x")

    let test_apply_singleton () =
      let q = K.random () in
      let e = if K.is_zero q then None else Some (q, one) in
      let sp = StringMap.singleton "x" q in
      let x = singleton "x" in
      let y = singleton "y" in
      Alcotest.(check (option (pair t_q t_mono)))
        "apply_singleton:1"
        e
        (apply x sp) ;
      Alcotest.(check (option (pair t_q t_mono)))
        "apply_singleton:2"
        (Some (K.one, y))
        (apply y sp)

    let test_apply () =
      let a = sample () in
      let b = sample () in
      let sp = StringMap.singleton "x" (K.random ()) in
      let sp = StringMap.add "y" (K.random ()) sp in
      let check_zero_var c v =
        K.eq (StringMap.find v sp) K.zero && StringMap.mem v c
      in
      let check_zero c = check_zero_var c "x" || check_zero_var c "y" in
      match (apply a sp, apply b sp, apply (a * b) sp) with
      | (None, None, None) ->
          Alcotest.(check bool) "apply:0*0" true (check_zero a && check_zero b)
      | (None, Some _, None) ->
          Alcotest.(check bool) "apply:0*b" true (check_zero a)
      | (Some _, None, None) ->
          Alcotest.(check bool) "apply:a*0" true (check_zero b)
      | (Some (qa, ra), Some (qb, rb), Some (qab, rab)) ->
          Alcotest.(check (pair t_q t_mono))
            "apply:a*b"
            (qab, rab)
            (K.mul qa qb, ra * rb)
      | _ -> Alcotest.fail "apply:impossible_zero_case"

    let tests =
      [
        ("The smallest monomial is 1", `Quick, many test_compare_one_is_min);
        ("Non empty monomial is not 1", `Quick, many test_equal_not_one);
        ("For all m, m = m", `Quick, many test_equal_self);
        ("For all m, m*1 = m", `Quick, many test_mul_one);
        ("For all a b, a*b = b*a", `Quick, many test_mul_sym);
        ("For all a b c, a*(b*c) = (a*b)*c", `Quick, many test_mul_distr);
        ("(x^4.y^2.z) * (xy)^2 = x^6.y^4.z", `Quick, test_mul_example);
        ("deg_x x = 1, deg_x y = 0", `Quick, test_deg_singleton);
        ( "For all a b, deg_x (a*b) = deg_x a + deg_x b",
          `Quick,
          many test_deg_mul );
        ("Test apply on x", `Quick, many test_apply_singleton);
        ( "For all a b, (apply a) * (apply b) = apply (a*b)",
          `Quick,
          many test_apply );
      ]
  end

  (** Polynomials *)
  module PolynomialTests = struct
    open Polynomial
    open PolynomialOperators

    let pp fmt t = Format.pp_print_string fmt (to_ascii t)

    let t_poly = Alcotest.testable pp equal

    let random_p_aux max_exp max_mono () =
      let rec aux nm =
        if nm <= 0 then if Random.bool () then one else zero
        else
          (K.random () *. of_monomial (MonomialTests.random_m max_exp ()))
          + aux (Int.pred nm)
      in
      aux (Random.int (Int.succ max_mono))

    let random_p max_exp max_mono max_fact () =
      let rec aux np =
        if np <= 0 then one
        else random_p_aux max_exp max_mono () * aux (Int.pred np)
      in
      K.random () *. aux (Int.succ (Random.int max_fact))

    let sample () =
      let r = random_p 10 3 2 () in
      Format.printf "%a\n" pp r ;
      r

    let mini_sample () =
      let r = random_p 1 3 2 () in
      Format.printf "%a\n" pp r ;
      r

    let test_equal_self () =
      let a = sample () in
      Alcotest.check t_poly "equal_self" a a

    let test_sub_self () =
      let a = sample () in
      let z =
        of_list
          StringMap.
            [
              (monomial_of_list ["Z"], K.one);
              (monomial_of_list ["Z"], K.negate K.one);
            ]
      in
      Alcotest.check t_poly "equal_self" (a + z) a

    let test_add_zero () =
      let a = sample () in
      Alcotest.check t_poly "add_zero" a (a + zero)

    let test_add_sym () =
      let a = sample () in
      let b = sample () in
      Alcotest.check t_poly "add_sym" (a + b) (b + a)

    let test_add_distr () =
      let a = sample () in
      let b = sample () in
      let c = sample () in
      Alcotest.check t_poly "add_distr" (a + (b + c)) (a + b + c)

    let test_mul_scalar () =
      let a = sample () in
      let b = sample () in
      let q = K.random () in
      Alcotest.check t_poly "mul_scalar:1" (q *. a * b) (a * (q *. b)) ;
      Alcotest.check t_poly "mul_scalar:2" (q *. (a * b)) (a * (q *. b))

    let test_mul_scalar_distr () =
      let a = sample () in
      let b = sample () in
      let q = K.random () in
      Alcotest.check
        t_poly
        "mul_scalar_distr"
        (q *. (a + b))
        ((q *. a) + (q *. b))

    let test_neg () =
      let a = sample () in
      Alcotest.check t_poly "neg" (K.(negate one) *. a) (neg a)

    let test_sub () =
      let a = sample () in
      let b = sample () in
      Alcotest.check t_poly "sub" (a + neg b) (a - b)

    let test_normalize () =
      let a = sample () in
      let (q, na) = normalize a in
      if K.is_zero q then (
        Alcotest.check t_poly "normalize:zero_a" zero a ;
        Alcotest.check t_poly "normalize:zero_na" zero na)
      else (
        Alcotest.(check (neg t_poly)) "normalize:zero_a" zero a ;
        Alcotest.(check (neg t_poly)) "normalize:zero_na" zero na ;
        Alcotest.check t_poly "normalize:decomp" a (q *. na) ;
        Alcotest.check
          t_q
          "normalize:min_one"
          K.one
          (snd (MonomialMap.min_binding na)))

    let test_mul_one () =
      let a = sample () in
      Alcotest.check t_poly "mul_one" a (a * one)

    let test_mul_sym () =
      let a = sample () in
      let b = sample () in
      Alcotest.check t_poly "mul_sym" (a * b) (b * a)

    let test_mul_distr () =
      let a = sample () in
      let b = sample () in
      let c = sample () in
      Alcotest.check t_poly "mul_distr" (a * (b * c)) (a * b * c)

    let test_mul_distr_add () =
      let a = sample () in
      let b = sample () in
      let c = sample () in
      Alcotest.check t_poly "mul_distr_add" (a * (b + c)) ((a * b) + (a * c))

    let test_deg_singleton () =
      Alcotest.(check int) "deg_singleton:1" 1 (deg (singleton "x") "x") ;
      Alcotest.(check int) "deg_singleton:0" 0 (deg (singleton "y") "x") ;
      Alcotest.(check int) "deg_singleton:-1" (-1) (deg zero "x")

    let test_deg_mul () =
      let a = sample () in
      let b = sample () in
      if equal a zero || equal b zero then
        Alcotest.(check int) "deg_mul:zero" (deg (a * b) "x") (-1)
      else
        Alcotest.(check int)
          "deg_mul"
          (deg (a * b) "x")
          (Int.add (deg a "x") (deg b "x"))

    let test_group_by () =
      let a = sample () in
      let rec regroup = function
        | [] -> zero
        | h :: t -> h + (singleton "x" * regroup t)
      in
      Alcotest.check t_poly "group_by" a (regroup (group_by a "x"))

    let test_substitution_singleton () =
      let a = sample () in
      let x = singleton "x" in
      Alcotest.check
        t_poly
        "substitution_singleton:sub"
        a
        (substitution x "x" a) ;
      Alcotest.check
        t_poly
        "substitution_singleton:not_sub"
        x
        (substitution x "y" a)

    let test_substitution_add () =
      let a = mini_sample () in
      let b = mini_sample () in
      let c = mini_sample () in
      Alcotest.check
        t_poly
        "substitution_add"
        (substitution a "x" c + substitution b "x" c)
        (substitution (a + b) "x" c)

    let test_substitution_mul () =
      let a = mini_sample () in
      let b = mini_sample () in
      let c = mini_sample () in
      Alcotest.check
        t_poly
        "substitution_mul"
        (substitution a "x" c * substitution b "x" c)
        (substitution (a * b) "x" c)

    let test_substitution_comp () =
      let a = mini_sample () in
      let b = mini_sample () in
      let c = mini_sample () in
      Alcotest.check
        t_poly
        "substitution_comp"
        (substitution a "x" (substitution b "x" c))
        (substitution (substitution a "x" b) "x" c)

    let test_substitution_comp_singleton () =
      let a = mini_sample () in
      let b = mini_sample () in
      let x1 = singleton "x" + one in
      Alcotest.check
        t_poly
        "substitution_singleton:sub"
        (a + b)
        (substitution_comp x1 "x" a b)

    let test_substitution_comp_mul () =
      let a = mini_sample () in
      let b = mini_sample () in
      let c = mini_sample () in
      let d = mini_sample () in
      Alcotest.check
        t_poly
        "substitution_mul"
        (substitution_comp a "x" c d * substitution_comp b "x" c d)
        (substitution_comp (a * b) "x" c d)

    let test_leading_coef_singleton () =
      Alcotest.(check (pair t_poly int))
        "leading_coef_singleton"
        (one, 1)
        (leading_coef (singleton "x") "x") ;
      Alcotest.(check (pair t_poly int))
        "leading_coef_singleton"
        (singleton "y", 0)
        (leading_coef (singleton "y") "x") ;
      Alcotest.(check (pair t_poly int))
        "leading_coef_singleton"
        (zero, -1)
        (leading_coef zero "x")

    let test_leading_coef_mul () =
      let a = sample () in
      let b = sample () in
      let (la, na) = leading_coef a "x" in
      let (lb, nb) = leading_coef b "x" in
      Alcotest.(check (pair t_poly int))
        "leading_coef_mul"
        (leading_coef (a * b) "x")
        ( la * lb,
          if Int.equal na (-1) || Int.equal nb (-1) then -1 else Int.add na nb
        )

    let test_apply_singleton () =
      let q = K.random () in
      let sp = StringMap.singleton "x" q in
      let x = singleton "x" in
      Alcotest.check t_q "apply_singleton:1" q (apply x sp)

    let test_apply () =
      let a = sample () in
      let b = sample () in
      let sp = StringMap.singleton "x" (K.random ()) in
      let _fail_app_a =
        try
          let _ = apply a sp in
          failwith "apply a sp should have failed"
        with Failure _ -> ()
      in
      let sp = StringMap.add "y" (K.random ()) sp in
      let app_a = apply a sp in
      let app_b = apply b sp in
      let app_a_b = apply (a + b) sp in
      let app_ab = apply (a * b) sp in
      Alcotest.check t_q "apply:add" (K.add app_a app_b) app_a_b ;
      Alcotest.check t_q "apply:mul" (K.mul app_a app_b) app_ab

    let test_apply_default_0 () =
      let a = sample () in
      let b = sample () in
      let sp = StringMap.singleton "x" (K.random ()) in
      let _fail_app_a =
        try
          let _ = apply a sp in
          failwith "apply a sp should have failed"
        with Failure _ -> ()
      in
      let sp = StringMap.add "y" (K.random ()) sp in
      let app_a = apply a sp in
      let app_b = apply b sp in
      let app_a_b = apply (a + b) sp in
      let app_ab = apply (a * b) sp in
      Alcotest.check t_q "apply_default_0:add" (K.add app_a app_b) app_a_b ;
      Alcotest.check t_q "apply_default_0:mul" (K.mul app_a app_b) app_ab

    let tests =
      [
        ("For all p, p = p", `Quick, many test_equal_self);
        ("For all p, p + 0 = p", `Quick, many test_sub_self);
        ("For all p, p = p + 0", `Quick, many test_add_zero);
        ("For all p q, p + q = q + p", `Quick, many test_add_sym);
        ("For all p q r, p + (q + r) = (p + q) + r", `Quick, many test_add_distr);
        ( "For all p q, and scalar k, (k.p)*q = p*(k.q) = k.(p*q)",
          `Quick,
          many test_mul_scalar );
        ( "For all p q, and scalar k, k.(p+q) = k.p + k.q",
          `Quick,
          many test_mul_scalar_distr );
        ("For all p, -p = (-1).p", `Quick, many test_neg);
        ("For all p q, p - q = p + (-q)", `Quick, many test_sub);
        ( "Test normalize: a = k.b with min monomial in b with coefficient 1",
          `Quick,
          many test_normalize );
        ("For all p, p = p*1", `Quick, many test_mul_one);
        ("For all p q, p*q = q*p", `Quick, many test_mul_sym);
        ("For all p q r, p*(q*r) = (p*q)*r", `Quick, many test_mul_distr);
        ( "For all p q r, p*(q+r) = (p*q) + (p*r)",
          `Quick,
          many test_mul_distr_add );
        ("deg_x x = 1, deg_x y = 0, deg_x 0 = -1", `Quick, test_deg_singleton);
        ( "For all a b <> 0, deg_x (a*b) = deg_x a + deg_x b",
          `Quick,
          many test_deg_mul );
        ("Test group_by", `Quick, many test_group_by);
        ( "For all p, x[x->p] = p and y[x->p] = y (substitution of the \
           variable x with the polynomial p)",
          `Quick,
          many test_substitution_singleton );
        ( "For all p q r, (p+q)[x->r] = p[x->r] + q[x->r]",
          `Quick,
          many test_substitution_add );
        ( "For all p q r, (p*q)[x->r] = p[x->r] * q[x->r]",
          `Quick,
          many test_substitution_mul );
        ( "For all p q r, (p[x->q])[x->r] = p[x->(q[x->r])]",
          `Quick,
          many test_substitution_comp );
        ( "For all p q, q.(x+1)[x->p/q] = p + q",
          `Quick,
          many test_substitution_comp_singleton );
        ( "For all p q r s, (p*q)[x->r/s] = p[x->r/s] * q[x->r/s]",
          `Quick,
          many test_substitution_comp_mul );
        ( "lc_x(x) = 1, lc_x(y) = y, lc_x(0) = 0",
          `Quick,
          test_leading_coef_singleton );
        ( "For all p q, lc_x(p*q) = lc_x(p) * lc_x(q)",
          `Quick,
          many test_leading_coef_mul );
        ("Test apply on x", `Quick, many test_apply_singleton);
        ("Test apply wrt addition and multiplication", `Quick, many test_apply);
        ( "Test apply_default_0 wrt addition and multiplication",
          `Quick,
          many test_apply_default_0 );
      ]
  end

  let tests =
    [
      ("Multivariate monomial", MonomialTests.tests);
      ("Multivariate polynomial", PolynomialTests.tests);
    ]
end

module T_Q = TestEnvironment (Q_config)
