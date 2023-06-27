(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2018 Dynamic Ledger Solutions, Inc. <contact@tezos.com>     *)
(* Copyright (c) 2020-2021 Nomadic Labs <contact@nomadic-labs.com>           *)
(* Copyright (c) 2021-2022 Trili Tech, <contact@trili.tech>                  *)
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

type dal = {
  feature_enable : bool;
  number_of_slots : int;
  attestation_lag : int;
  attestation_threshold : int;
  blocks_per_epoch : int32;
  cryptobox_parameters : Dal.parameters;
}

let dal_encoding =
  let open Data_encoding in
  conv
    (fun {
           feature_enable;
           number_of_slots;
           attestation_lag;
           attestation_threshold;
           cryptobox_parameters;
           blocks_per_epoch;
         } ->
      ( ( feature_enable,
          number_of_slots,
          attestation_lag,
          attestation_threshold,
          blocks_per_epoch ),
        cryptobox_parameters ))
    (fun ( ( feature_enable,
             number_of_slots,
             attestation_lag,
             attestation_threshold,
             blocks_per_epoch ),
           cryptobox_parameters ) ->
      {
        feature_enable;
        number_of_slots;
        attestation_lag;
        attestation_threshold;
        blocks_per_epoch;
        cryptobox_parameters;
      })
    (merge_objs
       (obj5
          (req "feature_enable" bool)
          (req "number_of_slots" int16)
          (req "attestation_lag" int16)
          (req "attestation_threshold" int16)
          (req "blocks_per_epoch" int32))
       Dal.parameters_encoding)

(* The encoded representation of this type is stored in the context as
   bytes. Changing the encoding, or the value of these constants from
   the previous protocol may break the context migration, or (even
   worse) yield an incorrect context after migration.

   If you change this encoding compared to `Constants_parametric_previous_repr.t`,
   you should ensure that there is a proper migration of the constants
   during context migration. See: `Raw_context.prepare_first_block` *)

type sc_rollup = {
  enable : bool;
  arith_pvm_enable : bool;
  origination_size : int;
  challenge_window_in_blocks : int;
  stake_amount : Tez_repr.t;
  commitment_period_in_blocks : int;
  max_lookahead_in_blocks : int32;
  max_active_outbox_levels : int32;
  max_outbox_messages_per_level : int;
  number_of_sections_in_dissection : int;
  timeout_period_in_blocks : int;
  max_number_of_stored_cemented_commitments : int;
  max_number_of_parallel_games : int;
}

type zk_rollup = {
  enable : bool;
  origination_size : int;
  min_pending_to_process : int;
  max_ticket_payload_size : int;
}

type adaptive_inflation = {
  staking_over_baking_limit : int;
  staking_over_delegation_edge : int;
  launch_ema_threshold : int32;
}

type reward_weights = {
  base_total_rewards_per_minute : Tez_repr.t;
  baking_reward_fixed_portion_weight : int;
  baking_reward_bonus_weight : int;
  endorsing_reward_weight : int;
  liquidity_baking_subsidy_weight : int;
  seed_nonce_revelation_tip_weight : int;
  vdf_revelation_tip_weight : int;
}

type t = {
  preserved_cycles : int;
  blocks_per_cycle : int32;
  blocks_per_commitment : int32;
  nonce_revelation_threshold : int32;
  blocks_per_stake_snapshot : int32;
  cycles_per_voting_period : int32;
  hard_gas_limit_per_operation : Gas_limit_repr.Arith.integral;
  hard_gas_limit_per_block : Gas_limit_repr.Arith.integral;
  proof_of_work_threshold : int64;
  minimal_stake : Tez_repr.t;
  vdf_difficulty : int64;
  origination_size : int;
  reward_weights : reward_weights;
  cost_per_byte : Tez_repr.t;
  hard_storage_limit_per_operation : Z.t;
  quorum_min : int32;
  quorum_max : int32;
  min_proposal_quorum : int32;
  liquidity_baking_toggle_ema_threshold : int32;
  max_operations_time_to_live : int;
  minimal_block_delay : Period_repr.t;
  delay_increment_per_round : Period_repr.t;
  minimal_participation_ratio : Ratio_repr.t;
  consensus_committee_size : int;
  consensus_threshold : int;
  max_slashing_period : int;
  delegation_over_baking_limit : int;
  percentage_of_frozen_deposits_slashed_per_double_baking : int;
  percentage_of_frozen_deposits_slashed_per_double_endorsement : int;
  testnet_dictator : Signature.Public_key_hash.t option;
  initial_seed : State_hash.t option;
  (* If a new cache is added, please also modify the
     [cache_layout_size] value. *)
  cache_script_size : int;
  cache_stake_distribution_cycles : int;
  cache_sampler_state_cycles : int;
  dal : dal;
  sc_rollup : sc_rollup;
  zk_rollup : zk_rollup;
  adaptive_inflation : adaptive_inflation;
}

