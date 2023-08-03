open Bls

type public_parameters = {
  max_polynomial_length : int;
  shard_length : int;
  srs_g1 : Srs_g1.t;
  number_of_shards : int;
}

type preprocess

val preprocess_encoding : preprocess t

type commitment = G1.t

type shard_proof = G1.t

val preprocess_equal : preprocess -> preprocess -> bool

val commit : public_parameters -> Poly.t -> commitment

val preprocess_multiple_multi_reveals : public_parameters -> preprocess

val multiple_multi_reveals :
  public_parameters ->
  preprocess:preprocess ->
  coefficients:scalar array ->
  shard_proof array

val verify :
  public_parameters ->
  commitment:commitment ->
  srs_point:G2.t ->
  domain:Domain.t ->
  root:scalar ->
  evaluations:scalar array ->
  proof:shard_proof ->
  bool
