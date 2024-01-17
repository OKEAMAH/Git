(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs <contact@nomadic-labs.com>                *)
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
open Baking_state
open Baking_actions
module Events = Baking_events.State_transitions

let do_nothing state = Lwt.return (state, Do_nothing)

type proposal_acceptance = Invalid | Outdated_proposal | Valid_proposal

let is_acceptable_proposal_for_current_level state
    (proposal : Baking_state.proposal) =
  let open Lwt_syntax in
  let current_round = state.round_state.current_round in
  if Round.(current_round < proposal.block.round) then
    let* () =
      Events.(
        emit unexpected_proposal_round (current_round, proposal.block.round))
    in
    return Invalid
  else if Round.(current_round > proposal.block.round) then
    return Outdated_proposal
  else
    (* current_round = proposal.round *)
    let previous_proposal = state.level_state.latest_proposal in
    if
      Round.(proposal.block.round = previous_proposal.block.round)
      && Block_hash.(proposal.block.hash <> previous_proposal.block.hash)
      && Block_hash.(
           proposal.predecessor.hash = previous_proposal.predecessor.hash)
    then
      (* An existing proposal was found at the same round: the
         proposal is bad and should be punished by the accuser *)
      let* () =
        Events.(
          emit
            proposal_for_round_already_seen
            (proposal.block.hash, current_round, previous_proposal.block.hash))
      in
      return Invalid
    else
      (* current_round = proposal.block.round ∧
         proposal.block.round <> previous_proposal.block.round
         =>
         proposal.block.round > previous_proposal.block.round

         The proposal has the expected round and the previous proposal
         is a predecessor therefore the proposal is valid *)
      return Valid_proposal

let make_consensus_list state proposal =
  let level =
    Raw_level.of_int32 state.level_state.current_level |> function
    | Ok l -> l
    | _ -> assert false
  in
  let round = proposal.block.round in
  let block_payload_hash = proposal.block.payload_hash in
  List.map
    (fun delegate_slot ->
      ( delegate_slot.consensus_key_and_delegate,
        {slot = delegate_slot.first_slot; level; round; block_payload_hash} ))
    (Delegate_slots.own_delegates state.level_state.delegate_slots)

(* If we do not have any slots, we won't inject any operation but we
   will still participate to determine an elected block *)
let prepare_preattest_action state proposal =
  let open Lwt_syntax in
  let preattestations : (consensus_key_and_delegate * consensus_content) list =
    make_consensus_list state proposal
  in
  return (Prepare_preattestations {preattestations})

let update_proposal ~is_proposal_applied state proposal =
  let open Lwt_syntax in
  let* () = Events.(emit updating_latest_proposal proposal.block.hash) in
  let prev_proposal = state.level_state.latest_proposal in
  let is_latest_proposal_applied =
    (* mark as applied if it is indeed applied or if this specific proposal was
       already marked as applied *)
    is_proposal_applied
    || prev_proposal.block.hash = proposal.block.hash
       && state.level_state.is_latest_proposal_applied
  in
  let new_level_state =
    {
      state.level_state with
      is_latest_proposal_applied;
      latest_proposal = proposal;
    }
  in
  return {state with level_state = new_level_state}

let may_update_proposal ~is_proposal_applied state (proposal : proposal) =
  assert (
    Compare.Int32.(
      state.level_state.latest_proposal.block.shell.level
      = proposal.block.shell.level)) ;
  if
    Round.(state.level_state.latest_proposal.block.round < proposal.block.round)
  then update_proposal ~is_proposal_applied state proposal
  else Lwt.return state

let preattest state proposal =
  let open Lwt_syntax in
  if Baking_state.is_first_block_in_protocol proposal then
    (* We do not preattest the first transition block *)
    let new_state = update_current_phase state Idle in
    return (new_state, Do_nothing)
  else
    let* () = Events.(emit attempting_preattest_proposal proposal.block.hash) in
    let new_state =
      (* We have detected a new proposal that needs to be preattested.
         We switch to the `Awaiting_preattestations` phase. *)
      update_current_phase state Awaiting_preattestations
    in
    let* preattest_action = prepare_preattest_action state proposal in
    return (new_state, preattest_action)

