module Test = struct
  module Scalar = Bls12_381.Fr

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
      Cryptobox.Internal_for_tests.initialisation_parameters_from_slot_size
        ~slot_size
        ~segment_size
    in
    let () = Cryptobox.Internal_for_tests.load_parameters parameters in
    Tezos_lwt_result_stdlib.Lwtreslib.Bare.List.iter_e
      (fun redundancy_factor ->
        let t' = Sys.time () in
        let* t =
          Cryptobox.make
            {redundancy_factor; slot_size; segment_size; number_of_shards}
        in
        let* p = Cryptobox.polynomial_from_slot t msg in
        let cm = Cryptobox.commit t p in
        let* pi = Cryptobox.prove_segment t p 1 in
        let segment = Bytes.sub msg segment_size segment_size in
        let* check =
          Cryptobox.verify_segment t cm {index = 1; content = segment} pi
        in
        Printf.eprintf "\n srs = %f \n" (Sys.time () -. t') ;
        assert check ;
        let enc_shards = Cryptobox.shards_from_polynomial t p in
        let c_indices =
          random_indices
            (number_of_shards - 1)
            ((number_of_shards / redundancy_factor) + 1)
          |> Array.of_list
        in

        let c =
          Cryptobox.IntMap.filter (fun i _ -> Array.mem i c_indices) enc_shards
        in
        let* dec = Cryptobox.polynomial_from_shards t c in
        assert (
          Bytes.compare
            msg
            (Bytes.sub
               (Cryptobox.polynomial_to_bytes t dec)
               0
               (min slot_size msg_size))
          = 0) ;
        let comm = Cryptobox.commit t p in
        let shard_proofs = Cryptobox.prove_shards t p in
        match Cryptobox.IntMap.find 0 enc_shards with
        | None -> Ok ()
        | Some eval ->
            let t' = Sys.time () in
            let check =
              Cryptobox.verify_shard
                t
                comm
                {index = 0; share = eval}
                shard_proofs.(0)
            in
            Printf.eprintf "\n verify_shard = %f \n" (Sys.time () -. t') ;
            assert check ;
            let pi = Cryptobox.prove_commitment t p in
            let check = Cryptobox.verify_commitment t comm pi in
            assert check ;
            Ok ()
        (* let point = Scalar.random () in *)
        (* let+ pi_slot = Cryptobox.prove_single trusted_setup p point in
         *
         * assert (
         *   Cryptobox.verify_single
         *     trusted_setup
         *     comm
         *     ~point
         *     ~evaluation:(Cryptobox.polynomial_evaluate p point)
         *     pi_slot) *))
      [16]
    |> fun x -> match x with Ok () -> () | Error _ -> assert false

  let _ = ignore bench_DAL_crypto_params

  let test () =
    match
      let redundancy_factor = 16 in
      let number_of_shards = 2048 in
      let slot_size = 1048576 in
      let segment_size = 4096 in

      let parameters =
        Cryptobox.Internal_for_tests.initialisation_parameters_from_slot_size
          ~slot_size
          ~segment_size
      in
      let () = Cryptobox.Internal_for_tests.load_parameters parameters in

      let msg_size = slot_size in
      let msg = Bytes.create msg_size in
      for i = 0 to (msg_size / 8) - 1 do
        Bytes.set_int64_le msg (i * 8) Int64.max_int
      done ;

      let open Error_monad.Result_syntax in
      let* t =
        Cryptobox.make
          {redundancy_factor; slot_size; segment_size; number_of_shards}
      in
      let* p = Cryptobox.polynomial_from_slot t msg in

      let enc_shards = Cryptobox.shards_from_polynomial t p in
      let c_indices =
        random_indices
          (number_of_shards - 1)
          ((number_of_shards / redundancy_factor) + 1)
        |> Array.of_list
      in

      let c =
        Cryptobox.IntMap.filter (fun i _ -> Array.mem i c_indices) enc_shards
      in
      let* dec = Cryptobox.polynomial_from_shards t c in
      assert (Cryptobox.Polynomials.equal p dec) ;
      (*assert (Bytes.equal msg (Cryptobox.polynomial_to_bytes t dec)) ;*)
      return_unit
    with
    | Ok _ -> ()
    | Error (`Fail s) ->
        Printf.eprintf "\n fail %s \n" s ;
        let f = false in
        assert f
    | Error (`Invert_zero s) ->
        Printf.eprintf "\n no inverse %s \n" s ;
        let f = false in
        assert f
    | Error (`Not_enough_shards s) ->
        Printf.eprintf "\n not enough shards %s \n" s ;
        let f = false in
        assert f
    | Error (`Slot_wrong_size s) ->
        Printf.eprintf "\n slot wrong size %s \n" s ;
        let f = false in
        assert f

  let test_compute_n () =
    let select_fft_domain domain_size =
      let rec powerset = function
        | [] -> [[]]
        | x :: xs ->
            let ps = powerset xs in
            List.concat [ps; List.map (fun ss -> x :: ss) ps]
      in
      let rec multiply_by_two domain_size target_domain_size pow_two =
        if domain_size >= target_domain_size then pow_two
        else multiply_by_two (2 * domain_size) target_domain_size (2 * pow_two)
      in
      let candidate_domains =
        List.map
          (fun factors ->
            let prod1 = List.fold_left ( * ) 1 factors in
            let prod2 = multiply_by_two prod1 domain_size 1 in
            (prod1 * prod2, prod2 :: factors))
          (powerset [3; 11; 19])
      in
      List.fold_left
        (fun e acc -> if fst e < fst acc then e else acc)
        (List.hd candidate_domains)
        candidate_domains
    in
    let redundancy_factor = 16 in

    let number_of_shards = 2048 in
    let slot_size = 1048576 in
    let segment_size = 4096 in
    let scalar_bytes_amount = Scalar.size_in_bytes - 1 in
    let segment_length = Int.div segment_size scalar_bytes_amount + 1 in
    let segment_length_domain, _ = select_fft_domain segment_length in

    let mul = slot_size / segment_size in
    let k = mul * segment_length_domain in
    let n = redundancy_factor * k in

    let module IntMap = Tezos_error_monad.TzLwtreslib.Map.Make (Int) in
    let module Scalar_array = Bls12_381_polynomial.Fr_carray in
    (* Computes the polynomial N(X) := \sum_{i=0}^{k-1} n_i x_i^{-1} X^{z_i}. *)
    let domain_n = Bls12_381_polynomial.Domain.build ~log:8 in
    let compute_n_works (eval_a' : Scalar.t array) shards =
      let w = Bls12_381_polynomial.Domain.get domain_n 1 in
      let n_poly = Array.init n (fun _ -> Scalar.(copy zero)) in
      let c = ref 0 in
      let () =
        IntMap.iter
          (fun z_i arr ->
            if !c >= k then ()
            else
              let rec loop j =
                match j with
                | j when j = Array.length arr -> ()
                | _ -> (
                    let c_i = arr.(j) in
                    let z_i = (number_of_shards * j) + z_i in
                    let x_i = Scalar.pow w (Z.of_int z_i) in
                    let tmp = Array.get eval_a' z_i in
                    Scalar.mul_inplace tmp tmp x_i ;
                    match Scalar.inverse_exn_inplace tmp tmp with
                    | exception _ -> assert false
                    | () ->
                        Scalar.mul_inplace tmp tmp c_i ;
                        n_poly.(z_i) <- tmp ;
                        c := !c + 1 ;
                        loop (j + 1))
              in
              loop 0)
          shards
      in
      n_poly
    in
    let compute_n_break (eval_a' : Scalar.t array) shards =
      let w = Bls12_381_polynomial.Domain.get domain_n 1 in
      let n_poly = Scalar_array.allocate n in
      let c = ref 0 in
      let () =
        IntMap.iter
          (fun z_i arr ->
            if !c >= k then ()
            else
              let rec loop j =
                match j with
                | j when j = Array.length arr -> ()
                | _ -> (
                    let c_i = arr.(j) in
                    let z_i = (number_of_shards * j) + z_i in
                    let x_i = Scalar.pow w (Z.of_int z_i) in
                    let tmp = Array.get eval_a' z_i in
                    Scalar.mul_inplace tmp tmp x_i ;
                    match Scalar.inverse_exn_inplace tmp tmp with
                    | exception _ -> assert false
                    | () ->
                        Scalar.mul_inplace tmp tmp c_i ;
                        Scalar_array.set n_poly tmp z_i ;
                        c := !c + 1 ;
                        loop (j + 1))
              in
              loop 0)
          shards
      in
      n_poly |> Scalar_array.to_array
    in
    let eval_a = Array.init n (fun _ -> Scalar.random ()) in
    let shard =
      let rec loop i map =
        if i = 10 then map
        else
          loop
            (i + 1)
            (IntMap.add i (Array.init 304 (fun _ -> Scalar.random ())) map)
      in
      loop 0 IntMap.empty
    in
    let works = compute_n_works eval_a shard in
    let breaks = compute_n_break eval_a shard in
    assert (Array.for_all2 Scalar.eq works breaks) ;
    ()

  let test_compute_b () =
    let select_fft_domain domain_size =
      let rec powerset = function
        | [] -> [[]]
        | x :: xs ->
            let ps = powerset xs in
            List.concat [ps; List.map (fun ss -> x :: ss) ps]
      in
      let rec multiply_by_two domain_size target_domain_size pow_two =
        if domain_size >= target_domain_size then pow_two
        else multiply_by_two (2 * domain_size) target_domain_size (2 * pow_two)
      in
      let candidate_domains =
        List.map
          (fun factors ->
            let prod1 = List.fold_left ( * ) 1 factors in
            let prod2 = multiply_by_two prod1 domain_size 1 in
            (prod1 * prod2, prod2 :: factors))
          (powerset [3; 11; 19])
      in
      List.fold_left
        (fun e acc -> if fst e < fst acc then e else acc)
        (List.hd candidate_domains)
        candidate_domains
    in

    let module Scalar_array = Bls12_381_polynomial.Fr_carray in
    let slot_size = 1048576 in
    let segment_size = 4096 in
    let number_of_shards = 2048 in
    let redundancy_factor = 16 in
    let scalar_bytes_amount = Scalar.size_in_bytes - 1 in
    let segment_length = Int.div segment_size scalar_bytes_amount + 1 in
    let segment_length_domain, _ = select_fft_domain segment_length in
    let mul = slot_size / segment_size in
    let k = mul * segment_length_domain in
    let n = redundancy_factor * k in
    let t =
      match
        Cryptobox.make
          {redundancy_factor; segment_size; slot_size; number_of_shards}
      with
      | Ok x -> x
      | _ -> assert false
    in

    let n_poly = Array.init n (fun _ -> Scalar.random ()) in
    let works = Cryptobox.Internal_for_tests.b_works t n_poly in
    let breaks =
      Cryptobox.Internal_for_tests.b_breaks t (Scalar_array.of_array n_poly)
    in
    assert (Cryptobox.Polynomials.equal works breaks) ;
    let works_array =
      Cryptobox.Polynomials.to_carray works |> Scalar_array.to_array
    in
    let breaks_array =
      Cryptobox.Polynomials.to_carray breaks |> Scalar_array.to_array
    in
    assert (Array.for_all2 Scalar.eq works_array breaks_array) ;
    ()
end

let test =
  [
    (*Alcotest.test_case "test_DAL_cryptobox" `Quick Test.bench_DAL_crypto_params

      ;*)
    Alcotest.test_case "test_DAL_cryptobox" `Quick Test.test;
    Alcotest.test_case "test_compute_n" `Quick Test.test_compute_n;
    Alcotest.test_case "test_compute_b" `Quick Test.test_compute_b;
  ]

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
