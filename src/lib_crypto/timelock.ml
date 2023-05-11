(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2020-2021 Nomadic Labs, <contact@nomadic-labs.com>          *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

open Tezos_hacl
module Blake2b = Hacl_star.Hacl.Blake2b_32

(* -------- Helpers I/O functions -------- *)
let add_path r n = r ^ "/" ^ n

let read_enc filepath filename enc =
  let inc = open_in (add_path filepath filename) in
  let file_size = In_channel.length inc |> Int64.to_int in
  let data = Stdlib.really_input_string inc file_size in
  close_in inc ;
  match Data_encoding.Json.from_string data with
  | Ok json -> Data_encoding.Json.destruct enc json
  | Error _ -> raise (Invalid_argument "Could not read file")

let write_enc filepath filename enc data =
  let outc = open_out (add_path filepath filename) in
  Printf.fprintf outc "%s" Data_encoding.Json.(construct enc data |> to_string) ;
  close_out outc

(* Timelock encryption scheme *)
type symmetric_key = Crypto_box.Secretbox.key

type ciphertext = {nonce : Crypto_box.nonce; payload : bytes}

let ciphertext_encoding =
  let open Data_encoding in
  def "timelock.ciphertext"
  @@ conv_with_guard
       (fun ciphertext -> (ciphertext.nonce, ciphertext.payload))
       (fun (nonce, payload) ->
         if Bytes.length payload <= Crypto_box.tag_length then
           Error "The ciphertext has a negative size"
         else Ok {nonce; payload})
       (obj2
          (req "timelock.nonce" Crypto_box.nonce_encoding)
          (req "timelock.payload" bytes))

let encrypt symmetric_key plaintext =
  let nonce = Crypto_box.random_nonce () in
  {
    nonce;
    payload = Crypto_box.Secretbox.secretbox symmetric_key plaintext nonce;
  }

let decrypt symmetric_key ciphertext =
  Crypto_box.Secretbox.secretbox_open
    symmetric_key
    ciphertext.payload
    ciphertext.nonce

(* -------- Timelock types, conversion functions and encodings -------- *)
(* RSA group rsa2048 = p * q where p and q are prime numbers *)
type rsa_public = Z.t

(* default RSA rsa2048: the 2048 bit RSA rsa2048 challenge
   c.f. https://en.wikipedia.org/wiki/RSA_numbers#RSA-2048 *)
let rsa2048 =
  Z.of_string
    "25195908475657893494027183240048398571429282126204032027777137836043662020707595556264018525880784406918290641249515082189298559149176184502808489120072844992687392807287776735971418347270261896375014971824691165077613379859095700097330459748808428401797429100642458691817195118746121515172654632282216869987549182422433637259085141865462043576798423387184774447920739934236584823824281198163815010674810451660377306056201619676256133844143603833904414952634432190114657544454178424020924616515723350778707749817125772467962926386356373289912154831438167899885040445364023527381951378636564391212010397122822120720357"

(* RSA2048 RSA modulus size. *)
let size_rsa2048 = 2048

let rsa_public_encoding =
  let open Data_encoding in
  def "timelock.rsa2048"
  @@ conv_with_guard
       (fun rsa_public -> rsa_public)
       (fun rsa_public ->
         if Z.equal rsa_public rsa2048 then Ok rsa_public
         else Error "not RSA2048 rsa2048")
       (obj1 (req "rsa_public" n))

(* Timelock challenge, also called "locked" value *)
type puzzle = Z.t

let to_puzzle_opt x =
  let y = Z.of_string x in
  if y >= rsa2048 then None else Some y

let to_puzzle_unsafe = Z.of_string

(* Timelock opening, also called "unlocked" value. *)
type solution = Z.t

(* VDF proof (Wesolowski https://eprint.iacr.org/2018/623.pdf) *)
type vdf_proof = Z.t

(* Timelock tuple: challenge, opening and VDF proof *)
type vdf_tuple = {puzzle : puzzle; solution : solution; vdf_proof : vdf_proof}

let vdf_tuple_encoding =
  let open Data_encoding in
  def "timelock.vdf_tuple"
  @@ conv_with_guard
       (fun vdf_tuple ->
         (vdf_tuple.puzzle, vdf_tuple.solution, vdf_tuple.vdf_proof))
       (fun (puzzle, solution, vdf_proof) ->
         if Z.Compare.(puzzle < Z.zero || puzzle >= rsa2048) then
           Error "puzzle is not in the rsa group"
         else if Z.Compare.(puzzle <= Z.one) then
           Error "invalid value for puzzle"
         else if Z.Compare.(solution < Z.zero || solution >= rsa2048) then
           Error "solution is not in the rsa group"
         else if Z.Compare.(vdf_proof < Z.zero || vdf_proof >= rsa2048) then
           Error "VDF proof is not in the rsa group"
         else Ok {puzzle; solution; vdf_proof})
       (obj3 (req "puzzle" n) (req "solution" n) (req "vdf_proof" n))

let to_vdf_tuple_unsafe ~puzzle ~solution ~vdf_proof =
  {
    puzzle = Z.of_string puzzle;
    solution = Z.of_string solution;
    vdf_proof = Z.of_string vdf_proof;
  }

(* Timelock proof:
   - a VDF tuple, and a random coin
   - a scalar, either the random coin for the precomputer or 1 *)
type timelock_proof = {vdf_tuple : vdf_tuple; randomness : Z.t}

let proof_encoding =
  let open Data_encoding in
  def "timelock.proof"
  @@ conv_with_guard
       (fun proof -> (proof.vdf_tuple, proof.randomness))
       (fun (t, r) ->
         if Z.Compare.(t.puzzle < Z.zero || t.puzzle >= rsa2048) then
           Error "puzzle is not in the rsa group"
         else if Z.Compare.(t.puzzle <= Z.one) then
           Error "invalid value for puzzle"
         else if Z.Compare.(t.solution < Z.zero || t.solution >= rsa2048) then
           Error "solution is not in the rsa group"
         else if Z.Compare.(t.vdf_proof < Z.zero || t.vdf_proof >= rsa2048) then
           Error "VDF proof is not in the rsa group"
         else if Z.Compare.(r < Z.one) then
           Error "randomness is null or negative"
         else Ok {vdf_tuple = t; randomness = r})
       (obj2 (req "vdf_tuple" vdf_tuple_encoding) (req "randomness" n))

(* -------- Timelock low level functions -------- *)
(* A random Z arith element of size [size] bytes *)
let random_z size = Hacl.Rand.gen size |> Bytes.to_string |> Z.of_bits

(* The resulting prime has size 256 bits or slightly more. *)
let hash_to_prime ~time value key =
  let personalization = Bytes.of_string "\032" in
  let s =
    String.concat
      "\xff\x00\xff\x00\xff\x00\xff\x00"
      (Int.to_string time :: List.map Z.to_bits [rsa2048; value; key])
  in
  let hash_result = Blake2b.hash ~key:personalization (Bytes.of_string s) 32 in
  (* Beware, the function nextprime gives a biased distribution,
     using it here is fine as the input is already uniformly distributed *)
  Z.(nextprime (of_bits (Bytes.to_string hash_result)))

let prove_wesolowski ~time puzzle solution =
  let l = hash_to_prime ~time puzzle solution in
  let exponent = Z.(pow (of_int 2) time / l) in
  Z.powm puzzle exponent rsa2048

let prove ~time puzzle solution =
  let vdf_proof = prove_wesolowski ~time puzzle solution in
  let vdf_tuple = {puzzle; solution; vdf_proof} in
  {vdf_tuple; randomness = Z.one}

let verify_wesolowski ~time vdf_tuple =
  let l = hash_to_prime ~time vdf_tuple.puzzle vdf_tuple.solution in
  let r = Z.(powm (of_int 2) (Z.of_int time) l) in
  vdf_tuple.solution
  = Z.(
      powm vdf_tuple.vdf_proof l rsa2048
      * powm vdf_tuple.puzzle r rsa2048
      mod rsa2048)

let to_vdf_tuple_opt ~time ~puzzle ~solution ~vdf_proof =
  let x, y, z = Z.(of_string puzzle, of_string solution, of_string vdf_proof) in
  let b_group =
    Z.(
      x < rsa2048 && y < rsa2048 && z < rsa2048 && x > one && y >= zero
      && z >= zero)
  in
  let vdf_tuple = {puzzle = x; solution = y; vdf_proof = z} in
  let b_weso = verify_wesolowski ~time vdf_tuple in
  if b_group && b_weso then Some vdf_tuple else None

let verify ~time puzzle proof =
  (* Verify link between precomputed tuple, randomness and evaluation *)
  let randomized_challenge =
    Z.powm proof.vdf_tuple.puzzle proof.randomness rsa2048
  in
  let b_exp = Z.(equal randomized_challenge puzzle) in
  (* Verify Wesolowski proof *)
  let b_weso = verify_wesolowski ~time proof.vdf_tuple in
  (* Return *)
  b_exp && b_weso

(* Solve the puzzle by "unlocking" the timelocked value from the timelock, and
   the time. Works in linear time in [time] *)
let rec open_timelock ~time puzzle =
  if time = 0 then puzzle
  else if puzzle = Z.zero then Z.zero
  else if puzzle = Z.one then Z.one
  else open_timelock ~time:Int.(pred time) Z.(puzzle * puzzle mod rsa2048)

let precompute_timelock ?(puzzle = None) ?(precompute_path = None) ~time () =
  let puzzle =
    match puzzle with
    | None ->
        let puzzle = ref Z.one in
        while Z.(equal !puzzle zero) || Z.(equal !puzzle one) do
          (* We divide by 8 to convert to bytes *)
          puzzle := Z.erem (random_z ((size_rsa2048 / 8) + 16)) rsa2048
        done ;
        !puzzle
    | Some c ->
        let c_mod = Z.(c mod rsa2048) in
        assert (Z.compare c_mod Z.one = 1) ;
        c_mod
  in
  let compute_tuple () =
    let solution = open_timelock ~time puzzle in
    (prove ~time puzzle solution).vdf_tuple
  in
  match precompute_path with
  | None -> compute_tuple ()
  | Some filepath ->
      let hash_mod = Blake2b.hash (Z.to_bits rsa2048 |> Bytes.of_string) 32 in
      let file_prefix = Hex.of_bytes hash_mod |> Hex.show in
      let filename = file_prefix ^ "_" ^ string_of_int time ^ ".json" in
      let file_exists = Sys.file_exists (add_path filepath filename) in
      if file_exists then read_enc filepath filename vdf_tuple_encoding
      else
        let precomputed = compute_tuple () in
        write_enc filepath filename vdf_tuple_encoding precomputed ;
        precomputed

let lock_timelock ~time vdf_tuple =
  if Z.compare vdf_tuple.puzzle Z.one < 1 then
    raise (Invalid_argument "Timelock puzzle is smaller than 1.") ;
  if Z.compare vdf_tuple.solution Z.zero < 1 then
    raise (Invalid_argument "Timelock solution is smaller than 0.") ;
  if Z.compare vdf_tuple.vdf_proof Z.zero < 1 then
    raise (Invalid_argument "Timelock proof is smaller than 0.") ;
  if
    Z.compare vdf_tuple.puzzle rsa2048 > -1
    || Z.compare vdf_tuple.solution rsa2048 > -1
    || Z.compare vdf_tuple.vdf_proof rsa2048 > -1
  then
    raise
      (Invalid_argument
         "Invalid timelock tuple, its elements are not in the RSA group.")
  else if verify_wesolowski ~time vdf_tuple then (
    let r = ref Z.zero in
    while Z.(equal !r zero) || Z.(equal !r one) do
      r := random_z ((size_rsa2048 + 128) / 8)
    done ;
    let randomized_puzzle = Z.powm vdf_tuple.puzzle !r rsa2048 in
    let proof = {vdf_tuple; randomness = !r} in
    (randomized_puzzle, proof))
  else raise (Invalid_argument "Timelock tuple verification failed.")

(* Creates a symmetric key using hash based key derivation from the time locked value*)
let timelock_proof_to_symmetric_key proof =
  let updated = Z.powm proof.vdf_tuple.solution proof.randomness rsa2048 in
  let kdf_key = Bytes.of_string "Tezoskdftimelockv1" in
  let to_hash = Z.to_bits updated |> Bytes.of_string in
  let hash = Blake2b.hash ~key:kdf_key to_hash 32 in
  Crypto_box.Secretbox.unsafe_of_bytes hash

(* -------- Timelock high level functions (used in Tezos) -------- *)
type chest = {puzzle : puzzle; rsa_public : rsa_public; ciphertext : ciphertext}

let chest_encoding =
  let open Data_encoding in
  def "timelock.chest"
  @@ conv_with_guard
       (fun chest -> (chest.puzzle, chest.rsa_public, chest.ciphertext))
       (fun (puzzle, rsa_public, ciphertext) ->
         if Z.Compare.(puzzle < Z.zero || puzzle >= rsa_public) then
           Error "puzzle is not in the rsa group"
         else if Z.Compare.(puzzle <= Z.one) then
           Error "invalid value for puzzle"
         else if not @@ Z.equal rsa_public rsa2048 then
           Error "not RSA2048 rsa2048"
         else if not @@ (Bytes.length ciphertext.payload > Crypto_box.tag_length)
         then Error "unexpected payload (smaller than expected tag length)"
         else Ok {puzzle; rsa_public; ciphertext})
       (obj3
          (req "puzzle" n)
          (req "rsa_public" n)
          (req "ciphertext" ciphertext_encoding))

type chest_key = timelock_proof

let chest_key_encoding = proof_encoding

type opening_result = Correct of Bytes.t | Bogus_cipher | Bogus_opening

let create_chest_and_chest_key ?(precompute_path = None) ~payload ~time () =
  if time < 0 then
    raise
      (Invalid_argument "Timelock: trying to create chest with a negative time")
  else
    let puzzle, proof =
      let vdf_tuple = precompute_timelock ~time ~precompute_path () in
      lock_timelock ~time vdf_tuple
    in
    let sym_key = timelock_proof_to_symmetric_key proof in
    let ciphertext = encrypt sym_key payload in
    ({puzzle; rsa_public = rsa2048; ciphertext}, proof)

let create_chest_key chest ~time =
  if time < 0 then
    raise
      (Invalid_argument
         "Timelock: trying to create chest_key with a negative time")
  else
    let solution = open_timelock ~time chest.puzzle in
    prove ~time chest.puzzle solution

let get_plaintext_size chest =
  assert (Bytes.length chest.ciphertext.payload > Crypto_box.tag_length) ;
  Bytes.length chest.ciphertext.payload - Crypto_box.tag_length

let open_chest chest chest_key ~time =
  if time < 0 then
    raise (Invalid_argument "Timelock: trying to open with a negative time")
  else if not @@ verify ~time chest.puzzle chest_key then Bogus_opening
  else
    let sym_key = timelock_proof_to_symmetric_key chest_key in
    match decrypt sym_key chest.ciphertext with
    | None -> Correct Bytes.empty
    | Some plaintext -> Correct plaintext

(* -------- Sampling functions for gas benchmarks -------- *)
(* Those function are unsafe for wallet usage as they use the OCaml
   random generator. This is used to easily reproduce benchmarks. *)
let gen_random_bytes_bench_unsafe size =
  Bytes.init size (fun _ -> Char.chr (Random.int 256))

let gen_puzzle_bench_unsafe =
  let gen_random_z_unsafe size =
    gen_random_bytes_bench_unsafe size |> Bytes.to_string |> Z.of_bits
  in
  Z.erem (gen_random_z_unsafe (size_rsa2048 / 8)) rsa2048

let encrypt_unsafe symmetric_key plaintext =
  let nonce =
    Data_encoding.Binary.of_bytes_exn
      Crypto_box.nonce_encoding
      (gen_random_bytes_bench_unsafe Crypto_box.nonce_size)
  in
  {
    nonce;
    payload = Crypto_box.Secretbox.secretbox symmetric_key plaintext nonce;
  }

let chest_sampler ~rng_state ~plaintext_size ~time =
  Random.set_state rng_state ;
  let plaintext = gen_random_bytes_bench_unsafe plaintext_size in
  let puzzle = gen_puzzle_bench_unsafe in
  let solution = open_timelock ~time puzzle in
  let proof = prove ~time puzzle solution in
  let sym_key = timelock_proof_to_symmetric_key proof in
  let ciphertext = encrypt_unsafe sym_key plaintext in
  ({puzzle; rsa_public = rsa2048; ciphertext}, proof)
