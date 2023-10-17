meta:
  id: id_008__ptedo2zk__constants__parametric
  endian: be
types:
  endorsement_reward:
    seq:
    - id: size_of_endorsement_reward
      type: s4
    - id: endorsement_reward
      type: n
      size: size_of_endorsement_reward
      repeat: eos
  baking_reward_per_endorsement:
    seq:
    - id: size_of_baking_reward_per_endorsement
      type: s4
    - id: baking_reward_per_endorsement
      type: n
      size: size_of_baking_reward_per_endorsement
      repeat: eos
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
  type: n
- id: michelson_maximum_type_size
  type: u2
- id: seed_nonce_revelation_tip
  type: n
- id: origination_size
  type: s4
- id: block_security_deposit
  type: n
- id: endorsement_security_deposit
  type: n
- id: baking_reward_per_endorsement
  type: baking_reward_per_endorsement
- id: endorsement_reward
  type: endorsement_reward
- id: cost_per_byte
  type: n
- id: hard_storage_limit_per_operation
  type: z
- id: test_chain_duration
  type: s8
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
