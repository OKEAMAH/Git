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

module Generated = struct
  type t = {consensus_threshold : int; reward_weights : reward_weights}

  let generate ~consensus_committee_size =
    (* The weights are expressed in [(256 * 80)]th of the total
       reward, because it is the smallest proportion used so far*)
    let consensus_threshold = (consensus_committee_size * 2 / 3) + 1 in
    let bonus_committee_size = consensus_committee_size - consensus_threshold in
    let base_total_rewards_per_minute = Tez_repr.of_mutez_exn 85_007_812L in
    let _reward_parts_whole = 20480 (* = 256 * 80 *) in
    let reward_parts_half = 10240 (* = reward_parts_whole / 2 *) in
    let reward_parts_quarter = 5120 (* = reward_parts_whole / 4 *) in
    let reward_parts_16th = 1280 (* = reward_parts_whole / 16 *) in
    {
      consensus_threshold;
      reward_weights =
        {
          base_total_rewards_per_minute;
          (* 85.007812 tez/minute *)
          baking_reward_fixed_portion_weight =
            (* 1/4 or 1/2 *)
            (if Compare.Int.(bonus_committee_size <= 0) then
             (* a fortiori, consensus_committee_size < 4 *)
             reward_parts_half
            else reward_parts_quarter);
          baking_reward_bonus_weight =
            (* 1/4 or 0 *)
            (if Compare.Int.(bonus_committee_size <= 0) then 0
            else reward_parts_quarter);
          endorsing_reward_weight = reward_parts_half;
          (* 1/2 *)
          (* All block (baking + endorsing)rewards sum to 1 ( *256*80 ) *)
          liquidity_baking_subsidy_weight = reward_parts_16th;
          (* 1/16 *)
          seed_nonce_revelation_tip_weight = 1;
          (* 1/20480 *)
          vdf_revelation_tip_weight = 1;
          (* 1/20480 *)
        };
    }
end

