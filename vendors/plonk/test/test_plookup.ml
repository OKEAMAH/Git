module Scalar = Bls12_381.Fr
module Fr_gen = Plonk.Fr_generation.Make (Scalar)

let srs_file = Helpers.srs_path "srs_16"

module External (PC : Plonk.Kzg.Polynomial_commitment_sig) = struct
  module Plook = Plonk.Plookup_protocol.Make (PC)

  let fr_of_int x = Scalar.of_z (Z.of_int x)

  let simple_test () =
    let n = 28 in
    let nb_lookups = 31 in
    let t_1 = Array.init n (fun _ -> Scalar.random ()) in
    let t_2 = Array.init n (fun _ -> Scalar.random ()) in
    let ts = [[t_1; t_2]] in
    let k_array = Array.init nb_lookups (fun _ -> Random.int n) in
    let f_1 = List.init nb_lookups (fun i -> t_1.(k_array.(i))) in
    let f_2 = List.init nb_lookups (fun i -> t_2.(k_array.(i))) in
    let fs = [f_1; f_2] in
    let nb_wires = List.length fs in
    let (pp_prove, pp_verify) =
      Plook.setup nb_wires nb_lookups ts srs_file ()
    in
    let (pi, _) = Plook.prove pp_prove fs Bytes.empty in
    let res = Plook.verify pp_verify pi Bytes.empty in
    assert res

  let test_16_range () =
    let n = 16 in
    let nb_lookups = n - 1 in
    let table = Array.init n (fun i -> fr_of_int i) in
    let ts = [[table]] in
    let f = List.init nb_lookups (fun _ -> fr_of_int (Random.int n)) in
    let fs = [f] in
    let nb_wires = List.length fs in
    let (pp_prove, pp_verify) =
      Plook.setup nb_wires nb_lookups ts srs_file ()
    in
    let transcript = Bytes.empty in
    let (pi, _) = Plook.prove pp_prove fs transcript in
    let res = Plook.verify pp_verify pi transcript in
    assert res ;
    try
      let f_false = List.init (2 * n) (fun i -> fr_of_int i) in
      let (pi, _) = Plook.prove pp_prove [f_false] transcript in
      let res = Plook.verify pp_verify pi transcript in
      assert (not res)
    with _ ->
      assert true ;
      ()

  let test_16_lookup () =
    let n = 16 in
    let n2 = n * n in
    let nb_lookups = n2 - 1 in
    let t_1 = Array.init n2 (fun i -> fr_of_int (i / n)) in
    let t_2 = Array.init n2 (fun i -> fr_of_int (i mod n)) in
    let t_3 = Array.init n2 (fun i -> fr_of_int (((i / n) + i) mod n)) in
    let ts = [[t_1; t_2; t_3]] in
    (* Auto example *)
    let k_array = Array.init nb_lookups (fun _ -> Random.int n2) in
    let f_1 = List.init (nb_lookups - 1) (fun i -> t_1.(k_array.(i))) in
    let f_2 = List.init (nb_lookups - 1) (fun i -> t_2.(k_array.(i))) in
    let f_3 = List.init (nb_lookups - 1) (fun i -> t_3.(k_array.(i))) in
    (* Manual example *)
    let fs = [Scalar.zero :: f_1; Scalar.one :: f_2; Scalar.one :: f_3] in
    let nb_wires = List.length fs in
    (* Generate and verify proof *)
    let (pp_prove, pp_verify) =
      Plook.setup nb_wires nb_lookups ts srs_file ()
    in
    let transcript = Bytes.empty in
    let (pi, _) = Plook.prove pp_prove fs transcript in
    let res = Plook.verify pp_verify pi transcript in
    assert res ;
    ()

  let two_table_test () =
    (* We check here that the sum of random values included in [0;9] are correct. *)
    let m = 10 in
    let m2 = m * m in
    let tables =
      let table_10 =
        let t_1 = Array.init m (fun i -> fr_of_int i) in
        [t_1]
      in
      let table_add_mod_10 =
        let t_1 = Array.init m2 (fun i -> fr_of_int (i / m)) in
        let t_2 = Array.init m2 (fun i -> fr_of_int (i mod m)) in
        let t_3 = Array.init m2 (fun i -> fr_of_int (((i / m) + i) mod m)) in
        [t_1; t_2; t_3]
      in
      [table_10; table_add_mod_10]
    in
    let n = 50 in
    let nb_lookups = 3 * n in
    let a = List.init n (fun _ -> Random.int m) in
    let b = List.init n (fun _ -> Random.int m) in
    let c = List.map2 (fun a b -> (a + b) mod m) a b in
    let f_1 = List.map (fun x -> fr_of_int x) List.(append a (append b a)) in
    let zero_list = List.init (2 * n) (fun _ -> 0) in
    let f_2 = List.map (fun x -> fr_of_int x) List.(append zero_list b) in
    let f_3 = List.map (fun x -> fr_of_int x) List.(append zero_list c) in
    let fs = [f_1; f_2; f_3] in
    let nb_wires = List.length fs in
    let zero_array = Array.init (2 * n) (fun _ -> Scalar.zero) in
    let one_array = Array.init n (fun _ -> Scalar.one) in
    let q_table = Array.to_list (Array.append zero_array one_array) in
    let (pp_prove, pp_verify) =
      Plook.setup nb_wires nb_lookups tables ~q_table srs_file ()
    in
    let (pi, _) = Plook.prove pp_prove fs Bytes.empty in
    let res = Plook.verify pp_verify pi Bytes.empty in
    assert res ;
    ()

  let tests pc_name =
    [
      (Printf.sprintf "%s.simple_test" pc_name, simple_test);
      (Printf.sprintf "%s.test_16_range" pc_name, test_16_range);
      (Printf.sprintf "%s.test_16_lookup" pc_name, test_16_lookup);
      (Printf.sprintf "%s.two_table_test" pc_name, two_table_test);
    ]
