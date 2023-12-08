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
module Events = Baking_events.Actions

type inject_block_kind =
  | Forge_and_inject of block_to_bake
  | Inject_only of prepared_block

type action =
  | Do_nothing
  | Prepare_block of {block_to_bake : block_to_bake}
  | Inject_block of {prepared_block : prepared_block}
  | Prepare_preattestations of {
      preattestations : (consensus_key_and_delegate * consensus_content) list;
    }
  | Inject_preattestation of {
      signed_preattestation :
        consensus_key_and_delegate * packed_operation * int32 * Round.t;
    }
  | Prepare_attestations of {
      attestations : (consensus_key_and_delegate * consensus_content) list;
    }
  | Inject_attestation of {
      signed_attestation :
        consensus_key_and_delegate * packed_operation * int32 * Round.t;
    }
  | Inject_dal_attestation of {
      signed_dal_attestation :
        (consensus_key * public_key_hash)
        * packed_operation
        * Dal.Attestation.t
        * int32;
    }
  | Update_to_level of level_update
  | Synchronize_round of round_update
  | Watch_proposal

and level_update = {
  new_level_proposal : proposal;
  compute_new_state :
    current_round:Round.t ->
    delegate_slots:delegate_slots ->
    next_level_delegate_slots:delegate_slots ->
    (state * action) Lwt.t;
}

and round_update = {
  new_round_proposal : proposal;
  handle_proposal : state -> (state * action) Lwt.t;
}

type t = action

let pp_action fmt = function
  | Do_nothing -> Format.fprintf fmt "do nothing"
  | Prepare_block _ -> Format.fprintf fmt "prepare block"
  | Inject_block _ -> Format.fprintf fmt "inject block"
  | Prepare_preattestations _ -> Format.fprintf fmt "prepare preattestations"
  | Inject_preattestation _ -> Format.fprintf fmt "inject preattestation"
  | Prepare_attestations _ -> Format.fprintf fmt "prepare attestations"
  | Inject_attestation _ -> Format.fprintf fmt "inject attestation"
  | Inject_dal_attestation _ -> Format.fprintf fmt "inject DAL attestation"
  | Update_to_level _ -> Format.fprintf fmt "update to level"
  | Synchronize_round _ -> Format.fprintf fmt "synchronize round"
  | Watch_proposal -> Format.fprintf fmt "watch proposal"

let inject_block state prepared_block =
  let open Lwt_result_syntax in
  let {signed_block_header; round; delegate; operations; baking_votes} =
    prepared_block
  in
  (* Cache last per-block votes to use in case of vote file errors *)
  let new_state =
    {
      state with
      global_state =
        {
          state.global_state with
          config =
            {
              state.global_state.config with
              per_block_votes =
                {
                  state.global_state.config.per_block_votes with
                  liquidity_baking_vote = baking_votes.liquidity_baking_vote;
                  adaptive_issuance_vote = baking_votes.adaptive_issuance_vote;
                };
            };
        };
    }
  in
  let inject_block () =
    let*! () =
      Events.(
        emit injecting_block (signed_block_header.shell.level, round, delegate))
    in
    let* bh =
      Node_rpc.inject_block
        state.global_state.cctxt
        ~force:state.global_state.config.force
        ~chain:(`Hash state.global_state.chain_id)
        signed_block_header
        operations
    in
    let*! () =
      Events.(
        emit
          block_injected
          (bh, signed_block_header.shell.level, round, delegate))
    in
    return_unit
  in
  let now = Time.System.now () in
  let block_time =
    Time.System.of_protocol_exn signed_block_header.shell.timestamp
  in
  (* Blocks might be ready before their actual timestamp: when this
     happens, we wait asynchronously until our clock reaches the
     block's timestamp before injecting. *)
  let* () =
    let delay = Ptime.diff block_time now in
    if Ptime.Span.(compare delay zero < 0) then inject_block ()
    else
      let*! () =
        Events.(
          emit
            delayed_block_injection
            (delay, signed_block_header.shell.level, round, delegate))
      in
      Lwt.dont_wait
        (fun () ->
          let*! () = Lwt_unix.sleep (Ptime.Span.to_float_s delay) in
          let*! _ = inject_block () in
          Lwt.return_unit)
        (fun _exn -> ()) ;
      return_unit
  in
  return new_state

let inject_consensus_vote state signed_operation kind =
  let open Lwt_result_syntax in
  let cctxt = state.global_state.cctxt in
  let chain_id = state.global_state.chain_id in
  let fail_inject_event, injected_event =
    match kind with
    | `Preattestation ->
        (Events.failed_to_inject_preattestation, Events.preattestation_injected)
    | `Attestation ->
        (Events.failed_to_inject_attestation, Events.attestation_injected)
  in
  (* TODO: add a RPC to inject multiple operations *)
  let delegate, operation, level, round = signed_operation in
  Lwt.dont_wait
    (fun () ->
      let*! (_ign : unit tzresult) =
        protect
          ~on_error:(fun err ->
            let*! () = Events.(emit fail_inject_event (delegate, err)) in
            return_unit)
          (fun () ->
            let* oph =
              Node_rpc.inject_operation cctxt ~chain:(`Hash chain_id) operation
            in
            let*! () =
              Events.(emit injected_event (oph, delegate, level, round))
            in
            return_unit)
      in
      Lwt.return_unit)
    (fun _exn -> ()) ;
  return_unit

