module Make
    (PC : Kzg.Polynomial_commitment_sig
            with type Commitment.t = Bls12_381.G1.t SMap.t)
    (Pack : Pack.Aggregator) =
struct
  module Scalar = PC.Scalar
  module Polynomial = PC.Polynomial
  module Domain = Polynomial.Domain
  module Poly = Polynomial.Polynomial
  module Scalar_map = PC.Scalar_map
  module Fr_generation = PC.Fr_generation

  type secret = Poly.t SMap.t

  type query = string list Scalar_map.t

  type packed_proof = {
    commitments : Pack.commitment SMap.t;
    answers : Pack.packed SMap.t;
    proof : Pack.proof option;
  }

  let packed_proof_encoding : packed_proof Data_encoding.t =
    Data_encoding.(
      conv
        (fun {commitments; answers; proof} -> (commitments, answers, proof))
        (fun (commitments, answers, proof) -> {commitments; answers; proof})
        (obj3
           (req "commitments" (SMap.encoding Pack.commitment_encoding))
           (req "answers" (SMap.encoding Pack.packed_encoding))
           (req "proof" (option Pack.proof_encoding))))

  type proof = {
    pc_proof : PC.answer * PC.proof;
    (* todo check the security*)
    unpacked_evaluations : PC.answer SMap.t;
    packed_proofs : packed_proof;
  }

  let proof_encoding : proof Data_encoding.t =
    Data_encoding.(
      conv
        (fun {pc_proof; unpacked_evaluations; packed_proofs} ->
          (pc_proof, unpacked_evaluations, packed_proofs))
        (fun (pc_proof, unpacked_evaluations, packed_proofs) ->
          {pc_proof; unpacked_evaluations; packed_proofs})
        (obj3
           (req "pc_proof" (tup2 PC.answer_encoding PC.proof_encoding))
           (req "unpacked_evaluations" (SMap.encoding PC.answer_encoding))
           (req "packed_proofs" packed_proof_encoding)))

  type answer = (string * Scalar.t) list Scalar_map.t

  let answer_encoding = PC.answer_encoding

  type transcript = Bytes.t

  module Public_parameters = struct
    type prover = {
      pc_public_parameters : PC.Public_parameters.prover;
      pack_public_parameters : Pack.prover_public_parameters;
    }

    type verifier = {
      pc_public_parameters : PC.Public_parameters.verifier;
      pack_public_parameters : Pack.verifier_public_parameters;
    }

    let verifier_encoding : verifier Data_encoding.t =
      Data_encoding.(
        conv
          (fun {pc_public_parameters; pack_public_parameters} ->
            (pc_public_parameters, pack_public_parameters))
          (fun (pc_public_parameters, pack_public_parameters) ->
            {pc_public_parameters; pack_public_parameters})
          (obj2
             (req "pc_public_parameters" PC.Public_parameters.verifier_encoding)
             (req
                "pack_public_parameters"
                Pack.verifier_public_parameters_encoding)))

    type setup_params = int * int

    let setup ?state setup_params =
      let (prover, verifier) = PC.Public_parameters.setup ?state setup_params in
      let (pack_prover, pack_verifier) = Pack.setup ?state (snd setup_params) in
      let (prover : prover) =
        {pc_public_parameters = prover; pack_public_parameters = pack_prover}
      in
      ( prover,
        {
          pc_public_parameters = verifier;
          pack_public_parameters = pack_verifier;
        } )

    let get_d (public_parameters : prover) =
      PC.Public_parameters.get_d public_parameters.pc_public_parameters

    let import setup_params srsfile =
      let (prover, verifier) =
        PC.Public_parameters.import setup_params srsfile
      in
      let (pack_prover, pack_verifier) = Pack.setup (snd setup_params) in
      let (prover : prover) =
        {pc_public_parameters = prover; pack_public_parameters = pack_prover}
      in
      ( prover,
        {
          pc_public_parameters = verifier;
          pack_public_parameters = pack_verifier;
        } )

    let export _public_params _file = failwith "not implemented"

    let to_bytes ({pc_public_parameters; pack_public_parameters} : prover) =
      Fr_generation.hash_bytes
        [
          PC.Public_parameters.to_bytes pc_public_parameters;
          Pack.public_parameters_to_bytes pack_public_parameters;
        ]
  end

  module Commitment = struct
    type t = {
      pc : PC.Commitment.t;
      pack : (PC.Commitment.t * Pack.commitment) SMap.t;
    }

    let encoding : t Data_encoding.t =
      Data_encoding.(
        conv
          (fun {pc; pack} -> (pc, pack))
          (fun (pc, pack) -> {pc; pack})
          (obj2
             (req "pc" PC.Commitment.encoding)
             (req
                "pack"
                (SMap.encoding
                   (tup2 PC.Commitment.encoding Pack.commitment_encoding)))))

    let expand_transcript transcript cmt =
      Bytes.cat transcript (Data_encoding.Binary.to_bytes_exn encoding cmt)

    let commit ?pack_name (pp : Public_parameters.prover) f_map =
      let pc = PC.Commitment.commit pp.pc_public_parameters f_map in
      match pack_name with
      | Some name ->
          let cm_list = List.map snd @@ SMap.bindings pc in
          let pack_cmt = Pack.commit pp.pack_public_parameters cm_list in
          {pc = SMap.empty; pack = SMap.singleton name (pc, pack_cmt)}
      | None -> {pc; pack = SMap.empty}

    let merge cmt_1 cmt_2 =
      let pc = SMap.union_disjoint cmt_1.pc cmt_2.pc in
      let pack = SMap.union_disjoint cmt_1.pack cmt_2.pack in
      {pc; pack}

    (* FIXME: what Anne-Laure expected is to apply it to the cm_t_map and get
       the number of T polynomials with this cardinal thing *)
    let cardinal {pc; _} = SMap.cardinal pc
  end

  type extra_cmts = Commitment.t

  type auxiliary = (Commitment.t * Scalar.t) * (Commitment.t * Scalar.t)

  let expand_vmap v_map pack_v_map = SMap.union_disjoint v_map pack_v_map

  let is_pack name =
    let pack = "packed_" in
    let len_prefix = String.length pack in
    if len_prefix >= String.length name then false
    else
      let prefix = String.sub name 0 len_prefix in
      prefix = pack

  let smap_find name map fun_name map_name =
    match SMap.find_opt name map with
    | None ->
        failwith
          (Printf.sprintf
             "Kzg_Pack.%s : '%s' not found in %s"
             fun_name
             name
             map_name)
    | Some poly -> poly

  module Prover = struct
    let get_polys_to_pack secret pack_cmts =
      SMap.map
        (fun (cm_map, pack_cm) ->
          let f_map =
            SMap.mapi
              (fun name _ -> smap_find name secret "get_polys_to_pack" "secret")
              cm_map
          in
          (f_map, pack_cm))
        pack_cmts

    (* Computes (\sum_i r^i poly_i) for all polynomials in the map,
       based on the order induced by the map keys. *)
    let pack_polys r poly_map =
      SMap.fold
        (fun _name poly (acc_poly, rk) ->
          (Poly.(acc_poly + mul_by_scalar rk poly), Scalar.mul rk r))
        poly_map
        (Poly.zero, Scalar.one)
      |> fst

    let remove_cmts_from_query query pack_cmts =
      let cm_to_remove =
        SMap.fold
          (fun _ (cm_map, _) smap ->
            SMap.union (fun _ a _ -> Some a) cm_map smap)
          pack_cmts
          SMap.empty
      in
      let res =
        Scalar_map.map
          (List.partition (fun name -> not (SMap.mem name cm_to_remove)))
          query
      in
      (Scalar_map.map fst res, Scalar_map.map snd res)

    let compute_unpacked_evaluations query poly_to_pack_map =
      let compute_list_evals poly_map x name_list =
        List.filter_map
          (fun name ->
            match SMap.find_opt name poly_map with
            | None -> None
            | Some poly -> Some (name, Poly.evaluate poly x))
          name_list
      in
      SMap.map
        (fun (poly_map, _) ->
          Scalar_map.mapi (compute_list_evals poly_map) query)
        poly_to_pack_map

    let build_answer pc_answer unpacked_evaluations =
      let answer_union = PC.Scalar_map.union (fun _x l1 l2 -> Some (l1 @ l2)) in
      let unpacked_evaluations =
        SMap.fold
          (fun _ answer acc -> answer_union answer acc)
          unpacked_evaluations
          Scalar_map.empty
      in
      (* We want packed polynomial at the end of answer’s lists in order to keep consistency with KZG ; thus PP.Verifier.build_common_h_map won’t fail because answer’s format will remain the same for both PCs *)
      answer_union unpacked_evaluations pc_answer
  end

  module Verifier = struct
    (* Computes (\sum_i r^i poly_i) for all polynomials in the map, based on
       the order induced by the map keys. *)

    (*Fix me*)
    let answer_proof_coherence answer
        {pc_proof = (pc_answer, _); unpacked_evaluations; _} =
      let pc_answer =
        Scalar_map.map
          (List.filter (fun (name, _) -> not (is_pack name)))
          pc_answer
      in
      let answer_reconstructed =
        Prover.build_answer pc_answer unpacked_evaluations
      in
      Scalar_map.equal
        (List.equal (fun (name1, eval1) (name2, eval2) ->
             name1 = name2 && Scalar.eq eval1 eval2))
        answer
        answer_reconstructed

    let format_query answers = PC.Scalar_map.map (List.map fst) answers

    let packed_evals_consistency r proof pc_answer =
      let pack_evaluations r evaluations =
        List.fold_right
          (fun (_name, eval) acc -> PC.Scalar.((r * acc) + eval))
          evaluations
          PC.Scalar.zero
      in
      let check_unpacked_eval x list_eval name_pack answer_of_packed =
        match
          List.find_opt (fun (name_eval, _) -> name_eval = name_pack) list_eval
        with
        | None -> true
        | Some (_, answer_given) ->
            let evals_x =
              match Scalar_map.find_opt x answer_of_packed with
              | None ->
                  failwith
                    "Kzg_Pack.packed_eval_consistency : x not found in \
                     answer_of_packed"
              | Some e -> e
            in
            Scalar.eq (pack_evaluations r evals_x) answer_given
      in
      Scalar_map.for_all
        (fun x list_eval ->
          SMap.for_all
            (check_unpacked_eval x list_eval)
            proof.unpacked_evaluations)
        pc_answer
  end

  (* Where do we sample r? *)
  (* What we need for the prover:
     - All public parameters (pc and pack)
     - All polynomials (it would be enough to get f_wires and f_perm aggregated)
     - Query: evaluation schedule for the polynomials
     - C_wires, C_perm: Packed commitments (not really necessary, but it would be good to have it)
     - data committed in C_wires, C_perm (this can be extracted from all polys, but it is expensive to do it again)
  *)
  let prove (pp : Public_parameters.prover) transcript extra_cms query secret =
    (* Step 1b : compute r *)
    let (r, transcript) = Fr_generation.generate_single_fr transcript in

    let poly_to_pack_map =
      Prover.get_polys_to_pack secret Commitment.(extra_cms.pack)
    in

    (* Step 11a : compute the KZG secret polynomials *)
    let secret_kzg_pack =
      SMap.map
        (fun (f_map, _pack_cmt) -> Prover.pack_polys r f_map)
        poly_to_pack_map
    in

    (* Step 11b & 10 : KZG proof on packed values & compute batched witness
       polynomial evaluations. *)
    let (query_kzg, _query_to_eval) =
      Prover.remove_cmts_from_query query Commitment.(extra_cms.pack)
    in

    let (pc_proof, transcript) =
      let secret = SMap.union_disjoint secret_kzg_pack secret in
      PC.prove
        pp.pc_public_parameters
        transcript
        Commitment.(extra_cms.pc)
        query_kzg
        secret
    in

    (* Step 5b & 6 : Compute Packed values & prove their correctness *)
    let data_pack_cm_list =
      SMap.map
        (fun (cm_map, pack_cm) ->
          (List.map snd @@ SMap.bindings cm_map, pack_cm))
        Commitment.(extra_cms.pack)
    in

    let data_map = SMap.map fst data_pack_cm_list in
    let cmts_map = SMap.map snd data_pack_cm_list in

    let packed_proofs =
      if SMap.is_empty data_pack_cm_list then
        {commitments = SMap.empty; answers = SMap.empty; proof = None}
      else
        let (answers, proof) =
          Pack.prove pp.pack_public_parameters cmts_map r data_map
        in
        {commitments = cmts_map; answers; proof = Some proof}
    in

    (* Step 10a : compute individual witness evaluations *)
    let unpacked_evaluations =
      Prover.compute_unpacked_evaluations query poly_to_pack_map
    in

    (* removed packed answer *)
    let pc_answer =
      Scalar_map.map
        (List.filter (fun (name, _) -> not (is_pack name)))
        (fst pc_proof)
    in
    let answer = Prover.build_answer pc_answer unpacked_evaluations in

    let proof = {pc_proof; unpacked_evaluations; packed_proofs} in

    ((answer, proof), transcript)

  (* cms must contain commitments that havn’t been given as extra_cm to the prover *)
  let verify (pp : Public_parameters.verifier) transcript _query cms
      (answer, proof) =
    let (r, transcript) = Fr_generation.generate_single_fr transcript in

    (* Step 5 : Pack.verify *)
    (* WARNING: make sure that no attack can follow from not giving a pack proof *)
    let {commitments; answers; proof = pack_proof} = proof.packed_proofs in
    let pack_verif =
      match pack_proof with
      | None -> SMap.is_empty commitments && SMap.is_empty answers
      | Some p ->
          Pack.verify pp.pack_public_parameters commitments r (answers, p)
    in

    (* Step 2a: KZG.verify proofs *)
    let kzg_verif =
      let cm_map =
        let cms = Commitment.(cms.pc) in
        SMap.union_disjoint_list [cms; answers]
      in
      let query = Verifier.format_query (fst proof.pc_proof) in
      PC.verify pp.pc_public_parameters transcript query cm_map proof.pc_proof
    in

    (* Step 1d : compute eta & eta_z (witness evaluations combination) *)
    let pc_answer = fst proof.pc_proof in

    let packed_evals_verif =
      Verifier.packed_evals_consistency r proof pc_answer
    in

    let answer_consistancy_verif =
      Verifier.answer_proof_coherence answer proof
    in
    pack_verif && kzg_verif && packed_evals_verif && answer_consistancy_verif
end

include (Make (Kzg) (Pack) : Kzg.Polynomial_commitment_sig)
