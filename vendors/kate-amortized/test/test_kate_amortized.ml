(* except eval_fr, Poly’s functions are only used to compute polynomial division and get the expected results of prove functions *)
module Poly = struct
  open Kate_amortized
  include Polynomial.Univariate.Make (Scalar)

  (* This extra function compute evaluation polynomial represented as list : it avoids the conversion from list to polynomial *)
  let eval_fr p x =
    let h_list = List.rev p in
    let aux acc a = Scalar.((acc * x) + a) in
    List.fold_left aux Scalar.zero h_list
end

module Internal = struct
  open Kate_amortized.Kate_amortized_impl

  (* test for multiple proofs of part 2 of the article *)
  let test_multiple_proofs () =
    let i = 4 in
    (* n = evaluation domain size
       m = polynomial degree + 1
       k = smallest power of two >= m *)
    let n = 1 lsl i in
    let m = 1 lsl (i - 1) in
    let k = Z.log2up (Z.of_int (2 * m)) in
    let domain2m = Domain.build k in
    let x = Scalar.random () in
    let srs = gen_srs ~l:n ~size:m x in
    let coefs = List.init m (fun _i -> Scalar.random ()) in
    let time = Unix.gettimeofday () in
    let proofs = build_ct_list ~nb_proofs:i ~degree:m coefs srs domain2m in
    Printf.printf "\nbuild_ct_list : %f s." (Unix.gettimeofday () -. time) ;
    let proofk k =
      let y =
        let module Fr_gen = Polynomial__Fr_generation.Make (Scalar) in
        Scalar.pow (Fr_gen.root_of_unity i) (Z.of_int k)
      in
      if k >= 1 lsl i then failwith "k >= 2^i" ;
      let poly_f = Poly.of_coefficients (List.mapi (fun i f -> (f, i)) coefs) in
      let z = Poly.eval_fr coefs y in
      let num = Poly.(sub poly_f (constants z)) in
      let denom =
        Poly.of_coefficients [(Scalar.one, 1); (Scalar.negate y, 0)]
      in
      let (quotient, _rest) =
        Option.get (Poly.euclidian_division_opt num denom)
      in
      commit (List.rev (Poly.get_dense_polynomial_coefficients quotient)) srs
    in
    let verif_all proofs_list =
      let aux y proof =
        let z = Poly.eval_fr coefs y in
        let x_y = G2.mul G2.one Scalar.(x + negate y) in
        let fx_z = G1.(add (commit coefs srs) (negate (mul one z))) in
        let e1 = Pairing.pairing proof x_y in
        let e2 = Pairing.pairing fx_z G2.one in
        assert (GT.eq e1 e2)
      in
      let domain = Domain.build i in
      Array.iteri (fun i p -> aux domain.(i) p) proofs_list
    in
    let p_list = Array.init (1 lsl i) proofk in
    assert (Array.for_all2 G1.eq p_list proofs) ;
    verif_all proofs ;
    print_string "\nAll proofs successfully verified.\n"

  (* i = log₂(total number of evaluations) = r+k (correspond to `n` in the article)
     k = log₂(number of proofs)
     r = log₂(number of evaluations for each proof), l = 2^r (same notation as in article)
     f is the committed polynomial ; generated with random scalars
     m = number of polynomial f’s coefficients, must be a power of two (same notation as in article)
     compute & verify k proofs, where proof.(a) = [f(w^a×ψ⁰), …, f(w^a×ψ^(2^r -1))], for a ∈ [0, 2^k -1]
     also compute the expected proofs by making the division & check the equality with the proofs of multiple_multi_reveals
  *)
  let test_prove_verify_multi () =
    let i = 8 in
    let r = 5 in
    let k = i - r in
    let m = 1 lsl (i - 1) in
    let l = 1 lsl r in
    let f = List.init m (fun _i -> Scalar.random ()) in
    let s = Scalar.random () in
    (* srs = ([[1]₁, …, [s^(m-1)]]₂, [s^l]₂) *)
    let srs = gen_srs ~l ~size:m s in
    let proofs =
      multiple_multi_reveals ~chunk_len:r ~chunk_count:k ~degree:m f srs
    in
    (* ---- Check proofs manually ---- *)
    let domain_n = Domain.build i in
    let f_poly = Poly.of_coefficients (List.mapi (fun i a -> (a, i)) f) in
    (* get expected proof directly with polynomial division *)
    let expected_proof k =
      let y = domain_n.(k) in
      let yl = Scalar.pow y (Z.of_int l) in
      let divider =
        Poly.of_coefficients [(Scalar.one, l); (Scalar.negate yl, 0)]
      in
      let (g_poly, _h_poly) =
        Option.get (Poly.euclidian_division_opt f_poly divider)
      in
      commit (List.rev (Poly.get_dense_polynomial_coefficients g_poly)) srs
    in
    let expected_proofs =
      Array.init (1 lsl (i - r)) (fun k -> expected_proof k)
    in
    assert (Array.for_all2 G1.eq expected_proofs proofs) ;
    (* ---- Verify ---- *)
    let cm_f = commit f srs in
    let domain_n = Domain.build i in
    let domain_l = Domain.build r in
    (* expected evaluations of f at (w^k×ψ^i) for i ∈ [0, l-1] *)
    let wk_evaluations k =
      let w = domain_n.(k) in
      let evaluations =
        Array.map (fun psi -> Poly.eval_fr f Scalar.(w * psi)) domain_l
      in
      (w, evaluations)
    in
    let wrong_wk_evaluations k =
      let w = domain_n.(k) in
      let evaluations =
        Array.map (fun psi -> Poly.eval_fr f Scalar.(one + (psi * w))) domain_l
      in
      (w, evaluations)
    in
    let verify_all_proofs proofs =
      let proof_list = Array.to_list proofs in
      let rec aux k proof_list =
        match proof_list with
        | [] -> Printf.printf "\n%d proofs verified successfully." k
        | ct :: tl ->
            assert (verify cm_f srs domain_l (wk_evaluations k) ct) ;
            assert (not (verify cm_f srs domain_l (wrong_wk_evaluations k) ct)) ;
            assert (
              not (verify cm_f srs domain_l (wk_evaluations k) G1.(add ct one))) ;
            aux (k + 1) tl
      in
      aux 0 proof_list
    in
    verify_all_proofs proofs