let sc_rollup_encoding =
  let open Data_encoding in
  conv
    (fun (c : sc_rollup) ->
      ( ( c.enable,
          c.arith_pvm_enable,
          c.origination_size,
          c.challenge_window_in_blocks,
          c.stake_amount,
          c.commitment_period_in_blocks,
          c.max_lookahead_in_blocks,
          c.max_active_outbox_levels,
          c.max_outbox_messages_per_level ),
        ( c.number_of_sections_in_dissection,
          c.timeout_period_in_blocks,
          c.max_number_of_stored_cemented_commitments,
          c.max_number_of_parallel_games ) ))
    (fun ( ( sc_rollup_enable,
             sc_rollup_arith_pvm_enable,
             sc_rollup_origination_size,
             sc_rollup_challenge_window_in_blocks,
             sc_rollup_stake_amount,
             sc_rollup_commitment_period_in_blocks,
             sc_rollup_max_lookahead_in_blocks,
             sc_rollup_max_active_outbox_levels,
             sc_rollup_max_outbox_messages_per_level ),
           ( sc_rollup_number_of_sections_in_dissection,
             sc_rollup_timeout_period_in_blocks,
             sc_rollup_max_number_of_cemented_commitments,
             sc_rollup_max_number_of_parallel_games ) ) ->
      {
        enable = sc_rollup_enable;
        arith_pvm_enable = sc_rollup_arith_pvm_enable;
        origination_size = sc_rollup_origination_size;
        challenge_window_in_blocks = sc_rollup_challenge_window_in_blocks;
        stake_amount = sc_rollup_stake_amount;
        commitment_period_in_blocks = sc_rollup_commitment_period_in_blocks;
        max_lookahead_in_blocks = sc_rollup_max_lookahead_in_blocks;
        max_active_outbox_levels = sc_rollup_max_active_outbox_levels;
        max_outbox_messages_per_level = sc_rollup_max_outbox_messages_per_level;
        number_of_sections_in_dissection =
          sc_rollup_number_of_sections_in_dissection;
        timeout_period_in_blocks = sc_rollup_timeout_period_in_blocks;
        max_number_of_stored_cemented_commitments =
          sc_rollup_max_number_of_cemented_commitments;
        max_number_of_parallel_games = sc_rollup_max_number_of_parallel_games;
      })
    (merge_objs
       (obj9
          (req "smart_rollup_enable" bool)
          (req "smart_rollup_arith_pvm_enable" bool)
          (req "smart_rollup_origination_size" int31)
          (req "smart_rollup_challenge_window_in_blocks" int31)
          (req "smart_rollup_stake_amount" Tez_repr.encoding)
          (req "smart_rollup_commitment_period_in_blocks" int31)
          (req "smart_rollup_max_lookahead_in_blocks" int32)
          (req "smart_rollup_max_active_outbox_levels" int32)
          (req "smart_rollup_max_outbox_messages_per_level" int31))
       (obj4
          (req "smart_rollup_number_of_sections_in_dissection" uint8)
          (req "smart_rollup_timeout_period_in_blocks" int31)
          (req "smart_rollup_max_number_of_cemented_commitments" int31)
          (req "smart_rollup_max_number_of_parallel_games" int31)))

let zk_rollup_encoding =
  let open Data_encoding in
  conv
    (fun ({
            enable;
            origination_size;
            min_pending_to_process;
            max_ticket_payload_size;
          } :
           zk_rollup) ->
      (enable, origination_size, min_pending_to_process, max_ticket_payload_size))
    (fun ( zk_rollup_enable,
           zk_rollup_origination_size,
           zk_rollup_min_pending_to_process,
           zk_rollup_max_ticket_payload_size ) ->
      {
        enable = zk_rollup_enable;
        origination_size = zk_rollup_origination_size;
        min_pending_to_process = zk_rollup_min_pending_to_process;
        max_ticket_payload_size = zk_rollup_max_ticket_payload_size;
      })
    (obj4
       (req "zk_rollup_enable" bool)
       (req "zk_rollup_origination_size" int31)
       (req "zk_rollup_min_pending_to_process" int31)
       (req "zk_rollup_max_ticket_payload_size" int31))

