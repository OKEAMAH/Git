module Test = struct
  module Scalar = Bls12_381.Fr
  module Scalar_array = Bls12_381_polynomial.Fr_carray

  type scalar_array = Scalar_array.t

  let random_indices bound k =
    Random.self_init () ;

    let rand_elt l =
      let rec loop i = function
        | true -> i
        | false ->
            let n = Random.int bound in
            loop n (not @@ List.mem n l)
      in
      loop 0 false
    in

    let rec aux l n =
      match List.length l with
      | x when x = n -> l
      | _ -> aux (rand_elt l :: l) n
    in

    aux [] k

  let _print_array a =
    let a = Scalar_array.to_array a in
    Printf.eprintf "\n\n Array:\n" ;
    Array.iter (fun s -> Printf.eprintf " %s ;" (Scalar.to_string s)) a ;
    Printf.eprintf "\n"

  let make_domain root d =
    let build_array init next len =
      let xi = ref init in
      Array.init len (fun _ ->
          let i = !xi in
          xi := next !xi ;
          i)
    in
    build_array Scalar.(copy one) (fun g -> Scalar.(mul g root)) d
    |> Scalar_array.of_array

  external dft_c :
    scalar_array -> bool -> int -> scalar_array -> scalar_array -> unit
    = "dft_c"

  let _dft_c ~domain ~inverse ~length ~coefficients =
    dft_c domain inverse length coefficients (Scalar_array.allocate length)

  external prime_factor_algorithm_fft_ext :
    bool ->
    scalar_array ->
    scalar_array ->
    int ->
    int ->
    scalar_array ->
    scalar_array ->
    unit
    = "prime_factor_algorithm_fft_bytecode" "prime_factor_algorithm_fft_native"

  let prime_factor_algorithm_fft ~inverse ~domain1 ~domain2 ~domain1_length_log
      ~domain2_length ~coefficients ~scratch_zone =
    prime_factor_algorithm_fft_ext
      inverse
      domain1
      domain2
      domain1_length_log
      domain2_length
      coefficients
      scratch_zone

  let get_primitive_root n =
    let multiplicative_group_order = Z.(Scalar.order - one) in
    let n = Z.of_int n in
    assert (Z.divisible multiplicative_group_order n) ;
    let exponent = Z.divexact multiplicative_group_order n in
    Scalar.pow (Scalar.of_int 7) exponent

  (* Encoding and decoding of Reed-Solomon codes on the erasure channel. *)
  let bench_DAL_crypto_params () =
    let open Tezos_error_monad.Error_monad.Result_syntax in
    (* We take mainnet parameters we divide by [16] to speed up the test. *)
    let number_of_shards = 2048 / 16 in
    let slot_size = 1048576 / 16 in
    let segment_size = 4096 / 16 in
    let msg_size = slot_size in
    let msg = Bytes.create msg_size in
    for i = 0 to (msg_size / 8) - 1 do
      Bytes.set_int64_le msg (i * 8) (Random.int64 Int64.max_int)
    done ;
    let parameters =
      Dal_cryptobox.Internal_for_tests.initialisation_parameters_from_slot_size
        ~slot_size
    in
    let () = Dal_cryptobox.Internal_for_tests.load_parameters parameters in
    Tezos_lwt_result_stdlib.Lwtreslib.Bare.List.iter_e
      (fun redundancy_factor ->
        let* t =
          Dal_cryptobox.make
            {redundancy_factor; slot_size; segment_size; number_of_shards}
        in
        let* p = Dal_cryptobox.polynomial_from_slot t msg in
        let cm = Dal_cryptobox.commit t p in
        let* pi = Dal_cryptobox.prove_segment t p 1 in
        let segment = Bytes.sub msg segment_size segment_size in
        let* check =
          Dal_cryptobox.verify_segment t cm {index = 1; content = segment} pi
        in
        let coefficients =
          Array.init 19 (fun _ -> Scalar.random ()) |> Scalar_array.of_array
        in
        let _domain =
          make_domain
            (Scalar.of_string
               "33954097614611596975476204725091907054106918505758578373023360834096706151438")
            19
        in
        _print_array coefficients ;
        _print_array _domain ;
        List.iter
          (fun i ->
            let eval =
              Bls12_381_polynomial.Polynomial.Polynomial.evaluate
                (Bls12_381_polynomial.Polynomial.Polynomial.of_dense
                   (Scalar_array.to_array coefficients))
                (Scalar_array.get _domain i)
            in
            Printf.eprintf " %s " (Scalar.to_string eval))
          [0; 1; 2; 3; 4; 5; 6; 7; 8; 9; 10; 11; 12; 13; 14; 15; 16; 17; 18] ;
        Printf.eprintf " -- zero : %s \n" Scalar.(to_string zero) ;
        let t' = Sys.time () in
        _dft_c ~inverse:false ~length:19 ~domain:_domain ~coefficients ;
        Printf.eprintf "\n dftC 19 = %f \n" (Sys.time () -. t') ;

        _print_array coefficients ;

        let t' = Sys.time () in
        let rt = get_primitive_root (4 * 19) in
        let domain1 = make_domain (Scalar.pow rt (Z.of_int 19)) 4 in
        let domain2 = make_domain (Scalar.pow rt (Z.of_int 4)) 19 in
        let coefficients =
          Array.init (4 * 19) (fun _ -> Scalar.random ())
          |> Scalar_array.of_array
        in
        let eval =
          Bls12_381_polynomial.Polynomial.Polynomial.evaluate
            (Bls12_381_polynomial.Polynomial.Polynomial.of_dense
               (Scalar_array.to_array coefficients))
            (Scalar.pow rt (Z.of_int 0))
        in
        Printf.eprintf " hey:%s " (Scalar.to_string eval) ;
        let scratch_zone = Scalar_array.allocate (4 * 19) in

        prime_factor_algorithm_fft
          ~domain1_length_log:2
          ~domain2_length:19
          ~domain1
          ~domain2
          ~coefficients
          ~inverse:false
          ~scratch_zone ;
        Printf.eprintf "\n fftC 2^15*16 = %f \n" (Sys.time () -. t') ;

        (*_print_array coefficients ;*)
        Printf.eprintf
          " got: %s "
          (Scalar.to_string (Scalar_array.get coefficients 0)) ;
        let asrt = false in
        assert asrt ;

        assert check ;
        let enc_shards = Dal_cryptobox.shards_from_polynomial t p in
        let c_indices =
          random_indices
            (number_of_shards - 1)
            (number_of_shards / redundancy_factor)
          |> Array.of_list
        in
        let c =
          Dal_cryptobox.IntMap.filter
            (fun i _ -> Array.mem i c_indices)
            enc_shards
        in
        let* dec = Dal_cryptobox.polynomial_from_shards t c in
        assert (
          Bytes.compare
            msg
            (Bytes.sub
               (Dal_cryptobox.polynomial_to_bytes t dec)
               0
               (min slot_size msg_size))
          = 0) ;
        let comm = Dal_cryptobox.commit t p in
        let shard_proofs = Dal_cryptobox.prove_shards t p in
        match Dal_cryptobox.IntMap.find 0 enc_shards with
        | None -> Ok ()
        | Some eval ->
            let check =
              Dal_cryptobox.verify_shard
                t
                comm
                {index = 0; share = eval}
                shard_proofs.(0)
            in
            assert check ;
            let pi = Dal_cryptobox.prove_commitment t p in
            let check = Dal_cryptobox.verify_commitment t comm pi in
            assert check ;
            Ok ()
        (* let point = Scalar.random () in *)
        (* let+ pi_slot = Dal_cryptobox.prove_single trusted_setup p point in
         *
         * assert (
         *   Dal_cryptobox.verify_single
         *     trusted_setup
         *     comm
         *     ~point
         *     ~evaluation:(Dal_cryptobox.polynomial_evaluate p point)
         *     pi_slot) *))
      [2]
    |> fun x -> match x with Ok () -> () | Error _ -> assert false
end

let test =
  [Alcotest.test_case "test_DAL_cryptobox" `Quick Test.bench_DAL_crypto_params]

let () =
  (* Seed for deterministic pseudo-randomness:
      If the environment variable RANDOM_SEED is set, then its value is used as
      as seed. Otherwise, a random seed is used.
     WARNING: using [Random.self_init] elsewhere in the tests breaks thedeterminism.
  *)
  (*Memtrace.trace_if_requested ~context:"Test" () ;*)
  let seed =
    match Sys.getenv_opt "RANDOM_SEED" with
    | None ->
        Random.self_init () ;
        Random.int 1073741823
    | Some v -> int_of_string v
  in

  Random.init seed ;
  Alcotest.run "Kate Amortized" [("DAL cryptobox", test)]
