let assert_num_steps action expected =
  let open Lwt.Syntax in
  let* _res, num_steps = Action.Internal_for_tests.run action in
  let () = Alcotest.(check int "Count" expected num_steps) in
  let* _res = Action.run ~max_num_steps:expected action in
  let* () =
    Lwt.catch
      (fun () ->
        let* _ = Action.run ~max_num_steps:(expected - 1) action in
        failwith "Expected to fail but succeeded.")
      (function
        | Action.Exceeded_max_num_steps -> Lwt.return ()
        | _ -> failwith "Expected exceeded-max-num-steps error")
  in
  Lwt.return ()

let test_num_steps _ () =
  let open Lwt.Syntax in
  let* () = assert_num_steps (Action.return ()) 0 in
  let* () =
    assert_num_steps
      (let open Action.Syntax in
      let+ () = Action.return () in
      ())
      1
  in
  let* () =
    assert_num_steps
      (let open Action.Syntax in
      let* _ = Action.return 1 in
      Action.return ())
      1
  in
  (* Two binds and a map for the following action. *)
  let* () =
    assert_num_steps
      (let open Action.Syntax in
      let+ x = Action.return 1 and+ y = Action.return 2 in
      return (x, y))
      3
  in
  (* One step per bind. *)
  let* () =
    assert_num_steps
      (let open Action.Syntax in
      let* _ = Action.return 1 in
      let* _ = Action.return 2 in
      let* _ = Action.return 3 in
      let* _ = Action.return 4 in
      let* _ = Action.return 5 in
      Action.return ())
      5
  in
  (* Each additional [and*] implies another map. The number of steps is:
     [num-binds x 2 - 1] *)
  let* () =
    assert_num_steps
      (let open Action.Syntax in
      let* _ = Action.return 1
      and* _ = Action.return 2
      and* _ = Action.return 3
      and* _ = Action.return 4
      and* _ = Action.return 5 in
      Action.return ())
      9
  in
  (* One step per iteration of the list. *)
  let* () =
    assert_num_steps
      (Action.List.iter_s (fun _ -> Action.return_unit) [1; 2; 3; 4; 5])
      5
  in
  (* One extra step for reversing the list. *)
  let* () =
    assert_num_steps
      (Action.List.mapi_s (fun _ _ -> Action.return_unit) [1; 2; 3; 4; 5])
      6
  in
  (* One step per fold operation. *)
  let* () =
    assert_num_steps
      (Action.List.fold_left_s
         (fun _ _ -> Action.return_unit)
         ()
         [1; 2; 3; 4; 5])
      5
  in
  Lwt.return ()

let tests = [Alcotest_lwt.test_case "Number of steps" `Quick test_num_steps]
