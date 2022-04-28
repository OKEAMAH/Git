open Plonk

let create_random_permutation n =
  (* This function does not sample permutations uniformly at random,
       it seems to be biased towards permutations similar to the identity *)
  let l = List.init n (fun i -> (i, Random.int n)) in
  let compare (_, k1) (_, k2) = compare k1 k2 in
  let permutation_list = List.map (fun (i, _) -> i) (List.sort compare l) in
  Array.of_list permutation_list

let expand_permutation ~n permutation =
  let m = Array.length permutation in
  List.init m (fun i -> Array.init n (fun j -> (permutation.(i) * n) + j))
  |> Array.concat

let arbitrary_perm =
  let print_perm perm =
    String.concat " " (List.map string_of_int (Array.to_list perm))
  in

  let perm_gen =
    QCheck.Gen.(
      sized @@ fun d _st ->
      let d = if d > 10 then 10 else if d < 2 then 2 else d in
      let n = Z.(pow (of_int 2) d |> to_int) in
      let perm = create_random_permutation n in
      perm)
  in
  QCheck.make perm_gen ~print:print_perm

module Internal = struct
  open Permutation_gate.Permutation_gate_impl (Polynomial_protocol)

  let generate_random_polynomial n =
    Poly.of_coefficients (List.init n (fun i -> (Scalar.random (), i)))

  let build_gi_list generator n =
    let rec aux acc i =
      if i = n then List.rev acc
      else
        let g_i_min_1 = List.hd acc in
        aux (Scalar.mul g_i_min_1 generator :: acc) (i + 1)
    in
    aux [generator] 2

  let test_fr_of_int_safe () =
    let fr_of_int_safe_slow n =
      let rec aux acc i =
        if i = 0 then acc else aux (Scalar.add acc Scalar.one) (i - 1)
      in
      aux Scalar.zero n
    in
    let n = Random.int 1000000 in
    let n1 = Fr_generation.fr_of_int_safe n in
    let n2 = fr_of_int_safe_slow n in
    assert (Scalar.eq n1 n2)
end

module External = struct
  module PP = Polynomial_protocol
  module Perm = Permutation_gate.Permutation_gate (PP)
  module Scalar = PP.PC.Scalar
  module Fr_generation = PP.PC.Fr_generation
  module Domain = PP.PC.Polynomial.Domain
  module Poly = PP.PC.Polynomial.Polynomial

  let nb_wires = 3

  let test_prop_perm_check (perm : int array) =
    let n = Array.length perm in
    let permutation = expand_permutation ~n:nb_wires perm in
    let log = Z.(log2up (of_int n)) in
    let domain = Domain.build ~log in
    let domain_evals = Domain.build ~log:(log + 2) in
    let g_map_perm =
      let (g_map_perm, _, _) =
        Perm.common_preprocessing
          ~compute_l1:true
          ~domain
          ~nb_wires
          ~domain_evals
      in
      SMap.union_disjoint
        g_map_perm
        (Perm.preprocessing ~domain ~nb_wires ~permutation ())
    in

    let l1 = SMap.find "L1" g_map_perm in

    (* Check that L1(g^1) = 1 and L(g^i) = 0 for all i <> 1 *)
    let _lconsistency (i, g) =
      let v = Poly.evaluate l1 g in
      if i = 1 then Scalar.is_one v else Scalar.is_zero v
    in
    (*     Array.for_all *)
    (*       lconsistency *)
    (*       (Array.mapi (fun i g -> (i, g)) (Domain.to_array domain)) *)
    (*     && *)
    Perm.srs_size ~zero_knowledge:true ~n = n + 9
    && Perm.srs_size ~zero_knowledge:false ~n = n
end

let tests =
  [
    Alcotest.test_case "test_fr_of_int_safe" `Quick Internal.test_fr_of_int_safe;
    QCheck_alcotest.to_alcotest
      (QCheck.Test.make
         ~count:30
         ~name:"permutation_properties"
         arbitrary_perm
         External.test_prop_perm_check);
  ]
