open Bls
open Utils

module Commit = struct
  exception SRS_too_short of string

  (* This function is used to raise a more helpful error message *)
  let pippenger pippenger ps ss =
    try pippenger ?start:None ?len:None ps ss
    with Invalid_argument s ->
      raise (Invalid_argument ("Utils.pippenger : " ^ s))

  let with_affine_array_1 g =
    pippenger G1.pippenger_with_affine_array (G1.to_affine_array g)

  let commit_single pippenger zero srs_size srs p =
    let p_size = 1 + Poly.degree p in
    if p_size = 0 then zero
    else if p_size > srs_size then
      raise
        (SRS_too_short
           (Printf.sprintf
              "commit : Polynomial degree, %i, exceeds srs length, %i."
              p_size
              srs_size))
    else pippenger srs p

  let with_srs1 srs p =
    commit_single Srs_g1.pippenger G1.zero (Srs_g1.size srs) srs p

  let with_srs2 srs p =
    commit_single Srs_g2.pippenger G2.zero (Srs_g2.size srs) srs p
end

module Polynomial_commitment = struct
  module Public_parameters = struct
    (* Structured Reference String
       - srs1 : [[1]₁, [x¹]₁, …, [x^(d-1)]₁] ;
       - encoding_1 : [1]₂;
       - encoding_x : [x]₂ *)
    type prover = {srs1 : Srs_g1.t; encoding_1 : G2.t; encoding_x : G2.t}
    [@@deriving repr]

    let to_bytes len srs =
      let open Utils.Hash in
      let st = init () in
      update st (G2.to_bytes srs.encoding_1) ;
      update st (G2.to_bytes srs.encoding_x) ;
      let srs1 = Srs_g1.to_array ~len srs.srs1 in
      Array.iter (fun key -> update st (G1.to_bytes key)) srs1 ;
      finish st

    type verifier = {encoding_1 : G2.t; encoding_x : G2.t} [@@deriving repr]

    type setup_params = int

    let setup_verifier srs_g2 =
      let encoding_1 = Srs_g2.get srs_g2 0 in
      let encoding_x = Srs_g2.get srs_g2 1 in
      {encoding_1; encoding_x}

    let setup_prover (srs_g1, srs_g2) =
      let {encoding_1; encoding_x} = setup_verifier srs_g2 in
      {srs1 = srs_g1; encoding_1; encoding_x}

    let setup _ (srs, _) =
      let prv = setup_prover srs in
      let vrf = setup_verifier (snd srs) in
      (prv, vrf)
  end

  module Commitment = struct
    type prover_public_parameters = Public_parameters.prover

    type secret = Poly.t SMap.t

    type t = G1.t SMap.t [@@deriving repr]

    type prover_aux = unit [@@deriving repr]

    let commit_single srs = Commit.with_srs1 Public_parameters.(srs.srs1)

    let commit ?all_keys:_ srs f_map =
      let cmt = SMap.map (commit_single srs) f_map in
      let prover_aux = () in
      (cmt, prover_aux)

    let cardinal cmt = SMap.cardinal cmt

    let rename f cmt =
      SMap.fold (fun key x acc -> SMap.add (f key) x acc) cmt SMap.empty

    let recombine cmt_list =
      List.fold_left
        (SMap.union (fun _k x _ -> Some x))
        (List.hd cmt_list)
        (List.tl cmt_list)

    let recombine_prover_aux _ = ()

    let empty = SMap.empty

    let empty_prover_aux = ()

    let of_list _ ~name l =
      let n = List.length l in
      ( SMap.(
          of_list
            (List.mapi (fun i c -> (Aggregation.add_prefix ~n ~i "" name, c)) l)),
        () )

    let to_map cm = cm
  end

  (* polynomials to be committed *)
  type secret = Commitment.secret

  (* maps evaluation point names to evaluation point values *)
  type query = Scalar.t SMap.t [@@deriving repr]

  (* maps evaluation point names to (map from polynomial names to evaluations) *)
  type answer = Scalar.t SMap.t SMap.t [@@deriving repr]

  type transcript = Bytes.t

  type proof = G1.t SMap.t [@@deriving repr]

  (* compute W := (f(x) - s) / (x - z), where x is the srs secret exponent,
     for every evaluation point [zname], key of the [query] map, where
       z := SMap.find zname query
       s := SMap.find zname batched_answer
       f := SMap.find zname batched_polys
     the computation is performed by first calculating polynomial
     (f(X) - s) / (X - z) and then committing to it using the srs.
     Here, f (respecitvely s) is a batched polynomial (respecively batched
     evaluation) of all polynomials (and their respective evaluations) that
     are evaluated at a common point z. They have been batched with the
     uniformly sampled randomness from [y_map], see {!sample_ymap} *)
  let compute_Ws srs batched_polys batched_answer query =
    SMap.mapi
      (fun x z ->
        let f = SMap.find x batched_polys in
        let s = SMap.find x batched_answer in
        (* WARNING: This modifies [batched_polys], but we won't use it again: *)
        Poly.sub_inplace f f @@ Poly.constant s ;
        let h = fst @@ Poly.division_xn f 1 (Scalar.negate z) in
        Commitment.commit_single srs h)
      query

  (* verify the KZG equation: e(F - [s]₁ + z W, [1]₂) = e(W, [x]₂)
     for every evaluation point [zname], key of the [query] map, where
       z := SMap.find zname query
       s := SMap.find zname s_map
       W := SMap.find zname w_map
     and F is computed as a linear combination (determined by [coeffs])
     of the commitments in [SMap.find zname cmt_map].
     All verification equations are checked at once by batching them
     with fresh randomness sampled in [r_map].
     The combination of [cmt_map] and other G1.mul is delayed as much
     as possible, in order to combine all of them with a single pippenger *)
  let verifier_check srs cmt_map coeffs query s_map w_map =
    let r_map = SMap.map (fun _ -> Scalar.random ()) w_map in
    let cmts = SMap.values cmt_map in
    let exponents =
      SMap.fold
        (fun x r exponents ->
          let x_coeffs = SMap.find x coeffs in
          SMap.mapi
            (fun name exp ->
              match SMap.find_opt name x_coeffs with
              | None -> exp
              | Some c -> Scalar.(exp + (r * c)))
            exponents)
        r_map
        (SMap.map (fun _ -> Scalar.zero) cmt_map)
      |> SMap.values
    in
    let s =
      SMap.fold
        (fun x r s -> Scalar.(sub s (r * SMap.find x s_map)))
        r_map
        Scalar.zero
    in
    let w_left_exps =
      List.map (fun (x, r) -> Scalar.mul r @@ SMap.find x query)
      @@ SMap.bindings r_map
    in
    let w_right_exps =
      (* We negate them before the pairing_check, which is done on the lhs *)
      SMap.values r_map |> List.map Scalar.negate
    in

    let ws = SMap.values w_map in
    let left =
      Commit.with_affine_array_1
        (Array.of_list @@ (G1.one :: ws) @ cmts)
        (Array.of_list @@ (s :: w_left_exps) @ exponents)
    in
    let right =
      Commit.with_affine_array_1 (Array.of_list ws) (Array.of_list w_right_exps)
    in
    Public_parameters.[(left, srs.encoding_1); (right, srs.encoding_x)]
    |> Pairing.pairing_check

  (* return a map between evaluation point names (from [query]) and uniformly
     sampled scalars, used for batching; also return an updated transcript *)
  let sample_ys transcript query =
    let n = SMap.cardinal query in
    let ys, transcript = Fr_generation.random_fr_list transcript n in
    let y_map =
      SMap.of_list (List.map2 (fun y name -> (name, y)) ys @@ SMap.keys query)
    in
    (y_map, transcript)

  (* On input a scalar map [y_map] and [answer], e.g.,
      y_map := { 'x0' -> y₀; 'x1' -> y₁ }
     answer := { 'x0' -> { 'a' -> a(x₀); 'b' -> b(x₀); 'c' -> c(x₀); ... };
                 'x1' -> { 'a' -> a(x₁); 'c' -> c(x₁); 'd' -> d(x₁); ... }; }
     outputs a map of batched evaluations:
       { 'x0' -> a(x₀) + y₀b(x0) + y₀²c(x₀) + ...);
         'x1' -> a(x₁) + y₁c(x1) + y₁²d(x₁) + ...); }
     and a map of batching coefficients:
       { 'x0' -> { 'a' -> 1; 'b' -> y₀; 'c' -> y₀²; ... };
         'x1' -> { 'a' -> 1; 'c' -> y₁; 'd' -> y₁²; ... }; } *)
  let batch_answer y_map answer =
    let couples =
      SMap.mapi
        (fun x s_map ->
          let y = SMap.find x y_map in
          let s, coeffs, _yk =
            SMap.fold
              (fun name s (acc_s, coeffs, yk) ->
                let acc_s = Scalar.(add acc_s @@ mul yk s) in
                let coeffs = SMap.add name yk coeffs in
                let yk = Scalar.mul yk y in
                (acc_s, coeffs, yk))
              s_map
              (Scalar.zero, SMap.empty, Scalar.one)
          in
          (s, coeffs))
        answer
    in
    (SMap.map fst couples, SMap.map snd couples)

  (* On input batching coefficients [coeffs] and a map of polys [f_map], e.g.,
      coeffs := { 'x0' -> { 'a' -> 1; 'b' -> y₀; 'c' -> y₀²; ... };
                  'x1' -> { 'a' -> 1; 'c' -> y₁; 'd' -> y₁²; ... }; }
       f_map := { 'a' -> a(X); 'b' -> b(X); 'c' -> c(X); ... },
     outputs a map of batched polynomials:
       { 'x0' -> a(X) + y₀b(X) + y₀²c(X) + ...);
         'x1' -> a(X) + y₁c(X) + y₁²d(X) + ...); } *)
  let batch_polys coeffs f_map =
    let polys = SMap.bindings f_map in
    SMap.map
      (fun f_coeffs ->
        let coeffs, polys =
          List.filter_map
            (fun (name, p) ->
              Option.map (fun c -> (c, p)) @@ SMap.find_opt name f_coeffs)
            polys
          |> List.split
        in
        Poly.linear polys coeffs)
      coeffs

  let prove_single srs transcript f_map query answer =
    let y_map, transcript = sample_ys transcript query in
    let batched_answer, coeffs = batch_answer y_map answer in
    let batched_polys = batch_polys coeffs f_map in
    let proof = compute_Ws srs batched_polys batched_answer query in
    (proof, Transcript.expand proof_t proof transcript)

  let verify_single srs transcript cmt_map query answer proof =
    let y_map, transcript = sample_ys transcript query in
    let batched_answer, coeffs = batch_answer y_map answer in
    let b = verifier_check srs cmt_map coeffs query batched_answer proof in
    (b, Transcript.expand proof_t proof transcript)

  (* group functions allow [prove] and [verify] rely on [prove_single] and
     [verify_single] respectively *)

  let group_secrets : secret list -> secret = SMap.union_disjoint_list

  let group_cmts : Commitment.t list -> Commitment.t = SMap.union_disjoint_list

  let group_queries : query list -> query =
   fun query_list ->
    let union =
      SMap.union (fun _ z z' ->
          if Scalar.eq z z' then Some z
          else
            failwith "group_query: equal query names must map to equal values")
    in
    List.fold_left union (List.hd query_list) (List.tl query_list)

  let group_answers : answer list -> answer =
   fun answer_list ->
    List.fold_left
      (SMap.union (fun _ m1 m2 -> Some (SMap.union_disjoint m1 m2)))
      (List.hd answer_list)
      (List.tl answer_list)

  (* evaluate every polynomial in [f_map] at all evaluation points in [query] *)
  let evaluate : Poly.t SMap.t -> query -> answer =
   fun f_map query ->
    SMap.map (fun z -> SMap.map (fun f -> Poly.evaluate f z) f_map) query

  let prove srs transcript f_map_list _prover_aux_list query_list answer_list =
    let transcript = Transcript.list_expand query_t query_list transcript in
    let transcript = Transcript.list_expand answer_t answer_list transcript in
    let f_map = group_secrets f_map_list in
    let query = group_queries query_list in
    let answer = group_answers answer_list in
    prove_single srs transcript f_map query answer

  let verify srs transcript cmt_map_list query_list answer_list proof =
    let transcript = Transcript.list_expand query_t query_list transcript in
    let transcript = Transcript.list_expand answer_t answer_list transcript in
    let cmt_map = group_cmts cmt_map_list in
    let query = group_queries query_list in
    let answer = group_answers answer_list in
    verify_single srs transcript cmt_map query answer proof
