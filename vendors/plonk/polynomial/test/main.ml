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
    | Some v -> (
        try int_of_string v
        with _ ->
          failwith
            (Format.sprintf
               "Invalid random seed '%s'. Maybe you need to run '$ unset \
                RANDOM_SEED' in your terminal?"
               v))
  in
  Printf.printf "Random seed: %d\n" seed ;
  Random.init seed ;
  Alcotest.run
    ~verbose:false
    "PlonK"
    (Test_multivariate_polynomials.T_Q.tests
    @ [
        ("Coefficients", Test_coefficients.tests);
        ("Polynomial_c", Test_polynomial_c.tests);
      ])
