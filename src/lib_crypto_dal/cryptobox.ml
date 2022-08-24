(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
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

open Error_monad
include Cryptobox_intf
module Base58 = Tezos_crypto.Base58
module Srs_g1 = Bls12_381_polynomial.Polynomial.M.Srs_g1
module Srs_g2 = Bls12_381_polynomial.Polynomial.M.Srs_g2

(* TODO: find better place for this piece of code *)
module Scalar_array = Bls12_381_polynomial.Fr_carray

type scalar_array = Scalar_array.t

external prime_factor_algorithm_fft_ext :
  bool ->
  scalar_array ->
  scalar_array ->
  int ->
  int ->
  scalar_array ->
  scalar_array ->
  unit
  = "prime_factor_algorithm_fft_bytecode" "prime_factor_algorithm_fft_native"

let prime_factor_algorithm_fft ~inverse ~domain1 ~domain2 ~domain1_length_log
    ~domain2_length ~coefficients ~scratch_zone =
  let res = Scalar_array.allocate (Scalar_array.length coefficients) in
  Scalar_array.blit
    coefficients
    ~src_off:0
    res
    ~dst_off:0
    ~len:(Scalar_array.length coefficients) ;
  prime_factor_algorithm_fft_ext
    inverse
    domain1
    domain2
    domain1_length_log
    domain2_length
    res
    scratch_zone ;
  res

external prime_factor_algorithm_fft_ext2 :
  bool ->
  scalar_array ->
  scalar_array ->
  int ->
  int ->
  scalar_array ->
  scalar_array ->
  unit
  = "prime_factor_algorithm_fft_bytecode2" "prime_factor_algorithm_fft_native2"

let prime_factor_algorithm_fft2 ~inverse ~domain1 ~domain2 ~domain1_length
    ~domain2_length ~coefficients ~scratch_zone =
  let res = Scalar_array.allocate (Scalar_array.length coefficients) in
  Scalar_array.blit
    coefficients
    ~src_off:0
    res
    ~dst_off:0
    ~len:(Scalar_array.length coefficients) ;
  prime_factor_algorithm_fft_ext2
    inverse
    domain1
    domain2
    domain1_length
    domain2_length
    res
    scratch_zone ;
  res

(* END TODO: find better place for this piece of code *)

type error += Failed_to_load_trusted_setup of string

let () =
  register_error_kind
    `Permanent
    ~id:"dal.node.trusted_setup_loading_failed"
    ~title:"Trusted setup loading failed"
    ~description:"Trusted setup failed to load"
    ~pp:(fun ppf msg ->
      Format.fprintf ppf "Trusted setup failed to load: %s" msg)
    Data_encoding.(obj1 (req "msg" string))
    (function
      | Failed_to_load_trusted_setup parameter -> Some parameter | _ -> None)
    (fun parameter -> Failed_to_load_trusted_setup parameter)

type initialisation_parameters = {srs_g1 : Srs_g1.t; srs_g2 : Srs_g2.t}

(* Initialisation parameters are supposed to be instantiated once. *)
let initialisation_parameters = ref None

type error += Dal_initialisation_twice

(* This function is expected to be called once. *)
let load_parameters parameters =
  let open Result_syntax in
  match !initialisation_parameters with
  | None ->
      initialisation_parameters := Some parameters ;
      return_unit
  | Some _ -> fail [Dal_initialisation_twice]

(* FIXME https://gitlab.com/tezos/tezos/-/issues/3400

   An integrity check is run to ensure the validity of the files. *)

let initialisation_parameters_from_files ~g1_path ~g2_path =
  let open Lwt_result_syntax in
  (* FIXME https://gitlab.com/tezos/tezos/-/issues/3409

     The `21` constant is the logarithmic size of the file. Can this
     constant be recomputed? Even though it should be determined by
     the integrity check. *)
  let logarithmic_size = 21 in
  let to_bigstring path =
    let open Lwt_syntax in
    let* fd = Lwt_unix.openfile path [Unix.O_RDONLY] 0o440 in
    Lwt.finalize
      (fun () ->
        return
          (Lwt_bytes.map_file
             ~fd:(Lwt_unix.unix_file_descr fd)
             ~shared:false
             ~size:(1 lsl logarithmic_size)
             ()))
      (fun () -> Lwt_unix.close fd)
  in
  let*! srs_g1_bigstring = to_bigstring g1_path in
  let*! srs_g2_bigstring = to_bigstring g2_path in
  match
    let open Result_syntax in
    let* srs_g1 = Srs_g1.of_bigstring srs_g1_bigstring in
    let* srs_g2 = Srs_g2.of_bigstring srs_g2_bigstring in
    return (srs_g1, srs_g2)
  with
  | Error (`End_of_file s) -> tzfail (Failed_to_load_trusted_setup s)
  | Error (`Invalid_point p) ->
      tzfail
        (Failed_to_load_trusted_setup (Printf.sprintf "Invalid point %i" p))
  | Ok (srs_g1, srs_g2) -> return {srs_g1; srs_g2}

(* The srs is made of the initialisation_parameters and two
   well-choosen points. Building the srs from the initialisation
   parameters is almost cost-free. *)
type srs = {
  raw : initialisation_parameters;
  kate_amortized_srs_g2_shards : Bls12_381.G2.t;
  kate_amortized_srs_g2_segments : Bls12_381.G2.t;
}

module Inner = struct
  (* Scalars are elements of the prime field Fr from BLS. *)
  module Scalar = Bls12_381.Fr
  module Polynomial = Bls12_381_polynomial.Polynomial.M

  (* Operations on vector of scalars *)
  module Evaluations = Polynomial.Evaluations

  (* Domains for the Fast Fourier Transform (FTT). *)
  module Domains = Polynomial.Domain
  module Polynomials = Polynomial.Polynomial.Polynomial_unsafe
  module IntMap = Tezos_error_monad.TzLwtreslib.Map.Make (Int)

  type slot = bytes

  type scalar = Scalar.t

  type polynomial = Polynomials.t

  type commitment = Bls12_381.G1.t

  type shard_proof = Bls12_381.G1.t

  type commitment_proof = Bls12_381.G1.t

  type _proof_single = Bls12_381.G1.t

  type segment_proof = Bls12_381.G1.t

  type segment = {index : int; content : bytes}

  type share = Scalar.t array

  type _shards_map = share IntMap.t

  type shard = {index : int; share : share}

  type shards_proofs_precomputation = Scalar.t array * segment_proof array array

  module Encoding = struct
    open Data_encoding

    let fr_encoding = conv Bls12_381.Fr.to_bytes Bls12_381.Fr.of_bytes_exn bytes

    (* FIXME https://gitlab.com/tezos/tezos/-/issues/3391

       The commitment is not bounded. *)
    let g1_encoding =
      conv
        Bls12_381.G1.to_compressed_bytes
        Bls12_381.G1.of_compressed_bytes_exn
        bytes

    let _proof_shards_encoding = g1_encoding

    let commitment_proof_encoding = g1_encoding

    let _proof_single_encoding = g1_encoding

    let segment_proof_encoding = g1_encoding

    let share_encoding = array fr_encoding

    let shard_encoding =
      conv
        (fun {index; share} -> (index, share))
        (fun (index, share) -> {index; share})
        (tup2 int31 share_encoding)

    let shards_encoding =
      conv
        IntMap.bindings
        (fun bindings -> IntMap.of_seq (List.to_seq bindings))
        (list (tup2 int31 share_encoding))

    let shards_proofs_precomputation_encoding =
      tup2 (array fr_encoding) (array (array g1_encoding))
  end

  include Encoding

  module Commitment = struct
    type t = commitment

    type Base58.data += Data of t

    let zero = Bls12_381.G1.zero

    let commitment_to_bytes = Bls12_381.G1.to_compressed_bytes

    let commitment_of_bytes_opt = Bls12_381.G1.of_compressed_bytes_opt

    let commitment_of_bytes_exn bytes =
      match Bls12_381.G1.of_compressed_bytes_opt bytes with
      | None ->
          Format.kasprintf Stdlib.failwith "Unexpected data (DAL commitment)"
      | Some commitment -> commitment

    (* We divide by two because we use the compressed representation. *)
    let commitment_size = Bls12_381.G1.size_in_bytes / 2

    let to_string commitment = commitment_to_bytes commitment |> Bytes.to_string

    let of_string_opt str = commitment_of_bytes_opt (String.to_bytes str)

    let b58check_encoding =
      Base58.register_encoding
        ~prefix:Base58.Prefix.slot_header
        ~length:commitment_size
        ~to_raw:to_string
        ~of_raw:of_string_opt
        ~wrap:(fun x -> Data x)

    let raw_encoding =
      let open Data_encoding in
      conv
        commitment_to_bytes
        commitment_of_bytes_exn
        (Fixed.bytes commitment_size)

    include Tezos_crypto.Helpers.Make (struct
      type t = commitment

      let name = "DAL_commitment"

      let title = "Commitment representation for the DAL"

      let b58check_encoding = b58check_encoding

      let raw_encoding = raw_encoding

      let compare = compare

      let equal = ( = )

      let hash _ =
        (* The commitment is not hashed. This is ensured by the
           function exposed. We only need the Base58 encoding and the
           rpc_arg. *)
        assert false

      let seeded_hash _ _ =
        (* Same argument. *)
        assert false
    end)
  end

  include Commitment

  (* Number of bytes fitting in a Scalar.t. Since scalars are integer modulo
     r~2^255, we restrict ourselves to 248-bit integers (31 bytes). *)
  let scalar_bytes_amount = Scalar.size_in_bytes - 1

  (* Builds group of nth roots of unity, a valid domain for the FFT. *)
  (*let make_domain n = Domains.build ~log:Z.(log2up (of_int n))*)

  let _make_domain root d =
    let build_array init next len =
      let xi = ref init in
      Array.init len (fun _ ->
          let i = !xi in
          xi := next !xi ;
          i)
    in
    build_array Scalar.(copy one) (fun g -> Scalar.(mul g root)) d

  let get_primitive_root n =
    let multiplicative_group_order = Z.(Scalar.order - one) in
    let n = Z.of_int n in
    assert (Z.divisible multiplicative_group_order n) ;
    let exponent = Z.divexact multiplicative_group_order n in
    Scalar.pow (Scalar.of_int 7) exponent

  type fft_configuration = {
    buffer : scalar_array;
    domain_k : int * int list; (*domains : scalar_array IntMap.t;*)
  }

  type t = {
    redundancy_factor : int;
    slot_size : int;
    segment_size : int;
    number_of_shards : int;
    k : int;
    n : int;
    (* k and n are the parameters of the erasure code. *)
    domain_k : scalar_array;
    (* Domain for the FFT on slots as polynomials to be erasure encoded. *)
    domain_2k : scalar_array;
    domain_n : scalar_array;
    scratch_zone : scalar_array;
    (* Domain for the FFT on erasure encoded slots (as polynomials). *)
    shard_size : int;
    (* Length of a shard in terms of scalar elements. *)
    nb_segments : int;
    (* Number of slot segments. *)
    segment_length : int;
    segment_length_domain : int;
    remaining_bytes : int;
    (* Log of the number of evaluations contained in a shard. *)
    srs : srs;
    fft_configuration : fft_configuration;
  }

  let make_domain2 root d =
    let module Scalar = Bls12_381.Fr in
    let build_array init next len =
      let xi = ref init in
      Array.init len (fun _ ->
          let i = !xi in
          xi := next !xi ;
          i)
    in
    build_array Scalar.(copy one) (fun g -> Scalar.(mul g root)) d
    |> Scalar_array.of_array

  let ensure_validity t =
    let open Result_syntax in
    let srs_size = Srs_g1.size t.srs.raw.srs_g1 in
    let is_pow_of_two x =
      let logx = Z.(log2 (of_int x)) in
      1 lsl logx = x
    in
    if
      not
        (is_pow_of_two t.slot_size
        && is_pow_of_two t.segment_size (*&& is_pow_of_two t.n*))
    then
      (* According to the specification the lengths of a slot a slot segment are
         in MiB *)
      fail (`Fail "Wrong slot size: expected MiB")
      (*else if not (Z.(log2 (of_int t.n)) <= 32 && is_pow_of_two t.k && t.n > t.k)
        then
          (* n must be at most 2^32, the biggest subgroup of 2^i roots of unity in the
             multiplicative group of Fr, because the FFTs operate on such groups. *)
          fail (`Fail "Wrong computed size for n")*)
    else if t.k > srs_size then
      fail
        (`Fail
          (Format.asprintf
             "SRS size is too small. Expected more than %d. Got %d"
             t.k
             srs_size))
    else if not (is_pow_of_two t.number_of_shards && t.n > t.number_of_shards)
    then invalid_arg "Shards not containing at least two elements"
      (* Shards must contain at least two elements. *)
    else return t

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

  let _make_fft_configuration redundancy_factor domain_size =
    let fft_domain_size, domains = select_fft_domain domain_size in
    (*let primitive_root =
        get_primitive_root (redundancy_factor * fft_domain_size)
      in
      let is_pow_of_two x =
        let logx = Z.(log2 (of_int x)) in
        1 lsl logx = x
      in
      let make_domains domains =
        List.fold_left
          (fun map d ->
            let d = if is_pow_of_two d then redundancy_factor * d else d in
            let rt = Scalar.pow primitive_root (Z.of_int (fft_domain_size / d)) in
            IntMap.add d (make_domain2 rt d) map)
          IntMap.empty
          domains
      in*)
    {
      buffer = Scalar_array.allocate (redundancy_factor * fft_domain_size);
      domain_k = (fft_domain_size, domains (*domains = make_domains domains;*));
    }

  external dft_c :
    scalar_array -> bool -> int -> scalar_array -> scalar_array -> unit
    = "dft_c"

  let dft_c ~domain ~inverse ~length ~coefficients =
    let res = Scalar_array.allocate length in
    dft_c domain inverse length coefficients (Scalar_array.allocate length) ;
    res

  let fft t ~coefficients ~domains ~inverse =
    (* For now *)
    assert (List.length domains <= 2) ;
    let len = Scalar_array.length coefficients in
    let primroot = Scalar_array.get t.domain_n 1 in
    let is_pow_of_two x =
      let logx = Z.(log2 (of_int x)) in
      1 lsl logx = x
    in
    match domains with
    | [d] ->
        let domain =
          if inverse then
            make_domain2
              (Scalar.inverse_exn (Scalar.pow primroot (Z.of_int (t.n / d))))
          else make_domain2 (Scalar.pow primroot (Z.of_int (t.n / d)))
        in
        dft_c ~domain:(domain d) ~inverse ~coefficients ~length:d
    | [domain1_length; domain2_length]
      when Z.(gcd (of_int domain1_length) (of_int domain2_length) = one)
           && is_pow_of_two domain1_length ->
        let domain1, domain2 =
          if inverse then
            ( make_domain2
                (Scalar.inverse_exn
                   (Scalar.pow primroot (Z.of_int (t.n / len * domain2_length)))),
              make_domain2
                (Scalar.inverse_exn
                   (Scalar.pow primroot (Z.of_int (t.n / len * domain1_length))))
            )
          else
            ( make_domain2
                (Scalar.pow primroot (Z.of_int (t.n / len * domain2_length))),
              make_domain2
                (Scalar.pow primroot (Z.of_int (t.n / len * domain1_length))) )
        in
        let domain1_length_log = Z.(log2 (of_int domain1_length)) in
        prime_factor_algorithm_fft
          ~domain1:(domain1 domain1_length)
          ~domain2:(domain2 domain2_length)
          ~domain1_length_log
          ~domain2_length
          ~scratch_zone:t.scratch_zone
          ~coefficients
          ~inverse
    | [domain1_length; domain2_length]
      when Z.(gcd (of_int domain1_length) (of_int domain2_length) = one) ->
        let domain1, domain2 =
          if inverse then
            ( make_domain2
                (Scalar.inverse_exn
                   (Scalar.pow primroot (Z.of_int (t.n / len * domain2_length)))),
              make_domain2
                (Scalar.inverse_exn
                   (Scalar.pow primroot (Z.of_int (t.n / len * domain1_length))))
            )
          else
            ( make_domain2
                (Scalar.pow primroot (Z.of_int (t.n / len * domain2_length))),
              make_domain2
                (Scalar.pow primroot (Z.of_int (t.n / len * domain1_length))) )
        in
        prime_factor_algorithm_fft2
          ~domain1:(domain1 domain1_length)
          ~domain2:(domain2 domain2_length)
          ~domain1_length
          ~domain2_length
          ~scratch_zone:t.scratch_zone
          ~inverse
          ~coefficients
    | _ -> assert false

  let evaluation_fft_n t coefficients =
    let _, domains = select_fft_domain t.n in
    fft t ~coefficients ~domains ~inverse:false

  let interpolation_fft_n t coefficients =
    let _, domains = select_fft_domain t.n in
    fft t ~coefficients ~domains ~inverse:true

  let evaluation_fft_k t coefficients =
    let _, domains = select_fft_domain t.k in
    fft t ~coefficients ~domains ~inverse:false

  let interpolation_fft_k t coefficients =
    let _, domains = select_fft_domain t.k in
    fft t ~coefficients ~domains ~inverse:true

  let evaluation_fft_2k t coefficients =
    let _, domains = select_fft_domain (2 * t.k) in
    fft t ~coefficients ~domains ~inverse:false

  let interpolation_fft_2k t coefficients =
    let _, domains = select_fft_domain (2 * t.k) in
    fft t ~coefficients ~domains ~inverse:true

  let _resize' s p ps =
    let res = Scalar_array.allocate s in
    Scalar_array.blit p ~src_off:0 res ~dst_off:0 ~len:ps ;
    res

  let slot_as_polynomial_length ~slot_size ~segment_size =
    let segment_length = Int.div segment_size scalar_bytes_amount + 1 in
    let segment_length_domain, _ = select_fft_domain segment_length in
    slot_size / segment_size * segment_length_domain

  type parameters = {
    redundancy_factor : int;
    segment_size : int;
    slot_size : int;
    number_of_shards : int;
  }

  (* Error cases of this functions are not encapsulated into
     `tzresult` for modularity reasons. *)
  let make {redundancy_factor; slot_size; segment_size; number_of_shards} =
    let open Result_syntax in
    let segment_length = Int.div segment_size scalar_bytes_amount + 1 in
    let segment_length_domain, _ = select_fft_domain segment_length in

    let mul = slot_size / segment_size in
    let k = mul * segment_length_domain in
    let n = redundancy_factor * k in
    let shard_size = n / number_of_shards in

    let rt_n = get_primitive_root n in
    let rt_k = Scalar.pow rt_n (Z.of_int redundancy_factor) in
    let rt_2k = Scalar.pow rt_n (Z.of_int (redundancy_factor / 2)) in
    let* srs =
      match !initialisation_parameters with
      | None -> fail (`Fail "Dal_cryptobox.make: DAL was not initialisated.")
      | Some raw ->
          return
            {
              raw;
              kate_amortized_srs_g2_shards = Srs_g2.get raw.srs_g2 shard_size;
              kate_amortized_srs_g2_segments =
                Srs_g2.get raw.srs_g2 segment_length_domain;
            }
    in
    let t =
      {
        redundancy_factor;
        slot_size;
        segment_size;
        number_of_shards;
        k;
        n;
        domain_k = make_domain2 rt_k k;
        domain_2k = make_domain2 rt_2k (2 * k);
        domain_n = make_domain2 rt_n n;
        scratch_zone = Scalar_array.allocate (2 * n);
        shard_size;
        nb_segments = slot_size / segment_size;
        segment_length;
        segment_length_domain;
        remaining_bytes = segment_size mod scalar_bytes_amount;
        srs;
        fft_configuration = _make_fft_configuration redundancy_factor k;
      }
    in
    ensure_validity t

  let polynomial_degree = Polynomials.degree

  let polynomial_evaluate = Polynomials.evaluate

  let resize s p ps =
    let res = Array.init s (fun _ -> Scalar.(copy zero)) in
    Array.blit p 0 res 0 ps ;
    res

  (* We encode by segments of [segment_size] bytes each.  The segments
     are arranged in cosets to evaluate in batch with Kate
     amortized. *)
  let polynomial_from_bytes' (t : t) slot =
    if Bytes.length slot <> t.slot_size then
      Error
        (`Slot_wrong_size
          (Printf.sprintf "message must be %d bytes long" t.slot_size))
    else
      let offset = ref 0 in
      let res = Array.init t.k (fun _ -> Scalar.(copy zero)) in
      for segment = 0 to t.nb_segments - 1 do
        for elt = 0 to t.segment_length - 1 do
          if !offset > t.slot_size then ()
          else if elt = t.segment_length - 1 then (
            let dst = Bytes.create t.remaining_bytes in
            Bytes.blit slot !offset dst 0 t.remaining_bytes ;
            offset := !offset + t.remaining_bytes ;
            res.((elt * t.nb_segments) + segment) <- Scalar.of_bytes_exn dst)
          else
            let dst = Bytes.create scalar_bytes_amount in
            Bytes.blit slot !offset dst 0 scalar_bytes_amount ;
            offset := !offset + scalar_bytes_amount ;
            res.((elt * t.nb_segments) + segment) <- Scalar.of_bytes_exn dst
        done
      done ;
      Ok res

  let polynomial_from_slot t slot =
    let open Result_syntax in
    let* data = polynomial_from_bytes' t slot in
    Ok
      (Polynomials.of_carray
         (interpolation_fft_k t (Scalar_array.of_array data)))

  let eval_coset t eval slot offset segment =
    for elt = 0 to t.segment_length - 1 do
      let idx = (elt * t.nb_segments) + segment in
      let coeff = Scalar.to_bytes (Array.get eval idx) in
      if elt = t.segment_length - 1 then (
        Bytes.blit coeff 0 slot !offset t.remaining_bytes ;
        offset := !offset + t.remaining_bytes)
      else (
        Bytes.blit coeff 0 slot !offset scalar_bytes_amount ;
        offset := !offset + scalar_bytes_amount)
    done

  (* The segments are arranged in cosets to evaluate in batch with Kate
     amortized. *)
  let polynomial_to_bytes t p =
    (* We copy the polynomial p so that the function doesn't modify it *)
    let coefficients = Polynomials.(to_carray (copy p)) in
    let eval = evaluation_fft_k t coefficients |> Scalar_array.to_array in
    let slot = Bytes.init t.slot_size (fun _ -> '0') in
    let offset = ref 0 in
    for segment = 0 to t.nb_segments - 1 do
      eval_coset t eval slot offset segment
    done ;
    slot

  let encode t p =
    evaluation_fft_n t (_resize' t.n Polynomials.(to_carray p) t.k)

  (* The shards are arranged in cosets to evaluate in batch with Kate
     amortized. *)
  let shards_from_polynomial t p =
    let codeword = encode t p in
    let rec loop i map =
      if i = t.number_of_shards then map
      else
        let shard = Array.init t.shard_size (fun _ -> Scalar.(copy zero)) in
        for j = 0 to t.shard_size - 1 do
          shard.(j) <- Scalar_array.get codeword ((t.number_of_shards * j) + i)
        done ;
        loop (i + 1) (IntMap.add i shard map)
    in
    loop 0 IntMap.empty

  (* Computes the polynomial N(X) := \sum_{i=0}^{k-1} n_i x_i^{-1} X^{z_i}. *)
  let compute_n t (eval_a' : scalar array) shards =
    let w = Scalar_array.get t.domain_n 1 in
    let n_poly = Scalar_array.allocate t.n in
    let open Result_syntax in
    let c = ref 0 in
    let* () =
      IntMap.iter_e
        (fun z_i arr ->
          if !c >= t.k then Ok ()
          else
            let rec loop j =
              match j with
              | j when j = Array.length arr -> Ok ()
              | _ -> (
                  let c_i = arr.(j) in
                  let z_i = (t.number_of_shards * j) + z_i in
                  let x_i = Scalar.pow w (Z.of_int z_i) in
                  let tmp = Array.get eval_a' z_i in
                  Scalar.mul_inplace tmp tmp x_i ;
                  match Scalar.inverse_exn_inplace tmp tmp with
                  | exception _ -> Error (`Invert_zero "can't inverse element")
                  | () ->
                      Scalar.mul_inplace tmp tmp c_i ;
                      Scalar_array.set n_poly tmp z_i ;
                      c := !c + 1 ;
                      loop (j + 1))
            in
            loop 0)
        shards
    in
    Ok n_poly

  let fft_mul2k_2 t a b =
    let a = resize (2 * t.k) a (Array.length a) in
    let b = resize (2 * t.k) b (Array.length b) in
    let eval_a = evaluation_fft_2k t (Scalar_array.of_array a) in
    let eval_b = evaluation_fft_2k t (Scalar_array.of_array b) in
    for i = 0 to (2 * t.k) - 1 do
      Scalar_array.set
        eval_a
        (Scalar.mul (Scalar_array.get eval_a i) (Scalar_array.get eval_b i))
        i
    done ;
    let res = interpolation_fft_2k t eval_a in
    Scalar_array.copy res

  let polynomial_from_shards t shards =
    let open Result_syntax in
    if t.k > IntMap.cardinal shards * t.shard_size then
      Error
        (`Not_enough_shards
          (Printf.sprintf
             "there must be at least %d shards to decode"
             (t.k / t.shard_size)))
    else
      (* 1. Computing A(x) = prod_{i=0}^{k-1} (x - w^{z_i}).
         Let w be a primitive nth root of unity and
         Ω_0 = {w^{number_of_shards j}}_{j=0 to (n/number_of_shards)-1}
         be the (n/number_of_shards)-th roots of unity and Ω_i = w^i Ω_0.

         Together, the Ω_i's form a partition of the subgroup of the n-th roots
         of unity: 𝕌_n = disjoint union_{i ∈ {0, ..., number_of_shards-1}} Ω_i.

         Let Z_j := Prod_{w ∈ Ω_j} (x − w). For a random set of shards
         S⊆{0, ..., number_of_shards-1} of length k/shard_size, we reorganize the
         product A(x) = Prod_{i=0}^{k-1} (x − w^{z_i}) into
         A(x) = Prod_{j ∈ S} Z_j.

         Moreover, Z_0 = x^|Ω_0| - 1 since x^|Ω_0| - 1 contains all roots of Z_0
         and conversely. Multiplying each term of the polynomial by the root w^j
         entails Z_j = x^|Ω_0| − w^{j*|Ω_0|}.

         The intermediate products Z_j have a lower Hamming weight (=2) than
         when using other ways of grouping the z_i's into shards.

         This also reduces the depth of the recursion tree of the poly_mul
         function from log(k) to log(number_of_shards), so that the decoding time
         reduces from O(k*log^2(k) + n*log(n)) to O(n*log(n)). *)
      let split = List.fold_left (fun (l, r) x -> (x :: r, l)) ([], []) in
      let f1, f2 =
        IntMap.bindings shards
        (* We always consider the first k codeword vector components. *)
        |> Tezos_stdlib.TzList.take_n (t.k / t.shard_size)
        |> split
      in

      let prod =
        List.fold_left
          (fun acc (i, _) ->
            Polynomials.mul_xn
              acc
              t.shard_size
              (Scalar.negate (Scalar_array.get t.domain_n (i * t.shard_size))))
          (Polynomials.of_dense [|Scalar.(copy one)|])
      in

      let p1 = prod f1 |> Polynomials.to_dense_coefficients in
      let p2 = prod f2 |> Polynomials.to_dense_coefficients in

      let a_poly = fft_mul2k_2 t p1 p2 |> Polynomials.of_carray in

      (* 2. Computing formal derivative of A(x). *)
      let a' = Polynomials.derivative a_poly in

      (* 3. Computing A'(w^i) = A_i(w^i). *)
      let a' = Polynomials.to_dense_coefficients a' in
      let eval_a' =
        evaluation_fft_n
          t
          (resize t.n a' (Array.length a') |> Scalar_array.of_array)
        |> Scalar_array.to_array
      in

      (* 4. Computing N(x). *)
      let* n_poly = compute_n t eval_a' shards in

      (* 5. Computing B(x). *)
      let b = interpolation_fft_n t n_poly |> Polynomials.of_carray in

      let b = Polynomials.copy ~len:t.k b in
      Polynomials.mul_by_scalar_inplace b (Scalar.of_int t.n) b ;

      (* 6. Computing Lagrange interpolation polynomial P(x). *)
      let p =
        fft_mul2k_2
          t
          (Polynomials.to_dense_coefficients a_poly)
          (Polynomials.to_dense_coefficients b)
        |> Polynomials.of_carray |> Polynomials.copy ~len:t.k
      in

      Polynomials.opposite_inplace p ;
      Ok p

  let commit t p = Srs_g1.pippenger t.srs.raw.srs_g1 p

  (* p(X) of degree n. Max degree that can be committed: d, which is also the
     SRS's length - 1. We take d = k - 1 since we don't want to commit
     polynomials with degree greater than polynomials to be erasure-encoded.

     We consider the bilinear groups (G_1, G_2, G_T) with G_1=<g> and G_2=<h>.
     - Commit (p X^{d-n}) such that deg (p X^{d-n}) = d the max degree
     that can be committed
     - Verify: checks if e(commit(p), commit(X^{d-n})) = e(commit(p X^{d-n}), h)
     using the commitments for p and p X^{d-n}, and computing the commitment for
     X^{d-n} on G_2.*)

  let prove_commitment t p =
    commit t Polynomials.(mul (of_coefficients [(Scalar.(copy one), 0)]) p)

  (* FIXME https://gitlab.com/tezos/tezos/-/issues/3389

     Generalize this function to pass the degree in parameter. *)
  let verify_commitment t cm proof =
    let open Bls12_381 in
    let check =
      match Srs_g2.get t.srs.raw.srs_g2 0 with
      | exception Invalid_argument _ -> false
      | commit_xk ->
          Pairing.pairing_check
            [(cm, commit_xk); (proof, G2.(negate (copy one)))]
    in
    check

  let inverse domain =
    let n = Array.length domain in
    Array.init n (fun i ->
        if i = 0 then Bls12_381.Fr.(copy one) else Array.get domain (n - i))

  let diff_next_power_of_two x =
    let logx = Z.log2 (Z.of_int x) in
    if 1 lsl logx = x then 0 else (1 lsl (logx + 1)) - x

  let _is_pow_of_two x =
    let logx = Z.log2 (Z.of_int x) in
    1 lsl logx = x

  (* Implementation of fast amortized Kate proofs
     https://github.com/khovratovich/Kate/blob/master/Kate_amortized.pdf). *)

  (* Precompute first part of Toeplitz trick, which doesn't depends on the
     polynomial’s coefficients. *)
  let preprocess_multi_reveals ~shard_size ~degree srs =
    let open Bls12_381 in
    let l = shard_size in
    let k =
      let ratio = degree / l in
      let log_inf = Z.log2 (Z.of_int ratio) in
      if 1 lsl log_inf < ratio then log_inf else log_inf + 1
    in
    let domain = Domains.build ~log:k |> Domains.inverse |> inverse in
    let precompute_srsj j =
      let quotient = (degree - j) / l in
      let padding = diff_next_power_of_two (2 * quotient) in
      let points =
        Array.init
          ((2 * quotient) + padding)
          (fun i ->
            if i < quotient then
              G1.copy (Srs_g1.get srs (degree - j - ((i + 1) * l)))
            else G1.(copy zero))
      in
      G1.fft_inplace ~domain ~points ;
      points
    in
    (domain, Array.init l precompute_srsj)

  (** Generate proofs of part 3.2.
  n, r are powers of two, m = 2^(log2(n)-1)
  coefs are f polynomial’s coefficients [f₀, f₁, f₂, …, fm-1]
  domain2m is the set of 2m-th roots of unity, used for Toeplitz computation
  (domain2m, precomputed_srs_part) = preprocess_multi_reveals r n m srs1
   *)
  let multiple_multi_reveals ~chunk_len ~chunk_count ~degree
      ~preprocess:(domain2m, precomputed_srs_part) coefs =
    let open Bls12_381 in
    (* TODO : restore checks *)
    (*let n = chunk_len + chunk_count in
      assert (2 <= chunk_len) ;
      assert (chunk_len < n) ;
      (*assert (is_pow_of_two degree) ;*)
      assert (chunk_len < degree) ;*)
    let l = chunk_len in
    Printf.eprintf
      "\n len coeffs = %d ; deg=%d; l =%d ; 2k/l=%d\n"
      (Array.length coefs)
      degree
      l
      (2 * degree / l) ;
    (* We don’t need the first coefficient f₀. *)
    let compute_h_j j =
      let rest = (degree - j) mod l in
      let quotient = (degree - j) / l in
      (* Padding in case quotient is not a power of 2 to get proper fft in
         Toeplitz matrix part. *)
      let padding = diff_next_power_of_two (2 * quotient) in
      (* fm, 0, …, 0, f₁, f₂, …, fm-1 *)
      let points =
        Array.init
          ((2 * quotient) + padding)
          (fun i ->
            if i <= quotient + (padding / 2) then Scalar.(copy zero)
            else
              let j = rest + ((i - (quotient + padding)) * l) in
              if j < Array.length coefs then Scalar.copy coefs.(j)
              else Scalar.(copy zero))
      in
      if j <> 0 && degree - j < Array.length coefs then
        points.(0) <- Scalar.copy coefs.(degree - j) ;
      Scalar.fft_inplace ~domain:domain2m ~points ;
      Array.map2 G1.mul precomputed_srs_part.(j) points
    in
    let sum = compute_h_j 0 in
    let rec sum_hj j =
      if j = l then ()
      else
        let hj = compute_h_j j in
        (* sum.(i) <- sum.(i) + hj.(i) *)
        Array.iteri (fun i hij -> sum.(i) <- G1.add sum.(i) hij) hj ;
        sum_hj (j + 1)
    in
    sum_hj 1 ;

    (* Toeplitz matrix-vector multiplication *)
    G1.ifft_inplace ~domain:(inverse domain2m) ~points:sum ;
    let hl = Array.sub sum 0 (Array.length domain2m / 2) in

    let phidomain = Domains.build ~log:chunk_count in
    let phidomain = inverse (Domains.inverse phidomain) in
    (* Kate amortized FFT *)
    G1.fft ~domain:phidomain ~points:hl

  (* h = polynomial such that h(y×domain[i]) = zi. *)
  let interpolation_h_poly y domain z_list =
    Scalar.ifft_inplace ~domain:(Domains.inverse domain) ~points:z_list ;
    let inv_y = Scalar.inverse_exn y in
    Array.fold_left_map
      (fun inv_yi h -> Scalar.(mul inv_yi inv_y, mul h inv_yi))
      Scalar.(copy one)
      z_list
    |> snd |> Polynomials.of_dense

  (* Part 3.2 verifier : verifies that f(w×domain.(i)) = evaluations.(i). *)
  let _verify t cm_f srs_point domain (w, evaluations) proof =
    let open Bls12_381 in
    let h = interpolation_h_poly w domain evaluations in
    let cm_h = commit t h in
    let l = Domains.length domain in
    let sl_min_yl =
      G2.(add srs_point (negate (mul (copy one) (Scalar.pow w (Z.of_int l)))))
    in
    let diff_commits = G1.(add cm_h (negate cm_f)) in
    Pairing.pairing_check [(diff_commits, G2.(copy one)); (proof, sl_min_yl)]

  let interpolation_h_poly t y domains coefficients =
    let h = fft t ~coefficients ~domains ~inverse:true in
    let inv_y = Scalar.inverse_exn y in
    Array.fold_left_map
      (fun inv_yi h -> Scalar.(mul inv_yi inv_y, mul h inv_yi))
      Scalar.(copy one)
      (Scalar_array.to_array h)
    |> snd

  let verify t cm_f srs2l (w, evaluations) domains l proof =
    let open Bls12_381 in
    let h = interpolation_h_poly t w domains evaluations in
    let cm_h = commit t (Polynomials.of_dense h) in
    let sl_min_yl =
      G2.(add srs2l (negate (mul (copy one) (Scalar.pow w (Z.of_int l)))))
    in
    let diff_commits = G1.(add cm_h (negate cm_f)) in
    Pairing.pairing_check [(diff_commits, G2.(copy one)); (proof, sl_min_yl)]

  let precompute_shards_proofs t =
    preprocess_multi_reveals
      ~shard_size:t.shard_size
      ~degree:t.k
      t.srs.raw.srs_g1

  let _save_precompute_shards_proofs (preprocess : shards_proofs_precomputation)
      filename =
    let chan = Out_channel.open_bin filename in
    Out_channel.output_bytes
      chan
      (Data_encoding.Binary.to_bytes_exn
         Encoding.shards_proofs_precomputation_encoding
         preprocess) ;
    Out_channel.close_noerr chan

  let _load_precompute_shards_proofs filename =
    let chan = In_channel.open_bin filename in
    let len = Int64.to_int (In_channel.length chan) in
    let data = Bytes.create len in
    let (_ : unit option) = In_channel.really_input chan data 0 len in
    let precomp =
      Data_encoding.Binary.of_bytes_exn
        Encoding.shards_proofs_precomputation_encoding
        data
    in
    In_channel.close_noerr chan ;
    precomp

  let prove_shards t p =
    let preprocess = precompute_shards_proofs t in
    let t' = Sys.time () in
    let res =
      multiple_multi_reveals
        ~chunk_len:t.shard_size
        ~chunk_count:Z.(log2 (of_int t.number_of_shards))
        ~degree:t.k
        ~preprocess
        (Polynomials.to_dense_coefficients p)
    in
    Printf.eprintf "\n prove_shards reveal = %f\n" (Sys.time () -. t') ;
    res

  let verify_shard t cm {index = shard_index; share = shard_evaluations} proof =
    let generator_domain_n = Scalar_array.get t.domain_n 1 in
    let power_coset = Scalar.pow generator_domain_n (Z.of_int shard_index) in
    verify
      t
      cm
      t.srs.kate_amortized_srs_g2_shards
      (power_coset, Scalar_array.of_array shard_evaluations)
      (snd (select_fft_domain t.shard_size))
      t.shard_size
      proof

  let _prove_single t p z =
    let q, _ =
      Polynomials.(
        division_xn (p - constant (evaluate p z)) 1 (Scalar.negate z))
    in
    commit t q

  let _verify_single t cm ~point ~evaluation proof =
    let h_secret = Srs_g2.get t.srs.raw.srs_g2 1 in
    Bls12_381.(
      Pairing.pairing_check
        [
          ( G1.(add cm (negate (mul (copy one) evaluation))),
            G2.(negate (copy one)) );
          (proof, G2.(add h_secret (negate (mul (copy one) point))));
        ])

  let prove_segment t p segment_index =
    if segment_index < 0 || segment_index >= t.nb_segments then
      Error `Segment_index_out_of_range
    else
      let l = t.segment_length_domain in
      let generator_domain_k = Scalar_array.get t.domain_k 1 in
      let power = Scalar.pow generator_domain_k (Z.of_int segment_index) in
      let quotient, _ =
        Polynomials.(division_xn p l Scalar.(negate (pow power (Z.of_int l))))
      in
      Ok (commit t quotient)

  (* Parses the [slot_segment] to get the evaluations that it contains. The
     evaluation points are given by the [slot_segment_index]. *)
  let verify_segment t cm {index = slot_segment_index; content = slot_segment}
      proof =
    if slot_segment_index < 0 || slot_segment_index >= t.nb_segments then
      Error `Segment_index_out_of_range
    else
      let coset_size = t.segment_length_domain in
      let generator_domain_k = Scalar_array.get t.domain_k 1 in
      let power = Scalar.pow generator_domain_k (Z.of_int slot_segment_index) in
      let slot_segment_evaluations =
        Array.init coset_size (function
            | i when i < t.segment_length - 1 ->
                let dst = Bytes.create scalar_bytes_amount in
                Bytes.blit
                  slot_segment
                  (i * scalar_bytes_amount)
                  dst
                  0
                  scalar_bytes_amount ;
                Scalar.of_bytes_exn dst
            | i when i = t.segment_length - 1 ->
                let dst = Bytes.create t.remaining_bytes in
                Bytes.blit
                  slot_segment
                  (i * scalar_bytes_amount)
                  dst
                  0
                  t.remaining_bytes ;
                Scalar.of_bytes_exn dst
            | _ -> Scalar.(copy zero))
      in
      Ok
        (verify
           t
           cm
           t.srs.kate_amortized_srs_g2_segments
           (power, Scalar_array.of_array slot_segment_evaluations)
           (snd (select_fft_domain t.segment_length_domain))
           t.segment_length_domain
           proof)
end

include Inner
module Verifier = Inner

module Internal_for_tests = struct
  let initialisation_parameters_from_slot_size ~slot_size ~segment_size =
    let size = slot_as_polynomial_length ~slot_size ~segment_size in
    let secret =
      Bls12_381.Fr.of_string
        "20812168509434597367146703229805575690060615791308155437936410982393987532344"
    in
    let srs_g1 = Srs_g1.generate_insecure size secret in
    let srs_g2 = Srs_g2.generate_insecure size secret in
    {srs_g1; srs_g2}

  let load_parameters parameters = initialisation_parameters := Some parameters
end
