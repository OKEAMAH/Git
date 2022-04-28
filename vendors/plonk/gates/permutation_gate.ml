module Permutation_gate_impl (PP : Polynomial_protocol.Polynomial_protocol_sig) =
struct
  module PP = PP
  module MP = PP.MP
  module Domain = PP.PC.Polynomial.Domain
  module Poly = PP.PC.Polynomial.Polynomial
  module Scalar = PP.PC.Scalar
  module Commitment = PP.PC.Commitment
  module Fr_generation = PP.PC.Fr_generation
  module Evaluations = PP.Evaluations

  let monomial_of_list = SMap.monomial_of_list

  let z = "Z"

  (* element preprocessed and known by both prover and verifier *)
  type public_parameters = {
    g_map_perm_PP : Poly.t SMap.t;
    cm_g_map_perm_PP : Commitment.t SMap.t;
    s_poly_map : Poly.t SMap.t;
    cm_s_poly_map : Commitment.t SMap.t;
    permutation : int array;
  }

  let srs_size ~zero_knowledge ~n = if zero_knowledge then n + 9 else n

  let one = Scalar.one

  let zero = Scalar.zero

  let mone = Scalar.negate one

  let quadratic_non_residues = Fr_generation.build_quadratic_non_residues 8

  let get_k k =
    if k < 8 then quadratic_non_residues.(k)
    else raise (Invalid_argument "Permutation.get_k : k must be lower than 8.")

  (* prime n-th roots of unity (g_2_i^(2^i)=1)
     n is of form 2^i
      generator is an nth root of unity
      permutations = array ; permutations.(i) = σ(i)
  *)

  (* Returns the list of monomial corresponding to the permutation identity*)
  let gate_identity ~prefix wires_name beta gamma =
    let wires_name = Array.map (fun x -> prefix ^ x) wires_name in
    (* Returns for a given tbit and position the labels for the permutation identity, as well as the gamma and beta coefficient *)
    let choose_list wires_name nb n =
      let index = string_of_int (n + 1) in
      match nb with
      | 0 ->
          let f = wires_name.(n) in
          (true, f, f, 0, 0)
      | 1 -> (true, "Si" ^ index, prefix ^ "Ss" ^ index, 1, 0)
      | 2 -> (false, "", "", 0, 1)
      | _ -> raise (Failure "choose_list: Error in ternary decomposition")
    in
    (* Returns the ternary decomposition of a number $nb$ as a $length_array$-element long int list*)
    let ternary nb length_array =
      let rec cpt_three acc length n =
        match n with
        | 0 -> (acc, length)
        | _ -> cpt_three ((n mod 3) :: acc) (length + 1) (n / 3)
      in
      let (suffix, suffix_length) = cpt_three [] 0 nb in
      List.rev_append
        (List.init (length_array - suffix_length) (fun _ -> 0))
        suffix
    in
    let nb_wires = Array.length wires_name in
    let array_betas = Fr_generation.powers (nb_wires + 1) beta in
    let array_gammas = Fr_generation.powers (nb_wires + 1) gamma in
    let size_identity = Z.(to_int (pow (of_int 3) nb_wires)) in
    let rec compute_identity_zfg acc size =
      let rec cpt_mnmls (acc_z, acc_zg, acc_b, acc_g) base3 ctr =
        match base3 with
        | t :: sub3 ->
            let (add, item_z, item_zg, b, g) = choose_list wires_name t ctr in
            let acc_b = acc_b + b in
            let acc_g = acc_g + g in
            let acc_z = if add then item_z :: acc_z else acc_z in
            let acc_zg = if add then item_zg :: acc_zg else acc_zg in
            cpt_mnmls (acc_z, acc_zg, acc_b, acc_g) sub3 (ctr + 1)
        | [] ->
            let coeff = Scalar.mul array_betas.(acc_b) array_gammas.(acc_g) in
            ( (SMap.monomial_of_list acc_z, coeff),
              (SMap.monomial_of_list acc_zg, Scalar.negate coeff) )
      in
      if size = size_identity then acc
      else
        let i_base3 = ternary size nb_wires in
        let (mnml_z, mnml_zg) =
          cpt_mnmls ([prefix ^ "Z"], [prefix ^ "Zg"], 0, 0) i_base3 0
        in
        compute_identity_zfg (mnml_z :: mnml_zg :: acc) (size + 1)
    in
    let identity_zfg = MP.Polynomial.of_list (compute_identity_zfg [] 0) in
    let identity_l1_z =
      MP.Polynomial.of_list
        [
          (SMap.monomial_of_list ["L1"; prefix ^ "Z"], one);
          (SMap.monomial_of_list ["L1"], mone);
        ]
    in
    SMap.of_list
      [(prefix ^ "Perm.a", identity_l1_z); (prefix ^ "Perm.b", identity_zfg)]

  (* v_map must contain all polynomials that are not involved in permutation checking ;
     those involved in permutation checking are fl, fr, fo *)
  let v_map ~prefix generator =
    let g_poly = Poly.of_coefficients [(generator, 1)] in
    (* (name of h∘v, (name of h, value of v))
       h∘v name will be used in identities
       h name is the name of the polynomial in g_map or f_map to compose with v
    *)
    SMap.singleton (prefix ^ "Zg") (prefix ^ "Z", g_poly)

  module Preprocessing = struct
    (* returns l1 polynomial such that l1(generator) = 1 & l1(a) = 0 for all a != generator in H *)
    let l1 domain =
      let size_domain = Domain.length domain in
      let scalar_list =
        Array.append
          Fr_generation.[|fr_of_int_safe 0; fr_of_int_safe 1|]
          Array.(init (size_domain - 2) (fun _ -> zero))
      in
      Evaluations.interpolation_fft2 domain scalar_list

    (* returns [sid_0, …, sid_k] *)
    let sid_list_non_quadratic_residues size =
      if size > 8 then
        raise (Failure "sid_list_non_quadratic_residues: sid list too long")
      else List.init size (fun i -> Poly.of_coefficients [(get_k i, 1)])

    let sid_map_non_quadratic_residues_prover size =
      if size > 8 then
        raise (Failure "sid_map_non_quadratic_residues: sid map too long")
      else
        SMap.of_list
          (List.init size (fun i ->
               let k = get_k i in
               ("Si" ^ string_of_int (i + 1), Poly.of_coefficients [(k, 1)])))

    (* Add a [not_committed] variant to represent Scalar.mul k x.(0) *)
    type PP.not_committed += MulK of Evaluations.scalar

    let () =
      (* NB: do not change tag, it will break the encoding *)
      let open Encodings in
      PP.register_nc_eval_and_encoding
        (function
          | MulK k -> Some (fun x_array -> Scalar.mul k x_array.(0)) | _ -> None)
        ~title:"permutation"
        ~tag:1
        fr_encoding
        (function MulK k -> Some k | _ -> None)
        (fun k -> MulK k)

    let sid_map_non_quadratic_residues_verifier size =
      if size > 8 then
        raise (Failure "sid_map_non_quadratic_residues: sid map too long")
      else
        SMap.of_list
          (List.init size (fun i ->
               let k = get_k i in
               ("Si" ^ string_of_int (i + 1), MulK k)))

    let evaluations_sid size domain_evals =
      SMap.of_list
        (List.init size (fun i ->
             let k = get_k i in
             let evals =
               Evaluations.mul_by_scalar k (Evaluations.of_domain domain_evals)
             in
             ("Si" ^ string_of_int (i + 1), evals)))

    let ssigma_map_non_quadratic_residues ~prefix permutation domain size =
      let n = Domain.length domain in
      let ssigma_map =
        SMap.of_list
          (List.init size (fun i ->
               let offset = i * n in
               let coeff_list =
                 Array.init n (fun j ->
                     let s_ij = permutation.(offset + j) in
                     let coeff = get_k (s_ij / n) in
                     let index = s_ij mod n in
                     Scalar.mul coeff (Domain.get domain index))
               in
               ( prefix ^ "Ss" ^ string_of_int (i + 1),
                 Evaluations.interpolation_fft2 domain coeff_list )))
      in
      ssigma_map
  end

  module Permutation_poly = struct
    (* compute f' & g' = (f + β×Sid + γ) & (g + β×Sσ + γ) products with Z *)
    let compute_prime beta gamma evaluations wires_names s_names z_name n =
      let wires_names = Array.to_list wires_names in
      let (res_name, evaluations) =
        let f_fold (acc_name, evaluations) wire_name s_name =
          let res_name = acc_name ^ "*" ^ wire_name ^ "_prime" in
          let (comp, acc_name) =
            if acc_name = "Zg" then (1, "Z") else (0, acc_name)
          in
          let evaluations =
            let evaluations =
              Evaluations.linear_update_map
                ~evaluations
                ~poly_names:[wire_name; s_name]
                ~linear_coeffs:[one; beta]
                ~add_constant:gamma
                ~name_result:("partial" ^ res_name)
                ()
            in
            Evaluations.mul_update_map
              ~evaluations
              ~poly_names:["partial" ^ res_name; acc_name]
              ~composition_gx:([0; comp], n)
              ~name_result:res_name
              ()
          in
          (res_name, evaluations)
        in
        List.fold_left2 f_fold (z_name, evaluations) wires_names s_names
      in
      (res_name, evaluations)

    (* evaluations must contain z’s evaluation *)
    let precompute_perm_identity_poly wires_name beta gamma evaluations n =
      let identity_zfg =
        let nb_wires = Array.length wires_name in
        (* changes f (resp g) array to f'(resp g') array, and multiply them together
            and with z (resp zg) *)
        let sid_names =
          List.init nb_wires (fun i -> "Si" ^ string_of_int (i + 1))
        in
        let (f_name, evaluations) =
          compute_prime beta gamma evaluations wires_name sid_names "Z" n
        in
        let ss_names =
          List.init nb_wires (fun i -> "Ss" ^ string_of_int (i + 1))
        in
        let (g_name, evaluations) =
          compute_prime beta gamma evaluations wires_name ss_names "Zg" n
        in
        Evaluations.linear
          ~evaluations
          ~poly_names:[f_name; g_name]
          ~linear_coeffs:[one; mone]
          ()
      in
      let identity_l1_z =
        let evaluations =
          Evaluations.linear_update_map
            ~evaluations
            ~poly_names:["Z"]
            ~add_constant:mone
            ~name_result:"Z - 1"
            ()
        in

        Evaluations.mul ~evaluations ~poly_names:["L1"; "Z - 1"] ()
      in
      SMap.of_list [("Perm.a", identity_l1_z); ("Perm.b", identity_zfg)]

    (*TODO : do this in evaluation*)
    let compute_Z s domain beta gamma values indices blinds =
      let size_domain = Domain.length domain in
      let scalar_list_Z =
        (* function takes as input the wires' indices (a b et c)
           and outputs f&gi= (x_i + beta*stuff + gamma)×
           acc contient fi/gi *)
        let func (acc, i, zi_min_1) indices_list =
          let gi = Domain.get domain i in
          let fgi index stuff =
            Scalar.(values.(index) + (beta * stuff) + gamma)
          in
          let make_list func =
            List.mapi (fun j index -> fgi index (func j)) indices_list
          in
          let f_list =
            let func j = Scalar.(get_k j * gi) in
            make_list func
          in
          let g_list =
            let func j =
              let sj = s.((j * size_domain) + i) in
              Scalar.(
                get_k (Int.div sj size_domain)
                * Domain.get domain (sj mod size_domain))
            in
            make_list func
          in
          let prod_list l =
            List.fold_left (fun acc li -> Scalar.(acc * li)) one l
          in
          let f_prod = prod_list f_list in
          let g_prod = prod_list g_list in
          let f_over_g = Scalar.div_exn f_prod g_prod in
          let zi = Scalar.mul zi_min_1 f_over_g in
          (zi :: acc, i + 1, zi)
        in
        let tail_list = List.map snd SMap.(bindings (map List.tl indices)) in
        let (z_list, _, z0) = List.fold_leftn func ([one], 1, one) tail_list in
        z0 :: List.rev (List.tl z_list) |> Array.of_list
      in

      let z_poly = Evaluations.interpolation_fft2 domain scalar_list_Z in
      match blinds with
      | None -> z_poly
      | Some b ->
          let p_poly =
            Poly.of_coefficients [(b.(0), 2); (b.(1), 1); (b.(2), 0)]
          in
          let zs_poly = Poly.of_coefficients [(one, size_domain); (mone, 0)] in
          Poly.(add (mul zs_poly p_poly) z_poly)
  end

  (* max degree needed is the degree of Perm.b, which is sum of wire’s degree plus z degree *)
  let polynomials_degree ~nb_wires = nb_wires + 1

  (* d = polynomials’ max degree
     n = generator’s order
     Returns SRS of decent size, preprocessed polynomials for permutation and
     their commitments (g_map_perm, cm_g_map_perm (="L1" -> L₁, preprocessed
     polynomial for verify perm’s identity), s_poly_map, cm_s_poly_map) & those
     for PP (g_map_PP, cm_g_map_PP)
     permutation for ssigma_list computation is deducted of cycles
     Details for SRS size :
       max size needed is deg(T)+1
       v polynomials all have degree 1
       according to identities_list_perm[0], t has max degree of Z×fL×fR×fO ;
       interpolation makes polynomials of degree n-1, so Z has degree of X²×Zh =
       X²×(X^n - 1) which is n+2, and each f has degree of X×Zh so n+1
       As a consequence, deg(T)-deg(Zs) = (n+2)+3(n+1) - n = 3n+5
       (for gates’ identity verification, max degree is degree of qM×fL×fR which
       is (n-1)+(n+1)+(n+1) < 3n+5)
  *)
  let preprocessing ?(prefix = "") ~domain ~permutation ~nb_wires () =
    Preprocessing.ssigma_map_non_quadratic_residues
      ~prefix
      permutation
      domain
      nb_wires

  let sid_not_committed = Preprocessing.sid_map_non_quadratic_residues_verifier

  let common_preprocessing ~compute_l1 ~domain ~nb_wires ~domain_evals =
    let sid_evals = Preprocessing.evaluations_sid nb_wires domain_evals in
    let sid_query =
      let sid_func =
        Preprocessing.sid_map_non_quadratic_residues_verifier nb_wires
      in
      PP.{empty_verifier_query with not_committed = sid_func}
    in
    let g_map_perm_PP =
      if not compute_l1 then SMap.empty
      else SMap.singleton "L1" (Preprocessing.l1 domain)
    in
    (g_map_perm_PP, sid_evals, sid_query)

  let prover_query ?(prefix = "") ~wires_name ~generator ~beta ~gamma
      ~evaluations ~n () =
    PP.
      {
        v_map = v_map ~prefix generator;
        precomputed_polys =
          Permutation_poly.precompute_perm_identity_poly
            wires_name
            beta
            gamma
            evaluations
            n;
      }

  let verifier_query ?(compute_sid = true) ?(prefix = "") ~wires_name ~generator
      ~beta ~gamma ~nb_wires () =
    PP.
      {
        v_map = v_map ~prefix generator;
        identities = gate_identity ~prefix wires_name beta gamma;
        not_committed =
          (if compute_sid then
           Preprocessing.sid_map_non_quadratic_residues_verifier nb_wires
          else SMap.empty);
      }

  let f_map_contribution ~permutation ~values ~indices ~blinds ~beta ~gamma
      ~domain =
    let z_poly =
      Permutation_poly.compute_Z
        permutation
        domain
        beta
        gamma
        values
        indices
        blinds
    in
    SMap.of_list [(z, z_poly)]
