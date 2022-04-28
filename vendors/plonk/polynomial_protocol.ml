(* A polynomial protocol allows a prover to convince
   a verifier that arithmetic identites between polynomials
   holds over a subgroup.
   It is defined in https://eprint.iacr.org/2019/953 part 4.1
   It depends on a polynomial commitment scheme. *)

module Make (PC : Kzg.Polynomial_commitment_sig) = struct
  (* utils functions related to the scalar field Fr *)
  module Fr_generation = PC.Fr_generation
  module PC = PC
  module MP =
    Polynomial.Multivariate.MultiPoly
      (PC.Scalar)
      (Polynomial.Univariate.Make (PC.Scalar))
  module MPoly = MP.Polynomial
  module Domain = PC.Polynomial.Domain
  module Poly = PC.Polynomial.Polynomial
  module Evaluations = Evaluations_map.Make (PC.Polynomial.Evaluations)

  type prover_public_parameters = {
    pc_public_parameters : PC.Public_parameters.prover;
    subgroup_size : int;
    (* So called pre-committed polynomials, these polynomials
       are fixed before the protocol starts *)
    g_map : Poly.t SMap.t;
  }

  type verifier_public_parameters = {
    pc_public_parameters : PC.Public_parameters.verifier;
    subgroup_size : int;
    (* The commitments to the pre-committed polynomials. *)
    cm_g_map : PC.Commitment.t;
  }

  (* We only encode the verifier's parameters as only those
     will be needed on chain *)
  let verifier_public_parameters_encoding :
      verifier_public_parameters Data_encoding.t =
    Data_encoding.(
      conv
        (fun {pc_public_parameters; subgroup_size; cm_g_map} ->
          (pc_public_parameters, subgroup_size, cm_g_map))
        (fun (pc_public_parameters, subgroup_size, cm_g_map) ->
          {pc_public_parameters; subgroup_size; cm_g_map})
        (obj3
           (req "pc_public_parameter" PC.Public_parameters.verifier_encoding)
           (req "subgroup_size" int31)
           (req "cm_g_map" PC.Commitment.encoding)))

  (*What the provers needs to know to answer a query. *)
  type prover_query = {
    (* indicates if a polynomial is composed with another one.
       e.g. showing an identity P(x) = Q(x^2) will have a "Q" -> X^2 as element
       of the v_map. No entries are present when composed with the polynomial X.
       The keys in the SMap indicates the name of the identity. *)
    v_map : (string * Poly.t) SMap.t;
    (* The precomputed_polys are pre-computation of the identites,
       in the form of an evaluation. *)
    precomputed_polys : Evaluations.t SMap.t;
  }

  let empty_prover_query = {v_map = SMap.empty; precomputed_polys = SMap.empty}

  (* Not_committed polynomials are polynomials participating
     in the relation which are sparse enough that the verifier
     does not evaluate them via the polynomial commitment scheme *)
  type not_committed = ..

  (*
  Evaluation of a [not_committed] variant. It is a reference to a function,
  which is extended every time a new [not_committed] case is registered.

  *)
  let eval_not_committed :
      (not_committed -> PC.Scalar.t array -> PC.Scalar.t) ref =
    ref @@ function _ -> failwith "eval case not matched"

  (* ref to a list of data_encoding cases, which is extended every time a
     new [not_committed] case is registered.
  *)
  let cases_not_committed : not_committed Data_encoding.case SMap.t ref =
    ref SMap.empty

  (* The encoding for [not_committed] is the union of all the registered cases.
     As this is not known until later in the execution, the encoding is dealyed.
  *)
  let not_committed_encoding () =
    Data_encoding.union (List.map snd @@ SMap.bindings @@ !cases_not_committed)

  let not_committed_encoding : not_committed Data_encoding.t =
    Data_encoding.delayed not_committed_encoding

  let register_nc_eval_and_encoding :
      (not_committed -> (PC.Scalar.t array -> PC.Scalar.t) option) ->
      title:string ->
      tag:int ->
      'b Data_encoding.t ->
      (not_committed -> 'b option) ->
      ('b -> not_committed) ->
      unit =
   fun f ~title ~tag inner from to' ->
    let old = !eval_not_committed in
    let new_eval e = match f e with Some g -> g | None -> old e in
    eval_not_committed := new_eval ;
    cases_not_committed :=
      SMap.add
        title
        Data_encoding.(case ~title (Tag tag) inner from to')
        !cases_not_committed

  (* Defines the identites the verifier wants a proof of. *)
  type verifier_query = {
    (* See prover_query *)
    v_map : (string * Poly.t) SMap.t;
    (* Multivariate polynomials, whose variables are represented as strings. *)
    identities : MPoly.t SMap.t;
    not_committed : not_committed SMap.t;
  }

  let empty_verifier_query =
    {v_map = SMap.empty; identities = SMap.empty; not_committed = SMap.empty}

  let verifier_query_encoding : verifier_query Data_encoding.t =
    let open Encodings in
    Data_encoding.(
      delayed @@ fun () ->
      conv
        (fun {v_map; identities; not_committed} ->
          (v_map, identities, not_committed))
        (fun (v_map, identities, not_committed) ->
          {v_map; identities; not_committed})
        (obj3
           (req "v_map" (SMap.encoding (tup2 string Poly.encoding)))
           (req
              "identities"
              (SMap.encoding (MP.MonomialMap.encoding fr_encoding)))
           (req "not_committed" (SMap.encoding not_committed_encoding))))

  (* The verifier needs auxiliary infos if the proofs are aggregated *)
  type aggregation_infos = {
    (* {circuit_name -> nb_proofs} *)
    nb_proofs : int SMap.t;
    (* name of polynomials that do not depend on the input *)
    common_keys : string list;
  }

  (* Indication for the verifier *)
  type proof_type = Single | Aggregated of aggregation_infos

  (* The polynomials of the identities.
     These are not known to the verifier *)
  type secret = Poly.t SMap.t

  (* used for fiat shamir see https://en.wikipedia.org/wiki/Fiat-Shamir_heuristic *)
  type transcript = Bytes.t

  let transcript_encoding = Data_encoding.bytes

  type proof = {
    (*evaluations and proof of the secret polynomials *)
    pc_proof : PC.answer * PC.proof;
    (* Commitements to T = identities/X^n-1.
       There are several commitments, see Poly.Split function.
       The existence of this polynomial proves
       identities(x) = 0 for all x n-th root of unity.*)
    cm_t_map : PC.Commitment.t;
  }

  let proof_encoding : proof Data_encoding.t =
    Data_encoding.(
      conv
        (fun {pc_proof; cm_t_map} -> (pc_proof, cm_t_map))
        (fun (pc_proof, cm_t_map) -> {pc_proof; cm_t_map})
        (obj2
           (req "pc_proof" (tup2 PC.answer_encoding PC.proof_encoding))
           (req "cm_t_map" PC.Commitment.encoding)))

  exception Rest_not_null of string

  module Prover = struct
    let compute_T n a precomputed =
      let poly_names = List.map fst (SMap.bindings precomputed) in
      let linear_coeffs =
        Fr_generation.powers (List.length poly_names) a |> Array.to_list
      in
      let t_evaluation =
        Evaluations.linear
          ~evaluations:precomputed
          ~poly_names
          ~linear_coeffs
          ()
      in
      let log = Z.log2up (Z.of_int @@ (Evaluations.degree t_evaluation + 1)) in
      let domain = Domain.build ~log in
      let sum = Evaluations.interpolation_fft domain t_evaluation in
      let proof = Poly.division_zs sum n in
      if Poly.(mul_zs proof n = sum) then proof
      else raise @@ Poly.Rest_not_null "T not divisible by (X^n - 1)"

    (* Helper function for format_query *)
    let update_scalar_map query x name_list =
      PC.Scalar_map.update
        x
        (function
          | None -> Some name_list
          | Some l -> Some (List.rev_append name_list l))
        query

    (* Helper function for format_query *)
    let sort_query query =
      PC.Scalar_map.map (List.sort_uniq String.compare) query

    (* Build PC query from h_map & v_map, and x the evaluation point.
       h_map contains the polynomials that need to be evaluated
       v_map precise if they should be evaluated on other point than x
       /!\ if f(gX) is required by v_map, f(X) will be also in the query
    *)
    let format_query x h_map v_map =
      let ffold _ (name, v) map =
        let (name, vx) = (name, Poly.evaluate v x) in
        update_scalar_map map vx [name]
      in
      let query_from_v_map = SMap.fold ffold v_map PC.Scalar_map.empty in
      let query =
        let (list_h, _) = List.split (SMap.bindings h_map) in
        update_scalar_map query_from_v_map x list_h
      in
      sort_query query
  end

  exception Wrong_transcript of string

  module Verifier = struct
    let search string list =
      try List.assoc string list
      with Not_found ->
        failwith
          (Format.sprintf
             "PP.Verifier.search : \"%s\" not found in answers."
             string)

    (* Build PC query from prover’s answers *)
    (* This is secure as the security comes from the name of cm_g_map *)
    let format_query answers = PC.Scalar_map.map (List.map fst) answers

    let add_first_common x h_map_base keys evals s_map v_map =
      let rec aux h_map keys evals =
        match (keys, evals) with
        | ([], _) -> h_map
        | (key :: key_tl, (name, eval) :: eval_tl) -> (
            if key = name then aux (SMap.add name eval h_map) key_tl eval_tl
            else
              (* a common key was not found ;
                 it may be binded with an other point in smap ;
                 we have to search it in v_map to get its original name
                 & its evaluation point, and then search it in answers *)
              match SMap.find_opt key v_map with
              | None ->
                  failwith
                    (Printf.sprintf
                       "PP.Verifier.build_common_h_map : '%s' not found in \
                        v_map"
                       key)
              | Some (base_name, poly) -> (
                  if not (base_name = name) then
                    failwith
                      (Printf.sprintf
                         "PP.Verifier.build_common_h_map : '%s' base name \
                          found in v_map does not match with s_map's '%s'"
                         base_name
                         name)
                  else
                    match
                      PC.Scalar_map.find_opt (Poly.evaluate poly x) s_map
                    with
                    | None ->
                        failwith
                          (Printf.sprintf
                             "PP.Verifier.build_common_h_map : no binding for \
                              '%s' found in s_map"
                             key)
                    | Some eval_list ->
                        let comp_eval = search base_name (List.rev eval_list) in
                        aux
                          (SMap.add key comp_eval h_map)
                          key_tl
                          ((name, eval) :: eval_tl)))
        | _ ->
            failwith
              "PP.Verifier.take_first_common : keys must be shorter than evals"
      in
      aux h_map_base keys evals

    (* Supposes that smap is sorted (making preprocessed poly in last positions)
       & that most of the common keys’s evaluations are binded to x
    *)
    let build_common_h_map x h_not_committed common_keys s_map v_map =
      let common_keys =
        common_keys
        |> List.filter (fun name -> not (SMap.mem name h_not_committed))
        |> List.sort (fun s t -> -String.compare s t)
      in
      let main_list_evals =
        List.rev
          (match PC.Scalar_map.find_opt x s_map with
          | None ->
              raise
              @@ Wrong_transcript
                   (Printf.sprintf
                      "PP.Verifier.build_h_map : %s not found in answers ; \
                       make sure that transcript is the same for prover and \
                       verifier."
                      (PC.Scalar.to_string x))
          | Some res -> res)
      in
      add_first_common x h_not_committed common_keys main_list_evals s_map v_map

    let add_in_hmap name name_identity vx h_map s_map_list =
      match List.assoc_opt vx s_map_list with
      | None ->
          raise
          @@ Wrong_transcript
               (Printf.sprintf
                  "PP.Verifier.build_h_map : %s(%s) not found in answers ; \
                   make sure that transcript is the same for prover and \
                   verifier."
                  name
                  (PC.Scalar.to_string vx))
      | Some eval_map -> (
          match SMap.find_opt name eval_map with
          | None ->
              failwith
                (Format.sprintf
                   "PP.Verifier.build_h_map : \"%s\" not found in answers."
                   name)
          | Some hx -> SMap.add_unique name_identity hx h_map)

    (* Rename s_map’s answers according to v_map *)
    let build_h_map x names_identity h_not_committed v_map s_map =
      let ffold h_map name =
        match SMap.find_opt name h_not_committed with
        | Some _ -> h_map
        | None -> (
            match SMap.find_opt name v_map with
            | Some (old_name, v) ->
                let vx = Poly.evaluate v x in
                add_in_hmap old_name name vx h_map s_map
            | None -> add_in_hmap name name x h_map s_map)
      in
      List.fold_left ffold h_not_committed names_identity

    let build_h_map_i ~prefix x names_identity h_not_committed v_map answer =
      let ffold h_map name =
        let name_prefixed = prefix ^ name in
        match SMap.find_opt name_prefixed h_not_committed with
        | Some value -> SMap.add name value h_map
        | None -> (
            match SMap.find_opt name v_map with
            | Some (old_name, v) ->
                let vx = Poly.evaluate v x in
                let old_name_prefixed = prefix ^ old_name in
                add_in_hmap old_name_prefixed name vx h_map answer
            | None -> add_in_hmap name_prefixed name x h_map answer)
      in
      List.fold_left ffold SMap.empty names_identity

    let is_t_name name = Char.(equal name.[0] 'T' && equal name.[1] '_')

    let build_tzs_h_map x_ni s_map eval_point =
      let t_evals =
        List.filter
          (fun x -> is_t_name (fst x))
          (PC.Scalar_map.find eval_point s_map)
      in
      SMap.(add "Zs" PC.Scalar.(sub x_ni.(1) one) (of_list t_evals))

    (* Count the number of polynomials prefixed by "T_" in map and remove them. *)
    let remove_t map =
      let ret = SMap.filter (fun name _ -> not (is_t_name name)) map in
      (ret, SMap.cardinal map - SMap.cardinal ret)

    let starts_with prefix name =
      let len_prefix = String.length prefix in
      if len_prefix >= String.length name then false
      else
        let start = String.sub name 0 len_prefix in
        prefix = start

    (* Use the horner method to compute the linear combination of the
       evaluated identities *)
    let apply ~proof_type a x identities h_not_committed v_map answer =
      (* Since the horner method is used,
         we need the identities in the decreasing order of a’s degree *)
      let add_ids sum h_map identities =
        let identities = List.rev_map snd (SMap.bindings identities) in
        List.fold_left
          (fun sum_id id ->
            PC.Scalar.((sum_id * a) + MPoly.fast_apply id h_map))
          sum
          identities
      in
      match proof_type with
      | Single ->
          let id_support = MPoly.get_support_map identities in
          let h_map = build_h_map x id_support h_not_committed v_map answer in
          add_ids PC.Scalar.zero h_map identities
      | Aggregated aggregation_infos ->
          let circuit_list =
            List.rev (SMap.bindings aggregation_infos.nb_proofs)
          in
          let rec apply_all identities id_support len_prefix res i =
            if i < 0 then res
            else
              let prefix = SMap.Aggregation.int_to_string ~len_prefix i in
              let h_map =
                build_h_map_i ~prefix x id_support h_not_committed v_map answer
              in
              apply_all
                identities
                id_support
                len_prefix
                (add_ids res h_map identities)
                (i - 1)
          in
          List.fold_left
            (fun res (name, nb_proofs) ->
              let identities =
                let c_prefix =
                  if name = "" then "" else name ^ SMap.Aggregation.sep
                in
                SMap.filter
                  (fun id_name _ -> starts_with c_prefix id_name)
                  identities
              in
              let id_support = MPoly.get_support_map identities in
              let len_prefix = SMap.Aggregation.compute_len_prefix ~nb_proofs in
              apply_all identities id_support len_prefix res (nb_proofs - 1))
            PC.Scalar.zero
            circuit_list
  end

  (* returns srs of length d, add zs to g_map and compute cm_g_map *)
  let setup ~setup_params g_map ~subgroup_size srsfile =
    let (pp_prover, pp_verifier) =
      PC.Public_parameters.import setup_params srsfile
    in
    let cm_g_map = PC.Commitment.commit pp_prover g_map in
    ( {pc_public_parameters = pp_prover; subgroup_size; g_map},
      {pc_public_parameters = pp_verifier; subgroup_size; cm_g_map} )

  (* n is expected length of a_list
     returns x & a_list where a_list[i] ∈ F is a^i, and x & a
     is generated from transcript *)
  let build_a_list n transcript =
    let (a, new_transcript) = Fr_generation.generate_single_fr transcript in
    (Array.to_list (Fr_generation.powers n a), new_transcript)

  let merge_prover_queries list_queries =
    let list_v_map =
      List.map (fun (query : prover_query) -> query.v_map) list_queries
    in
    let v_map = SMap.union_disjoint_list list_v_map in
    let list_precomputed_polys =
      List.map (fun query -> query.precomputed_polys) list_queries
    in
    let precomputed_polys = SMap.union_disjoint_list list_precomputed_polys in
    {v_map; precomputed_polys}

  let merge_verifier_queries ?(common_keys = []) list_queries =
    let common_keys_equal_elt = (common_keys, fun _ _ -> true) in
    let list_v_map = List.map (fun query -> query.v_map) list_queries in
    let v_map = SMap.union_disjoint_list list_v_map in
    let list_identities =
      List.map (fun query -> query.identities) list_queries
    in
    let identities = SMap.union_disjoint_list list_identities in
    let list_not_committed =
      List.map (fun query -> query.not_committed) list_queries
    in
    let not_committed =
      SMap.union_disjoint_list ~common_keys_equal_elt list_not_committed
    in
    {v_map; identities; not_committed}

  (* Helpers function for merge_equal_set_of_{verifier}_query} *)
  (* Substitute name of variable in a multivariate poly.
     Add i to the end of the name of the variable
     unless it belongs to common_keys. *)
  let substitue ~nb_proofs ~common_keys monomial_map i =
    let len_prefix = SMap.Aggregation.compute_len_prefix ~nb_proofs in
    MP.MonomialMap.(
      fold (fun key value new_map ->
          add
            (SMap.Aggregation.rename ~len_prefix ~common_keys i key)
            value
            new_map))
      monomial_map
      MP.MonomialMap.empty

  (* Helpers function for merge_equal_set_of_{verifier}_query}*)
  (* [merge_v_map common_keys list_map] returns the disjoint union of list_map
     with their keys and the name of the base polynomials updated with their map's index
     in the list (unless they appear in common keys).
     All maps are asserted to be equal. *)
  let merge_v_map ~len_prefix common_keys list_map =
    (*assert the maps are the same *)
    let equal_elt (name_1, poly_1) (name_2, poly_2) =
      name_1 = name_2 && Poly.equal poly_1 poly_2
    in
    assert (List.for_all (SMap.equal equal_elt (List.hd list_map)) list_map) ;
    (*  create unique identifiers in all map except common_keys*)
    let new_list_map =
      let update_value prefix (name, poly) = (prefix ^ name, poly) in
      List.mapi
        (SMap.Aggregation.rename ~len_prefix ~update_value ~common_keys)
        list_map
    in
    (* merge the modified map*)
    SMap.union_disjoint_list
      ~common_keys_equal_elt:(common_keys, equal_elt)
      new_list_map

  (* Helpers function for main_proto
     to call merge_equal_set_of_{prover/verifier}_query} *)
  (* returns the concatenation of common_keys with the images of common_keys in v_map.
     The common_keys also need to contain all images of common_keys in v_map *)
  let update_common_keys_with_v_map ?(extra_prefix = "") common_keys ~v_map =
    SMap.fold
      (fun composed_name (base_name, _poly_to_compose) common_keys ->
        if List.mem (extra_prefix ^ base_name) common_keys then
          (extra_prefix ^ composed_name) :: common_keys
        else common_keys)
      v_map
      common_keys

  let merge_equal_set_of_keys_prover_queries ?(extra_prefix = "") ~len_prefix
      ~common_keys (list_queries : prover_query list) =
    let list_v_map =
      List.map (fun (query : prover_query) -> query.v_map) list_queries
    in
    let v_map = merge_v_map ~len_prefix common_keys list_v_map in
    let list_precomputed_polys =
      List.map (fun query -> query.precomputed_polys) list_queries
    in
    (* Identities are prefixed with circuit before the number of proofs
       in order to keep the same aggregation order as the verifier *)
    let precomputed_polys =
      SMap.Aggregation.merge_equal_set_of_keys
        ~common_keys_equal_elt:(common_keys, Evaluations.equal)
        ~len_prefix
        list_precomputed_polys
    in
    let precomputed_polys =
      SMap.Aggregation.prefix_map ~prefix:extra_prefix precomputed_polys
    in
    {v_map; precomputed_polys}

  let merge_equal_set_of_keys_verifier_queries ?(extra_prefix = "") ~len_prefix
      ~common_keys list_queries =
    let list_v_map = List.map (fun query -> query.v_map) list_queries in
    let v_map =
      SMap.Aggregation.prefix_map ~prefix:extra_prefix (List.hd list_v_map)
    in
    let list_identities =
      List.map (fun query -> query.identities) list_queries
    in
    let identities =
      SMap.Aggregation.prefix_map ~prefix:extra_prefix (List.hd list_identities)
    in
    let list_not_committed =
      List.map (fun query -> query.not_committed) list_queries
    in
    let not_committed =
      (* We can't compare functions here *)
      let equal_elt _elt_1 _elt_2 = true in
      SMap.Aggregation.merge_equal_set_of_keys
        ~extra_prefix
        ~common_keys_equal_elt:(common_keys, equal_elt)
        ~len_prefix
        list_not_committed
    in
    {v_map; identities; not_committed}

  (* Helper function for sum_{prover/verifier}_query} *)
  let merge_vmaps map1 map2 function_name =
    SMap.union
      (fun key v1 v2 ->
        let (str1, poly1) = v1 in
        let (str2, poly2) = v2 in
        if String.equal str1 str2 && Poly.equal poly1 poly2 then Some v1
        else
          raise
            (Invalid_argument
               (Printf.sprintf
                  "PP/%s: Distinct values in vmap for label '%s'."
                  function_name
                  key)))
      map1
      map2

  let sum_prover_queries q1 q2 =
    let precomputed_polys =
      SMap.union
        (fun _key v1 v2 -> Some (Evaluations.add v1 v2))
        q1.precomputed_polys
        q2.precomputed_polys
    in
    let v_map = merge_vmaps q1.v_map q2.v_map "sum_prover_queries" in
    {v_map; precomputed_polys}

  let sum_verifier_queries q1 q2 =
    let v_map = merge_vmaps q1.v_map q2.v_map "sum_verifier_queries" in
    let identities =
      SMap.union
        (fun _key v1 v2 -> Some (MPoly.add v1 v2))
        q1.identities
        q2.identities
    in
    let not_committed = SMap.union_disjoint q1.not_committed q2.not_committed in
    {v_map; identities; not_committed}

  (* v_map = map of "h∘v name in identities" ->
     ("h name in f_map or g_map", v polynomial) ;
     mustn’t contain "Zs" or "PI" or any polynomial which name begins with "T_"
   * g_map’s polynomials are preprocessed
   * f_map musn’t contain "Zs" or "PI" or any polynomial whose name begins with "T_"
   * g_map and f_map must be disjoint
   polynomials & their names must match with verify’s identities
   precommitted polys contains commitments that have been already computed ;
   these commitments will not be added to the transcript ; its keys must be in f_map
   * returns PP.proof, T commitments (-> (Σai*fi)/zs) & new transcript
   *)
  let prove {pc_public_parameters; subgroup_size; g_map} transcript
      committed_polys f_map {v_map; precomputed_polys} =
    (* Step 7b : compute alpha *)
    let (a, transcript) = Fr_generation.generate_single_fr transcript in

    (* Step 8 : (Compute T) combines identities with alpha & divide by Zh *)
    let t_map =
      let t = Prover.compute_T subgroup_size a precomputed_polys in
      let t_list =
        let d = PC.Public_parameters.get_d pc_public_parameters in
        Poly.split d subgroup_size t
      in
      SMap.of_list (List.mapi (fun i t -> ("T_" ^ string_of_int i, t)) t_list)
    in
    let cm_t_map = PC.Commitment.commit pc_public_parameters t_map in
    (* Step 9 : compute evaluation point xi *)
    let transcript = PC.Commitment.expand_transcript transcript cm_t_map in
    let (x, transcript) = Fr_generation.generate_single_fr transcript in

    (* Step 12 : output the final proof & evaluations *)
    (* Add T to the map of secret polynomials *)
    let h_map = SMap.union_disjoint_list [g_map; f_map; t_map] in
    let query = Prover.format_query x h_map v_map in
    let (pc_proof, transcript) =
      PC.prove pc_public_parameters transcript committed_polys query h_map
    in
    ({pc_proof; cm_t_map}, transcript)

  (* returns true iff (Σai*Fi) - T×Zs = 0
     /!\ may return false for a correct statement if a polynomial of Prover’s (f_map ∪ g_map) is not included in MPoly.get_support (identities) (& vice-versa) ; this may make the verifier & prover queries for PC different, resulting in a verification failure
  *)
  let verify ~proof_type {pc_public_parameters; subgroup_size; cm_g_map}
      transcript {cm_t_map; pc_proof = (answer, proof)}
      {v_map; identities; not_committed} =
    (* Step 1c : compute alpha & xi *)
    let (a, transcript) = Fr_generation.generate_single_fr transcript in
    let transcript = PC.Commitment.expand_transcript transcript cm_t_map in

    let (x, transcript) = Fr_generation.generate_single_fr transcript in

    (* Step 2a: KZG.verify proofs for witness combinations *)
    let kzg_verif =
      let cm_map = PC.Commitment.merge cm_t_map cm_g_map in
      let z_map = Verifier.format_query answer in
      PC.verify pc_public_parameters transcript z_map cm_map (answer, proof)
    in
    (* Step 3b & 4 : combine & verify identities *)
    let nb_t = PC.Commitment.cardinal cm_t_map in
    (* x_ni = [|x, x^n, x^2n,...|] *)
    let x_ni =
      let pows =
        let nb_x = max 2 nb_t in
        Fr_generation.powers nb_x (PC.Scalar.pow x (Z.of_int subgroup_size))
      in
      pows.(0) <- x ;
      pows
    in
    let h_map_not_committed =
      SMap.map (fun e -> !eval_not_committed e x_ni) not_committed
    in
    let answer_list =
      List.map
        (fun (p, eval_list) -> (p, SMap.of_list eval_list))
        (PC.Scalar_map.bindings answer)
    in

    let sum_id =
      match proof_type with
      | Single ->
          let identities =
            SMap.map
              (fun id -> MPoly.partial_apply id h_map_not_committed)
              identities
          in
          Verifier.apply
            ~proof_type
            a
            x
            identities
            h_map_not_committed
            v_map
            answer_list
      | Aggregated aggregation_infos ->
          let (common_not_committed, h_map_not_committed) =
            SMap.partition
              (fun k _ -> List.mem k aggregation_infos.common_keys)
              h_map_not_committed
          in
          let s_map = answer in
          let common_h_map =
            (* adding T in common keys *)
            let common_keys =
              aggregation_infos.common_keys
              @ List.init nb_t (fun i -> "T_" ^ string_of_int i)
            in
            Verifier.build_common_h_map
              x
              common_not_committed
              common_keys
              s_map
              v_map
          in
          let identities =
            SMap.map (fun id -> MPoly.partial_apply id common_h_map) identities
          in
          Verifier.apply
            ~proof_type
            a
            x
            identities
            h_map_not_committed
            v_map
            answer_list
    in
    let tzs =
      let identity =
        MPoly.of_list
          (List.init nb_t (function
              | 0 -> (SMap.monomial_of_list ["T_0"; "Zs"], PC.Scalar.one)
              | i ->
                  ( SMap.monomial_of_list ["T_" ^ string_of_int i; "Zs"],
                    x_ni.(i) )))
      in
      let h_map = Verifier.build_tzs_h_map x_ni answer x in
      MPoly.fast_apply identity h_map
    in
    let id_verif = PC.Scalar.eq sum_id tzs in
    kzg_verif && id_verif
end

module type Polynomial_protocol_sig = sig
  module PC : Kzg.Polynomial_commitment_sig

  module MP :
    Polynomial.Multivariate.MultiPoly_sig with type scalar = PC.Scalar.t

  module Evaluations :
    Evaluations_map.Evaluations_sig
      with type scalar = PC.Scalar.t
       and type domain = PC.Polynomial.Domain.t
       and type polynomial = PC.Polynomial.Polynomial.t
       and type t = PC.Polynomial.Evaluations.t

  exception Wrong_transcript of string

  type prover_public_parameters = {
    pc_public_parameters : PC.Public_parameters.prover;
    subgroup_size : int;
    g_map : PC.Polynomial.Polynomial.t SMap.t;
  }

  type verifier_public_parameters = {
    pc_public_parameters : PC.Public_parameters.verifier;
    subgroup_size : int;
    cm_g_map : PC.Commitment.t;
  }

  val verifier_public_parameters_encoding :
    verifier_public_parameters Data_encoding.t

  type prover_query = {
    v_map : (string * PC.Polynomial.Polynomial.t) SMap.t;
    precomputed_polys : Evaluations.t SMap.t;
  }

  (*
     A not_committed is a description of a function of
     type Scalar.t array -> Scalar.t that is easily serializable.
     This is important, as they are part of the verifier public parameters.

     Concretely, [not_committed] is an extensible variant type. A new variant
     is to be added for every new function to represent
     (see [register_nc_eval_and_encoding]).
  *)
  type not_committed = ..

  type verifier_query = {
    v_map : (string * PC.Polynomial.Polynomial.t) SMap.t;
    identities : PC.Scalar.t MP.MonomialMap.t SMap.t;
    not_committed : not_committed SMap.t;
  }

  val verifier_query_encoding : verifier_query Data_encoding.t

  (*
    Register a new [not_committed] variant. To do so, it is necessary to
    provide:
    - The evaluation function, that maps this new variant to [Some foo],
    where foo is the function represented by the new variant, and every
    other variant to [None].
    - The case for the [Data_encoding] encoding.

    NB: [tag] should be used incrementally. Changing the tag of a case will
    break the encoding.
  *)
  val register_nc_eval_and_encoding :
    (not_committed -> (PC.Scalar.t array -> PC.Scalar.t) option) ->
    title:string ->
    tag:int ->
    'b Data_encoding.t ->
    (not_committed -> 'b option) ->
    ('b -> not_committed) ->
    unit

  (* The verifier needs auxiliary infos if the proofs are aggregated*)
  type aggregation_infos = {
    nb_proofs : int SMap.t;
    (* name of polynomials that do not depend on the input*)
    common_keys : string list;
  }

  (* Indication for the verifier*)
  type proof_type = Single | Aggregated of aggregation_infos

  val empty_prover_query : prover_query

  val empty_verifier_query : verifier_query

  val merge_prover_queries : prover_query list -> prover_query

  val merge_verifier_queries :
    ?common_keys:string list -> verifier_query list -> verifier_query

  val sum_prover_queries : prover_query -> prover_query -> prover_query

  val sum_verifier_queries : verifier_query -> verifier_query -> verifier_query

  val update_common_keys_with_v_map :
    ?extra_prefix:string ->
    string list ->
    v_map:(string * PC.Polynomial.Polynomial.t) SMap.t ->
    string list

  val merge_equal_set_of_keys_prover_queries :
    ?extra_prefix:string ->
    len_prefix:int ->
    common_keys:string list ->
    prover_query list ->
    prover_query

  val merge_equal_set_of_keys_verifier_queries :
    ?extra_prefix:string ->
    len_prefix:int ->
    common_keys:string list ->
    verifier_query list ->
    verifier_query

  type transcript = PC.transcript

  val transcript_encoding : transcript Data_encoding.t

  type proof = {pc_proof : PC.answer * PC.proof; cm_t_map : PC.Commitment.t}

  val proof_encoding : proof Data_encoding.t

  (* Computes the public parameters needed for prove & verify
     Inputs:
     - srs_size
     - g_map: preprocessed polynomials
     - subgroup_size
     - srsfile: the name of SRS file in the srs folder from where the SRS will be imported
     Outputs:
     - public_parameters
  *)
  val setup :
    setup_params:PC.Public_parameters.setup_params ->
    PC.secret ->
    subgroup_size:int ->
    string ->
    prover_public_parameters * verifier_public_parameters

  (* Prover function: compute the T polynomial, KZG proofs & polynomials commitments
     Inputs:
     - precommitted_polys: the map of polynomials that have to be commit before calling prove (when it’s called from Main Protocol, it may be the wires)
     - public_parameters: output of setup
     - transcript
     - secret: the map of polynomial that are unknown from the verifier
     - prover_query: the v_map & the precomputed univariate version
     of identities multivariate polynomials
     Outputs:
     - proof: KZG answers & proofs, precommitted_polys & secret polynomials commitments
  *)
  val prove :
    prover_public_parameters ->
    transcript ->
    PC.Commitment.t ->
    PC.secret ->
    prover_query ->
    proof * transcript

  (* Verifier function: checks the proof and that the identities hold
     Inputs:
     - public_parameters: output of setup
     - transcript
     - proof: output of prove
     - verifier_query: the v_map, the identities multivariate polynomials,
     and the polynomials that are needed & not committed by the prover
     (in main protocol, these polynomials are Sid & PI)
     Outputs:
     - bool
  *)
  val verify :
    proof_type:proof_type ->
    verifier_public_parameters ->
    transcript ->
    proof ->
    verifier_query ->
    bool
end

include (Make (Kzg_pack) : Polynomial_protocol_sig)
