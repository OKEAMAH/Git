(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2023 Trilitech <contact@trili.tech>                         *)
(*                                                                           *)
(*****************************************************************************)

open Protocol
open Alpha_context
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

val prepare_block :
  global_state -> block_to_bake -> prepared_block tzresult Lwt.t

val sign_dal_attestations :
  #Protocol_client_context.full ->
  Chain_id.t ->
  branch:Block_hash.t ->
  (consensus_key_and_delegate * Dal.Attestation.operation * int32) list ->
  (consensus_key_and_delegate
  * packed_operation
  * Dal.Attestation.operation
  * int32)
  list
  tzresult
  Lwt.t

val sign_attestations :
  #Protocol_client_context.full ->
  ?force:bool ->
  Chain_id.t ->
  branch:Block_hash.t ->
  (consensus_key_and_delegate * consensus_content) list ->
  ((consensus_key * public_key_hash) * packed_operation * int32 * Round.t) list
  tzresult
  Lwt.t

val sign_preattestations :
  #Protocol_client_context.full ->
  ?force:bool ->
  Chain_id.t ->
  branch:Block_hash.t ->
  (consensus_key_and_delegate * consensus_content) list ->
  ((consensus_key * public_key_hash) * packed_operation * int32 * Round.t) list
  tzresult
  Lwt.t

type worker

type t = worker

val push_request : worker -> forge_request -> unit

val get_event_stream : worker -> forge_event Lwt_stream.t

val shutdown : worker -> unit

val start : global_state -> worker tzresult Lwt.t