let extract_pqc state (new_proposal : proposal) =
  match new_proposal.block.prequorum with
  | None -> None
  | Some pqc ->
      let add_voting_power acc (op : Kind.preattestation Operation.t) =
        let open Protocol.Alpha_context.Operation in
        let {
          shell = _;
          protocol_data = {contents = Single (Preattestation {slot; _}); _};
          _;
        } =
          op
        in
        match
          Delegate_slots.voting_power state.level_state.delegate_slots ~slot
        with
        | None ->
            (* cannot happen if the map is correctly populated *)
            acc
        | Some attesting_power -> acc + attesting_power
      in
      let voting_power =
        List.fold_left add_voting_power 0 pqc.preattestations
      in
      let consensus_threshold =
        state.global_state.constants.parametric.consensus_threshold
      in
      if Compare.Int.(voting_power >= consensus_threshold) then
        Some (pqc.preattestations, pqc.round)
      else None

let may_update_attestable_payload_with_internal_pqc state
    (new_proposal : proposal) =
  match
    (new_proposal.block.prequorum, state.level_state.attestable_payload)
  with
  | None, _ ->
      (* The proposal does not contain a PQC: no need to update *)
      state
  | Some {round = new_round; _}, Some {prequorum = {round = old_round; _}; _}
    when Round.(new_round < old_round) ->
      (* The proposal pqc is outdated, do not update *)
      state
  | Some better_prequorum, _ ->
      assert (
        Block_payload_hash.(
          better_prequorum.block_payload_hash = new_proposal.block.payload_hash)) ;
      assert (
        Compare.Int32.(better_prequorum.level = new_proposal.block.shell.level)) ;
      let new_attestable_payload =
        Some {proposal = new_proposal; prequorum = better_prequorum}
      in
      let new_level_state =
        {state.level_state with attestable_payload = new_attestable_payload}
      in
      {state with level_state = new_level_state}

let has_already_been_handled state new_proposal =
  let current_proposal = state.level_state.latest_proposal in
  Block_hash.(current_proposal.block.hash = new_proposal.block.hash)
  && state.level_state.is_latest_proposal_applied

