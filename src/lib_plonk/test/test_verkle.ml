let test_verkle () =
  let () = Kzg.Verkle.create_storage "vfd" in
  Kzg.Verkle.read_storage "vfd"

let tests =
  List.map
    (fun (name, f) -> Alcotest.test_case name `Quick f)
    [("Verkle", test_verkle)]
