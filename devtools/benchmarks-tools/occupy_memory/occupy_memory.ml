let amount = int_of_string @@ Sys.argv.(1)

let () =
  let bytes = Bytes.init amount (fun _ -> '\000') in
  Format.eprintf "Allocated %d bytes@." amount ;
  print_endline "allocated" ;
  flush stdout ;
  let _ = input_line stdin in
  Format.eprintf "Deallocated %d bytes@." (Bytes.length bytes) ;
  Gc.compact () ;
  print_endline "deallocating"