end

module External = struct
  open Kate_amortized

  (* article here : https://github.com/khovratovich/Kate/blob/master/Kate_amortized.pdf
     i = log₂(total number of evaluations) = r+k (correspond to `n` in the article)
     k = log₂(number of proofs)
     r = log₂(number of evaluations for each proof), l = 2^r (same notation as in article)
     f is the committed polynomial ; generated with random scalars
     m = number of polynomial f’s coefficients, must be a power of two (same notation as in article)
     compute & verify k proofs, where proof.(a) = [f(w^a×ψ⁰), …, f(w^a×ψ^(2^r -1))], for a ∈ [0, 2^k -1]
  *)
  let test_prove_verify_multi () =
    let i = 13 in
    let r = 5 in
    let m = 1 lsl (i - 1) in
    let k = i - r in
    let n = 1 lsl i in
    let l = 1 lsl r in
    Printf.printf "\nn = %d" i ;
    Printf.printf "\nr = %d" r ;
    Printf.printf "\n2^n = %d" n ;
    Printf.printf "\nm = %d" m ;
    Printf.printf "\nl = %d" (1 lsl r) ;
    let f = List.init m (fun _ -> Scalar.random ()) in
    let s = Scalar.random () in
    let srs = gen_srs ~l ~size:m s in
    let time = Unix.gettimeofday () in
    let proofs =
      multiple_multi_reveals ~chunk_len:r ~chunk_count:k ~degree:m f srs
    in
    Printf.printf "\nproofs + preprocess : %f s." (Unix.gettimeofday () -. time) ;
    (* ---- Verify ---- *)
    let cm_f = commit f srs in
    let domain_n = Domain.build i in
    let domain_l = Domain.build r in
    (* compute expected evaluations for each k-th proof *)
    let wk_evaluations k =
      let w = Domain.get domain_n k in
      let evaluations =
        Domain.map (fun psi -> Poly.eval_fr f Scalar.(w * psi)) domain_l
      in
      (w, evaluations)
    in
    (* verify all expected evaluations with computed proofs *)
    let verify_all_proofs proofs =
      let proof_list = Array.to_list proofs in
      let rec aux k proof_list =
        match proof_list with
        | [] -> Printf.printf "\n%d proofs verified successfully." k
        | ct :: tl ->
            (* let time = Unix.gettimeofday () in *)
            assert (verify cm_f srs domain_l (wk_evaluations k) ct) ;
            (* Printf.printf
               "\n%d-th proof verified in %f s."
               k
               (Unix.gettimeofday () -. time) ; *)
            aux (k + 1) tl
      in
      aux 0 proof_list
    in
    let time = Unix.gettimeofday () in
    verify_all_proofs proofs ;
    Printf.printf
      "\nTotal verification time for all proofs : %f s."
      (Unix.gettimeofday () -. time)
end

module Benches = struct
  open Kate_amortized.Kate_amortized_impl

  let chrono_mulG1 () =
    let x = G1.random () in
    let y = Scalar.random () in
    let time = Unix.gettimeofday () in
    let _ = G1.mul x y in
    (Unix.gettimeofday () -. time) *. 1000000.

  let chrono_mulFr () =
    let x = Scalar.random () in
    let y = Scalar.random () in
    let time = Unix.gettimeofday () in
    let _ = Scalar.mul x y in
    (Unix.gettimeofday () -. time) *. 1000000.

  let bench chrono_func unity nb_tests =
    let rec aux_for i acc =
      if i = nb_tests then acc /. float_of_int nb_tests
      else aux_for (i + 1) (chrono_func () +. acc)
    in
    let time = Unix.gettimeofday () in
    let t = aux_for 0 0. in
    Printf.printf "\nAverage time for %d executions : %f %s." nb_tests t unity ;
    Printf.printf "\nTotal time spent : %f s." (Unix.gettimeofday () -. time)
end

let tests =
  List.map
    (fun (name, f) ->
      Alcotest.test_case name `Quick (fun () -> Plonk.Multicore.with_pool f))
    [
      ("test_multiple_proofs", Internal.test_multiple_proofs);
      ("Internal.test_prove_verify_multi", Internal.test_prove_verify_multi);
    ]

let bench =
  [
    Alcotest.test_case "External.test_prove_verify_multi" `Slow (fun () ->
        Plonk.Multicore.with_pool External.test_prove_verify_multi);
  ]
