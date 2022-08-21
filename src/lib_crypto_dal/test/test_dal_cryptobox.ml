module Test = struct
  module Scalar = Bls12_381.Fr

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
        let* p = Dal_cryptobox.polynomial_from_slot t msg in
        let res = Dal_cryptobox.polynomial_to_bytes t p in
        assert (Bytes.compare msg res = 0) ;
        let cm = Dal_cryptobox.commit t p in
        let* pi = Dal_cryptobox.prove_segment t p 1 in
        let segment = Bytes.sub msg segment_size segment_size in
        let* check =
          Dal_cryptobox.verify_segment t cm {index = 1; content = segment} pi
        in
        Printf.eprintf "\n srs = %f \n" (Sys.time () -. t') ;
        assert check ;

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

        let comm = Dal_cryptobox.commit t p in

        let t' = Sys.time () in
        let shard_proofs = Dal_cryptobox.prove_shards t p in
        Printf.eprintf "\n prove_shards = %f \n" (Sys.time () -. t') ;
        match Dal_cryptobox.IntMap.find 0 enc_shards with
        | None -> Ok ()
        | Some eval ->
            let t' = Sys.time () in
            let check =
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
