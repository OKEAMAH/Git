(* O(k log^2 k + n log n) Reed-Solomon encoding and decoding on the erasure channel *)
open Tezos_error_monad.Error_monad

module type Reed_solomon_params_sig = sig
  module Scalar : Ff_sig.PRIME with type t = Bls12_381.Fr.t

  module Evaluations = Polynomial.Evaluations

  val n : int

  val k : int

  val shards_amount : int

  val domain_n : Scalar.t * Evaluations.domain

  val domain_k : Scalar.t * Evaluations.domain
end

module type Reed_solomon_sig = sig
  module Scalar : Ff_sig.PRIME with type t = Bls12_381.Fr.t

  module IntMap : Tezos_error_monad.TzLwtreslib.Map.S with type key = int

  type polynomial

  val polynomial_to_scalar_array : polynomial -> Scalar.t array

  (** [polynomial_from_bytes message] returns a polynomial from the input message *)
  val polynomial_from_bytes : bytes -> polynomial tzresult

  (** [encode_shares polynomial] returns the Reed-Solomon encoded data in shards *)
  val encode_shares : polynomial -> Scalar.t array IntMap.t tzresult

  (** [decode_shares shards] returns the Reed-Solomon decoded polynomial *)
  val decode_shares : Scalar.t array IntMap.t -> polynomial tzresult
end

