module SMap = Plonk.SMap

module Make = struct
  module Main = Plonk.Main_protocol
  module Helpers_main = Helpers.Make (Main)

  let test_make_one_sel sel () =
    let open Plonk.Circuit in
    let wires = SMap.of_list [("a", [1]); ("b", [1]); ("c", [1])] in
    let gates = SMap.add sel [Scalar.one] SMap.empty in
    let (gates, tables) =
      match sel with
      | "q_plookup" -> (SMap.add "q_table" [Scalar.one] gates, [[[||]]])
      | "q_table" -> (SMap.add "q_plookup" [Scalar.one] gates, [[[||]]])
      | _ -> (gates, [])
    in
    let c = make ~tables ~wires ~gates ~public_input_size:0 () in
    assert (c.wires = wires) ;
    assert (gates_equal c.gates gates)

  let tests_one_sel =
    List.map
      (fun (s, _) ->
        Alcotest.test_case ("make " ^ s) `Quick (test_make_one_sel s))
      Plonk.Circuit.all_selectors

  let test_empty () =
    let open Plonk.Circuit in
    let wires = SMap.of_list [("a", [1]); ("b", [1]); ("c", [1])] in
    let gates = SMap.add "qc" [Scalar.one] SMap.empty in
    Helpers.must_fail (fun () ->
        ignore @@ make ~wires:SMap.empty ~gates ~public_input_size:0 ()) ;
    Helpers.must_fail (fun () ->
        ignore @@ make ~wires ~gates:SMap.empty ~public_input_size:0 ())

  let test_different_size () =
    let open Plonk.Circuit in
    (* wires have different size wrt to gates *)
    let wires = SMap.of_list [("a", [1]); ("b", [1]); ("c", [1])] in
    let gates = SMap.add "qc" Scalar.[one; one] SMap.empty in
    Helpers.must_fail (fun () ->
        ignore @@ make ~wires ~gates ~public_input_size:0 ()) ;
    (* wires have different sizes *)
    let wires = SMap.of_list [("a", [1; 1]); ("b", [1]); ("c", [1])] in
    let gates = SMap.add "qc" Scalar.[one] SMap.empty in
    Helpers.must_fail (fun () ->
        ignore @@ make ~wires ~gates ~public_input_size:0 ()) ;
    (* gates have different sizes *)
    let wires = SMap.of_list [("a", [1]); ("b", [1]); ("c", [1])] in
    let gates = SMap.of_list Scalar.[("qc", [one]); ("ql", [one; one])] in
    Helpers.must_fail (fun () ->
        ignore @@ make ~wires ~gates ~public_input_size:0 ())

  (* Test that Plonk supports using qecc_ws_add and a q*g in the same circuit. *)
  let test_disjoint () =
    let open Plonk.Circuit in
    let x = Scalar.[|one; add one one; of_string "3"; of_string "4"|] in
    let wires =
      SMap.of_list [("a", [0; 2; 0]); ("b", [0; 3; 3]); ("c", [0; 1; 1])]
    in
    let gates =
      SMap.of_list
        Scalar.
          [
            ("ql", [one; zero; zero]);
            ("qecc_ws_add", [zero; one; zero]);
            ("qlg", [one; zero; zero]);
            ("qc", [Scalar.(negate (of_string "4")); zero; zero]);
          ]
    in
    let c = make ~wires ~gates ~public_input_size:0 () in
    Helpers_main.test_circuit ~nb_proofs:1 c x (Helpers.srs_path "srs_16")

  let test_wrong_selectors () =
    let open Plonk.Circuit in
    let x = Scalar.[|one; add one one; of_string "3"; of_string "4"|] in
    let wires =
      SMap.of_list [("a", [0; 2; 0]); ("b", [0; 3; 3]); ("c", [0; 1; 1])]
    in
    let gates =
      SMap.of_list
        Scalar.
          [
            ("ql", [one; zero; zero]);
            ("dummy", [zero; one; zero]);
            ("qlg", [one; zero; zero]);
            ("qc", [Scalar.(negate (of_string "4")); zero; zero]);
          ]
    in
    try
      let c = make ~wires ~gates ~public_input_size:0 () in
      Helpers_main.test_circuit ~nb_proofs:1 c x (Helpers.srs_path "srs_16") ;
      assert (1 = 0)
    with _ -> assert true

  let test_vector () =
    let open Plonk.Circuit in
    let wires = SMap.of_list [("a", [1; 1]); ("b", [1; 1]); ("c", [1; 1])] in
    let gates =
      SMap.of_list Scalar.[("qc", [zero; one]); ("qr", [zero; zero])]
    in
    let gates_expected =
      SMap.of_list Scalar.[("qc", [zero; one]); ("qr", [zero; zero])]
    in
    let c = make ~wires ~gates ~public_input_size:1 () in
    assert (c.wires = wires) ;
    assert (gates_equal c.gates gates_expected)

  (* TODO add more tests about lookup *)

  let test_table () =
    let open Plonk.Circuit in
    let (zero, one) = Scalar.(zero, one) in
    let table_or =
      Table.of_list
        [
          [|zero; zero; one; one|];
          [|zero; one; zero; one|];
          [|zero; one; one; one|];
        ]
    in
    let entry = ({a = zero; b = zero; c = zero} : Table.entry) in
    let input = Table.{a = Some zero; b = Some zero; c = None} in
    assert (Table.size table_or = 4) ;
    assert (Table.mem entry table_or) ;
    Table.find input table_or |> Option.get |> fun res ->
    assert (Scalar.(eq entry.a res.a && eq entry.b res.b && eq entry.c res.c)) ;
    ()
end

module To_plonk = struct
  let test_vector () =
    let open Plonk.Circuit in
    let (zero, one, two) = Scalar.(zero, one, one + one) in
    let g1 = [|{a = 0; b = 1; c = 0; sels = [("qr", one)]; label = ""}|] in
    let g2 = [|{a = 1; b = 2; c = 1; sels = [("qm", two)]; label = ""}|] in
    let c = to_plonk ~public_input_size:1 [g1; g2] in
    let expected_wires =
      SMap.of_list [("a", [0; 1]); ("b", [1; 2]); ("c", [0; 1])]
    in
    let expected_gates =
      SMap.of_list [("qr", [one; zero]); ("qm", [zero; two])]
    in
    assert (c.wires = expected_wires) ;
    assert (gates_equal c.gates expected_gates)
end

let tests =
  Make.tests_one_sel
  @ [
      Alcotest.test_case "make empty" `Quick Make.test_empty;
      Alcotest.test_case "make different_size" `Quick Make.test_different_size;
      Alcotest.test_case "make vectors" `Quick Make.test_vector;
      Alcotest.test_case "make table" `Quick Make.test_table;
      Alcotest.test_case "make disjoint" `Quick Make.test_disjoint;
      Alcotest.test_case "to_plonk vectors" `Quick To_plonk.test_vector;
      Alcotest.test_case
        "to_plonk wrong selectors"
        `Quick
        Make.test_wrong_selectors;
    ]
