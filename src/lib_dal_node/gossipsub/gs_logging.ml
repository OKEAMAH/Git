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

module Worker_events = struct
  include Internal_event.Simple
  open Data_encoding

  let section = ["gossipsub"; "worker"; "event"]

  let prefix =
    let prefix = String.concat "_" section in
    fun s -> prefix ^ "-" ^ s

  let heartbeat =
    declare_0
      ~section
      ~name:(prefix "heartbeat")
      ~msg:"Process Heartbeat"
      ~level:Info
      ()

  let publish_message =
    declare_2
      ~section
      ~name:(prefix "publish_message")
      ~msg:"Process Publish_message id {message_id} with topic {topic}"
      ~level:Debug
      ~pp1:GS.Topic.pp
      ~pp2:GS.Message_id.pp
      ("topic", Types.Topic.encoding)
      ("message_id", Types.Message_id.encoding)

  let join =
    declare_1
      ~section
      ~name:(prefix "join")
      ~msg:"Process Join {topic}"
      ~level:Info
      ~pp1:GS.Topic.pp
      ("topic", Types.Topic.encoding)

  let leave =
    declare_1
      ~section
      ~name:(prefix "leave")
      ~msg:"Process Leave {topic}"
      ~level:Info
      ~pp1:GS.Topic.pp
      ("topic", Types.Topic.encoding)

  let new_connection =
    declare_4
      ~section
      ~name:(prefix "new_connection")
      ~msg:
        "Process New_connection from/to {peer} (direct={direct}, \
         trusted={trusted}, bootstrap={bootstrap})"
      ~level:Notice
      ~pp1:P2p_peer.Id.pp
      ("peer", P2p_peer.Id.encoding)
      ("direct", bool)
      ("trusted", bool)
      ("bootstrap", bool)

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
      ~level:Debug
      ~pp1:P2p_peer.Id.pp
      ~pp2:GS.Topic.pp
      ~pp3:GS.Message_id.pp
      ("peer", P2p_peer.Id.encoding)
      ("topic", Types.Topic.encoding)
      ("message_id", Types.Message_id.encoding)

  let subscribe =
    declare_2
      ~section
      ~name:(prefix "subscribe")
      ~msg:"Process Subscribe {peer} to {topic}"
      ~level:Info
      ~pp1:P2p_peer.Id.pp
      ~pp2:GS.Topic.pp
      ("peer", P2p_peer.Id.encoding)
      ("topic", Types.Topic.encoding)

  let unsubscribe =
    declare_2
      ~section
      ~name:(prefix "unsubscribe")
      ~msg:"Process Unsubscribe {peer} from {topic}"
      ~level:Info
      ~pp1:P2p_peer.Id.pp
      ~pp2:GS.Topic.pp
      ("peer", P2p_peer.Id.encoding)
      ("topic", Types.Topic.encoding)

  let graft =
    declare_2
      ~section
      ~name:(prefix "graft")
      ~msg:"Process Graft {peer} for {topic}"
      ~level:Info
      ~pp1:P2p_peer.Id.pp
      ~pp2:GS.Topic.pp
      ("peer", P2p_peer.Id.encoding)
      ("topic", Types.Topic.encoding)

  let prune =
    declare_4
      ~section
      ~name:(prefix "prune")
      ~msg:"Process Prune {peer} for {topic} with backoff {backoff} and px {px}"
      ~level:Info
      ~pp1:P2p_peer.Id.pp
      ~pp2:GS.Topic.pp
      ~pp3:Types.Span.pp
      ~pp4:(Format.pp_print_list P2p_peer.Id.pp)
      ("peer", P2p_peer.Id.encoding)
      ("topic", Types.Topic.encoding)
      ("backoff", Types.Span.encoding)
      ("px", list P2p_peer.Id.encoding)

  let ihave =
    declare_3
      ~section
      ~name:(prefix "ihave")
      ~msg:
        "Process IHave from {peer} for {topic} with message_ids {message_ids}"
      ~level:Info
      ~pp1:P2p_peer.Id.pp
      ~pp2:GS.Topic.pp
      ~pp3:(Format.pp_print_list GS.Message_id.pp)
      ("peer", P2p_peer.Id.encoding)
      ("topic", Types.Topic.encoding)
      ("message_ids", list Types.Message_id.encoding)

  let iwant =
    declare_2
      ~section
      ~name:(prefix "iwant")
      ~msg:"Process IWant from {peer} with message_ids {message_ids}"
      ~level:Info
      ~pp1:P2p_peer.Id.pp
      ~pp2:(Format.pp_print_list GS.Message_id.pp)
      ("peer", P2p_peer.Id.encoding)
      ("message_ids", list Types.Message_id.encoding)
end

