open Bls

module type Commitment = sig
  type t [@@deriving repr]

  type prover_aux [@@deriving repr]

  type public_parameters

  type secret = Poly.t SMap.t

  val commit_single : public_parameters -> Poly.t -> G1.t

  (* [all_keys] is an optional argument that should only be used for
     partial commitments. It contains all the polynomial names that
     make up the full commitment.
     For instance, if the full commitment contains polynomials "a", "b", "c" &
     "d", then all keys will contain ["a", "b", "c", "d"]
     Note that [secret] may only contain a subset of [all_keys] (for instance,
     {"a", "b"}).
  *)
  val commit :
    ?all_keys:string list -> public_parameters -> secret -> t * prover_aux

  val cardinal : t -> int

  val rename : (string -> string) -> t -> t

  val recombine : t list -> t

  val recombine_prover_aux : prover_aux list -> prover_aux

  val empty : t

  val empty_prover_aux : prover_aux

  val of_list : public_parameters -> name:string -> G1.t list -> t * prover_aux

  val to_map : t -> G1.t SMap.t
end

module type Public_parameters = sig
  type prover [@@deriving repr]

  type verifier [@@deriving repr]

  type commitment

  type setup_params = int

  val setup : setup_params -> Srs.t * Srs.t -> prover * verifier

  val to_bytes : int -> prover -> Bytes.t

  val get_commit_parameters : prover -> commitment
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
    Public_parameters with type commitment = Commitment.public_parameters

  val commit :
    ?all_keys:string list ->
    Public_parameters.prover ->
    secret ->
    Commitment.t * Commitment.prover_aux

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

module type DegreeCheck_proof = sig
  type t [@@deriving repr]

  val zero : t

  val alter_proof : t -> t

  val encoding : t encoding
end

module type DegreeCheck = sig
  module Proof : DegreeCheck_proof

  module Commitment : Commitment

  type prover_public_parameters = Commitment.public_parameters

  type verifier_public_parameters = {srs_0 : G2.t; srs_n_d : G2.t}

  type secret = Poly.t SMap.t

  val prove :
    max_commit:int ->
    max_degree:int ->
    prover_public_parameters ->
    bytes ->
    secret ->
    Proof.t * bytes

  val verify :
    verifier_public_parameters ->
    bytes ->
    Commitment.t ->
    Proof.t ->
    bool * bytes
end

module type Commitment_for_Dal = sig
  exception SRS_too_short of string

  type t [@@deriving repr]

  type public_parameters = Srs_g1.t

  type secret = Poly.t

  val encoding : t encoding

  val zero : t

  val equal : t -> t -> bool

  val compare : t -> t -> int

  val commit : public_parameters -> secret -> t

  (** [to_b58check commitment] returns a b58 representation
        of [commitment]. *)
  val to_b58check : t -> string

  (** [of_b58check_opt bytes] computes a commitment from
              its b58 representation. Returns [None] if it is not a valid
              representation. *)
  val of_b58check_opt : string -> t option

  val of_b58check : string -> t Tezos_error_monad.Error_monad.tzresult

  val pp : Format.formatter -> t -> unit

  val rpc_arg : t Resto.Arg.t
end

module type DegreeCheck_for_Dal = sig
  module Proof : DegreeCheck_proof

  module Commitment : Commitment_for_Dal

  type prover_public_parameters = Commitment.public_parameters

  type verifier_public_parameters = {srs_0 : G2.t; srs_n_d : G2.t}

  type secret = Commitment.secret

  type commitment = Commitment.t

  val prove :
    max_commit:int ->
    max_degree:int ->
    prover_public_parameters ->
    secret ->
    Proof.t

  val verify : verifier_public_parameters -> commitment -> Proof.t -> bool
end
