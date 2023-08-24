open Plonk
module Scalar = Kzg.Bls.Scalar
module SMap = Kzg.SMap

let ( ! ) = List.map Scalar.of_int

let ( !! ) l = List.map Scalar.of_int l |> Array.of_list

type outcome = Valid | Proof_error | Lookup_error

type case = {
  name : string;
  circuit : Circuit.t;
  witness : Scalar.t array;
  outcome : outcome;
}

(* This function aggregates cases ; if several cases concern the same circuit,
   it becomes a circuit with several statements *)
let aggregate_cases ?(prefix = "") cases =
  let outcome = (List.hd cases).outcome in
  let name, circuits_map, inputs_map, outcome =
    List.fold_left
      (fun (name, circuits_map, inputs_map, outcome) case ->
        assert (outcome = case.outcome) ;
        let circuit = case.circuit in
        let other_inputs =
          Option.value ~default:[] @@ SMap.find_opt case.name inputs_map
        in
        let inputs = case.witness :: other_inputs in
        SMap.
          ( (if name = "" then case.name else name ^ "+" ^ case.name),
            add case.name (circuit, List.length inputs) circuits_map,
            add case.name inputs inputs_map,
            outcome ))
      SMap.(prefix, empty, empty, outcome)
      cases
  in
  let inputs_map = SMap.map List.rev inputs_map in
  (name, circuits_map, inputs_map, outcome)

