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

  (* Encoding and decoding of Reed-Solomon codes on the erasure channel. *)
  let bench_DAL_crypto_params () =
    let shards_amount = 2048 / 32 in
    let slot_size = 1048576 / 32 in
    let slot_segment_size = 4096 / 32 in
    let msg_size = slot_size in
    let msg = Bytes.create msg_size in
    for i = 0 to (msg_size / 8) - 1 do
      Bytes.set_int64_le msg (i * 8) (Random.int64 Int64.max_int)
    done ;
    let open Tezos_error_monad.Error_monad.Result_syntax in
    List.iter
      (fun redundancy_factor ->
        let module DAL_crypto = Dal_cryptobox.Make (struct
          let redundancy_factor = redundancy_factor

          let slot_size = slot_size

          let slot_segment_size = slot_segment_size

          let shards_amount = shards_amount
        end) in
        let l = 3 in
        (* l must be power of 2 divisible by 4 *)
        let sz = 1 lsl l in
        let buffer' =
          Array.init sz (fun i ->
              if i < sz then Scalar.of_int i else Scalar.(copy zero))
        in
        let d' = Kate_amortized.Kate_amortized.Domain.build ~log:l in
        let _dom4 = Kate_amortized.Kate_amortized.Domain.subgroup ~log:2 d' in
        let domrev = Kate_amortized.Kate_amortized.Domain.inverse d' in
        let dom = Kate_amortized.Kate_amortized.inverse domrev in

        let t = Sys.time () in
        Kate_amortized.Kate_amortized.fft_inplace3 ~domain:dom ~points:buffer' ;

        Kate_amortized.Kate_amortized.ifft_inplace3
          ~domain:domrev
          ~points:buffer' ;
        Kate_amortized.Kate_amortized.print_array2 buffer' ;
        Printf.eprintf "\n ntt radix 2 : %f \n" (Sys.time () -. t) ;

        (*Array.iter2
          (fun a b ->
            if not (Scalar.eq a b) then
              Printf.eprintf
                "\n %s != %s \n"
                (Scalar.to_string a)
                (Scalar.to_string b))
          buffer
          buffer' ;*)
        (*Kate_amortized.Kate_amortized.print_array2
          (Bls12_381_polynomial.Polynomial.Polynomial.to_dense_coefficients res) ;*)
        let buffer =
          Array.init sz (fun i ->
              if i < sz then Scalar.of_int i else Scalar.(copy zero))
        in

        (*let _prepare =
            Kate_amortized.Kate_amortized.prepare_fft
              ~phi2N:(Bls12_381_polynomial.Polynomial.Domain.get dom4 1)
              ~domlen:(1 lsl l)
              ()
          in*)
        (*let multiplicative_group_order = Z.(Scalar.order - one) in
          let exponent = Z.divexact multiplicative_group_order (Z.of_int 4) in
          let primroot4th = Scalar.pow (Array.get dom 1) exponent in*)
        Printf.eprintf
          "\n %s ; %s \n "
          (Scalar.to_string (Kate_amortized.Kate_amortized.Domain.get _dom4 1))
          (Scalar.to_string (Array.get dom 1)) ;
        let t = Sys.time () in
        Scalar.fft_inplace ~domain:dom ~points:buffer ;

        Scalar.ifft_inplace ~domain:domrev ~points:buffer ;

        (*Kate_amortized.Kate_amortized.fft_inplace2 ~points:buffer ~prepare ;*)
        Kate_amortized.Kate_amortized.print_array2 buffer ;

        Printf.eprintf "\n ntt radix 4 : %f \n" (Sys.time () -. t) ;

        (*Array.iter2
          (fun a b ->
            if not (Scalar.eq a b) then
              Printf.eprintf
                "\n %s != %s \n"
                (Scalar.to_string a)
                (Scalar.to_string b))
          buffer
          buffer' ;*)
        let r = false in
        assert r ;

        let trusted_setup =
          DAL_crypto.build_trusted_setup_instance `Unsafe_for_test_only
          (*(`Files
            {
              srs_g1_file = "./test/srs_zcash_g1";
              srs_g2_file = "./test/srs_zcash_g2";
              logarithm_size = 21;
            })*)
        in

        Printf.eprintf "\n n=%d\n" DAL_crypto.erasure_encoding_length ;
        match
          let* p = DAL_crypto.polynomial_from_bytes msg in

          let* cm = DAL_crypto.commit trusted_setup p in
          let t = Sys.time () in
          let* pi = DAL_crypto.prove_slot_segment trusted_setup p 0 in
          Printf.eprintf "\n prove=%f \n" (Sys.time () -. t) ;

          let slot_segment =
            Bytes.sub msg (0 * slot_segment_size) slot_segment_size
          in
          let t = Sys.time () in
          let* check =
            DAL_crypto.verify_slot_segment trusted_setup cm (0, slot_segment) pi
          in
          Printf.eprintf "\n verify=%f \n" (Sys.time () -. t) ;
          assert check ;
          let t = Sys.time () in
          let enc_shards = DAL_crypto.to_shards p in
          Printf.eprintf "\n to_shards=%f \n" (Sys.time () -. t) ;
          (* Only take half of the buckets *)
          let c_indices =
            random_indices (shards_amount - 1) (shards_amount / 2)
            |> Array.of_list
          in

          let c =
            DAL_crypto.IntMap.filter
              (fun i _ -> Array.mem i c_indices)
              enc_shards
          in

          let t = Sys.time () in
          let* dec = DAL_crypto.from_shards c in
          Printf.eprintf "\n from_shards=%f \n" (Sys.time () -. t) ;
          assert (
            Bytes.compare
              msg
              (Bytes.sub
                 (DAL_crypto.polynomial_to_bytes dec)
                 0
                 (min slot_size msg_size))
            = 0) ;

          let* comm = DAL_crypto.commit trusted_setup p in
          let t = Sys.time () in
          let precompute_pi_shards =
            DAL_crypto.precompute_shards_proofs trusted_setup
          in
          let _filename = "shard_proofs_precomp" in

          (*let () =
              DAL_crypto.save_precompute_shards_proofs
                precompute_pi_shards
                filename
            in*)

          (*let precompute_pi_shards =
              DAL_crypto.load_precompute_shards_proofs filename
            in*)
          Printf.eprintf "\n precomp shard=%f \n" (Sys.time () -. t) ;
          let t = Sys.time () in
          let shard_proofs =
            DAL_crypto.prove_shards p ~preprocess:precompute_pi_shards
          in
          Printf.eprintf "\n prove shard=%f \n" (Sys.time () -. t) ;
          match DAL_crypto.IntMap.find 0 enc_shards with
          | None -> Ok ()
          | Some eval ->
              assert (
                DAL_crypto.verify_shard
                  trusted_setup
                  comm
                  (0, eval)
                  shard_proofs.(0)) ;

              let* pi =
                DAL_crypto.prove_degree
                  trusted_setup
                  p
                  (DAL_crypto.polynomial_degree p)
              in

              let* check =
                DAL_crypto.verify_degree
                  trusted_setup
                  comm
                  pi
                  (DAL_crypto.polynomial_degree p)
              in
              assert check ;

              let point = Scalar.random () in
              let+ pi_slot = DAL_crypto.prove_single trusted_setup p point in

              assert (
                DAL_crypto.verify_single
                  trusted_setup
                  comm
                  ~point
                  ~evaluation:(DAL_crypto.polynomial_evaluate p point)
                  pi_slot)
        with
        | Ok () -> ()
        | Error _ -> assert false)
      [2]
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
  Alcotest.run "Kate Amortized" [("DAScryptobox", test)]
