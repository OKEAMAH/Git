open Bls

type public_parameters = {
  max_polynomial_length : int;
  shard_length : int;
  srs_g1 : Srs_g1.t;
  number_of_shards : int;
}

type preprocess

val preprocess_encoding : preprocess t

type shard_proof = G1.t

val preprocess_equal : preprocess -> preprocess -> bool

val commit : public_parameters -> Poly.t -> Commitment.Single.t

val interpolation_poly :
  root:scalar -> domain:Domain.t -> evaluations:scalar array -> Poly.t

val preprocess_multiple_multi_reveals : public_parameters -> preprocess

val multiple_multi_reveals :
  public_parameters ->
  preprocess:preprocess ->
  coefficients:scalar array ->
  shard_proof array

val verify_page :
  public_parameters ->
  commitment:Commitment.Single.t ->
  srs_point:G2.t ->
  domain:Domain.t ->
  root:scalar ->
  evaluations:scalar array ->
  proof:shard_proof ->
  bool

val verify_shard :
  commitment:Commitment.Single.t ->
  commitment_remainder:Commitment.Single.t ->
  srs_point:G2.t ->
  domain_length:int ->
  root:scalar ->
  proof:shard_proof ->
  pi_kzg:G1.t ->
  challenge_point:scalar ->
  batching_alpha:scalar ->
  eval:scalar ->
  x_g2:G2.t ->
  one_g1:G1.t ->
  one_g2:G2.t ->
  bool