let init (c : Constants_parametric_previous_repr.t) : t =
  let cryptobox_parameters =
    {
      Dal.page_size = c.dal.cryptobox_parameters.page_size;
      number_of_shards = c.dal.cryptobox_parameters.number_of_shards;
      slot_size = c.dal.cryptobox_parameters.slot_size;
      redundancy_factor = c.dal.cryptobox_parameters.redundancy_factor;
    }
  in
  let dal =
    {
      feature_enable = c.dal.feature_enable;
      number_of_slots = c.dal.number_of_slots;
      attestation_lag = c.dal.attestation_lag;
      attestation_threshold = c.dal.attestation_threshold;
      blocks_per_epoch = c.dal.blocks_per_epoch;
      cryptobox_parameters;
    }
  in
  let sc_rollup =
    {
      enable = c.sc_rollup.enable;
      arith_pvm_enable = c.sc_rollup.arith_pvm_enable;
      origination_size = c.sc_rollup.origination_size;
      challenge_window_in_blocks = c.sc_rollup.challenge_window_in_blocks;
      stake_amount = c.sc_rollup.stake_amount;
      commitment_period_in_blocks = c.sc_rollup.commitment_period_in_blocks;
      max_lookahead_in_blocks = c.sc_rollup.max_lookahead_in_blocks;
      max_active_outbox_levels = c.sc_rollup.max_active_outbox_levels;
      max_outbox_messages_per_level = c.sc_rollup.max_outbox_messages_per_level;
      number_of_sections_in_dissection =
        c.sc_rollup.number_of_sections_in_dissection;
      timeout_period_in_blocks = c.sc_rollup.timeout_period_in_blocks;
      max_number_of_stored_cemented_commitments =
        c.sc_rollup.max_number_of_stored_cemented_commitments;
      max_number_of_parallel_games = c.sc_rollup.max_number_of_parallel_games;
    }
  in
  let zk_rollup =
    {
      enable = c.zk_rollup.enable;
      origination_size = c.zk_rollup.origination_size;
      min_pending_to_process = c.zk_rollup.min_pending_to_process;
      max_ticket_payload_size = c.tx_rollup.max_ticket_payload_size;
    }
  in
  let adaptive_inflation =
    {
      staking_over_baking_limit = 5;
      staking_over_delegation_edge = 2;
      launch_ema_threshold =
        (* 80% of the max ema (which is 2 billion) *) 1_600_000_000l;
    }
  in
  let reward_weights =
    let c_gen =
      Generated.generate ~consensus_committee_size:c.consensus_committee_size
    in
    c_gen.reward_weights
  in
  let percentage_of_frozen_deposits_slashed_per_double_endorsement =
    100 * c.ratio_of_frozen_deposits_slashed_per_double_endorsement.numerator
    / c.ratio_of_frozen_deposits_slashed_per_double_endorsement.denominator
  in
  let percentage_of_frozen_deposits_slashed_per_double_baking =
    let double_baking_punishment_times_100 =
      Int64.mul 100L (Tez_repr.to_mutez c.double_baking_punishment)
    in
    let percentage_rounded_down =
      Int64.div
        double_baking_punishment_times_100
        (Tez_repr.to_mutez c.minimal_stake)
    in
    1 + Int64.to_int percentage_rounded_down
  in
  let delegation_over_baking_limit = (100 / c.frozen_deposits_percentage) - 1 in
  {
    preserved_cycles = c.preserved_cycles;
    blocks_per_cycle = c.blocks_per_cycle;
    blocks_per_commitment = c.blocks_per_commitment;
    nonce_revelation_threshold = c.nonce_revelation_threshold;
    blocks_per_stake_snapshot = c.blocks_per_stake_snapshot;
    cycles_per_voting_period = c.cycles_per_voting_period;
    hard_gas_limit_per_operation = c.hard_gas_limit_per_operation;
    hard_gas_limit_per_block = c.hard_gas_limit_per_block;
    proof_of_work_threshold = c.proof_of_work_threshold;
    minimal_stake = c.minimal_stake;
    vdf_difficulty = c.vdf_difficulty;
    origination_size = c.origination_size;
    max_operations_time_to_live = c.max_operations_time_to_live;
    reward_weights;
    cost_per_byte = c.cost_per_byte;
    hard_storage_limit_per_operation = c.hard_storage_limit_per_operation;
    quorum_min = c.quorum_min;
    quorum_max = c.quorum_max;
    min_proposal_quorum = c.min_proposal_quorum;
    liquidity_baking_toggle_ema_threshold =
      c.liquidity_baking_toggle_ema_threshold;
    minimal_block_delay = c.minimal_block_delay;
    delay_increment_per_round = c.delay_increment_per_round;
    consensus_committee_size = c.consensus_committee_size;
    consensus_threshold = c.consensus_threshold;
    minimal_participation_ratio = c.minimal_participation_ratio;
    max_slashing_period = c.max_slashing_period;
    delegation_over_baking_limit;
    percentage_of_frozen_deposits_slashed_per_double_baking;
    percentage_of_frozen_deposits_slashed_per_double_endorsement;
    (* The `testnet_dictator` should absolutely be None on mainnet *)
    testnet_dictator = c.testnet_dictator;
    initial_seed = c.initial_seed;
    cache_script_size = c.cache_script_size;
    cache_stake_distribution_cycles = c.cache_stake_distribution_cycles;
    cache_sampler_state_cycles = c.cache_sampler_state_cycles;
    dal;
    sc_rollup;
    zk_rollup;
    adaptive_inflation;
  }

let patch_base_total_rewards_per_minute base_total_rewards_per_minute constants
    =
  {
    constants with
    reward_weights =
      {constants.reward_weights with base_total_rewards_per_minute};
  }

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

(** The challenge window is about two weeks with 15s block-time,
    (4 * 60 * 24 * 14).
    WARNING: changing this value also impacts
    [sc_rollup_max_active_outbox_levels]. See below. *)
let sc_rollup_challenge_window_in_blocks = 80_640

(** Number of active levels kept for executing outbox messages.

    WARNING: Changing this value impacts the storage charge for
    applying messages from the outbox. It also requires migration for
    remapping existing active outbox levels to new indices. *)
