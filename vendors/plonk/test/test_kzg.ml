module SMap = Plonk.SMap

(* The module is instantiated again to avoid the signature so that internal
   functions can be tested. *)
module Internal = struct
  open Plonk.Kzg.Kzg_impl

  (* [1]₁ = g1 *)
  let test_encoding1 () =
    let x = Scalar.one in
    let y = Public_parameters.encoding x in
    assert (G1.eq y G1.one)

  (* [1]₂ = g2 *)
  let test_encoding2 () =
    let x = Scalar.one in
    let y = Public_parameters.encoding_2 x in
    assert (G2.eq y G2.one)

  let test_create_srs1 () =
    let open Public_parameters in
    let x = Scalar.random () in
    let srs1 = create_srs1 5 x in
    assert (Array.length srs1 = 5) ;
    assert (G1.eq srs1.(0) G1.one) ;
    (* encoding_1 Scalar.one *)
    assert (G1.eq srs1.(1) (encoding x)) ;
    assert (G1.eq srs1.(2) (encoding (Scalar.pow x (Z.of_int 2)))) ;
    assert (G1.eq srs1.(3) (encoding (Scalar.pow x (Z.of_int 3)))) ;
    assert (G1.eq srs1.(4) (encoding (Scalar.pow x (Z.of_int 4))))
end

(* Tests on the the interface of the module. *)
module External = struct
  open Plonk.Kzg
  module Poly = Polynomial.Polynomial

  let generate_z_maps t =
    let rec build_map len map =
      match len with
      | 0 -> map
      | i ->
          let z = Scalar.random () in
          let len_i_list = max 1 (Random.int (t * t)) in
          let i_list =
            List.init len_i_list (fun _ -> Int.to_string (Random.int (t * t)))
          in
          build_map (i - 1) (Scalar_map.add z i_list map)
    in
    build_map t Scalar_map.empty

  (* Poly.generate_random_polynomial is not used because it gives sparse polynomial ; this may induce equal evaluations for supposed different polynomial and make negative tests fail because different evaluations are assumed *)
  let generate_random_poly d =
    Poly.of_coefficients (List.init d (fun i -> (Scalar.random (), i)))

  let generate_f_map d n =
    let generate_f i = (string_of_int i, generate_random_poly d) in
    SMap.of_list (List.init n generate_f)

  let srsfile = Helpers.srs_path "srs_16"

  let test_prove_verify () =
    let d = 20 in
    let t = 10 in
    let (prv, vrf) = Public_parameters.setup (d, 0) in
    let f_map = generate_f_map d (t * t) in
    let cm_map = Commitment.commit prv f_map in
    let transcript = Commitment.expand_transcript Bytes.empty cm_map in
    let z_map = generate_z_maps t in
    let (proof, _) = prove prv transcript cm_map z_map f_map in
    let dummy_cm = Commitment.commit prv SMap.empty in
    let v = verify vrf transcript z_map dummy_cm proof in
    assert v

  let test_prove_verify_fake_answer_proof () =
    let d = 20 in
    let t = 10 in
    let (prv, vrf) = Public_parameters.setup (d, 0) in
    let f_map = generate_f_map d (t * t) in
    let cm_map = Commitment.commit prv f_map in
    let transcript = Commitment.expand_transcript Bytes.empty cm_map in
    let z_map = generate_z_maps t in
    let ((s_map, w_list), _) = prove prv transcript cm_map z_map f_map in
    let new_first_answer =
      let (x, _) = Scalar_map.choose s_map in
      let first_answer = Scalar_map.find x s_map in
      let (s, head) = List.hd first_answer in
      let new_first_answer =
        (s, Scalar.(add head one)) :: List.tl first_answer
      in
      Scalar_map.add x new_first_answer s_map
    in
    let dummy_cm = Commitment.commit prv SMap.empty in
    let v = verify vrf transcript z_map dummy_cm (new_first_answer, w_list) in
    assert (not v)
end

let tests =
  [
    Alcotest.test_case "test_encoding1" `Quick Internal.test_encoding1;
    Alcotest.test_case "test_encoding2" `Quick Internal.test_encoding2;
    Alcotest.test_case "test_create_srs1" `Quick Internal.test_create_srs1;
  ]
  @ List.map
      (fun (name, f) ->
        Alcotest.test_case name `Quick (fun () -> Plonk.Multicore.with_pool f))
      [
        ("test_prove_verify", External.test_prove_verify);
        ( "test_prove_verify_fake_answer_proof",
          External.test_prove_verify_fake_answer_proof );
      ]