let no_dal_node_warning_counter = ref 0

let only_if_dal_feature_enabled state ~default_value f =
  let open Lwt_result_syntax in
  let open Constants in
  let Parametric.{dal = {feature_enable; _}; _} =
    state.global_state.constants.parametric
  in
  if feature_enable then
    match state.global_state.dal_node_rpc_ctxt with
    | None ->
        incr no_dal_node_warning_counter ;
        let*! () =
          if !no_dal_node_warning_counter mod 10 = 1 then
            Events.(emit no_dal_node ())
          else Lwt.return_unit
        in
        return default_value
    | Some ctxt -> f ctxt
  else return default_value

let get_dal_attestations state =
  let open Lwt_result_syntax in
  only_if_dal_feature_enabled state ~default_value:[] (fun dal_node_rpc_ctxt ->
      let attestation_level = state.level_state.current_level in
      let attested_level = Int32.succ attestation_level in
      let delegates =
        List.map
          (fun delegate_slot ->
            (delegate_slot.consensus_key_and_delegate, delegate_slot.first_slot))
          (Delegate_slots.own_delegates state.level_state.delegate_slots)
      in
      let signing_key delegate = (fst delegate).public_key_hash in
      let* attestations =
        List.fold_left_es
          (fun acc (delegate, first_slot) ->
            let*! tz_res =
              Node_rpc.get_attestable_slots
                dal_node_rpc_ctxt
                (signing_key delegate)
                ~attested_level
            in
            match tz_res with
            | Error errs ->
                let*! () =
                  Events.(emit failed_to_get_dal_attestations (delegate, errs))
                in
                return acc
            | Ok res -> (
                match res with
                | Tezos_dal_node_services.Types.Not_in_committee -> return acc
                | Attestable_slots {slots = attestation; published_level} ->
                    if List.exists Fun.id attestation then
                      return
                        ((delegate, attestation, published_level, first_slot)
                        :: acc)
                    else
                      (* No slot is attested, no need to send an attestation, at least
                         for now. *)
                      let*! () =
                        Events.(
                          emit
                            dal_attestation_void
                            (delegate, attestation_level, published_level))
                      in
                      return acc))
          []
          delegates
      in
      let number_of_slots =
        state.global_state.constants.parametric.dal.number_of_slots
      in
      List.map
        (fun (delegate, attestation_flags, published_level, first_slot) ->
          let attestation =
            List.fold_left_i
              (fun i acc flag ->
                match Dal.Slot_index.of_int_opt ~number_of_slots i with
                | Some index when flag -> Dal.Attestation.commit acc index
                | None | Some _ -> acc)
              Dal.Attestation.empty
              attestation_flags
          in
          ( delegate,
            Dal.Attestation.
              {
                attestation;
                level = Raw_level.of_int32_exn attestation_level;
                slot = first_slot;
              },
            published_level ))
        attestations
      |> return)

