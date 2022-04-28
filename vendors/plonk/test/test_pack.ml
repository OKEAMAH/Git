module External = struct
  open Plonk.Pack
  module Fr_generation = Plonk.Fr_generation.Make (Scalar)

  let with_time f =
    let start_time = Sys.time () in
    let res = f () in
    let end_time = Sys.time () in
    (res, end_time -. start_time)

  let test_prove_and_verify_single () =
    Random.init 31415 ;
    let n = 256 in
    let (pp_prv, pp_vrf) = setup n in
    let data = List.init n (fun _i -> G1.random ()) in
    let (cmt, t1) = with_time @@ fun () -> commit pp_prv data in
    let (r, _) = Fr_generation.generate_single_fr (bytes_of_commitment cmt) in
    let ((packed, proof), t2) =
      with_time @@ fun () -> prove_single pp_prv cmt r data
    in
    let (b, t3) =
      with_time @@ fun () -> verify_single pp_vrf cmt r (packed, proof)
    in
    assert b ;
    Format.printf "\nTime commit (single): %f s\n" t1 ;
    Format.printf "Time aggregate and prove (single): %f s\n" t2 ;
    Format.printf "Time verify (single): %f s\n" t3

  let test_prove_and_verify () =
    Random.init 31415 ;
    let max_n = 256 in
    let nb_instances = 10 in
    let (pp_prv, pp_vrf) = setup max_n in
    let generate_instance () =
      let data = List.init (1 + Random.int max_n) (fun _i -> G1.random ()) in
      let cmt = commit pp_prv data in
      (data, cmt)
    in
    let instances = List.init nb_instances (fun _ -> generate_instance ()) in
    let (datas, cmts) = List.split instances in
    let keys = List.init nb_instances string_of_int in

    let data_map = Plonk.SMap.of_list (List.combine keys datas) in
    let cmts_map = Plonk.SMap.of_list (List.combine keys cmts) in

    let r = Scalar.random () in
    let ((packed_map, proof), t1) =
      with_time @@ fun () -> prove pp_prv cmts_map r data_map
    in
    let (b, t2) =
      with_time @@ fun () -> verify pp_vrf cmts_map r (packed_map, proof)
    in
    Format.printf "Time aggregate and prove: %f s\n" t1 ;
    Format.printf "Time verify: %f s\n" t2 ;
    assert b
end

let tests =
  [
    Alcotest.test_case
      "correctness (single)"
      `Quick
      External.test_prove_and_verify_single;
    Alcotest.test_case "correctness" `Quick External.test_prove_and_verify;
  ]
