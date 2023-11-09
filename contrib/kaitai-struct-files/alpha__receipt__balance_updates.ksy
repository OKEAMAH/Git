meta:
  id: alpha__receipt__balance_updates
  endian: be
doc: ! 'Encoding id: alpha.receipt.balance_updates'
types:
  alpha__bond_id:
    seq:
    - id: alpha__bond_id_tag
      type: u1
      enum: alpha__bond_id_tag
    - id: smart_rollup_bond_id
      size: 20
      if: (alpha__bond_id_tag == alpha__bond_id_tag::smart_rollup_bond_id)
  alpha__contract_id:
    doc: ! >-
      A contract handle: A contract notation as given to an RPC or inside scripts.
      Can be a base58 implicit contract hash or a base58 originated contract hash.
    seq:
    - id: alpha__contract_id_tag
      type: u1
      enum: alpha__contract_id_tag
    - id: implicit
      type: public_key_hash
      if: (alpha__contract_id_tag == alpha__contract_id_tag::implicit)
    - id: originated
      type: originated
      if: (alpha__contract_id_tag == alpha__contract_id_tag::originated)
  alpha__operation_metadata__alpha__balance_and_update:
    seq:
    - id: alpha__operation_metadata__alpha__balance_and_update_tag
      type: u1
      enum: alpha__operation_metadata__alpha__balance_and_update_tag
    - id: contract
      type: contract
      if: (alpha__operation_metadata__alpha__balance_and_update_tag == alpha__operation_metadata__alpha__balance_and_update_tag::contract)
    - id: block_fees
      type: s8
      if: (alpha__operation_metadata__alpha__balance_and_update_tag == alpha__operation_metadata__alpha__balance_and_update_tag::block_fees)
    - id: deposits
      type: deposits
      if: (alpha__operation_metadata__alpha__balance_and_update_tag == alpha__operation_metadata__alpha__balance_and_update_tag::deposits)
    - id: nonce_revelation_rewards
      type: s8
      if: (alpha__operation_metadata__alpha__balance_and_update_tag == alpha__operation_metadata__alpha__balance_and_update_tag::nonce_revelation_rewards)
    - id: attesting_rewards
      type: s8
      if: (alpha__operation_metadata__alpha__balance_and_update_tag == alpha__operation_metadata__alpha__balance_and_update_tag::attesting_rewards)
    - id: baking_rewards
      type: s8
      if: (alpha__operation_metadata__alpha__balance_and_update_tag == alpha__operation_metadata__alpha__balance_and_update_tag::baking_rewards)
    - id: baking_bonuses
      type: s8
      if: (alpha__operation_metadata__alpha__balance_and_update_tag == alpha__operation_metadata__alpha__balance_and_update_tag::baking_bonuses)
    - id: storage_fees
      type: s8
      if: (alpha__operation_metadata__alpha__balance_and_update_tag == alpha__operation_metadata__alpha__balance_and_update_tag::storage_fees)
    - id: double_signing_punishments
      type: s8
      if: (alpha__operation_metadata__alpha__balance_and_update_tag == alpha__operation_metadata__alpha__balance_and_update_tag::double_signing_punishments)
    - id: lost_attesting_rewards
      type: lost_attesting_rewards
      if: (alpha__operation_metadata__alpha__balance_and_update_tag == alpha__operation_metadata__alpha__balance_and_update_tag::lost_attesting_rewards)
    - id: liquidity_baking_subsidies
      type: s8
      if: (alpha__operation_metadata__alpha__balance_and_update_tag == alpha__operation_metadata__alpha__balance_and_update_tag::liquidity_baking_subsidies)
    - id: burned
      type: s8
      if: (alpha__operation_metadata__alpha__balance_and_update_tag == alpha__operation_metadata__alpha__balance_and_update_tag::burned)
    - id: commitments
      type: commitments
      if: (alpha__operation_metadata__alpha__balance_and_update_tag == alpha__operation_metadata__alpha__balance_and_update_tag::commitments)
    - id: bootstrap
      type: s8
      if: (alpha__operation_metadata__alpha__balance_and_update_tag == alpha__operation_metadata__alpha__balance_and_update_tag::bootstrap)
    - id: invoice
      type: s8
      if: (alpha__operation_metadata__alpha__balance_and_update_tag == alpha__operation_metadata__alpha__balance_and_update_tag::invoice)
    - id: initial_commitments
      type: s8
      if: (alpha__operation_metadata__alpha__balance_and_update_tag == alpha__operation_metadata__alpha__balance_and_update_tag::initial_commitments)
    - id: minted
      type: s8
      if: (alpha__operation_metadata__alpha__balance_and_update_tag == alpha__operation_metadata__alpha__balance_and_update_tag::minted)
    - id: frozen_bonds
      type: frozen_bonds
      if: (alpha__operation_metadata__alpha__balance_and_update_tag == alpha__operation_metadata__alpha__balance_and_update_tag::frozen_bonds)
    - id: smart_rollup_refutation_punishments
      type: s8
      if: (alpha__operation_metadata__alpha__balance_and_update_tag == alpha__operation_metadata__alpha__balance_and_update_tag::smart_rollup_refutation_punishments)
    - id: smart_rollup_refutation_rewards
      type: s8
      if: (alpha__operation_metadata__alpha__balance_and_update_tag == alpha__operation_metadata__alpha__balance_and_update_tag::smart_rollup_refutation_rewards)
    - id: unstaked_deposits
      type: unstaked_deposits
      if: (alpha__operation_metadata__alpha__balance_and_update_tag == alpha__operation_metadata__alpha__balance_and_update_tag::unstaked_deposits)
    - id: staking_delegator_numerator
      type: staking_delegator_numerator
      if: (alpha__operation_metadata__alpha__balance_and_update_tag == alpha__operation_metadata__alpha__balance_and_update_tag::staking_delegator_numerator)
    - id: staking_delegate_denominator
      type: staking_delegate_denominator
      if: (alpha__operation_metadata__alpha__balance_and_update_tag == alpha__operation_metadata__alpha__balance_and_update_tag::staking_delegate_denominator)
  alpha__operation_metadata__alpha__balance_updates:
    seq:
    - id: len_alpha__operation_metadata__alpha__balance_updates
      type: s4
    - id: alpha__operation_metadata__alpha__balance_updates
      type: alpha__operation_metadata__alpha__balance_updates_entries
      size: len_alpha__operation_metadata__alpha__balance_updates
      repeat: eos
  alpha__operation_metadata__alpha__balance_updates_entries:
    seq:
    - id: alpha__operation_metadata__alpha__balance_and_update
      type: alpha__operation_metadata__alpha__balance_and_update
    - id: origin
      type: u1
      enum: origin_tag
  alpha__staker:
    doc: ! >-
      staker: Abstract notion of staker used in operation receipts, either a single
      staker or all the stakers delegating to some delegate.
    seq:
    - id: alpha__staker_tag
      type: u1
      enum: alpha__staker_tag
    - id: single
      type: single
      if: (alpha__staker_tag == alpha__staker_tag::single)
    - id: shared
      type: public_key_hash
      if: (alpha__staker_tag == alpha__staker_tag::shared)
  commitments:
    seq:
    - id: committer
      size: 20
    - id: change
      type: s8
  contract:
    seq:
    - id: contract
      type: alpha__contract_id
    - id: change
      type: s8
  deposits:
    seq:
    - id: staker
      type: alpha__staker
    - id: change
      type: s8
  frozen_bonds:
    seq:
    - id: contract
      type: alpha__contract_id
    - id: bond_id
      type: alpha__bond_id
    - id: change
      type: s8
  lost_attesting_rewards:
    seq:
    - id: delegate
      type: public_key_hash
    - id: participation
      type: u1
      enum: bool
    - id: revelation
      type: u1
      enum: bool
    - id: change
      type: s8
  originated:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  public_key_hash:
    doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: ed25519
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: secp256k1
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: p256
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: bls
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  single:
    seq:
    - id: contract
      type: alpha__contract_id
    - id: delegate
      type: public_key_hash
  staking_delegate_denominator:
    seq:
    - id: delegate
      type: public_key_hash
    - id: change
      type: s8
  staking_delegator_numerator:
    seq:
    - id: delegator
      type: alpha__contract_id
    - id: change
      type: s8
  unstaked_deposits:
    seq:
    - id: staker
      type: alpha__staker
    - id: cycle
      type: s4
    - id: change
      type: s8
enums:
  alpha__bond_id_tag:
    1: smart_rollup_bond_id
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
  alpha__staker_tag:
    0: single
    1: shared
  bool:
    0: false
    255: true
  origin_tag:
    0: block_application
    1: protocol_migration
    2: subsidy
    3: simulation
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
    3: bls
seq:
- id: alpha__operation_metadata__alpha__balance_updates
  type: alpha__operation_metadata__alpha__balance_updates
