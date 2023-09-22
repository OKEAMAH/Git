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

[@@@warning "-a"]

open Gs_interface.Worker_instance

module Gs_output_logging = struct
  include Internal_event.Simple
  open Data_encoding

  let section = ["GS"; "output"]

  let prefix =
    let prefix = String.concat "_" section in
    fun s -> if String.equal s String.empty then prefix else prefix ^ "-" ^ s

  let mk_message_title =
    let prefix = String.concat "." section in
    fun kind name -> Format.sprintf "[%s : `%s %s]" name kind prefix

  let sf = Format.sprintf

  let spaces_to_underscores = String.map (function ' ' -> '_' | s -> s)

  let pp_sep fmt () = Format.pp_print_string fmt ", "

  (* `IHave output *)
  let ihave_from_peer_with_low_score =
    let name = "ihave from peer with low score" in
    declare_2
      ~section
      ~name:(spaces_to_underscores name |> prefix)
      ~msg:
        (sf
           "%s score is {score} and threshold is {threshold}"
           (mk_message_title "IHave" name))
      ~level:Info
      ("score", float)
      ("threshold", float)

  let too_many_recv_ihave_messages =
    let name = "too many recv ihave messages" in
    declare_2
      ~section
      ~name:(spaces_to_underscores name |> prefix)
      ~msg:
        (sf
           "%s count is {count} and max is {max}"
           (mk_message_title "IHave" name))
      ~level:Info
      ("count", int31)
      ("max", int31)

  let too_many_sent_iwant_messages =
    let name = "too many sent iwant messages" in
    declare_2
      ~section
      ~name:(spaces_to_underscores name |> prefix)
      ~msg:
        (sf
           "%s count is {count} and max is {max}"
           (mk_message_title "IHave" name))
      ~level:Info
      ("count", int31)
      ("max", int31)

  let message_requested_message_ids =
    let name = "message requested message ids" in
    declare_1
      ~section
      ~name:(spaces_to_underscores name |> prefix)
      ~msg:(sf "%s for IDs {messages_ids}" (mk_message_title "IHave" name))
      ~level:Info
      ~pp1:(Format.pp_print_list GS.Message_id.pp)
      ("messages_ids", list Gs_interface.message_id_encoding)

  (* `IWant output *)

  let iwant_from_peer_with_low_score =
    let name = "iwant from peer with low score" in
    declare_2
      ~section
      ~name:(spaces_to_underscores name |> prefix)
      ~msg:
        (sf
           "%s score is {score} and threshold is {threshold}"
           (mk_message_title "IWant" name))
      ~level:Info
      ("score", float)
      ("threshold", float)

  let on_iwant_messages_to_route_encoding =
    let open Data_encoding in
    union
      [
        case
          (Tag 0)
          ~title:"Ignored"
          (obj1 (req "ignored" unit))
          (function `Ignored -> Some () | _ -> None)
          (fun () -> `Ignored);
        case
          (Tag 1)
          ~title:"Not_found"
          (obj1 (req "not_found" unit))
          (function `Not_found -> Some () | _ -> None)
          (fun () -> `Not_found);
        case
          (Tag 2)
          ~title:"Too_many_requests"
          (obj1 (req "too_many_requests" unit))
          (function `Too_many_requests -> Some () | _ -> None)
          (fun () -> `Too_many_requests);
        case
          (Tag 3)
          ~title:"Message"
          (obj1 (req "message" Gs_interface.message_encoding))
          (function `Message msg -> Some msg | _ -> None)
          (fun msg -> `Message msg);
      ]

  let on_iwant_messages_to_route =
    let name = "on iwant message to route" in
    let open Format in
    let pp_status fmt = function
      | `Ignored -> pp_print_string fmt "ignored"
      | `Not_found -> pp_print_string fmt "not found"
      | `Too_many_requests -> pp_print_string fmt "too many requests"
      | `Message msg ->
          fprintf fmt "%a" Gs_interface.Worker_instance.GS.Message.pp msg
    in
    let pp_item fmt (id, status) =
      fprintf
        fmt
        "(%a |-> {%a})"
        Gs_interface.Worker_instance.GS.Message_id.pp
        id
        pp_status
        status
    in
    declare_1
      ~section
      ~name:(spaces_to_underscores name |> prefix)
      ~msg:
        (sf "%s for IDs {routed_message_ids}" (mk_message_title "IWant" name))
      ~level:Info
      ~pp1:(Format.pp_print_list pp_item)
      ( "routed_message_ids",
        list
          (tup2
             Gs_interface.message_id_encoding
             on_iwant_messages_to_route_encoding) )

  (* `Prune output *)
  let peers_exchange =
    let name = "peers exchange" in
    declare_1
      ~section
      ~name:(spaces_to_underscores name |> prefix)
      ~msg:(sf "%s remaining peers {peers}" (mk_message_title "Prune" name))
      ~level:Info
      ~pp1:(fun fmt ->
        let open Format in
        fprintf fmt "{%a}" ((pp_print_list ~pp_sep) P2p_peer.Id.pp))
      ("peers", list P2p_peer.Id.encoding)

  let ignore_PX_score_too_low =
    let name = "ignore PX score too low" in
    declare_1
      ~section
      ~name:(spaces_to_underscores name |> prefix)
      ~msg:(sf "%s score is {score}" (mk_message_title "Prune" name))
      ~level:Info
      ("score", float)

  (* `Publish_message output *)
  let publish_message =
    let name = "publish message" in
    declare_1
      ~section
      ~name:(spaces_to_underscores name |> prefix)
      ~msg:(sf "%s to peers {peers}" (mk_message_title "Publish_message" name))
      ~level:Info
      ~pp1:(fun fmt ->
        let open Format in
        fprintf fmt "{%a}" ((pp_print_list ~pp_sep) P2p_peer.Id.pp))
      ("peers", list P2p_peer.Id.encoding)

  (* `Receive_message output *)
  let route_message =
    let name = "route message" in
    declare_1
      ~section
      ~name:(spaces_to_underscores name |> prefix)
      ~msg:(sf "%s to peers {peers}" (mk_message_title "Receive_message" name))
      ~level:Info
      ~pp1:(fun fmt ->
        let open Format in
        fprintf fmt "{%a}" ((pp_print_list ~pp_sep) P2p_peer.Id.pp))
      ("peers", list P2p_peer.Id.encoding)

  (* `Join output *)
  let joining_topic =
    let name = "joining topic" in
    declare_1
      ~section
      ~name:(spaces_to_underscores name |> prefix)
      ~msg:(sf "%s grafting peers {peers}" (mk_message_title "Join" name))
      ~level:Info
      ~pp1:(fun fmt ->
        let open Format in
        fprintf fmt "{%a}" ((pp_print_list ~pp_sep) P2p_peer.Id.pp))
      ("peers", list P2p_peer.Id.encoding)

  (*** `Leave output ***)
  let leaving_topic =
    let name = "leaving topic" in
    declare_2
      ~section
      ~name:(spaces_to_underscores name |> prefix)
      ~msg:
        (sf
           "%s peers to prune {prune_peers}, noPX peers for {noPX_peers}"
           (mk_message_title "Leave" name))
      ~level:Info
      ~pp1:(fun fmt ->
        let open Format in
        fprintf fmt "{%a}" ((pp_print_list ~pp_sep) P2p_peer.Id.pp))
      ~pp2:(fun fmt ->
        let open Format in
        fprintf fmt "{%a}" ((pp_print_list ~pp_sep) P2p_peer.Id.pp))
      ("prune_peers", list P2p_peer.Id.encoding)
      ("noPX_peers", list P2p_peer.Id.encoding)

  (*** `Heartbeat output ***)
  let heartbeat =
    let open Format in
    let name = "heartbeat" in
    let pp_topics = pp_print_list ~pp_sep GS.Topic.pp in
    let pp_item fmt (p, topics) =
      fprintf fmt "(%a |-> {%a})" P2p_peer.Id.pp p pp_topics topics
    in
    declare_3
      ~section
      ~name:(spaces_to_underscores name |> prefix)
      ~msg:
        (sf
           "%s to graft: [{to_graft}] | to prune: [{to_prune}] | noPX for \
            [{noPX_peers}]"
           (mk_message_title "Heartbeat" name))
      ~level:Info
      ~pp1:(pp_print_list ~pp_sep pp_item)
      ~pp2:(pp_print_list ~pp_sep pp_item)
      ~pp3:(Format.pp_print_list P2p_peer.Id.pp)
      ( "to_graft",
        list (tup2 P2p_peer.Id.encoding (list Gs_interface.topic_encoding)) )
      ( "to_prune",
        list (tup2 P2p_peer.Id.encoding (list Gs_interface.topic_encoding)) )
      ("noPX_peers", list P2p_peer.Id.encoding)

  (* Parameterized by [kind] *)
  let event_of_string ~kind =
    let raw_events =
      List.rev_map
        (fun name ->
          let decl =
            declare_0
              ~section
              ~name:(spaces_to_underscores name |> prefix)
              ~msg:(sf "%s" (mk_message_title kind name))
              ~level:Info
              ()
          in
          (name, decl))
        [
          "message topic not tracked";
          "peer filtered";
          "unsubscribed topic";
          "peer already in mesh";
          "grafting direct peer";
          "unexpected grafting peer";
          "grafting peer with negative score";
          "grafting successfully";
          "peer backed off";
          "mesh full";
          "prune topic not tracked";
          "peer not in mesh";
          "no PX";
          "already published";
          "already received";
          "not subscribed";
          "invalid message";
          "unknown validity";
          "already joined";
          "not joined";
          "peer added";
          "peer already known";
          "removing peer";
          "subscribed";
          "subscribe to unknown peer";
          "unsubscribed";
          "unsubscribe from unknown peer";
          "set application score";
        ]
    in
    let event_not_found name kind =
      declare_0
        ~section
        ~name:(spaces_to_underscores name |> prefix)
        ~msg:(sf "%s Unknown event name %S" (mk_message_title kind name) name)
        ~level:Warning
        ()
    in
    fun ~name ->
      match List.assoc ~equal:String.equal name raw_events with
      | Some v -> v
      | None -> event_not_found name kind
