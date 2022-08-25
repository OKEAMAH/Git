let tests = [("Smallint", Test_smallint.tests); ("Action", Test_action.tests)]

let () =
  Lwt_main.run
    (Alcotest_lwt.run "WebAssembly reference interpreter tests" tests)
