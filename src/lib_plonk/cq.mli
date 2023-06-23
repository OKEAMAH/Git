open Bls

exception Entry_not_in_table

type prover_public_parameters

type verifier_public_parameters

type proof

val setup :
  Srs_g1.t * Srs_g2.t ->
  int ->
  S.t array ->
  prover_public_parameters * verifier_public_parameters

val prove : prover_public_parameters -> bytes -> S.t array -> proof * bytes

val verify : verifier_public_parameters -> bytes -> proof -> bool * bytes