end

let automaton_output (Gs_interface.Worker_instance.GS.Output output) =
  let open Gs_interface.Worker_instance.GS in
  let open Gs_output_logging in
  let score_value score = Score.(value score |> to_float) in
  match output with
  (*** `IHave output ***)
  | Ihave_from_peer_with_low_score {score; threshold} ->
      emit ihave_from_peer_with_low_score (score_value score, threshold)
  | Too_many_recv_ihave_messages {count; max} ->
      emit too_many_recv_ihave_messages (count, max)
  | Too_many_sent_iwant_messages {count; max} ->
      emit too_many_sent_iwant_messages (count, max)
  | Message_requested_message_ids messages_ids ->
      emit message_requested_message_ids messages_ids
  | Message_topic_not_tracked ->
      emit (event_of_string ~name:"message topic not tracked" ~kind:"IHave") ()
      (*** `IWant output ***)
  | On_iwant_messages_to_route {routed_message_ids} ->
      emit
        on_iwant_messages_to_route
        (Message_id.Map.bindings routed_message_ids)
  | Iwant_from_peer_with_low_score {score; threshold} ->
      emit iwant_from_peer_with_low_score (score_value score, threshold)
  (*** `Graft output ***)
  | Peer_filtered ->
      emit (event_of_string ~name:"peer filtered" ~kind:"Graft") ()
  | Unsubscribed_topic ->
      emit (event_of_string ~name:"unsubscribed topic" ~kind:"Graft") ()
  | Peer_already_in_mesh ->
      emit (event_of_string ~name:"peer already in mesh" ~kind:"Graft") ()
  | Grafting_direct_peer ->
      emit (event_of_string ~name:"grafting direct peer" ~kind:"Graft") ()
  | Unexpected_grafting_peer ->
      emit (event_of_string ~name:"unexpected grafting peer" ~kind:"Graft") ()
  (* *)
  | Grafting_peer_with_negative_score ->
      emit
        (event_of_string
           ~name:"grafting peer with negative score"
           ~kind:"Graft")
        ()
  | Grafting_successfully ->
      emit (event_of_string ~name:"grafting successfully" ~kind:"Graft") ()
  | Peer_backed_off ->
      emit (event_of_string ~name:"peer backed off" ~kind:"Graft") ()
  | Mesh_full -> emit (event_of_string ~name:"mesh full" ~kind:"Graft") ()
  (*** `Prune output ***)
  | PX peers -> emit peers_exchange (Peer.Set.elements peers)
  | Ignore_PX_score_too_low score ->
      emit ignore_PX_score_too_low (score_value score)
  | Prune_topic_not_tracked ->
      emit (event_of_string ~name:"prune topic not tracked" ~kind:"Prune") ()
  | Peer_not_in_mesh ->
      emit (event_of_string ~name:"peer not in mesh" ~kind:"Prune") ()
  | No_PX -> emit (event_of_string ~name:"no PX" ~kind:"Prune") ()
  (*** `Publish_message output ***)
  | Publish_message {to_publish} ->
      emit publish_message (Peer.Set.elements to_publish)
  | Already_published ->
      emit
        (event_of_string ~name:"already published" ~kind:"Publish_message")
        ()
  (*** `Receive_message output ***)
  | Route_message {to_route} -> emit route_message (Peer.Set.elements to_route)
  | Already_received ->
      emit (event_of_string ~name:"already received" ~kind:"Receive_message") ()
  | Not_subscribed ->
      emit (event_of_string ~name:"not subscribed" ~kind:"Receive_message") ()
  | Invalid_message ->
      emit (event_of_string ~name:"invalid message" ~kind:"Receive_message") ()
  | Unknown_validity ->
      emit (event_of_string ~name:"unknown validity" ~kind:"Receive_message") ()
  (*** `Join output ***)
  | Joining_topic {to_graft} -> emit joining_topic (Peer.Set.elements to_graft)
  | Already_joined ->
      emit (event_of_string ~name:"already joined" ~kind:"Join") ()
  (*** `Leave output ***)
  | Leaving_topic {to_prune; noPX_peers} ->
      emit
        leaving_topic
        (Peer.Set.elements to_prune, Peer.Set.elements noPX_peers)
  | Not_joined -> emit (event_of_string ~name:"not joined" ~kind:"Leave") ()
  (*** `Heartbeat output ***)
  | Heartbeat {to_graft; to_prune; noPX_peers} ->
      let to_list m =
        Peer.Map.fold
          (fun p topics acc -> (p, Topic.Set.elements topics) :: acc)
          m
          []
      in
      emit
        heartbeat
        (to_list to_graft, to_list to_prune, Peer.Set.elements noPX_peers)
  (*** `Add_peer output ***)
  | Peer_added -> emit (event_of_string ~name:"peer added" ~kind:"Add_peer") ()
  | Peer_already_known ->
      emit (event_of_string ~name:"peer already known" ~kind:"Add_peer") ()
  (*** `Remove_peer output ***)
  | Removing_peer ->
      emit (event_of_string ~name:"removing peer" ~kind:"Remove_peer") ()
  (*** `Subscribe output ***)
  | Subscribed -> emit (event_of_string ~name:"subscribed" ~kind:"Subscribe") ()
  | Subscribe_to_unknown_peer ->
      emit
        (event_of_string ~name:"subscribe to unknown peer" ~kind:"Subscribe")
        ()
  (*** `Unsubscribe output ***)
  | Unsubscribed ->
      emit (event_of_string ~name:"unsubscribed" ~kind:"Unsubscribe") ()
  | Unsubscribe_from_unknown_peer ->
      emit
        (event_of_string
           ~name:"unsubscribe from unknown peer"
           ~kind:"Unsubscribe")
        ()
      (*** `Set_application_score output ***)
  | Set_application_score ->
      emit
        (event_of_string
           ~name:"set application score"
           ~kind:"Set_application_score")
        ()

