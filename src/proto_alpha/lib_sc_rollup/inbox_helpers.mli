(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

val wrap_and_add_messages :
  predecessor_timestamp:Timestamp.time ->
  predecessor:Block_hash.t ->
  Sc_rollup.Inbox_message.t trace ->
  (Sc_rollup.Inbox_merkelized_payload_hashes.t
  * Sc_rollup.Inbox_message.t trace)
  tzresult

val wrap_and_add_messages_to_inbox :
  predecessor_timestamp:Timestamp.time ->
  predecessor:Block_hash.t ->
  Sc_rollup.Inbox.t ->
  Sc_rollup.Inbox_message.t trace ->
  (Sc_rollup.Inbox.t
  * Sc_rollup.Inbox_merkelized_payload_hashes.t
  * Sc_rollup.Inbox_message.t trace)
  tzresult

(** [add_payloads_with_history_history payloads] builds the
    payloads history for the list of [payloads]. This allows to not
    store payloads histories (which contain merkelized skip lists) but
    simply messages. *)
val add_payloads_with_history :
  Sc_rollup.Inbox_message.serialized trace ->
  (Sc_rollup.Inbox_merkelized_payload_hashes.t
  * Sc_rollup.Inbox_merkelized_payload_hashes.merkelized_and_payload
    Sc_rollup.Inbox_merkelized_payload_hashes.Hash.Map.t)
  tzresult

(** [add_messages_with_history_history messages] builds the
    payloads history for the list of [messgaes]. This allows to not
    store payloads histories (which contain merkelized skip lists) but
    simply messages. It first *)
val add_messages_with_history :
  Sc_rollup.Inbox_message.t trace ->
  (Sc_rollup.Inbox_merkelized_payload_hashes.t
  * Sc_rollup.Inbox_merkelized_payload_hashes.merkelized_and_payload
    Sc_rollup.Inbox_merkelized_payload_hashes.Hash.Map.t)
  tzresult

val wrap_and_add_messages_with_history :
  predecessor_timestamp:Time.Protocol.t ->
  predecessor:Block_hash.t ->
  Sc_rollup.Inbox_message.t list ->
  (Sc_rollup.Inbox_merkelized_payload_hashes.t
  * Sc_rollup.Inbox_message.t list
  * Sc_rollup.Inbox_merkelized_payload_hashes.merkelized_and_payload
    Sc_rollup.Inbox_merkelized_payload_hashes.Hash.Map.t)
  tzresult

val wrap_and_add_messages_to_inbox_with_history :
  predecessor_timestamp:Time.Protocol.t ->
  predecessor:Block_hash.t ->
  Sc_rollup.Inbox.t ->
  Sc_rollup.Inbox_message.t list ->
  (Sc_rollup.Inbox.t
  * Sc_rollup.Inbox_merkelized_payload_hashes.t
  * Sc_rollup.Inbox_message.t list
  * Sc_rollup.Inbox_merkelized_payload_hashes.merkelized_and_payload
    Sc_rollup.Inbox_merkelized_payload_hashes.Hash.Map.t)
  tzresult