let sc_rollup_max_active_outbox_levels =
  Int32.of_int sc_rollup_challenge_window_in_blocks

(** Maximum number of outbox messages per level.

    WARNING: changing this value impacts the storage size a rollup has to
    pay for at origination time. *)
let sc_rollup_max_outbox_messages_per_level = 100

(** The timeout period is about a week with 15s block-time,
    (4 * 60 * 24 * 7).

    It suffers from the same risk of censorship as
    {!sc_rollup_challenge_windows_in_blocks} so we use the same value.
*)
let sc_rollup_timeout_period_in_blocks = 40_320

(** We want to allow a max lookahead in blocks of 4 weeks, so the rollup
    can still move forward even if its impossible to cement commitments.

    As there is a challenge window of 2 weeks, and because the maximum
    duration of a game is 2 weeks, the hypothetical maximum time
    to cement a block is a month, (4 * 60 * 24 * 30).

    Be careful, this constant has an impact of the maximum cost of
    a rollup on the storage:
    [maximum_cost_in_storage =
       (sc_rollup_max_lookahead_in_blocks / commitment_period) *
       max_commitment_storage_size_in_bytes *
       cost_per_byte]

    With the current values:
    [maximum_cost_in_storage = 348.3 tez]
*)
let sc_rollup_max_lookahead_in_blocks = 172_800l

(* DAL/FIXME https://gitlab.com/tezos/tezos/-/issues/3177

   Think harder about those values. *)
let default_cryptobox_parameters =
  {
    Dal.page_size = 4096;
    slot_size = 1 lsl 20;
    redundancy_factor = 16;
    number_of_shards = 2048;
  }

let default_dal =
  {
    feature_enable = false;
    number_of_slots = 256;
    attestation_lag = 1;
    attestation_threshold = 50;
    blocks_per_epoch = 32l;
    cryptobox_parameters = default_cryptobox_parameters;
  }

