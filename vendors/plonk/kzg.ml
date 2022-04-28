(* Implements scheme described in section 3 ("A batched version of the KZG10 scheme") of article "PlonK: Permutations over Lagrange-bases for Oecumenical Non interactive arguments of Knowledge" by Ariel Gabizon, Zachary J. Williamson and Oana Ciobotaru of June 4, 2020, avaliable on https://eprint.iacr.org/2019/953.pdf *)

module Kzg_impl = struct
  (* F is a prime field represented by module Bls12_381.Fr
     G1, G2, GT are groups of same size as F and are represented by Bls12_381.G1 and Bls12_381.G2
   * e is a non-degenerate pairing : G1×G2 -> GT such as e(G1.one, G2.one) = GT.one
   *)

  module Scalar = Bls12_381.Fr
  module G1 = Bls12_381.G1
  module G2 = Bls12_381.G2
  module GT = Bls12_381.GT
  module Pairing = Bls12_381.Pairing
  module Fr_generation = Fr_generation.Make (Scalar)
  module Polynomial = Polynomial
  module Poly = Polynomial.Polynomial

  (* module scalar_map is used to represent query type, which will be represented as a map with keys in field F, bounded with a list of indexes of polynomials to compute with that key *)

  module Scalar_map = Map.Make (Scalar)

  let scalar_map_encoding :
      'a Data_encoding.t -> 'a Scalar_map.t Data_encoding.t =
   fun inner_enc ->
    let open Data_encoding in
    let to_list m = List.of_seq @@ Scalar_map.to_seq m in
    let of_list l = Scalar_map.of_seq @@ List.to_seq l in
    conv to_list of_list (list (tup2 Encodings.fr_encoding inner_enc))

  (* Polynomials hidden from verifier and only known by prover *)
  type secret = Poly.t SMap.t

  (* int lists are indexes of corresponding polynomials *)
  type query = string list Scalar_map.t

  let expand_vmap v_map _ = v_map

  (* Scalar associated to its evaluations *)
  type answer = (string * Scalar.t) list Scalar_map.t

  let answer_encoding : answer Data_encoding.t =
    Data_encoding.(
      scalar_map_encoding (list (tup2 string Encodings.fr_encoding)))

  type transcript = Bytes.t

  let pippenger ?(start = 0) ?len ps ss =
    try G1.pippenger ~start ?len ps ss
    with Invalid_argument s ->
      raise (Invalid_argument (Printf.sprintf "KZG.pippenger : %s" s))

  module Public_parameters = struct
    (* Structured Reference String
       - srs1 : [[x⁰]₁, [x¹]₁, …, [x^(d-1)]₁] ;
       - encoding_1 : [x⁰]₂;
       - encoding_x : [x]₂; d} for x∈F and d an int *)
    type prover = {
      srs1 : G1.t array;
      encoding_1 : G2.t;
      encoding_x : G2.t;
      d : int;
    }

    type verifier = {encoding_1 : G2.t; encoding_x : G2.t (* ; d : int *)}

    let verifier_encoding : verifier Data_encoding.t =
      let open Encodings in
      let open Data_encoding in
      conv
        (fun {encoding_1; encoding_x} -> (encoding_1, encoding_x))
        (fun (encoding_1, encoding_x) -> {encoding_1; encoding_x})
        (obj2 (req "encoding_1" g2_encoding) (req "encoding_x" g2_encoding))

    type setup_params = int * int

    let get_d srs = srs.d

    let create_srs1 d x =
      let xi = ref G1.one in
      Array.init d (fun _ ->
          let res = !xi in
          xi := G1.mul !xi x ;
          res)

    let encoding x = G1.mul G1.one x

    let encoding_2 x = G2.mul G2.one x

    let setup ?state (d, _) =
      let x = Scalar.random ?state () in
      ( {
          srs1 = create_srs1 d x;
          encoding_1 = G2.one;
          encoding_x = G2.mul G2.one x;
          d;
        },
        {encoding_1 = G2.one; encoding_x = G2.mul G2.one x} )

    let import (d, _) srsfile =
      (* Read bytes from file and convert to element of G1,
         raise exception on failure *)
      let read_g1 ic bytes_buf =
        Stdlib.really_input ic bytes_buf 0 G1.size_in_bytes ;
        G1.of_bytes_exn bytes_buf
      in
      (* Read bytes from file and convert to element of G2,
         raise exception on failure *)
      let read_g2 ic bytes_buf =
        Stdlib.really_input ic bytes_buf 0 G2.size_in_bytes ;
        G2.of_bytes_exn bytes_buf
      in
      let expected_size = (2 * G2.size_in_bytes) + (d * G1.size_in_bytes) in
      let ic = open_in srsfile in
      try
        if in_channel_length ic < expected_size then
          failwith "SRS asked too big" ;
        let bytes_buf = Bytes.create G2.size_in_bytes in
        let g2 = read_g2 ic bytes_buf in
        let g2x = read_g2 ic bytes_buf in
        let bytes_buf = Bytes.create G1.size_in_bytes in
        let srs1 = Array.init d (fun _ -> read_g1 ic bytes_buf) in
        close_in ic ;
        ( {srs1; encoding_1 = g2; encoding_x = g2x; d},
          {encoding_1 = g2; encoding_x = g2x} )
      with e ->
        close_in ic ;
        raise e

    let export srs srsfile =
      let oc = open_out_bin srsfile in
      let srs1 = srs.srs1 in
      let () = output_bytes oc (G2.to_bytes srs.encoding_1) in
      let () = output_bytes oc (G2.to_bytes srs.encoding_x) in
      let () = Array.iter (fun x -> output_bytes oc (G1.to_bytes x)) srs1 in
      close_out oc

    let to_bytes srs =
      let b1 =
        Bytes.concat Bytes.empty Array.(map G1.to_bytes srs.srs1 |> to_list)
      in
      let b2 =
        Bytes.cat (G2.to_bytes srs.encoding_1) (G2.to_bytes srs.encoding_x)
      in
      Fr_generation.hash_bytes [Bytes.cat b2 b1]
  end

  module Commitment = struct
    type t = G1.t SMap.t

    let encoding : t Data_encoding.t = SMap.encoding Encodings.g1_encoding

    let expand_transcript transcript cm_map =
      Bytes.cat transcript (Data_encoding.Binary.to_bytes_exn encoding cm_map)

    let commit_kate_amortized srs1 p =
      if p = [||] then G1.zero
      else if Array.(length p > length srs1) then
        raise
          (Failure
             (Printf.sprintf
                "Kzg.compute_encoded_polynomial : Polynomial degree, %i, \
                 exceeds srs’ length, %i."
                (Array.length p)
                (Array.length srs1)))
      else
        let s = Array.(sub srs1 0 (Array.length p)) in
        let res =
          Multicore.map2_one_chunk_per_core
            (fun ~start ~len -> pippenger ~start ~len)
            s
            p
        in
        List.fold_left G1.add G1.zero res

    let commit_single srs p =
      commit_kate_amortized
        Public_parameters.(srs.srs1)
        (Poly.to_dense_coefficients p)

    let commit ?pack_name:_ srs f_map = SMap.map (commit_single srs) f_map

    let merge cm1 cm2 = SMap.union_disjoint cm1 cm2

    let cardinal cmt = SMap.cardinal cmt
  end

  type extra_cmts = Commitment.t

  type proof = {proof : G1.t list; commitments : Commitment.t}

  let proof_encoding : proof Data_encoding.t =
    Data_encoding.(
      conv
        (fun {proof; commitments} -> (proof, commitments))
        (fun (proof, commitments) -> {proof; commitments})
        (obj2
           (req "proof" (list Encodings.g1_encoding))
           (req "commitments" Commitment.encoding)))

  let expand_transcript transcript w_list =
    Bytes.(cat transcript (concat empty (List.map G1.to_bytes w_list)))

  module Verifier = struct
    (*
     * for y, r ∈ F and l a list of (string, F elements)
     * computes F = r*Σ(γ^i)*li
     *)
    let compute_sum_y_l_F r y l =
      let f (sum, yi) (_name, c) = Scalar.(add sum (mul c yi), yi * y) in
      List.fold_left f Scalar.(zero, r) l |> fst

    (*
     * rk the k-th element of the r list
     * yk the k-th element of the γ list
     * cmk_list the k-th element of the cm list
     * sk_list the k-th element of the s list
     * computes Fk = rk(Σ(yk^i*cmki)-[Σ(yk^i*ski)]₁) term of F
     *)
    let compute_Fk rk yk cmk_list sk_list =
      let sum_cmi =
        let cmk_array = List.map snd cmk_list |> Array.of_list in
        let exponents_array =
          Utils.build_array rk Scalar.(mul yk) (Array.length cmk_array)
        in
        pippenger cmk_array exponents_array
      in
      let encoded_sum_sk =
        Public_parameters.encoding (compute_sum_y_l_F rk yk sk_list)
      in
      G1.(add sum_cmi (negate encoded_sum_sk))

    (*
     * r_list = list of r ∈ F, of length t
     * y_list = gamma_list cm_list of length t
     * cm_list = commit srs f_list, list of (cmi_name, cmi)
     * s_list = compute_s_list, list of si
     * returns F = (Σ(y₀^i*cmi₀)-[Σ(y₀^i*si₀)]₁) + r₁(Σ(y₁^i*cmi₁)-[Σ(y₁^i*si₁)]₁) + …
     *)
    let compute_F r_list y_list cm_list s_map =
      let (_, s_list) = List.split (Scalar_map.bindings s_map) in
      let f sum rk yk cmk_list sk_list =
        (* addition of Fk *)
        G1.add (compute_Fk rk yk cmk_list sk_list) sum
      in
      List.fold_left4 f G1.zero r_list y_list cm_list s_list

    (*
     * w_list is the list of Wi = [hi(x)]₁
     * f = compute_F
     * r_list rk’s list, ∀k, rk ∈ F
     * z_list zk’s list, ∀k, zk ∈ F
     * computes e(F + z₀r₀W₀ + z₁r₁W₁ + …, [1]₂) + e(-r₀W₀ - r₁W₁ - …, [x]₂)
     * returns true iff it is equal to GT.zero
     *)
    let verifying_function r_list z_list f w_list srs =
      (* list such as rzi=ri*zi *)
      let rz_list = List.map2 Scalar.mul r_list z_list in
      let w_array = Array.of_list w_list in
      (* Sum of ri*zi*Wi *)
      let rzw_sum = pippenger w_array (Array.of_list rz_list) in
      (* Sum of ri*Wi *)
      let rw_sum = pippenger w_array (Array.of_list r_list) in
      Pairing.pairing_check
        [
          (G1.add f rzw_sum, Public_parameters.(srs.encoding_1));
          (G1.negate rw_sum, Public_parameters.(srs.encoding_x));
        ]

    (* returns gamma_list & list of r^i ∈ F, of size t (size of z_list),
       gamma_list and r are generated from transcript *)
    let build_r_lists transcript t =
      let open Fr_generation in
      let (r, new_transcript) = Fr_generation.generate_single_fr transcript in

      (powers t r |> Array.to_list, new_transcript)
  end

  module Prover = struct
    (* zfs the map of z ∈ F bound to the polynomials to be evaluated at z
       returns ss = {z₀ -> [f₀⁰(z₀), f₁⁰(z₀), …] ; z₁ -> [f₀¹(z₁), f₁¹(z₁), …] ; …} *)
    let compute_ss zfs =
      let eval_z z f_list =
        List.map (fun (name, f) -> (name, Poly.evaluate f z)) f_list
      in
      Scalar_map.mapi eval_z zfs

    (*
     * z ∈ F
     * fi is the i-th polynomial related to z
     * yi = gamma^i
     * i the index of the hx term to compute
     * returns polynomial (y**i)[fi-fi(z)]₁
     *)
    let compute_z_hi_polynomial fi z yi =
      (* fi(z) *)
      let fi_z_poly = Poly.(constant (evaluate fi z)) in
      (* fi(X)-fi(z) *)
      let diff_poly = Poly.(sub fi fi_z_poly) in
      (* y^i*(fi(X)-fi(z)) *)
      Poly.mul_by_scalar yi diff_poly

    (*
     * f is a list of degree (d-1) or less polynomials related to z
     * z ∈ F
     * y = gamma
     * returns polynomial h = (1/X-z) Σ(y**i-1)[fi-fi(z)]₁
     *)
    let compute_z_h_polynomial f z y =
      let s (sum, yi) (_name, fi) =
        (* sum + (y^i)(fi(X)-fi(z)) *)
        (Poly.add sum (compute_z_hi_polynomial fi z yi), Scalar.mul yi y)
      in
      let (sum_poly, _) = List.fold_left s (Poly.zero, Scalar.one) f in
      Poly.division_x_z sum_poly z

    (*
      srs = gen d
      zfs the map of z ∈ F bound to the list of max degree (d-1) polynomials fi to be evaluated at z
      y_list = gamma_list com related to each zi
      x ∈ F
      returns W, the list of [h(x)]₁ related to each polynomial list f of f_list : (1/x-z) Σ(γ**i-1)[fi(x)-fi(z)]₁ = [h(x)]₁
     *)
    let compute_Ws srs zfs y_list =
      let compute_encoded_hz_in_list (z, f_list) y =
        let pz = compute_z_h_polynomial f_list z y in
        Commitment.commit_single srs pz
      in
      let zfs = Scalar_map.bindings zfs in
      List.map2 compute_encoded_hz_in_list zfs y_list
  end

  (* fs = {f₀_name -> f₀ ; f₁_name -> f₁ ; …}
     zs = {z₀ -> [f_names for z₀] ; …}
     returns [(z₀, [(f_name, f), …]), (z₁, [(f_name, f), …]), …]
     where (f_name, f) list with zi is the polynomial and their name to evaluate at zi
     Fails if a name in zs is not in fs
  *)
  let format_from_zs zs fs =
    let find names =
      let find name =
        match SMap.find_opt name fs with
        | None ->
            failwith
              (Format.sprintf
                 "Kzg.format_from_zs : \"%s\" in zs not found in fs."
                 name)
        | Some poly -> (name, poly)
      in
      List.map find names
    in
    Scalar_map.map find zs

  (*
   * fs is a map of polynomials’ name and their value
   * zs is the map of evaluation points associated with the names in fs of polynomials to be evaluated at this point
   * returns:
     - ss, the evaluation points associated with the list of (name of polynomial evaluated, their evaluations)
     - w_list, the proofs list of evaluations in ss
     - the new transcript
   *)
  let prove srs transcript extra_cms zs fs =
    let zfs = format_from_zs zs fs in
    let ss = Prover.compute_ss zfs in
    let transcript =
      Bytes.cat
        transcript
        (Data_encoding.Binary.to_bytes_exn answer_encoding ss)
    in
    let (ys, transcript) =
      Fr_generation.generate_random_fr_list transcript (Scalar_map.cardinal zfs)
    in
    let ws = Prover.compute_Ws srs zfs ys in
    let new_transcript = expand_transcript transcript ws in
    ((ss, {proof = ws; commitments = extra_cms}), new_transcript)

  (*
   * cms is a string map of polynomials names alongside their commits
   * returns true iff evaluations and proofs are correct
   *)
  let verify srs transcript zs g_cms (ss, {proof = ws; commitments}) =
    let cms = SMap.union_disjoint g_cms commitments in
    let nb_z = Scalar_map.cardinal zs in
    let zcms = format_from_zs zs cms in
    let (zs, cms) = List.split (Scalar_map.bindings zcms) in
    let transcript =
      Bytes.cat
        transcript
        (Data_encoding.Binary.to_bytes_exn answer_encoding ss)
    in
    let (ys, transcript) =
      Fr_generation.generate_random_fr_list transcript nb_z
    in
    let transcript = expand_transcript transcript ws in
    let (rs, _) = Verifier.build_r_lists transcript nb_z in
    let f = Verifier.compute_F rs ys cms ss in
    Verifier.verifying_function rs zs f ws srs
