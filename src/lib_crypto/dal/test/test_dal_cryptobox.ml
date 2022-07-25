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
    let shards_amount = 4096 in
    let slot_size = 1048576 in
    let slot_segment_size = 4096 in
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
        let l = 7 in
        (* l must be power of 2 divisible by 4 *)
        let sz = 1 lsl l in
        let _buffer' =
          Array.init sz (fun i ->
              if i < sz then Scalar.of_int i else Scalar.(copy zero))
        in
        let d' = Kate_amortized.Kate_amortized.Domain.build ~log:l in
        let _dom4 = Kate_amortized.Kate_amortized.Domain.subgroup ~log:2 d' in
        let domrev = Kate_amortized.Kate_amortized.Domain.inverse d' in
        let dom = Kate_amortized.Kate_amortized.inverse domrev in

        let t = Sys.time () in

        (*Kate_amortized.Kate_amortized.fft_inplace3 ~domain:dom ~points:buffer' ;*)

        (*Kate_amortized.Kate_amortized.ifft_inplace3
          ~domain:domrev
          ~points:buffer' ;*)
        (*Kate_amortized.Kate_amortized.print_array2 buffer' ;*)
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
        (*Kate_amortized.Kate_amortized.print_array2
          (Bls12_381_polynomial.Polynomial.Polynomial.to_dense_coefficients res) ;*)
        let buffer =
          Array.init sz (fun i ->
              if i < sz then Scalar.of_int i else Scalar.(copy zero))
        in

        let dft ~inverse ~domain ~coefficients =
          let n = Array.length domain in
          let res = Array.make n Scalar.(copy zero) in
          for i = 0 to n - 1 do
            for j = 0 to n - 1 do
              let mul =
                Scalar.mul
                  coefficients.(j)
                  (Scalar.pow (Array.get domain 1) (Z.of_int (i * j)))
              in
              res.(i) <- Scalar.add res.(i) mul
            done
          done ;
          if inverse then
            for i = 0 to n - 1 do
              res.(i) <-
                Scalar.mul (Scalar.inverse_exn @@ Scalar.of_int n) res.(i)
            done ;
          res
        in

        let dft_g1 ~domain ~coefficients =
          let open Bls12_381 in
          let n = Array.length domain in
          let res = Array.make n G1.(copy zero) in
          for i = 0 to n - 1 do
            for j = 0 to n - 1 do
              let mul =
                G1.mul
                  coefficients.(j)
                  (Scalar.mul (Array.get domain 1) (Scalar.of_int (i * j)))
              in
              res.(i) <- G1.add res.(i) mul
            done
          done ;
          res
        in

        let get_root order =
          let multiplicative_group_order = Z.(Scalar.order - one) in
          let exponent =
            Z.divexact multiplicative_group_order (Z.of_int order)
          in
          Scalar.pow (Scalar.of_int 7) exponent
        in

        let make_domain root d =
          let build_array init next len =
            let xi = ref init in
            Array.init len (fun _ ->
                let i = !xi in
                xi := next !xi ;
                i)
          in
          build_array Scalar.(copy one) (fun g -> Scalar.(mul g root)) d
        in

        let _inv_root root = Scalar.inverse_exn root in

        let _pfa_g1_inplace n1 n2 ~coefficients =
          let n = n1 * n2 in
          assert (Array.length coefficients = n) ;
          let domain_n1 = make_domain (get_root n1) n1 in
          let domain_n2 = make_domain (get_root n2) n2 in
          let columns =
            Array.init n1 (fun _ ->
                Array.init n2 (fun _ -> Bls12_381.G1.(copy zero)))
          in
          let rows =
            Array.init n2 (fun _ ->
                Array.init n1 (fun _ -> Bls12_381.G1.(copy zero)))
          in

          for z = 0 to n - 1 do
            columns.(z mod n1).(z mod n2) <- coefficients.(z)
          done ;

          for k1 = 0 to n1 - 1 do
            columns.(k1) <- dft_g1 ~domain:domain_n2 ~coefficients:columns.(k1)
          done ;

          for k1 = 0 to n1 - 1 do
            for k2 = 0 to n2 - 1 do
              rows.(k2).(k1) <- columns.(k1).(k2)
            done
          done ;

          for k2 = 0 to n2 - 1 do
            rows.(k2) <- dft_g1 ~domain:domain_n1 ~coefficients:rows.(k2)
          done ;

          for k1 = 0 to n1 - 1 do
            for k2 = 0 to n2 - 1 do
              coefficients.(((n1 * k2) + (n2 * k1)) mod n) <- rows.(k2).(k1)
            done
          done
        in

        let _pfa_fr_inplace ~inverse n1 n2 root1 root2 ~coefficients =
          let n = n1 * n2 in
          assert (Array.length coefficients = n) ;
          let domain_n1 = make_domain root1 n1 in
          let domain_n2 = make_domain root2 n2 in
          let columns =
            Array.init n1 (fun _ -> Array.init n2 (fun _ -> Scalar.(copy zero)))
          in
          let rows =
            Array.init n2 (fun _ -> Array.init n1 (fun _ -> Scalar.(copy zero)))
          in

          for z = 0 to n - 1 do
            columns.(z mod n1).(z mod n2) <- coefficients.(z)
          done ;

          for k1 = 0 to n1 - 1 do
            columns.(k1) <-
              dft ~inverse ~domain:domain_n2 ~coefficients:columns.(k1)
          done ;

          for k1 = 0 to n1 - 1 do
            for k2 = 0 to n2 - 1 do
              rows.(k2).(k1) <- columns.(k1).(k2)
            done
          done ;

          for k2 = 0 to n2 - 1 do
            rows.(k2) <- dft ~inverse ~domain:domain_n1 ~coefficients:rows.(k2)
          done ;

          for k1 = 0 to n1 - 1 do
            for k2 = 0 to n2 - 1 do
              coefficients.(((n1 * k2) + (n2 * k1)) mod n) <- rows.(k2).(k1)
            done
          done ;
          let _inverse' domain =
            let n = Array.length domain in
            Array.init n (fun i ->
                if i = 0 then Array.get domain 0 else Array.get domain (n - i))
          in
          if inverse then
            (* TODO: get rid of allocation *)
            (*let res = Array.copy coefficients in
              inverse' res*)
            coefficients
          else coefficients
        in

        Printf.eprintf "\n %s \n" (Scalar.to_string (get_root 3)) ;
        (* P(X)=Mod(15,r)+Mod(2,r)*X+Mod(2578,r)*X^2*)
        let coefficients =
          [|Scalar.of_int 15; Scalar.of_int 2; Scalar.of_int 2578|]
        in
        let domain = make_domain (get_root 3) 3 in

        (*Array.iter
          (fun a -> Printf.eprintf " %s | " (Scalar.to_string a))
          domain ;*)
        let t = Sys.time () in
        let dft' = dft ~inverse:false ~domain ~coefficients in
        Printf.eprintf "\n elapsed dft = %f \n" (Sys.time () -. t) ;

        Array.iter (fun a -> Printf.eprintf " %s | " (Scalar.to_string a)) dft' ;

        (*let _prepare =
            Kate_amortized.Kate_amortized.prepare_fft
              ~phi2N:(Bls12_381_polynomial.Polynomial.Domain.get dom4 1)
              ~domlen:(1 lsl l)
              ()
          in*)
        (*let multiplicative_group_order = Z.(Scalar.order - one) in
          let exponent = Z.divexact multiplicative_group_order (Z.of_int 4) in
          let primroot4th = Scalar.pow (Array.get dom 1) exponent in*)
        (*Printf.eprintf
          "\n %s ; %s \n "
          (Scalar.to_string (Kate_amortized.Kate_amortized.Domain.get _dom4 1))
          (Scalar.to_string (Array.get dom 1)) ;*)
        let t = Sys.time () in
        Scalar.fft_inplace ~domain:dom ~points:buffer ;

        (*Scalar.ifft_inplace ~domain:domrev ~points:buffer ;*)

        (*Kate_amortized.Kate_amortized.fft_inplace2 ~points:buffer ~prepare ;*)
        (*Kate_amortized.Kate_amortized.print_array2 buffer ;*)
        Printf.eprintf "\n ntt radix 2 : %f \n" (Sys.time () -. t) ;

        let coefficients = Array.init sz (fun _ -> Scalar.(random ())) in
        let t = Sys.time () in
        let _res = Scalar.fft ~domain:dom ~points:coefficients in
        Printf.eprintf "\n G1 fft = %f \n" (Sys.time () -. t) ;

        let coefficients = Array.init (2 * 3) (fun _ -> Scalar.(random ())) in
        let coefficients2 = Array.copy coefficients in
        let _coefficients3 = Array.copy coefficients in
        let rt = get_root (2 * 3) in
        let rt1 = Scalar.pow rt (Z.of_int @@ 3) in
        let rt2 = Scalar.pow rt (Z.of_int @@ 2) in
        Printf.eprintf
          "\n rt = %s ; rt5 = %s ; rt3 = %s\n"
          (Scalar.to_string rt)
          (Scalar.to_string rt1)
          (Scalar.to_string rt2) ;
        let t = Sys.time () in
        let coefficients =
          _pfa_fr_inplace 2 3 rt1 rt2 ~coefficients ~inverse:false
        in

        for i = 0 to (2 * 3) - 1 do
          Printf.eprintf
            "\n  fft.(%d)=%s \n"
            i
            (Scalar.to_string coefficients.(i))
        done ;
        let _inverse' domain =
          let n = Array.length domain in
          Array.init n (fun i ->
              if i = 0 then Array.get domain 0 else Array.get domain (n - i))
        in
        (*let coefficients = inverse' coefficients in*)
        let coefficients =
          _pfa_fr_inplace
            2
            3
            (_inv_root rt1)
            (_inv_root rt2)
            ~coefficients
            ~inverse:true
        in
        Printf.eprintf "\n G1 FFT PFA = %f \n" (Sys.time () -. t) ;

        for i = 0 to (2 * 3) - 1 do
          Printf.eprintf
            "\n ifft o fft.(%d)=%s \n"
            i
            (Scalar.to_string coefficients.(i))
        done ;

        for i = 0 to (2 * 3) - 1 do
          Printf.eprintf
            "\n origin.(%d)=%s \n"
            i
            (Scalar.to_string coefficients2.(i))
        done ;

        for i = 0 to (2 * 3) - 1 do
          Printf.eprintf
            "\n eval.(%d)=%s \n"
            i
            (Scalar.to_string
               Bls12_381_polynomial.Polynomial.Polynomial.(
                 evaluate (of_dense coefficients2) (Scalar.pow rt (Z.of_int i))))
        done ;

        (*let i = ref 0 in
          Array.iter
            (fun a ->
              let b =
                Bls12_381_polynomial.Polynomial.Polynomial.(
                  evaluate
                    (of_dense coefficients2)
                    (Scalar.pow (_inv_root rt) (Z.of_int !i)))
              in
              assert (Scalar.eq a b) ;
              i := !i + 1)
            coefficients4 ;*)
        (* let t = Sys.time () in
           let res =
             dft ~domain:(make_domain rt (2 * 3)) ~coefficients:coefficients3
           in
           for i = 0 to (2 * 3) - 1 do
             Printf.eprintf "\n DFT.(%d)=%s \n" i (Scalar.to_string res.(i))
           done ;
           Printf.eprintf "\n G1 FFT dft = %f \n" (Sys.time () -. t) ;*)
        let coefficients = Array.init sz (fun _ -> Bls12_381.G1.(copy one)) in
        let t = Sys.time () in
        (*Kate_amortized.Kate_amortized.fft_g1_inplace2*)
        Kate_amortized.Kate_amortized.fft_g1_inplace2
          ~domain:dom
          ~points:coefficients ;
        (*let res2 = Bls12_381.G1.fft ~domain:dom ~points:coefficients in*)
        Printf.eprintf "\n custom G1 fft inplace = %f \n" (Sys.time () -. t) ;

        let _c = ref 0 in

        (*Array.iter2 (fun a b -> assert (Bls12_381.G1.eq a b)) coefficients res ;*)

        (*Array.iter2
          (fun a b ->
            if not (Scalar.eq a b) then
              Printf.eprintf
                "\n %s != %s \n"
                (Scalar.to_string a)
                (Scalar.to_string b))
          buffer
          buffer' ;*)
        (*let r = false in
          assert r ;*)
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
