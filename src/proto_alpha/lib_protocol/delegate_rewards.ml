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

let seconds_per_year = Q.of_int 31_556_852

(* TODO have accurate total_supply *)
let total_supply = Z.of_int64 22_685_733_000_000L

let get_rewards ctxt =
  let open Lwt_result_syntax in
  match Raw_context.get_rewards ctxt with
  | Constant ->
      let baking_reward_fixed_portion =
        Constants_storage.baking_reward_fixed_portion ctxt
      in
      let baking_reward_bonus_per_slot =
        Constants_storage.baking_reward_bonus_per_slot ctxt
      in
      return
        ( ctxt,
          Delegate_rewards_repr.
            {baking_reward_fixed_portion; baking_reward_bonus_per_slot} )
  | Constant_override c -> return (ctxt, c)
  | Adaptive {f; reward} -> (
      match reward with
      | Some r -> return (ctxt, r)
      | None ->
          let level = Level_storage.current ctxt in
          let* total_stake =
            Stake_storage.get_total_active_stake ctxt level.cycle
          in
          let total_stake = Tez_repr.to_mutez total_stake |> Z.of_int64 in
          let pct = f total_stake total_supply in
          let min_block_delay =
            Constants_storage.minimal_block_delay ctxt
            |> Period_repr.to_seconds |> Q.of_int64
          in
          let bonus_endorsment_slots =
            Constants_storage.(
              consensus_committee_size ctxt - consensus_threshold ctxt)
            |> Q.of_int
          in
          let reward_per_block_half =
            Q.(
              div
                (div
                   (mul (mul pct (Q.of_bigint total_supply)) min_block_delay)
                   seconds_per_year)
                (Q.of_int 2))
          in
          let baking_reward_fixed_portion =
            Q.to_int64 reward_per_block_half |> Tez_repr.of_mutez_exn
          in
          let baking_reward_bonus_per_slot =
            Q.div reward_per_block_half bonus_endorsment_slots
            |> Q.to_int64 |> Tez_repr.of_mutez_exn
          in
          let reward =
            Delegate_rewards_repr.
              {baking_reward_fixed_portion; baking_reward_bonus_per_slot}
          in
          let ctxt =
            Raw_context.set_rewards ctxt (Adaptive {f; reward = Some reward})
          in
          return (ctxt, reward))

let reset_reward_at_cycle_end ctxt =
  match Raw_context.get_rewards ctxt with
  | Adaptive {f; _} ->
      Raw_context.set_rewards ctxt (Adaptive {f; reward = None})
  | _ -> ctxt
