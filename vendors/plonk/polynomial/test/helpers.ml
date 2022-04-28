let rec repeat n f =
  if n < 0 then ()
  else (
    f () ;
    repeat (n - 1) f)

let must_fail f =
  let exception Local in
  try
    (try f () with _ -> raise Local) ;
    assert false
  with
  | Local -> ()
  | _ -> assert false
