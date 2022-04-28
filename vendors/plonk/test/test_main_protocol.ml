module Scalar = Bls12_381.Fr
module Fr_generation = Plonk.Fr_generation.Make (Scalar)
open Fr_generation

module type PC_sig = Plonk.Kzg.Polynomial_commitment_sig

let zero = Scalar.zero

let one = Scalar.one

let two = Scalar.add one one

let mone = Scalar.negate one

let srsfile = Helpers.srs_path "srs_16"

let smallsrs = Helpers.srs_path "srs_5"

module Internal = struct
  open Plonk.Main_protocol.Make (Plonk.Polynomial_protocol)

  let cycles_list_to_cycles_map cycles_list =
    let cycles_set = List.map IntSet.of_list cycles_list in
    let aux (i, map) s = (i + 1, IntMap.add i s map) in
    let (_, cycles) = List.fold_left aux (0, IntMap.empty) cycles_set in
    cycles

  let test_cycles_to_permutation () =
    let kn = 10 in
    let cycles =
      [[0; 1; 2; 3]; [4; 5; 6]; [7; 8; 9]] |> cycles_list_to_cycles_map
    in
    let permutation = Partition.cycles_to_permutation_map_set kn cycles in
    let res = [|1; 2; 3; 0; 5; 6; 4; 8; 9; 7|] in
    assert (permutation = res) ;
    let t = 300 in
    let kn = 1000 in
    (* i-th cycle is the equivalence class modulo t for integers under kn ; cycles is a partition of [0, kn-1] *)
    let cycles_list =
      let cycles_array = Array.init t (fun _ -> []) in
      let rec aux i =
        if i = -1 then Array.to_list cycles_array
        else
          let p = i mod t in
          cycles_array.(p) <- i :: cycles_array.(p) ;
          aux (i - 1)
      in
      aux (kn - 1)
    in
    let cycles = cycles_list_to_cycles_map cycles_list in
    let permutation = Partition.cycles_to_permutation_map_set kn cycles in
    let verify_cycle_in_permutation cycle =
      let a0 = List.hd cycle in
      let rec aux prec l =
        match l with
        | [] -> permutation.(prec) = a0
        | e :: r -> permutation.(prec) = e && aux e r
      in
      (aux a0 (List.tl cycle), List.length cycle)
    in
    let aux (v_acc, k_acc) cycle =
      let (v, k) = verify_cycle_in_permutation cycle in
      (v && v_acc, k + k_acc)
    in
    let (cycles_in_perm, sum_card_cycles) =
      List.fold_left aux (true, 0) cycles_list
    in
    (* (cycles ⊆ permutation) & (card(cycles) = card(permutation)) => cycles = permutation *)
    assert cycles_in_perm ;
    assert (sum_card_cycles = Array.length permutation)
end

