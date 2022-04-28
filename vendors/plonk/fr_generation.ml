module type Fr_generation_sig = sig
  type scalar

  val fr_of_int_safe : int -> scalar

  val powers : int -> scalar -> scalar array

  val build_quadratic_non_residues : int -> scalar array

  val generate_random_fr_list : Bytes.t -> int -> scalar list * Bytes.t

  val generate_single_fr : Bytes.t -> scalar * Bytes.t

  val hash_bytes : Bytes.t list -> Bytes.t

  val bytes_to_seed : bytes -> int array * bytes
end

module Make (Scalar : Ff_sig.PRIME) :
  Fr_generation_sig with type scalar = Scalar.t = struct
  (* convert int to Fr scalar (algo based on fast exponentiation model) *)
  type scalar = Scalar.t

  let fr_of_int_safe n = Z.of_int n |> Scalar.of_z

  let succ = Scalar.(add one)

  (* computes [| 1; x; x²; x³; ...; xᵈ⁻¹ |] *)
  let powers d x = Utils.build_array Scalar.one Scalar.(mul x) d

  (* quadratic non-residues for Sid *)
  let build_quadratic_non_residues len =
    let is_nonresidue n = Z.(equal (Scalar.legendre_symbol n) Z.(-one)) in
    let rec next n = succ n |> fun n -> if is_nonresidue n then n else next n in
    Utils.build_array Scalar.one next len

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
    blake2b (Bytes.concat Bytes.empty bytes)

  let z_to_bytes n = Z.to_bits n |> Bytes.of_string

  (*
   * a is the element to hash
   * to_bytes_func, add, one is the function of conversion to_bytes, the function of addition, the one compatible with a type
   * returns x ∈ F built from the hash of a
   * if hash a not in F, returns hash (a+1) until its value belongs to F
   *)
  let rec hash_to_Fr a =
    let b = z_to_bytes a in
    let hashed_b = hash_bytes [b] in
    assert (Bytes.length hashed_b = 32) ;
    let x_fr = Scalar.of_bytes_opt hashed_b in
    match x_fr with
    | Some a -> a (* x_fr can be converted *)
    | None -> hash_to_Fr (Z.succ a)

  (* generate a seed for Random.full_init from hash of b bytes
     Also returns the hash of the bytes*)
  let bytes_to_seed b =
    let hashed_b = hash_bytes [b] in
    assert (Bytes.length hashed_b = 32) ;
    let sys_int_size = Sys.int_size - 1 in
    let modulo = Z.pow (Z.of_int 2) sys_int_size in
    (* seed generation based on four int, computed from hashed_b sub_byte ;
       each ni is Bytes.sub hashed_b i 8 modulo 2**sys.int_size, in order to avoid
       Z.Overflow when ni is converted to int *)
    let n0_raw = Z.of_bits (Bytes.sub_string hashed_b 0 8) in
    let n0 = Z.to_int (Z.erem n0_raw modulo) in
    let n1_raw = Z.of_bits (Bytes.sub_string hashed_b 8 8) in
    let n1 = Z.to_int (Z.erem n1_raw modulo) in
    let n2_raw = Z.of_bits (Bytes.sub_string hashed_b 16 8) in
    let n2 = Z.to_int (Z.erem n2_raw modulo) in
    let n3_raw = Z.of_bits (Bytes.sub_string hashed_b 24 8) in
    let n3 = Z.to_int (Z.erem n3_raw modulo) in
    ([|n0; n1; n2; n3|], hashed_b)

  let generate_random_fr ?state () =
    (match state with None -> () | Some s -> Random.set_state s) ;
    let n0 = Z.of_int64 @@ Random.int64 Int64.max_int in
    let n1 = Z.of_int64 @@ Random.int64 Int64.max_int in
    let n2 = Z.of_int64 @@ Random.int64 Int64.max_int in
    let n3 = Z.of_int64 @@ Random.int64 Int64.max_int in
    let n1_64 = Z.(n1 lsl 64) in
    let n2_128 = Z.(n2 lsl 128) in
    let n3_192 = Z.(n3 lsl 192) in
    let gamma_z = Z.(n0 + n1_64 + n2_128 + n3_192) in
    let gamma_fr = hash_to_Fr gamma_z in
    gamma_fr

  (* generate nb_values scalar of Fr based on seed transcript *)
  let generate_random_fr_list transcript nb_values =
    let (transcript_array, hashed_transcript) = bytes_to_seed transcript in
    Random.full_init transcript_array ;
    (List.init nb_values (fun _ -> generate_random_fr ()), hashed_transcript)

  let generate_single_fr transcript =
    let (l, hashed_transcript) = generate_random_fr_list transcript 1 in
    (List.hd l, hashed_transcript)
end