module Unit_tests_for_each_selector = struct
  (* ---- Unit tests for each selector. ----
     We make circuits with 2 constraints,
     as circuits with 1 constraint are not supported. *)

  let qc =
    let name = "qc" in
    let witness = !![0; 1] in
    let circuit =
      let wires =
        let a = [0; 0] in
        let b = [0; 0] in
        let c = [0; 1] in
        [|a; b; c|]
      in
      let qo = ![0; -1] in
      let gates = Circuit.make_gates ~linear:[(2, qo)] ~qc:![0; 1] () in
      Circuit.make ~wires ~gates ~public_input_size:0 ()
    in
    {name; circuit; witness; outcome = Valid}

  let linear_selector_test i =
    (* We don't have a test for "qo" *)
    assert (i <> 2) ;
    let name = Plompiler.Csir.linear_selector_name i in
    let witness = !![0; 1] in
    let circuit =
      let wires =
        Array.init Plompiler.Csir.nb_wires_arch (fun j ->
            if j = i || j = 2 then [0; 1] else [0; 0])
      in
      let q_linear = ![1; 1] in
      let qo = ![0; -1] in
      let linear = [(i, q_linear); (2, qo)] in
      let gates = Circuit.make_gates ~linear () in
      Circuit.make ~wires ~gates ~public_input_size:0 ()
    in
    {name; circuit; witness; outcome = Valid}

  let next_linear_selector_test i =
    let name =
      Plompiler.Csir.(linear_selector_name i |> add_next_wire_suffix)
    in
    let witness = !![0; 1] in
    let circuit =
      let wires =
        Array.init Plompiler.Csir.nb_wires_arch (fun j ->
            if j = 2 then if i = 2 then [1; 1] else [1; 0]
            else if j = i then [0; 1]
            else [0; 0])
      in
      let gates =
        Circuit.make_gates ~linear:[(2, ![-1; 0])] ~linear_g:[(i, ![1; 0])] ()
      in
      Circuit.make ~wires ~gates ~public_input_size:0 ()
    in
    {name; circuit; witness; outcome = Valid}

  let qm =
    let name = "qm" in
    let witness = !![0; 1] in
    let circuit =
      let wires =
        let a = [0; 1] in
        let b = [1; 1] in
        let c = [0; 1] in
        [|a; b; c|]
      in
      let gates = Circuit.make_gates ~qm:![1; 1] ~linear:[(2, ![0; -1])] () in
      Circuit.make ~wires ~gates ~public_input_size:0 ()
    in
    {name; circuit; witness; outcome = Valid}

  let qx2b =
    let name = "qx2b" in
    let witness = !![0; -3; 3; 9] in
    let circuit =
      let wires =
        let a = [0; 0; 0] in
        let b = [0; 1; 2] in
        let c = [0; 3; 3] in
        [|a; b; c|]
      in
      let gates =
        Circuit.make_gates ~qx2b:![1; 1; 1] ~linear:[(2, ![0; -1; -1])] ()
      in
      Circuit.make ~wires ~gates ~public_input_size:0 ()
    in
    {name; circuit; witness; outcome = Valid}

  let qx5a =
    let name = "qx5a" in
    let witness = !![0; 2; 32] in
    let circuit =
      let wires =
        let a = [0; 1] in
        let b = [0; 0] in
        let c = [0; 2] in
        [|a; b; c|]
      in
      let gates = Circuit.make_gates ~qx5a:![1; 1] ~linear:[(2, ![0; -1])] () in
      Circuit.make ~wires ~gates ~public_input_size:0 ()
    in
    {name; circuit; witness; outcome = Valid}

  let qx5c =
    let name = "qx5c" in
    let witness = !![0; 243; 3] in
    let circuit =
      let wires =
        let a = [0; 1] in
        let b = [0; 0] in
        let c = [0; 2] in
        [|a; b; c|]
      in
      let gates = Circuit.make_gates ~qx5c:![1; 1] ~linear:[(0, ![0; -1])] () in
      Circuit.make ~wires ~gates ~public_input_size:0 ()
    in
    {name; circuit; witness; outcome = Valid}

  let qecc_ws_add =
    let name = "qecc_ws_add" in
    (* We check that: (3,1) + (4,4) = (2,2).
       These are dummy points, they do not belong to a specific curve. *)
    let witness = !![1; 2; 3; 4] in
    let circuit =
      let wires =
        let a = [2; 0] in
        let b = [3; 3] in
        let c = [1; 1] in
        [|a; b; c|]
      in
      let gates = Circuit.make_gates ~qecc_ws_add:![1; 0] () in
      Circuit.make ~wires ~gates ~public_input_size:0 ()
    in
    {name; circuit; witness; outcome = Valid}

  let qecc_ed_add =
    let name = "qecc_ed_add" in
    let witness = !![0; 1] in
    let circuit =
      let wires =
        let a = [0; 1] in
        let b = [0; 1] in
        let c = [0; 1] in
        [|a; b; c|]
      in
      let gates = Circuit.make_gates ~qecc_ed_add:![1; 0] () in
      Circuit.make ~wires ~gates ~public_input_size:0 ()
    in
    {name; circuit; witness; outcome = Valid}

  let qecc_ed_cond_add =
    let name = "qecc_cond_ed_add" in
    (* In the first 2 constraints we are doing A(0;1) + 0B(2;3) = C(1;2);
       in the other 2, A(0;1) + 1B(0;1) = C(0;1) *)
    let witness = !![0; 1; 2; 3] in
    let circuit =
      let wires =
        let a = [0; 0; 1; 0] in
        let b = [2; 0; 0; 0] in
        let c = [3; 0; 1; 0] in
        let d = [1; 1; 0; 0] in
        let e = [2; 2; 1; 1] in
        [|a; b; c; d; e|]
      in
      let gates = Circuit.make_gates ~qecc_ed_cond_add:![1; 0; 1; 0] () in
      Circuit.make ~wires ~gates ~public_input_size:0 ()
    in
    {name; circuit; witness; outcome = Valid}

  let qbool =
    let name = "qbool" in
    let witness = !![0; 1] in
    let circuit =
      let wires =
        let a = [0; 1] in
        let b = [0; 0] in
        let c = [0; 0] in
        [|a; b; c|]
      in
      let gates = Circuit.make_gates ~qbool:![1; 1] () in
      Circuit.make ~wires ~gates ~public_input_size:0 ()
    in
    {name; circuit; witness; outcome = Valid}

  let qcond_swap =
    let name = "qcond_swap" in
    let witness = !![0; 1; 2] in
    let circuit =
      let wires =
        let a = [0; 1] in
        let b = [1; 1] in
        let c = [2; 2] in
        let d = [1; 2] in
        let e = [2; 1] in
        [|a; b; c; d; e|]
      in
      let gates = Circuit.make_gates ~qcond_swap:![1; 1] () in
      Circuit.make ~wires ~gates ~public_input_size:0 ()
    in
    {name; circuit; witness; outcome = Valid}

  let q_anemoi =
    let name = "q_anemoi" in
    let x0 = "1" in
    let y0 = "1" in
    let x1 =
      "39027417478195954763090966714903261667484379123570980405377627458504913299628"
    in
    let y1 =
      "12807118572207854608879870979725669075358379219019309928321803168748017551407"
    in
    let x2 =
      "16347289160862248212893857406118677211322091184422502665988411845410114556281"
    in

    let y2 =
      "7279269625797671375403766084307099687590046281141194129086784189878517048332"
    in

    let kx1 = Scalar.of_string "39" in
    let ky1 =
      Scalar.of_string
        "14981678621464625851270783002338847382197300714436467949315331057125308909900"
    in
    let kx2 =
      Scalar.of_string
        "41362478282768062297187132445775312675360473883834860695283235286481594490621"
    in
    let ky2 =
      Scalar.of_string
        "28253420209785428420233456008091632509255652343634529984400816700490470131093"
    in
    let witness = Array.map Scalar.of_string [|"0"; x0; y0; x1; y1; x2; y2|] in
    let circuit =
      let wires =
        let a = [0; 0; 0; 0] in
        let b = [0; 0; 3; 0] in
        let c = [0; 0; 4; 0] in
        let d = [0; 0; 1; 5] in
        let e = [0; 0; 2; 6] in
        [|a; b; c; d; e|]
      in
      let precomputed_advice =
        SMap.of_list
          [
            ("qadv0", Scalar.[zero; zero; kx1; zero]);
            ("qadv1", Scalar.[zero; zero; ky1; zero]);
            ("qadv2", Scalar.[zero; zero; kx2; zero]);
            ("qadv3", Scalar.[zero; zero; ky2; zero]);
          ]
      in
      let gates =
        Circuit.make_gates
          ~q_anemoi:Scalar.[zero; zero; one; zero]
          ~linear:[(0, ![1; 1; 0; 0]); (1, ![1; 0; 0; 0])]
          ~precomputed_advice
          ()
      in
      Circuit.make ~wires ~gates ~public_input_size:0 ()
    in
    {name; circuit; witness; outcome = Valid}

  let list =
    let wires = List.init Plompiler.Csir.nb_wires_arch Fun.id in
    (qc :: List.map linear_selector_test (List.filter (fun i -> i <> 2) wires))
    @ List.map next_linear_selector_test wires
    @ [
        qm;
        qx2b;
        qx5a;
        qx5c;
        qecc_ws_add;
        qecc_ed_add;
        qecc_ed_cond_add;
        qbool;
        qcond_swap;
        q_anemoi;
      ]
end

module General_circuits = struct
  let bnot =
    let name = "bnot" in
    let witness = !![0; 1] in
    let circuit =
      let wires =
        let a = [0; 0] in
        let b = [0; 0] in
        let c = [1; 0] in
        [|a; b; c|]
      in
      let gates = Circuit.make_gates ~linear:[(2, ![-1; -1])] ~qc:![1; 0] () in
      Circuit.make ~wires ~gates ~public_input_size:1 ()
    in
    {name; circuit; witness; outcome = Valid}

  let list = [bnot]
end

module General = struct
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

  let wires =
    let a = [0; 1; 2; 3; 4; 2; 0] in
    let b = [9; 8; 7; 6; 5; 3; 3] in
    let c = [10; 9; 8; 7; 6; 1; 1] in
    [|a; b; c|]

  let gates =
    Circuit.make_gates
      ~linear:
        [
          (0, ![1; 0; 1; 0; 1; 0; 0]);
          (1, ![1; 0; 1; 0; 1; 0; 0]);
          (2, ![-1; -1; -1; -1; -1; 0; 0]);
        ]
      ~qm:![0; 1; 0; 1; 0; 0; 0]
      ~qecc_ws_add:![0; 0; 0; 0; 0; 1; 0]
      ()

  let circuit = Circuit.make ~wires ~gates ~public_input_size:1 ()

  let witness = !![1; 2; 3; 4; 5; 6; 11; 44; 47; 94; 95]

  let zero_values =
    let name = "zero_values" in
    let witness = Array.make 11 (Scalar.of_int 0) in
    {name; circuit; witness; outcome = Valid}

  let non_zero_values =
    let name = "non_zero_values" in
    {name; circuit; witness; outcome = Valid}

  (* Same test with no public inputs *)
  let no_public_inputs =
    let name = "no_public_inputs" in
    let circuit = Circuit.make ~wires ~gates ~public_input_size:0 () in
    {name; circuit; witness; outcome = Valid}

  let wrong_values =
    let name = "wrong_values" in
    let witness =
      !![1; 2; 3; 4; 5; 6; 11; 44; 47; 94; 94]
      (* """mistake""" here *)
    in
    {name; circuit; witness; outcome = Proof_error}

  let input_com =
    let name = "input_commitment" in
    let circuit =
      Circuit.make ~wires ~gates ~public_input_size:0 ~input_com_sizes:[3; 1] ()
    in
    {name; circuit; witness; outcome = Valid}

  let list =
    [zero_values; non_zero_values; no_public_inputs; wrong_values; input_com]

  let list_one_public_input = [zero_values; non_zero_values; wrong_values]
end

module Range_Checks = struct
  open General

  let public_input_size = 0

  let valid =
    let name = "RC_single_valid" in
    let circuit =
      Plonk.Circuit.make
        ~wires
        ~gates
        ~public_input_size
        ~range_checks:(SMap.of_list [("w0", [(4, 4); (6, 4)])])
        ()
    in
    {name; circuit; witness; outcome = Valid}

  let wrong =
    let name = "RC_single_wrong" in
    let circuit =
      Plonk.Circuit.make
        ~wires
        ~gates
        ~public_input_size
        ~range_checks:(SMap.of_list [("w0", [(1, 2); (3, 4); (4, 2)])])
        ()
    in
    {name; circuit; witness; outcome = Proof_error}

  let basic =
    let circuit =
      (* This circuit takes x₁ & x₂ (given as first elements of d & e) as inputs and
         rangechecks the outputs x₁ + x₂ & 3×x₁ + x₂ given in a
         We also bound x₂ as the first value of e (in order to check bounds on other wires)
      *)
      let gates =
        Circuit.make_gates
          ~linear:[(0, ![-1; -1]); (3, ![1; 3]); (4, ![1; 1])]
          ()
      in
      let wires = [|[2; 3]; [0; 0]; [0; 0]; [0; 0]; [1; 1]|] in
      Circuit.make
        ~wires
        ~gates
        ~public_input_size:0
        ~range_checks:
          (SMap.of_list [("w0", [(0, 3); (1, 4)]); ("w4", [(0, 2)])])
        ()
    in
    let get_witness x1 x2 =
      let x1 = Scalar.of_int x1 in
      let x2 = Scalar.of_int x2 in
      let x3 = Scalar.(x1 + x2) in
      let x4 = Scalar.((of_int 3 * x1) + x2) in
      [|x1; x2; x3; x4|]
    in
    let witness = get_witness 4 3 in
    {name = "basic"; circuit; witness; outcome = Valid}

  let list = [valid; wrong; basic]
end

module Mod_Arith = struct
  let add_mod_25519 ?(valid = true) ?(sub = false) case_name ~x ~y ~z ~qm ~tj =
    let prefix = if sub then "sub" else "add" in
    let name = prefix ^ "_mod_2^255-19." ^ case_name in
    (* addition mod 2^255-19, we have;
        |moduli| = [base] = [2^85]
        qm_shift := -1
        tj_shift := -32767
    *)
    (* if there is no wrap-around, we will have qm = 1 and tj = 32767 *)
    (* if there is wrap-around 2^255 - 19, qm = 2 (so that qm + qm_shift = 1)
       and tj = 32767 . *)
    let base = Z.(shift_left one 85) in
    let xs = Plompiler.Utils.z_to_limbs ~len:3 ~base x in
    let ys = Plompiler.Utils.z_to_limbs ~len:3 ~base y in
    let zs = Plompiler.Utils.z_to_limbs ~len:3 ~base z in
    let xs, zs = if sub then (zs, xs) else (xs, zs) in
    let witness =
      (Z.zero :: xs) @ ys @ [qm; tj] @ zs
      |> List.map Scalar.of_z |> Array.of_list
    in
    let circuit =
      let wires =
        let a = [1; 9] in
        let b = [2; 10] in
        let c = [3; 11] in
        let d = [4; 7] in
        let e = [5; 8] in
        let f = [6; 0] in
        [|a; b; c; d; e; f|]
      in
      let gates = Circuit.make_gates ~q_mod_add:[("25519", ![1; 0])] () in
      Circuit.make ~wires ~gates ~public_input_size:0 ()
    in
    {name; circuit; witness; outcome = (if valid then Valid else Proof_error)}

  let mod_add_tests_25519 =
    let ( ! ) = Z.of_int in
    let m = Z.(shift_left one 255 - of_int 19) in
    let tj = !32767 in
    let sub = true in
    [
      add_mod_25519 "no_wrap_around" ~x:!5 ~y:!6 ~z:!11 ~qm:!1 ~tj;
      add_mod_25519 "wrap_around" ~x:Z.(m - !1) ~y:!2 ~z:!1 ~qm:!2 ~tj;
      add_mod_25519 "non-std out" ~x:Z.(m - !1) ~y:!4 ~z:Z.(m + !3) ~qm:!1 ~tj;
      add_mod_25519 ~valid:false "invalid" ~x:!0 ~y:!1 ~z:!2 ~qm:!1 ~tj;
      add_mod_25519 ~valid:false "invalid qm" ~x:!1 ~y:!2 ~z:!3 ~qm:!0 ~tj;
      add_mod_25519 ~valid:false "invalid tj" ~x:!1 ~y:!2 ~z:!3 ~qm:!1 ~tj:!0;
      add_mod_25519 "no_wrap_around" ~sub ~x:!8 ~y:!2 ~z:!6 ~qm:!1 ~tj;
      add_mod_25519 "wrap_around" ~sub ~x:!8 ~y:Z.(m - !2) ~z:!10 ~qm:!2 ~tj;
      add_mod_25519 ~valid:false ~sub "invalid" ~x:!0 ~y:!1 ~z:!1 ~qm:!1 ~tj;
    ]

  let add_mod_64 ?(valid = true) ?(sub = false) case_name ~x ~y ~z ~qm =
    let prefix = if sub then "sub" else "add" in
    let name = prefix ^ "_mod_2^64." ^ case_name in
    let m = Z.(shift_left one 64) in
    let xs = Plompiler.Utils.z_to_limbs ~len:1 ~base:m x in
    let ys = Plompiler.Utils.z_to_limbs ~len:1 ~base:m y in
    let zs = Plompiler.Utils.z_to_limbs ~len:1 ~base:m z in
    let xs, zs = if sub then (zs, xs) else (xs, zs) in
    (*
       PlonK wires distribution:
        row i   : x0 y0 0 0 0 0
        row i+1 : z0 qm 0 0 0 0
    *)
    let witness =
      (Z.zero :: xs) @ ys @ [qm] @ zs |> List.map Scalar.of_z |> Array.of_list
    in
    let circuit =
      let wires =
        let a = [1; 4] in
        let b = [2; 3] in
        let c = [0; 0] in
        let d = [0; 0] in
        let e = [0; 0] in
        let f = [0; 0] in
        [|a; b; c; d; e; f|]
      in
      let gates = Circuit.make_gates ~q_mod_add:[("64", ![1; 0])] () in
      Circuit.make ~wires ~gates ~public_input_size:0 ()
    in
    {name; circuit; witness; outcome = (if valid then Valid else Proof_error)}

  let mod_add_tests_64 =
    let ( ! ) = Z.of_int in
    let m = Z.(shift_left one 64) in
    let sub = true in
    [
      add_mod_64 "no_wrap_around" ~x:!5 ~y:!6 ~z:!11 ~qm:!0;
      add_mod_64 "wrap_around" ~x:Z.(m - !1) ~y:!2 ~z:!1 ~qm:!1;
      add_mod_64 ~valid:false "invalid" ~x:!0 ~y:!1 ~z:!2 ~qm:!0;
      add_mod_64 "no_wrap_around" ~sub ~x:!8 ~y:!2 ~z:!6 ~qm:!0;
      add_mod_64 "wrap_around" ~sub ~x:!8 ~y:Z.(m - !2) ~z:!10 ~qm:!1;
      add_mod_64 ~valid:false ~sub "invalid" ~x:!0 ~y:!1 ~z:!1 ~qm:!0;
    ]

  let mul_mod_25519 ?(valid = true) ?(div = false) case_name ~x ~y ~z ~qm ~t1
      ~t2 =
    let prefix = if div then "div" else "mul" in
    let name = prefix ^ "_mod_2^255-19." ^ case_name in
    (* multiplication mod 2^255-19, we have;
        |moduli| = [base; base-1] = [2^85; 2^85-1]
        qm_shift := -1
        t1_shift := -1237940039285380274899123616
        t2_shift := -1237940039285380274899123649
    *)
    let base = Z.(shift_left one 85) in
    let xs = Plompiler.Utils.z_to_limbs ~len:3 ~base x in
    let ys = Plompiler.Utils.z_to_limbs ~len:3 ~base y in
    let zs = Plompiler.Utils.z_to_limbs ~len:3 ~base z in
    let xs, zs = if div then (zs, xs) else (xs, zs) in
    let witness =
      xs @ ys @ [qm; t1; t2] @ zs |> List.map Scalar.of_z |> Array.of_list
    in
    let circuit =
      let wires =
        let a = [0; 9] in
        let b = [1; 10] in
        let c = [2; 11] in
        let d = [3; 6] in
        let e = [4; 7] in
        let f = [5; 8] in
        [|a; b; c; d; e; f|]
      in
      let gates = Circuit.make_gates ~q_mod_mul:[("25519", ![1; 0])] () in
      Circuit.make ~wires ~gates ~public_input_size:0 ()
    in
    {name; circuit; witness; outcome = (if valid then Valid else Proof_error)}

  let mod_mul_tests_25519 =
    let ( ! ) = Z.of_int in
    let m = Z.(shift_left one 255 - of_int 19) in
    (* The correct t1, t2 when there is no wrap-around: *)
    let t1 = Z.of_string "1237940039285380274899123616" in
    let t2 = Z.of_string "1237940039285380274899123649" in
    let div = true in
    [
      mul_mod_25519 "no_wrap_around" ~x:!7 ~y:!13 ~z:!91 ~qm:!1 ~t1 ~t2;
      mul_mod_25519
        "wrap_around"
        ~x:Z.(m - !1)
        ~y:!2
        ~z:Z.(m - !2)
        ~qm:!2
        ~t1
        ~t2:(Z.of_string "1237940039285380274899123651");
      mul_mod_25519
        "non-std out"
        ~x:Z.(m - !1)
        ~y:Z.(m - !3)
        ~z:Z.(m + !3)
        ~qm:(Z.of_string "116056878683004400771792871")
        ~t1:(Z.of_string "2630622583481433084160638332")
        ~t2:(Z.of_string "3559077612945468290334981463");
      mul_mod_25519 ~valid:false "invalid" ~x:!0 ~y:!1 ~z:!1 ~qm:!1 ~t1 ~t2;
      mul_mod_25519 ~valid:false "invalid qm" ~x:!1 ~y:!2 ~z:!2 ~qm:!2 ~t1 ~t2;
      mul_mod_25519
        ~valid:false
        "invalid t1"
        ~x:!1
        ~y:!2
        ~z:!2
        ~qm:!1
        ~t1:!0
        ~t2;
      mul_mod_25519
        ~valid:false
        "invalid t2"
        ~x:!1
        ~y:!2
        ~z:!2
        ~qm:!1
        ~t1
        ~t2:!0;
      mul_mod_25519 "no_wrap_around" ~div ~x:!9009 ~y:!9 ~z:!1001 ~qm:!1 ~t1 ~t2;
      mul_mod_25519
        "wrap_around"
        ~div
        ~x:!8
        ~y:Z.(m - !2)
        ~z:Z.(m - !4)
        ~qm:(Z.of_string "116056878683004400771792870")
        ~t1:(Z.of_string "2630622583481433084160638332")
        ~t2:(Z.of_string "3559077612945468290334981461");
      mul_mod_25519
        "invalid"
        ~valid:false
        ~div
        ~x:!10
        ~y:!2
        ~z:!3
        ~qm:!1
        ~t1
        ~t2;
    ]

  let mul_mod_64 ?(valid = true) case_name ~x ~y ~z ~qm =
    let name = "mul_mod_2^64." ^ case_name in
    let m = Z.(shift_left one 64) in
    let xs = Plompiler.Utils.z_to_limbs ~len:1 ~base:m x in
    let ys = Plompiler.Utils.z_to_limbs ~len:1 ~base:m y in
    let zs = Plompiler.Utils.z_to_limbs ~len:1 ~base:m z in
    let witness =
      (Z.zero :: xs) @ ys @ [qm] @ zs |> List.map Scalar.of_z |> Array.of_list
    in
    let circuit =
      let wires =
        let a = [1; 4] in
        let b = [2; 3] in
        let c = [0; 0] in
        let d = [0; 0] in
        let e = [0; 0] in
        let f = [0; 0] in
        [|a; b; c; d; e; f|]
      in
      let gates = Circuit.make_gates ~q_mod_mul:[("64", ![1; 0])] () in
      Circuit.make ~wires ~gates ~public_input_size:0 ()
    in
    {name; circuit; witness; outcome = (if valid then Valid else Proof_error)}

  let mod_mul_tests_64 =
    let ( ! ) = Z.of_int in
    let m = Z.(shift_left one 64) in
    [
      mul_mod_64 "no_wrap_around" ~x:!7 ~y:!13 ~z:!91 ~qm:!0;
      mul_mod_64 "wrap_around" ~x:Z.(m - !1) ~y:!2 ~z:Z.(m - !2) ~qm:!1;
      mul_mod_64 ~valid:false "invalid" ~x:!0 ~y:!1 ~z:!1 ~qm:!1;
      mul_mod_64 ~valid:false "invalid qm" ~x:!1 ~y:!2 ~z:!2 ~qm:!2;
    ]

  let list =
    mod_add_tests_25519 @ mod_add_tests_64 @ mod_mul_tests_25519
    @ mod_mul_tests_64
end

module Big_circuit = struct
  (* generates circuit with 2^k - 1 constraints that adds 2^(k + 1) inputs 4 by 4,
     then adds 2^(k-1) inputs 2 by 2, then multiplies 2^(k-2) inputs 2 by 2, and
     repeat the two last steps until there is 1 output left.
     At each gate of the circuit, a random scalar is also added. There
     is a total of k-1 layers of gates, i-th layer contains 2^i gates (starting
     from the "output layer", numbering from 0 to i-1)
     IMPORTANT : with aPlonK, this case is intended to fit PI_rollup_example
     module, which means 2 public inputs and the first element of each witness
     equal to the second element of the previous witness.
  *)
  let make ~nb_proofs ~public_input_size ~k =
    let name = Format.sprintf "big_circuit.%i.%i" public_input_size k in
    let len_fst_layer = 1 lsl (k - 1) in
    (* for wires d & e : [[d₁ ; e₁] ; [d₂ ; e₂] ; …]. They are handled
       separately because they are only in the first gate & we don’t want to
       involve them in the loop *)
    let e_d =
      Array.init len_fst_layer (fun _ -> Scalar.[|random (); random ()|])
    in
    let witness nb_proofs k qc =
      let rec build_w (acc_w_left, acc_w_right) =
        let l = List.hd acc_w_left in
        let r = List.hd acc_w_right in
        let len_l = Array.length l in
        assert (Array.(len_l = length r)) ;
        let op =
          if List.length acc_w_left mod 2 = 0 then Scalar.mul else Scalar.add
        in
        let add_qc i =
          let i_constraint =
            let lens =
              List.(fold_left (fun i l -> i + Array.length l))
                0
                (acc_w_left @ acc_w_right)
            in
            lens - (1 lsl k) + i
          in
          Scalar.(add qc.(i_constraint))
        in
        if len_l = 1 then
          (* We are at the last layer, there is only 1 gate left *)
          let last = add_qc 0 (op l.(0) r.(0)) in
          Array.(
            concat
              List.(rev acc_w_left @ rev acc_w_right @ [[|last|]] @ to_list e_d))
        else if len_l = len_fst_layer then
          let wl =
            Array.init (len_l / 2) (fun i ->
                let j = 2 * i in
                add_qc j Scalar.(l.(j) + r.(j) + e_d.(j).(0) + e_d.(j).(1)))
          in
          let wr =
            Array.init (len_l / 2) (fun i ->
                let j = (2 * i) + 1 in
                add_qc j Scalar.(l.(j) + r.(j) + e_d.(j).(0) + e_d.(j).(1)))
          in
          build_w (wl :: acc_w_left, wr :: acc_w_right)
        else
          let wl =
            Array.init (len_l / 2) (fun i ->
                add_qc (2 * i) (op l.(2 * i) r.(2 * i)))
          in
          let wr =
            Array.init (len_l / 2) (fun i ->
                add_qc ((2 * i) + 1) (op l.((2 * i) + 1) r.((2 * i) + 1)))
          in
          build_w (wl :: acc_w_left, wr :: acc_w_right)
      in
      let open Stdlib (* to recover the ! deref operator *) in
      let w0 = ref (Scalar.random ()) in
      List.init nb_proofs (fun _ ->
          let w =
            let w_left =
              Array.init len_fst_layer (fun i ->
                  if i = 0 then !w0 else Scalar.random ())
            in
            let w_right =
              Array.init len_fst_layer (fun _ -> Scalar.random ())
            in

            build_w ([w_left], [w_right])
          in
          w0 := w.(1) ;
          w)
    in
    let n = (1 lsl k) - 1 in
    let qc = List.init n (fun _ -> Scalar.random ()) in
    let circuit =
      let wires =
        let last_c = 2 * n in
        let a = List.init n Fun.id in
        let b = List.init n (fun i -> n + i) in
        let c =
          List.init (n / 2) (fun i ->
              let i = (1 lsl (k - 1)) + i in
              [i; n + i])
          @ [[last_c]]
          |> List.concat
        in
        let d =
          List.init n (fun i ->
              if i < len_fst_layer then last_c + ((2 * i) + 1) else 0)
        in
        let e =
          List.mapi (fun i x -> if i < len_fst_layer then x + 1 else 0) d
        in
        [|a; b; c; d; e|]
      in
      let gates =
        let is_add k n i =
          let dist = k - Z.(log2 (of_int (Int.sub n i))) in
          if dist mod 2 = 0 then false else true
        in
        let qm = List.init n (fun i -> if is_add k n i then 0 else 1) in
        let ql = List.init n (fun i -> if is_add k n i then 1 else 0) in
        let qr = ql in
        let qo = List.init n (fun _ -> -1) in
        let qd = List.init n (fun i -> if i < 1 lsl (k - 1) then 1 else 0) in
        let qe = qd in
        Circuit.Circuit.make_gates
          ~qm:!qm
          ~linear:[(0, !ql); (1, !qr); (2, !qo); (3, !qd); (4, !qe)]
          ~qc
          ()
      in
      Circuit.make ~wires ~gates ~public_input_size ()
    in
    let witnesses = witness nb_proofs k (Array.of_list qc) in
    List.map
      (fun witness -> {name; circuit; witness; outcome = Valid})
      witnesses

  let list = make ~nb_proofs:2 ~public_input_size:2 ~k:5

  let list_slow = make ~nb_proofs:2 ~public_input_size:2 ~k:16
end

let list =
  Unit_tests_for_each_selector.list @ General_circuits.list @ General.list
  @ Mod_Arith.list @ Big_circuit.list

let list_slow = Big_circuit.list_slow

module Lookup = struct
  (* Tables corresponding to addition of digits mod m to perform tests on. *)
  let table_add_mod_m m =
    let m2 = m * m in
    let t_1 = List.init m2 (fun i -> i / m) in
    let t_2 = List.init m2 (fun i -> i mod m) in
    let t_3 = List.init m2 (fun i -> ((i / m) + i) mod m) in
    [!!t_1; !!t_2; !!t_3]

  let table_add_mod_5 = table_add_mod_m 5

  let table_add_mod_10 = table_add_mod_m 10

  (* ---- Unit tests for each selector. ---- *)
  let qplookup =
    let name = "qplookup" in
    let witness = !![0; 1; 2] in
    let circuit =
      let a = [1] in
      let b = [1] in
      let c = [2] in
      let wires = [|a; b; c|] in
      let gates = Circuit.make_gates ~q_plookup:![1] ~q_table:![0] () in
      let tables = [table_add_mod_5] in
      Circuit.make ~tables ~wires ~gates ~public_input_size:0 ()
    in
    {name; circuit; witness; outcome = Valid}

  (* ---- Test with 2 tables. ---- *)
  let qplookup_two_tables =
    let name = "qplookup_two_tables" in
    let witness = !![0; 1; 3; 9] in
    let circuit =
      let wires =
        let a = [2; 3] in
        let b = [2; 1] in
        let c = [1; 0] in
        [|a; b; c|]
      in
      let gates = Circuit.make_gates ~q_plookup:![1; 1] ~q_table:![0; 1] () in
      let tables = [table_add_mod_5; table_add_mod_10] in
      Circuit.make ~tables ~wires ~gates ~public_input_size:0 ()
    in
    {name; circuit; witness; outcome = Valid}

  (* ---- General test with correct and incorrect witness. ---- *)

  let wires =
    let a = [1; 1; 4; 2; 4; 3; 1] in
    let b = [2; 1; 2; 2; 3; 4; 4] in
    let c = [3; 1; 1; 4; 2; 2; 2] in
    [|a; b; c|]

  let gates =
    Circuit.make_gates
      ~linear:[(2, ![0; -1; 0; -1; 0; 0; 0])]
      ~qm:![0; 1; 0; 1; 0; 0; 0]
      ~qecc_ws_add:![0; 0; 0; 0; 0; 1; 0]
      ~q_plookup:![1; 0; 1; 0; 1; 0; 0]
      ~q_table:![0; 0; 0; 0; 0; 0; 0]
      ()

  let tables = [table_add_mod_5]

  let circuit =
    (* Proving the relations with addition mod 5 using lookups
          x8 = x7 + x1 * (x3 + x4 * (x5 + x6))
          R(x2, x2) = P(x3, x1) + Q(x4, x4) <- these are dummy points
          with 1 public input
       <=>
       Constraints:
          lookup: x1 (+) x7 = x8
          1*x1*x7 - 1*x7 = 0
          lookup: x3 (+) x4 = x7
          1*x4*x1 - x4 = 0
          lookup: x5 (+) x6 = x1
          F_add_weirestrass(x3, x4, x2, x1, x4, x2) = 0
    *)
    Circuit.make ~tables ~wires ~gates ~public_input_size:1 ()

  (* Base witness proves that:
      3 = 2 + 1 * (2 + 2 * (3 + 4))   addition modulo 5
      R(2,2) = P(3,1) + Q(4,4) weierstrass point addition
  *)
  let witness = !![0; 1; 2; 3; 4]

  let lookup_zero_values =
    let name = "lookup_zero_values" in
    let witness = !!(List.init 5 (fun _i -> 0)) in
    {name; circuit; witness; outcome = Valid}

  let lookup_non_zero_values =
    let name = "lookup_non_zero_values" in
    {name; circuit; witness; outcome = Valid}

  let lookup_no_public_inputs =
    let name = "lookup_no_public_inputs" in
    let circuit = Circuit.make ~tables ~wires ~gates ~public_input_size:0 () in
    {name; circuit; witness; outcome = Valid}

  let lookup_wrong_arith_values =
    let name = "lookup_wrong_arith_values" in
    let wires =
      let a = [1; 1; 4; 2; 4; 3; 1] in
      let b = [2; 1; 2; 2; 3; 4; 4] in
      let c = [3; 1; 1; 3; 2; 2; 2] in
      [|a; b; c|]
      (* """mistake""" here in arith. constraint *)
    in
    let circuit = Circuit.make ~tables ~wires ~gates ~public_input_size:1 () in
    {name; circuit; witness; outcome = Proof_error}

  let wrong_plookup_values =
    let name = "wrong_plookup_values" in
    let wires =
      let a = [0; 1; 4; 2; 4; 3; 1] in
      let b = [2; 1; 2; 2; 3; 4; 4] in
      let c = [3; 1; 1; 4; 2; 2; 2] in
      [|a; b; c|]
      (* """mistake""" here in lookup constraint *)
    in
    let circuit = Circuit.make ~tables ~wires ~gates ~public_input_size:1 () in
    {name; circuit; witness; outcome = Lookup_error}

  let list =
    [
      qplookup;
      qplookup_two_tables;
      lookup_zero_values;
      lookup_non_zero_values;
      lookup_no_public_inputs;
      lookup_wrong_arith_values;
      wrong_plookup_values;
    ]
end
