(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2023 Trilitech <contact@trili.tech>                         *)
(*                                                                           *)
(*****************************************************************************)

open Protocol
open Alpha_context
module Events = Baking_events.Actions
open Baking_state

module Operations_source : sig
  val retrieve :
    Baking_configuration.Operations_source.t option ->
    packed_operation trace option Lwt.t
end

val generate_seed_nonce_hash :
  Baking_configuration.nonce_config ->
  consensus_key ->
  Level.t ->
  (Nonce_hash.t * Nonce.t) option tzresult Lwt.t

val prepare_block : state -> block_to_bake -> prepared_block tzresult Lwt.t

val sign_consensus_votes :
  state ->
  (consensus_key_and_delegate * consensus_content) list ->
  [`Preattestation | `Attestation] ->
  ((consensus_key * public_key_hash) * packed_operation * int32 * Round.t) list
  tzresult
  Lwt.t
