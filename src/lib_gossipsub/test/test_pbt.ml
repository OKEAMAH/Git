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

(** {2 PBT for gossipsub.} *)

open Test_gossipsub_shared
open Gossipsub_intf
open Tezt_core.Base

module Basic_fragments = struct
  open Gossipsub_pbt_generators
  open Fragment

  let prune_backoff = 10

  let add_then_remove_peer ~gen_peer : t =
    of_input_gen (add_peer ~gen_peer) @@ fun ap ->
    [Add_peer ap; Remove_peer {peer = ap.peer}]

  let join_then_leave_topic ~gen_topic : t =
    of_input_gen (join ~gen_topic) @@ fun jp ->
    [Join jp; Leave {topic = jp.topic}]

  let graft_then_prune ~gen_peer ~gen_topic : t =
    of_input_gen (graft ~gen_peer ~gen_topic) @@ fun g ->
    [
      Graft g;
      Prune
        {
          peer = g.peer;
          topic = g.topic;
          px = Seq.empty;
          backoff = prune_backoff;
        };
    ]

  let heartbeat : t = of_list [Heartbeat]
end

(** Test that removing a peer really removes it from the state *)
module Test_remove_peer = struct
  open Gossipsub_pbt_generators

  let all_peers = [0; 1; 2; 3]

  let fail_if_in_map peers map ~on_error =
    let fail = List.find_opt (fun peer -> GS.Peer.Map.mem peer map) peers in
    match fail with None -> Ok () | Some peer -> Error (on_error peer)

  let fail_if_in_set peers set ~on_error =
    let fail = List.find_opt (fun peer -> GS.Peer.Set.mem peer set) peers in
    match fail with None -> Ok () | Some peer -> Error (on_error peer)

  let not_in_view peers state =
    let open GS.Introspection in
    let open Result_syntax in
    let view = view state in
    let check_map str map =
      fail_if_in_map peers map ~on_error:(fun peer ->
          `peer_not_removed_correctly (view, str, peer))
    in
    let check_set str set =
      fail_if_in_set peers set ~on_error:(fun peer ->
          `peer_not_removed_correctly (view, str, peer))
    in
    let* () = check_map "connections" view.connections in
    (* We don't check [ihave/iwant_per_heartbeat], as these maps are
       only cleaned on heartbeat. There's a potential issue with smap though.
       FIXME https://gitlab.com/tezos/tezos/-/issues/5252 *)
    let* () =
      C.Topic.Map.to_seq view.mesh
      |> Seq.E.iter (fun (topic, peer_set) ->
             let str = Format.asprintf "mesh[topic=%a]" C.Topic.pp topic in
             check_set str peer_set)
    in
    let* () =
      C.Topic.Map.to_seq view.fanout
      |> Seq.E.iter (fun (topic, fanout_peers) ->
             let str = Format.asprintf "fanout[topic=%a]" C.Topic.pp topic in
             check_set str fanout_peers.peers)
    in
    C.Message_id.Map.to_seq view.memory_cache.messages
    |> Seq.E.iter (fun (message_id, value) ->
           let place =
             Format.asprintf "memory_cache[message_id=%d]" message_id
           in
           check_map place value.Memory_cache.access)

  let predicate final_state _final_output =
    (* This predicate checks that [peer_id] does not appear in the [view]
       of the final state. *)
    not_in_view all_peers final_state

  let scenario limits =
    let open Fragment in
    let open Basic_fragments in
    let gen_peer = M.oneofl all_peers in
    let gen_topic =
      M.oneofl ["topicA"; "topicB"; "topicC"; "topicD"; "topicE"]
    in
    let gen_message_id = M.oneofl [42; 43; 44] in
    let gen_msg_count = M.int_range 1 5 in

    let add_then_remove_peer_wait_and_clean () =
      (* In order to purge a peer from the connections, we need to
         1. remove it
         2. wait until [expire=retain_duration+slack]
         3. wait until the next round of cleanup in the heartbeat *)
      let expire = limits.retain_duration + (limits.heartbeat_interval * 2) in
      let heartbeat_cleanup_ticks = limits.backoff_cleanup_ticks in
      add_then_remove_peer ~gen_peer
      @% repeat expire tick
      @% repeat heartbeat_cleanup_ticks heartbeat
    in
    let graft_then_prune_wait_and_clean () =
      (* A pruned peer will stay in the connection table until the
         end of the backoff specified in the Prune message.
         After pruning, we wait for [backoff] ticks then force
         triggering a cleanup of the backoffs in the heartbeat. *)
      let backoff = Basic_fragments.prune_backoff in
      let heartbeat_cleanup_ticks = limits.backoff_cleanup_ticks in
      graft_then_prune ~gen_peer ~gen_topic
      @% repeat backoff tick
      @% repeat heartbeat_cleanup_ticks heartbeat
    in
    interleave
      [
        fork_at_most
          4
          (repeat_at_most 2 (add_then_remove_peer_wait_and_clean ()));
        repeat_at_most 10 @@ join_then_leave_topic ~gen_topic;
        repeat_at_most 10 heartbeat;
        repeat_at_most 100 tick;
        of_input_gen
          (ihave ~gen_peer ~gen_topic ~gen_message_id ~gen_msg_count)
          (fun ihave -> [Ihave ihave])
        |> repeat_at_most 5;
        of_input_gen
          (iwant ~gen_peer ~gen_message_id ~gen_msg_count)
          (fun iwant -> [Iwant iwant])
        |> repeat_at_most 5;
        graft_then_prune_wait_and_clean () |> repeat_at_most 10;
      ]

  let pp_backoff fmtr (backoff : int GS.Topic.Map.t) =
    let list = backoff |> GS.Topic.Map.to_seq |> List.of_seq in
    Format.pp_print_list
      ~pp_sep:(fun fmtr () -> Format.fprintf fmtr ",")
      (fun fmtr (topic, backoff) ->
        Format.fprintf fmtr "%a -> %d" GS.Topic.pp topic backoff)
      fmtr
      list

  let pp_state fmtr state =
    let v = GS.Introspection.view state in
    let cleanup =
      Int64.(rem v.heartbeat_ticks (of_int v.limits.backoff_cleanup_ticks)) = 0L
    in
    C.Peer.Map.iter
      (fun peer {GS.Introspection.backoff; expire; _} ->
        let open Format in
        fprintf
          fmtr
          "peer %a, expire=%a, backoff=[%a], cleanup=%b"
          GS.Peer.pp
          peer
          (pp_print_option pp_print_int)
          expire
          pp_backoff
          backoff
          cleanup)
      v.connections

  let test rng limits parameters =
    Tezt_core.Test.register
      ~__FILE__
      ~title:"Gossipsub: remove peer"
      ~tags:["gossipsub"; "control"]
    @@ fun () ->
    let scenario =
      let open M in
      let* limits =
        let+ retain_duration = M.int_range 0 (limits.retain_duration * 2)
        and+ heartbeat_interval = M.int_range 0 (limits.heartbeat_interval * 2)
        and+ backoff_cleanup_ticks =
          M.int_range 1 (limits.backoff_cleanup_ticks * 2)
        in
        {limits with retain_duration; heartbeat_interval; backoff_cleanup_ticks}
      in
      let state = GS.make rng limits parameters in
      run state (scenario limits)
    in
    let test =
      QCheck2.Test.make ~count:10_000 ~name:"Gossipsub: remove_peer" scenario
      @@ fun trace ->
      match check_final predicate trace with
      | Ok () -> true
      | Error e -> (
          match e with
          | `peer_not_removed_correctly (v, msg, peer) ->
              Tezt.Test.fail
                ~__LOC__
                "@[<v 2>Peer %d was not removed correctly from %s.@;\
                 Limits:@;\
                 %a@;\
                 Dumping trace:@;\
                 @[<v>%a@]@]"
                peer
                msg
                pp_limits
                GS.Introspection.(limits v)
                (pp_trace ~pp_state ~pp_state':pp_state ())
                trace)
    in
    QCheck2.Test.check_exn ~rand:rng test ;
    unit
end

let register rng limits parameters = Test_remove_peer.test rng limits parameters
