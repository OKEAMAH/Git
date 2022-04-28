module Make (PP : Polynomial_protocol.Polynomial_protocol_sig) = struct
  module Scalar = PP.PC.Scalar
  module Domain = PP.PC.Polynomial.Domain
  module Poly = PP.PC.Polynomial.Polynomial
  module Evaluations = PP.Evaluations

  module Perm : Permutation_gate.Permutation_gate_sig with module PP = PP =
    Permutation_gate.Permutation_gate (PP)

  module Plook : Plookup_gate.Plookup_gate_sig with module PP = PP =
    Plookup_gate.Plookup_gate (PP)

  module Gates = Custom_gate.Custom_gate_impl (PP)
  module Commitment = PP.PC.Commitment
  module Fr_generation = Fr_generation.Make (Scalar)
  module SMap = SMap

  exception Entry_not_in_table = Plook.Entry_not_in_table

  exception Rest_not_null = Poly.Rest_not_null

  exception Wrong_transcript = PP.Wrong_transcript

  type scalar = Scalar.t

  type proof = {
    perm_and_plook : PP.PC.Commitment.t;
    wires_cm : PP.PC.Commitment.t;
    proof : PP.proof;
  }

  let proof_encoding : proof Data_encoding.t =
    Data_encoding.(
      conv
        (fun {perm_and_plook; wires_cm; proof} ->
          (perm_and_plook, wires_cm, proof))
        (fun (perm_and_plook, wires_cm, proof) ->
          {perm_and_plook; wires_cm; proof})
        (obj3
           (req "perm_and_plook" PP.PC.Commitment.encoding)
           (req "wires_cm" PP.PC.Commitment.encoding)
           (req "proof" PP.proof_encoding)))

  type transcript = PP.transcript

  let scalar_encoding = Encodings.fr_encoding

  let transcript_encoding : transcript Data_encoding.t = PP.transcript_encoding

  type prover_inputs = {public : scalar array; witness : scalar array}

  let empty_map = SMap.empty

  let one = Scalar.one

  let zero = Scalar.zero

  let minus_one = Scalar.negate one

  let sep = SMap.Aggregation.sep

  module IntSet = Set.Make (Int)

  (* key = int, intended to be binded to int set *)
  module IntMap = Map.Make (Int)

  module Partition = struct
    type t = IntSet.t IntMap.t

    (* Add binding (i, {e}) to a map from int to intset
       if there is no binding for i in map ;
       else, adds e to the set binded to i *)
    let add_IntMap i e map =
      let set =
        Option.value (IntMap.find_opt i map) ~default:IntSet.empty
        |> IntSet.add e
      in
      IntMap.add i set map

    (* Function returing {Ti} such that Ti = {j ∈ [List.length wire_indices * n]
       such that V[j] = i}, the partition on which the permutation is based
       Inputs:
       - wire_indices: the input list corresponding to the wires indices,
       e.g. [a; b; c] for an arithmetic circuit
       Outputs:
       - {Ti}
    *)
    let build_partition wire_indices =
      let v = List.(flatten (map snd (SMap.bindings wire_indices))) in
      let rec aux map j v =
        match v with
        | [] -> map
        | h :: t ->
            let new_map = add_IntMap h j map in
            aux new_map (j + 1) t
      in
      aux IntMap.empty 0 v

    (* same as cycles_to_permutation except that cycles is a map of int with sets as bindings *)
    let cycles_to_permutation_map_set kn cycles =
      (* cycles in permutation are ascendent,
           so set structure is not a problem because elements are in this order *)
      (* array initialisation *)
      let permutation = Array.make kn (-1) in
      (* filling array with cycle *)
      let set_cycle_in_permutation _ cycle =
        let n = IntSet.cardinal cycle in
        if n = 0 then failwith "cycles_to_permutation : empty cycle"
        else if n = 1 (* when cycle has 1 element e, it means that σ(e) = e *)
        then
          let e = IntSet.choose cycle in
          permutation.(e) <- e
        else
          (* cycle has two elements or more *)
          let aux e (i, prec, first) =
            if i = 0 then (1, e, e)
            else if i = n - 1 then
              let () = permutation.(prec) <- e in
              let () = permutation.(e) <- first in
              (n, e, first)
            else
              let () = permutation.(prec) <- e in
              (i + 1, e, first)
          in
          let _ = IntSet.fold aux cycle (0, -1, -1) in
          ()
      in
      let () = IntMap.iter set_cycle_in_permutation cycles in
      (* If cycles is a legit partition of [kn], all partition's cases must be filled,
           and no -1 must be left *)
      if Array.mem (-1) permutation then
        failwith "cycles is not a 'partition' of kn"
      else permutation
  end

  let module_list =
    [
      (module Gates.Constant_gate : Gates.Gate_base_sig);
      (module Gates.Public_gate);
      (module Gates.AddLeft_gate);
      (module Gates.AddRight_gate);
      (module Gates.AddOutput_gate);
      (module Gates.AddNextLeft_gate);
      (module Gates.AddNextRight_gate);
      (module Gates.AddNextOutput_gate);
      (module Gates.Multiplication_gate);
      (module Gates.X5_gate);
      (module Gates.AddWeierstrass_gate);
      (module Gates.AddEdwards_gate);
    ]

  let select_modules gates =
    let to_q_label m =
      let module M = (val m : Gates.Gate_base_sig) in
      M.q_label
    in
    List.filter (fun m -> SMap.mem (to_q_label m) gates) module_list

  let get_wires_names nb_wires =
    let alphabet = "abcdefghijklmnopqrstuvwxyz" in
    Array.init nb_wires (fun i -> Char.escaped alphabet.[i])

  module Prover = struct
    type prover_common_pp = {
      n : int;
      domain : Domain.t;
      pp_public_parameters : PP.prover_public_parameters;
      evaluations : Evaluations.t SMap.t;
      common_keys : string list;
    }

    type prover_circuit_pp = {
      circuit_size : int;
      nb_wires : int;
      gates : Scalar.t array SMap.t;
      tables : Scalar.t array list;
      wires : int array SMap.t;
      permutation : int array;
      evaluations : Evaluations.t SMap.t;
      alpha : Scalar.t;
      ultra : bool;
    }

    let build_blinds ~zero_knowledge ~module_list ~wires =
      if not zero_knowledge then (None, None, None)
      else
        let nb_blinds_wires =
          let additional_blinds =
            Gates.Gate_aggregator.aggregate_blinds ~module_list
          in
          (* 1 more blinds is added for the commitment evaluation *)
          SMap.(
            mapi
              (fun name _ ->
                match find_opt name additional_blinds with
                | None -> 1
                | Some k -> k + 1)
              wires)
        in
        let nb_all_blinds = SMap.fold (fun _ a b -> a + b) nb_blinds_wires 0 in
        let nb_blinds_permutation = 3 in
        let nb_blinds_lookup = 12 in
        let nb_first_blinds = nb_blinds_permutation + nb_blinds_lookup in
        let blinds_array =
          Array.init (nb_first_blinds + nb_all_blinds) (fun _ ->
              Scalar.random ())
        in
        (* We start at 3 to leave the first 3 for the permutation, and the next 12 for lookup (3 for Z, 3 for f, 3 for h₁, 3 for h₂). *)
        let i_base = ref nb_first_blinds in
        let wire_blinds =
          SMap.map
            (fun number_blind ->
              let blinds =
                List.init number_blind (fun i -> blinds_array.(i + !i_base))
              in
              i_base := !i_base + number_blind ;
              blinds)
            nb_blinds_wires
        in
        let permutation_blinds =
          Some (Array.sub blinds_array 0 nb_blinds_permutation)
        in
        let lookup_blinds =
          Some (Array.sub blinds_array nb_blinds_permutation nb_blinds_lookup)
        in
        (Some wire_blinds, permutation_blinds, lookup_blinds)

    (* Helper function blinding the wire polys
        Inputs:
        - n: the number of constraints in the circuits + the number of public inputs
        - blind_map: a list of random blinds
        - f_map: the polys to be blinded
        Outputs:
        (b_2*i X + b_2*i+1)*Zh(X) + f_i
    *)
    let blind_polys n blinds_map f_map =
      let zh = Poly.of_coefficients [(one, n); (minus_one, 0)] in
      let blinding_poly b_list =
        let p = Poly.of_coefficients (List.mapi (fun i b -> (b, i)) b_list) in
        Poly.mul p zh
      in
      SMap.(
        mapi
          (fun name f ->
            match find_opt name blinds_map with
            | None -> f
            | Some blinds -> Poly.(blinding_poly blinds + f))
          f_map)

    let enforce_wire_values wire_indices wire_values =
      SMap.pmap
        (fun l -> Array.map (fun index -> wire_values.(index)) l)
        wire_indices

    (* Compute the wire polynomials
       Inputs:
       - domain: the interpolation domain for polynomials of size n
       - wire_indices: the list corresponding to the wires indices,
       e.g. [a, b, c] for an arithmetic circuit
       - x: the values of the wires
       Outputs:
       - wire_polys, the list of wire polynomials,
       e.g. for a(X) = (b1*X +b2)*Z_H(X) + sum_n w_i Li(X)
    *)
    let compute_wire_polynomials n domain blinds wires =
      let unblinded_res =
        try SMap.pmap (fun w -> Evaluations.interpolation_fft2 domain w) wires
        with Invalid_argument _ ->
          failwith
            "Compute_wire_polynomial : x's length does not match with circuit. \
             Either your witness is too short, or some indexes in a, b or c \
             are greater than the witness size."
      in
      match blinds with
      | None -> unblinded_res
      | Some blinds_map -> blind_polys n blinds_map unblinded_res

    let pack_query generator =
      let g_poly = Poly.of_coefficients [(generator, 1)] in
      let x_poly = Poly.of_coefficients [(one, 1)] in
      let pack_v_map =
        SMap.of_list
          [
            ("packed_perm_and_plook_g", ("packed_perm_and_plook", g_poly));
            ("packed_perm_and_plook", ("packed_perm_and_plook", x_poly));
            ("packed_wires", ("packed_wires", x_poly));
          ]
      in
      let v_map = PP.PC.expand_vmap SMap.empty pack_v_map in
      PP.{empty_prover_query with v_map}

    type wires_data = {
      pp : prover_circuit_pp;
      wires_blinds :
        (scalar array SMap.t
        * Evaluations.polynomial SMap.t
        * scalar array option
        * scalar array option
        * scalar array
        * int array SMap.t)
        list;
      inputs : prover_inputs list;
      f_map : Evaluations.polynomial SMap.t;
    }

    let build_wires_map ?(zero_knowledge = true) common_pp circuit_name
        (pp, inputs) =
      let nb_proofs = List.length inputs in
      let len_prefix = SMap.Aggregation.compute_len_prefix ~nb_proofs in
      let module_list = select_modules pp.gates in
      (* Compute the list of wires related values and some blinds*)
      let wires_blinds =
        List.map
          (fun input ->
            let wires_values = input.witness in
            let wires_indices = pp.wires in
            let wires = enforce_wire_values wires_indices wires_values in
            let (wires_blinds, permutation_blinds, lookup_blinds) =
              build_blinds ~zero_knowledge ~module_list ~wires
            in
            let f_wires_map =
              compute_wire_polynomials
                common_pp.n
                common_pp.domain
                wires_blinds
                wires
            in
            ( wires,
              f_wires_map,
              permutation_blinds,
              lookup_blinds,
              wires_values,
              wires_indices ))
          inputs
      in
      (* Aggregate wires commitments for transcript.
         Everything is renamed here as wires are value dependant by definition.*)
      (* Step 1 : Building wires polynomial *)
      let extra_prefix =
        if circuit_name = "" then "" else circuit_name ^ SMap.Aggregation.sep
      in
      let f_map =
        SMap.Aggregation.merge_equal_set_of_keys
          ~extra_prefix
          ~len_prefix
          (List.map (fun (_, x, _, _, _, _) -> x) wires_blinds)
      in
      {pp; wires_blinds; inputs; f_map}

    let build_query (common_pp : prover_common_pp) beta_plonk gamma_plonk
        beta_plookup gamma_plookup generator circuit_name
        (pp, f_map_evals_list, inputs) =
      let g_evals = SMap.union_disjoint common_pp.evaluations pp.evaluations in
      let extra_prefix = if circuit_name = "" then "" else circuit_name ^ sep in
      let query_list =
        List.map2
          (fun (f_map, evaluations) inputs ->
            let evaluations = SMap.union_disjoint g_evals evaluations in
            let perm_query =
              Perm.prover_query
                ~prefix:extra_prefix
                ~wires_name:(get_wires_names pp.nb_wires)
                ~generator
                ~beta:beta_plonk
                ~gamma:gamma_plonk
                ~evaluations
                ~n:common_pp.n
            in
            let plookup_query () =
              if pp.ultra then
                Plook.prover_query
                  ~prefix:extra_prefix
                  ~wires_name:(get_wires_names pp.nb_wires)
                  ~generator
                  ~alpha:pp.alpha
                  ~beta:beta_plookup
                  ~gamma:gamma_plookup
                  ~f_map
                  ~ultra:pp.ultra
                  ~evaluations
                  ~n:common_pp.n
                  ()
              else PP.empty_prover_query
            in
            let gates_queries =
              Gates.Gate_aggregator.aggregate_prover_queries
                ~prefix:extra_prefix
                ~module_list:(select_modules pp.gates)
                ~public_inputs:inputs.public
                ~domain:common_pp.domain
                ~evaluations
            in
            let queries =
              Multicore.pmap
                (fun f -> f ())
                [perm_query; plookup_query; gates_queries]
            in
            PP.merge_prover_queries queries)
          f_map_evals_list
          inputs
      in
      (* Get the pre computed polynomials to avoid renaming them
         as we want to open them once only. *)
      let v_map = PP.((List.hd (query_list : PP.prover_query list)).v_map) in
      let common_keys =
        PP.update_common_keys_with_v_map common_pp.common_keys ~v_map
      in
      let nb_proofs = List.length inputs in
      let len_prefix = SMap.Aggregation.compute_len_prefix ~nb_proofs in
      (* Merge all queries without renaming pre computed polynomials
         as we want to open them once only. *)
      let aggregated_query =
        PP.merge_equal_set_of_keys_prover_queries
          ~extra_prefix
          ~len_prefix
          ~common_keys
          query_list
      in
      aggregated_query

    let build_all_f_wires_map ~zero_knowledge common_pp circuit_map_with_inputs
        =
      let all_circuit =
        SMap.mapi
          (build_wires_map ~zero_knowledge common_pp)
          circuit_map_with_inputs
      in
      let f_wires_map =
        SMap.(
          union_disjoint_list
            (List.map snd (bindings (map (fun x -> x.f_map) all_circuit))))
      in
      (f_wires_map, all_circuit)

    let build_f_map_evaluation_perm (cpp : prover_common_pp) beta_plonk
        gamma_plonk beta_plookup gamma_plookup circuit_name
        {pp; wires_blinds; inputs; _} =
      let domain_evals = Evaluations.get_domain cpp.evaluations in
      (* Computes the list of f_map contribution for all proofs *)
      (* Step 3b : compute permutation polynomial Z *)
      let f_map_evaluation_perm_list =
        List.map
          (fun ( wires,
                 f_wires_map,
                 permutation_blinds,
                 lookup_blinds,
                 wires_values,
                 wires_indices ) ->
            let f_perm () =
              Perm.f_map_contribution
                ~permutation:pp.permutation
                ~values:wires_values
                ~indices:(SMap.map Array.to_list wires_indices)
                ~blinds:permutation_blinds
                ~beta:beta_plonk
                ~gamma:gamma_plonk
                ~domain:cpp.domain
            in
            let f_plook () =
              if pp.ultra then
                Plook.f_map_contribution
                  ~wires:(SMap.map Array.to_list wires)
                  ~gates:(SMap.map Array.to_list pp.gates)
                  ~tables:pp.tables
                  ~blinds:lookup_blinds
                  ~alpha:pp.alpha
                  ~beta:beta_plookup
                  ~gamma:gamma_plookup
                  ~domain:cpp.domain
                  ~size_domain:cpp.n
                  ~circuit_size:pp.circuit_size
                  ~ultra:pp.ultra
              else empty_map
            in
            let (f_perm, f_plook) =
              Multicore.pmap (fun f -> f ()) [f_perm; f_plook] |> function
              | [a; b] -> (a, b)
              | _ -> assert false
            in
            let f_perm_and_plook = SMap.union_disjoint f_perm f_plook in
            let f_map = SMap.union_disjoint f_wires_map f_perm_and_plook in
            let evaluations =
              PP.Evaluations.compute_evaluations ~domain:domain_evals f_map
            in
            ((f_map, evaluations), f_perm_and_plook))
          wires_blinds
      in
      let f_map_evaluation_list = List.map fst f_map_evaluation_perm_list in
      let f_perm_and_plook =
        let nb_proofs = List.length inputs in
        let len_prefix = SMap.Aggregation.compute_len_prefix ~nb_proofs in

        let extra_prefix =
          if circuit_name = "" then "" else circuit_name ^ SMap.Aggregation.sep
        in
        SMap.Aggregation.merge_equal_set_of_keys
          ~extra_prefix
          ~len_prefix
          (List.map snd f_map_evaluation_perm_list)
      in
      ((pp, f_map_evaluation_list, inputs), f_perm_and_plook)

    let build_all_f_map_evaluation_perm pp beta_plonk gamma_plonk beta_plookup
        gamma_plookup circuit_and_wires =
      let all_circuit =
        SMap.mapi
          (build_f_map_evaluation_perm
             pp
             beta_plonk
             gamma_plonk
             beta_plookup
             gamma_plookup)
          circuit_and_wires
      in
      let f_map_evaluation_map = SMap.map fst all_circuit in
      let f_perm_and_plook =
        SMap.(
          union_disjoint_list (List.map snd (bindings (map snd all_circuit))))
      in
      (f_perm_and_plook, f_map_evaluation_map)

    let build_all_queries (common_pp : prover_common_pp) beta_plonk gamma_plonk
        beta_plookup gamma_plookup generator circuit_map =
      let map =
        SMap.mapi
          (build_query
             common_pp
             beta_plonk
             gamma_plonk
             beta_plookup
             gamma_plookup
             generator)
          circuit_map
      in
      PP.merge_prover_queries (List.map snd (SMap.bindings map))

    let prove_circuits_with_pool ?(zero_knowledge = true)
        ((common_pp, circuit_map), transcript) ~inputs =
      let circuit_map_with_inputs =
        try SMap.mapi (fun name i -> (SMap.find name circuit_map, i)) inputs
        with _ ->
          failwith
            "Main : inputs map's keys must be included in circuit_map's."
      in
      (* add the PI in the transcript*)
      let pi_bytes =
        let printer x =
          x
          |> List.map (fun x -> x.public)
          |> List.map Array.to_list |> List.flatten |> List.map Scalar.to_bytes
          |> Bytes.concat Bytes.empty
        in
        SMap.to_bytes printer inputs
      in
      let transcript = Fr_generation.hash_bytes [transcript; pi_bytes] in

      (* Aggregate wires commitments for transcript.
         Everything is renamed here as wires are value dependant by definition.*)
      (* Step 1 : Building wires polynomial *)
      let (f_wires_map, circuits_and_wires) =
        build_all_f_wires_map ~zero_knowledge common_pp circuit_map_with_inputs
      in
      (* Step 2 : Commit with pack to the wires comitments *)
      let srs = common_pp.pp_public_parameters.pc_public_parameters in
      let commitment_wires =
        PP.PC.Commitment.commit ~pack_name:"packed_wires" srs f_wires_map
      in
      (* Step 3 : compute beta & gamma *)
      (* Get common randomness for all proofs *)
      let transcript =
        PP.PC.Commitment.expand_transcript transcript commitment_wires
      in
      let (betas_gammas, transcript) =
        Fr_generation.generate_random_fr_list transcript 4
      in
      let beta_plonk = List.hd betas_gammas in
      let gamma_plonk = List.nth betas_gammas 1 in
      let beta_plookup = List.nth betas_gammas 2 in
      let gamma_plookup = List.nth betas_gammas 3 in
      (* Computes the list of f_map contribution for all proofs & all circuits *)
      (* Step 3b : compute permutation polynomial Z *)
      let (f_perm_and_plook_map, f_map_evaluation_list) =
        build_all_f_map_evaluation_perm
          common_pp
          beta_plonk
          gamma_plonk
          beta_plookup
          gamma_plookup
          circuits_and_wires
      in
      (* Step 4 : commit with Pack to each Z commitment *)
      let cmt_perm_and_plook =
        PP.PC.Commitment.commit
          ~pack_name:"packed_perm_and_plook"
          srs
          f_perm_and_plook_map
      in
      let transcript =
        PP.PC.Commitment.expand_transcript transcript cmt_perm_and_plook
      in
      let generator = Domain.get common_pp.domain 1 in
      (* Computes the list of prover queries for all proofs & all circuits *)
      (* Step 7 : compute gates identities *)
      let query =
        build_all_queries
          common_pp
          beta_plonk
          gamma_plonk
          beta_plookup
          gamma_plookup
          generator
          f_map_evaluation_list
      in
      let query = PP.merge_prover_queries [query; pack_query generator] in

      let (proof, transcript) =
        PP.prove
          common_pp.pp_public_parameters
          transcript
          (PP.PC.Commitment.merge commitment_wires cmt_perm_and_plook)
          (SMap.union_disjoint f_wires_map f_perm_and_plook_map)
          query
      in
      ( {perm_and_plook = cmt_perm_and_plook; wires_cm = commitment_wires; proof},
        transcript )
  end

  module Verifier = struct
    type verifier_common_pp = {
      n : int;
      generator : Scalar.t;
      pp_public_parameters : PP.verifier_public_parameters;
      query : PP.verifier_query;
      common_keys : string list;
    }

    let verifier_common_pp_encoding : verifier_common_pp Data_encoding.t =
      let open Encodings in
      let open Data_encoding in
      conv
        (fun {n; generator; pp_public_parameters; query; common_keys} ->
          (n, generator, pp_public_parameters, query, common_keys))
        (fun (n, generator, pp_public_parameters, query, common_keys) ->
          {n; generator; pp_public_parameters; query; common_keys})
        (obj5
           (req "n" int31)
           (req "generator" fr_encoding)
           (req "pp_public_parameters" PP.verifier_public_parameters_encoding)
           (req "query" PP.verifier_query_encoding)
           (req "common_keys" (list string)))

    type verifier_circuit_pp = {
      gates : unit SMap.t;
      nb_wires : int;
      alpha : Scalar.t;
      ultra : bool;
    }

    let verifier_circuit_pp_encoding : verifier_circuit_pp Data_encoding.t =
      let open Encodings in
      let open Data_encoding in
      conv
        (fun {gates; nb_wires; alpha; ultra} -> (gates, nb_wires, alpha, ultra))
        (fun (gates, nb_wires, alpha, ultra) -> {gates; nb_wires; alpha; ultra})
        (obj4
           (req "gates" (SMap.encoding unit))
           (req "nb_wires" int31)
           (req "alpha" fr_encoding)
           (req "ultra" bool))

    let build_query pp beta_plonk gamma_plonk beta_plookup gamma_plookup
        circuit_map =
      let (query_list, gates_query, common_keys) =
        SMap.fold
          (fun name (c, inputs, nb_proofs) (query_list, gates_query, common_keys)
               ->
            let prefix = if name = "" then "" else name ^ sep in
            let common_query =
              let perm_query =
                Perm.verifier_query
                  ~compute_sid:false
                  ~prefix
                  ~wires_name:(get_wires_names c.nb_wires)
                  ~generator:pp.generator
                  ~beta:beta_plonk
                  ~gamma:gamma_plonk
                  ~nb_wires:c.nb_wires
                  ()
              in
              let plookup_query =
                if c.ultra then
                  Plook.verifier_query
                    ~prefix
                    ~generator:pp.generator
                    ~wires_name:(get_wires_names c.nb_wires)
                    ~alpha:c.alpha
                    ~beta:beta_plookup
                    ~gamma:gamma_plookup
                    ~ultra:c.ultra
                    ()
                else PP.empty_verifier_query
              in
              PP.merge_verifier_queries [perm_query; plookup_query]
            in
            let len_prefix = SMap.Aggregation.compute_len_prefix ~nb_proofs in
            (* We now add the PI polynomial*)
            let (gates_query, _) =
              List.fold_left
                (fun (query, i) public_inputs ->
                  let si = SMap.Aggregation.(int_to_string ~len_prefix i) in
                  let prefix = si ^ prefix in
                  ( Gates.Gate_aggregator.add_public_inputs
                      ~prefix
                      ~public_inputs
                      ~generator:pp.generator
                      ~size_domain:pp.n
                      query,
                    i + 1 ))
                (gates_query, 0)
                inputs
            in
            (* Contains the names of polynomials that have the same value for each proof, especially preprocessed polynomials, but also later T polynomials, and possibly their evaluations in gX if needed by v_maps *)
            (* Merge all queries without renaming pre computed polynomials
               as we want to open them once only. *)
            let new_common_keys =
              PP.update_common_keys_with_v_map
                common_keys
                ~v_map:common_query.v_map
            in
            (common_query :: query_list, gates_query, new_common_keys))
          circuit_map
          ([], pp.query, pp.common_keys)
      in
      ( PP.merge_verifier_queries ~common_keys (gates_query :: query_list),
        common_keys )

    (* Assumes the same circuit, i.e. the public parameters are fixed *)
    let verify_circuits ((common_pp, circuit_map), transcript) ~public_inputs
        proof =
      let circuit_map =
        try
          SMap.mapi
            (fun i pi -> (SMap.find i circuit_map, pi, List.length pi))
            public_inputs
        with _ ->
          failwith
            "Main : public inputs maps keys must be included in circuit_map's."
      in
      (* add the PI in the transcript*)
      let pi_bytes =
        let printer x =
          x |> List.map Array.to_list |> List.flatten
          |> List.map Scalar.to_bytes |> Bytes.concat Bytes.empty
        in
        SMap.to_bytes printer public_inputs
      in

      let transcript = Fr_generation.hash_bytes [transcript; pi_bytes] in
      (* The transcript is the same as the provers's transcript since the proof
         is already aggregated *)
      let transcript =
        PP.PC.Commitment.expand_transcript transcript proof.wires_cm
      in
      (* Get the same randomness for all proofs *)
      (* Step 1a : compute beta & gamma *)
      let (betas_gammas, transcript) =
        Fr_generation.generate_random_fr_list transcript 4
      in
      let transcript =
        PP.PC.Commitment.expand_transcript transcript proof.perm_and_plook
      in
      let beta_plonk = List.hd betas_gammas in
      let gamma_plonk = List.nth betas_gammas 1 in
      let beta_plookup = List.nth betas_gammas 2 in
      let gamma_plookup = List.nth betas_gammas 3 in
      (* Step 3 : compute verifier’s identities *)
      (* common_keys is the list of the names of polynomials that have the same value for each proof, especially preprocessed polynomials, but also later T polynomials, and possibly their evaluations in gX if needed by v_maps *)
      let (query, common_keys) =
        build_query
          common_pp
          beta_plonk
          gamma_plonk
          beta_plookup
          gamma_plookup
          circuit_map
      in
      PP.verify
        ~proof_type:
          (PP.Aggregated
             {
               nb_proofs = SMap.map (fun (_, _, n) -> n) circuit_map;
               common_keys;
             })
        common_pp.pp_public_parameters
        transcript
        proof.proof
        query
  end

  type prover_public_parameters = {
    common_pp : Prover.prover_common_pp;
    circuit_map : Prover.prover_circuit_pp SMap.t;
  }

  type verifier_public_parameters = {
    common_pp : Verifier.verifier_common_pp;
    circuit_map : Verifier.verifier_circuit_pp SMap.t;
  }

  let verifier_public_parameters_encoding :
      verifier_public_parameters Data_encoding.t =
    Data_encoding.(
      conv
        (fun {common_pp; circuit_map} -> (common_pp, circuit_map))
        (fun (common_pp, circuit_map) -> {common_pp; circuit_map})
        (obj2
           (req "common_pp" Verifier.verifier_common_pp_encoding)
           (req
              "circuit_map"
              (SMap.encoding Verifier.verifier_circuit_pp_encoding))))

  module Preprocess = struct
    let degree_evaluations ~nb_wires ~zero_knowledge ~gates ~n ~ultra =
      let module_list = select_modules gates in
      let degree_evaluation =
        Gates.Gate_aggregator.aggregate_polynomials_degree ~module_list
      in
      let zk_factor = if zero_knowledge then if n <= 2 then 4 else 2 else 1 in
      let min_deg =
        (* minimum size needed for permutation gate ; if we are in the gate case, nb_wires = 0 => min_perm = 1 which is the minimum degree anyway *)
        let min_perm = Perm.polynomials_degree ~nb_wires in
        if ultra then max (Plook.polynomials_degree ()) min_perm else min_perm
      in
      let max_degree =
        SMap.fold (fun _ d acc -> max d acc) degree_evaluation min_deg
      in
      let len_evals = zk_factor * max_degree * n in
      len_evals

    let domain_evaluations ~nb_wires ~zero_knowledge ~gates ~n ~ultra =
      let len_evals =
        degree_evaluations ~nb_wires ~zero_knowledge ~gates ~n ~ultra
      in
      Domain.build ~log:Z.(log2up (of_int len_evals))

    (* Function preprocessing the circuit wires and selector polynomials;
          Inputs:
          - n: the number of constraints in the circuits + the number of public inputs
       -   domain: the interpolation domain for polynomials of size n
       - s elector_polys: the selector polynomials,
       e.g. [ql, qr, qo, qm, qc] for an arithmetic circuit.
       We assume ql is the first polynomial in the list.
       - wire_indices: the list corresponding to the wires indices,
       e.g. [a, b, c] for an arithmetic circuit
       - l, the number of public inputs
       Outputs:
       - interpolated_polys: selector polynomials, prepended with 0/1s for the public inputs,
       interpolated on the domain
       - extended_wires: circuits wires prepended with wires corresponding to the public inputs
    *)
    let preprocessing ?(prefix = "") domain gates wires tables n l circuit_size
        table_size nb_wires ~ultra =
      (* Updating selectors for public inputs. *)
      let gates =
        (* Define ql if undefined as it is the gate taking the public input in. *)
        if l > 0 && (not @@ SMap.mem "ql" gates) then
          SMap.add "ql" (List.init circuit_size (fun _ -> zero)) gates
        else gates
      in
      (* other preprocessed things in article are computed in prove of permutations *)
      let extended_gates =
        let zero_list = List.init l (fun _ -> zero) in
        let one_list = List.init l (fun _ -> one) in
        let zero_append = List.init (n - circuit_size - l) (fun _ -> zero) in
        (* Adding 0s/1s for public inputs *)
        SMap.mapi
          (fun label poly ->
            let extension = if label = "ql" then one_list else zero_list in
            let extended = List.rev_append extension poly in
            List.rev_append (List.rev extended) zero_append |> Array.of_list)
          gates
      in
      (* renommage des portes *)
      let extended_gates = SMap.Aggregation.prefix_map ~prefix extended_gates in
      let interpolated_gates =
        SMap.map (Evaluations.interpolation_fft2 domain) extended_gates
      in
      let extended_gates =
        if l = 0 then extended_gates
        else SMap.add (prefix ^ "qpub") [||] extended_gates
      in
      let extended_wires =
        let li_array = List.init l (fun i -> l - i - 1) in
        (* Adding public inputs and resizing *)
        let size = circuit_size + l in
        SMap.map
          (fun w -> List.(pad (rev_append li_array w) ~size ~final_size:n))
          wires
      in
      let extended_tables =
        if not ultra then []
        else
          Plook.format_tables
            ~tables
            ~nb_columns:nb_wires
            ~length_not_padded:table_size
            ~length_padded:n
      in
      (interpolated_gates, extended_gates, extended_wires, extended_tables)

    let preprocess_map domain domain_evals n circuit_map =
      (* Preprocessing wires, gates and tables *)
      SMap.fold
        (fun name ((c : Circuit.t), _) (prv, vrf, all_g_maps, gates_query) ->
          (* Generating alpha for Plookup *)
          let alpha = Scalar.random () in
          let (gates_poly, gates, wires, tables) =
            preprocessing
              domain
              c.gates
              c.wires
              c.tables
              n
              c.public_input_size
              c.circuit_size
              c.table_size
              c.nb_wires
              ~ultra:c.ultra
          in
          (* Generating permutation *)
          let permutation =
            let partition = Partition.build_partition wires in
            Partition.cycles_to_permutation_map_set (c.nb_wires * n) partition
          in
          (* Computing g_map *)
          let g_map_perm =
            Perm.preprocessing ~domain ~nb_wires:c.nb_wires ~permutation ()
          in
          let g_map_plook =
            if c.ultra then Plook.preprocessing ~domain ~tables ~alpha ()
            else empty_map
          in
          let circuit_g_map =
            SMap.union_disjoint_list [g_map_plook; g_map_perm; gates_poly]
          in
          let evaluations =
            Evaluations.compute_evaluations ~domain:domain_evals circuit_g_map
          in
          let prefix = if name = "" then "" else name ^ sep in
          let prover_pp =
            Prover.
              {
                circuit_size = c.circuit_size;
                nb_wires = c.nb_wires;
                gates;
                tables;
                wires = SMap.map Array.of_list wires;
                evaluations;
                permutation;
                alpha;
                ultra = c.ultra;
              }
          in

          let generator = Domain.get domain 1 in
          let c_gates_query =
            (* Compute gate_query without PI’s not_committed *)
            Gates.Gate_aggregator.aggregate_verifier_queries
              ~prefix
              ~module_list:(select_modules gates)
              ~generator
              ~size_domain:n
              ()
          in
          let verifier_pp =
            let gates = SMap.map (fun _ -> ()) gates in
            Verifier.{gates; nb_wires = c.nb_wires; alpha; ultra = c.ultra}
          in
          let g_map =
            SMap.(
              union_disjoint
                all_g_maps
                (Aggregation.prefix_map ~prefix circuit_g_map))
          in
          ( SMap.(union_disjoint prv (singleton name prover_pp)),
            SMap.(union_disjoint vrf (singleton name verifier_pp)),
            g_map,
            PP.merge_verifier_queries [c_gates_query; gates_query] ))
        circuit_map
        SMap.(empty, empty, empty, PP.empty_verifier_query)

    let compute_sizes ~zero_knowledge
        Circuit.
          {
            public_input_size;
            circuit_size;
            nb_wires;
            table_size;
            nb_lookups;
            ultra;
            _;
          } nb_proofs =
      (* Computing domain *)
      (* For TurboPlonk, we want a domain of size a power of two
         higher than or equal to the number of constraints plus public inputs.
         As for UltraPlonk, a domain of size stricly higher than the number of constraints
         (to be sure we pad the last lookup). *)
      let nb_cs_pi =
        circuit_size + public_input_size + if ultra then 1 else 0
      in
      (* For UltraPlonk, we want a domain of size a power of two
         higher than the number of records and strictly higher than the number of lookups *)
      let nb_rec_look = if ultra then max (nb_lookups + 1) table_size else 0 in
      let max_nb = max nb_cs_pi nb_rec_look in
      let log = Z.(log2up (of_int max_nb)) in
      let n = Int.shift_left 1 log in
      (* Computing SRS size *)
      let srs_size =
        let srs_size_plonk = Perm.srs_size ~zero_knowledge ~n in
        if ultra then
          let srs_size_plookup = Plook.srs_size ~length_table:n in
          max srs_size_plonk srs_size_plookup + 1
        else srs_size_plonk
      in
      let pack_size =
        let nb_extra_polys = if ultra then 5 else 1 in
        (nb_wires * nb_proofs) + nb_extra_polys
      in
      (log, n, srs_size, pack_size)

    let get_sizes ~zero_knowledge circuit_map =
      let (log, n, max_d, total_pack, some_ultra) =
        SMap.fold
          (fun _
               (c, nb_proofs)
               (acc_log, acc_n, acc_srs_size, acc_pack_size, acc_ultra) ->
            let (log, n, srs_size, pack_size) =
              compute_sizes ~zero_knowledge c nb_proofs
            in
            ( max acc_log log,
              max acc_n n,
              max acc_srs_size srs_size,
              acc_pack_size + pack_size,
              acc_ultra || c.ultra ))
          circuit_map
          (0, 0, 0, 0, false)
      in
      let len_evals =
        SMap.fold
          (fun _ ((c : Circuit.t), _) acc_deg_eval ->
            let deg_eval =
              degree_evaluations
                ~nb_wires:c.nb_wires
                ~zero_knowledge
                ~gates:c.gates
                ~n
                ~ultra:c.ultra
            in
            max acc_deg_eval deg_eval)
          circuit_map
          0
      in
      let domain_evals = Domain.build ~log:Z.(log2up (of_int len_evals)) in
      let domain = Domain.build ~log in
      let total_pack = 1 lsl Z.(log2up (of_int total_pack)) in
      (domain, n, max_d, total_pack, domain_evals, some_ultra)

    let setup_circuits_with_pool ?(zero_knowledge = true) circuit_map ~srsfile =
      let (domain, n, srs_size, pack_size, domain_evals, some_ultra) =
        get_sizes ~zero_knowledge circuit_map
      in
      let (g_map_common, evaluations, sid_verifier_query) =
        let (g_map_perm, evaluations_perm, sid_verifier_query) =
          Perm.common_preprocessing
            ~compute_l1:(not some_ultra)
            ~domain
            ~nb_wires:
              3 (* Fixme what should we keep this nb_wires as it is ? *)
            ~domain_evals
        in
        let g_map_plook =
          if some_ultra then Plook.common_preprocessing ~n ~domain
          else empty_map
        in
        let g_map = SMap.union_disjoint g_map_perm g_map_plook in
        (* Add X evaluations, which is the domain needed for other evaluations *)
        let evaluations =
          SMap.add "X" (Evaluations.of_domain domain_evals) evaluations_perm
        in
        ( g_map,
          Evaluations.compute_evaluations_update_map ~evaluations g_map,
          sid_verifier_query )
      in
      let (pp_prv, pp_vrf, g_map, gates_query) =
        preprocess_map domain domain_evals n circuit_map
      in
      let query = PP.merge_verifier_queries [sid_verifier_query; gates_query] in
      let g_map = SMap.union_disjoint g_map g_map_common in
      (* Generating public parameters *)
      let (pp_prover, pp_verifier) =
        PP.setup
          ~setup_params:(srs_size, pack_size)
          g_map
          ~subgroup_size:n
          srsfile
      in
      (* Generating transcript *)
      let transcript =
        let pc_public_parameters = pp_prover.pc_public_parameters in
        let tmp = PP.PC.Public_parameters.to_bytes pc_public_parameters in
        PP.PC.Commitment.expand_transcript tmp pp_verifier.cm_g_map
      in
      let common_keys =
        let common_keys = List.map fst (SMap.bindings g_map) in
        if some_ultra then common_keys @ ["Si1"; "Si2"; "Si3"; "x_minus_1"]
        else common_keys @ ["Si1"; "Si2"; "Si3"]
      in
      let common_prv =
        Prover.
          {
            n;
            domain;
            pp_public_parameters = pp_prover;
            evaluations;
            common_keys;
          }
      in
      let common_vrf =
        Verifier.
          {
            n;
            generator = Domain.get domain 1;
            pp_public_parameters = pp_verifier;
            query;
            common_keys;
          }
      in
      ( ( ({common_pp = common_prv; circuit_map = pp_prv}
            : prover_public_parameters),
          {common_pp = common_vrf; circuit_map = pp_vrf} ),
        transcript )
  end

  let check_circuit_name map =
    SMap.iter
      (fun name _ ->
        if name = "" then ()
        else if Char.compare name.[0] '9' <= 0 then
          failwith
            (Printf.sprintf "check_circuit_name : circuit name (= '%s')" name
            ^ " must not begin with '\\', '#', '$', '%', '&', ''', '(', ')', \
               '*', '+', ',', '-', '.', '/' or a digit.")
        else if String.contains name SMap.Aggregation.sep.[0] then
          failwith
            (Printf.sprintf
               "check_circuit_name : circuit name (= '%s') mustn't contain '%s'"
               name
               SMap.Aggregation.sep))
      map

  let setup_multi_circuits ?(zero_knowledge = true) circuit_map ~srsfile =
    check_circuit_name circuit_map ;
    Multicore.with_pool (fun () ->
        Preprocess.setup_circuits_with_pool ~zero_knowledge circuit_map ~srsfile)

  let prove_multi_circuits ?(zero_knowledge = true)
      ((pp : prover_public_parameters), transcript) ~inputs =
    check_circuit_name pp.circuit_map ;
    Multicore.with_pool (fun () ->
        Prover.prove_circuits_with_pool
          ~zero_knowledge
          ((pp.common_pp, pp.circuit_map), transcript)
          ~inputs)

  let verify_multi_circuits (pp, transcript) ~public_inputs =
    check_circuit_name pp.circuit_map ;
    Multicore.with_pool (fun () ->
        Verifier.verify_circuits
          ((pp.common_pp, pp.circuit_map), transcript)
          ~public_inputs)

  let setup ?(zero_knowledge = true) circuit ~srsfile ~nb_proofs =
    let circuit_map = SMap.singleton "" (circuit, nb_proofs) in
    Multicore.with_pool (fun () ->
        Preprocess.setup_circuits_with_pool ~zero_knowledge circuit_map ~srsfile)

  (* Prover function:
      proves a statement for some inputs

     computes the wires polynomials
     and calls Polynomial Protocol on the identities of the gates needed,
     the Permutation (copy-satisfaction) & optionally Plookup
      Inputs:
      - transcript: transcript initialized with SRS
      - public_parameters: (output of setup for the statement)
        - domain: the interpolation domain for polynomials of size n
        - n: the number of constraints in the circuits + the number of public inputs
        - wires: the int list representation for each wire’s indices
        - gates: the scalar list representation for each gate
        - tables: the representation of tables
        - pp_public_parameters: public parameters of Polynomial_protocol
        - permutation: the int array representation for the permutation defined by the circuit
        - alpha: the random scalar for plookup
        - ultra: true if Plookup gate must be called
        - circuit_size: the number of constraints in the circuit
        - nb_wires: the number of wires
        - evaluations: the (degree, fft evaluation) of preprocessed polynomials
      - private_inputs: the values of the wires
      - public_inputs: the firsts values of private_inputs that are public
      Outputs:
      - a unique zk-snark
  *)
  (* TODO : add antireplay arg *)
  let prove ?zero_knowledge pp ~inputs =
    let inputs = SMap.singleton "" [inputs] in
    prove_multi_circuits ?zero_knowledge pp ~inputs

  let verify pp ~public_inputs proof =
    let public_inputs = SMap.singleton "" [public_inputs] in

    verify_multi_circuits pp ~public_inputs proof
