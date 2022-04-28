(* Our version of SnarkPack for PLONK *)

module type Aggregator = sig
  module Scalar = Bls12_381.Fr
  module G1 = Bls12_381.G1
  module G2 = Bls12_381.G2
  module GT = Bls12_381.GT
  module Pairing = Bls12_381.Pairing

  (* Public parameters *)
  type prover_public_parameters

  type verifier_public_parameters

  val verifier_public_parameters_encoding :
    verifier_public_parameters Data_encoding.t

  (* Data to be aggregated *)
  type data = G1.t

  (* Commitment to the data *)
  type commitment = GT.t * GT.t

  val commitment_encoding : commitment Data_encoding.t

  (* Randomness used to pack the data, usually derived from a commitment to it *)
  type randomness = Scalar.t

  (* Packed/aggregated data *)
  type packed = G1.t

  val packed_encoding : packed Data_encoding.t

  (* Proof that the data was correctly aggregated *)
  type proof

  val proof_encoding : proof Data_encoding.t

  type setup_params

  val setup :
    ?state:Random.State.t ->
    int ->
    prover_public_parameters * verifier_public_parameters

  val get_setup_params : prover_public_parameters -> setup_params

  val public_parameters_to_bytes : prover_public_parameters -> Bytes.t

  val commit : ?start:int -> prover_public_parameters -> data list -> commitment

  val bytes_of_commitment : commitment -> Bytes.t

  val prove_single :
    prover_public_parameters ->
    commitment ->
    randomness ->
    data list ->
    packed * proof

  val prove :
    prover_public_parameters ->
    commitment SMap.t ->
    randomness ->
    data list SMap.t ->
    packed SMap.t * proof

  val verify_single :
    verifier_public_parameters ->
    commitment ->
    randomness ->
    packed * proof ->
    bool

  val verify :
    verifier_public_parameters ->
    commitment SMap.t ->
    randomness ->
    packed SMap.t * proof ->
    bool
end

