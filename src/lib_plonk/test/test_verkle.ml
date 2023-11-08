let test_verkle () =
  let expected_snd_lvl = Kzg.Verkle.create_storage "vfd" in
  let snd_level = Kzg.Verkle.read_storage "vfd" in
  assert (snd_level = expected_snd_lvl) ;
  ()

let tests =
  List.map
    (fun (name, f) -> Alcotest.test_case name `Quick f)
    [("Verkle", test_verkle)]