let inject_dal_attestation state signed_dal_attestation =
  let open Lwt_result_syntax in
  let cctxt = state.global_state.cctxt in
  let chain_id = state.global_state.chain_id in
  let ( delegate,
        signed_operation,
        (attestation : Dal.Attestation.t),
        published_level ) =
    signed_dal_attestation
  in
  let encoded_op =
    Data_encoding.Binary.to_bytes_exn
      Operation.encoding_with_legacy_attestation_name
      signed_operation
  in
  Lwt.dont_wait
    (fun () ->
      let*! (_ign : unit tzresult) =
        protect
          ~on_error:(fun err ->
            let*! () =
              Events.(emit failed_to_inject_dal_attestation (delegate, err))
            in
            return_unit)
          (fun () ->
            let* oph =
              Shell_services.Injection.operation
                cctxt
                ~chain:(`Hash chain_id)
                encoded_op
            in
            let bitset_int = Bitset.to_z (attestation :> Bitset.t) in
            let attestation_level = state.level_state.current_level in
            let*! () =
              Events.(
                emit
                  dal_attestation_injected
                  (oph, delegate, bitset_int, published_level, attestation_level))
            in
            return_unit)
      in
      Lwt.return_unit)
    (fun _exn -> ()) ;
  return_unit

let prepare_waiting_for_quorum state =
  let consensus_threshold =
    state.global_state.constants.parametric.consensus_threshold
  in
  let get_slot_voting_power ~slot =
    Delegate_slots.voting_power state.level_state.delegate_slots ~slot
  in
  let latest_proposal = state.level_state.latest_proposal.block in
  (* assert (latest_proposal.block.round = state.round_state.current_round) ; *)
  let candidate =
    {
      Operation_worker.hash = latest_proposal.hash;
      round_watched = latest_proposal.round;
      payload_hash_watched = latest_proposal.payload_hash;
    }
  in
  (consensus_threshold, get_slot_voting_power, candidate)

let start_waiting_for_preattestation_quorum state =
  let consensus_threshold, get_slot_voting_power, candidate =
    prepare_waiting_for_quorum state
  in
  let operation_worker = state.global_state.operation_worker in
  Operation_worker.monitor_preattestation_quorum
    operation_worker
    ~consensus_threshold
    ~get_slot_voting_power
    candidate

let start_waiting_for_attestation_quorum state =
  let consensus_threshold, get_slot_voting_power, candidate =
    prepare_waiting_for_quorum state
  in
  let operation_worker = state.global_state.operation_worker in
  Operation_worker.monitor_attestation_quorum
    operation_worker
    ~consensus_threshold
    ~get_slot_voting_power
    candidate

let compute_round (proposal : proposal) round_durations =
  let open Protocol in
  let open Baking_state in
  let timestamp = Time.System.now () |> Time.System.to_protocol in
  let predecessor_block = proposal.predecessor in
  Environment.wrap_tzresult
  @@ Alpha_context.Round.round_of_timestamp
       round_durations
       ~predecessor_timestamp:predecessor_block.shell.timestamp
       ~predecessor_round:predecessor_block.round
       ~timestamp

let update_to_level state level_update =
  let open Lwt_result_syntax in
  let {new_level_proposal : proposal; compute_new_state} = level_update in
  let cctxt = state.global_state.cctxt in
  let delegates = state.global_state.delegates in
  let new_level = new_level_proposal.block.shell.level in
  let chain = `Hash state.global_state.chain_id in
  (* Sync the context to clean-up potential GC artifacts *)
  let*! () =
    match state.global_state.validation_mode with
    | Node -> Lwt.return_unit
    | Local index -> index.sync_fun ()
  in
  let* delegate_slots =
    if Int32.(new_level = succ state.level_state.current_level) then
      return state.level_state.next_level_delegate_slots
    else
      Baking_state.compute_delegate_slots
        cctxt
        delegates
        ~level:new_level
        ~chain
  in
  let* next_level_delegate_slots =
    Baking_state.compute_delegate_slots
      cctxt
      delegates
      ~level:(Int32.succ new_level)
      ~chain
  in
  let round_durations = state.global_state.round_durations in
  let*? current_round = compute_round new_level_proposal round_durations in
  let*! new_state =
    compute_new_state ~current_round ~delegate_slots ~next_level_delegate_slots
  in
  return new_state

let synchronize_round state {new_round_proposal; handle_proposal} =
  let open Lwt_result_syntax in
  let*! () =
    Events.(emit synchronizing_round new_round_proposal.predecessor.hash)
  in
  let round_durations = state.global_state.round_durations in
  let*? current_round = compute_round new_round_proposal round_durations in
  if Round.(current_round < new_round_proposal.block.round) then
    (* impossible *)
    failwith
      "synchronize_round: current round (%a) is behind the new proposal's \
       round (%a)"
      Round.pp
      current_round
      Round.pp
      new_round_proposal.block.round
  else
    let new_round_state =
      {current_round; current_phase = Idle; delayed_quorum = None}
    in
    let new_state = {state with round_state = new_round_state} in
    let*! new_state = handle_proposal new_state in
    return new_state

(* TODO: https://gitlab.com/tezos/tezos/-/issues/4539
   Avoid updating the state here.
   (See also comment in {!State_transitions.step}.)

   TODO: https://gitlab.com/tezos/tezos/-/issues/4538
   Improve/clarify when the state is recorded.
*)
let rec perform_action ~state_recorder state (action : action) =
  let open Lwt_result_syntax in
  match action with
  | Do_nothing ->
      let* () = state_recorder ~new_state:state in
      return state
  | Prepare_block {block_to_bake} ->
      let request = Forge_and_sign_block block_to_bake in
      let () = state.global_state.forge_worker_hooks.push_request request in
      return state
  | Inject_block {prepared_block} ->
      let* new_state = inject_block state prepared_block in
      let* () = state_recorder ~new_state in
      return new_state
  | Prepare_preattestations {preattestations} ->
      let branch = state.level_state.latest_proposal.predecessor.hash in
      let request = Forge_and_sign_preattestations (branch, preattestations) in
      state.global_state.forge_worker_hooks.push_request request ;
      return state
  | Inject_preattestation {signed_preattestation} ->
      let* () =
        inject_consensus_vote state signed_preattestation `Preattestation
      in
      perform_action ~state_recorder state Watch_proposal
  | Prepare_attestations {attestations} ->
      let branch = state.level_state.latest_proposal.predecessor.hash in
      let request = Forge_and_sign_attestations (branch, attestations) in
      state.global_state.forge_worker_hooks.push_request request ;
      let* dal_attestations = get_dal_attestations state in
      let branch = state.level_state.latest_proposal.predecessor.hash in
      let request =
        Forge_and_sign_dal_attestations (branch, dal_attestations)
      in
      state.global_state.forge_worker_hooks.push_request request ;
      return state
  | Inject_attestation {signed_attestation} ->
      let* () = state_recorder ~new_state:state in
      let* () = inject_consensus_vote state signed_attestation `Attestation in
      (* We wait for attestations to trigger the [Quorum_reached]
         event *)
      let*! () = start_waiting_for_attestation_quorum state in
      (* TODO: https://gitlab.com/tezos/tezos/-/issues/4667
         Also inject attestations for the migration block. *)
      (* TODO: https://gitlab.com/tezos/tezos/-/issues/4671
         Don't inject multiple attestations? *)
      return state
  | Inject_dal_attestation {signed_dal_attestation} ->
      let* () = inject_dal_attestation state signed_dal_attestation in
      return state
  | Update_to_level level_update ->
      let* new_state, new_action = update_to_level state level_update in
      perform_action ~state_recorder new_state new_action
  | Synchronize_round round_update ->
      let* new_state, new_action = synchronize_round state round_update in
      perform_action ~state_recorder new_state new_action
  | Watch_proposal ->
      (* We wait for preattestations to trigger the
           [Prequorum_reached] event *)
      let*! () = start_waiting_for_preattestation_quorum state in
      return state