end

module type Permutation_gate_sig = sig
  module PP : Polynomial_protocol.Polynomial_protocol_sig

  val srs_size : zero_knowledge:bool -> n:int -> int

  val polynomials_degree : nb_wires:int -> int

  val common_preprocessing :
    compute_l1:bool ->
    domain:PP.PC.Polynomial.Domain.t ->
    nb_wires:int ->
    domain_evals:PP.Evaluations.domain ->
    PP.PC.Polynomial.Polynomial.t SMap.t
    * PP.Evaluations.t SMap.t
    * PP.verifier_query

  val preprocessing :
    ?prefix:string ->
    domain:PP.PC.Polynomial.Domain.t ->
    permutation:int array ->
    nb_wires:int ->
    unit ->
    PP.PC.Polynomial.Polynomial.t SMap.t

  val prover_query :
    ?prefix:string ->
    wires_name:string array ->
    generator:PP.PC.Scalar.t ->
    beta:PP.PC.Scalar.t ->
    gamma:PP.PC.Scalar.t ->
    evaluations:PP.Evaluations.t SMap.t ->
    n:int ->
    unit ->
    PP.prover_query

  val verifier_query :
    ?compute_sid:bool ->
    ?prefix:string ->
    wires_name:string array ->
    generator:PP.PC.Scalar.t ->
    beta:PP.PC.Scalar.t ->
    gamma:PP.PC.Scalar.t ->
    nb_wires:int ->
    unit ->
    PP.verifier_query

  val f_map_contribution :
    permutation:int array ->
    values:PP.PC.Scalar.t array ->
    indices:int list SMap.t ->
    blinds:PP.PC.Scalar.t array option ->
    beta:PP.PC.Scalar.t ->
    gamma:PP.PC.Scalar.t ->
    domain:PP.PC.Polynomial.Domain.t ->
    PP.PC.Polynomial.Polynomial.t SMap.t
end

module Permutation_gate (PP : Polynomial_protocol.Polynomial_protocol_sig) :
  Permutation_gate_sig with module PP = PP =
  Permutation_gate_impl (PP)
