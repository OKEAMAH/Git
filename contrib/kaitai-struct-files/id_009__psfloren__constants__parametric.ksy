meta:
  id: id_009__psfloren__constants__parametric
  endian: be
doc: ! 'Encoding id: 009-PsFLoren.constants.parametric'
types:
  endorsement_reward:
    seq:
    - id: len_endorsement_reward_dyn
      type: u4
      valid:
        max: 1073741823
    - id: endorsement_reward_dyn
      type: endorsement_reward_dyn
      size: len_endorsement_reward_dyn
  endorsement_reward_dyn:
    seq:
    - id: endorsement_reward_entries
      type: endorsement_reward_entries
      repeat: eos
  endorsement_reward_entries:
    seq:
    - id: id_009__psfloren__mutez
      type: n
  baking_reward_per_endorsement:
    seq:
    - id: len_baking_reward_per_endorsement_dyn
      type: u4
      valid:
        max: 1073741823
    - id: baking_reward_per_endorsement_dyn
      type: baking_reward_per_endorsement_dyn
      size: len_baking_reward_per_endorsement_dyn
  baking_reward_per_endorsement_dyn:
    seq:
    - id: baking_reward_per_endorsement_entries
      type: baking_reward_per_endorsement_entries
      repeat: eos
  baking_reward_per_endorsement_entries:
    seq:
    - id: id_009__psfloren__mutez
      type: n
  int31:
    seq:
    - id: int31
      type: s4
      valid:
        min: -1073741824
        max: 1073741823
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
    - id: len_time_between_blocks_dyn
      type: u4
      valid:
        max: 1073741823
    - id: time_between_blocks_dyn
      type: time_between_blocks_dyn
      size: len_time_between_blocks_dyn
  time_between_blocks_dyn:
    seq:
    - id: time_between_blocks_entries
      type: time_between_blocks_entries
      repeat: eos
  time_between_blocks_entries:
    seq:
    - id: time_between_blocks_elt
      type: s8
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
  type: int31
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
