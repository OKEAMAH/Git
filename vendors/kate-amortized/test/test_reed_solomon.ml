module Test = struct
  open Kate_amortized

  let random_vector n = Array.init n (fun _ -> Bls12_381.Fr.non_null_random ())

  let print_array ~label a =
    Printf.eprintf
      "%s = %s"
      label
      (Array.map (fun e -> Bls12_381.Fr.to_string e ^ "\n") a
      |> Array.to_list |> String.concat "")

  let print_array2 ~label a =
    Printf.eprintf
      "%s = %s"
      label
      (Array.map (fun e -> Int.to_string e ^ "\n") a
      |> Array.to_list |> String.concat "")

  let print_list ~label l =
    Printf.eprintf
      "%s = %s"
      label
      (List.map (fun e -> Bls12_381.Fr.to_string e ^ "\n") l |> String.concat "")

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

  (* Encoding and decoding of Reed-Solomon codes on the erasure channel *)
  let testRS () =
    let module Poly_c = Polynomial.Polynomial in
    let n = 65536 (* 2^16=65536 *) in
    let k = n / 2 in
    let shards_amount = 2048 in

    let msg = Bytes.create 1000000 in
    for i = 0 to 1000000 / 64 do
      Bytes.set_int64_le msg i (Random.int64 Int64.max_int)
    done ;

    let open Tezos_error_monad.Error_monad.Result_syntax in
    let module RS =
    (val Reed_solomon.make_reed_solomon_code ~n ~k ~shards_amount)
    in
    match
      let* p = RS.polynomial_from_bytes msg in
      let* enc_shares = RS.encode_shares p in

      (* Only take half of the buckets *)
      let c_indices = random_indices (2048 - 1) 1024 |> Array.of_list in

      Printf.eprintf "\nlen c indices=%d\n" (Array.length c_indices) ;
      let c = RS.IntMap.filter (fun i _ -> Array.mem i c_indices) enc_shares in
      Printf.eprintf "\nlen c=%d\n" (RS.IntMap.cardinal c) ;

      let+ dec = RS.decode_shares c in
      let dec = RS.polynomial_to_scalar_array dec in

      let m = RS.polynomial_to_scalar_array p in
      print_array ~label:"m" m ;
      (*print_array ~label:"enc" enc ;*)
      Printf.eprintf "\n" ;
      (*print_array ~label:"enc.(0)" enc_shares.(0) ;*)
      print_array ~label:"dec" dec ;

      assert (Array.length m = Array.length dec) ;

      assert (Array.for_all2 Scalar.eq m dec)
    with
    | Ok () -> Printf.eprintf "OK!"
    | Error e ->
        Format.eprintf
          "Error: %a\n%!\n"
          Tezos_error_monad.Error_monad.pp_print_top_error_of_trace
          e ;
        assert false

  let bench_rs () =
    let n = 65536 (* 2^16=65536 *) in
    let k = n / 2 in
    let shards_amount = 2048 in
    let time = Unix.gettimeofday () in
    let msg = Bytes.create 1000000 in
    for i = 0 to 1000000 / 64 do
      Bytes.set_int64_le msg i (Random.int64 Int64.max_int)
    done ;

    let module RS =
    (val Reed_solomon.make_reed_solomon_code ~n ~k ~shards_amount)
    in
    let open Tezos_error_monad.Error_monad.Result_syntax in
    (let* p = RS.polynomial_from_bytes msg in
     let* enc_shares = RS.encode_shares p in

     Printf.printf "\nencoding : %f s.\n" (Unix.gettimeofday () -. time) ;
     (* Only take half of the buckets *)
     let c_indices = random_indices (2048 - 1) 1024 |> Array.of_list in

     let c = RS.IntMap.filter (fun i _ -> Array.mem i c_indices) enc_shares in

     let time = Unix.gettimeofday () in

     let+ dec = RS.decode_shares c in
     let dec = RS.polynomial_to_scalar_array dec in

     let m = RS.polynomial_to_scalar_array p in

     Printf.printf
       "\ndecoding : %f s. Success : %b\n"
       (Unix.gettimeofday () -. time)
       (Array.for_all2 Scalar.eq m dec))
    |> Result.get_ok

  let bench_rs_params () =
    let k = 32768 (* 2^15 *) in
    let shards_amount = 2048 in
    let msg = Bytes.create 1000000 in
    for i = 0 to 1000000 / 64 do
      Bytes.set_int64_le msg i (Random.int64 Int64.max_int)
    done ;
    let open Tezos_error_monad.Error_monad.Result_syntax in
    List.iter
      (fun i ->
        let n = k lsl i in
        Printf.printf "\nk = 2^15 ; n = 2^%d * k\n" i ;

        let module RS =
        (val Reed_solomon.make_reed_solomon_code ~n ~k ~shards_amount)
        in
        let time = Unix.gettimeofday () in

        (let* p = RS.polynomial_from_bytes msg in
         let* enc_shares = RS.encode_shares p in

         Printf.printf "\nencoding : %f s.\n" (Unix.gettimeofday () -. time) ;

         (* Only take half of the buckets *)
         let c_indices = random_indices (2048 - 1) 1024 |> Array.of_list in

         Printf.eprintf "\nlen c indices=%d\n" (Array.length c_indices) ;
         let c =
           RS.IntMap.filter (fun i _ -> Array.mem i c_indices) enc_shares
         in
         Printf.eprintf "\nlen c=%d\n" (RS.IntMap.cardinal c) ;
         let m = RS.polynomial_to_scalar_array p in

         let time = Unix.gettimeofday () in
         let+ dec = RS.decode_shares c in
         let dec = RS.polynomial_to_scalar_array dec in

         Printf.printf
           "\ndecoding : %f s. Success : %b\n"
           (Unix.gettimeofday () -. time)
           (Array.for_all2 Scalar.eq m dec))
        |> Result.get_ok)
      [4]
end

let tests =
  List.map
    (fun (name, f) -> Alcotest.test_case name `Quick f)
    [("bench_rs_params", Test.bench_rs_params)]

let bench =
  [
    Alcotest.test_case "bench_rs" `Slow Test.bench_rs;
    Alcotest.test_case "bench_rs_params" `Slow Test.bench_rs_params;
  ]
