meta:
  id: id_013__ptjakart__parameters
  endian: be
doc: ! 'Encoding id: 013-PtJakart.parameters'
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
  commitments:
    seq:
    - id: len_commitments
      type: u4
      valid:
        max: 1073741823
    - id: commitments_
      type: commitments_
      size: len_commitments
  commitments_:
    seq:
    - id: commitments_entries
      type: commitments_entries
      repeat: eos
  commitments_entries:
    seq:
    - id: commitments_elt_field0
      size: 20
      doc: blinded__public__key__hash
    - id: commitments_elt_field1
      type: n
      doc: id_013__ptjakart__mutez
  bootstrap_contracts:
    seq:
    - id: len_bootstrap_contracts
      type: u4
      valid:
        max: 1073741823
    - id: bootstrap_contracts_
      type: bootstrap_contracts_
      size: len_bootstrap_contracts
  bootstrap_contracts_:
    seq:
    - id: bootstrap_contracts_entries
      type: bootstrap_contracts_entries
      repeat: eos
  bootstrap_contracts_entries:
    seq:
    - id: delegate_tag
      type: u1
      enum: bool
    - id: delegate
      type: public_key_hash_
      if: (delegate_tag == bool::true)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: amount
      type: n
    - id: script
      type: id_013__ptjakart__scripted__contracts_
  id_013__ptjakart__scripted__contracts_:
    seq:
    - id: code
      type: code
    - id: storage
      type: storage
  storage:
    seq:
    - id: len_storage
      type: u4
      valid:
        max: 1073741823
    - id: storage
      size: len_storage
  code:
    seq:
    - id: len_code
      type: u4
      valid:
        max: 1073741823
    - id: code
      size: len_code
  public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  bootstrap_accounts:
    seq:
    - id: len_bootstrap_accounts
      type: u4
      valid:
        max: 1073741823
    - id: bootstrap_accounts_
      type: bootstrap_accounts_
      size: len_bootstrap_accounts
  bootstrap_accounts_:
    seq:
    - id: bootstrap_accounts_entries
      type: bootstrap_accounts_entries
      repeat: eos
  bootstrap_accounts_entries:
    seq:
    - id: bootstrap_accounts_elt_tag
      type: u1
      enum: bootstrap_accounts_elt_tag
    - id: public_key_known__bootstrap_accounts_elt
      type: public_key_known__bootstrap_accounts_elt
      if: (bootstrap_accounts_elt_tag == bootstrap_accounts_elt_tag::public_key_known)
    - id: public_key_unknown__bootstrap_accounts_elt
      type: public_key_unknown__bootstrap_accounts_elt
      if: (bootstrap_accounts_elt_tag == bootstrap_accounts_elt_tag::public_key_unknown)
  public_key_unknown__bootstrap_accounts_elt:
    seq:
    - id: public_key_unknown_field0
      type: public_key_unknown__public_key_hash_
      doc: ! 'A Ed25519, Secp256k1, or P256 public key hash


        signature__v0__public_key_hash'
    - id: public_key_unknown_field1
      type: n
      doc: id_013__ptjakart__mutez
  public_key_unknown__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: public_key_unknown__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: public_key_unknown__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: public_key_unknown__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  public_key_known__bootstrap_accounts_elt:
    seq:
    - id: public_key_known_field0
      type: public_key_known__public_key_
      doc: ! 'A Ed25519, Secp256k1, or P256 public key


        signature__v0__public_key'
    - id: public_key_known_field1
      type: n
      doc: id_013__ptjakart__mutez
  n:
    seq:
    - id: n
      type: n_chunk
      repeat: until
      repeat-until: not (_.has_more).as<bool>
  n_chunk:
    seq:
    - id: has_more
      type: b1be
    - id: payload
      type: b7be
  public_key_known__public_key_:
    seq:
    - id: public_key_tag
      type: u1
      enum: public_key_tag
    - id: public_key_known__ed25519__public_key
      size: 32
      if: (public_key_tag == public_key_tag::ed25519)
    - id: public_key_known__secp256k1__public_key
      size: 33
      if: (public_key_tag == public_key_tag::secp256k1)
    - id: public_key_known__p256__public_key
      size: 33
      if: (public_key_tag == public_key_tag::p256)
enums:
  bool:
    0: false
    255: true
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
  public_key_tag:
    0: ed25519
    1: secp256k1
    2: p256
  bootstrap_accounts_elt_tag:
    0: public_key_known
    1: public_key_unknown
seq:
- id: bootstrap_accounts
  type: bootstrap_accounts
- id: bootstrap_contracts
  type: bootstrap_contracts
- id: commitments
  type: commitments
- id: security_deposit_ramp_up_cycles_tag
  type: u1
  enum: bool
- id: security_deposit_ramp_up_cycles
  type: s4
  if: (security_deposit_ramp_up_cycles_tag == bool::true)
  valid:
    min: -1073741824
    max: 1073741823
- id: no_reward_cycles_tag
  type: u1
  enum: bool
- id: no_reward_cycles
  type: s4
  if: (no_reward_cycles_tag == bool::true)
  valid:
    min: -1073741824
    max: 1073741823
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
