(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022-2023 TriliTech <contact@trili.tech>                    *)
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

open Protocol
open Alpha_context
open Kernel_durable

(** This module simulates sequence of the messages
    in which they will be eventually supplied to the sequencer kernel.
    It's doing so by replicating the exact same order
    defined in the seq_batcher, basically reacting to the two types of events:
    - new finalized block added to the simulation
    - user messages injected through sequencer RPC added to the simulation

    Currently, the simulation works in a quadratic way,
    resimulating all the sequence of the messages when new messages arrives.
    It will be fixed when this https://gitlab.com/tezos/tezos/-/issues/6020 task is done.
*)

(** Provides capability to encode well formed sequence,
    which will be supplied to the simulation PVM *)
module type Messages_encoder = sig
  type signer_ctxt

  val encode_sequence :
    signer_ctxt ->
    nonce:int32 ->
    prefix:int32 ->
    suffix:int32 ->
    Sc_rollup.Inbox_message.serialized list ->
    string tzresult Lwt.t
end

type t = {
  current_block_diff : Delayed_inbox.Pointer.t;
      (** The range of the delayed inbox queue,
          which have been added to the delayed inbox by the current block.
          Head of this pointer corresponds to the head of the queue.
        *)
  inbox_level : int32;
      (** Current inbox level, incremented when a new block arrives *)
  ctxt : Context.ro;
  state : Context.tree;
      (** State of the PVM corresponding to all [accumulated_messages] @@ EoL *)
  tot_messages_consumed : int;
      (** How many messages have been fed to the user kernel by the sequencer kernel *)
  accumulated_messages : Sc_rollup.Inbox_message.serialized list;
      (** All the messages, which have to be fed to the sequencer kernel since the last block.
          Workaround causing quadratic complexity of the simulation, will be removed when
          https://gitlab.com/tezos/tezos/-/issues/6020 is done *)
  block_beginning : Context.tree;
      (** State of the PVM corresponding to the previous block.
          Will be removed when https://gitlab.com/tezos/tezos/-/issues/6020 is done *)
}

module type S = sig
  type signer_ctxt

  (** Init simulation context with the first block, having level genesis + 1. *)
  val init_ctxt :
    signer_ctxt ->
    Node_context.ro ->
    Delayed_inbox.queue_slice ->
    t tzresult Lwt.t

  (** New block arrives, adding a difference to the delayed inbox. *)
  val new_block :
    signer_ctxt ->
    Node_context.ro ->
    t ->
    Delayed_inbox.queue_slice ->
    t tzresult Lwt.t

  (** Append more messages to the simulation. *)
  val append_messages :
    signer_ctxt ->
    Node_context.ro ->
    t ->
    Sc_rollup.Inbox_message.serialized list ->
    t tzresult Lwt.t
end

module Make (Enc : Messages_encoder) :
  S with type signer_ctxt := Enc.signer_ctxt
