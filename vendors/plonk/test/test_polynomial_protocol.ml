open Plonk
module PC = Kzg
module Fr_generation = PC.Fr_generation

let fr_of_string = PC.Scalar.of_string

module Internal = struct
  open Polynomial_protocol.Make (PC)

  module Poly = PC.Polynomial.Polynomial

  let test_build_query () =
    let x = Fr_generation.fr_of_int_safe 1 in
    let v_list =
      [
        Poly.of_coefficients
          [
            (Fr_generation.fr_of_int_safe 2, 2);
            (Fr_generation.fr_of_int_safe 1, 1);
          ];
        Poly.of_coefficients
          [
            (Fr_generation.fr_of_int_safe 2, 3);
            (Fr_generation.fr_of_int_safe 1, 2);
          ];
        Poly.of_coefficients
          [
            (Fr_generation.fr_of_int_safe 1, 1);
            (Fr_generation.fr_of_int_safe 1, 0);
          ];
      ]
    in
    let v_list_att =
      (* expected result of build query *)
      [
        Fr_generation.fr_of_int_safe 3;
        Fr_generation.fr_of_int_safe 3;
        Fr_generation.fr_of_int_safe 2;
      ]
    in
    let v_list_query = List.map (fun v -> Poly.evaluate v x) v_list in
    assert (List.for_all2 PC.Scalar.eq v_list_att v_list_query)
end

module External = struct
  open Polynomial_protocol
  module Domain = PC.Polynomial.Domain

  let fr_of_string = PC.Scalar.of_string

  let test_protocol ~pc ~pack () =
    let module PC = (val pc : Plonk.Kzg.Polynomial_commitment_sig) in
    let open Plonk.Polynomial_protocol.Make (PC) in
    let module Domain = PC.Polynomial.Domain in
    let module Poly = PC.Polynomial.Polynomial in
    let module Evaluations = PC.Polynomial.Evaluations in
    let log = 4 in
    let n = Int.shift_left 1 log in
    let nb_packs = if pack then 10 else 0 in
    let domain = Domain.build ~log in
    (* verify that identity X₁X₂-X₁ = 0 when X₁ = L₁(a) and X₂ = Z(a) where
       L₁(g^n-1) = 1, L₁(a) = 0 for all a != g^n-1, Z(g^n-1) = 1 and
       Z(a) = whatever for all a != g, with g a prime n-th root of unity
       (n of the form 2^i), and a = g^k for k between 0 and n-1, different
       from g^n-1 *)
    (* we take g^n-1 and not g in order to avoid the bug in interpolation_fft
       with prevent to give to f(g^n-1) the value zero *)
    let l1 =
      let scalar_list_l1 =
        Array.init n (fun i ->
            if i = n - 1 then PC.Scalar.one else PC.Scalar.zero)
      in
      Evaluations.interpolation_fft2 domain scalar_list_l1
    in
    let z =
      let scalar_list_z =
        Array.init n (fun i ->
            if i = n - 1 then PC.Scalar.one else PC.Scalar.random ())
      in
      Evaluations.interpolation_fft2 domain scalar_list_z
    in
    let g_map = SMap.add_unique "L1" l1 SMap.empty in
    let (pp_prover, pp_verifier) =
      setup
        ~setup_params:(n + 1, nb_packs)
        g_map
        (Helpers.srs_path "srs_5")
        ~subgroup_size:n
    in
    let f_map = SMap.add_unique "Z" z SMap.empty in
    let v_map = SMap.empty in
    let identities =
      SMap.(
        add
          "L1_Z"
          (MP.Polynomial.of_list
             [
               (monomial_of_list ["L1"; "Z"], PC.Scalar.one);
               (monomial_of_list ["L1"], PC.Scalar.(negate one));
             ])
          empty)
    in
    let prover_query =
      let eval_l1_z =
        let l1_z = Poly.((l1 * z) - l1) in
        let deg_l1_z =
          let deg_l1 = Poly.degree l1 in
          let deg_z = Poly.degree z in
          deg_l1 + deg_z
        in
        let domain = Domain.build ~log:Z.(log2up (of_int deg_l1_z)) in
        Evaluations.evaluation_fft domain l1_z
      in

      {v_map; precomputed_polys = SMap.singleton "L1_Z" eval_l1_z}
    in
    let verifier_query = {v_map; identities; not_committed = SMap.empty} in
    let transcript =
      PC.Commitment.expand_transcript Bytes.empty pp_verifier.cm_g_map
    in
    let pack_name = if pack then Some "pack_test" else None in

    (* Positive test *)
    let cm_f_map =
      PC.Commitment.commit ?pack_name pp_prover.pc_public_parameters f_map
    in
    let (proof, _) = prove pp_prover transcript cm_f_map f_map prover_query in
    assert (
      verify ~proof_type:Single pp_verifier transcript proof verifier_query) ;

    (* Negative test *)
    let new_z =
      let scalar_list_z = Array.init n (fun _ -> PC.Scalar.random ()) in
      Evaluations.interpolation_fft2 domain scalar_list_z
    in
    let f_map = SMap.add_unique "Z" new_z SMap.empty in
    try
      let cm_f_map =
        PC.Commitment.commit ?pack_name pp_prover.pc_public_parameters f_map
      in
      let (proof, _) = prove pp_prover transcript cm_f_map f_map prover_query in
      assert (
        not
          (verify
             ~proof_type:Single
             pp_verifier
             transcript
             proof
             verifier_query))
    with Poly.Rest_not_null _ -> ()
end

(* TODO ;; *)
let () = Random.init 128456788909876

let tests =
  List.map
    (fun (name, f) ->
      Alcotest.test_case name `Quick (fun () -> Plonk.Multicore.with_pool f))
    [
      ("Internal.test_build_query", Internal.test_build_query);
      ( "KZG.test_protocol",
        External.test_protocol
          ~pack:false
          ~pc:(module Plonk.Kzg : PC.Polynomial_commitment_sig) );
      ( "KZG_Pack.test_protocol (no pack)",
        External.test_protocol
          ~pack:false
          ~pc:(module Plonk.Kzg_pack : PC.Polynomial_commitment_sig) );
      ( "KZG_Pack.test_protocol (pack)",
        External.test_protocol
          ~pack:true
          ~pc:(module Plonk.Kzg_pack : PC.Polynomial_commitment_sig) );
    ]