module External (PC : PC_sig) = struct
  open Plonk.Circuit
  module Main = Plonk.Main_protocol.Make (Plonk.Polynomial_protocol.Make (PC))
  module Helpers = Helpers.Make (Main)

  (* ---- Unit tests for each selector. ----
     We make circuits with 2 constraints,
     as circuits with 1 constraint are not supported. *)

  let test_qc ~zero_knowledge () =
    let x = [|zero; one|] in
    let circuit =
      let l = 0 in
      let wires = make_wires ~a:[0; 0] ~b:[0; 0] ~c:[0; 1] () in
      let gates = make_gates ~qo:[zero; mone] ~qc:[zero; one] () in
      make ~wires ~gates ~public_input_size:l ()
    in
    Helpers.test_circuit ~nb_proofs:1 ~zero_knowledge circuit x smallsrs

  let test_ql ~zero_knowledge () =
    let x = [|zero; one|] in
    let circuit =
      let l = 0 in
      let wires = make_wires ~a:[0; 1] ~b:[0; 0] ~c:[0; 1] () in
      let gates = make_gates ~ql:[one; one] ~qo:[zero; mone] () in
      make ~wires ~gates ~public_input_size:l ()
    in
    Helpers.test_circuit ~nb_proofs:1 ~zero_knowledge circuit x smallsrs

  let test_qr ~zero_knowledge () =
    let x = [|zero; one|] in
    let circuit =
      let l = 0 in
      let wires = make_wires ~a:[0; 0] ~b:[0; 1] ~c:[0; 1] () in
      let gates = make_gates ~qr:[one; one] ~qo:[zero; mone] () in
      make ~wires ~gates ~public_input_size:l ()
    in
    Helpers.test_circuit ~nb_proofs:1 ~zero_knowledge circuit x smallsrs

  let test_qlg ~zero_knowledge () =
    let x = [|zero; one|] in
    let circuit =
      let l = 0 in
      let wires = make_wires ~a:[0; 1] ~b:[0; 0] ~c:[1; 0] () in
      let gates = make_gates ~qlg:[one; zero] ~qo:[mone; zero] () in
      make ~wires ~gates ~public_input_size:l ()
    in
    Helpers.test_circuit ~nb_proofs:1 ~zero_knowledge circuit x smallsrs

  let test_qrg ~zero_knowledge () =
    let x = [|zero; one|] in
    let circuit =
      let l = 0 in
      let wires = make_wires ~a:[0; 0] ~b:[0; 1] ~c:[1; 0] () in
      let gates = make_gates ~qrg:[one; zero] ~qo:[mone; zero] () in
      make ~wires ~gates ~public_input_size:l ()
    in
    Helpers.test_circuit ~nb_proofs:1 ~zero_knowledge circuit x smallsrs

  let test_qog ~zero_knowledge () =
    let x = [|zero; one|] in
    let circuit =
      let l = 0 in
      let wires = make_wires ~a:[0; 0] ~b:[0; 0] ~c:[1; 1] () in
      let gates = make_gates ~qog:[one; zero] ~qo:[mone; zero] () in
      make ~wires ~gates ~public_input_size:l ()
    in
    Helpers.test_circuit ~nb_proofs:1 ~zero_knowledge circuit x smallsrs

  let test_qm ~zero_knowledge () =
    let x = [|zero; one|] in
    let circuit =
      let l = 0 in
      let wires = make_wires ~a:[0; 1] ~b:[1; 1] ~c:[0; 1] () in
      let gates = make_gates ~qm:[one; one] ~qo:[zero; mone] () in
      make ~wires ~gates ~public_input_size:l ()
    in
    Helpers.test_circuit ~nb_proofs:1 ~zero_knowledge circuit x smallsrs

  let test_qx5 ~zero_knowledge () =
    let x = [|zero; two; Scalar.of_string "32"|] in
    let circuit =
      let l = 0 in
      let wires = make_wires ~a:[0; 1] ~b:[0; 0] ~c:[0; 2] () in
      let gates = make_gates ~qx5:[one; one] ~qo:[zero; mone] () in
      make ~wires ~gates ~public_input_size:l ()
    in
    Helpers.test_circuit ~nb_proofs:1 ~zero_knowledge circuit x smallsrs

  let test_qecc_ws_add ~zero_knowledge () =
    (* We check that: (3,1) + (4,4) = (2,2).
       These are dummy points, they do not belong to a specific curve. *)
    let x = [|one; two; fr_of_int_safe 3; fr_of_int_safe 4|] in
    let circuit =
      let l = 0 in
      let wires = make_wires ~a:[2; 0] ~b:[3; 3] ~c:[1; 1] () in
      let gates = make_gates ~qecc_ws_add:[one; zero] () in
      make ~wires ~gates ~public_input_size:l ()
    in
    Helpers.test_circuit ~nb_proofs:1 ~zero_knowledge circuit x smallsrs

  let test_qecc_ed_add ~zero_knowledge () =
    let x = [|zero; one|] in
    let circuit =
      let l = 0 in
      let wires = make_wires ~a:[0; 1] ~b:[0; 1] ~c:[0; 1] () in
      let gates = make_gates ~qecc_ed_add:[one; zero] () in
      make ~wires ~gates ~public_input_size:l ()
    in
    Helpers.test_circuit ~nb_proofs:1 ~zero_knowledge circuit x smallsrs

  (* ---- Tests on general circuits. ---- *)
  let test_bnot ~zero_knowledge () =
    let l = 1 in
    let x = [|zero; one|] in
    let wires = Plonk.Circuit.make_wires ~a:[0; 0] ~b:[0; 0] ~c:[1; 0] () in
    let gates = Plonk.Circuit.make_gates ~qo:[mone; mone] ~qc:[one; zero] () in

    let circuit = make ~wires ~gates ~public_input_size:l () in
    Helpers.test_circuit ~nb_proofs:1 ~zero_knowledge circuit x smallsrs

  (*  General tests *)

  (* Proving the relations
       x10 = x0 + x1 * (x2 + x3 * (x4 + x5))
       & P(x2, x0) + Q(x3, x3) = R(x1, x1)

       Using intermediary variables:
       x10 = x0 + x1 * (x2 + x3 * x6)
       x10 = x0 + x1 * (x2 + x7)
       x10 = x0 + x1 * x8
       x10 = x0 + x9
     <=>
     Constraints:
       1*x0 + 1*x9 - 1*x10 + 0*x0*x9 + 0 = 0
       0*x1 + 0*x8 - 1*x9  + 1*x1*x8 + 0 = 0
       1*x2 + 1*x7 - 1*x8  + 0*x2*x7 + 0 = 0
       0*x3 + 0*x6 - 1*x7  + 1*x3*x6 + 0 = 0
       1*x4 + 1*x5 - 1*x6  + 0*x4*x5 + 0 = 0
       F_add_weirestrass(x2, x3, x1, x0, x3, x1) = 0
  *)

  (* Base circuit proves that:
      95 = 1 + 2 * (3 + 4 * (5 + 6))
      with 1 public input
  *)
  let l = 1

  let wires =
    make_wires
      ~a:[0; 1; 2; 3; 4; 2; 0]
      ~b:[9; 8; 7; 6; 5; 3; 3]
      ~c:[10; 9; 8; 7; 6; 1; 1]
      ()

  let gates =
    make_gates
      ~ql:[one; zero; one; zero; one; zero; zero]
      ~qr:[one; zero; one; zero; one; zero; zero]
      ~qo:[mone; mone; mone; mone; mone; zero; zero]
      ~qm:[zero; one; zero; one; zero; zero; zero]
      ~qecc_ws_add:[zero; zero; zero; zero; zero; one; zero]
      ()

  let witness =
    [|
      one;
      two;
      fr_of_int_safe 3;
      fr_of_int_safe 4;
      fr_of_int_safe 5;
      fr_of_int_safe 6;
      fr_of_int_safe 11;
      fr_of_int_safe 44;
      fr_of_int_safe 47;
      fr_of_int_safe 94;
      fr_of_int_safe 95;
    |]

  let test_zero_values ~zero_knowledge () =
    let circuit = make ~wires ~gates ~public_input_size:l () in
    let private_inputs = Array.make 11 zero in
    Helpers.test_circuit
      ~nb_proofs:1
      ~zero_knowledge
      circuit
      private_inputs
      smallsrs

  let test_non_zero_values ~zero_knowledge () =
    let circuit = make ~wires ~gates ~public_input_size:l () in
    Helpers.test_circuit ~nb_proofs:1 ~zero_knowledge circuit witness smallsrs

  let test_no_public_inputs ~zero_knowledge () =
    (* Same test with no public inputs *)
    let circuit_no_public_input =
      Plonk.Circuit.make ~wires ~gates ~public_input_size:0 ()
    in
    Helpers.test_circuit
      ~nb_proofs:1
      ~zero_knowledge
      circuit_no_public_input
      witness
      smallsrs

  let test_wrong_public_inputs ~zero_knowledge () =
    (* Same test with wrong public inputs *)
    let open Plonk.Main_protocol in
    let circuit = make ~wires ~gates ~public_input_size:l () in
    let public = [|one; two; zero|] in
    let ((pp_prover, _), transcript) =
      setup circuit ~srsfile:smallsrs ~nb_proofs:1
    in
    let b =
      try
        let _ =
          prove
            (pp_prover, transcript)
            ~inputs:{public; witness}
            ~zero_knowledge
        in
        false
      with
      (* We expect an error when computing T. *)
      | Rest_not_null _ -> true
      | _ -> false
    in
    assert b

  let test_wrong_values ~zero_knowledge () =
    let circuit = make ~wires ~gates ~public_input_size:l () in
    let x =
      [|
        one;
        two;
        fr_of_int_safe 3;
        fr_of_int_safe 4;
        fr_of_int_safe 5;
        fr_of_int_safe 6;
        fr_of_int_safe 11;
        fr_of_int_safe 44;
        fr_of_int_safe 47;
        fr_of_int_safe 94;
        fr_of_int_safe 94;
      |]
      (* """mistake""" here *)
    in
    Helpers.test_circuit
      ~nb_proofs:1
      ~zero_knowledge
      circuit
      x
      smallsrs
      ~valid_proof:false
      ~proof_exception:true

  let test_big_dummy_circuit ~zero_knowledge () =
    let i = 13 in
    let n = Int.shift_left 1 i in
    let start_build_circuit = Unix.gettimeofday () in
    (* Fibonacci circuit *)
    let m = n + 2 in
    let circuit =
      let l = 0 in
      let wires =
        make_wires
          ~a:(List.init n (fun i -> i))
          ~b:(List.init n (fun i -> i + 1))
          ~c:(List.init n (fun i -> i + 2))
          ()
      in
      let gates =
        make_gates
          ~qo:(List.init n (fun _ -> mone))
          ~ql:(List.init n (fun _ -> one))
          ~qr:(List.init n (fun _ -> one))
          ()
      in
      make ~wires ~gates ~public_input_size:l ()
    in
    let x = Array.init m (fun _ -> Scalar.one) in
    for i = 2 to m - 1 do
      x.(i) <- Scalar.add x.(i - 1) x.(i - 2)
    done ;

    let end_build_circuit = Unix.gettimeofday () in
    Printf.printf "For %d gates (2^%d) and %d wires :\n\n" n i m ;
    Printf.printf
      "Dummy circuit built in %f ms.\n"
      ((end_build_circuit -. start_build_circuit) *. 1000.) ;
    Helpers.test_circuit
      ~nb_proofs:1
      ~zero_knowledge
      circuit
      x
      srsfile
      ~verbose:true

  (* This test checks that the proof given by the aggregation of several correct proofs for different witnesses is verified.
     The circuit computes for input (x0, x1, x3, x4)
      x2 := x0 + x3 + x4
      x5 := x1 + 1
      x6 := x2 * x5
  *)
  let test_aggregation ~zero_knowledge () =
    let x_0 = [|one; one; two; one; zero; two; Scalar.of_int 4|] in
    let x_1 = Scalar.[|two; two; of_int 4; two; zero; of_int 3; of_int 12|] in
    let x_2 = [|one; one; Scalar.of_int 3; one; one; two; Scalar.of_int 6|] in
    let circuit =
      let l = 1 in
      let wires = make_wires ~a:[0; 1; 2] ~b:[3; 4; 5] ~c:[2; 5; 6] () in
      let gates =
        make_gates
          ~ql:[one; one; zero]
          ~qr:[one; zero; zero]
          ~qm:[zero; zero; one]
          ~qo:[mone; mone; mone]
          ~qc:[zero; one; zero]
          ~qrg:[one; zero; zero]
          ()
      in
      make ~wires ~gates ~public_input_size:l ()
    in
    let another_x = Array.map Scalar.of_int [|1; 2; 1; 0; 0; 32; 33|] in
    let another_circuit =
      let l = 1 in
      let wires = make_wires ~a:[0; 1; 2] ~b:[3; 4; 5] ~c:[2; 5; 6] () in
      let gates =
        make_gates
          ~qx5:[one; one; zero]
          ~ql:[zero; zero; one]
          ~qr:[zero; zero; one]
          ~qo:[mone; mone; mone]
          ()
      in
      make ~wires ~gates ~public_input_size:l ()
    in
    let yet_another_x = Array.map Scalar.of_int [|2; 2; 32|] in
    let yet_another_circuit =
      let l = 1 in
      let wires = make_wires ~a:[0] ~b:[1] ~c:[2] () in
      let gates = make_gates ~qx5:[one] ~qo:[mone] () in
      make ~wires ~gates ~public_input_size:l ()
    in
    let circuit_map =
      Main.SMap.of_list
        [
          ("another_circuit", (another_circuit, 2));
          ("circuit", (circuit, 3));
          ("yet_another_circuit", (yet_another_circuit, 1));
        ]
    in
    let x_map =
      Main.SMap.of_list
        [
          ("another_circuit", [another_x; another_x]);
          ("circuit", [x_0; x_1; x_2]);
          ("yet_another_circuit", [yet_another_x]);
        ]
    in
    Helpers.test_circuits ~zero_knowledge circuit_map x_map smallsrs

  let test_aggregation_random ~zero_knowledge ~nb_proofs () =
    Printf.printf "%d proofs :\n" nb_proofs ;
    let generate_witness _ =
      let x0 = Scalar.random () in
      let x1 = Scalar.random () in
      let x3 = Scalar.random () in
      let x4 = Scalar.random () in
      let x2 = Scalar.(x0 + x3 + x4) in
      let x5 = Scalar.(x1 + one) in
      let x6 = Scalar.(x2 * x5) in
      [|x0; x1; x2; x3; x4; x5; x6|]
    in
    let witnesses = List.init nb_proofs generate_witness in
    let circuit =
      let l = 1 in
      let wires = make_wires ~a:[0; 1; 2] ~b:[3; 4; 5] ~c:[2; 5; 6] () in
      let gates =
        make_gates
          ~ql:[one; one; zero]
          ~qr:[one; zero; zero]
          ~qm:[zero; zero; one]
          ~qo:[mone; mone; mone]
          ~qc:[zero; one; zero]
          ~qrg:[one; zero; zero]
          ()
      in
      make ~wires ~gates ~public_input_size:l ()
    in
    Helpers.test_circuits
      ~zero_knowledge
      (Main.SMap.singleton "" (circuit, nb_proofs))
      (Main.SMap.singleton "" witnesses)
      smallsrs
      ~verbose:true

  let test_encodings ~zero_knowledge () =
    let i = 5 in
    let n = Int.shift_left 1 i in
    let m = 3 + (2 * (n - 1)) in
    let circuit =
      let l = 0 in
      let wires =
        make_wires
          ~a:(List.init n (fun i -> i))
          ~b:(List.init n (fun i -> m - 2 - i))
          ~c:(List.init n (fun i -> m - 1 - i))
          ()
      in
      let gates =
        make_gates
          ~qo:(List.init n (fun _ -> mone))
          ~qm:(List.init n (fun _ -> one))
          ()
      in
      make ~wires ~gates ~public_input_size:l ()
    in
    let private_inputs = Array.init m (fun _ -> Scalar.zero) in
    let module Main : Plonk.Main_protocol.Main_protocol_sig =
      Plonk.Main_protocol.Make (Plonk.Polynomial_protocol.Make (PC)) in
    let public_inputs = Array.sub private_inputs 0 circuit.public_input_size in
    let inputs = Main.{witness = private_inputs; public = public_inputs} in
    let ((pp_prover, pp_verifier), transcript) =
      Main.setup ~zero_knowledge circuit ~srsfile ~nb_proofs:1
    in
    let b_pp_verifier =
      Data_encoding.Binary.to_bytes_exn
        Main.verifier_public_parameters_encoding
        pp_verifier
    in
    let b_transcript =
      Data_encoding.Binary.to_bytes_exn Main.transcript_encoding transcript
    in
    let pp_verifier' =
      Data_encoding.Binary.of_bytes_exn
        Main.verifier_public_parameters_encoding
        b_pp_verifier
    in
    let transcript' =
      Data_encoding.Binary.of_bytes_exn Main.transcript_encoding b_transcript
    in
    let (proof, _transcript) =
      Main.prove ~zero_knowledge (pp_prover, transcript) ~inputs
    in
    let b_proof = Data_encoding.Binary.to_bytes_exn Main.proof_encoding proof in
    let proof' =
      Data_encoding.Binary.of_bytes_exn Main.proof_encoding b_proof
    in
    assert (Main.verify (pp_verifier', transcript') ~public_inputs proof') ;
    (* Json *)
    let b_pp_verifier =
      Data_encoding.Json.construct
        Main.verifier_public_parameters_encoding
        pp_verifier
    in
    let b_transcript =
      Data_encoding.Json.construct Main.transcript_encoding transcript
    in
    let _pp_verifier' =
      Data_encoding.Json.destruct
        Main.verifier_public_parameters_encoding
        b_pp_verifier
    in
    let transcript' =
      Data_encoding.Json.destruct Main.transcript_encoding b_transcript
    in
    let (proof, _transcript) =
      Main.prove ~zero_knowledge (pp_prover, transcript) ~inputs
    in
    let b_proof = Data_encoding.Json.construct Main.proof_encoding proof in
    let proof' = Data_encoding.Json.destruct Main.proof_encoding b_proof in
    assert (Main.verify (pp_verifier, transcript') ~public_inputs proof')

  let tests pc_name =
    [
      (Printf.sprintf "%s.test_qc" pc_name, test_qc);
      (Printf.sprintf "%s.test_ql" pc_name, test_ql);
      (Printf.sprintf "%s.test_qr" pc_name, test_qr);
      (Printf.sprintf "%s.test_qlg" pc_name, test_qlg);
      (Printf.sprintf "%s.test_qrg" pc_name, test_qrg);
      (Printf.sprintf "%s.test_qog" pc_name, test_qog);
      (Printf.sprintf "%s.test_qm" pc_name, test_qm);
      (Printf.sprintf "%s.test_qx5" pc_name, test_qx5);
      (Printf.sprintf "%s.test_qecc_ws_add" pc_name, test_qecc_ws_add);
      (Printf.sprintf "%s.test_qecc_ed_add" pc_name, test_qecc_ed_add);
      (Printf.sprintf "%s.test_bnot" pc_name, test_bnot);
      (Printf.sprintf "%s.test_non_zero_values" pc_name, test_non_zero_values);
      (Printf.sprintf "%s.test_no_public_inputs" pc_name, test_no_public_inputs);
      (Printf.sprintf "%s.test_wrong_values" pc_name, test_wrong_values);
      ( Printf.sprintf "%s.test_wrong_public_inputs" pc_name,
        test_wrong_public_inputs );
      (Printf.sprintf "%s.test_aggregation" pc_name, test_aggregation);
      ( Printf.sprintf "%s.test_aggregation_bench" pc_name,
        test_aggregation_random ~nb_proofs:10 );
      (Printf.sprintf "%s.test_encodings" pc_name, test_encodings);
    ]
end

module External_Kzg = External (Plonk.Kzg)
module External_Kzg_pack = External (Plonk.Kzg_pack)

let external_tests =
  let tests_kzg = External_Kzg.tests "KZG" in
  let tests_kzg_pack = External_Kzg_pack.tests "KZG_Pack" in
  tests_kzg @ tests_kzg_pack

let tests =
  [
    Alcotest.test_case
      "test_cycles_to_permutation"
      `Quick
      Internal.test_cycles_to_permutation;
  ]
  @ List.map
      (fun (n, f) -> Alcotest.test_case n `Quick (f ~zero_knowledge:false))
      external_tests
  @ List.map
      (fun (n, f) ->
        Alcotest.test_case (n ^ " zk") `Quick (f ~zero_knowledge:true))
      external_tests

let bench =
  let both_list =
    let nb_proofs = 10 in
    [
      ("Kzg.test_big_dummy_circuit", External_Kzg.test_big_dummy_circuit);
      ( "Kzg_pack.test_big_dummy_circuit",
        External_Kzg_pack.test_big_dummy_circuit );
      ( "Kzg.test_aggregation_bench",
        External_Kzg.test_aggregation_random ~nb_proofs );
      ( "Kzg_pack.test_aggregation_bench",
        External_Kzg_pack.test_aggregation_random ~nb_proofs );
    ]
  in
  List.map
    (fun (n, f) -> Alcotest.test_case n `Slow (f ~zero_knowledge:false))
    both_list
  @ List.map
      (fun (n, f) ->
        Alcotest.test_case (n ^ " zk") `Slow (f ~zero_knowledge:true))
      both_list