end

module Internal = struct
  open Plonk.Plookup_gate.Plookup_gate_impl (Plonk.Polynomial_protocol)

  module Domain = PP.PC.Polynomial.Domain
  module Poly = PP.PC.Polynomial.Polynomial
  module Evaluations = Plonk.Evaluations_map.Make (PP.PC.Polynomial.Evaluations)
  module Scalar = PP.PC.Scalar
  module Fr_gen = Polynomial__Fr_generation.Make (PP.PC.Scalar)

  let test_aggregation () =
    let alpha = Scalar.random () in
    let length_list = 5 in
    let length_t = 30 in
    let length_f = 25 in
    let tables =
      List.init length_list (fun _ ->
          Array.init length_t (fun _ -> Scalar.random ()))
    in
    let k_array = Array.init length_f (fun _ -> Random.int length_t) in
    let f_list =
      List.init length_list (fun i ->
          Array.init length_f (fun j ->
              let t_i = List.nth tables i in
              t_i.(k_array.(j))))
    in
    let f_list_sorted =
      List.map2 (fun f t -> Plookup_poly.sort_by f t) f_list tables
    in
    let t = Plookup_poly.compute_aggregation tables alpha in
    let f = Plookup_poly.compute_aggregation f_list_sorted alpha in
    for i = 0 to length_f - 1 do
      assert (Array.exists (fun x -> Scalar.eq x f.(i)) t)
    done ;
    ()

  let test_z () =
    let n = 32 in
    let log = 5 in
    let generator = Fr_gen.root_of_unity log in
    let domain = Domain.build ~log in
    let t = Array.init n (fun _ -> Scalar.random ()) in
    let f =
      Array.init (n - 1) (fun i ->
          let k = if i = 0 || i = 1 || i = n - 1 then 5 else i in
          t.(k))
    in
    let beta = Scalar.random () in
    let gamma = Scalar.random () in
    let one_plus_beta = Scalar.(one + beta) in
    let gamma_one_plus_beta = Scalar.(gamma * one_plus_beta) in
    let s = Plookup_poly.compute_s f t in
    let z = Plookup_poly.compute_z beta gamma f t s n domain in
    let t_poly =
      Evaluations.interpolation_fft2 domain (Plookup_poly.switch t)
    in
    let f_poly =
      Evaluations.interpolation_fft2 domain Array.(append [|zero|] f)
    in
    let (h1, h2) = Plookup_poly.compute_h s domain n in
    let eval_left x =
      let x_minus_one = Scalar.(x + negate one) in
      let f_term = Scalar.(Poly.evaluate f_poly x + gamma) in
      let t_term =
        Scalar.(
          gamma_one_plus_beta + Poly.evaluate t_poly x
          + (beta * Poly.evaluate t_poly (generator * x)))
      in
      Scalar.(x_minus_one * Poly.evaluate z x * one_plus_beta * f_term * t_term)
    in
    let eval_right x =
      let x_minus_one = Scalar.(x + negate one) in
      let h_term h =
        Scalar.(
          gamma_one_plus_beta + Poly.evaluate h x
          + (beta * Poly.evaluate h (generator * x)))
      in
      Scalar.(
        x_minus_one * Poly.evaluate z (generator * x) * h_term h1 * h_term h2)
    in
    for i = 0 to 31 do
      let eval_point = Scalar.pow generator (Z.of_int i) in
      assert (Scalar.eq (eval_left eval_point) (eval_right eval_point))
    done ;
    ()

  let test_sort () =
    let a = Array.init 10 (fun i -> Scalar.of_z (Z.of_int i)) in
    let b = Array.init 12 (fun i -> Scalar.of_z (Z.of_int (11 - i))) in
    let sorted_a = Plookup_poly.sort_by a b in
    Array.iteri
      (fun i a_i -> assert (Scalar.eq a_i (Scalar.of_z (Z.of_int (9 - i)))))
      sorted_a ;
    ()
end

let tests_internal =
  [
    ("Internal.test_z", Internal.test_z);
    ("Internal.test_sort", Internal.test_sort);
    ("Internal.test_aggregation", Internal.test_aggregation);
  ]

let tests_kzg =
  let open External (Plonk.Kzg) in
  tests "KZG"

let tests_kzg_pack =
  let open External (Plonk.Kzg_pack) in
  tests "KZG_Pack"

let tests =
  List.map
    (fun (name, f) ->
      Alcotest.test_case name `Quick (fun () -> Plonk.Multicore.with_pool f))
    (tests_internal @ tests_kzg @ tests_kzg_pack)