module Automaton_events = struct
  include Internal_event.Simple
  open Data_encoding

  let section = ["gossipsub"; "automaton"; "event"]

  let prefix =
    let prefix = String.concat "_" section in
    fun s -> prefix ^ "-" ^ s

  let output =
    declare_2
      ~section
      ~name:(prefix "output")
      ~msg:"Output {output} after event from {peer}"
      ~level:Info
      ~pp1:(fun fmt opt ->
        match opt with
        | None -> Format.fprintf fmt "app"
        | Some p -> Format.fprintf fmt "peer %a" P2p_peer.Id.pp p)
      ("peer", option P2p_peer.Id.encoding)
      ("output", Data_encoding.string)
end

let _event =
  let open Worker_events in
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
      | New_connection {peer; direct; trusted; bootstrap} ->
          emit new_connection (peer, direct, trusted, bootstrap)
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

let _output =
  let open Automaton_events in
  let open GS in
  fun ?(heartbeat = false)
      ?(mesh = true)
      ?(metadata = true)
      ?(connection = true)
      ?(messages = true)
      ?(regular = false)
      ?from_peer
      (Output o) ->
    match o with
    (* IHave *)
    | Ihave_from_peer_with_low_score _ when metadata ->
        emit output (from_peer, "Ihave_from_peer_with_low_score")
    | Too_many_recv_ihave_messages _ when metadata ->
        emit output (from_peer, "Too_many_recv_ihave_messages")
    | Too_many_sent_iwant_messages _ when metadata ->
        emit output (from_peer, "Too_many_sent_iwant_messages")
    | Message_topic_not_tracked when metadata ->
        emit output (from_peer, "Message_topic_not_tracked")
    | Message_requested_message_ids _ when metadata && regular ->
        emit output (from_peer, "Message_requested_message_ids")
    | Invalid_message_id when metadata ->
        emit output (from_peer, "Invalid_message_id")
    | Iwant_from_peer_with_low_score _ when metadata ->
        emit output (from_peer, "Iwant_from_peer_with_low_score")
    | On_iwant_messages_to_route _ when metadata ->
        emit output (from_peer, "On_iwant_messages_to_route")
    | Peer_filtered when mesh -> emit output (from_peer, "Peer_filtered")
    | Unsubscribed_topic when mesh ->
        emit output (from_peer, "Unsubscribed_topic")
    | Peer_already_in_mesh when mesh ->
        emit output (from_peer, "Peer_already_in_mesh")
    | Grafting_direct_peer when mesh ->
        emit output (from_peer, "Grafting_direct_peer")
    | Unexpected_grafting_peer when mesh ->
        emit output (from_peer, "Unexpected_grafting_peer")
    | Grafting_peer_with_negative_score when mesh ->
        emit output (from_peer, "Grafting_peer_with_negative_score")
    | Grafting_successfully when mesh && regular ->
        emit output (from_peer, "Grafting_successfully")
    | Peer_backed_off when mesh -> emit output (from_peer, "Peer_backed_off")
    | Mesh_full when metadata -> emit output (from_peer, "Mesh_full")
    | Prune_topic_not_tracked ->
        emit output (from_peer, "Prune_topic_not_tracked")
    | Peer_not_in_mesh when mesh -> emit output (from_peer, "Peer_not_in_mesh")
    | Ignore_PX_score_too_low _ when mesh ->
        emit output (from_peer, "Ignore_PX_score_too_low")
    | No_PX when mesh -> emit output (from_peer, "No_PX")
    | PX _ when mesh && regular -> emit output (from_peer, "PX")
    | Publish_message _ when messages && regular ->
        emit output (from_peer, "Publish_message")
    | Already_published when messages && regular ->
        emit output (from_peer, "Already_published")
    | Route_message _ when messages && regular ->
        emit output (from_peer, "Route_message")
    | Already_received when messages && regular ->
        emit output (from_peer, "Already_received")
    | Not_subscribed when messages -> emit output (from_peer, "Not_subscribed")
    | Invalid_message when messages -> emit output (from_peer, "Invalid_message")
    | Unknown_validity when messages ->
        emit output (from_peer, "Unknown_validity")
    | Already_joined when connection -> emit output (from_peer, "Already_joined")
    | Joining_topic _ when connection && regular ->
        emit output (from_peer, "Joining_topic")
    | Not_joined when connection -> emit output (from_peer, "Not_joined")
    | Leaving_topic _ when connection && regular ->
        emit output (from_peer, "Leaving_topic")
    | Heartbeat _ when heartbeat -> emit output (from_peer, "Heartbeat")
    | Peer_added when connection && regular ->
        emit output (from_peer, "Peer_added")
    | Peer_already_known when connection ->
        emit output (from_peer, "Peer_already_known")
    | Removing_peer when connection && regular ->
        emit output (from_peer, "Removing_peer")
    | Subscribed when connection && regular ->
        emit output (from_peer, "Subscribed")
    | Subscribe_to_unknown_peer when connection ->
        emit output (from_peer, "Subscribe_to_unknown_peer")
    | Unsubscribed when connection && regular ->
        emit output (from_peer, "Unsubscribed")
    | Unsubscribe_from_unknown_peer when connection ->
        emit output (from_peer, "Unsubscribe_from_unknown_peer")
    | Set_application_score -> emit output (from_peer, "Set_application_score")
    | _ -> Lwt.return_unit