let adaptive_inflation_encoding =
  let open Data_encoding in
  conv
    (fun {
           staking_over_baking_limit;
           staking_over_delegation_edge;
           launch_ema_threshold;
         } ->
      ( staking_over_baking_limit,
        staking_over_delegation_edge,
        launch_ema_threshold ))
    (fun ( staking_over_baking_limit,
           staking_over_delegation_edge,
           launch_ema_threshold ) ->
      {
        staking_over_baking_limit;
        staking_over_delegation_edge;
        launch_ema_threshold;
      })
    (obj3
       (req "staking_over_baking_limit" uint8)
       (req "staking_over_delegation_edge" uint8)
       (req "adaptive_inflation_launch_ema_threshold" int32))

let reward_weights_encoding =
  let open Data_encoding in
  conv
    (fun ({
            base_total_rewards_per_minute;
            baking_reward_fixed_portion_weight;
            baking_reward_bonus_weight;
            endorsing_reward_weight;
            liquidity_baking_subsidy_weight;
            seed_nonce_revelation_tip_weight;
            vdf_revelation_tip_weight;
          } :
           reward_weights) ->
      ( base_total_rewards_per_minute,
        baking_reward_fixed_portion_weight,
        baking_reward_bonus_weight,
        endorsing_reward_weight,
        liquidity_baking_subsidy_weight,
        seed_nonce_revelation_tip_weight,
        vdf_revelation_tip_weight ))
    (fun ( base_total_rewards_per_minute,
           baking_reward_fixed_portion_weight,
           baking_reward_bonus_weight,
           endorsing_reward_weight,
           liquidity_baking_subsidy_weight,
           seed_nonce_revelation_tip_weight,
           vdf_revelation_tip_weight ) ->
      {
        base_total_rewards_per_minute;
        baking_reward_fixed_portion_weight;
        baking_reward_bonus_weight;
        endorsing_reward_weight;
        liquidity_baking_subsidy_weight;
        seed_nonce_revelation_tip_weight;
        vdf_revelation_tip_weight;
      })
    (obj7
       (req "base_total_rewards_per_minute" Tez_repr.encoding)
       (req "baking_reward_fixed_portion_weight" int31)
       (req "baking_reward_bonus_weight" int31)
       (req "endorsing_reward_weight" int31)
       (req "liquidity_baking_subsidy_weight" int31)
       (req "seed_nonce_revelation_tip_weight" int31)
       (req "vdf_revelation_tip_weight" int31))

