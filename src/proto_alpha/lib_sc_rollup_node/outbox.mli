(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2023 TriliTech, <contact@trili.tech>                        *)
(*                                                                           *)
(*****************************************************************************)

(** This module provides helper to interact with PVM outboxes. *)

open Protocol.Alpha_context

(** [proof_of_output node_ctxt output] returns the last cemented commitment hash
    and the proof of the output in the LCC. *)
val proof_of_output :
  Irmin_context.repo Node_context_types.rw ->
  Sc_rollup.output ->
  (Octez_smart_rollup.Commitment.Hash.t * string) tzresult Lwt.t

(** [proof_of_output_simple node_ctxt ~level ~message_index] returns the last
    cemented commitment hash and the proof of the output in the LCC. *)
val proof_of_output_simple :
  Irmin_context.repo Node_context_types.rw ->
  outbox_level:Raw_level.t ->
  message_index:int ->
  (Octez_smart_rollup.Commitment.Hash.t * string) tzresult Lwt.t
