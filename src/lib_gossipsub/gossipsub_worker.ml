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

(* FIXME: https://gitlab.com/tezos/tezos/-/issues/5165

   Add coverage unit tests *)

module Make (C : Gossipsub_intf.WORKER_CONFIGURATION) :
  Gossipsub_intf.WORKER with module GS = C.GS = struct
  open C
  module GS = GS

  (** A worker has one of the following statuses:
     - [Starting] in case it is initialized with {!make} but not started yet.
     - [Running] in case the function [start] has been called. *)
  type worker_status =
    | Starting
    | Running of {
        heartbeat_handle : unit Monad.t;
        event_loop_handle : unit Monad.t;
      }

  type message =
    | Graft of GS.graft
    | Prune of GS.prune
    | IHave of GS.ihave
    | IWant of GS.iwant
    | Subscribe of GS.subscribe
    | Unsubscribe of GS.unsubscribe
    | Application of GS.publish

  (** The different kinds of events the Gossipsub worker handles. *)
  type event =
    | Heartbeat
    | New_connection of P2P.Connections_handler.connection
    | Disconnection of {peer : GS.Peer.t}
    | Join of {topic : GS.Topic.t}
    | Leave of {topic : GS.Topic.t}
    | Message of message

  type outcome =
    [ `IHave of GS.ihave * [`IHave] GS.output
    | `IWant of GS.iwant * [`IWant] GS.output
    | `Graft of GS.graft * [`Graft] GS.output
    | `Prune of GS.prune * [`Prune] GS.output
    | `Publish of GS.publish * [`Publish] GS.output
    | `Join of GS.join * [`Join] GS.output
    | `Leave of GS.leave * [`Leave] GS.output
    | `Heartbeat of [`Heartbeat] GS.output
    | `Add_peer of GS.add_peer * [`Add_peer] GS.output
    | `Remove_peer of GS.remove_peer * [`Remove_peer] GS.output
    | `Subscribe of GS.subscribe * [`Subscribe] GS.output
    | `Unsubscribe of GS.unsubscribe * [`Unsubscribe] GS.output ]

  (** The worker's state is made of its status, the gossipsub automaton's state,
      and a stream of events to process.  *)
  type t = {
    gossip_state : GS.state;
    status : worker_status;
    events_stream : event Stream.t;
    p2p_output_stream : message Stream.t;
    app_output_stream : GS.publish Stream.t;
    logging_stream : outcome Stream.t;
  }

  (** This is the main function of the worker. It interacts with the Gossipsub
      automaton given an event. The outcome is a new automaton state and an
      output to be processed, depending on the kind of input event. *)
  let apply_event gstate input : GS.state * outcome =
    match input with
    | Heartbeat ->
        (* TODO: https://gitlab.com/tezos/tezos/-/issues/5170

           Do we want to detect cases where two successive [Heartbeat] events
           would be handled (e.g. because the first one is late)? *)
        let gstate, res = GS.heartbeat gstate in
        (gstate, `Heartbeat res)
    | New_connection {peer; direct; outbound} ->
        (* FIXME:

           Should we send the list of topics we're subscribed to? *)
        let add = {GS.peer; direct; outbound} in
        let gstate, res = GS.add_peer add gstate in
        (gstate, `Add_peer (add, res))
    | Disconnection {peer} ->
        let remove = {GS.peer} in
        let gstate, res = GS.remove_peer remove gstate in
        (gstate, `Remove_peer (remove, res))
    | Join {topic} ->
        let topic = ({topic} : GS.join) in
        let gstate, res = GS.join topic gstate in
        (gstate, `Join (topic, res))
    | Leave {topic} ->
        let topic = ({topic} : GS.leave) in
        let gstate, res = GS.leave topic gstate in
        (gstate, `Leave (topic, res))
    | Message (Graft graft) ->
        let gstate, res = GS.handle_graft graft gstate in
        (gstate, `Graft (graft, res))
    | Message (Prune prune) ->
        let gstate, res = GS.handle_prune prune gstate in
        (gstate, `Prune (prune, res))
    | Message (IHave ihave) ->
        let gstate, res = GS.handle_ihave ihave gstate in
        (gstate, `IHave (ihave, res))
    | Message (IWant iwant) ->
        let gstate, res = GS.handle_iwant iwant gstate in
        (gstate, `IWant (iwant, res))
    | Message (Subscribe subscribe) ->
        let gstate, res = GS.handle_subscribe subscribe gstate in
        (gstate, `Subscribe (subscribe, res))
    | Message (Unsubscribe unsubscribe) ->
        let gstate, res = GS.handle_unsubscribe unsubscribe gstate in
        (gstate, `Unsubscribe (unsubscribe, res))
    | Message (Application publish) ->
        let gstate, res = GS.publish publish gstate in
        (gstate, `Publish (publish, res))

  let apply_outcome ~p2p_msg ~app_msg (outcome : outcome) =
    match outcome with
    | `Heartbeat (GS.Heartbeat {to_graft; to_prune = _; noPX_peers = _}) ->
        (* FIXME: xx

           Handle noPX_peers and future extensions of Heartbeat. *)
        (* FIXME: xx

           Handle prune. Some info are missing. *)

        (* FIXME: xx

           It's not clear right now where/when (un)subscribe should be called. *)
        ignore (Subscribe (assert false)) ;
        ignore (Unsubscribe (assert false)) ;

        GS.Peer.Map.iter
          (fun peer topics ->
            GS.Topic.Set.iter
              (fun topic -> p2p_msg @@ Graft {peer; topic})
              topics)
          to_graft
    | `Join ({GS.topic}, GS.Joining_topic {to_graft}) ->
        GS.Peer.Set.iter (fun peer -> p2p_msg @@ Graft {peer; topic}) to_graft
    | `Leave (_leave, GS.Leaving_topic _to_prune) ->
        (* FIXME: xx

           Handle prune. Some info are missing. *)
        p2p_msg @@ Prune (assert false)
    | `Publish
        ( ({GS.sender; message_id; topic; _} as publish),
          GS.Publish_message {advertise_peers; subscribed} ) ->
        let message_ids = [message_id] in
        GS.Peer.Set.iter
          (fun peer -> p2p_msg @@ IHave {peer; topic; message_ids})
          advertise_peers ;
        if Option.is_some sender && subscribed then app_msg publish
    | `IHave ({GS.peer; _}, GS.Message_requested_message_ids ids) ->
        if ids <> [] then p2p_msg @@ IWant {peer; message_ids = ids}
    | `IWant ({GS.peer; _}, GS.On_iwant_messages_to_route {routed_message_ids})
      ->
        (* FIXME:
           Topics needed here *)
        let topic = assert false in
        let sender = Some peer in
        GS.Message_id.Map.iter
          (fun message_id msg ->
            match msg with
            | `Message message ->
                p2p_msg @@ Application {GS.sender; message; message_id; topic}
            | _ -> ())
          routed_message_ids
    | `Prune (_prune, GS.PX _peers) ->
        (* FIXME: xx

           In case the answer is [PX Peer.Set.t], what should we do with those
           peers? *)
        assert false
    | `Graft
        ( _,
          ( GS.Peer_filtered | GS.Unknown_topic | GS.Peer_already_in_mesh
          | GS.Grafting_direct_peer | GS.Unexpected_grafting_peer
          | GS.Grafting_peer_with_negative_score | GS.Grafting_successfully
          | GS.Peer_backed_off ) )
    | `Add_peer (_, (GS.Peer_added | GS.Peer_already_known))
    | `Remove_peer (_, GS.Removing_peer)
    | `Subscribe (_, (GS.Subscribed | GS.Subscribe_to_unknown_peer))
    | `Unsubscribe (_, (GS.Unsubscribed | GS.Unsubscribe_from_unknown_peer))
    | `Join (_, GS.Already_subscribed)
    | `Leave (_, GS.Not_subscribed)
    | `Prune (_, (GS.No_peer_in_mesh | GS.Ignore_PX_score_too_low _ | GS.No_PX))
    | `IHave
        ( _,
          ( GS.Negative_peer_score _ | GS.Too_many_recv_ihave_messages _
          | GS.Too_many_sent_iwant_messages _ | GS.Message_topic_not_tracked )
        ) ->
        ()

  (** A helper function that pushes events in the state *)
  let push e t = Stream.push e t.events_stream

  (** A set of functions that push different kinds of events in the worker's
      state. *)
  let inject t message_id message topic =
    push (Message (Application {sender = None; message; message_id; topic})) t

  let new_connection t conn = push (New_connection conn) t

  let disconnection t peer = push (Disconnection {peer}) t

  let join t topics = List.iter (fun topic -> push (Join {topic}) t) topics

  let leave t topics = List.iter (fun topic -> push (Leave {topic}) t) topics

  (** This function returns a never-ending loop that periodically pushes
      [Heartbeat] events in the stream.  *)
  let heartbeat_events_producer ~heartbeat_span stream =
    let rec loop () =
      let open Monad in
      let* () = Monad.sleep heartbeat_span in
      Stream.push Heartbeat stream ;
      loop ()
    in
    loop ()

  (** This function returns a never-ending loop that processes the events of the
      worker's stream. *)
  let event_loop t =
    let rev_push stream e = Stream.push e stream in
    let p2p_msg = rev_push t.p2p_output_stream in
    let app_msg = rev_push t.app_output_stream in
    let logging = rev_push t.logging_stream in
    let rec loop t =
      let open Monad in
      let* event = Stream.pop t.events_stream in
      let gossip_state, outcome = apply_event t.gossip_state event in
      let () = logging outcome in
      let () = apply_outcome ~p2p_msg ~app_msg outcome in
      loop {t with gossip_state}
    in
    loop t

  let start ~heartbeat_span topics t =
    match t.status with
    | Starting ->
        let heartbeat_handle =
          heartbeat_events_producer ~heartbeat_span t.events_stream
        in
        let event_loop_handle = event_loop t in
        (* FIXME: https://gitlab.com/tezos/tezos/-/issues/5167

           We should probably do something with the topics. Currently, they are
           not used. Should we use [GS.join] and [GS.leave] to dynamically join
           or leave topics instead (In which case, we should probably expose
           them in the worker?). *)
        let status = Running {heartbeat_handle; event_loop_handle} in
        let () = P2P.Connections_handler.on_connection (new_connection t) in
        let () = P2P.Connections_handler.on_diconnection (disconnection t) in
        let t = {t with status} in
        let () = join t topics in
        t
    | Running _ ->
        (* FIXME: https://gitlab.com/tezos/tezos/-/issues/5166

           Better error handling *)
        Format.eprintf "A worker is already running for this state!@." ;
        assert false

  let shutdown state =
    match state.status with
    | Starting -> ()
    | Running _ ->
        (* FIXME: https://gitlab.com/tezos/tezos/-/issues/5171

           Implement worker shutdown.
           Should we unsubscribe from the callbacks called in start? *)
        ()

  let make rng limits parameters =
    {
      gossip_state = GS.make rng limits parameters;
      status = Starting;
      events_stream = Stream.empty;
      p2p_output_stream = Stream.empty;
      app_output_stream = Stream.empty;
      logging_stream = Stream.empty;
    }
  (* FIXME: xx

     Provide getters for the streams above.*)
end
