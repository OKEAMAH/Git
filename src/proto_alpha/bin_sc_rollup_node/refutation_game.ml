(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

(** This module implements the refutation game logic of the rollup
   node.

   When a new L1 block arises, the rollup node asks the L1 node for
   the current game it is part of, if any.

   If a game is running and it is the rollup operator turn, the rollup
   node injects the next move of the winning strategy.

   If a game is running and it is not the rollup operator turn, the
   rollup node asks the L1 node whether the timeout is reached to play
   the timeout argument if possible.

   Otherwise, if no game is running, the rollup node asks the L1 node
   whether there is a conflict with one of its disputable commitments. If
   there is such a conflict with a commitment C', then the rollup node
   starts a game to refute C' by starting a game with one of its staker.

*)
open Protocol

open Alpha_context

module type S = sig
  module PVM : Pvm.S

  val process :
    Layer1.head -> Node_context.t -> PVM.context -> unit tzresult Lwt.t
end

module Make (PVM : Pvm.S) : S with module PVM = PVM = struct
  module PVM = PVM
  module Interpreter = Interpreter.Make (PVM)
  open Sc_rollup.Game

  let node_role node_ctxt Sc_rollup.Game.Index.{alice; bob} =
    let self = node_ctxt.Node_context.operator in
    if Sc_rollup.Staker.equal alice self then Alice
    else if Sc_rollup.Staker.equal bob self then Bob
    else (* By validity of [ongoing_game] RPC. *)
      assert false

  type role = Our_turn | Their_turn

  let turn node_ctxt game players =
    let Sc_rollup.Game.Index.{alice; bob} = players in
    match (node_role node_ctxt players, game.turn) with
    | Alice, Alice -> (Our_turn, bob)
    | Bob, Bob -> (Our_turn, alice)
    | Alice, Bob -> (Their_turn, bob)
    | Bob, Alice -> (Their_turn, bob)

  (** [inject_next_move node_ctxt move] submits an L1 operation to
      issue the next move in the refutation game. [node_ctxt] provides
      the connection to the Tezos node. *)
  let inject_next_move node_ctxt (refutation, opponent) =
    let open Node_context in
    let open Lwt_result_syntax in
    let* source, src_pk, src_sk = Node_context.get_operator_keys node_ctxt in
    let {rollup_address; cctxt; _} = node_ctxt in
    let* _, _, Manager_operation_result {operation_result; _} =
      Client_proto_context.sc_rollup_refute
        cctxt
        ~chain:cctxt#chain
        ~block:cctxt#block
        ~refutation
        ~opponent
        ~source
        ~rollup:rollup_address
        ~src_pk
        ~src_sk
        ~fee_parameter:Configuration.default_fee_parameter
        ()
    in
    let open Apply_results in
    let*! () =
      match operation_result with
      | Applied (Sc_rollup_refute_result _) ->
          Refutation_game_event.refutation_published opponent refutation
      | Failed (Sc_rollup_refute_manager_kind, _errors) ->
          Refutation_game_event.refutation_failed opponent refutation
      | Backtracked (Sc_rollup_refute_result _, _errors) ->
          Refutation_game_event.refutation_backtracked opponent refutation
      | Skipped Sc_rollup_refute_manager_kind ->
          Refutation_game_event.refutation_skipped opponent refutation
    in
    return_unit

  let as_single_tick_dissection dissection =
    match (List.hd dissection, List.last_opt dissection) with
    | Some (Some start_hash, start_tick), Some (_stop_state, stop_tick) ->
        if Sc_rollup.Tick.distance stop_tick start_tick = Z.one then
          Some (start_hash, start_tick)
        else None
    | _ ->
        (* By wellformedness of games returned by the [ongoing_game] RPC. *)
        assert false

  let generate_proof node_ctxt store game start_state =
    let open Lwt_result_syntax in
    let module P = struct
      include PVM

      let context = store

      let state = start_state
    end in
    let*! hash = Layer1.hash_of_level store (Raw_level.to_int32 game.level) in
    let*! inbox = Inbox.inbox_of_hash node_ctxt store hash in
    let*! r = Sc_rollup.Proof.produce (module P) inbox game.level in
    match r with
    | Ok r -> return r
    | Error _err -> failwith "The rollup node cannot produce a proof."

  let new_dissection node_ctxt store last_level ok our_view =
    let open Lwt_result_syntax in
    let _start_hash, start_tick = ok in
    let our_state, stop_tick = our_view in
    (* TODO: #3200
       We should not rely on an hard-coded constant here but instead
       introduce a protocol constant for the maximum number of sections
       in a dissection.
    *)
    let max_number_of_sections = Z.of_int 32 in
    let trace_length = Z.succ (Sc_rollup.Tick.distance stop_tick start_tick) in
    let number_of_sections = Z.min max_number_of_sections trace_length in
    let section_length =
      Z.(max (of_int 1) (div trace_length number_of_sections))
    in
    (* [k] is the number of sections in [rev_dissection]. *)
    let rec make rev_dissection k tick =
      if Z.equal k (Z.pred number_of_sections) then
        return @@ List.rev ((our_state, stop_tick) :: rev_dissection)
      else
        let* r = Interpreter.state_of_tick node_ctxt store tick last_level in
        let hash = Option.map snd r in
        let next_tick = Sc_rollup.Tick.jump tick section_length in
        make ((hash, tick) :: rev_dissection) (Z.succ k) next_tick
    in
    make [] Z.zero start_tick

  (** [generate_from_dissection node_ctxt store game]
      traverses the current [game.dissection] and returns a move which
      performs a new dissection of the execution trace or provide a
      refutation proof to serve as the next move of the [game]. *)
  let generate_next_dissection node_ctxt store game =
    let open Lwt_result_syntax in
    let rec traverse ok = function
      | [] ->
          (* The game invariant states that the dissection from the
             opponent must contain a tick we disagree with. If the
             retrieved game does not respect this, we cannot trust the
             Tezos node we are connected to and prefer to stop here. *)
          assert false
      | (their_hash, tick) :: dissection -> (
          let open Lwt_result_syntax in
          let* our =
            Interpreter.state_of_tick node_ctxt store tick game.level
          in
          match (their_hash, our) with
          | None, None -> assert false
          | Some _, None | None, Some _ ->
              return (ok, (Option.map snd our, tick))
          | Some their_hash, Some (_, our_hash) ->
              if Sc_rollup.State_hash.equal our_hash their_hash then
                traverse (their_hash, tick) dissection
              else return (ok, (Some our_hash, tick)))
    in
    match game.dissection with
    | (Some hash, tick) :: dissection ->
        let* ok, ko = traverse (hash, tick) dissection in
        let choice = snd ok in
        let* dissection = new_dissection node_ctxt store game.level ok ko in
        return (choice, dissection)
    | [] | (None, _) :: _ ->
        (*
             By wellformedness of dissection.
             A dissection always starts with a tick of the form [(Some hash, tick)].
             A dissection always contains strictly more than one element.
          *)
        assert false

  let next_move node_ctxt store game =
    let open Lwt_result_syntax in
    let final_move start_tick =
      let* start_state =
        Interpreter.state_of_tick node_ctxt store start_tick game.level
      in
      match start_state with
      | None -> assert false
      | Some (start_state, _start_hash) ->
          let* proof = generate_proof node_ctxt store game start_state in
          let choice = start_tick in
          return {choice; step = Proof proof}
    in
    match as_single_tick_dissection game.dissection with
    | Some (_start_hash, start_tick) -> final_move start_tick
    | None -> (
        let* choice, dissection =
          generate_next_dissection node_ctxt store game
        in
        match as_single_tick_dissection dissection with
        | Some (_, start_tick) -> final_move start_tick
        | None -> return {choice; step = Dissection dissection})

  let play_next_move node_ctxt store game opponent =
    let open Lwt_result_syntax in
    let* refutation = next_move node_ctxt store game in
    inject_next_move node_ctxt (Some refutation, opponent)

  let try_timeout node_ctxt players =
    let Sc_rollup.Game.Index.{alice; bob} = players in
    let open Node_context in
    let open Lwt_result_syntax in
    let* source, src_pk, src_sk = Node_context.get_operator_keys node_ctxt in
    let {rollup_address; cctxt; _} = node_ctxt in
    let* _, _, Manager_operation_result {operation_result; _} =
      Client_proto_context.sc_rollup_timeout
        cctxt
        ~chain:cctxt#chain
        ~block:cctxt#block
        ~source
        ~alice
        ~bob
        ~rollup:rollup_address
        ~src_pk
        ~src_sk
        ~fee_parameter:Configuration.default_fee_parameter
        ()
    in
    let open Apply_results in
    let*! () =
      match operation_result with
      | Applied (Sc_rollup_timeout_result _) ->
          Refutation_game_event.timeout_published players
      | Failed (Sc_rollup_timeout_manager_kind, _errors) ->
          Refutation_game_event.timeout_failed players
      | Backtracked (Sc_rollup_timeout_result _, _errors) ->
          Refutation_game_event.timeout_backtracked players
      | Skipped Sc_rollup_timeout_manager_kind ->
          Refutation_game_event.timeout_skipped players
    in
    return_unit

  let play node_ctxt store (game, players) =
    match turn node_ctxt game players with
    | Our_turn, opponent -> play_next_move node_ctxt store game opponent
    | Their_turn, _ -> try_timeout node_ctxt players

  let ongoing_game node_ctxt =
    let Node_context.{rollup_address; cctxt; operator; _} = node_ctxt in
    Plugin.RPC.Sc_rollup.ongoing_refutation_game
      cctxt
      (cctxt#chain, cctxt#block)
      rollup_address
      operator
      ()

  let play_opening_move node_ctxt conflict =
    let open Sc_rollup.Refutation_storage in
    inject_next_move node_ctxt (None, conflict.other)

  let start_game_if_conflict node_ctxt =
    let open Lwt_result_syntax in
    let Node_context.{rollup_address; cctxt; operator; _} = node_ctxt in
    let* conflicts =
      Plugin.RPC.Sc_rollup.conflicts
        cctxt
        (cctxt#chain, cctxt#block)
        rollup_address
        operator
        ()
    in
    let play_new_game conflicts =
      match conflicts with
      | [] -> return ()
      | conflict :: _conflicts -> play_opening_move node_ctxt conflict
    in
    play_new_game conflicts

  let process _head node_ctxt store =
    let open Lwt_result_syntax in
    let* game = ongoing_game node_ctxt in
    match game with
    | Some game -> play node_ctxt store game
    | None -> start_game_if_conflict node_ctxt
end
