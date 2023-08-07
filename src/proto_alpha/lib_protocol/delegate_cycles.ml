(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2018 Dynamic Ledger Solutions, Inc. <contact@tezos.com>     *)
(* Copyright (c) 2021 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2022 G.B. Fefe, <gb.fefe@protonmail.com>                    *)
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

let update_activity ctxt last_cycle =
  let preserved = Constants_storage.preserved_cycles ctxt in
  match Cycle_repr.sub last_cycle preserved with
  | None -> return (ctxt, [])
  | Some _unfrozen_cycle ->
      Stake_storage.fold_on_active_delegates_with_minimal_stake
        ctxt
        ~order:`Sorted
        ~init:(Ok (ctxt, []))
        ~f:(fun delegate () acc ->
          acc >>?= fun (ctxt, deactivated) ->
          Delegate_activation_storage.last_cycle_before_deactivation
            ctxt
            delegate
          >>=? fun cycle ->
          if Cycle_repr.(cycle <= last_cycle) then
            Stake_storage.set_inactive ctxt delegate >>= fun ctxt ->
            return (ctxt, delegate :: deactivated)
          else return (ctxt, deactivated))
      >|=? fun (ctxt, deactivated) -> (ctxt, deactivated)

(* Return a map from delegates (with active stake at some cycle
   in the cycle window [from_cycle, to_cycle]) to the maximum
   of the active stake in that window. Also
   return the delegates that have fallen out of the sliding window. *)
let max_frozen_deposits_and_delegates_to_remove ctxt ~from_cycle ~to_cycle =
  let cycles = Cycle_repr.(from_cycle ---> to_cycle) in
  (match Cycle_repr.pred from_cycle with
  | None -> return Signature.Public_key_hash.Set.empty
  | Some cleared_cycle -> (
      Stake_storage.find_selected_distribution ctxt cleared_cycle
      >|=? fun cleared_cycle_delegates ->
      match cleared_cycle_delegates with
      | None -> Signature.Public_key_hash.Set.empty
      | Some delegates ->
          List.fold_left
            (fun set (d, _) -> Signature.Public_key_hash.Set.add d set)
            Signature.Public_key_hash.Set.empty
            delegates))
  >>=? fun cleared_cycle_delegates ->
  List.fold_left_es
    (fun (maxima, delegates_to_remove) (cycle : Cycle_repr.t) ->
      Stake_storage.get_selected_distribution ctxt cycle
      >|=? fun active_stakes ->
      List.fold_left
        (fun (maxima, delegates_to_remove)
             (delegate, Stake_repr.{frozen; delegated = _}) ->
          let maxima =
            Signature.Public_key_hash.Map.update
              delegate
              (function
                | None -> Some frozen
                | Some maximum -> Some (Tez_repr.max maximum frozen))
              maxima
          in
          let delegates_to_remove =
            Signature.Public_key_hash.Set.remove delegate delegates_to_remove
          in
          (maxima, delegates_to_remove))
        (maxima, delegates_to_remove)
        active_stakes)
    (Signature.Public_key_hash.Map.empty, cleared_cycle_delegates)
    cycles

let update_initial_frozen_deposits ctxt ~new_cycle =
  Delegate_storage.reset_forbidden_delegates ctxt >>= fun ctxt ->
  let max_slashable_period = Constants_storage.max_slashing_period ctxt in
  (* We want to be able to slash for at most [max_slashable_period] *)
  (match Cycle_repr.(sub new_cycle (max_slashable_period - 1)) with
  | None ->
      Storage.Tenderbake.First_level_of_protocol.get ctxt
      >>=? fun first_level_of_protocol ->
      let cycle_eras = Raw_context.cycle_eras ctxt in
      let level =
        Level_repr.level_from_raw ~cycle_eras first_level_of_protocol
      in
      return level.cycle
  | Some cycle -> return cycle)
  >>=? fun from_cycle ->
  let preserved_cycles = Constants_storage.preserved_cycles ctxt in
  let to_cycle = Cycle_repr.(add new_cycle preserved_cycles) in
  max_frozen_deposits_and_delegates_to_remove ctxt ~from_cycle ~to_cycle
  >>=? fun (maxima, delegates_to_remove) ->
  Signature.Public_key_hash.Map.fold_es
    (fun delegate maximum_stake_to_be_deposited ctxt ->
      let delegate_contract = Contract_repr.Implicit delegate in
      Frozen_deposits_storage.update_initial_amount
        ctxt
        delegate_contract
        maximum_stake_to_be_deposited
      >>=? fun ctxt ->
      Frozen_deposits_storage.get ctxt delegate_contract >>=? fun deposits ->
      let current_amount = deposits.current_amount in
      if Tez_repr.(current_amount = zero) then
        (* If the delegate's current deposit remains at zero then we add it to
           the forbidden set. *)
        Delegate_storage.forbid_delegate ctxt delegate >>= fun ctxt ->
        return ctxt
      else return ctxt)
    maxima
    ctxt
  >>=? fun ctxt ->
  Signature.Public_key_hash.Set.fold_es
    (fun delegate ctxt ->
      let delegate_contract = Contract_repr.Implicit delegate in
      Frozen_deposits_storage.update_initial_amount
        ctxt
        delegate_contract
        Tez_repr.zero)
    delegates_to_remove
    ctxt

let delegate_has_revealed_nonces delegate unrevelead_nonces_set =
  not (Signature.Public_key_hash.Set.mem delegate unrevelead_nonces_set)

let distribute_endorsing_rewards ctxt last_cycle unrevealed_nonces =
  let endorsing_reward_per_slot =
    Delegate_rewards.attesting_reward_per_slot ctxt
  in
  let unrevealed_nonces_set =
    List.fold_left
      (fun set {Storage.Seed.nonce_hash = _; delegate} ->
        Signature.Public_key_hash.Set.add delegate set)
      Signature.Public_key_hash.Set.empty
      unrevealed_nonces
  in
  Stake_storage.get_total_active_stake ctxt last_cycle
  >>=? fun total_active_stake ->
  let total_active_stake_weight =
    Stake_context.staking_weight ctxt total_active_stake
  in
  Stake_storage.get_selected_distribution ctxt last_cycle >>=? fun delegates ->
  List.fold_left_es
    (fun (ctxt, balance_updates) (delegate, active_stake) ->
      Delegate_missed_endorsements_storage
      .check_and_reset_delegate_participation
        ctxt
        delegate
      >>=? fun (ctxt, sufficient_participation) ->
      let has_revealed_nonces =
        delegate_has_revealed_nonces delegate unrevealed_nonces_set
      in
      let active_stake_weight =
        Stake_context.staking_weight ctxt active_stake
      in
      let expected_slots =
        Delegate_missed_endorsements_storage
        .expected_slots_for_given_active_stake
          ctxt
          ~total_active_stake_weight
          ~active_stake_weight
      in
      let rewards = Tez_repr.mul_exn endorsing_reward_per_slot expected_slots in
      if sufficient_participation && has_revealed_nonces then
        (* Sufficient participation: we pay the rewards *)
        Delegate_staking_parameters.pay_rewards
          ctxt
          ~active_stake
          ~source:`Attesting_rewards
          ~delegate
          rewards
        >|=? fun (ctxt, payed_rewards_receipts) ->
        (ctxt, payed_rewards_receipts @ balance_updates)
      else
        (* Insufficient participation or unrevealed nonce: no rewards *)
        Token.transfer
          ctxt
          `Attesting_rewards
          (`Lost_attesting_rewards
            (delegate, not sufficient_participation, not has_revealed_nonces))
          rewards
        >|=? fun (ctxt, payed_rewards_receipts) ->
        (ctxt, payed_rewards_receipts @ balance_updates))
    (ctxt, [])
    delegates

