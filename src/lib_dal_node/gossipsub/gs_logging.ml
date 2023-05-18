(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2023 Functori,     <contact@functori.com>                   *)
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

open Gs_interface.Worker_instance

module Events = struct
  include Internal_event.Simple
  open Data_encoding
  open Gs_interface

  let section = ["gossipsub"; "worker"; "event"]

  let prefix =
    let prefix = String.concat "_" section in
    fun s -> prefix ^ "-" ^ s

  let heartbeat =
    declare_0
      ~section
      ~name:(prefix "heartbeat")
      ~msg:"Process Heartbeat"
      ~level:Notice
      ()

  let publish_message =
    declare_2
      ~section
      ~name:(prefix "publish_message")
      ~msg:"Process Publish_message id {message_id} with topic {topic}"
      ~level:Notice
      ~pp1:GS.Topic.pp
      ~pp2:GS.Message_id.pp
      ("topic", topic_encoding)
      ("message_id", message_id_encoding)

  let join =
    declare_1
      ~section
      ~name:(prefix "join")
      ~msg:"Process Join {topic}"
      ~level:Notice
      ~pp1:GS.Topic.pp
      ("topic", topic_encoding)

  let leave =
    declare_1
      ~section
      ~name:(prefix "leave")
      ~msg:"Process Leave {topic}"
      ~level:Notice
      ~pp1:GS.Topic.pp
      ("topic", topic_encoding)

  let new_connection =
    declare_3
      ~section
      ~name:(prefix "new_connection")
      ~msg:
        "Process New_connection from/to {peer} (direct={direct}, \
         outbound={outbound})"
      ~level:Notice
      ~pp1:P2p_peer.Id.pp
      ("peer", P2p_peer.Id.encoding)
      ("direct", bool)
      ("outbound", bool)

  let disconnection =
    declare_1
      ~section
      ~name:(prefix "disconnection")
      ~msg:"Process Disconnection of {peer}"
      ~level:Notice
      ~pp1:P2p_peer.Id.pp
      ("peer", P2p_peer.Id.encoding)

  let message_with_header =
    declare_3
      ~section
      ~name:(prefix "message_with_header")
      ~msg:
        "Process Message_with_header from {peer} with id {message_id} and \
         topic {topic}"
      ~level:Notice
      ~pp1:P2p_peer.Id.pp
      ~pp2:GS.Topic.pp
      ~pp3:GS.Message_id.pp
      ("peer", P2p_peer.Id.encoding)
      ("topic", topic_encoding)
      ("message_id", message_id_encoding)

  let subscribe =
    declare_2
      ~section
      ~name:(prefix "subscribe")
      ~msg:"Process Subscribe {peer} to {topic}"
      ~level:Notice
      ~pp1:P2p_peer.Id.pp
      ~pp2:GS.Topic.pp
      ("peer", P2p_peer.Id.encoding)
      ("topic", topic_encoding)

  let unsubscribe =
    declare_2
      ~section
      ~name:(prefix "unsubscribe")
      ~msg:"Process Unsubscribe {peer} from {topic}"
      ~level:Notice
      ~pp1:P2p_peer.Id.pp
      ~pp2:GS.Topic.pp
      ("peer", P2p_peer.Id.encoding)
      ("topic", topic_encoding)

  let graft =
    declare_2
      ~section
      ~name:(prefix "graft")
      ~msg:"Process Graft {peer} for {topic}"
      ~level:Notice
      ~pp1:P2p_peer.Id.pp
      ~pp2:GS.Topic.pp
      ("peer", P2p_peer.Id.encoding)
      ("topic", topic_encoding)

  let prune =
    declare_4
      ~section
      ~name:(prefix "prune")
      ~msg:"Process Prune {peer} for {topic} with backoff {backoff} and px {px}"
      ~level:Notice
      ~pp1:P2p_peer.Id.pp
      ~pp2:GS.Topic.pp
      ~pp3:Span.pp
      ~pp4:(Format.pp_print_list P2p_peer.Id.pp)
      ("peer", P2p_peer.Id.encoding)
      ("topic", topic_encoding)
      ("backoff", span_encoding)
      ("px", list P2p_peer.Id.encoding)

  let ihave =
    declare_3
      ~section
      ~name:(prefix "ihave")
      ~msg:
        "Process IHave from {peer} for {topic} with message_ids {message_ids}"
      ~level:Notice
      ~pp1:P2p_peer.Id.pp
      ~pp2:GS.Topic.pp
      ~pp3:(Format.pp_print_list GS.Message_id.pp)
      ("peer", P2p_peer.Id.encoding)
      ("topic", topic_encoding)
      ("message_ids", list message_id_encoding)

  let iwant =
    declare_2
      ~section
      ~name:(prefix "iwant")
      ~msg:"Process IWant from {peer} with message_ids {message_ids}"
      ~level:Notice
      ~pp1:P2p_peer.Id.pp
      ~pp2:(Format.pp_print_list GS.Message_id.pp)
      ("peer", P2p_peer.Id.encoding)
      ("message_ids", list message_id_encoding)
end

let event =
  let open Events in
  function
  | Heartbeat -> emit heartbeat ()
  | App_input event -> (
      match event with
      | Publish_message {message = _; message_id; topic} ->
          emit publish_message (topic, message_id)
      | Join topic -> emit join topic
      | Leave topic -> emit leave topic)
  | P2P_input event -> (
      match event with
      | New_connection {peer; direct; outbound} ->
          emit new_connection (peer, direct, outbound)
      | Disconnection {peer} -> emit disconnection peer
      | In_message {from_peer; p2p_message} -> (
          match p2p_message with
          | Message_with_header {message = _; topic; message_id} ->
              emit message_with_header (from_peer, topic, message_id)
          | Subscribe {topic} -> emit subscribe (from_peer, topic)
          | Unsubscribe {topic} -> emit unsubscribe (from_peer, topic)
          | Graft {topic} -> emit graft (from_peer, topic)
          | Prune {topic; px; backoff} ->
              emit prune (from_peer, topic, backoff, List.of_seq px)
          | IHave {topic; message_ids} ->
              emit ihave (from_peer, topic, message_ids)
          | IWant {message_ids} -> emit iwant (from_peer, message_ids)))
