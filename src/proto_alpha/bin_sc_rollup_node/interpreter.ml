(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 TriliTech <contact@trili.tech>                         *)
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

module type S = sig
  module PVM : Pvm.S

  val metadata : Node_context.t -> Sc_rollup.Metadata.t tzresult Lwt.t

  (** [process_head node_ctxt head] interprets the messages associated
      with a [head] from a chain [event]. This requires the inbox to be updated
      beforehand. *)
  val process_head :
    Node_context.t -> Context.t -> Layer1.head -> unit tzresult Lwt.t

  (** [state_of_tick node_ctxt tick level] returns [Some (state, hash)]
      for a given [tick] if this [tick] happened before
      [level]. Otherwise, returns [None].*)
  val state_of_tick :
    Node_context.t ->
    Sc_rollup.Tick.t ->
    Raw_level.t ->
    (PVM.state * PVM.hash) option tzresult Lwt.t
end

module Make (PVM : Pvm.S) : S with module PVM = PVM = struct
  module PVM = PVM

  module Interpreter_event : Interpreter_event.S with type state := PVM.state =
    Interpreter_event.Make (PVM)

  module Accounted_pvm =
    Fueled_pvm.Make (PVM) (Interpreter_event) (Fuel.Accounted)
  module Free_pvm = Fueled_pvm.Make (PVM) (Interpreter_event) (Fuel.Free)

  (** [metadata node_ctxt] creates a {Sc_rollup.Metadata.t} using the information
      stored in [node_ctxt]. *)
  let metadata (node_ctxt : Node_context.t) =
    let open Lwt_result_syntax in
    let address = node_ctxt.rollup_address in
    let origination_level = node_ctxt.genesis_info.Sc_rollup.Commitment.level in
    return Sc_rollup.Metadata.{address; origination_level}

  let genesis_state block_hash node_ctxt ctxt =
    let open Node_context in
    let open Lwt_result_syntax in
    let* boot_sector =
      Plugin.RPC.Sc_rollup.boot_sector
        node_ctxt.cctxt
        (node_ctxt.cctxt#chain, `Hash (block_hash, 0))
        node_ctxt.rollup_address
    in
    let*! initial_state = PVM.initial_state node_ctxt.context in
    let*! genesis_state = PVM.install_boot_sector initial_state boot_sector in
    let*! ctxt = PVM.State.set ctxt genesis_state in
    return (ctxt, genesis_state)

  let state_of_head node_ctxt ctxt Layer1.{hash; level} =
    let open Lwt_result_syntax in
    let genesis_level =
      Raw_level.to_int32 node_ctxt.Node_context.genesis_info.level
    in
    if level = genesis_level then genesis_state hash node_ctxt ctxt
    else
      let*! state = PVM.State.find ctxt in
      match state with
      | None -> tzfail (Sc_rollup_node_errors.Missing_PVM_state (hash, level))
      | Some state -> return (ctxt, state)

  (** [transition_pvm node_ctxt predecessor head] runs a PVM at the
      previous state from block [predecessor] by consuming as many messages
      as possible from block [head]. *)
  let transition_pvm node_ctxt ctxt predecessor Layer1.{hash; _} =
    let open Lwt_result_syntax in
    (* Retrieve the previous PVM state from store. *)
    let* ctxt, predecessor_state = state_of_head node_ctxt ctxt predecessor in
    let* metadata = metadata node_ctxt in
    let dal_endorsement_lag =
      node_ctxt.protocol_constants.parametric.dal.endorsement_lag
    in
    let* state, num_messages, inbox_level, _fuel =
      Free_pvm.eval_block_inbox
        ~metadata
        ~dal_endorsement_lag
        ~fuel:(Fuel.Free.of_ticks 0L)
        node_ctxt
        hash
        predecessor_state
    in

    (* Write final state to store. *)
    let*! ctxt = PVM.State.set ctxt state in
    let*! context_hash = Context.commit ctxt in
    let*! () = Store.Contexts.add node_ctxt.store hash context_hash in

    (* Compute extra information about the state. *)
    let*! initial_tick = PVM.get_tick predecessor_state in

    let*! () =
      let open Store.StateHistoryRepr in
      let Layer1.{hash = predecessor_hash; _} = predecessor in
      let event =
        {
          tick = initial_tick;
          block_hash = hash;
          predecessor_hash;
          level = inbox_level;
        }
      in
      Store.StateHistory.insert node_ctxt.store event
    in

    let*! last_tick = PVM.get_tick state in
    (* TODO: #2717
       The number of ticks should not be an arbitrarily-sized integer or
       the difference between two ticks should be made an arbitrarily-sized
       integer too.
    *)
    let num_ticks = Sc_rollup.Tick.distance initial_tick last_tick in
    let*! () =
      Store.StateInfo.add
        node_ctxt.store
        hash
        {num_messages; num_ticks; initial_tick}
    in
    (* Produce events. *)
    let*! () =
      Interpreter_event.transitioned_pvm inbox_level state num_messages
    in

    return_unit

  (** [process_head node_ctxt head] runs the PVM for the given head. *)
  let process_head (node_ctxt : Node_context.t) ctxt head =
    let open Lwt_result_syntax in
    let first_inbox_level =
      Raw_level.to_int32 node_ctxt.genesis_info.level |> Int32.succ
    in
    if head.Layer1.level >= first_inbox_level then
      let* predecessor =
        Layer1.get_predecessor node_ctxt.Node_context.l1_ctxt head
      in
      transition_pvm node_ctxt ctxt predecessor head
    else if head.Layer1.level = Raw_level.to_int32 node_ctxt.genesis_info.level
    then
      let* ctxt, state = genesis_state head.hash node_ctxt ctxt in
      (* Write final state to store. *)
      let*! ctxt = PVM.State.set ctxt state in
      let*! context_hash = Context.commit ctxt in
      let*! () = Store.Contexts.add node_ctxt.store head.hash context_hash in

      let*! () =
        Store.StateInfo.add
          node_ctxt.store
          head.hash
          {
            num_messages = Z.zero;
            num_ticks = Z.zero;
            initial_tick = Sc_rollup.Tick.initial;
          }
      in
      return_unit
    else return_unit

  (** [run_for_ticks node_ctxt predecessor_hash hash tick_distance] starts the
      evaluation of the inbox at block [hash] for at most [tick_distance]. *)
  let run_for_ticks node_ctxt predecessor_hash hash level tick_distance =
    let open Lwt_result_syntax in
    let pred_level = Raw_level.to_int32 level |> Int32.pred in
    let* ctxt = Node_context.checkout_context node_ctxt predecessor_hash in
    let* _ctxt, state =
      state_of_head
        node_ctxt
        ctxt
        Layer1.{hash = predecessor_hash; level = pred_level}
    in
    let* metadata = metadata node_ctxt in
    let dal_endorsement_lag =
      node_ctxt.protocol_constants.parametric.dal.endorsement_lag
    in
    let* state, _counter, _level, _fuel =
      Accounted_pvm.eval_block_inbox
        ~metadata
        ~dal_endorsement_lag
        ~fuel:(Fuel.Accounted.of_ticks tick_distance)
        node_ctxt
        hash
        state
    in
    return state

  (** [state_of_tick node_ctxt tick level] returns [Some (state, hash)] for a
      given [tick] if this [tick] happened before [level].  Otherwise, returns
      [None].*)
  let state_of_tick node_ctxt tick level =
    let open Lwt_result_syntax in
    let* closest_event =
      Store.StateHistory.event_of_largest_tick_before
        node_ctxt.Node_context.store
        tick
    in
    match closest_event with
    | None -> return None
    | Some event ->
        if Raw_level.(event.level > level) then return None
        else
          let tick_distance =
            Sc_rollup.Tick.distance tick event.tick |> Z.to_int64
          in
          (* TODO: #3384
             We assume that [StateHistory] correctly stores enough
             events to compute the state of any tick using
             [run_for_ticks]. In particular, this assumes that
             [event.block_hash] is the block where the tick
             happened. We should test that this is always true because
             [state_of_tick] is a critical function. *)
          let* state =
            run_for_ticks
              node_ctxt
              event.predecessor_hash
              event.block_hash
              event.level
              tick_distance
          in
          let*! hash = PVM.state_hash state in
          return (Some (state, hash))
end