let cycle_end ctxt last_cycle =
  Profiler.aggregate_s "cycle-end: seed storage" (fun () ->
      Seed_storage.cycle_end ctxt last_cycle)
  >>=? fun (ctxt, unrevealed_nonces) ->
  let new_cycle = Cycle_repr.add last_cycle 1 in
  (* TODO #5807: is this the right place?? *)
  Profiler.aggregate_s "cycle-end: activate staking parameters" (fun () ->
      Delegate_staking_parameters.activate ctxt ~new_cycle)
  >>=? fun ctxt ->
  Profiler.aggregate_s "cycle-end: select new distribution" (fun () ->
      Delegate_sampler.select_new_distribution_at_cycle_end ctxt ~new_cycle)
  >>=? fun ctxt ->
  Profiler.aggregate_s "cycle-end: activate consensus key" (fun () ->
      Delegate_consensus_key.activate ctxt ~new_cycle)
  >>=? fun ctxt ->
  Delegate_slashed_deposits_storage.clear_outdated_slashed_deposits
    ctxt
    ~new_cycle
  >>= fun ctxt ->
  Profiler.aggregate_s "cycle-end: distribute endorsing rewards" (fun () ->
      distribute_endorsing_rewards ctxt last_cycle unrevealed_nonces)
  >>=? fun (ctxt, balance_updates) ->
  Profiler.aggregate_s "cycle-end: update initial frozen deposits" (fun () ->
      update_initial_frozen_deposits ctxt ~new_cycle)
  >>=? fun ctxt ->
  Stake_storage.clear_at_cycle_end ctxt ~new_cycle >>=? fun ctxt ->
  Delegate_sampler.clear_outdated_sampling_data ctxt ~new_cycle >>=? fun ctxt ->
  Profiler.aggregate_s "cycle-end: update activity" (fun () ->
      update_activity ctxt last_cycle)
  >>=? fun (ctxt, deactivated_delegates) ->
  Profiler.aggregate_s "cycle-end: update stored rewards" (fun () ->
      Adaptive_inflation_storage.update_stored_rewards_at_cycle_end
        ctxt
        ~new_cycle)
  >>=? fun ctxt ->
  Profiler.aggregate_s "cycle-end: squash frozen deposits" (fun () ->
      Unstaked_frozen_deposits_storage
      .squash_unslashable_unstaked_frozen_deposits_at_cycle_end
        ctxt
        ~last_cycle)
  >>=? fun ctxt -> return (ctxt, balance_updates, deactivated_delegates)

let init_first_cycles ctxt =
  let preserved = Constants_storage.preserved_cycles ctxt in
  List.fold_left_es
    (fun ctxt c ->
      let cycle = Cycle_repr.of_int32_exn (Int32.of_int c) in
      Stake_storage.snapshot ctxt >>=? fun ctxt ->
      (* NB: we need to take several snapshots because
         select_distribution_for_cycle deletes the snapshots *)
      Delegate_sampler.select_distribution_for_cycle ctxt cycle)
    ctxt
    Misc.(0 --> preserved)
  >>=? fun ctxt ->
  let cycle = (Raw_context.current_level ctxt).cycle in
  update_initial_frozen_deposits ~new_cycle:cycle ctxt
