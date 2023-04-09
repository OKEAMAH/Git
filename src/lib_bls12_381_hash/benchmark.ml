open Core
open Core_bench

let bench_size_in_bits = 512

let bench_size_in_bytes = bench_size_in_bits / 8

let bench_nb_elements_of_fr = bench_size_in_bytes / Bls12_381.Fr.size_in_bytes

let generate_random_input size_in_bytes =
  Stdlib.Bytes.init size_in_bytes (fun _ -> char_of_int @@ Random.int 256)

let bench_anemoi =
  let fr_elements =
    Array.init ~f:(fun _ -> Bls12_381.Fr.random ()) bench_nb_elements_of_fr
  in
  let parameters =
    Bls12_381_hash.Permutation.Anemoi.Parameters.security_128_state_size_2
  in
  let name =
    Printf.sprintf
      "Hash anemoi on %d Fr elements (size in bytes = %d, size in bits = %d)"
      bench_nb_elements_of_fr
      bench_size_in_bytes
      bench_size_in_bits
  in
  let ctxt = Bls12_381_hash.Permutation.Anemoi.allocate_ctxt parameters in
  let () = Bls12_381_hash.Permutation.Anemoi.set_state ctxt fr_elements in
  Bench.Test.create ~name (fun () ->
      Bls12_381_hash.Permutation.Anemoi.apply_permutation ctxt)

let bench_poseidon =
  let fr_elements =
    Array.init ~f:(fun _ -> Bls12_381.Fr.random ()) bench_nb_elements_of_fr
  in
  let parameters =
    Bls12_381_hash.Permutation.Poseidon.Parameters.security_128_state_size_2
  in
  let name =
    Printf.sprintf
      "Hash Poseidon on %d Fr elements (size in bytes = %d, size in bits = %d)"
      bench_nb_elements_of_fr
      bench_size_in_bytes
      bench_size_in_bits
  in
  let ctxt = Bls12_381_hash.Permutation.Poseidon.allocate_ctxt parameters in
  let () = Bls12_381_hash.Permutation.Poseidon.set_state ctxt fr_elements in
  Bench.Test.create ~name (fun () ->
      Bls12_381_hash.Permutation.Poseidon.apply_permutation ctxt)

let bench_rescue =
  let fr_elements =
    Array.init ~f:(fun _ -> Bls12_381.Fr.random ()) bench_nb_elements_of_fr
  in
  let parameters =
    Bls12_381_hash.Permutation.Rescue.Parameters.security_128_state_size_2
  in
  let name =
    Printf.sprintf
      "Hash Rescue on %d Fr elements (size in bytes = %d, size in bits = %d)"
      bench_nb_elements_of_fr
      bench_size_in_bytes
      bench_size_in_bits
  in
  let ctxt = Bls12_381_hash.Permutation.Rescue.allocate_ctxt parameters in
  let () = Bls12_381_hash.Permutation.Rescue.set_state ctxt fr_elements in
  Bench.Test.create ~name (fun () ->
      Bls12_381_hash.Permutation.Rescue.apply_permutation ctxt)

let bench_blake2b =
  let name =
    Printf.sprintf
      "Hash Blake2b on input size in bytes = %d, size in bits = %d"
      bench_size_in_bytes
      bench_size_in_bits
  in
  let hash_bytes bytes =
    (* select the appropriate BLAKE2b function depending on platform and
     * always produce a 32 byte digest *)
    let blake2b msg =
      let digest_size = 32 in
      let open Hacl_star in
      if AutoConfig2.(has_feature VEC256) then
        Hacl.Blake2b_256.hash msg digest_size
      else Hacl.Blake2b_32.hash msg digest_size
    in
    blake2b bytes
  in
  let input = generate_random_input bench_size_in_bytes in
  Bench.Test.create ~name (fun () -> ignore @@ hash_bytes input)

let command =
  Bench.make_command [bench_anemoi; bench_poseidon; bench_blake2b; bench_rescue]

let () = Command_unix.run command