let constants_mainnet =
  let consensus_committee_size = 7000 in
  let block_time = 15 in
  let Generated.
        {
          consensus_threshold;
          reward_weights =
            {
              base_total_rewards_per_minute;
              baking_reward_fixed_portion_weight;
              baking_reward_bonus_weight;
              endorsing_reward_weight;
              liquidity_baking_subsidy_weight;
              seed_nonce_revelation_tip_weight;
              vdf_revelation_tip_weight;
            };
        } =
    Generated.generate ~consensus_committee_size
  in
  {
    preserved_cycles = 5;
    blocks_per_cycle = 16384l;
    blocks_per_commitment = 128l;
    nonce_revelation_threshold = 512l;
    blocks_per_stake_snapshot = 1024l;
    cycles_per_voting_period = 5l;
    hard_gas_limit_per_operation =
      Gas_limit_repr.Arith.(integral_of_int_exn 1_040_000);
    hard_gas_limit_per_block =
      Gas_limit_repr.Arith.(integral_of_int_exn 2_600_000);
    (* When reducing block times, consider adapting this constant so
       the block production's overhead is not too important. *)
    proof_of_work_threshold = Int64.(sub (shift_left 1L 48) 1L);
    minimal_stake = Tez_repr.(mul_exn one 6_000);
    (* VDF's difficulty must be a multiple of `nonce_revelation_threshold` times
       the block time. At the moment it is equal to 8B = 8000 * 5 * .2M with
          - 8000 ~= 512 * 15 that is nonce_revelation_threshold * block time
          - .2M  ~= number of modular squaring per second on benchmark machine
         with 2.8GHz CPU
          - 5: security factor (strictly higher than the ratio between highest CPU
         clock rate and benchmark machine that is 8.43/2.8 ~= 3 *)
    vdf_difficulty = 8_000_000_000L;
    origination_size = 257;
    reward_weights =
      {
        base_total_rewards_per_minute;
        (* 85.007812 tez/minute *)
        baking_reward_fixed_portion_weight;
        (* 1/4th of total block rewards *)
        baking_reward_bonus_weight;
        (* all bonus rewards = fixed rewards *)
        endorsing_reward_weight;
        (* all baking rewards = all endorsing rewards *)
        liquidity_baking_subsidy_weight;
        (* 1/16th of block rewards *)
        seed_nonce_revelation_tip_weight;
        (* 1/20480 of block rewards *)
        vdf_revelation_tip_weight;
        (* 1/20480 of block rewards *)
      };
    hard_storage_limit_per_operation = Z.of_int 60_000;
    cost_per_byte = Tez_repr.of_mutez_exn 250L;
    quorum_min = 20_00l;
    quorum_max = 70_00l;
    min_proposal_quorum = 5_00l;
    (* 1/2 window size of 2000 blocks with precision of 1_000_000
       for integer computation *)
    liquidity_baking_toggle_ema_threshold = 1_000_000_000l;
    (* The rationale behind the value of this constant is that an
       operation should be considered alive for about one hour:

         minimal_block_delay * max_operations_time_to_live = 3600

       The unit for this value is a block.
    *)
    max_operations_time_to_live = 240;
    minimal_block_delay = Period_repr.of_seconds_exn (Int64.of_int block_time);
    delay_increment_per_round = Period_repr.of_seconds_exn 8L;
    consensus_committee_size;
    consensus_threshold;
    (* 4667 slots *)
    minimal_participation_ratio = {numerator = 2; denominator = 3};
    max_slashing_period = 2;
    delegation_over_baking_limit = 9;
    percentage_of_frozen_deposits_slashed_per_double_baking = 11;
    percentage_of_frozen_deposits_slashed_per_double_endorsement = 50;
    (* The `testnet_dictator` should absolutely be None on mainnet *)
    testnet_dictator = None;
    initial_seed = None;
    (* A cache for contract source code and storage. Its size has been
       chosen not too exceed 100 000 000 bytes. *)
    cache_script_size = 100_000_000;
    (* A cache for the stake distribution for all cycles stored at any
       moment: preserved_cycles + max_slashing_period + 1 = 8 currently. *)
    cache_stake_distribution_cycles = 8;
    (* One for the sampler state for all cycles stored at any moment (as above). *)
    cache_sampler_state_cycles = 8;
    dal = default_dal;
    sc_rollup =
      {
        enable = true;
        arith_pvm_enable = false;
        (* The following value is chosen to prevent spam. *)
        origination_size = 6_314;
        challenge_window_in_blocks = sc_rollup_challenge_window_in_blocks;
        commitment_period_in_blocks = 60;
        stake_amount = Tez_repr.of_mutez_exn 10_000_000_000L;
        max_lookahead_in_blocks = sc_rollup_max_lookahead_in_blocks;
        max_active_outbox_levels = sc_rollup_max_active_outbox_levels;
        max_outbox_messages_per_level = sc_rollup_max_outbox_messages_per_level;
        (* The default number of required sections in a dissection *)
        number_of_sections_in_dissection = 32;
        timeout_period_in_blocks = sc_rollup_timeout_period_in_blocks;
        (* We store multiple cemented commitments because we want to
            allow the execution of outbox messages against cemented
            commitments that are older than the last cemented commitment.
            The execution of an outbox message is a manager operation,
            and manager operations are kept in the mempool for one
            hour. Hence we only need to ensure that an outbox message
            can be validated against a cemented commitment produced in the
            last hour. If we assume that the rollup is operating without
            issues, that is no commitments are being refuted and commitments
            are published and cemented regularly by one rollup node, we can
            expect commitments to be cemented approximately every 15
            minutes, or equivalently we can expect 5 commitments to be
            published in one hour (at minutes 0, 15, 30, 45 and 60).
            Therefore, we need to keep 5 cemented commitments to guarantee
            that the execution of an outbox operation can always be
            validated against a cemented commitment while it is in the
            mempool. *)
        max_number_of_stored_cemented_commitments = 5;
        max_number_of_parallel_games = 32;
      };
    zk_rollup =
      {
        enable = false;
        (* TODO: https://gitlab.com/tezos/tezos/-/issues/3726
           The following constants need to be refined. *)
        origination_size = 4_000;
        min_pending_to_process = 10;
        max_ticket_payload_size = 2_048;
      };
    adaptive_inflation =
      {
        staking_over_baking_limit = 5;
        staking_over_delegation_edge = 2;
        launch_ema_threshold = 1_600_000_000l;
      };
  }

(* Sandbox and test networks's Dal cryptobox are computed by this function:
   - Redundancy_factor is provided as a parameter;
   - The other fields are derived from mainnet's values, as divisions by the
     provided factor. *)
let derive_cryptobox_parameters ~redundancy_factor ~mainnet_constants_divider =
  let m = default_cryptobox_parameters in
  {
    Dal.redundancy_factor;
    page_size = m.page_size / mainnet_constants_divider;
    slot_size = m.slot_size / mainnet_constants_divider;
    number_of_shards = m.number_of_shards / mainnet_constants_divider;
  }

let constants_sandbox =
  let consensus_committee_size = 256 in
  let block_time = 1 in
  let Generated.{consensus_threshold = _; reward_weights} =
    Generated.generate ~consensus_committee_size
  in
  {
    constants_mainnet with
    dal =
      {
        constants_mainnet.dal with
        number_of_slots = 16;
        blocks_per_epoch = 2l;
        cryptobox_parameters =
          derive_cryptobox_parameters
            ~redundancy_factor:8
            ~mainnet_constants_divider:32;
      };
    reward_weights;
    preserved_cycles = 2;
    blocks_per_cycle = 8l;
    blocks_per_commitment = 4l;
    nonce_revelation_threshold = 4l;
    blocks_per_stake_snapshot = 4l;
    cycles_per_voting_period = 8l;
    proof_of_work_threshold = Int64.(sub (shift_left 1L 62) 1L);
    vdf_difficulty = 50_000L;
    minimal_block_delay = Period_repr.of_seconds_exn (Int64.of_int block_time);
    delay_increment_per_round = Period_repr.one_second;
    consensus_committee_size = 256;
    consensus_threshold = 0;
    max_slashing_period = 2;
    delegation_over_baking_limit = 19;
  }

let constants_test =
  let consensus_committee_size = 25 in
  let Generated.{consensus_threshold; reward_weights} =
    Generated.generate ~consensus_committee_size
  in
  {
    constants_mainnet with
    dal =
      {
        constants_mainnet.dal with
        number_of_slots = 8;
        blocks_per_epoch = 2l;
        cryptobox_parameters =
          derive_cryptobox_parameters
            ~redundancy_factor:4
            ~mainnet_constants_divider:64;
      };
    reward_weights;
    preserved_cycles = 3;
    blocks_per_cycle = 12l;
    blocks_per_commitment = 4l;
    nonce_revelation_threshold = 4l;
    blocks_per_stake_snapshot = 4l;
    cycles_per_voting_period = 2l;
    proof_of_work_threshold =
      Int64.(sub (shift_left 1L 62) 1L) (* 1/4 of nonces are accepted *);
    vdf_difficulty = 50_000L;
    consensus_committee_size;
    consensus_threshold (* 17 slots *);
    max_slashing_period = 2;
    delegation_over_baking_limit =
      19
      (* Not 9 so that multiplication by a percentage and
         divisions by a limit do not easily get intermingled. *);
  }

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
      ?nonce_revelation_threshold ?preserved_cycles ?initial_seed
      ?consensus_committee_size ?minimal_block_delay ?delay_increment_per_round
      constants =
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
    let preserved_cycles =
      Option.value ~default:constants.preserved_cycles preserved_cycles
    in
    let initial_seed =
      Option.value ~default:constants.initial_seed initial_seed
    in
    let consensus_committee_size =
      Option.value
        ~default:constants.consensus_committee_size
        consensus_committee_size
    in
    let minimal_block_delay =
      Option.value ~default:constants.minimal_block_delay minimal_block_delay
    in
    let delay_increment_per_round =
      Option.value
        ~default:constants.delay_increment_per_round
        delay_increment_per_round
    in
    let constants =
      {
        constants with
        preserved_cycles;
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
        initial_seed;
        consensus_committee_size;
        minimal_block_delay;
        delay_increment_per_round;
      }
    in
    let+ () = check_constants_consistency constants in
    constants
end