let rec handle_proposal ~is_proposal_applied state (new_proposal : proposal) =
  let open Lwt_syntax in
  (* TODO: https://gitlab.com/tezos/tezos/-/issues/6648
     Do not handle proposals that have been applied already.
  *)
  (* We need to avoid to send preattestations, if we are in phases were
     preattestations have been sent already. This is needed to avoid switching
     back from Awaiting_attestations to Awaiting_preattestations. *)
  let may_preattest state proposal =
    match state.round_state.current_phase with
    | Idle -> preattest state proposal
    | _ -> do_nothing state
  in
  let current_level = state.level_state.current_level in
  let new_proposal_level = new_proposal.block.shell.level in
  let current_proposal = state.level_state.latest_proposal in
  if
    is_proposal_applied
    && Block_hash.(current_proposal.block.hash = new_proposal.block.hash)
  then
    let new_level_state =
      {state.level_state with is_latest_proposal_applied = true}
    in
    let new_state = {state with level_state = new_level_state} in
    do_nothing new_state
  else if Compare.Int32.(current_level > new_proposal_level) then
    (* The baker is ahead, a reorg may have happened. Do nothing:
       wait for the node to send us the branch's head. This new head
       should have a fitness that is greater than our current
       proposal and thus, its level should be at least the same as
       our current proposal's level. *)
    let* () =
      Events.(emit baker_is_ahead_of_node (current_level, new_proposal_level))
    in
    do_nothing state
  else if Compare.Int32.(current_level = new_proposal_level) then
    if
      (* The received head is a new proposal for the current level:
         let's check if it's a valid one for us. *)
      Block_hash.(
        current_proposal.predecessor.hash <> new_proposal.predecessor.hash)
    then
      let* () =
        Events.(
          emit
            new_proposal_is_on_another_branch
            (current_proposal.predecessor.hash, new_proposal.predecessor.hash))
      in
      may_switch_branch ~is_proposal_applied state new_proposal
    else
      let* proposal_acceptance =
        is_acceptable_proposal_for_current_level state new_proposal
      in
      match proposal_acceptance with
      | Invalid ->
          (* The proposal is invalid: we ignore it *)
          let* () = Events.(emit skipping_invalid_proposal ()) in
          do_nothing state
      | Outdated_proposal ->
          (* Check whether we need to update our attestable payload  *)
          let state =
            may_update_attestable_payload_with_internal_pqc state new_proposal
          in
          (* The proposal is outdated: we update to be able to extract
             its included attestations but we do not attest it *)
          let* () = Events.(emit outdated_proposal new_proposal.block.hash) in
          let* state =
            may_update_proposal ~is_proposal_applied state new_proposal
          in
          do_nothing state
      | Valid_proposal -> (
          (* Valid_proposal => proposal.round = current_round *)
          (* Check whether we need to update our attestable payload  *)
          let new_state =
            may_update_attestable_payload_with_internal_pqc state new_proposal
          in
          let* new_state =
            may_update_proposal ~is_proposal_applied new_state new_proposal
          in
          (* The proposal is valid but maybe we already locked on a payload *)
          match new_state.level_state.locked_round with
          | Some locked_round -> (
              if
                Block_payload_hash.(
                  locked_round.payload_hash = new_proposal.block.payload_hash)
              then
                (* when the new head has the same payload as our
                   [locked_round], we accept it and preattest *)
                may_preattest new_state new_proposal
              else
                (* The payload is different *)
                match new_proposal.block.prequorum with
                | Some {round; _} when Round.(locked_round.round < round) ->
                    (* This PQC is above our locked_round, we can preattest it *)
                    may_preattest new_state new_proposal
                | _ ->
                    (* We shouldn't preattest this proposal, but we
                       should at least watch (pre)quorums events on it
                       but only when it is applied otherwise we await
                       for the proposal to be applied. *)
                    let new_state =
                      update_current_phase new_state Awaiting_preattestations
                    in
                    return (new_state, Watch_proposal))
          | None ->
              (* Otherwise, we did not lock on any payload, thus we can
                 preattest it *)
              may_preattest new_state new_proposal)
  else
    (* Last case: new_proposal_level > current_level *)
    (* Possible scenarios:
       - we received a block for a next level
       - we received our own block
         This is where we update our [level_state] (and our [round_state]) *)
    let* () = Events.(emit new_head_with_increasing_level ()) in
    let new_level = new_proposal.block.shell.level in
    let compute_new_state ~current_round ~delegate_slots
        ~next_level_delegate_slots =
      let round_state =
        {current_round; current_phase = Idle; delayed_quorum = None}
      in
      let level_state =
        {
          current_level = new_level;
          latest_proposal = new_proposal;
          is_latest_proposal_applied = is_proposal_applied;
          (* Unlock values *)
          locked_round = None;
          attestable_payload = None;
          elected_block = None;
          delegate_slots;
          next_level_delegate_slots;
          next_level_proposed_round = None;
          next_forged_block = None;
        }
      in
      (* recursive call with the up-to-date state to handle the new
         level proposals *)
      handle_proposal
        ~is_proposal_applied
        {state with level_state; round_state}
        new_proposal
    in
    let action =
      Update_to_level {new_level_proposal = new_proposal; compute_new_state}
    in
    return (state, action)

and may_switch_branch ~is_proposal_applied state new_proposal =
  let open Lwt_syntax in
  let switch_branch state =
    let* () = Events.(emit switching_branch ()) in
    (* If we are on a different branch, we also need to update our
       [round_state] accordingly.
       The recursive call to [handle_proposal] cannot end up
       with an invalid proposal as it's on a different branch, thus
       there is no need to backtrack to the former state as the new
       proposal must end up being the new [latest_proposal]. That's
       why we update it here. *)
    let round_update =
      {
        Baking_actions.new_round_proposal = new_proposal;
        handle_proposal =
          (fun state -> handle_proposal ~is_proposal_applied state new_proposal);
      }
    in
    let* new_state = update_proposal ~is_proposal_applied state new_proposal in
    (* TODO if the branch proposal is outdated, we should
       trigger an [End_of_round] to participate *)
    return (new_state, Synchronize_round round_update)
  in
  let current_attestable_payload = state.level_state.attestable_payload in
  match (current_attestable_payload, new_proposal.block.prequorum) with
  | None, Some _ | None, None ->
      let* () = Events.(emit branch_proposal_has_better_fitness ()) in
      (* The new branch contains a PQC (and we do not) or a better
         fitness, we switch. *)
      switch_branch state
  | Some _, None ->
      (* We have a better PQC, we don't switch as we are able to
         propose a better chain if we stay on our current one. *)
      let* () = Events.(emit branch_proposal_has_no_prequorum ()) in
      do_nothing state
  | Some {prequorum = current_pqc; _}, Some new_pqc ->
      if Round.(current_pqc.round > new_pqc.round) then
        let* () = Events.(emit branch_proposal_has_lower_prequorum ()) in
        (* The other's branch PQC is lower than ours, do not
           switch *)
        do_nothing state
      else if Round.(current_pqc.round < new_pqc.round) then
        let* () = Events.(emit branch_proposal_has_better_prequorum ()) in
        (* Their PQC is better than ours: we switch *)
        switch_branch state
      else
        (* current_pqc.round = new_pqc *)
        (* There is a PQC on two branches with the same round and
           the same level but not the same predecessor : it's
           impossible unless if there was some double-baking. This
           shouldn't happen but do nothing anyway. *)
        let* () = Events.(emit branch_proposal_has_same_prequorum ()) in
        do_nothing state

(* Create a fresh block proposal containing the  current operations of
   the mempool in [state] and the additional  [attestations] and
   [dal_attestations] for [delegate] at round [round]. *)
let prepare_block_to_bake ~attestations ~dal_attestations ?last_proposal
    ~(predecessor : block_info) state delegate round =
  (* The block to bake embeds the operations gathered by the
     worker. However, consensus operations that are not relevant for
     this block are filtered out. In the case of proposing a new fresh
     block, the block is supposed to carry only attestations for the
     previous level. *)
  let open Lwt_syntax in
  let operation_pool =
    (* 1. Fetch operations from the mempool. *)
    let current_mempool =
      let pool =
        Operation_worker.get_current_operations
          state.global_state.operation_worker
      in
      (* Considered the operations in the previous proposal as well *)
      match last_proposal with
      | Some proposal ->
          let {
            Operation_pool.votes_payload;
            anonymous_payload;
            managers_payload;
          } =
            proposal.payload
          in
          List.fold_left
            Operation_pool.add_operations
            pool
            [votes_payload; anonymous_payload; managers_payload]
      | None -> pool
    in
    (* 2. Filter and only retain relevant attestations. *)
    let relevant_consensus_operations =
      let attestation_filter =
        {
          Operation_pool.level = predecessor.shell.level;
          round = predecessor.round;
          payload_hash = predecessor.payload_hash;
        }
      in
      Operation_pool.filter_with_relevant_consensus_ops
        ~attestation_filter
        ~preattestation_filter:None
        current_mempool.consensus
    in
    let filtered_mempool =
      {current_mempool with consensus = relevant_consensus_operations}
    in
    (* 3. Add the additional given [attestations] and [dal_attestations].
         N.b. this is a set: there won't be duplicates *)
    let pool =
      Operation_pool.add_operations
        filtered_mempool
        (List.map Operation.pack attestations)
    in
    Operation_pool.add_operations
      pool
      (List.map Operation.pack dal_attestations)
  in
  let kind = Fresh operation_pool in
  let* () = Events.(emit preparing_fresh_block (delegate, round)) in
  let force_apply =
    state.global_state.config.force_apply || Round.(round <> zero)
    (* This is used as a safety net by applying blocks on round > 0, in case
       validation-only did not produce a correct round-0 block. *)
  in
  let block_to_bake = {predecessor; round; delegate; kind; force_apply} in
  let updated_state = update_current_phase state Idle in
  return (Prepare_block {block_to_bake; updated_state})

let forge_fresh_block_action ~attestations ~dal_attestations ?last_proposal
    ~(predecessor : block_info) state delegate =
  prepare_block_to_bake
    ~attestations
    ~dal_attestations
    ?last_proposal
    ~predecessor
    state
    delegate
    Round.zero

(** Create an inject action that will inject either a fresh block or the pre-emptively
    forged block if it exists. *)
let propose_fresh_block_action ~attestations ~dal_attestations ?last_proposal
    ~(predecessor : block_info) state delegate round =
  (* TODO check if there is a trace where we could not have updated the level *)
  let open Lwt_syntax in
  match state.level_state.next_forged_block with
  | Some
      ({delegate; round; signed_block_header = _; operations = _; _} as
      signed_block) ->
      let* () =
        Events.(emit found_preemptively_forged_block (delegate, round))
      in
      let updated_state =
        {
          state with
          level_state = {state.level_state with next_forged_block = None};
        }
      in
      return (Inject_block {prepared_block = signed_block; updated_state})
  | None ->
      prepare_block_to_bake
        ~attestations
        ~dal_attestations
        ?last_proposal
        ~predecessor
        state
        delegate
        round

let propose_block_action state delegate round ~last_proposal =
  let open Lwt_syntax in
  (* Possible cases:
     1. There was a proposal but the PQC was not reached.
     2. There was a proposal and the PQC was reached. We repropose the
     [attestable_payload] if it exists, not the [locked_round] as it
     may be older. *)
  match state.level_state.attestable_payload with
  | None ->
      let* () = Events.(emit no_attestable_payload_fresh_block ()) in
      (* For case 1, we may re-inject with the same payload or a fresh
         one. We make the choice of baking a fresh one: the previous
         proposal may have been rejected because the block may have been
         valid but may be considered "bad" (censored operations, empty
         block, etc.) by the other validators. *)
      (* Invariant: there is no locked round if there is no attestable
         payload *)
      assert (state.level_state.locked_round = None) ;
      let attestations_in_last_proposal = last_proposal.block.quorum in
      (* Also insert the DAL attestations from the proposal, because the mempool
         may not contain them anymore *)
      (* TODO: https://gitlab.com/tezos/tezos/-/issues/4671
         The block may therefore contain multiple attestations for the same delegate. *)
      let dal_attestations_in_last_proposal =
        last_proposal.block.dal_attestations
      in
      propose_fresh_block_action
        ~attestations:attestations_in_last_proposal
        ~dal_attestations:dal_attestations_in_last_proposal
        state
        ~last_proposal:last_proposal.block
        ~predecessor:last_proposal.predecessor
        delegate
        round
  | Some {proposal; prequorum} ->
      let* () = Events.(emit repropose_block proposal.block.payload_hash) in
      (* For case 2, we re-inject the same block as [attestable_round]
         but we may add some left-overs attestations. Therefore, the
         operations we need to include are:
         - the proposal's included attestations
         - the potential missing new attestations for the
           previous block
         - the PQC of the attestable payload *)
      let consensus_operations =
        (* Fetch preattestations and attestations from the mempool
           (that could be missing from the proposal), filter, then add
           consensus operations of the proposal itself, and convert
           into [packed_operation trace]. *)
        let mempool_consensus_operations =
          (Operation_worker.get_current_operations
             state.global_state.operation_worker)
            .consensus
        in
        let all_consensus_operations =
          (* Add the proposal and pqc consensus operations to the
             mempool *)
          List.fold_left
            (fun set op -> Operation_pool.Operation_set.add op set)
            mempool_consensus_operations
            ((List.map Operation.pack proposal.block.quorum
             @ List.map Operation.pack prequorum.preattestations)
            @ List.map Operation.pack proposal.block.dal_attestations)
        in
        let attestation_filter =
          {
            Operation_pool.level = proposal.predecessor.shell.level;
            round = proposal.predecessor.round;
            payload_hash = proposal.predecessor.payload_hash;
          }
        in
        let preattestation_filter =
          Some
            {
              Operation_pool.level = prequorum.level;
              round = prequorum.round;
              payload_hash = prequorum.block_payload_hash;
            }
        in
        Operation_pool.(
          filter_with_relevant_consensus_ops
            ~attestation_filter
            ~preattestation_filter
            all_consensus_operations
          |> Operation_set.elements)
      in
      let payload_hash = proposal.block.payload_hash in
      let payload_round = proposal.block.payload_round in
      let payload = proposal.block.payload in
      let kind =
        Reproposal {consensus_operations; payload_hash; payload_round; payload}
      in
      let force_apply =
        true
        (* This is used as a safety net by applying blocks on round > 0, in case
           validation-only did not produce a correct round-0 block. *)
      in
      let block_to_bake =
        {predecessor = proposal.predecessor; round; delegate; kind; force_apply}
      in
      let updated_state = update_current_phase state Idle in
      return (Prepare_block {block_to_bake; updated_state})

let end_of_round state current_round =
  let open Lwt_syntax in
  let new_round = Round.succ current_round in
  let new_round_state = {state.round_state with current_round = new_round} in
  let new_state = {state with round_state = new_round_state} in
  (* we need to check if we need to bake for this round or not *)
  match
    round_proposer new_state ~level:`Current new_state.round_state.current_round
  with
  | None ->
      let* () =
        Events.(
          emit
            no_proposal_slot
            (current_round, state.level_state.current_level, new_round))
      in
      (* We don't have any delegate that may propose a new block for
         this round -- We will wait for preattestations when the next
         level block arrive. Meanwhile, we are idle *)
      let new_state = update_current_phase new_state Idle in
      do_nothing new_state
  | Some {consensus_key_and_delegate; _} ->
      let latest_proposal = state.level_state.latest_proposal in
      if Baking_state.is_first_block_in_protocol latest_proposal then
        (* Do not inject a block for the previous protocol! (Let the
           baker of the previous protocol do it.) *)
        do_nothing new_state
      else
        let* () =
          Events.(
            emit
              proposal_slot
              ( current_round,
                state.level_state.current_level,
                new_round,
                consensus_key_and_delegate ))
        in
        (* We have a delegate, we need to determine what to inject *)
        let* action =
          propose_block_action
            new_state
            consensus_key_and_delegate
            new_round
            ~last_proposal:state.level_state.latest_proposal
        in
        return (new_state, action)

let time_to_forge_block state =
  let open Lwt_syntax in
  let at_round = Round.zero in
  let round_proposer_opt = round_proposer state ~level:`Next at_round in
  match (state.level_state.elected_block, round_proposer_opt) with
  | None, _ | _, None ->
      (* Unreachable: the [Time_to_forge_Block] event can only be
         triggered when we have a slot and an elected block *)
      assert false
  | Some elected_block, Some {consensus_key_and_delegate; _} ->
      let attestations = elected_block.attestation_qc in
      let dal_attestations =
        (* Unlike proposal attestations, we don't watch and store DAL attestations for
           each proposal, we'll retrieve them from the mempool *)
        []
      in
      let* action =
        forge_fresh_block_action
          ~attestations
          ~dal_attestations
          ~predecessor:elected_block.proposal.block
          state
          consensus_key_and_delegate
      in
      return (state, action)

let time_to_bake_at_next_level state at_round =
  let open Lwt_syntax in
  (* It is now time to update the state level *)
  (* We need to keep track for which block we have 2f+1 *attestations*, that is,
     which will become the new predecessor_block *)
  (* Invariant: attestable_round >= round(elected block) >= locked_round *)
  let round_proposer_opt = round_proposer state ~level:`Next at_round in
  match (state.level_state.elected_block, round_proposer_opt) with
  | None, _ | _, None ->
      (* Unreachable: the [Time_to_bake_next_level] event can only be
         triggered when we have a slot and an elected block *)
      assert false
  | Some elected_block, Some {consensus_key_and_delegate; _} ->
      let attestations = elected_block.attestation_qc in
      let dal_attestations =
        (* Unlike proposal attestations, we don't watch and store DAL attestations for
           each proposal, we'll retrieve them from the mempool *)
        []
      in
      let new_level_state =
        {state.level_state with next_level_proposed_round = Some at_round}
      in
      let new_state = {state with level_state = new_level_state} in
      let* action =
        propose_fresh_block_action
          ~attestations
          ~dal_attestations
          ~predecessor:elected_block.proposal.block
          new_state
          consensus_key_and_delegate
          at_round
      in
      return (new_state, action)

let update_locked_round state round payload_hash =
  let locked_round = Some {payload_hash; round} in
  let new_level_state = {state.level_state with locked_round} in
  {state with level_state = new_level_state}

let prepare_attest_action state proposal =
  let open Lwt_syntax in
  let attestations : (consensus_key_and_delegate * consensus_content) list =
    make_consensus_list state proposal
  in
  return (Prepare_attestations {attestations})

let prequorum_reached_when_awaiting_preattestations state candidate
    preattestations =
  let open Lwt_syntax in
  let latest_proposal = state.level_state.latest_proposal in
  if Block_hash.(candidate.Operation_worker.hash <> latest_proposal.block.hash)
  then
    let* () =
      Events.(
        emit
          unexpected_prequorum_received
          (candidate.hash, latest_proposal.block.hash))
    in
    do_nothing state
  else
    let prequorum =
      {
        level = latest_proposal.block.shell.level;
        round = latest_proposal.block.round;
        block_payload_hash = latest_proposal.block.payload_hash;
        preattestations
        (* preattestations may be nil when [consensus_threshold] is 0 *);
      }
    in
    let new_attestable_payload = {proposal = latest_proposal; prequorum} in
    let new_level_state =
      let level_state_with_new_payload =
        {
          state.level_state with
          attestable_payload = Some new_attestable_payload;
        }
      in
      match state.level_state.attestable_payload with
      | None -> level_state_with_new_payload
      | Some attestable_payload ->
          if
            Round.(
              attestable_payload.prequorum.round
              < new_attestable_payload.prequorum.round)
          then level_state_with_new_payload
          else state.level_state
    in
    let new_state = {state with level_state = new_level_state} in
    let new_state =
      update_locked_round
        new_state
        latest_proposal.block.round
        latest_proposal.block.payload_hash
    in
    let new_state = update_current_phase new_state Awaiting_attestations in
    let* attest_action = prepare_attest_action new_state latest_proposal in
    return (new_state, attest_action)

let quorum_reached_when_waiting_attestations state candidate attestation_qc =
  let open Lwt_syntax in
  let latest_proposal = state.level_state.latest_proposal in
  let is_latest_proposal_applied =
    state.level_state.is_latest_proposal_applied
  in
  if Block_hash.(candidate.Operation_worker.hash <> latest_proposal.block.hash)
  then
    let* () =
      Events.(
        emit
          unexpected_quorum_received
          (candidate.hash, latest_proposal.block.hash))
    in
    do_nothing state
  else
    let new_round_state, new_level_state =
      match state.level_state.elected_block with
      | None when is_latest_proposal_applied ->
          (* The elected proposal has been applied. Record the elected block
             and transition to the Idle phase, as there is nothing left to do.
          *)
          let elected_block =
            Some {proposal = latest_proposal; attestation_qc}
          in
          let new_level_state = {state.level_state with elected_block} in
          let new_round_state = {state.round_state with current_phase = Idle} in
          (new_round_state, new_level_state)
      | None ->
          (* A quorum has been reached, but the elected proposal has not been
             applied yet by the node. Transition in the `Awaiting_application`
             phase, and do not save the elected block in the state. Instead,
             keep track that an early quorum has been reached at this round.
             This avoids the proposer of a block at the next level to inject a
             proposal before the node has been applied the proposal elected at
             the current level. *)
          let new_round_state =
            {
              state.round_state with
              current_phase = Awaiting_application;
              delayed_quorum = Some attestation_qc;
            }
          in
          (new_round_state, state.level_state)
      | Some _ ->
          (* If we already have an elected block, do not update it: the
             earlier, the better. We do not need to record the quorum either,
             as this won't be used to elect a new block. *)
          (state.round_state, state.level_state)
    in
    let new_state =
      {state with round_state = new_round_state; level_state = new_level_state}
    in
    do_nothing new_state

let handle_expected_applied_proposal (state : Baking_state.t) =
  let new_level_state =
    {state.level_state with is_latest_proposal_applied = true}
  in
  (* This code is triggered only when in the `Awaiting_application`phase, which
     in turn is reached only if a quorum has been met but the
     block has not been applied by the node. As a consequence, the only
     thing that is left to do at this stage is to update the elected block
     and transition to the Idle phase, as there is nothing left to do. *)
  let new_state = {state with level_state = new_level_state} in
  let new_state =
    match new_state.level_state.elected_block with
    | None ->
        (* We do not have an elected block for this level. We need to update it. *)
        let latest_proposal = state.level_state.latest_proposal in
        let attestation_qc =
          match state.round_state.delayed_quorum with
          | None -> assert false
          | Some attestation_qc -> attestation_qc
        in
        let elected_block = Some {proposal = latest_proposal; attestation_qc} in
        let new_level_state = {state.level_state with elected_block} in
        {state with level_state = new_level_state}
    | Some _ ->
        (* We already have an elected block at this level. We do not need to update
           it. The earlier, the better. *)
        new_state
  in
  let new_state = update_current_phase new_state Idle in
  do_nothing new_state

(* Hypothesis:
   - The state is not to be modified outside this module
     (NB: there are exceptions in Baking_actions: the corner cases
     [update_to_level] and [synchronize_round] and
     the hack used by [inject_block])

   - new_proposal's received blocks are expected to belong to our current
     round

   - [Prequorum_reached] can only be received when we've seen a new head

   - [Quorum_reached] can only be received when we've seen a
     [Prequorum_reached] *)
let step (state : Baking_state.t) (event : Baking_state.event) :
    (Baking_state.t * Baking_actions.t) Lwt.t =
  let open Lwt_syntax in
  let phase = state.round_state.current_phase in
  let* () = Events.(emit step_current_phase (phase, event)) in
  match (phase, event) with
  (* Handle timeouts *)
  | _, Timeout (End_of_round {ending_round}) ->
      (* If the round is ending, stop everything currently going on and
         increment the round. *)
      end_of_round state ending_round
  | _, Ready_to_inject forge_event -> (
      match forge_event with
      | Preattestations_ready signed_preattestations ->
          Lwt.return (state, Inject_preattestations {signed_preattestations})
      | Attestations_ready signed_attestations ->
          Lwt.return (state, Inject_attestations {signed_attestations})
      | Dal_attestations_ready signed_dal_attestations ->
          Lwt.return (state, Inject_dal_attestations {signed_dal_attestations})
      | Block_ready prepared_block ->
          Lwt.return
            (state, Inject_block {prepared_block; updated_state = state}))
  | _, Timeout (Time_to_bake_next_level {at_round}) ->
      (* If it is time to bake the next level, stop everything currently
         going on and propose the next level block *)
      time_to_bake_at_next_level state at_round
  | _, Timeout Time_to_forge_block -> time_to_forge_block state
  | Idle, New_head_proposal proposal ->
      let* () =
        Events.(
          emit
            new_head
            ( proposal.block.hash,
              proposal.block.shell.level,
              proposal.block.round ))
      in
      handle_proposal ~is_proposal_applied:true state proposal
  | Awaiting_application, New_head_proposal proposal ->
      if
        Block_hash.(
          state.level_state.latest_proposal.block.hash <> proposal.block.hash)
      then
        let* () =
          Events.(
            emit
              new_head
              ( proposal.block.hash,
                proposal.block.shell.level,
                proposal.block.round ))
        in
        let* () =
          Events.(emit unexpected_new_head_while_waiting_for_application ())
        in
        handle_proposal ~is_proposal_applied:true state proposal
      else
        let* () =
          Events.(emit applied_expected_proposal_received proposal.block.hash)
        in
        handle_expected_applied_proposal state
  | Awaiting_attestations, New_head_proposal proposal
  | Awaiting_preattestations, New_head_proposal proposal ->
      let* () =
        Events.(
          emit
            new_head
            ( proposal.block.hash,
              proposal.block.shell.level,
              proposal.block.round ))
      in
      let* () = Events.(emit new_head_while_waiting_for_qc ()) in
      handle_proposal ~is_proposal_applied:true state proposal
  | Idle, New_valid_proposal proposal ->
      let* () =
        Events.(
          emit
            new_valid_proposal
            ( proposal.block.hash,
              proposal.block.shell.level,
              proposal.block.round ))
      in
      handle_proposal ~is_proposal_applied:false state proposal
  | Awaiting_application, New_valid_proposal proposal
  | Awaiting_attestations, New_valid_proposal proposal
  | Awaiting_preattestations, New_valid_proposal proposal ->
      let* () =
        Events.(
          emit
            new_valid_proposal
            ( proposal.block.hash,
              proposal.block.shell.level,
              proposal.block.round ))
      in
      if has_already_been_handled state proposal then
        let* () = Events.(emit valid_proposal_received_after_application ()) in
        do_nothing state
      else
        let* () = Events.(emit new_valid_proposal_while_waiting_for_qc ()) in
        handle_proposal ~is_proposal_applied:false state proposal
  | Awaiting_preattestations, Prequorum_reached (candidate, preattestation_qc)
    ->
      prequorum_reached_when_awaiting_preattestations
        state
        candidate
        preattestation_qc
  | Awaiting_attestations, Quorum_reached (candidate, attestation_qc) ->
      quorum_reached_when_waiting_attestations state candidate attestation_qc
  (* Unreachable cases *)
  | Idle, (Prequorum_reached _ | Quorum_reached _)
  | Awaiting_preattestations, Quorum_reached _
  | (Awaiting_application | Awaiting_attestations), Prequorum_reached _
  | Awaiting_application, Quorum_reached _ ->
      (* This cannot/should not happen *)
      do_nothing state