module Events_logging = struct
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
      ~level:Info
      ()

  let publish_message =
    declare_2
      ~section
      ~name:(prefix "publish_message")
      ~msg:"Process Publish_message id {message_id} with topic {topic}"
      ~level:Info
      ~pp1:GS.Topic.pp
      ~pp2:GS.Message_id.pp
      ("topic", topic_encoding)
      ("message_id", message_id_encoding)

  let join =
    declare_1
      ~section
      ~name:(prefix "join")
      ~msg:"Process Join {topic}"
      ~level:Info
      ~pp1:GS.Topic.pp
      ("topic", topic_encoding)

  let leave =
    declare_1
      ~section
      ~name:(prefix "leave")
      ~msg:"Process Leave {topic}"
      ~level:Info
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
      ~level:Info
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
      ~level:Info
      ~pp1:P2p_peer.Id.pp
      ~pp2:GS.Topic.pp
      ("peer", P2p_peer.Id.encoding)
      ("topic", topic_encoding)

  let graft =
    declare_2
      ~section
      ~name:(prefix "graft")
      ~msg:"Process Graft {peer} for {topic}"
      ~level:Info
      ~pp1:P2p_peer.Id.pp
      ~pp2:GS.Topic.pp
      ("peer", P2p_peer.Id.encoding)
      ("topic", topic_encoding)

  let prune =
    declare_4
      ~section
      ~name:(prefix "prune")
      ~msg:"Process Prune {peer} for {topic} with backoff {backoff} and px {px}"
      ~level:Info
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
      ~level:Info
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
      ~level:Info
      ~pp1:P2p_peer.Id.pp
      ~pp2:(Format.pp_print_list GS.Message_id.pp)
      ("peer", P2p_peer.Id.encoding)
      ("message_ids", list message_id_encoding)
end

let event =
  let open Events_logging in
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
