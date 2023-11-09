let test_verkle () =
  let expected_snd_lvl =
    Array.init Kzg.Verkle.array_size (fun _ ->
        Array.init Kzg.Verkle.array_size (fun i -> Bls12_381.Fr.of_int i))
  in
  let () = Kzg.Verkle.create_storage ~test:true "vfd" in
  let _, _, snd_level = Kzg.Verkle.read_storage "vfd" in
  Array.iteri
    (fun fst v ->
      Array.iteri
        (fun snd expected ->
          assert (Bls12_381.Fr.eq expected snd_level.(fst).(snd)))
        v)
    expected_snd_lvl

let test_update () =
  let open Kzg.Verkle in
  let () = create_storage "test" in
  let diff = create_diff 10 in
  let () = update_storage "test" diff in
  ()

let tests =
  List.map
    (fun (name, f) -> Alcotest.test_case name `Quick f)
    [("Verkle", test_verkle); ("Update", test_update)]