end

module type Polynomial_commitment_sig = sig
  module Scalar : Ff_sig.PRIME with type t = Bls12_381.Fr.t

  module Polynomial : Polynomial.S with type scalar = Scalar.t

  module Scalar_map : Map.S with type key = Scalar.t

  module Fr_generation :
    Fr_generation.Fr_generation_sig with type scalar = Scalar.t

  (* A set of named polynomials. *)
  type secret = Polynomial.Polynomial.t SMap.t

  (* The verifier asks the prover to evaluate its secret polynomials on a set of points.
     Each point has a list of names of polynomials that must be evaluated on it. *)
  type query = string list Scalar_map.t

  (* This functions merges the two v_map following the necessity of the Polynomial Commitment ; it is expected to be used in Main Protocol to merge the regular v_map with the pack v_map. Concretely, for KZG it just returns the first v_map unchanged and for Kzg_pack it is an union_disjoint *)
  val expand_vmap : 'a SMap.t -> 'a SMap.t -> 'a SMap.t

  type proof

  val proof_encoding : proof Data_encoding.t

  (* Same as query but to each polynomials is associated its evaluation. *)
  type answer = (string * Scalar.t) list Scalar_map.t

  val answer_encoding : answer Data_encoding.t

  type transcript = Bytes.t

  module Public_parameters : sig
    type prover

    type verifier

    val verifier_encoding : verifier Data_encoding.t

    type setup_params = int * int

    (* [setup ~state d] returns an SRS of size d generated randomly *)
    val setup : ?state:Random.State.t -> setup_params -> prover * verifier

    (* [get_d srs] returns the size of srs *)
    val get_d : prover -> int

    (* [import d srsfile] returns the SRS of size d imported from srsfile *)
    val import : setup_params -> string -> prover * verifier

    (* [export srs srsfile] writes srs in srsfile *)
    val export : prover -> string -> unit

    val to_bytes : prover -> Bytes.t
  end

  module Commitment : sig
    type t

    val encoding : t Data_encoding.t

    val expand_transcript : transcript -> t -> transcript

    val commit : ?pack_name:string -> Public_parameters.prover -> secret -> t

    val merge : t -> t -> t

    val cardinal : t -> int
  end

  type extra_cmts = Commitment.t

  val prove :
    Public_parameters.prover ->
    transcript ->
    extra_cmts ->
    query ->
    secret ->
    (answer * proof) * transcript

  val verify :
    Public_parameters.verifier ->
    transcript ->
    query ->
    Commitment.t ->
    answer * proof ->
    bool
end

include (
  Kzg_impl :
    Polynomial_commitment_sig with type Commitment.t = Bls12_381.G1.t SMap.t)
