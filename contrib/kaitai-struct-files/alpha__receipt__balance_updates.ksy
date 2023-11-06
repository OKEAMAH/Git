meta:
  id: alpha__receipt__balance_updates
  endian: be
doc: ! 'Encoding id: alpha.receipt.balance_updates'
types:
  alpha__operation_metadata__alpha__balance_updates:
    seq:
    - id: len_alpha__operation_metadata__alpha__balance_updates
      type: u4
      valid:
        max: 1073741823
    - id: alpha__operation_metadata__alpha__balance_updates
      type: alpha__operation_metadata__alpha__balance_updates_entries
      size: len_alpha__operation_metadata__alpha__balance_updates
      repeat: eos
  alpha__operation_metadata__alpha__balance_updates_entries:
    seq:
    - id: alpha__operation_metadata__alpha__balance_and_update
      type: alpha__operation_metadata__alpha__balance_and_update
    - id: alpha__operation_metadata__alpha__update_origin
      type: u1
      enum: origin_tag
  alpha__operation_metadata__alpha__balance_and_update:
    seq:
    - id: alpha__operation_metadata__alpha__balance_and_update_tag
      type: u1
      enum: alpha__operation_metadata__alpha__balance_and_update_tag
    - id: smart_rollup_refutation_rewards__alpha__operation_metadata__alpha__balance_and_update
      type: s8
      if: (alpha__operation_metadata__alpha__balance_and_update_tag == ::alpha__operation_metadata__alpha__balance_and_update_tag::alpha__operation_metadata__alpha__balance_and_update_tag::smart_rollup_refutation_rewards)
    - id: unstaked_deposits__alpha__operation_metadata__alpha__balance_and_update
      type: unstaked_deposits__alpha__operation_metadata__alpha__balance_and_update
      if: (alpha__operation_metadata__alpha__balance_and_update_tag == alpha__operation_metadata__alpha__balance_and_update_tag::unstaked_deposits)
    - id: staking_delegator_numerator__alpha__operation_metadata__alpha__balance_and_update
      type: staking_delegator_numerator__alpha__operation_metadata__alpha__balance_and_update
      if: (alpha__operation_metadata__alpha__balance_and_update_tag == alpha__operation_metadata__alpha__balance_and_update_tag::staking_delegator_numerator)
    - id: staking_delegate_denominator__alpha__operation_metadata__alpha__balance_and_update
      type: staking_delegate_denominator__alpha__operation_metadata__alpha__balance_and_update
      if: (alpha__operation_metadata__alpha__balance_and_update_tag == alpha__operation_metadata__alpha__balance_and_update_tag::staking_delegate_denominator)
  staking_delegate_denominator__alpha__operation_metadata__alpha__balance_and_update:
    seq:
    - id: delegate
      type: staking_delegate_denominator__public_key_hash
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: alpha__operation_metadata__alpha__staking_abstract_quantity
      type: s8
  staking_delegate_denominator__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: staking_delegate_denominator__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  staking_delegator_numerator__alpha__operation_metadata__alpha__balance_and_update:
    seq:
    - id: delegator
      type: staking_delegator_numerator__alpha__contract_id
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: alpha__operation_metadata__alpha__staking_abstract_quantity
      type: s8
  staking_delegator_numerator__alpha__contract_id:
    seq:
    - id: alpha__contract_id_tag
      type: u1
      enum: alpha__contract_id_tag
    - id: staking_delegator_numerator__implicit__alpha__contract_id
      type: staking_delegator_numerator__implicit__public_key_hash
      if: (alpha__contract_id_tag == ::alpha__contract_id_tag::alpha__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: staking_delegator_numerator__originated__alpha__contract_id
      type: staking_delegator_numerator__originated__alpha__contract_id
      if: (alpha__contract_id_tag == alpha__contract_id_tag::originated)
  staking_delegator_numerator__originated__alpha__contract_id:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  staking_delegator_numerator__implicit__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: staking_delegator_numerator__implicit__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  unstaked_deposits__alpha__operation_metadata__alpha__balance_and_update:
    seq:
    - id: staker
      type: unstaked_deposits__alpha__staker
      doc: ! >-
        staker: Abstract notion of staker used in operation receipts, either a single
        staker or all the stakers delegating to some delegate.
    - id: cycle
      type: s4
    - id: alpha__operation_metadata__alpha__tez_balance_update
      type: s8
  unstaked_deposits__alpha__staker:
    seq:
    - id: alpha__staker_tag
      type: u1
      enum: alpha__staker_tag
    - id: unstaked_deposits__shared__alpha__staker
      type: unstaked_deposits__shared__public_key_hash
      if: (alpha__staker_tag == ::alpha__staker_tag::alpha__staker_tag::shared)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
  unstaked_deposits__shared__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: unstaked_deposits__shared__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  unstaked_deposits__single__alpha__staker:
    seq:
    - id: contract
      type: unstaked_deposits__single__alpha__contract_id
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: delegate
      type: unstaked_deposits__single__public_key_hash
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
  unstaked_deposits__single__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: unstaked_deposits__single__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  unstaked_deposits__single__alpha__contract_id:
    seq:
    - id: alpha__contract_id_tag
      type: u1
      enum: alpha__contract_id_tag
    - id: unstaked_deposits__single__implicit__alpha__contract_id
      type: unstaked_deposits__single__implicit__public_key_hash
      if: (alpha__contract_id_tag == ::alpha__contract_id_tag::alpha__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: unstaked_deposits__single__originated__alpha__contract_id
      type: unstaked_deposits__single__originated__alpha__contract_id
      if: (alpha__contract_id_tag == alpha__contract_id_tag::originated)
  unstaked_deposits__single__originated__alpha__contract_id:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  unstaked_deposits__single__implicit__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: unstaked_deposits__single__implicit__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  frozen_bonds__alpha__operation_metadata__alpha__balance_and_update:
    seq:
    - id: contract
      type: frozen_bonds__alpha__contract_id
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: bond_id
      type: frozen_bonds__alpha__bond_id
    - id: alpha__operation_metadata__alpha__tez_balance_update
      type: s8
  frozen_bonds__alpha__bond_id:
    seq:
    - id: alpha__bond_id_tag
      type: u1
      enum: alpha__bond_id_tag
    - id: frozen_bonds__smart_rollup_bond_id__alpha__bond_id
      size: 20
      if: (alpha__bond_id_tag == ::alpha__bond_id_tag::alpha__bond_id_tag::smart_rollup_bond_id)
  frozen_bonds__alpha__contract_id:
    seq:
    - id: alpha__contract_id_tag
      type: u1
      enum: alpha__contract_id_tag
    - id: frozen_bonds__implicit__alpha__contract_id
      type: frozen_bonds__implicit__public_key_hash
      if: (alpha__contract_id_tag == ::alpha__contract_id_tag::alpha__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: frozen_bonds__originated__alpha__contract_id
      type: frozen_bonds__originated__alpha__contract_id
      if: (alpha__contract_id_tag == alpha__contract_id_tag::originated)
  frozen_bonds__originated__alpha__contract_id:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  frozen_bonds__implicit__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: frozen_bonds__implicit__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  commitments__alpha__operation_metadata__alpha__balance_and_update:
    seq:
    - id: committer
      size: 20
    - id: alpha__operation_metadata__alpha__tez_balance_update
      type: s8
  lost_attesting_rewards__alpha__operation_metadata__alpha__balance_and_update:
    seq:
    - id: delegate
      type: lost_attesting_rewards__public_key_hash
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: participation
      type: u1
      enum: bool
    - id: revelation
      type: u1
      enum: bool
    - id: alpha__operation_metadata__alpha__tez_balance_update
      type: s8
  lost_attesting_rewards__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: lost_attesting_rewards__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  deposits__alpha__operation_metadata__alpha__balance_and_update:
    seq:
    - id: staker
      type: deposits__alpha__staker
      doc: ! >-
        staker: Abstract notion of staker used in operation receipts, either a single
        staker or all the stakers delegating to some delegate.
    - id: alpha__operation_metadata__alpha__tez_balance_update
      type: s8
  deposits__alpha__staker:
    seq:
    - id: alpha__staker_tag
      type: u1
      enum: alpha__staker_tag
    - id: deposits__shared__alpha__staker
      type: deposits__shared__public_key_hash
      if: (alpha__staker_tag == ::alpha__staker_tag::alpha__staker_tag::shared)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
  deposits__shared__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: deposits__shared__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  deposits__single__alpha__staker:
    seq:
    - id: contract
      type: deposits__single__alpha__contract_id
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: delegate
      type: deposits__single__public_key_hash
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
  deposits__single__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: deposits__single__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  deposits__single__alpha__contract_id:
    seq:
    - id: alpha__contract_id_tag
      type: u1
      enum: alpha__contract_id_tag
    - id: deposits__single__implicit__alpha__contract_id
      type: deposits__single__implicit__public_key_hash
      if: (alpha__contract_id_tag == ::alpha__contract_id_tag::alpha__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: deposits__single__originated__alpha__contract_id
      type: deposits__single__originated__alpha__contract_id
      if: (alpha__contract_id_tag == alpha__contract_id_tag::originated)
  deposits__single__originated__alpha__contract_id:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  deposits__single__implicit__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: deposits__single__implicit__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  contract__alpha__operation_metadata__alpha__balance_and_update:
    seq:
    - id: contract
      type: contract__alpha__contract_id
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: alpha__operation_metadata__alpha__tez_balance_update
      type: s8
  contract__alpha__contract_id:
    seq:
    - id: alpha__contract_id_tag
      type: u1
      enum: alpha__contract_id_tag
    - id: contract__implicit__alpha__contract_id
      type: contract__implicit__public_key_hash
      if: (alpha__contract_id_tag == ::alpha__contract_id_tag::alpha__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: contract__originated__alpha__contract_id
      type: contract__originated__alpha__contract_id
      if: (alpha__contract_id_tag == alpha__contract_id_tag::originated)
  contract__originated__alpha__contract_id:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  contract__implicit__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: contract__implicit__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
enums:
  origin_tag:
    0: block_application
    1: protocol_migration
    2: subsidy
    3: simulation
  alpha__bond_id_tag:
    1: smart_rollup_bond_id
  bool:
    0: false
    255: true
  alpha__staker_tag:
    0: single
    1: shared
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
    3: bls
  alpha__contract_id_tag:
    0: implicit
    1: originated
  alpha__operation_metadata__alpha__balance_and_update_tag:
    0: contract
    2: block_fees
    4: deposits
    5: nonce_revelation_rewards
    7: attesting_rewards
    8: baking_rewards
    9: baking_bonuses
    11: storage_fees
    12: double_signing_punishments
    13: lost_attesting_rewards
    14: liquidity_baking_subsidies
    15: burned
    16: commitments
    17: bootstrap
    18: invoice
    19: initial_commitments
    20: minted
    21: frozen_bonds
    24: smart_rollup_refutation_punishments
    25: smart_rollup_refutation_rewards
    26: unstaked_deposits
    27: staking_delegator_numerator
    28: staking_delegate_denominator
seq:
- id: alpha__operation_metadata__alpha__balance_updates
  type: alpha__operation_metadata__alpha__balance_updates
