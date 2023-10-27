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
  let open Lwt_result_syntax in
  let preserved = Constants_storage.preserved_cycles ctxt in
  match Cycle_repr.sub last_cycle preserved with
  | None -> return (ctxt, [])
  | Some _unfrozen_cycle ->
      Stake_storage.fold_on_active_delegates_with_minimal_stake_s
        ctxt
        ~order:`Sorted
        ~init:(Ok (ctxt, []))
        ~f:(fun delegate () acc ->
          let*? ctxt, deactivated = acc in
          let* cycle =
            Delegate_activation_storage.last_cycle_before_deactivation
              ctxt
              delegate
          in
          if Cycle_repr.(cycle <= last_cycle) then
            let*! ctxt = Stake_storage.set_inactive ctxt delegate in
            return (ctxt, delegate :: deactivated)
          else return (ctxt, deactivated))

let update_forbidden_delegates ctxt ~new_cycle =
  let open Lwt_result_syntax in
  let*! ctxt = Delegate_storage.reset_forbidden_delegates ctxt in
  let* selection_for_new_cycle =
    Stake_storage.get_selected_distribution ctxt new_cycle
  in
  List.fold_left_es
    (fun ctxt (delegate, _stake) ->
      let* current_deposits =
        Delegate_storage.current_frozen_deposits ctxt delegate
      in
      if Tez_repr.(current_deposits = zero) then
        (* If the delegate's current deposit remains at zero then we add it to
           the forbidden set. *)
        let*! ctxt = Delegate_storage.forbid_delegate ctxt delegate in
        return ctxt
      else return ctxt)
    ctxt
    selection_for_new_cycle

let delegate_has_revealed_nonces delegate unrevelead_nonces_set =
  not (Signature.Public_key_hash.Set.mem delegate unrevelead_nonces_set)

let distribute_attesting_rewards ctxt last_cycle unrevealed_nonces =
  let open Lwt_result_syntax in
  let attesting_reward_per_slot =
    Delegate_rewards.attesting_reward_per_slot ctxt
  in
  let unrevealed_nonces_set =
    List.fold_left
      (fun set {Storage.Seed.nonce_hash = _; delegate} ->
        Signature.Public_key_hash.Set.add delegate set)
      Signature.Public_key_hash.Set.empty
      unrevealed_nonces
  in
  let* total_active_stake =
    Stake_storage.get_total_active_stake ctxt last_cycle
  in
  let total_active_stake_weight =
    Stake_repr.staking_weight total_active_stake
  in
  let* delegates = Stake_storage.get_selected_distribution ctxt last_cycle in
  List.fold_left_es
    (fun (ctxt, balance_updates) (delegate, active_stake) ->
      let* ctxt, sufficient_participation =
        Delegate_missed_attestations_storage
        .check_and_reset_delegate_participation
          ctxt
          delegate
      in
      let has_revealed_nonces =
        delegate_has_revealed_nonces delegate unrevealed_nonces_set
      in
      let active_stake_weight = Stake_repr.staking_weight active_stake in
      let expected_slots =
        Delegate_missed_attestations_storage
        .expected_slots_for_given_active_stake
          ctxt
          ~total_active_stake_weight
          ~active_stake_weight
      in
      let rewards = Tez_repr.mul_exn attesting_reward_per_slot expected_slots in
      if sufficient_participation && has_revealed_nonces then
        (* Sufficient participation: we pay the rewards *)
        let+ ctxt, payed_rewards_receipts =
          Delegate_staking_parameters.pay_rewards
            ctxt
            ~active_stake
            ~source:`Attesting_rewards
            ~delegate
            rewards
        in
        (ctxt, payed_rewards_receipts @ balance_updates)
      else
        (* Insufficient participation or unrevealed nonce: no rewards *)
        let+ ctxt, payed_rewards_receipts =
          Token.transfer
            ctxt
            `Attesting_rewards
            (`Lost_attesting_rewards
              (delegate, not sufficient_participation, not has_revealed_nonces))
            rewards
        in
        (ctxt, payed_rewards_receipts @ balance_updates))
    (ctxt, [])
    delegates

let cycle_end ctxt last_cycle =
  let open Lwt_result_syntax in
  let* ctxt, unrevealed_nonces =
    Profiler.record_s "seed storage" @@ fun () ->
    Seed_storage.cycle_end ctxt last_cycle
  in
  let* ctxt, attesting_balance_updates =
    Profiler.record_s "distribute attesting rewards" @@ fun () ->
    distribute_attesting_rewards ctxt last_cycle unrevealed_nonces
  in
  let* ctxt, slashings, slashing_balance_updates =
    Delegate_slashed_deposits_storage
    .apply_and_clear_current_cycle_denunciations
      ctxt
  in
  let new_cycle = Cycle_repr.add last_cycle 1 in
  let* ctxt =
    Profiler.record_s "select new distribution" @@ fun () ->
    Delegate_sampler.select_new_distribution_at_cycle_end
      ctxt
      ~slashings
      ~new_cycle
  in
  let*! ctxt =
    Profiler.record_s "activate consensus key" @@ fun () ->
    Delegate_consensus_key.activate ctxt ~new_cycle
  in
  let*! ctxt =
    Delegate_slashed_deposits_storage.clear_outdated_slashed_deposits
      ctxt
      ~new_cycle
  in
  let* ctxt =
    Profiler.record_s "update forbidden delegates" @@ fun () ->
    update_forbidden_delegates ctxt ~new_cycle
  in
  let* ctxt = Stake_storage.clear_at_cycle_end ctxt ~new_cycle in
  let* ctxt = Delegate_sampler.clear_outdated_sampling_data ctxt ~new_cycle in
  let*! ctxt =
    Profiler.record_s "activate staking parameters" @@ fun () ->
    Delegate_staking_parameters.activate ctxt ~new_cycle
  in
  let* ctxt, deactivated_delegates =
    Profiler.record_s "update activity" @@ fun () ->
    update_activity ctxt last_cycle
  in
  let* ctxt =
    Profiler.record_s "update stored rewards at cycle end" @@ fun () ->
    Adaptive_issuance_storage.update_stored_rewards_at_cycle_end ctxt ~new_cycle
  in
  let balance_updates = slashing_balance_updates @ attesting_balance_updates in
  return (ctxt, balance_updates, deactivated_delegates)

let init_first_cycles ctxt =
  let open Lwt_result_syntax in
  let preserved = Constants_storage.preserved_cycles ctxt in
  let* ctxt =
    List.fold_left_es
      (fun ctxt c ->
        let cycle = Cycle_repr.of_int32_exn (Int32.of_int c) in
        let* ctxt = Stake_storage.snapshot ctxt in
        (* NB: we need to take several snapshots because
           select_distribution_for_cycle deletes the snapshots *)
        Delegate_sampler.select_distribution_for_cycle
          ctxt
          ~slashings:Signature.Public_key_hash.Map.empty
          cycle)
      ctxt
      Misc.(0 --> preserved)
  in
  let cycle = (Raw_context.current_level ctxt).cycle in
  update_forbidden_delegates ~new_cycle:cycle ctxt
