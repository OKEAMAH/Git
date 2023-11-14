let test_update_one () =
  let open Kzg.Merkle in
  let fd = "test_mt" in
  let leaves = generate_leaves () in
  commit_storage fd leaves ;
  let index, value =
    (Random.int Parameters.nb_cells, Kzg.Bls.Scalar.(random () |> to_bytes))
  in
  update_one fd index value ;
  let root_after_update_one = read_root fd in
  leaves.(index) <- value ;
  commit_storage fd leaves ;
  let root_after_commit_storage = read_root fd in
  assert (Bytes.equal root_after_update_one root_after_commit_storage)

let tests =
  List.map
    (fun (name, f) -> Alcotest.test_case name `Quick f)
    [("Merkle update one", test_update_one)]
