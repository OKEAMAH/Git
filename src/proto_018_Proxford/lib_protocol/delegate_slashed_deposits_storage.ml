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

let already_slashed_for_double_attesting ctxt delegate (level : Level_repr.t) =
  let open Lwt_result_syntax in
  let* slashed_opt =
    Storage.Slashed_deposits.find (ctxt, level.cycle) (level.level, delegate)
  in
  match slashed_opt with
  | None -> return_false
  | Some slashed -> return slashed.for_double_attesting

let already_slashed_for_double_baking ctxt delegate (level : Level_repr.t) =
  let open Lwt_result_syntax in
  let* slashed_opt =
    Storage.Slashed_deposits.find (ctxt, level.cycle) (level.level, delegate)
  in
  match slashed_opt with
  | None -> return_false
  | Some slashed -> return slashed.for_double_baking

type reward_and_burn = {reward : Tez_repr.t; amount_to_burn : Tez_repr.t}

type punishing_amounts = {
  staked : reward_and_burn;
  unstaked : (Cycle_repr.t * reward_and_burn) list;
}

(** [punish_double_signing ctxt misbehaviour delegate level] record
    in the context that the given [delegate] has now been slashed for the
    double signing event [misbehaviour] for the given [level] and return the amounts of the
    frozen deposits to burn and to reward the denuncer.

    The double signing event corresponds to a field in {!Storage.slashed_level}.
*)
let punish_double_signing ctxt ~operation_hash (misbehaviour : Misbehaviour.t)
    delegate (level : Level_repr.t) ~rewarded :
    (Raw_context.t * bool) tzresult Lwt.t =
  let open Lwt_result_syntax in
  let* slashed_opt =
    Storage.Slashed_deposits.find (ctxt, level.cycle) (level.level, delegate)
  in
  let slashed =
    Option.value slashed_opt ~default:Storage.default_slashed_level
  in
  let already_slashed, updated_slashed, slashing_percentage =
    let Storage.{for_double_baking; for_double_attesting} = slashed in
    match misbehaviour with
    | Double_baking ->
        ( for_double_baking,
          {slashed with for_double_baking = true},
          Constants_storage
          .percentage_of_frozen_deposits_slashed_per_double_baking
            ctxt )
    | Double_attesting ->
        ( for_double_attesting,
          {slashed with for_double_attesting = true},
          Constants_storage
          .percentage_of_frozen_deposits_slashed_per_double_attestation
            ctxt )
  in
  assert (Compare.Bool.(already_slashed = false)) ;
  let delegate_contract = Contract_repr.Implicit delegate in
  let current_cycle = (Raw_context.current_level ctxt).cycle in
  let*! ctxt =
    Storage.Slashed_deposits.add
      (ctxt, level.cycle)
      (level.level, delegate)
      updated_slashed
  in
  let* slash_history_opt =
    Storage.Contract.Slashed_deposits.find ctxt delegate_contract
  in
  let slash_history = Option.value slash_history_opt ~default:[] in
  let previously_slashed_this_cycle =
    Storage.Slashed_deposits_history.get current_cycle slash_history
  in
  let slash_history =
    Storage.Slashed_deposits_history.add
      level.cycle
      slashing_percentage
      slash_history
  in
  let*! ctxt =
    Storage.Contract.Slashed_deposits.add ctxt delegate_contract slash_history
  in
  let*! ctxt, did_forbid =
    Forbidden_delegates_storage.may_forbid
      ctxt
      delegate
      ~current_cycle
      slash_history
  in
  let* ctxt =
    if Compare.Int.((previously_slashed_this_cycle :> int) >= 100) then
      (* Do not store denunciations that have no effects .*) return ctxt
    else
      let* denunciations_opt =
        Storage.Current_cycle_denunciations.find ctxt delegate
      in
      let denunciations = Option.value denunciations_opt ~default:[] in
      let cycle =
        if Cycle_repr.(level.cycle = current_cycle) then
          Denunciations_repr.Current
        else if Cycle_repr.(succ level.cycle = current_cycle) then
          Denunciations_repr.Previous
        else
          (* [max_slashing_period = 2] according to
             {!Constants_repr.check_constants}. *)
          assert false
      in
      let denunciations =
        Denunciations_repr.add
          operation_hash
          rewarded
          misbehaviour
          cycle
          denunciations
      in
      let*! ctxt =
        Storage.Current_cycle_denunciations.add ctxt delegate denunciations
      in
      return ctxt
  in
  return (ctxt, did_forbid)

let clear_outdated_slashed_deposits ctxt ~new_cycle =
  let max_slashable_period = Constants_repr.max_slashing_period in
  match Cycle_repr.(sub new_cycle max_slashable_period) with
  | None -> Lwt.return ctxt
  | Some outdated_cycle -> Storage.Slashed_deposits.clear (ctxt, outdated_cycle)

