let tests =
  [
    ("Smallint", Smallint.tests);
    ("Lazy_vector", Lazy_vector_tests.tests);
    ("Chunked_byte_vector", Chunked_byte_vector_tests.tests);
    ("Lazy_stack", Lazy_stack_tests.tests);
  ]

let () =
  Printexc.record_backtrace true ;
  Alcotest.run "WebAssembly reference interpreter tests" tests
