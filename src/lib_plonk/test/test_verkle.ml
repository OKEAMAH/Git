let test_correctness () =
  let open Kzg.Verkle in
  let fd = "test_vc" in
  let snd_lvl = generate_snd_lvl () in
  let () = commit_storage fd snd_lvl in

  let diff = create_diff 10 in
  let () = update_commit fd diff in
  let root = read_root fd in

  update_storage diff snd_lvl ;
  let root_new, _ = commit snd_lvl in
  assert (Bls12_381.G1.eq root root_new)

let tests =
  List.map
    (fun (name, f) -> Alcotest.test_case name `Quick f)
    [("Verkle_correctness", test_correctness)]
