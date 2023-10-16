meta:
  id: id_010__ptgranad__constants
  endian: be
types:
  endorsement_reward:
    seq:
    - id: size_of_endorsement_reward
      type: s4
    - id: endorsement_reward
      type: id_010__ptgranad__mutez
      size: size_of_endorsement_reward
      repeat: eos
  baking_reward_per_endorsement:
    seq:
    - id: size_of_baking_reward_per_endorsement
      type: s4
    - id: baking_reward_per_endorsement
      type: id_010__ptgranad__mutez
      size: size_of_baking_reward_per_endorsement
      repeat: eos
  id_010__ptgranad__mutez:
    seq:
    - id: id_010__ptgranad__mutez
      type: n
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
  time_between_blocks:
    seq:
    - id: size_of_time_between_blocks
      type: s4
    - id: time_between_blocks
      type: s8
      size: size_of_time_between_blocks
      repeat: eos
seq:
- id: proof_of_work_nonce_size
  type: u1
- id: nonce_length
  type: u1
- id: max_anon_ops_per_block
  type: u1
- id: max_operation_data_length
  type: s4
- id: max_proposals_per_delegate
  type: u1
- id: preserved_cycles
  type: u1
- id: blocks_per_cycle
  type: s4
- id: blocks_per_commitment
  type: s4
- id: blocks_per_roll_snapshot
  type: s4
- id: blocks_per_voting_period
  type: s4
- id: time_between_blocks
  type: time_between_blocks
- id: endorsers_per_block
  type: u2
- id: hard_gas_limit_per_operation
  type: z
- id: hard_gas_limit_per_block
  type: z
- id: proof_of_work_threshold
  type: s8
- id: tokens_per_roll
  type: id_010__ptgranad__mutez
  size: 10
- id: michelson_maximum_type_size
  type: u2
- id: seed_nonce_revelation_tip
  type: id_010__ptgranad__mutez
  size: 10
- id: origination_size
  type: s4
- id: block_security_deposit
  type: id_010__ptgranad__mutez
  size: 10
- id: endorsement_security_deposit
  type: id_010__ptgranad__mutez
  size: 10
- id: baking_reward_per_endorsement
  type: baking_reward_per_endorsement
- id: endorsement_reward
  type: endorsement_reward
- id: cost_per_byte
  type: id_010__ptgranad__mutez
  size: 10
- id: hard_storage_limit_per_operation
  type: z
- id: quorum_min
  type: s4
- id: quorum_max
  type: s4
- id: min_proposal_quorum
  type: s4
- id: initial_endorsers
  type: u2
- id: delay_per_missing_endorsement
  type: s8
- id: minimal_block_delay
  type: s8
- id: liquidity_baking_subsidy
  type: id_010__ptgranad__mutez
  size: 10
- id: liquidity_baking_sunset_level
  type: s4
- id: liquidity_baking_escape_ema_threshold
  type: s4
