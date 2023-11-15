let test_update_one () =
  let open Kzg.Merkle in
  let fd = "test_mt" in
  let leaves = generate_leaves () in
  (* let leaves =
       Kzg.Bls.Scalar.[|of_string "1" |> to_bytes; of_string "2" |> to_bytes ; of_string "3" |> to_bytes; of_string "4" |> to_bytes|]
     in *)
  (* Array.iteri
     (fun k i -> Printf.printf "\nl[%d] : %s" k Hex.(show (of_bytes i)))
     leaves ; *)
  commit_storage fd leaves ;
  Printf.printf "\ninitial storage\n" ;
  print_storage fd ;
  (* let root_before = read_root fd in *)
  let index, value =
    (Random.int Parameters.nb_cells, Kzg.Bls.Scalar.(random () |> to_bytes))
    (* (0, Kzg.Bls.Scalar.(of_string "5" |> to_bytes)) *)
  in
  update_one fd index value ;
  Printf.printf "\nafter update_one\n" ;
  print_storage fd ;
  let root_after_update_one = read_root fd in
  leaves.(index) <- value ;
  (* Array.iteri
     (fun k i -> Printf.printf "\nl[%d] : %s" k Hex.(show (of_bytes i)))
     leaves ; *)
  commit_storage fd leaves ;
  Printf.printf "\nafter commit\n" ;
  print_storage fd ;
  let root_after_commit_storage = read_root fd in
  (* Printf.printf "\nroot_before : %s" Hex.(show (of_bytes root_before)) ;
     Printf.printf "\nroot_afteru : %s" Hex.(show (of_bytes root_after_update_one)) ; *)
  (* Printf.printf
     "\nroot_afterc : %s\n"
     Hex.(show (of_bytes root_after_commit_storage)) ; *)
  assert (Bytes.equal root_after_update_one root_after_commit_storage)

let tests =
  List.map
    (fun (name, f) -> Alcotest.test_case name `Quick f)
    [("Merkle update one", test_update_one)]
