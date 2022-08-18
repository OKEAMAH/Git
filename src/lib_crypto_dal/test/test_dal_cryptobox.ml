module Test = struct
  module Scalar = Bls12_381.Fr
  module Scalar_array = Bls12_381_polynomial.Fr_carray

  type scalar_array = Scalar_array.t

  let _random_indices bound k =
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

  let computed_hash bs = Tezos_crypto.Blake2B.hash_bytes [bs]

  (*let st =
      Hacl_star.EverCrypt.Hash.init ~alg:Hacl_star.SharedDefs.HashDefs.BLAKE2b
    in
    let len = 48 in
    let msg = Bytes.create len in
    for i = 0 to (Bytes.length bs / len) - 1 do
      Bytes.blit bs (i * len) msg 0 len ;
      Hacl_star.EverCrypt.Hash.update ~st ~msg
    done ;
    Hacl_star.EverCrypt.Hash.finish ~st*)
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

  let range a b = List.init (b - a) (( + ) a)

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
    let number_of_shards = 2048 in
    let slot_size = 1048576 in
    let segment_size = 4096 in
    let msg_size = slot_size in
    let msg = Bytes.create msg_size in
    for i = 0 to (msg_size / 8) - 1 do
      Bytes.set_int64_le msg (i * 8) Int64.max_int
    done ;

    Printf.eprintf
      "\n %s \n"
      (Tezos_crypto.Blake2B.to_string @@ computed_hash msg) ;

    let parameters =
      Dal_cryptobox.Internal_for_tests.initialisation_parameters_from_slot_size
        ~slot_size
    in
    let () = Dal_cryptobox.Internal_for_tests.load_parameters parameters in

    Tezos_lwt_result_stdlib.Lwtreslib.Bare.List.iter_e
      (fun redundancy_factor ->
        let t' = Sys.time () in
        let* t =
          Dal_cryptobox.make
            {redundancy_factor; slot_size; segment_size; number_of_shards}
        in
        Printf.eprintf "\n make = %f \n" (Sys.time () -. t') ;

        let dft ~inverse ~domain ~coefficients =
          let n = Array.length domain in
          let res = Array.make n Scalar.(copy zero) in
          for i = 0 to n - 1 do
            for j = 0 to n - 1 do
              let mul =
                Scalar.mul coefficients.(j) (Array.get domain (i * j mod n))
              in
              res.(i) <- Scalar.add res.(i) mul
            done
          done ;
          if inverse then
            for i = 0 to n - 1 do
              res.(i) <- Scalar.(mul (inverse_exn (of_int n)) res.(i))
            done ;
          res
        in
        let coefficients = Array.init 19 (fun _ -> Scalar.random ()) in
        let t' = Sys.time () in
        let _ =
          dft
            ~inverse:false
            ~domain:
              (make_domain (get_primitive_root 19) 19 |> Scalar_array.to_array)
            ~coefficients
        in
        Printf.eprintf "\n dft 19 = %f \n" (Sys.time () -. t') ;

        let points = Array.init 32768 (fun _ -> Scalar.random ()) in
        let t' = Sys.time () in
        let _ =
          Bls12_381.Fr.fft_inplace
            ~domain:
              (make_domain (get_primitive_root 32768) 32768
              |> Scalar_array.to_array)
            ~points
        in
        Printf.eprintf "\n fft 2^11*16 = %f \n" (Sys.time () -. t') ;

        let points = Array.init 1048576 (fun _ -> Scalar.random ()) in
        let t' = Sys.time () in
        let _ =
          Bls12_381.Fr.fft_inplace
            ~domain:
              (make_domain (get_primitive_root 1048576) 1048576
              |> Scalar_array.to_array)
            ~points
        in
        Printf.eprintf "\n fft 2^16*16 = %f \n" (Sys.time () -. t') ;

        (*let asrt = false in
          assert asrt ;
          let t' = Sys.time () in*)
        Printf.eprintf "\n srs = %f \n" (Sys.time () -. t') ;

        let t' = Sys.time () in
        let* p = Dal_cryptobox.polynomial_from_slot t msg in
        Printf.eprintf "\n polynomial_from_slot = %f \n" (Sys.time () -. t') ;
        let t' = Sys.time () in
        let msg' = Dal_cryptobox.polynomial_to_bytes t p in
        Printf.eprintf "\n polynomial_to_bytes = %f \n" (Sys.time () -. t') ;
        assert (Bytes.compare msg msg' = 0) ;
        let t' = Sys.time () in
        let cm = Dal_cryptobox.commit t p in
        Printf.eprintf "\n commit = %f \n" (Sys.time () -. t') ;
        let t' = Sys.time () in
        let* pi = Dal_cryptobox.prove_segment t p 1 in
        Printf.eprintf "\n prove_segment = %f \n" (Sys.time () -. t') ;
        let segment = Bytes.sub msg segment_size segment_size in
        let t' = Sys.time () in
        let* check =
          Dal_cryptobox.verify_segment t cm {index = 1; content = segment} pi
        in
        Printf.eprintf "\n verify_segment = %f \n" (Sys.time () -. t') ;
        let coefficients = Scalar_array.allocate 19 in

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
          (range 0 19) ;
        Printf.eprintf " -- zero : %s \n" Scalar.(to_string zero) ;
        let t' = Sys.time () in
        _dft_c ~inverse:false ~length:19 ~domain:_domain ~coefficients ;
        Printf.eprintf "\n dftC 19 = %f \n" (Sys.time () -. t') ;

        _print_array coefficients ;

        Printf.eprintf "\n ==================== \n" ;

        let size = 2048 in
        let rt = get_primitive_root (size * 19) in
        let domain = make_domain rt (size * 19) in
        let domain1 = make_domain (Scalar.pow rt (Z.of_int 19)) size in
        let domain2 = make_domain (Scalar.pow rt (Z.of_int size)) 19 in
        let coefficients =
          Array.init (size * 19) (fun _ -> Scalar.(random ()))
          |> Scalar_array.of_array
        in
        let scratch_zone = Scalar_array.allocate (2 * size * 19) in

        List.iter
          (fun i ->
            let eval =
              Bls12_381_polynomial.Polynomial.Polynomial.evaluate
                (Bls12_381_polynomial.Polynomial.Polynomial.of_dense
                   (Scalar_array.to_array coefficients))
                (Scalar_array.get domain i)
            in
            Printf.eprintf " %s " (Scalar.to_string eval))
          (range 0 4) ;

        let t' = Sys.time () in
        prime_factor_algorithm_fft
          ~domain1_length_log:11
          ~domain2_length:19
          ~domain1
          ~domain2
          ~coefficients
          ~inverse:false
          ~scratch_zone ;
        Printf.eprintf "\n fftC 2^15*16 = %f \n" (Sys.time () -. t') ;

        (*_print_array coefficients ;*)
        Printf.eprintf
          "\n %s \n"
          (Scalar.to_string @@ Scalar_array.get coefficients 1) ;

        (*let asrt = false in
          assert asrt ;*)
        assert check ;
        let t' = Sys.time () in
        let enc_shards = Dal_cryptobox.shards_from_polynomial t p in
        Printf.eprintf "\n shard_from_polynomial = %f \n" (Sys.time () -. t') ;

        (match Dal_cryptobox.IntMap.find 0 enc_shards with
        | None -> ()
        | Some eval ->
            let eval = Obj.magic eval in
            Printf.eprintf "\n len share =%d \n" (Array.length eval)) ;

        let ( -- ) _ b = Array.init b (fun i -> i) in

        (* Only take half of the buckets *)
        let c_indices =
          0 -- (number_of_shards / redundancy_factor)
          (*random_indices
              (shards_amount - 1)
              ((shards_amount / redundancy_factor) + 1)
            |> Array.of_list*)
        in

        let c =
          Dal_cryptobox.IntMap.filter
            (fun i _ -> Array.mem i c_indices)
            enc_shards
        in

        let t' = Sys.time () in
        let* dec = Dal_cryptobox.polynomial_from_shards t c in
        let msg' = Dal_cryptobox.polynomial_to_bytes t dec in
        Printf.eprintf "\n polynomial_from_shards = %f \n" (Sys.time () -. t') ;

        Printf.eprintf
          "\n %s \n"
          (Tezos_crypto.Blake2B.to_string @@ computed_hash msg') ;
        assert (Bytes.compare msg msg' = 0) ;

        (*let asrt = false in
        assert asrt ;*)

        let comm = Dal_cryptobox.commit t p in

        let t' = Sys.time () in
        let shard_proofs = Dal_cryptobox.prove_shards t p in
        Printf.eprintf "\n prove_shards = %f \n" (Sys.time () -. t') ;
        match Dal_cryptobox.IntMap.find 0 enc_shards with
        | None -> Ok ()
        | Some eval ->
            let t' = Sys.time () in
            let _check =
              Dal_cryptobox.verify_shard
                t
                comm
                {index = 0; share = eval}
                shard_proofs.(0)
            in
            Printf.eprintf "\n verify_shard = %f \n" (Sys.time () -. t') ;

            assert check ;

            let t' = Sys.time () in
            let pi = Dal_cryptobox.prove_commitment t p in
            Printf.eprintf "\n prove_degree = %f \n" (Sys.time () -. t') ;
            let t' = Sys.time () in
            let check = Dal_cryptobox.verify_commitment t comm pi in
            Printf.eprintf "\n verify_commitment = %f \n" (Sys.time () -. t') ;
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
      [16]
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
