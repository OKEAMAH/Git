meta:
  id: id_011__pthangz2__parameters
  endian: be
types:
  endorsement_reward:
    seq:
    - id: size_of_endorsement_reward
      type: s4
    - id: endorsement_reward
      type: endorsement_reward_entries
      size: size_of_endorsement_reward
      repeat: eos
  endorsement_reward_entries:
    seq:
    - id: id_011__pthangz2__mutez
      type: n
  baking_reward_per_endorsement:
    seq:
    - id: size_of_baking_reward_per_endorsement
      type: s4
    - id: baking_reward_per_endorsement
      type: baking_reward_per_endorsement_entries
      size: size_of_baking_reward_per_endorsement
      repeat: eos
  baking_reward_per_endorsement_entries:
    seq:
    - id: id_011__pthangz2__mutez
      type: n
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
  time_between_blocks:
    seq:
    - id: size_of_time_between_blocks
      type: s4
    - id: time_between_blocks
      type: time_between_blocks_entries
      size: size_of_time_between_blocks
      repeat: eos
  time_between_blocks_entries:
    seq:
    - id: time_between_blocks_elt
      type: s8
  commitments:
    seq:
    - id: size_of_commitments
      type: s4
    - id: commitments
      type: commitments_entries
      size: size_of_commitments
      repeat: eos
  commitments_entries:
    seq:
    - id: blinded__public__key__hash
      size: 20
    - id: id_011__pthangz2__mutez
      type: n
  bootstrap_contracts:
    seq:
    - id: size_of_bootstrap_contracts
      type: s4
    - id: bootstrap_contracts
      type: bootstrap_contracts_entries
      size: size_of_bootstrap_contracts
      repeat: eos
  bootstrap_contracts_entries:
    seq:
    - id: delegate
      type: public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: amount
      type: n
    - id: script
      type: id_011__pthangz2__scripted__contracts
  id_011__pthangz2__scripted__contracts:
    seq:
    - id: code
      type: code
    - id: storage
      type: storage
  storage:
    seq:
    - id: size_of_storage
      type: s4
    - id: storage
      size: size_of_storage
  code:
    seq:
    - id: size_of_code
      type: s4
    - id: code
      size: size_of_code
  bootstrap_accounts:
    seq:
    - id: size_of_bootstrap_accounts
      type: s4
    - id: bootstrap_accounts
      type: bootstrap_accounts_entries
      size: size_of_bootstrap_accounts
      repeat: eos
  bootstrap_accounts_entries:
    seq:
    - id: bootstrap_accounts_elt_tag
      type: u1
      enum: bootstrap_accounts_elt_tag
    - id: bootstrap_accounts_elt_public_key_known
      type: bootstrap_accounts_elt_public_key_known
      if: (bootstrap_accounts_elt_tag == bootstrap_accounts_elt_tag::Public_key_known)
    - id: bootstrap_accounts_elt_public_key_unknown
      type: bootstrap_accounts_elt_public_key_unknown
      if: (bootstrap_accounts_elt_tag == bootstrap_accounts_elt_tag::Public_key_unknown)
  bootstrap_accounts_elt_public_key_unknown:
    seq:
    - id: signature__v0__public_key_hash
      type: public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: id_011__pthangz2__mutez
      type: n
  public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: public_key_hash_ed25519
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::Ed25519)
    - id: public_key_hash_secp256k1
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::Secp256k1)
    - id: public_key_hash_p256
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::P256)
  bootstrap_accounts_elt_public_key_known:
    seq:
    - id: signature__v0__public_key
      type: public_key
      doc: A Ed25519, Secp256k1, or P256 public key
    - id: id_011__pthangz2__mutez
      type: n
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
  public_key:
    seq:
    - id: public_key_tag
      type: u1
      enum: public_key_tag
    - id: public_key_ed25519
      size: 32
      if: (public_key_tag == public_key_tag::Ed25519)
    - id: public_key_secp256k1
      size: 33
      if: (public_key_tag == public_key_tag::Secp256k1)
    - id: public_key_p256
      size: 33
      if: (public_key_tag == public_key_tag::P256)
enums:
  bool:
    0: false
    255: true
  public_key_hash_tag:
    0: Ed25519
    1: Secp256k1
    2: P256
  public_key_tag:
    0: Ed25519
    1: Secp256k1
    2: P256
  bootstrap_accounts_elt_tag:
    0: Public_key_known
    1: Public_key_unknown
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
- id: no_reward_cycles_tag
  type: u1
  enum: bool
- id: no_reward_cycles
  type: s4
  if: (no_reward_cycles_tag == bool::true)
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
  type: n
- id: liquidity_baking_sunset_level
  type: s4
- id: liquidity_baking_escape_ema_threshold
  type: s4