module Pack_impl = struct
  module Scalar = Bls12_381.Fr
  module G1 = Bls12_381.G1
  module G2 = Bls12_381.G2
  module GT = Bls12_381.GT
  module Pairing = Bls12_381.Pairing
  module Fr_generation = Fr_generation.Make (Scalar)
  module Polynomial = Polynomial
  module Poly = Polynomial.Polynomial

  type prover_public_parameters = {
    length : int;
    srs2_s : G2.t list;
    srs2_t : G2.t list;
    g1_s : G1.t;
    g1_t : G1.t;
  }

  type verifier_public_parameters = {g1_s : G1.t; g1_t : G1.t}

  let verifier_public_parameters_encoding :
      verifier_public_parameters Data_encoding.t =
    let open Encodings in
    Data_encoding.(
      conv
        (fun {g1_s; g1_t} -> (g1_s, g1_t))
        (fun (g1_s, g1_t) -> {g1_s; g1_t})
        (obj2 (req "g1_s" g1_encoding) (req "g1_t" g1_encoding)))

  type data = G1.t

  type commitment = GT.t * GT.t

  let commitment_encoding : commitment Data_encoding.t =
    let open Encodings in
    Data_encoding.tup2 gt_encoding gt_encoding

  type randomness = Scalar.t

  type packed = G1.t

  let packed_encoding = Encodings.g1_encoding

  type ipa_proof = {
    srs_s_Ls : GT.t list;
    srs_s_Rs : GT.t list;
    srs_t_Ls : GT.t list;
    srs_t_Rs : GT.t list;
    r_Ls : G1.t list;
    r_Rs : G1.t list;
    a0 : G1.t;
    srs_s0 : G2.t;
    srs_t0 : G2.t;
  }

  let ipa_proof_encoding : ipa_proof Data_encoding.t =
    let open Encodings in
    let open Data_encoding in
    conv
      (fun {
             srs_s_Ls;
             srs_s_Rs;
             srs_t_Ls;
             srs_t_Rs;
             r_Ls;
             r_Rs;
             a0;
             srs_s0;
             srs_t0;
           } ->
        (srs_s_Ls, srs_s_Rs, srs_t_Ls, srs_t_Rs, r_Ls, r_Rs, a0, srs_s0, srs_t0))
      (fun ( srs_s_Ls,
             srs_s_Rs,
             srs_t_Ls,
             srs_t_Rs,
             r_Ls,
             r_Rs,
             a0,
             srs_s0,
             srs_t0 ) ->
        {srs_s_Ls; srs_s_Rs; srs_t_Ls; srs_t_Rs; r_Ls; r_Rs; a0; srs_s0; srs_t0})
      (obj9
         (req "srs_s_Ls" (list gt_encoding))
         (req "srs_s_Rs" (list gt_encoding))
         (req "srs_t_Ls" (list gt_encoding))
         (req "srs_t_Rs" (list gt_encoding))
         (req "r_Ls" (list g1_encoding))
         (req "r_Rs" (list g1_encoding))
         (req "a0" g1_encoding)
         (req "srs_s0" g2_encoding)
         (req "srs_t0" g2_encoding))

  let empty_ipa_proof =
    {
      srs_s_Ls = [];
      srs_s_Rs = [];
      srs_t_Ls = [];
      srs_t_Rs = [];
      r_Ls = [];
      r_Rs = [];
      a0 = G1.zero;
      srs_s0 = G2.zero;
      srs_t0 = G2.zero;
    }

  let reverse_ipa_proof p =
    {
      p with
      srs_s_Ls = List.rev p.srs_s_Ls;
      srs_s_Rs = List.rev p.srs_s_Rs;
      srs_t_Ls = List.rev p.srs_t_Ls;
      srs_t_Rs = List.rev p.srs_t_Rs;
      r_Ls = List.rev p.r_Ls;
      r_Rs = List.rev p.r_Rs;
    }

  type kzg_proof = G2.t * G2.t

  let kzg_proof_encoding : kzg_proof Data_encoding.t =
    let open Encodings in
    Data_encoding.tup2 g2_encoding g2_encoding

  type proof = ipa_proof * kzg_proof

  let proof_encoding : proof Data_encoding.t =
    Data_encoding.tup2 ipa_proof_encoding kzg_proof_encoding

  type setup_params = int

  let split len setup =
    try List.split_n len setup
    with Invalid_argument _ ->
      raise
        (Invalid_argument
           (Printf.sprintf
              "Pack.split : %d > %d (= srs size) ; make sure that Pack's \
               setup was generated with the correct size."
              len
              (List.length setup)))

  let powers ~one ~mul d x =
    Utils.build_array one (fun g -> mul g x) d |> Array.to_list

  let hash ~random ?(g1s = []) ?(g2s = []) ?(gts = []) ?(scalars = []) () =
    let bs1 = List.map G1.to_bytes g1s in
    let bs2 = List.map G2.to_bytes g2s in
    let bs3 = List.map GT.to_bytes gts in
    let bss = List.map Scalar.to_bytes scalars in
    let transcript = Bytes.concat Bytes.empty (bs1 @ bs2 @ bs3 @ bss) in
    let (seed, _) = Fr_generation.bytes_to_seed transcript in
    let state = Some (Random.State.make seed) in
    random ?state ()

  let ip_pairing list1 list2 =
    Pairing.(
      miller_loop (List.safe_combine list1 list2) |> final_exponentiation_exn)

  let setup ?state length =
    let s = Scalar.random ?state () in
    let t = Scalar.random () in
    let srs2_s = G2.(powers ~one ~mul length s) in
    let srs2_t = G2.(powers ~one ~mul length t) in
    let g1_s = G1.mul G1.one s in
    let g1_t = G1.mul G1.one t in
    ({length; srs2_s; srs2_t; g1_s; g1_t}, {g1_s; g1_t})

  let get_setup_params public_parameters = public_parameters.length

  let public_parameters_to_bytes {srs2_s; srs2_t; g1_s; g1_t; _} =
    hash ~random:Scalar.random ~g1s:[g1_s; g1_t] ~g2s:(srs2_s @ srs2_t) ()
    |> Scalar.to_bytes

  let commit ?(start = 0) pp data =
    ( ip_pairing data (split start pp.srs2_s |> snd),
      ip_pairing data (split start pp.srs2_t |> snd) )

  let bytes_of_commitment (cmt_s, cmt_t) =
    Bytes.cat (GT.to_bytes cmt_s) (GT.to_bytes cmt_t)

  let pack rs data =
    (* rs can be longer than needed *)
    let rs = fst @@ List.split_n (List.length data) rs in
    let packed = G1.pippenger (Array.of_list data) (Array.of_list rs) in
    packed

  let prove_but_not_pack pp cmt r data packed =
    (* Assert that the data length is a power of 2 *)
    let data_length = List.length data in
    if data_length = 0 then
      raise @@ Invalid_argument "[List.length data] cannot be 0" ;
    let nb_iterations = Z.(log2up @@ of_int data_length) in
    let next_2power = Int.shift_left 1 nb_iterations in
    let diff_from_2power = next_2power - data_length in
    let data =
      if diff_from_2power = 0 then data
      else (
        Format.printf
          "\nWARNING: [List.length data] is not a power of 2, we pad it\n" ;
        data @ List.init diff_from_2power (fun _i -> G1.zero))
    in
    let data_length = next_2power in
    let rs = Scalar.(powers ~one ~mul data_length r) in

    let rec loop remaining_iterations g_poly prev_u ipa_proof a b srs_s srs_t =
      if remaining_iterations = 0 then
        match (a, b, srs_s, srs_t) with
        | ([a0], [_], [srs_s0], [srs_t0]) ->
            (g_poly, reverse_ipa_proof {ipa_proof with a0; srs_s0; srs_t0})
        | _ -> raise @@ Invalid_argument "Aggregation: IPA loop"
      else
        let (a_left, a_right) = List.split_in_half a in
        let (b_left, b_right) = List.split_in_half b in
        let (srs_s_left, srs_s_right) = List.split_in_half srs_s in
        let (srs_t_left, srs_t_right) = List.split_in_half srs_t in

        let srs_s_L = ip_pairing a_left srs_s_right in
        let srs_s_R = ip_pairing a_right srs_s_left in

        let srs_t_L = ip_pairing a_left srs_t_right in
        let srs_t_R = ip_pairing a_right srs_t_left in

        let r_L = G1.pippenger (Array.of_list a_left) (Array.of_list b_right) in
        let r_R = G1.pippenger (Array.of_list a_right) (Array.of_list b_left) in

        let u =
          let g1s = [r_L; r_R] in
          let gts = [srs_s_L; srs_s_R; srs_t_L; srs_t_R] in
          Scalar.(hash ~random ~g1s ~gts ~scalars:[prev_u] ())
        in
        let u_inv = Scalar.inverse_exn u in

        let merge ~add ~mul x y = add (mul x u) (mul y u_inv) in
        let a' = List.map2 G1.(merge ~add ~mul) a_left a_right in
        let b' = List.map2 Scalar.(merge ~add ~mul) b_right b_left in
        let srs_s' = List.map2 G2.(merge ~add ~mul) srs_s_right srs_s_left in
        let srs_t' = List.map2 G2.(merge ~add ~mul) srs_t_right srs_t_left in
        let ipa_proof' =
          {
            ipa_proof with
            srs_s_Ls = srs_s_L :: ipa_proof.srs_s_Ls;
            srs_s_Rs = srs_s_R :: ipa_proof.srs_s_Rs;
            srs_t_Ls = srs_t_L :: ipa_proof.srs_t_Ls;
            srs_t_Rs = srs_t_R :: ipa_proof.srs_t_Rs;
            r_Ls = r_L :: ipa_proof.r_Ls;
            r_Rs = r_R :: ipa_proof.r_Rs;
          }
        in

        let xn = Int.shift_left 1 (remaining_iterations - 1) in
        let g'_poly = Poly.(g_poly * of_coefficients [(u_inv, 0); (u, xn)]) in

        loop (remaining_iterations - 1) g'_poly u ipa_proof' a' b' srs_s' srs_t'
    in

    let (srs2_t, _) = split data_length pp.srs2_t in
    let (srs2_s, _) = split data_length pp.srs2_s in
    let u_init =
      Scalar.(hash ~random ~g1s:[packed] ~gts:[fst cmt; snd cmt] ())
    in
    let (g, ipa_proof) =
      loop nb_iterations Poly.one u_init empty_ipa_proof data rs srs2_s srs2_t
    in

    let gts =
      ipa_proof.srs_s_Ls @ ipa_proof.srs_s_Rs @ ipa_proof.srs_t_Ls
      @ ipa_proof.srs_t_Rs
    in
    let g1s = ipa_proof.a0 :: ipa_proof.r_Ls @ ipa_proof.r_Rs in
    let g2s = [ipa_proof.srs_s0; ipa_proof.srs_t0] in
    let rho = Scalar.(hash ~random ~g1s ~g2s ~gts ()) in
    let h = Poly.(division_x_z (g - (constant @@ evaluate g rho)) rho) in
    let h_coeffs = Poly.to_dense_coefficients h in
    let kzg_proof_s = G2.pippenger (Array.of_list srs2_s) h_coeffs in
    let kzg_proof_t = G2.pippenger (Array.of_list srs2_t) h_coeffs in

    let proof = (ipa_proof, (kzg_proof_s, kzg_proof_t)) in
    proof

  let prove_single pp cmt r data =
    let rs = Scalar.(powers ~one ~mul (List.length data) r) in
    let packed = pack rs data in
    (packed, prove_but_not_pack pp cmt r data packed)

  let prove pp cmts_map r data_map =
    if SMap.is_empty data_map then raise @@ Failure "data_map cannot be empty" ;

    let (cmts_s, cmts_t) =
      List.split @@ List.map snd (SMap.bindings cmts_map)
    in
    let datas = List.map snd @@ SMap.bindings data_map in
    let n = List.length datas in
    let max_length_datas = List.fold_left max 0 List.(map length datas) in

    (* Pad with zeros at the tail so that all datas have the same length *)
    let padded_datas =
      let tail n = List.init (max_length_datas - n) @@ Fun.const G1.zero in
      List.map (fun l -> l @ tail (List.length l)) datas
    in

    let delta = Scalar.(hash ~random ~gts:(cmts_s @ cmts_t) ()) in
    let deltas = Scalar.(powers ~one ~mul n delta) in
    let data =
      let safe_tl = function _ :: tl -> tl | _ -> [] in
      assert (List.length padded_datas > 0) ;
      List.fold_left2
        (fun acc data_list d ->
          List.map2 (fun a b -> G1.(add a (mul b d))) acc data_list)
        (List.hd padded_datas)
        (safe_tl padded_datas)
        (safe_tl deltas)
    in

    let f acc gt d = GT.(add acc (mul gt d)) in
    let cmt_s = List.fold_left2 f GT.zero cmts_s deltas in
    let cmt_t = List.fold_left2 f GT.zero cmts_t deltas in
    let rs = Scalar.(powers ~one ~mul max_length_datas r) in
    let packed = pack rs data in
    let packed_map = SMap.map (pack rs) data_map in
    (packed_map, prove_but_not_pack pp (cmt_s, cmt_t) r data packed)

  let verify_single pp (cmt_s, cmt_t) r (packed, (ipa_proof, kzg_proof)) =
    let u_init = Scalar.(hash ~random ~g1s:[packed] ~gts:[cmt_s; cmt_t] ()) in
    let (us_rev, _) =
      List.fold_left6
        (fun (us, prev_u) srs_s_L srs_s_R srs_t_L srs_t_R r_L r_R ->
          let u =
            let g1s = [r_L; r_R] in
            let gts = [srs_s_L; srs_s_R; srs_t_L; srs_t_R] in
            Scalar.(hash ~random ~g1s ~gts ~scalars:[prev_u] ())
          in
          (u :: us, u))
        ([], u_init)
        ipa_proof.srs_s_Ls
        ipa_proof.srs_s_Rs
        ipa_proof.srs_t_Ls
        ipa_proof.srs_t_Rs
        ipa_proof.r_Ls
        ipa_proof.r_Rs
    in

    let us = List.rev us_rev in

    (* g(X) := (u₁⁻¹ + u₁ X^{2ᵏ⁻¹}) · (u₂⁻¹ + u₂ X^{2ᵏ⁻²}) ··· (uₖ⁻¹ + uₖ X) *)
    let eval_g x =
      List.fold_left
        (fun (acc, x_power) u ->
          let term = Scalar.(inverse_exn u + (u * x_power)) in
          Scalar.(acc * term, square x_power))
        (Scalar.one, x)
        us_rev
      |> fst
    in

    (* Verify the IPA proof *)
    let r0 = eval_g r in

    (* Computes [init + sum_j (u_j^2 L_j + u_j^{-2} R_j)] *)
    let rhs ~init ~add ~mul us gLs gRs =
      let f acc u gL gR =
        let u2 = Scalar.square u in
        let u2_inv = Scalar.inverse_exn u2 in
        add acc @@ add (mul gL u2) (mul gR u2_inv)
      in
      List.fold_left3 f init us gLs gRs
    in

    let lhs_srs_s = Pairing.pairing ipa_proof.a0 ipa_proof.srs_s0 in
    let rhs_srs_s =
      GT.(rhs ~init:cmt_s ~add ~mul us ipa_proof.srs_s_Ls ipa_proof.srs_s_Rs)
    in

    let lhs_srs_t = Pairing.pairing ipa_proof.a0 ipa_proof.srs_t0 in
    let rhs_srs_t =
      GT.(rhs ~init:cmt_t ~add ~mul us ipa_proof.srs_t_Ls ipa_proof.srs_t_Rs)
    in

    let lhs_r = G1.mul ipa_proof.a0 r0 in
    let rhs_r =
      G1.(rhs ~init:packed ~add ~mul us ipa_proof.r_Ls ipa_proof.r_Rs)
    in

    let ipa_ok =
      GT.eq lhs_srs_s rhs_srs_s && GT.eq lhs_srs_t rhs_srs_t
      && G1.eq lhs_r rhs_r
    in

    (* Verify the KZG proof *)
    let gts =
      ipa_proof.srs_s_Ls @ ipa_proof.srs_s_Rs @ ipa_proof.srs_t_Ls
      @ ipa_proof.srs_t_Rs
    in
    let g1s = ipa_proof.a0 :: ipa_proof.r_Ls @ ipa_proof.r_Rs in
    let g2s = [ipa_proof.srs_s0; ipa_proof.srs_t0] in
    let rho = Scalar.(hash ~random ~g1s ~g2s ~gts ()) in
    let m_v = eval_g rho |> Scalar.negate in
    let delta = Scalar.random () in
    let srs_st0 = G2.(add ipa_proof.srs_s0 (mul ipa_proof.srs_t0 delta)) in
    let m_v' = G2.mul G2.one Scalar.(mul m_v (add one delta)) in
    let rho_g1 = G1.mul G1.one @@ Scalar.negate rho in
    let (kzg_proof_s, kzg_proof_t) = kzg_proof in

    let rhs =
      ip_pairing
        G1.[negate one; add pp.g1_s rho_g1; add pp.g1_t rho_g1]
        G2.[add srs_st0 m_v'; kzg_proof_s; mul kzg_proof_t delta]
    in
    let kzg_ok = GT.is_zero rhs in

    ipa_ok && kzg_ok

  let verify pp cmts_map r (packed_map, proof) =
    let cmt_pairs = List.map snd (SMap.bindings cmts_map) in
    let (cmts_s, cmts_t) = List.split cmt_pairs in
    let n = List.length cmt_pairs in

    let delta = Scalar.(hash ~random ~gts:(cmts_s @ cmts_t) ()) in
    let deltas = Scalar.(powers ~one ~mul n delta) in

    let f acc gt d = GT.(add acc (mul gt d)) in
    let cmt_s = List.fold_left2 f GT.zero cmts_s deltas in
    let cmt_t = List.fold_left2 f GT.zero cmts_t deltas in

    let packed =
      List.fold_left2
        (fun acc (_, p) d -> G1.(add acc (mul p d)))
        G1.zero
        (SMap.bindings packed_map)
        deltas
    in
    verify_single pp (cmt_s, cmt_t) r (packed, proof)
end

include (Pack_impl : Aggregator)