end

module DegreeCheck = struct
  type prover_public_parameters = Srs_g1.t

  type verifier_public_parameters = {srs_0 : G2.t; srs_n_d : G2.t}

  (* p(X) of degree n. Max degree that can be committed: d, which is also the
     SRS's length - 1. We take d = t.max_polynomial_length - 1 since we don't want to commit
     polynomials with degree greater than polynomials to be erasure-encoded.

     We consider the bilinear groups (G_1, G_2, G_T) with G_1=<g> and G_2=<h>.
     - Commit (p X^{d-n}) such that deg (p X^{d-n}) = d the max degree
     that can be committed
     - Verify: checks if e(commit(p), commit(X^{d-n})) = e(commit(p X^{d-n}), h)
     using the commitments for p and p X^{d-n}, and computing the commitment for
     X^{d-n} on G_2. *)

  (* Proves that degree(p) < t.max_polynomial_length *)
  (* FIXME https://gitlab.com/tezos/tezos/-/issues/4192

     Generalize this function to pass the slot_size in parameter. *)
  let prove ~max_commit ~max_degree srs p =
    (* Note: this reallocates a buffer of size (Srs_g1.size t.srs.raw.srs_g1)
       (2^21 elements in practice), so roughly 100MB. We can get rid of the
       allocation by giving an offset for the SRS in Pippenger. *)
    Poly.mul_xn p (max_commit - max_degree) Scalar.zero |> Commit.with_srs1 srs

  (* Verifies that the degree of the committed polynomial is < t.max_polynomial_length *)
  let verify {srs_0; srs_n_d} cm proof =
    (* checking that cm * committed_offset_monomial = proof *)
    Pairing.pairing_check [(G1.negate cm, srs_n_d); (proof, srs_0)]
end

(* [open_at_0 p] returns (p - p(0))/X *)
let open_at_0 p =
  let q, r =
    Poly.(division_xn (p - constant (evaluate p Scalar.zero)) 1 Scalar.zero)
  in
  assert (Poly.is_zero r) ;
  q