module Make (Params : Reed_solomon_params_sig) = struct
  module Poly = Polynomial.Polynomial
  module Evaluations = Polynomial.Evaluations
  module Scalar = Bls12_381.Fr
  module IntMap = Tezos_error_monad.TzLwtreslib.Map.Make (Int)

  type polynomial = Poly.t

  let fft_mul domain a b =
    Evaluations.(
      mul_c
        ~evaluations:
          [("a", evaluation_fft domain a); ("b", evaluation_fft domain b)]
        ()
      |> interpolation_fft domain)

  let poly_mul x =
    let make_domain n =
      Polynomial.Domain.build_with_root ~log:Z.(log2up (of_int n))
    in
    let split = List.fold_left (fun (l, r) x -> (x :: r, l)) ([], []) in
    let rec poly_mul_aux x =
      match x with
      | [] -> Poly.one
      | [x] -> Poly.of_dense [|x; Scalar.one|]
      | _ ->
          let (a, b) = split x in
          let (_, d) = make_domain (List.length x * 2) in
          fft_mul d (poly_mul_aux a) (poly_mul_aux b)
    in
    poly_mul_aux x

  let encode ~message =
    if Poly.degree message > Params.k then
      error_with "message must be lesser than k"
    else Ok (Evaluations.evaluation_fft2 (snd Params.domain_n) message)

  let polynomial_to_scalar_array = Poly.to_array

  let polynomial_from_bytes message =
    if not (Bytes.length message = 1000000) then
      error_with "message must be 1 MB long"
    else
      let nb_elts =
        Int.of_float Float.(floor (div (of_int (Bytes.length message)) 31.))
      in
      let remaining_bytes = Bytes.length message mod 31 in
      let data =
        Array.init Params.k (fun i ->
            match i with
            | i when i < nb_elts ->
                let dst = Bytes.create 31 in
                Bytes.blit message (i * 31) dst 0 31 ;
                Scalar.of_bytes_exn dst
            | i when i = nb_elts ->
                let dst = Bytes.create remaining_bytes in
                Bytes.blit message (i * 31) dst 0 remaining_bytes ;
                Scalar.of_bytes_exn dst
            | _ -> Scalar.zero)
      in
      Ok (Evaluations.interpolation_fft2 (snd Params.domain_k) data)

  let encode_shares message =
    let open Result_syntax in
    let* codeword = encode ~message in
    let len_share = Params.n / Params.shards_amount in
    let rec loop i map =
      match i with
      | i when i = Params.shards_amount -> map
      | _ ->
          let share = Array.make len_share Scalar.zero in
          for j = 0 to len_share - 1 do
            share.(j) <- codeword.((i * len_share) + j)
          done ;
          loop (i + 1) (IntMap.add i share map)
    in
    Ok (loop 0 IntMap.empty)

  let compute_n w eval_a' codeword_shares =
    let n' = Array.init Params.n (fun _ -> Scalar.copy Scalar.zero) in
    let open Result_syntax in
    let time = Unix.gettimeofday () in
    let c = ref 0 in
    let* () =
      IntMap.iter_e
        (fun z_i c_i ->
          if !c >= Params.k then Ok ()
          else
            let x_i = Scalar.pow w (Z.of_int z_i) in
            let tmp = eval_a'.(z_i) in
            Scalar.mul_inplace tmp x_i ;
            match Scalar.inverse_exn_inplace tmp with
            | exception _ -> error_with "can't inverse element"
            | () ->
                Scalar.mul_inplace tmp c_i ;
                n'.(z_i) <- tmp ;
                c := !c + 1 ;
                Ok ())
        codeword_shares
    in
    Printf.printf "\ncompute N(x) : %f s.\n" (Unix.gettimeofday () -. time) ;
    Ok n'

  let decode codeword_shares =
    let open Result_syntax in
    if Params.k > IntMap.cardinal codeword_shares then
      error_with "there must be at least k codeword shares to decode"
    else
      let time = Unix.gettimeofday () in
      (* We always consider the first k codeword components *)
      let (w, domain) = Params.domain_n in

      Printf.eprintf
        "\nlen=%d k=%d\n"
        (IntMap.cardinal codeword_shares)
        Params.k ;
      let time_idx = Unix.gettimeofday () in

      let indices = Array.init Params.k (fun _ -> 0) in
      let c = ref 0 in
      IntMap.iter
        (fun i _ ->
          if !c >= Params.k then () else indices.(!c) <- i ;
          c := !c + 1)
        codeword_shares ;

      Printf.printf "\nindices : %f s.\n" (Unix.gettimeofday () -. time_idx) ;

      (* 1. Computing A(x) = prod_{i=0}^{k-1} (x - w^{z_i}) *)
      let time_pows = Unix.gettimeofday () in

      let pows =
        Array.map (fun e -> Scalar.(negate (pow w (Z.of_int e)))) indices
      in

      Printf.printf "\npows : %f s.\n" (Unix.gettimeofday () -. time_pows) ;

      let time_poly_a = Unix.gettimeofday () in
      let a_poly = poly_mul (pows |> Array.to_list) in

      Printf.printf "\nA(x) : %f s.\n" (Unix.gettimeofday () -. time_poly_a) ;

      (* 2. Computing formal derivative of A(x) *)
      let a' = Poly.derivative a_poly in

      (* 3. Computing A'(w^i)=A_i(w^i) *)
      let eval_a' = Evaluations.evaluation_fft2 domain a' in

      (* 4. Computing N(x) *)
      let* n_poly = compute_n w eval_a' codeword_shares in

      (* 5. Computing B(x) *)
      let b = Evaluations.interpolation_fft2 domain n_poly in
      Poly.truncate_inplace b Params.k ;
      (* TODO: mul inplace truncated (up to the kth index) *)
      Poly.mul_by_scalar_inplace (Scalar.of_int Params.n) b ;

      (* 6. Computing Lagrange interpolation polynomial P(x) *)
      let p = fft_mul domain a_poly b in
      Poly.opposite_truncated_inplace p Params.k ;
      let p = Poly.to_array_truncated p Params.k |> Poly.of_dense in
      Printf.printf "\ndecode : %f s.\n" (Unix.gettimeofday () -. time) ;
      Ok p

  let decode_prepare shares =
    let open Result_syntax in
    let* len_share =
      match IntMap.choose shares with
      | None -> error_with "empty map"
      | Some (_, share) -> Ok (Array.length share)
    in

    (* Flatten map *)
    let time = Unix.gettimeofday () in
    let m =
      IntMap.fold
        (fun i share acc ->
          let rec iter j acc =
            match j with
            | j when j = len_share -> acc
            | _ -> iter (j + 1) (IntMap.add ((i * len_share) + j) share.(j) acc)
          in
          iter 0 acc)
        shares
        IntMap.empty
    in
    Printf.printf "\nflatten shares : %f s.\n" (Unix.gettimeofday () -. time) ;
    Ok m

  let decode_shares shares =
    let open Result_syntax in
    let* codeword_shares = decode_prepare shares in
    decode codeword_shares
end

(*include (Reed_solomon_impl : Reed_solomon_sig)*)
let make_reed_solomon_code ~n ~k ~shards_amount : (module Reed_solomon_sig) =
  let make_domain n =
    Polynomial.Domain.build_with_root ~log:Z.(log2up (of_int n))
  in
  (module Make (struct
    module Evaluations = Polynomial.Evaluations
    module Scalar = Bls12_381.Fr

    let n = n

    let k = k

    let shards_amount = shards_amount

    let domain_k = make_domain k

    let domain_n = make_domain n

    (* check code parameters *)
    let _ =
      let is_pow_of_two x =
        let logx = Z.(log2 (of_int x)) in
        1 lsl logx = x
      in
      assert (is_pow_of_two n) ;
      assert (Z.(log2 (of_int n)) <= 32) ;
      assert (is_pow_of_two k) ;
      assert (n mod shards_amount == 0)
  end))
