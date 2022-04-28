let test_fold_leftn () =
  let length = 1_000 in
  let width = 1_000 in
  let l = List.init length (fun _ -> 1) in
  let ls = List.init width (fun _ -> l) in
  assert (Plonk.List.fold_leftn (fun acc is -> acc + List.hd is) 0 ls = length) ;
  Plonk.List.fold_leftn
    (fun () is ->
      assert (List.fold_left ( + ) 0 is = width) ;
      ())
    ()
    ls

let test_fold_leftn_negative () =
  let l1 = List.init 1 (fun _ -> 1) in
  let l2 = List.init 2 (fun _ -> 1) in
  let ls = [l1; l2] in
  try
    let _ = Plonk.List.fold_leftn (fun acc is -> acc + List.hd is) 0 ls in
    assert false
  with _ -> ()

let tests =
  [
    Alcotest.test_case "fold_leftn" `Quick test_fold_leftn;
    Alcotest.test_case "fold_leftn_negative" `Quick test_fold_leftn_negative;
  ]
