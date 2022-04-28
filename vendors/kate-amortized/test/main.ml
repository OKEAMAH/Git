let () =
  (* Seed for deterministic pseudo-randomness:
      If the environment variable RANDOM_SEED is set, then its value is used as
      as seed. Otherwise, a random seed is used.
     WARNING: using [Random.self_init] elsewhere in the tests breaks thedeterminism.
  *)
  let seed =
    match Sys.getenv_opt "RANDOM_SEED" with
    | None ->
        Random.self_init () ;
        Random.int 1073741823
    | Some v -> int_of_string v
  in
  Printf.printf "Random seed: %d\n" seed ;
  Random.init seed ;
  Alcotest.run
    "Kate Amortized"
    [
      ("Kate Amortized", Test_kate_amortized.tests);
      ("Bench", Test_kate_amortized.bench);
      ("Reed Solomon", Test_reed_solomon.tests);
      ("BenchRS", Test_reed_solomon.bench);
    ]
