(* TODOS:
- comment
- pad t if neccessary
- move aggregation of tables inside prover
- move randomness generation to transcript
- make signature
- use fft for f_poly computation
- generalise n
- use transcript for public param
- use utils signature
- change poly_protocol signature
- *)

(* TODOS Raph:
- compute h3 = interpolation s(2n-1) ... (s(3n-1))
- Add h3 and t(g^n x) in z
- update identity
*)

module Make (PC : Kzg.Polynomial_commitment_sig) = struct
  module PP : Polynomial_protocol.Polynomial_protocol_sig =
    Polynomial_protocol.Make (PC)

  module Scalar = PP.PC.Scalar
  module Domain = PP.PC.Polynomial.Domain
  module Poly = PP.PC.Polynomial.Polynomial
  module Fr_generation = PP.PC.Fr_generation
  module Evaluations = PP.Evaluations
  module Plook = Plookup_gate.Plookup_gate (PP)
  module MP = PP.MP

  type secret = Poly.t list

  type proof = PP.proof

  type transcript = PP.transcript

  type input = Scalar.t list list

  type lookup = Scalar.t array list

  type prover_public_parameters = {
    pp_parameters : PP.prover_public_parameters;
    size_domain : int;
    domain : Domain.t;
    generator : Scalar.t;
    tables : lookup;
    alpha : Scalar.t;
    gates : Scalar.t list SMap.t;
    evaluations : Evaluations.t SMap.t;
  }

  type verifier_public_parameters = {
    pp_parameters : PP.verifier_public_parameters;
    generator : Scalar.t;
    alpha : Scalar.t;
  }

  let setup ?(zero_knowledge = true) nb_wires nb_lookups tables ?(q_table = [])
      srs_file () =
    if q_table != [] then assert (List.length q_table = nb_lookups) ;
    let alpha = Scalar.random () in
    let table_size =
      List.(fold_left (fun acc t -> acc + Array.length (hd t))) 0 tables
    in
    let n = max nb_lookups table_size in
    let log = Z.(log2up (of_int n)) in
    let size_domain = Int.shift_left 1 log in
    let domain = Domain.build ~log in
    let ((pp_prover, pp_verifier), tables) =
      Plook.(
        setup
          ~nb_wires
          ~domain
          ~size_domain
          ~tables
          ~table_size
          ~alpha
          ~srs_file)
    in
    let PP.{pc_public_parameters; g_map; _} = pp_prover in
    let gates =
      let qplook = Array.init size_domain (fun _i -> Scalar.one) in
      let qtable =
        if q_table != [] then
          Array.of_list
          @@ List.pad q_table ~final_size:size_domain ~size:nb_lookups
        else Array.init size_domain (fun _i -> Scalar.zero)
      in
      SMap.of_list [("q_table", qtable); ("q_plookup", qplook)]
    in
    let gates_interpolated =
      SMap.map (Evaluations.interpolation_fft2 domain) gates
    in
    let g_map_updated =
      (* q_table is removed from g_map because this polynomial is not needed for identities ; it is just needed in gates *)
      SMap.(remove "q_table" (union_disjoint g_map gates_interpolated))
    in
    let cm_g_map = PP.PC.Commitment.commit pc_public_parameters g_map_updated in
    let pp_prover = PP.{pp_prover with g_map = g_map_updated} in
    let pp_verifier = PP.{pp_verifier with cm_g_map} in
    let evaluations =
      let n = Poly.degree (SMap.find "L1" g_map) in

      let zk_factor = if zero_knowledge then 1 else 0 in
      let d = Z.of_int (Plook.polynomials_degree ()) in
      let size_domain = Z.(log2up (d * of_int n)) + zk_factor in
      let domain = Domain.build ~log:size_domain in

      PP.Evaluations.compute_evaluations_update_map
        ~evaluations:(SMap.singleton "X" (Evaluations.of_domain domain))
        g_map_updated
    in
    let generator = Domain.get domain 1 in
    ( {
        pp_parameters = pp_prover;
        size_domain;
        domain;
        generator;
        tables;
        alpha;
        gates = SMap.map Array.to_list gates;
        evaluations;
      },
      {pp_parameters = pp_verifier; generator; alpha} )

  let prove ?(zero_knowledge = true) pp f_list transcript =
    let blinds =
      if not zero_knowledge then None
      else Some (Array.init 11 (fun _ -> Scalar.random ()))
    in
    let (beta_gamma, transcript) =
      Fr_generation.generate_random_fr_list transcript 2
    in
    let beta = List.nth beta_gamma 0 and gamma = List.nth beta_gamma 1 in
    let nb_wires = List.length f_list in
    let circuit_size = List.(length (hd f_list)) in
    let f_map =
      let wires =
        let names = [|"a"; "b"; "c"; "d"; "e"; "f"; "g"|] in
        let names = Array.(to_list (sub names 0 nb_wires)) in
        SMap.map
          (fun w ->
            List.resize w ~size:circuit_size ~final_size:(pp.size_domain - 1))
          (SMap.of_list (List.combine names f_list))
      in
      Plook.f_map_contribution
        ~wires
        ~gates:pp.gates
        ~tables:pp.tables
        ~blinds
        ~alpha:pp.alpha
        ~beta
        ~gamma
        ~domain:pp.domain
        ~size_domain:pp.size_domain
        ~circuit_size
        ~ultra:false
    in
    let query =
      Plook.prover_query
        ~generator:pp.generator
        ~alpha:pp.alpha
        ~beta
        ~gamma
        ~f_map
        ~wires_name:[||]
        ~ultra:false
        ~evaluations:pp.evaluations
        ~n:pp.size_domain
        ()
    in
    let pp = pp.pp_parameters in
    let cm_f_map = PP.PC.Commitment.commit pp.pc_public_parameters f_map in
    PP.prove pp transcript cm_f_map f_map query

  let verify pp pi transcript =
    let (beta_gamma, transcript) =
      Fr_generation.generate_random_fr_list transcript 2
    in
    let beta = List.nth beta_gamma 0 and gamma = List.nth beta_gamma 1 in
    let query =
      Plook.verifier_query
        ~generator:pp.generator
        ~wires_name:[||]
        ~alpha:pp.alpha
        ~beta
        ~gamma
        ~ultra:false
        ()
    in
    PP.verify ~proof_type:PP.Single pp.pp_parameters transcript pi query
end

module type Plookup_sig = sig
  module PP : Polynomial_protocol.Polynomial_protocol_sig

  type prover_public_parameters

  type verifier_public_parameters

  type proof

  type input = PP.PC.Scalar.t list list

  type lookup = PP.PC.Scalar.t array list

  type transcript = PP.transcript

  val setup :
    ?zero_knowledge:bool ->
    int ->
    int ->
    lookup list ->
    ?q_table:PP.PC.Scalar.t list ->
    string ->
    unit ->
    prover_public_parameters * verifier_public_parameters

  val prove :
    ?zero_knowledge:bool ->
    prover_public_parameters ->
    input ->
    transcript ->
    proof * transcript

  val verify : verifier_public_parameters -> proof -> transcript -> bool
end

include (Make (Kzg) : Plookup_sig)
