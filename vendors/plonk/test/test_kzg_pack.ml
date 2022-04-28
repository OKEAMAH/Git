module SMap = Plonk.SMap

module Auxiliary (PC : Plonk.Kzg.Polynomial_commitment_sig) = struct
  open PC
  module Poly = PC.Polynomial.Polynomial

  let get_pack_name x = "packed_" ^ string_of_int (Z.hash (Scalar.to_z x))

  let dummy_cm srs = Commitment.commit srs SMap.empty

  let generate_z_maps t nb_poly =
    let rec build_map i map =
      if i = t then map
      else
        let z = Scalar.random () in
        let i_list =
          get_pack_name z
          :: List.init nb_poly (fun k -> Int.to_string ((i * nb_poly) + k))
        in
        build_map (i + 1) (Scalar_map.add z i_list map)
    in
    build_map 0 Scalar_map.empty

  (* Poly.generate_random_polynomial is not used because it gives sparse polynomial ; this may induce equal evaluations for supposed different polynomial and make negative tests fail because different evaluations are assumed *)
  let generate_random_poly d =
    Poly.of_coefficients (List.init d (fun i -> (PC.Scalar.random (), i)))

  let generate_f_map d n =
    let generate_f i = (string_of_int i, generate_random_poly d) in
    SMap.of_list (List.init n generate_f)

  let get_polys_to_pack nb_pack secret names =
    let (names_pack, names_unpack) = Plonk.List.split_n nb_pack names in
    (names_unpack, SMap.filter (fun name _ -> List.mem name names_pack) secret)

  let get_pack_map nb_pack srs query secret =
    (* nb_pack is the minimum length of query’s list - 1 *)
    Scalar_map.fold
      (fun x names (names_unpack_acc, acc) ->
        let (names_unpack, f_pack_map) =
          get_polys_to_pack nb_pack secret names
        in
        let pack_name = get_pack_name x in
        let cm = Commitment.commit ~pack_name srs f_pack_map in
        ( List.rev_append names_unpack names_unpack_acc,
          Commitment.(merge acc cm) ))
      query
      ([], dummy_cm srs)

  let add_unpack_cm srs secret (names_unpack, cm_map) =
    let f_map = SMap.filter (fun name _ -> List.mem name names_unpack) secret in
    Commitment.(merge cm_map (commit srs f_map))

  let build_proof d t nb_poly_per_points =
    assert (nb_poly_per_points >= 4) ;
    let nb_pack = max 2 (Random.int (nb_poly_per_points - 2)) in
    let pack_setup_param = 1 lsl Z.(log2up (of_int nb_pack)) in
    let (prv, vrf) = Public_parameters.setup (d, pack_setup_param) in
    let f_map = generate_f_map d (t * nb_poly_per_points) in
    let z_map = generate_z_maps t nb_poly_per_points in
    let cm_map =
      add_unpack_cm prv f_map (get_pack_map nb_pack prv z_map f_map)
    in
    let transcript = Commitment.expand_transcript Bytes.empty cm_map in
    let (proof, _) = prove prv transcript cm_map z_map f_map in
    (prv, vrf, transcript, z_map, proof)
end

module External = struct
  module PC = Plonk.Kzg_pack
  module Auxiliary = Auxiliary (PC)

  (* d = polynomial’s degree, t = number of evaluations points, nb_poly_per_points = number of polynomial evaluated at each point *)
  let test_prove_verify () =
    let d = 20 in
    let t = 5 in
    let nb_poly_per_points = 10 in
    let (prv, vrf, transcript, z_map, proof) =
      Auxiliary.build_proof d t nb_poly_per_points
    in
    let v = PC.verify vrf transcript z_map (Auxiliary.dummy_cm prv) proof in
    assert v
end

