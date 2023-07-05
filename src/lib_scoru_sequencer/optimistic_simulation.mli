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
open Octez_smart_rollup_node_alpha
open Kernel_durable

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
  inbox_level : Raw_level.t;
  ctxt : Context.ro;
  state : Context.tree;
  (* nb_messages_inbox : int; *)
  tot_messages_consumed : int;
  accumulated_messages : Sc_rollup.Inbox_message.serialized list;
  block_beginning : Context.tree;
}

module type S = sig
  type signer_ctxt

  val init_ctxt :
    signer_ctxt ->
    Node_context.ro ->
    Delayed_inbox.queue_slice ->
    t tzresult Lwt.t

  val new_block :
    signer_ctxt ->
    Node_context.ro ->
    t ->
    Delayed_inbox.queue_slice ->
    t tzresult Lwt.t

  val append_messages :
    signer_ctxt ->
    Node_context.ro ->
    t ->
    Sc_rollup.Inbox_message.serialized list ->
    t tzresult Lwt.t
end

module Make (Enc : Messages_encoder) :
  S with type signer_ctxt := Enc.signer_ctxt
