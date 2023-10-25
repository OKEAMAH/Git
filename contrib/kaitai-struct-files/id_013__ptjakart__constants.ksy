meta:
  id: id_013__ptjakart__constants
  endian: be
doc: ! 'Encoding id: 013-PtJakart.constants'
types:
  ratio_of_frozen_deposits_slashed_per_double_endorsement:
    seq:
    - id: numerator
      type: u2
    - id: denominator
      type: u2
  minimal_participation_ratio:
    seq:
    - id: numerator
      type: u2
    - id: denominator
      type: u2
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
  bool:
    0: false
    255: true
seq:
- id: proof_of_work_nonce_size
  type: u1
- id: nonce_length
  type: u1
- id: max_anon_ops_per_block
  type: u1
- id: max_operation_data_length
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: max_proposals_per_delegate
  type: u1
- id: max_micheline_node_count
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: max_micheline_bytes_limit
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: max_allowed_global_constants_depth
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: cache_layout_size
  type: u1
- id: michelson_maximum_type_size
  type: u2
- id: preserved_cycles
  type: u1
- id: blocks_per_cycle
  type: s4
- id: blocks_per_commitment
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
- id: tokens_per_roll
  type: n
- id: seed_nonce_revelation_tip
  type: n
- id: origination_size
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: baking_reward_fixed_portion
  type: n
- id: baking_reward_bonus_per_slot
  type: n
- id: endorsing_reward_per_slot
  type: n
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
- id: liquidity_baking_subsidy
  type: n
- id: liquidity_baking_sunset_level
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
  valid:
    min: -1073741824
    max: 1073741823
- id: consensus_threshold
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: minimal_participation_ratio
  type: minimal_participation_ratio
- id: max_slashing_period
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: frozen_deposits_percentage
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: double_baking_punishment
  type: n
- id: ratio_of_frozen_deposits_slashed_per_double_endorsement
  type: ratio_of_frozen_deposits_slashed_per_double_endorsement
- id: initial_seed_tag
  type: u1
  enum: bool
- id: initial_seed
  size: 32
  if: (initial_seed_tag == bool::true)
- id: cache_script_size
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: cache_stake_distribution_cycles
  type: s1
- id: cache_sampler_state_cycles
  type: s1
- id: tx_rollup_enable
  type: u1
  enum: bool
- id: tx_rollup_origination_size
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: tx_rollup_hard_size_limit_per_inbox
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: tx_rollup_hard_size_limit_per_message
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: tx_rollup_max_withdrawals_per_batch
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: tx_rollup_commitment_bond
  type: n
- id: tx_rollup_finality_period
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: tx_rollup_withdraw_period
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: tx_rollup_max_inboxes_count
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: tx_rollup_max_messages_per_inbox
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: tx_rollup_max_commitments_count
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: tx_rollup_cost_per_byte_ema_factor
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: tx_rollup_max_ticket_payload_size
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: tx_rollup_rejection_max_proof_size
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: tx_rollup_sunset_level
  type: s4
- id: sc_rollup_enable
  type: u1
  enum: bool
- id: sc_rollup_origination_size
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: sc_rollup_challenge_window_in_blocks
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: sc_rollup_max_available_messages
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
