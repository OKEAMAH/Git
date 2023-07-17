open Bls

module type Commitment = sig
  type t [@@deriving repr]

  type prover_aux [@@deriving repr]

  type prover_public_parameters

  type secret = Poly.t SMap.t

  val commit_single : prover_public_parameters -> Poly.t -> G1.t

  (* [all_keys] is an optional argument that should only be used for
     partial commitments. It contains all the polynomial names that
     make up the full commitment.
     For instance, if the full commitment contains polynomials "a", "b", "c" &
     "d", then all keys will contain ["a", "b", "c", "d"]
     Note that [secret] may only contain a subset of [all_keys] (for instance,
     {"a", "b"}).
  *)
  val commit :
    ?all_keys:string list ->
    prover_public_parameters ->
    secret ->
    t * prover_aux

  val cardinal : t -> int

  val rename : (string -> string) -> t -> t

  val recombine : t list -> t

  val recombine_prover_aux : prover_aux list -> prover_aux

  val empty : t

  val empty_prover_aux : prover_aux

  val of_list :
    prover_public_parameters -> name:string -> G1.t list -> t * prover_aux

  val to_map : t -> G1.t SMap.t
end

module type Public_parameters = sig
  type prover [@@deriving repr]

  type verifier [@@deriving repr]

  type setup_params = int

  val setup : setup_params -> Srs.t * Srs.t -> prover * verifier

  val to_bytes : int -> prover -> Bytes.t
end

module type Polynomial_commitment = sig
  (* polynomials to be committed *)
  type secret = Poly.t SMap.t

  (* maps evaluation point names to evaluation point values *)
  type query = Scalar.t SMap.t [@@deriving repr]

  (* maps evaluation point names to (map from polynomial names to evaluations) *)
  type answer = Scalar.t SMap.t SMap.t [@@deriving repr]

  type proof [@@deriving repr]

  type transcript = Bytes.t

  module Commitment : Commitment

  module Public_parameters :
    Public_parameters with type prover = Commitment.prover_public_parameters

  val evaluate : secret -> query -> answer

  val prove :
    Public_parameters.prover ->
    transcript ->
    secret list ->
    Commitment.prover_aux list ->
    query list ->
    answer list ->
    proof * transcript

  val verify :
    Public_parameters.verifier ->
    transcript ->
    Commitment.t list ->
    query list ->
    answer list ->
    proof ->
    bool * transcript
end