let encoding =
  let open Data_encoding in
  conv
    (fun c ->
      ( ( c.preserved_cycles,
          c.blocks_per_cycle,
          c.blocks_per_commitment,
          c.nonce_revelation_threshold,
          c.blocks_per_stake_snapshot,
          c.cycles_per_voting_period,
          c.hard_gas_limit_per_operation,
          c.hard_gas_limit_per_block,
          c.proof_of_work_threshold,
          c.minimal_stake ),
        ( ( c.vdf_difficulty,
            c.origination_size,
            c.reward_weights,
            c.cost_per_byte,
            c.hard_storage_limit_per_operation,
            c.quorum_min ),
          ( ( c.quorum_max,
              c.min_proposal_quorum,
              c.liquidity_baking_toggle_ema_threshold,
              c.max_operations_time_to_live,
              c.minimal_block_delay,
              c.delay_increment_per_round,
              c.consensus_committee_size,
              c.consensus_threshold ),
            ( ( c.minimal_participation_ratio,
                c.max_slashing_period,
                c.delegation_over_baking_limit,
                c.percentage_of_frozen_deposits_slashed_per_double_baking,
                c.percentage_of_frozen_deposits_slashed_per_double_endorsement,
                c.testnet_dictator,
                c.initial_seed ),
              ( ( c.cache_script_size,
                  c.cache_stake_distribution_cycles,
                  c.cache_sampler_state_cycles ),
                (c.dal, ((c.sc_rollup, c.zk_rollup), c.adaptive_inflation)) ) )
          ) ) ))
    (fun ( ( preserved_cycles,
             blocks_per_cycle,
             blocks_per_commitment,
             nonce_revelation_threshold,
             blocks_per_stake_snapshot,
             cycles_per_voting_period,
             hard_gas_limit_per_operation,
             hard_gas_limit_per_block,
             proof_of_work_threshold,
             minimal_stake ),
           ( ( vdf_difficulty,
               origination_size,
               reward_weights,
               cost_per_byte,
               hard_storage_limit_per_operation,
               quorum_min ),
             ( ( quorum_max,
                 min_proposal_quorum,
                 liquidity_baking_toggle_ema_threshold,
                 max_operations_time_to_live,
                 minimal_block_delay,
                 delay_increment_per_round,
                 consensus_committee_size,
                 consensus_threshold ),
               ( ( minimal_participation_ratio,
                   max_slashing_period,
                   delegation_over_baking_limit,
                   percentage_of_frozen_deposits_slashed_per_double_baking,
                   percentage_of_frozen_deposits_slashed_per_double_endorsement,
                   testnet_dictator,
                   initial_seed ),
                 ( ( cache_script_size,
                     cache_stake_distribution_cycles,
                     cache_sampler_state_cycles ),
                   (dal, ((sc_rollup, zk_rollup), adaptive_inflation)) ) ) ) )
         ) ->
      {
        preserved_cycles;
        blocks_per_cycle;
        blocks_per_commitment;
        nonce_revelation_threshold;
        blocks_per_stake_snapshot;
        cycles_per_voting_period;
        hard_gas_limit_per_operation;
        hard_gas_limit_per_block;
        proof_of_work_threshold;
        minimal_stake;
        vdf_difficulty;
        origination_size;
        reward_weights;
        cost_per_byte;
        hard_storage_limit_per_operation;
        quorum_min;
        quorum_max;
        min_proposal_quorum;
        liquidity_baking_toggle_ema_threshold;
        max_operations_time_to_live;
        minimal_block_delay;
        delay_increment_per_round;
        minimal_participation_ratio;
        max_slashing_period;
        consensus_committee_size;
        consensus_threshold;
        delegation_over_baking_limit;
        percentage_of_frozen_deposits_slashed_per_double_baking;
        percentage_of_frozen_deposits_slashed_per_double_endorsement;
        testnet_dictator;
        initial_seed;
        cache_script_size;
        cache_stake_distribution_cycles;
        cache_sampler_state_cycles;
        dal;
        sc_rollup;
        zk_rollup;
        adaptive_inflation;
      })
    (merge_objs
       (obj10
          (req "preserved_cycles" uint8)
          (req "blocks_per_cycle" int32)
          (req "blocks_per_commitment" int32)
          (req "nonce_revelation_threshold" int32)
          (req "blocks_per_stake_snapshot" int32)
          (req "cycles_per_voting_period" int32)
          (req
             "hard_gas_limit_per_operation"
             Gas_limit_repr.Arith.z_integral_encoding)
          (req
             "hard_gas_limit_per_block"
             Gas_limit_repr.Arith.z_integral_encoding)
          (req "proof_of_work_threshold" int64)
          (req "minimal_stake" Tez_repr.encoding))
       (merge_objs
          (obj6
             (req "vdf_difficulty" int64)
             (req "origination_size" int31)
             (req "reward_weights" reward_weights_encoding)
             (req "cost_per_byte" Tez_repr.encoding)
             (req "hard_storage_limit_per_operation" z)
             (req "quorum_min" int32))
          (merge_objs
             (obj8
                (req "quorum_max" int32)
                (req "min_proposal_quorum" int32)
                (req "liquidity_baking_toggle_ema_threshold" int32)
                (req "max_operations_time_to_live" int16)
                (req "minimal_block_delay" Period_repr.encoding)
                (req "delay_increment_per_round" Period_repr.encoding)
                (req "consensus_committee_size" int31)
                (req "consensus_threshold" int31))
             (merge_objs
                (obj7
                   (req "minimal_participation_ratio" Ratio_repr.encoding)
                   (req "max_slashing_period" int31)
                   (req "delegation_over_baking_limit" uint8)
                   (req
                      "percentage_of_frozen_deposits_slashed_per_double_baking"
                      uint8)
                   (req
                      "percentage_of_frozen_deposits_slashed_per_double_endorsement"
                      uint8)
                   (opt "testnet_dictator" Signature.Public_key_hash.encoding)
                   (opt "initial_seed" State_hash.encoding))
                (merge_objs
                   (obj3
                      (req "cache_script_size" int31)
                      (req "cache_stake_distribution_cycles" int8)
                      (req "cache_sampler_state_cycles" int8))
                   (merge_objs
                      (obj1 (req "dal_parametric" dal_encoding))
                      (merge_objs
                         (merge_objs sc_rollup_encoding zk_rollup_encoding)
                         adaptive_inflation_encoding)))))))