end

module type Main_protocol_sig = sig
  exception Entry_not_in_table of string

  exception Rest_not_null of string

  exception Wrong_transcript of string

  module SMap : SMap.StringMap_sig

  type scalar = Bls12_381.Fr.t

  val scalar_encoding : scalar Data_encoding.t

  type transcript

  type prover_public_parameters

  type verifier_public_parameters

  val verifier_public_parameters_encoding :
    verifier_public_parameters Data_encoding.t

  type proof

  val proof_encoding : proof Data_encoding.t

  type prover_inputs = {public : scalar array; witness : scalar array}

  val transcript_encoding : transcript Data_encoding.t

  (* Computes the public parameters needed for prove & verify from a circuit
     Inputs:
     - zero_knowledge: true if wires polynomials have to be blinded
     - circuit: output from Circuit.make
     - srsfile: the name of SRS file in the srs folder from where the SRS will be imported
     Outputs:
     - public_parameters & transcript
  *)
  val setup :
    ?zero_knowledge:bool ->
    Circuit.t ->
    srsfile:string ->
    nb_proofs:int ->
    (prover_public_parameters * verifier_public_parameters) * transcript

  (* Prover function: computes the wires polynomials and calls Polynomial Protocol on the identities of the gates needed, the Permutation (copy-satisfaction) & optionally Plookup
     Inputs:
     - zero_knowledge: true if wires polynomials have to be blinded
     - transcript: transcript initialized with SRS
     - public_parameters: output of setup
     - private_inputs: the values of the wires
     - public_inputs: the firsts values of private_inputs that are public
     Outputs:
     - zk-snark
  *)
  val prove :
    ?zero_knowledge:bool ->
    prover_public_parameters * transcript ->
    inputs:prover_inputs ->
    proof * transcript

  (* Verifier function: checks proof
     Inputs:
     - transcript: transcript initialized with SRS
     - public_parameters: output of setup
     - public_inputs (scalar array): the firsts values of private_inputs that are public
     - proof: output of prove
     Outputs:
     - bool
  *)
  val verify :
    verifier_public_parameters * transcript ->
    public_inputs:scalar array ->
    proof ->
    bool

  (* Computes the public parameters needed for prove & verify for several circuit
     Inputs:
     - zero_knowledge: true if wires polynomials have to be blinded
     - circuit: a StringMap of (outputs from Circuit.make, upper bound of the number of proofs to aggregate for this circuit) binded with the circuit’s name
     - srsfile: the name of SRS file in the srs folder from where the SRS will be imported
     Outputs:
     - public_parameters & transcript
  *)
  val setup_multi_circuits :
    ?zero_knowledge:bool ->
    (Circuit.t * int) SMap.t ->
    srsfile:string ->
    (prover_public_parameters * verifier_public_parameters) * transcript

  (* Prover function: for several circuits & several inputs, computes the wires polynomials and calls Polynomial Protocol on the identities of the gates needed, the Permutation (copy-satisfaction) & optionally Plookup
     Inputs:
     - zero_knowledge: true if wires polynomials have to be blinded
     - transcript: transcript initialized with SRS
     - public_parameters: output of setup
     - private_inputs: the map of the list of values of the wires binded with the circuit name
     - public_inputs: the map of the list of the firsts values of private_inputs that are public,  binded with the circuit name
     Outputs:
     - zk-snark
  *)
  val prove_multi_circuits :
    ?zero_knowledge:bool ->
    prover_public_parameters * transcript ->
    inputs:prover_inputs list SMap.t ->
    proof * transcript

  (* Verifier function: checks a bunch of proofs for several circuits
     Inputs:
     - transcript: transcript initialized with SRS
     - public_parameters: output of setup_multi_circuits for the circuits being checked
     - public_inputs: StringMap where the lists of public inputs are binded with the circuit to which they correspond
     - proof: the unique proof that correspond to all inputs
     Outputs:
     - bool
  *)
  val verify_multi_circuits :
    verifier_public_parameters * transcript ->
    public_inputs:scalar array list SMap.t ->
    proof ->
    bool
end

include (Make (Polynomial_protocol) : Main_protocol_sig)
