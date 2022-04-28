module Scalar = Bls12_381.Fr
module Fr_generation = Plonk.Fr_generation.Make (Scalar)
open Fr_generation

let zero = Scalar.zero

let one = Scalar.one

let two = Scalar.add one one

let mone = Scalar.negate one

let srsfile = Helpers.srs_path "srs_16"

module type PC_sig = Plonk.Kzg.Polynomial_commitment_sig

module External (PC : PC_sig) = struct
  module PP = Plonk.Polynomial_protocol.Make (PC)
  module Main = Plonk.Main_protocol.Make (PP)
  module Helpers = Helpers.Make (Main)
  open Plonk.Circuit

  (* Tables corresponding to addition of digits mod 5 to perform tests on. *)
  let table_add_mod_5 =
    let m = 5 in
    let t_1 = Array.init (m * m) (fun i -> fr_of_int_safe (i / m)) in
    let t_2 = Array.init (m * m) (fun i -> fr_of_int_safe (i mod m)) in
    let t_3 =
      Array.init (m * m) (fun i -> fr_of_int_safe (((i / m) + (i mod m)) mod m))
    in
    [t_1; t_2; t_3]

  let table_5 =
    let m = 5 in
    let t_1 = Array.init m (fun i -> fr_of_int_safe i) in
    [t_1]

  (* ---- Unit tests for each selector. ----
     We make circuits with at least 2 constraints,
     as circuits with 1 constraint are not supported. *)
  let test_qplookup ~zero_knowledge () =
    let x = [|zero; one; two|] in
    let circuit =
      let l = 0 in
      let wires = Plonk.Circuit.make_wires ~a:[1] ~b:[1] ~c:[2] () in
      let gates =
        Plonk.Circuit.make_gates ~q_plookup:[one] ~q_table:[zero] ()
      in
      Plonk.Circuit.make
        ~wires
        ~gates
        ~tables:[table_add_mod_5]
        ~public_input_size:l
        ()
    in
    Helpers.test_circuit ~nb_proofs:1 ~zero_knowledge circuit x srsfile

  (* ---- Tests on general circuits. ---- *)
  let test_bnot ~zero_knowledge () =
    let l = 0 in
    let x = [|zero; one; two|] in
    let wires =
      Plonk.Circuit.make_wires ~a:[1; 0; 0] ~b:[1; 0; 0] ~c:[2; 1; 0] ()
    in
    let gates =
      Plonk.Circuit.make_gates
        ~qo:[zero; mone; mone]
        ~qc:[zero; one; zero]
        ~q_plookup:[one; zero; zero]
        ~q_table:[zero; zero; zero]
        ()
    in
    let circuit =
      Plonk.Circuit.make
        ~wires
        ~gates
        ~tables:[table_add_mod_5]
        ~public_input_size:l
        ()
    in
    Helpers.test_circuit ~nb_proofs:1 ~zero_knowledge circuit x srsfile

  (* This test should fail as the last constraint is a lookup.
     This is due to the fact that we need for PlookUp, hence UltraPlonk, to pad the lookup tables to the size_domain
     and pad the lookup requests to size_domain - 1. As the wires in TurboPlonk are padded to size_domain (to compute the permutations), this mean that we get rid in plookup_gate of the last constraint which is problematic if it is a lookup. Normally, the Plookup aggregation identity should catch such issue unless the aggregated value sums up to 0 (or the prover is malicious and changes the code), we cannot rule out this possibility however. To avoid such problem, we could either reorganize the lookup queries or increase the domain's size. We decided for simplicity to have the preprocessing done in circuit.ml fail if the last request is a lookup request. *)
  let test_qplookup_fail ~zero_knowledge () =
    try
      let table_add_mod_2 =
        let m = 2 in
        let t_1 = Array.init (m * m) (fun i -> fr_of_int_safe (i / m)) in
        let t_2 = Array.init (m * m) (fun i -> fr_of_int_safe (i mod m)) in
        let t_3 =
          Array.init (m * m) (fun i -> fr_of_int_safe (((i / m) + i) mod m))
        in
        [t_1; t_2; t_3]
      in
      let l = 0 in
      let x = [|zero; one; two; fr_of_int_safe 3|] in
      let wires =
        make_wires ~a:[1; 0; 0; 0] ~b:[1; 0; 0; 0] ~c:[2; 1; 0; 1] ()
      in
      let gates =
        make_gates
          ~qo:[zero; mone; mone; zero]
          ~qc:[zero; one; zero; zero]
          ~q_plookup:[zero; zero; one; one]
          ~q_table:[zero; zero; zero; zero]
          ()
      in
      let circuit =
        Plonk.Circuit.make
          ~wires
          ~gates
          ~tables:[table_add_mod_2]
          ~public_input_size:l
          ()
      in
      Helpers.test_circuit ~nb_proofs:1 ~zero_knowledge circuit x srsfile
      (* FIXME *)
      (* with Entry_not_in_table _ -> () *)
    with _ -> ()

  (* Proving the relations with addition mod 5 using lookups
        x8 = x7 + x1 * (x3 + x4 * (x5 + x6))
        R(x2, x2) = P(x3, x1) + Q(x4, x4) <- these are dummy points
     <=>
     Constraints:
        lookup: x1 (+) x7 = x8
        1*x1*x7 - 1*x7 = 0
        lookup: x3 (+) x4 = x7
        1*x4*x1 - x4 = 0
        lookup: x5 (+) x6 = x1
        F_add_weirestrass(x3, x4, x2, x1, x4, x2) = 0
  *)

  (* Base circuit proves that:
      3 = 2 + 1 * (2 + 2 * (3 + 4))
      R(2,2) = P(3,1) + Q(4,4)
      with 1 public input
  *)
  let l = 1

  let wires =
    Plonk.Circuit.make_wires
      ~a:[1; 1; 4; 2; 4; 3; 1]
      ~b:[2; 1; 2; 2; 3; 4; 4]
      ~c:[3; 1; 1; 4; 2; 2; 2]
      ()

  let gates =
    make_gates
      ~qo:[zero; mone; zero; mone; zero; zero; zero]
      ~qm:[zero; one; zero; one; zero; zero; zero]
      ~qecc_ws_add:[zero; zero; zero; zero; zero; one; zero]
      ~q_plookup:[one; zero; one; zero; one; zero; zero]
      ~q_table:[zero; zero; zero; zero; zero; zero; zero]
      ()

  let x = [|zero; one; two; fr_of_int_safe 3; fr_of_int_safe 4|]

  let test_zero_values ~zero_knowledge () =
    let circuit =
      Plonk.Circuit.make
        ~wires
        ~gates
        ~tables:[table_add_mod_5]
        ~public_input_size:l
        ()
    in
    let x = Array.init 5 (fun _i -> zero) in
    Helpers.test_circuit ~nb_proofs:1 ~zero_knowledge circuit x srsfile

  let test_non_zero_values ~zero_knowledge () =
    let circuit =
      Plonk.Circuit.make
        ~wires
        ~gates
        ~tables:[table_add_mod_5]
        ~public_input_size:l
        ()
    in
    Helpers.test_circuit ~nb_proofs:1 ~zero_knowledge circuit x srsfile

  let test_two_tables ~zero_knowledge () =
    let wires =
      Plonk.Circuit.make_wires
        ~a:[0; 1; 2; 3; 4; 1; 1; 4; 2; 4; 3; 1]
        ~b:[0; 0; 0; 0; 0; 2; 1; 2; 2; 3; 4; 4]
        ~c:[0; 0; 0; 0; 0; 3; 1; 1; 4; 2; 2; 2]
        ()
    in
    let zero_list = List.init (Array.length x) (fun _ -> zero) in
    let one_list = List.init (Array.length x) (fun _ -> one) in
    let gates =
      Plonk.Circuit.make_gates
        ~qo:(zero_list @ [zero; mone; zero; mone; zero; zero; zero])
        ~qm:(zero_list @ [zero; one; zero; one; zero; zero; zero])
        ~qecc_ws_add:(zero_list @ [zero; zero; zero; zero; zero; one; zero])
        ~q_plookup:(one_list @ [one; zero; one; zero; one; zero; zero])
        ~q_table:
          (List.init 12 (fun i -> if i < Array.length x then zero else one))
        ()
    in
    let circuit =
      Plonk.Circuit.make
        ~wires
        ~gates
        ~tables:[table_5; table_add_mod_5]
        ~public_input_size:0
        ()
    in
    Helpers.test_circuit ~nb_proofs:1 ~zero_knowledge circuit x srsfile

  let test_no_public_inputs ~zero_knowledge () =
    let circuit =
      Plonk.Circuit.make
        ~wires
        ~gates
        ~tables:[table_add_mod_5]
        ~public_input_size:0
        ()
    in
    Helpers.test_circuit ~nb_proofs:1 ~zero_knowledge circuit x srsfile

  let test_wrong_public_inputs ~zero_knowledge () =
    (* Same test with wrong public inputs
       the correct ones would be 1, 2 and 3 *)
    let open Plonk.Main_protocol in
    let circuit =
      Plonk.Circuit.make
        ~wires
        ~gates
        ~tables:[table_add_mod_5]
        ~public_input_size:l
        ()
    in
    let public = [|one; zero; fr_of_int_safe 3|] in
    let ((pp_prover, pp_verifier), transcript) =
      setup circuit ~nb_proofs:1 ~zero_knowledge ~srsfile
    in
    let b =
      try
        let (proof, _transcript) =
          prove
            (pp_prover, transcript)
            ~zero_knowledge
            ~inputs:{public; witness = x}
        in
        not (verify (pp_verifier, transcript) ~public_inputs:public proof)
      with
      (* We expect an error when computing T. *)
      | Rest_not_null _ -> true
      | _ -> false
    in
    assert b

  let test_wrong_arith_values ~zero_knowledge () =
    let wires =
      Plonk.Circuit.make_wires
        ~a:[1; 1; 4; 2; 4; 3; 1]
        ~b:[2; 1; 2; 2; 3; 4; 4]
        ~c:[3; 1; 1; 3; 2; 2; 2]
        ()
      (* """mistake""" here in arith. constraint *)
    in
    let circuit =
      Plonk.Circuit.make
        ~wires
        ~gates
        ~tables:[table_add_mod_5]
        ~public_input_size:l
        ()
    in
    Helpers.test_circuit
      ~nb_proofs:1
      circuit
      x
      srsfile
      ~zero_knowledge
      ~valid_proof:false
      ~proof_exception:true

  let test_wrong_plookup_values ~zero_knowledge () =
    let wires =
      Plonk.Circuit.make_wires
        ~a:[0; 1; 4; 2; 4; 3; 1]
        ~b:[2; 1; 2; 2; 3; 4; 4]
        ~c:[3; 1; 1; 4; 2; 2; 2]
        ()
      (* """mistake""" here in lookup constraint *)
    in
    let circuit =
      Plonk.Circuit.make
        ~wires
        ~gates
        ~tables:[table_add_mod_5]
        ~public_input_size:l
        ()
    in
    Helpers.test_circuit
      ~nb_proofs:1
      circuit
      x
      srsfile
      ~zero_knowledge
      ~valid_proof:false
      ~lookup_exception:true

  let test_aggregation ~zero_knowledge () =
    let l = 2 in
    let x_0 = [|one; Scalar.of_int 3; two; zero; Scalar.of_int 3|] in
    let x_1 =
      [|
        Scalar.of_int 4; Scalar.of_int 3; Scalar.of_int 4; zero; Scalar.of_int 3;
      |]
    in
    let x_2 =
      [|zero; Scalar.of_int 3; Scalar.of_int 3; zero; Scalar.of_int 3|]
    in

    let circuit1 =
      let wires = Plonk.Circuit.make_wires ~a:[0; 1] ~b:[2; 3] ~c:[1; 4] () in
      let gates =
        Plonk.Circuit.make_gates
          ~qo:[zero; mone]
          ~q_plookup:[one; zero]
          ~q_table:[zero; zero]
          ~ql:[zero; one]
          ()
      in
      Plonk.Circuit.make
        ~wires
        ~gates
        ~tables:[table_add_mod_5]
        ~public_input_size:l
        ()
    in
    let l = 1 in
    let x = [|zero; one; two|] in
    let circuit2 =
      let wires =
        Plonk.Circuit.make_wires ~a:[1; 0; 0] ~b:[1; 0; 0] ~c:[2; 1; 0] ()
      in
      let gates =
        Plonk.Circuit.make_gates
          ~qo:[zero; mone; mone]
          ~qc:[zero; one; zero]
          ~q_plookup:[one; zero; zero]
          ~q_table:[zero; zero; zero]
          ()
      in
      Plonk.Circuit.make
        ~wires
        ~gates
        ~tables:[table_add_mod_5]
        ~public_input_size:l
        ()
    in
    let circuit_map =
      Main.SMap.of_list [("c1", (circuit1, 3)); ("c2", (circuit2, 1))]
    in
    let x_map = Main.SMap.of_list [("c1", [x_0; x_1; x_2]); ("c2", [x])] in
    Helpers.test_circuits ~zero_knowledge circuit_map x_map srsfile

  let tests pc_name =
    [
      (Printf.sprintf "%s.test_qplookup" pc_name, test_qplookup);
      (Printf.sprintf "%s.test_q_plookup_fail" pc_name, test_qplookup_fail);
      (Printf.sprintf "%s.test_bnot" pc_name, test_bnot);
      (Printf.sprintf "%s.test_zero_values" pc_name, test_zero_values);
      (Printf.sprintf "%s.test_non_zero_values" pc_name, test_non_zero_values);
      (Printf.sprintf "%s.test_two_tables" pc_name, test_two_tables);
      (Printf.sprintf "%s.test_no_public_inputs" pc_name, test_no_public_inputs);
      ( Printf.sprintf "%s.test_wrong_public_inputs" pc_name,
        test_wrong_public_inputs );
      ( Printf.sprintf "%s.test_wrong_arith_values" pc_name,
        test_wrong_arith_values );
      ( Printf.sprintf "%s.test_wrong_plookup_values" pc_name,
        test_wrong_plookup_values );
      (Printf.sprintf "%s.test_aggregation" pc_name, test_aggregation);
    ]
end

module External_Kzg = External (Plonk.Kzg)
module External_Kzg_pack = External (Plonk.Kzg_pack)

let external_tests =
  let tests_kzg = External_Kzg.tests "KZG" in
  let tests_kzg_pack = External_Kzg_pack.tests "KZG_Pack" in
  tests_kzg @ tests_kzg_pack

let tests =
  List.map
    (fun (n, f) -> Alcotest.test_case n `Quick (f ~zero_knowledge:false))
    external_tests
  @ List.map
      (fun (n, f) ->
        Alcotest.test_case (n ^ " zk") `Quick (f ~zero_knowledge:true))
      external_tests
