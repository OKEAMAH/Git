let () =
  let discriminant_size = 128 in
  let seed = Bytes.of_string "secret" in
  let discriminant = Vdf.generate_discriminant ~seed discriminant_size in
  let challenge = Bytes.make Vdf.form_size_bytes (char_of_int 0) in
  Bytes.set_uint8 challenge 0 8 ;
  let difficulty = Unsigned.UInt64.of_int 1000000 in
  let start_proof = Sys.time () in
  let res, proof = Vdf.prove_vdf discriminant challenge difficulty in
  let end_proof = Sys.time () in
  let b = Vdf.verify_vdf discriminant challenge difficulty res proof in
  let end_verify = Sys.time () in
  let its =
    (Float.of_string @@ Unsigned.UInt64.to_string difficulty)
    /. (end_proof -. start_proof)
    |> Int.of_float |> Int.to_string
  in
  Printf.printf
    "\nVDF test with discriminant size = %d and difficulty = %s"
    (discriminant_size * 8)
    (Unsigned.UInt64.to_string difficulty) ;
  Printf.printf "\n   - proving time: %fs" (end_proof -. start_proof) ;
  Printf.printf "\n   - verification time: %fs" (end_verify -. end_proof) ;
  Printf.printf "\n   - IPS: %s" its ;
  Printf.printf "\n" ;
  (* Creates another proof starting at the previous output *)
  let difficulty2 = Unsigned.UInt64.of_int 2000000 in
  let start_proof = Sys.time () in
  let res2, proof2 = Vdf.prove_vdf discriminant challenge difficulty2 in
  let end_proof = Sys.time () in
  let b2 = Vdf.verify_vdf discriminant challenge difficulty2 res2 proof2 in
  let end_verify = Sys.time () in
  let its2 =
    (Float.of_string @@ Unsigned.UInt64.to_string difficulty2)
    /. (end_proof -. start_proof)
    |> Int.of_float |> Int.to_string
  in
  Printf.printf
    "\nVDF test with discriminant size = %d and difficulty = %s"
    (discriminant_size * 8)
    (Unsigned.UInt64.to_string difficulty2) ;
  Printf.printf "\n   - proving time: %fs" (end_proof -. start_proof) ;
  Printf.printf "\n   - verification time: %fs" (end_verify -. end_proof) ;
  Printf.printf "\n   - IPS: %s" its2 ;
  Printf.printf "\n" ;
  assert (b && b2)