let apply_and_clear_current_cycle_denunciations ctxt =
  let open Lwt_result_syntax in
  let current_cycle = (Raw_context.current_level ctxt).cycle in
  let previous_cycle =
    match Cycle_repr.pred current_cycle with
    | None -> current_cycle
    | Some previous_cycle -> previous_cycle
  in
  let preserved_cycles = Constants_storage.preserved_cycles ctxt in
  let global_limit_of_staking_over_baking_plus_two =
    let global_limit_of_staking_over_baking =
      Constants_storage.adaptive_issuance_global_limit_of_staking_over_baking
        ctxt
    in
    Int64.add (Int64.of_int global_limit_of_staking_over_baking) 2L
  in
  let compute_reward_and_burn slashing_percentage
      (frozen_deposits : Deposits_repr.t) =
    let open Result_syntax in
    let punish_value =
      Tez_repr.mul_percentage
        ~rounding:`Down
        frozen_deposits.initial_amount
        slashing_percentage
    in
    let punishing_amount =
      Tez_repr.min punish_value frozen_deposits.current_amount
    in
    let* reward =
      Tez_repr.(
        punishing_amount /? global_limit_of_staking_over_baking_plus_two)
    in
    let+ amount_to_burn = Tez_repr.(punishing_amount -? reward) in
    {reward; amount_to_burn}
  in
  let* ctxt, slashings, balance_updates =
    Storage.Current_cycle_denunciations.fold
      ctxt
      ~order:`Undefined
      ~init:(Ok (ctxt, Signature.Public_key_hash.Map.empty, []))
      ~f:(fun delegate denunciations acc ->
        let*? ctxt, slashings, balance_updates = acc in
        let+ ctxt, percentage, balance_updates =
          List.fold_left_es
            (fun (ctxt, percentage, balance_updates)
                 Denunciations_repr.
                   {operation_hash; rewarded; misbehaviour; misbehaviour_cycle} ->
              let slashing_percentage =
                match misbehaviour with
                | Double_baking ->
                    Constants_storage
                    .percentage_of_frozen_deposits_slashed_per_double_baking
                      ctxt
                | Double_attesting ->
                    Constants_storage
                    .percentage_of_frozen_deposits_slashed_per_double_attestation
                      ctxt
              in
              let ( misbehaviour_cycle,
                    get_initial_frozen_deposits_of_misbehaviour_cycle ) =
                match misbehaviour_cycle with
                | Current ->
                    (current_cycle, Delegate_storage.initial_frozen_deposits)
                | Previous ->
                    ( previous_cycle,
                      Delegate_storage.initial_frozen_deposits_of_previous_cycle
                    )
              in
              let* frozen_deposits =
                let* initial_amount =
                  get_initial_frozen_deposits_of_misbehaviour_cycle
                    ctxt
                    delegate
                in
                let* current_amount =
                  Delegate_storage.current_frozen_deposits ctxt delegate
                in
                return Deposits_repr.{initial_amount; current_amount}
              in
              let*? staked =
                compute_reward_and_burn slashing_percentage frozen_deposits
              in
              let* init_to_burn_to_reward =
                let giver_baker =
                  `Frozen_deposits (Frozen_staker_repr.baker delegate)
                in
                let giver_stakers =
                  `Frozen_deposits
                    (Frozen_staker_repr.shared_between_stakers ~delegate)
                in
                let {amount_to_burn; reward} = staked in
                let* to_burn =
                  let+ {baker_part; stakers_part} =
                    Shared_stake.share
                      ~rounding:`Towards_baker
                      ctxt
                      delegate
                      amount_to_burn
                  in
                  [(giver_baker, baker_part); (giver_stakers, stakers_part)]
                in
                let* to_reward =
                  let+ {baker_part; stakers_part} =
                    Shared_stake.share
                      ~rounding:`Towards_baker
                      ctxt
                      delegate
                      reward
                  in
                  [(giver_baker, baker_part); (giver_stakers, stakers_part)]
                in
                return (to_burn, to_reward)
              in
              let* to_burn, to_reward =
                let oldest_slashable_cycle =
                  Cycle_repr.sub misbehaviour_cycle preserved_cycles
                  |> Option.value ~default:Cycle_repr.root
                in
                let slashable_cycles =
                  Cycle_repr.(oldest_slashable_cycle ---> misbehaviour_cycle)
                in
                List.fold_left_es
                  (fun (to_burn, to_reward) cycle ->
                    let* frozen_deposits =
                      Unstaked_frozen_deposits_storage.get ctxt delegate cycle
                    in
                    let*? {amount_to_burn; reward} =
                      compute_reward_and_burn
                        slashing_percentage
                        frozen_deposits
                    in
                    let giver =
                      `Unstaked_frozen_deposits
                        (Unstaked_frozen_staker_repr.Shared delegate, cycle)
                    in
                    return
                      ( (giver, amount_to_burn) :: to_burn,
                        (giver, reward) :: to_reward ))
                  init_to_burn_to_reward
                  slashable_cycles
              in
              let origin = Receipt_repr.Delayed_operation {operation_hash} in
              let* ctxt, punish_balance_updates =
                Token.transfer_n
                  ctxt
                  ~origin
                  to_burn
                  `Double_signing_punishments
              in
              let+ ctxt, reward_balance_updates =
                Token.transfer_n
                  ctxt
                  ~origin
                  to_reward
                  (`Contract (Contract_repr.Implicit rewarded))
              in
              let percentage =
                Int_percentage.add_bounded percentage slashing_percentage
              in
              ( ctxt,
                percentage,
                punish_balance_updates @ reward_balance_updates
                @ balance_updates ))
            (ctxt, Int_percentage.p0, balance_updates)
            denunciations
        in
        let slashings =
          Signature.Public_key_hash.Map.add delegate percentage slashings
        in
        (ctxt, slashings, balance_updates))
  in
  let*! ctxt = Storage.Current_cycle_denunciations.clear ctxt in
  return (ctxt, slashings, balance_updates)
