meta:
  id: id_005__psbabym1__parameters
  endian: be
doc: ! 'Encoding id: 005-PsBabyM1.parameters'
types:
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
  int31:
    seq:
    - id: int31
      type: s4
      valid:
        min: -1073741824
        max: 1073741823
  commitments:
    seq:
    - id: len_commitments_dyn
      type: u4
      valid:
        max: 1073741823
    - id: commitments_dyn
      type: commitments_dyn
      size: len_commitments_dyn
  commitments_dyn:
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
      doc: id_005__psbabym1__mutez
  bootstrap_contracts:
    seq:
    - id: len_bootstrap_contracts_dyn
      type: u4
      valid:
        max: 1073741823
    - id: bootstrap_contracts_dyn
      type: bootstrap_contracts_dyn
      size: len_bootstrap_contracts_dyn
  bootstrap_contracts_dyn:
    seq:
    - id: bootstrap_contracts_entries
      type: bootstrap_contracts_entries
      repeat: eos
  bootstrap_contracts_entries:
    seq:
    - id: delegate
      type: public_key_hash_
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: amount
      type: n
    - id: script
      type: id_005__psbabym1__scripted__contracts_
  id_005__psbabym1__scripted__contracts_:
    seq:
    - id: code
      type: bytes_dyn_uint30
    - id: storage
      type: bytes_dyn_uint30
  bytes_dyn_uint30:
    seq:
    - id: len_bytes_dyn_uint30
      type: u4
      valid:
        max: 1073741823
    - id: bytes_dyn_uint30
      size: len_bytes_dyn_uint30
  uint30:
    seq:
    - id: uint30
      type: u4
      valid:
        max: 1073741823
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
    - id: len_bootstrap_accounts_dyn
      type: u4
      valid:
        max: 1073741823
    - id: bootstrap_accounts_dyn
      type: bootstrap_accounts_dyn
      size: len_bootstrap_accounts_dyn
  bootstrap_accounts_dyn:
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
      doc: id_005__psbabym1__mutez
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
      doc: id_005__psbabym1__mutez
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
  type: int31
  if: (security_deposit_ramp_up_cycles_tag == bool::true)
- id: no_reward_cycles_tag
  type: u1
  enum: bool
- id: no_reward_cycles
  type: int31
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
- id: block_reward
  type: n
- id: endorsement_reward
  type: n
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
