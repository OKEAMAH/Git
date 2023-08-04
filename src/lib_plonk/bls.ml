module Scalar = Plompiler.Csir.Scalar
module Scalar_map = Map.Make (Scalar)
module Domain = Domain
module Poly = Polynomial
module Pairing = Bls12_381.Pairing
module Srs_g1 = Srs.Srs_g1
module Srs_g2 = Srs.Srs_g2
module G1_carray = G1_carray

(* Module to operate with polynomials in FFT evaluations form. *)
module Evaluations = Evaluations_map.Make (Evaluations)

module G1 = struct
  include Bls12_381.G1

  let t : t Repr.t =
    Repr.(map bytes of_compressed_bytes_exn to_compressed_bytes)
end

module G2 = struct
  include Bls12_381.G2

  let t : t Repr.t =
    Repr.(
      map
        (bytes_of (`Fixed (size_in_bytes / 2)))
        of_compressed_bytes_exn
        to_compressed_bytes)
end

module GT = struct
  include Bls12_381.GT

  let t : t Repr.t =
    Repr.(map (bytes_of (`Fixed size_in_bytes)) of_bytes_exn to_bytes)
end

let to_encoding repr =
  let of_bytes repr bs =
    Stdlib.Result.get_ok
    @@ Repr.(unstage @@ of_bin_string repr) (Bytes.unsafe_to_string bs)
  in
  let to_bytes repr e =
    Bytes.unsafe_of_string @@ Repr.(unstage @@ to_bin_string repr) e
  in
  let data_encoding_of_repr repr =
    conv (to_bytes repr) (of_bytes repr) Data_encoding.bytes
  in
  data_encoding_of_repr repr