module Internal = struct
  module PC = Plonk.Kzg_pack.Make (Plonk.Kzg) (Plonk.Pack)
  module Auxiliary = Auxiliary (PC)
  open PC

  let update_answer_list (n, e) l =
    let rec aux acc = function
      | [] -> None
      | (nn, _) :: tl when nn = n -> Some (List.rev_append acc ((nn, e) :: tl))
      | h :: tl -> aux (h :: acc) tl
    in
    aux [] l

  let update_answer x (n, e) answer =
    let l = Scalar_map.find x answer in
    match update_answer_list (n, e) l with
    | Some l -> Scalar_map.add x l answer
    | None -> answer

  let update_unpacked_eval x (n, e) unpacked_eval =
    SMap.map (update_answer x (n, e)) unpacked_eval

  let test_prove_verify_fake_pack () =
    let d = 20 in
    let t = 5 in
    let nb_poly_per_points = 10 in
    let (prv, vrf, transcript, z_map, (answer, proof)) =
      Auxiliary.build_proof d t nb_poly_per_points
    in
    let packed_proofs = {proof.packed_proofs with proof = None} in
    let fake_proof = {proof with packed_proofs} in
    let dummy_cm = Commitment.commit prv SMap.empty in
    let v = verify vrf transcript z_map dummy_cm (answer, fake_proof) in
    assert (not v)

  let test_prove_verify_fake_unpacked_answer () =
    let d = 20 in
    let t = 5 in
    let nb_poly_per_points = 10 in
    let (prv, vrf, transcript, z_map, (answer, proof)) =
      Auxiliary.build_proof d t nb_poly_per_points
    in
    let fake_proof =
      (* Let’s switch two unpacked evaluations *)
      let unpacked_evaluations = proof.unpacked_evaluations in
      let bindings = SMap.bindings unpacked_evaluations in
      let (name1, p1) = List.hd bindings in
      let (name2, p2) = List.nth bindings 1 in
      let unpacked_evaluations = SMap.add name1 p2 unpacked_evaluations in
      let unpacked_evaluations = SMap.add name2 p1 unpacked_evaluations in
      {proof with unpacked_evaluations}
    in
    let dummy_cm = Commitment.commit prv SMap.empty in
    let v = verify vrf transcript z_map dummy_cm (answer, fake_proof) in
    assert (not v)

  let test_prove_verify_fake_answer () =
    let d = 20 in
    let t = 5 in
    let nb_poly_per_points = 10 in
    let (prv, vrf, transcript, z_map, (answer, proof)) =
      Auxiliary.build_proof d t nb_poly_per_points
    in
    let (fake_answer, fake_proof) =
      (* Let’s change an evaluation in both answers & proof *)
      let (x, list) = Scalar_map.choose answer in
      let ((name1, _p1), list) = (List.hd list, List.tl list) in
      let (_name2, p2) = List.hd list in
      let answer = Scalar_map.add x ((name1, p2) :: list) answer in
      let (pc_answer, pcp) = proof.pc_proof in
      let proof =
        let pc_answer = update_answer x (name1, p2) pc_answer in
        let unpacked_evaluations =
          update_unpacked_eval x (name1, p2) proof.unpacked_evaluations
        in
        {
          pc_proof = (pc_answer, pcp);
          unpacked_evaluations;
          packed_proofs = proof.packed_proofs;
        }
      in
      (answer, proof)
    in
    let dummy_cm = Commitment.commit prv SMap.empty in
    let v = verify vrf transcript z_map dummy_cm (fake_answer, fake_proof) in
    assert (not v)
end

let tests =
  List.map
    (fun (name, f) ->
      Alcotest.test_case name `Quick (fun () -> Plonk.Multicore.with_pool f))
    [
      ("test_prove_verify", External.test_prove_verify);
      ("test_prove_verify_fake_pack", Internal.test_prove_verify_fake_pack);
      ( "test_prove_verify_fake_unpacked_answer",
        Internal.test_prove_verify_fake_unpacked_answer );
      ("test_prove_verify_fake_answer", Internal.test_prove_verify_fake_answer);
    ]
