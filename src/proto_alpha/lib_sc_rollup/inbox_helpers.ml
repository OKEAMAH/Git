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

let wrap_external_messages ~predecessor_timestamp ~predecessor messages =
  let open Sc_rollup.Inbox_message in
  let sol = Internal Start_of_level in
  let info_per_level =
    Internal (Info_per_level {predecessor_timestamp; predecessor})
  in
  let eol = Internal End_of_level in
  [sol; info_per_level] @ messages @ [eol]

let wrap_and_add_messages ~predecessor_timestamp ~predecessor messages =
  let open Result_syntax in
  let* external_payloads =
    Environment.wrap_tzresult
    @@ List.map_e Sc_rollup.Inbox_message.serialize messages
  in
  (* Add [SOL], [Info_per_level] and [eol]. *)
  let witness = Sc_rollup.Inbox.Node_helpers.init_witness in
  let* witness =
    Environment.wrap_tzresult
    @@ Sc_rollup.Inbox.Node_helpers.add_info_per_level
         ~predecessor_timestamp
         ~predecessor
         witness
  in
  let* witness =
    match external_payloads with
    | [] -> return witness
    | payloads ->
        Environment.wrap_tzresult
        @@ Sc_rollup.Inbox.add_messages payloads witness
  in
  let witness = Sc_rollup.Inbox.Node_helpers.finalize_witness witness in
  (* Wrap the messages so the caller can execute every actual messages
     for this inbox level. *)
  return
    ( witness,
      wrap_external_messages ~predecessor ~predecessor_timestamp messages )

let wrap_and_add_messages_to_inbox ~predecessor_timestamp ~predecessor inbox
    messages =
  let open Result_syntax in
  let* witness, messages_with_protocol_internal_messages =
    wrap_and_add_messages ~predecessor_timestamp ~predecessor messages
  in
  let inbox = Sc_rollup.Inbox.Node_helpers.archive inbox witness in
  return (inbox, witness, messages_with_protocol_internal_messages)

let remember history witness payload =
  let open Sc_rollup.Inbox_merkelized_payload_hashes in
  let prev_cell_ptr = hash witness in
  Hash.Map.add prev_cell_ptr {merkelized = witness; payload} history

let add_payloads_with_history payloads =
  let open Result_syntax in
  let open Sc_rollup.Inbox_merkelized_payload_hashes in
  let history = Hash.Map.empty in
  match payloads with
  | [] -> error_with "invalid arg: empty list"
  | sol :: payloads ->
      let genesis_witness = genesis sol in
      let history = remember history genesis_witness sol in
      return
      @@ List.fold_left
           (fun (witness, history) payload ->
             let witness = add_payload witness payload in
             let history = remember history witness payload in
             (witness, history))
           (genesis_witness, history)
           payloads

let add_messages_with_history messages =
  let open Result_syntax in
  let* payloads =
    Environment.wrap_tzresult
    @@ List.map_e Sc_rollup.Inbox_message.serialize messages
  in
  add_payloads_with_history payloads

let wrap_and_add_messages_with_history ~predecessor_timestamp ~predecessor
    messages =
  let open Result_syntax in
  let messages_with_protocol_internal_messages =
    wrap_external_messages ~predecessor_timestamp ~predecessor messages
  in
  let* witness, history =
    add_messages_with_history messages_with_protocol_internal_messages
  in
  return (witness, messages_with_protocol_internal_messages, history)

let wrap_and_add_messages_to_inbox_with_history ~predecessor_timestamp
    ~predecessor inbox messages =
  let open Result_syntax in
  let* witness, messages_with_protocol_internal_messages, history =
    wrap_and_add_messages_with_history
      ~predecessor_timestamp
      ~predecessor
      messages
  in
  let inbox = Sc_rollup.Inbox.Node_helpers.archive inbox witness in
  return (inbox, witness, messages_with_protocol_internal_messages, history)
