open Plonk.List
open Plonk.Utils

let rng6 = [1; 2; 3; 4; 5; 6]

let list_tests () =
  let (left, right) = split_n 2 rng6 in
  assert (equal_lists ~equal:( = ) [1; 2] left) ;
  assert (equal_lists ~equal:( = ) [3; 4; 5; 6] right) ;

  let (left, right) = split_in_half rng6 in
  assert (equal_lists ~equal:( = ) [1; 2; 3] left) ;
  assert (equal_lists ~equal:( = ) [4; 5; 6] right) ;

  assert (
    21 * 21 = fold_left3 (fun acc a b c -> acc + (a * b * c)) 0 rng6 rng6 rng6)

let utils_tests () = assert (91 = inner_product ~add:( + ) ~mul:( * ) rng6 rng6)

module Multicore = struct
  let pippenger_bls_copy ~start ~len aa bb =
    let aa = Array.sub aa start len in
    let bb = Array.sub bb start len in
    Bls12_381.G1.pippenger aa bb

  let pippenger_bls ~start ~len aa bb = Bls12_381.G1.pippenger ~start ~len aa bb

  let test () =
    Plonk.Multicore.with_pool (fun () ->
        let l = 4_000_001 in
        let open Bls12_381 in
        let a1 = Array.make l G1.one in
        let a2 = Array.make l G1.Scalar.one in
        let res =
          Helpers.time "one big pippengeer" (fun () ->
              pippenger_bls ~start:0 ~len:l a1 a2)
        in
        assert (G1.(eq res (mul one (Scalar.of_z @@ Z.of_int l)))) ;
        let res =
          let res =
            Helpers.time "one_chunk_per_core with copy" (fun () ->
                Plonk.Multicore.map2_one_chunk_per_core pippenger_bls_copy a1 a2)
          in
          List.fold_left G1.add G1.zero res
        in
        assert (G1.(eq res (mul one (Scalar.of_z @@ Z.of_int l)))) ;
        let res =
          let res =
            Helpers.time "one_chunk_per_core no copying" (fun () ->
                Plonk.Multicore.map2_one_chunk_per_core pippenger_bls a1 a2)
          in
          List.fold_left G1.add G1.zero res
        in
        assert (G1.(eq res (mul one (Scalar.of_z @@ Z.of_int l)))))
end

let tests =
  Alcotest.
    [
      test_case "List.ml" `Quick list_tests;
      test_case "Utils.ml" `Quick utils_tests;
      test_case "pippenger" `Quick Multicore.test;
    ]