module Internal_for_tests = struct
  let check_constants_consistency constants =
    let {
      blocks_per_cycle;
      blocks_per_commitment;
      nonce_revelation_threshold;
      blocks_per_stake_snapshot;
      _;
    } =
      constants
    in
    Error_monad.unless
      Compare.Int32.(blocks_per_commitment <= blocks_per_cycle)
      (fun () ->
        failwith
          "Inconsistent constants : blocks_per_commitment must be less than \
           blocks_per_cycle")
    >>=? fun () ->
    Error_monad.unless
      Compare.Int32.(nonce_revelation_threshold <= blocks_per_cycle)
      (fun () ->
        failwith
          "Inconsistent constants : nonce_revelation_threshold must be less \
           than blocks_per_cycle")
    >>=? fun () ->
    Error_monad.unless
      Compare.Int32.(blocks_per_cycle >= blocks_per_stake_snapshot)
      (fun () ->
        failwith
          "Inconsistent constants : blocks_per_cycle must be superior than \
           blocks_per_stake_snapshot")

  let prepare_initial_constants ?consensus_threshold ?min_proposal_quorum
      ?cost_per_byte ?reward_weights ?origination_size ?blocks_per_cycle
      ?cycles_per_voting_period ?sc_rollup_enable ?sc_rollup_arith_pvm_enable
      ?dal_enable ?zk_rollup_enable ?hard_gas_limit_per_block
      ?nonce_revelation_threshold constants =
    let open Lwt_result_syntax in
    let min_proposal_quorum =
      Option.value ~default:constants.min_proposal_quorum min_proposal_quorum
    in
    let cost_per_byte =
      Option.value ~default:constants.cost_per_byte cost_per_byte
    in
    let reward_weights =
      Option.value ~default:constants.reward_weights reward_weights
    in
    let origination_size =
      Option.value ~default:constants.origination_size origination_size
    in
    let blocks_per_cycle =
      Option.value ~default:constants.blocks_per_cycle blocks_per_cycle
    in
    let cycles_per_voting_period =
      Option.value
        ~default:constants.cycles_per_voting_period
        cycles_per_voting_period
    in
    let consensus_threshold =
      Option.value ~default:constants.consensus_threshold consensus_threshold
    in
    let sc_rollup_enable =
      Option.value ~default:constants.sc_rollup.enable sc_rollup_enable
    in
    let sc_rollup_arith_pvm_enable =
      Option.value
        ~default:constants.sc_rollup.enable
        sc_rollup_arith_pvm_enable
    in
    let dal_enable =
      Option.value ~default:constants.dal.feature_enable dal_enable
    in
    let zk_rollup_enable =
      Option.value ~default:constants.zk_rollup.enable zk_rollup_enable
    in
    let hard_gas_limit_per_block =
      Option.value
        ~default:constants.hard_gas_limit_per_block
        hard_gas_limit_per_block
    in
    let nonce_revelation_threshold =
      Option.value
        ~default:constants.nonce_revelation_threshold
        nonce_revelation_threshold
    in
    let constants =
      {
        constants with
        reward_weights;
        origination_size;
        blocks_per_cycle;
        cycles_per_voting_period;
        min_proposal_quorum;
        cost_per_byte;
        consensus_threshold;
        sc_rollup =
          {
            constants.sc_rollup with
            enable = sc_rollup_enable;
            arith_pvm_enable = sc_rollup_arith_pvm_enable;
          };
        dal = {constants.dal with feature_enable = dal_enable};
        zk_rollup = {constants.zk_rollup with enable = zk_rollup_enable};
        adaptive_inflation = constants.adaptive_inflation;
        hard_gas_limit_per_block;
        nonce_revelation_threshold;
      }
    in
    let+ () = check_constants_consistency constants in
    constants
end
