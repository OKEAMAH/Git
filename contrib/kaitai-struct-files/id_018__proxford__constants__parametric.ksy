meta:
  id: id_018__proxford__constants__parametric
  endian: be
types:
  adaptive_rewards_params:
    seq:
    - id: issuance_ratio_min
      type: issuance_ratio_min
    - id: issuance_ratio_max
      type: issuance_ratio_max
    - id: max_bonus
      type: s8
    - id: growth_rate
      type: s8
    - id: center_dz
      type: center_dz
    - id: radius_dz
      type: radius_dz
  radius_dz:
    seq:
    - id: numerator
      type: z
    - id: denominator
      type: z
  center_dz:
    seq:
    - id: numerator
      type: z
    - id: denominator
      type: z
  issuance_ratio_max:
    seq:
    - id: numerator
      type: z
    - id: denominator
      type: z
  issuance_ratio_min:
    seq:
    - id: numerator
      type: z
    - id: denominator
      type: z
  smart_rollup_reveal_activation_level:
    seq:
    - id: raw_data
      type: s4
    - id: metadata
      type: s4
    - id: dal_page
      type: s4
  dal_parametric:
    seq:
    - id: feature_enable
      type: u1
      enum: bool
    - id: number_of_slots
      type: s2
    - id: attestation_lag
      type: s2
    - id: attestation_threshold
      type: s2
    - id: blocks_per_epoch
      type: s4
    - id: redundancy_factor
      type: u1
    - id: page_size
      type: u2
    - id: slot_size
      type: s4
    - id: number_of_shards
      type: u2
  public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: public_key_hash_Ed25519
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::Ed25519)
    - id: public_key_hash_Secp256k1
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::Secp256k1)
    - id: public_key_hash_P256
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::P256)
    - id: public_key_hash_Bls
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::Bls)
  minimal_participation_ratio:
    seq:
    - id: numerator
      type: u2
    - id: denominator
      type: u2
  issuance_weights:
    seq:
    - id: base_total_issued_per_minute
      type: n
    - id: baking_reward_fixed_portion_weight
      type: s4
    - id: baking_reward_bonus_weight
      type: s4
    - id: attesting_reward_weight
      type: s4
    - id: liquidity_baking_subsidy_weight
      type: s4
    - id: seed_nonce_revelation_tip_weight
      type: s4
    - id: vdf_revelation_tip_weight
      type: s4
  n:
    seq:
    - id: n
      type: n_chunk
      repeat: until
      repeat-until: not (_.has_more).as<bool>
  z:
    seq:
    - id: has_tail
      type: b1be
    - id: sign
      type: b1be
    - id: payload
      type: b6be
    - id: tail
      type: n_chunk
      repeat: until
      repeat-until: not (_.has_more).as<bool>
      if: has_tail.as<bool>
  n_chunk:
    seq:
    - id: has_more
      type: b1be
    - id: payload
      type: b7be
enums:
  public_key_hash_tag:
    0: Ed25519
    1: Secp256k1
    2: P256
    3: Bls
  bool:
    0: false
    255: true
seq:
- id: preserved_cycles
  type: u1
- id: blocks_per_cycle
  type: s4
- id: blocks_per_commitment
  type: s4
- id: nonce_revelation_threshold
  type: s4
- id: blocks_per_stake_snapshot
  type: s4
- id: cycles_per_voting_period
  type: s4
- id: hard_gas_limit_per_operation
  type: z
- id: hard_gas_limit_per_block
  type: z
- id: proof_of_work_threshold
  type: s8
- id: minimal_stake
  type: n
- id: minimal_frozen_stake
  type: n
- id: vdf_difficulty
  type: s8
- id: origination_size
  type: s4
- id: issuance_weights
  type: issuance_weights
- id: cost_per_byte
  type: n
- id: hard_storage_limit_per_operation
  type: z
- id: quorum_min
  type: s4
- id: quorum_max
  type: s4
- id: min_proposal_quorum
  type: s4
- id: liquidity_baking_toggle_ema_threshold
  type: s4
- id: max_operations_time_to_live
  type: s2
- id: minimal_block_delay
  type: s8
- id: delay_increment_per_round
  type: s8
- id: consensus_committee_size
  type: s4
- id: consensus_threshold
  type: s4
- id: minimal_participation_ratio
  type: minimal_participation_ratio
- id: max_slashing_period
  type: s4
- id: limit_of_delegation_over_baking
  type: u1
- id: percentage_of_frozen_deposits_slashed_per_double_baking
  type: u1
- id: percentage_of_frozen_deposits_slashed_per_double_attestation
  type: u1
- id: testnet_dictator_tag
  type: u1
  enum: bool
- id: testnet_dictator
  type: public_key_hash
  if: (testnet_dictator_tag == bool::true)
  doc: A Ed25519, Secp256k1, P256, or BLS public key hash
- id: initial_seed_tag
  type: u1
  enum: bool
- id: initial_seed
  size: 32
  if: (initial_seed_tag == bool::true)
- id: cache_script_size
  type: s4
- id: cache_stake_distribution_cycles
  type: s1
- id: cache_sampler_state_cycles
  type: s1
- id: dal_parametric
  type: dal_parametric
- id: smart_rollup_enable
  type: u1
  enum: bool
- id: smart_rollup_arith_pvm_enable
  type: u1
  enum: bool
- id: smart_rollup_origination_size
  type: s4
- id: smart_rollup_challenge_window_in_blocks
  type: s4
- id: smart_rollup_stake_amount
  type: n
- id: smart_rollup_commitment_period_in_blocks
  type: s4
- id: smart_rollup_max_lookahead_in_blocks
  type: s4
- id: smart_rollup_max_active_outbox_levels
  type: s4
- id: smart_rollup_max_outbox_messages_per_level
  type: s4
- id: smart_rollup_number_of_sections_in_dissection
  type: u1
- id: smart_rollup_timeout_period_in_blocks
  type: s4
- id: smart_rollup_max_number_of_cemented_commitments
  type: s4
- id: smart_rollup_max_number_of_parallel_games
  type: s4
- id: smart_rollup_reveal_activation_level
  type: smart_rollup_reveal_activation_level
- id: zk_rollup_enable
  type: u1
  enum: bool
- id: zk_rollup_origination_size
  type: s4
- id: zk_rollup_min_pending_to_process
  type: s4
- id: zk_rollup_max_ticket_payload_size
  type: s4
- id: global_limit_of_staking_over_baking
  type: u1
- id: edge_of_staking_over_delegation
  type: u1
- id: adaptive_issuance_launch_ema_threshold
  type: s4
- id: adaptive_rewards_params
  type: adaptive_rewards_params
