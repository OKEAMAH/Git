module Test = struct
  module Scalar = Bls12_381.Fr
  module Scalar_array = Bls12_381_polynomial.Fr_carray

  type scalar_array = Scalar_array.t

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

  let get_primitive_root n =
    let multiplicative_group_order = Z.(Scalar.order - one) in
    let n = Z.of_int n in
    assert (Z.divisible multiplicative_group_order n) ;
    let exponent = Z.divexact multiplicative_group_order n in
    Scalar.pow (Scalar.of_int 7) exponent

  let _range a b = List.init (b - a) (( + ) a)

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
    let open Tezos_error_monad.Error_monad.Result_syntax in
    (* We take mainnet parameters we divide by [16] to speed up the test. *)
    let number_of_shards = 2048 in
    let slot_size = 1048576 in
    let segment_size = 4096 in
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

        let coefficients =
          Array.init 19 (fun _ -> Scalar.random ()) |> Scalar_array.of_array
        in
        let _coefficients2 = Scalar_array.copy coefficients in
        let rt = get_primitive_root 19 in
        let domain = make_domain (Scalar.inverse_exn rt) 19 in
        _print_array coefficients ;

        (*List.iter
          (fun i ->
            let eval =
              Bls12_381_polynomial.Polynomial.Polynomial.evaluate
                (Bls12_381_polynomial.Polynomial.Polynomial.of_dense
                   (Scalar_array.to_array coefficients))
                (Scalar_array.get _domain i)
            in
            Printf.eprintf " %s " (Scalar.to_string eval))
          (range 0 19) ;*)
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
        let coefficients = Scalar_array.to_array coefficients in
        let t' = Sys.time () in
        let coefficients =
          dft
            ~inverse:false
            ~domain:(Scalar_array.to_array (make_domain rt 19))
            ~coefficients
        in
        Printf.eprintf "\n dft 19 = %f \n" (Sys.time () -. t') ;
        _print_array (Scalar_array.of_array coefficients) ;

        let coefficients = Scalar_array.of_array coefficients in

        let t' = Sys.time () in
        _dft_c ~inverse:true ~length:19 ~domain ~coefficients ;
        Printf.eprintf "\n dftC 19 = %f \n" (Sys.time () -. t') ;

        _print_array coefficients ;

        let* p = Dal_cryptobox.polynomial_from_slot t msg in
        let cm = Dal_cryptobox.commit t p in
        let* pi = Dal_cryptobox.prove_segment t p 1 in
        let segment = Bytes.sub msg segment_size segment_size in
        let* check =
          Dal_cryptobox.verify_segment t cm {index = 1; content = segment} pi
        in

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
    |> function
    | Ok () -> ()
    | Error (`Fail s) -> Printf.eprintf "\n%s\n" s
    | Error (`Invert_zero s) -> Printf.eprintf "\n%s\n" s
    | Error (`Not_enough_shards s) -> Printf.eprintf "\n%s\n" s
    | Error `Segment_index_out_of_range -> Printf.eprintf "\nOOB\n"
    | Error `Slot_segment_index_out_of_range -> Printf.eprintf "\nOOB 2\n"
    | Error (`Slot_wrong_size s) -> Printf.eprintf "\n%s\n" s
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
