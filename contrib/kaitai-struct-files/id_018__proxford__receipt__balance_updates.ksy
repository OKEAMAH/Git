meta:
  id: id_018__proxford__receipt__balance_updates
  endian: be
doc: ! 'Encoding id: 018-Proxford.receipt.balance_updates'
types:
  contract__id_018__proxford__contract_id_:
    seq:
    - id: id_018__proxford__contract_id_tag
      type: u1
      enum: id_018__proxford__contract_id_tag
    - id: contract__implicit__id_018__proxford__contract_id
      type: contract__implicit__public_key_hash_
      if: (id_018__proxford__contract_id_tag == id_018__proxford__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: contract__originated__id_018__proxford__contract_id
      type: contract__originated__id_018__proxford__contract_id
      if: (id_018__proxford__contract_id_tag == id_018__proxford__contract_id_tag::originated)
  contract__implicit__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: contract__implicit__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: contract__implicit__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: contract__implicit__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: contract__implicit__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  contract__originated__id_018__proxford__contract_id:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  deposits__id_018__proxford__staker_:
    seq:
    - id: id_018__proxford__staker_tag
      type: u1
      enum: id_018__proxford__staker_tag
    - id: deposits__single__id_018__proxford__staker
      type: deposits__single__id_018__proxford__staker
      if: (id_018__proxford__staker_tag == id_018__proxford__staker_tag::single)
    - id: deposits__shared__id_018__proxford__staker
      type: deposits__shared__public_key_hash_
      if: (id_018__proxford__staker_tag == id_018__proxford__staker_tag::shared)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
  deposits__shared__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: deposits__shared__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: deposits__shared__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: deposits__shared__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: deposits__shared__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  deposits__single__id_018__proxford__contract_id_:
    seq:
    - id: id_018__proxford__contract_id_tag
      type: u1
      enum: id_018__proxford__contract_id_tag
    - id: deposits__single__implicit__id_018__proxford__contract_id
      type: deposits__single__implicit__public_key_hash_
      if: (id_018__proxford__contract_id_tag == id_018__proxford__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: deposits__single__originated__id_018__proxford__contract_id
      type: deposits__single__originated__id_018__proxford__contract_id
      if: (id_018__proxford__contract_id_tag == id_018__proxford__contract_id_tag::originated)
  deposits__single__id_018__proxford__staker:
    seq:
    - id: contract
      type: deposits__single__id_018__proxford__contract_id_
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: delegate
      type: deposits__single__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
  deposits__single__implicit__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: deposits__single__implicit__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: deposits__single__implicit__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: deposits__single__implicit__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: deposits__single__implicit__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  deposits__single__originated__id_018__proxford__contract_id:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  deposits__single__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: deposits__single__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: deposits__single__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: deposits__single__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: deposits__single__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  frozen_bonds__id_018__proxford__bond_id_:
    seq:
    - id: id_018__proxford__bond_id_tag
      type: u1
      enum: id_018__proxford__bond_id_tag
    - id: frozen_bonds__smart_rollup_bond_id__id_018__proxford__bond_id
      size: 20
      if: (id_018__proxford__bond_id_tag == id_018__proxford__bond_id_tag::smart_rollup_bond_id)
  frozen_bonds__id_018__proxford__contract_id_:
    seq:
    - id: id_018__proxford__contract_id_tag
      type: u1
      enum: id_018__proxford__contract_id_tag
    - id: frozen_bonds__implicit__id_018__proxford__contract_id
      type: frozen_bonds__implicit__public_key_hash_
      if: (id_018__proxford__contract_id_tag == id_018__proxford__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: frozen_bonds__originated__id_018__proxford__contract_id
      type: frozen_bonds__originated__id_018__proxford__contract_id
      if: (id_018__proxford__contract_id_tag == id_018__proxford__contract_id_tag::originated)
  frozen_bonds__id_018__proxford__operation_metadata__alpha__balance:
    seq:
    - id: contract
      type: frozen_bonds__id_018__proxford__contract_id_
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: bond_id
      type: frozen_bonds__id_018__proxford__bond_id_
  frozen_bonds__implicit__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: frozen_bonds__implicit__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: frozen_bonds__implicit__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: frozen_bonds__implicit__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: frozen_bonds__implicit__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  frozen_bonds__originated__id_018__proxford__contract_id:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  id_018__proxford__operation_metadata__alpha__balance_:
    seq:
    - id: id_018__proxford__operation_metadata__alpha__balance_tag
      type: u1
      enum: id_018__proxford__operation_metadata__alpha__balance_tag
    - id: contract__id_018__proxford__operation_metadata__alpha__balance
      type: contract__id_018__proxford__contract_id_
      if: (id_018__proxford__operation_metadata__alpha__balance_tag == id_018__proxford__operation_metadata__alpha__balance_tag::contract)
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: deposits__id_018__proxford__operation_metadata__alpha__balance
      type: deposits__id_018__proxford__staker_
      if: (id_018__proxford__operation_metadata__alpha__balance_tag == id_018__proxford__operation_metadata__alpha__balance_tag::deposits)
      doc: ! >-
        staker: Abstract notion of staker used in operation receipts, either a single
        staker or all the stakers delegating to some delegate.
    - id: lost_attesting_rewards__id_018__proxford__operation_metadata__alpha__balance
      type: lost_attesting_rewards__id_018__proxford__operation_metadata__alpha__balance
      if: (id_018__proxford__operation_metadata__alpha__balance_tag == id_018__proxford__operation_metadata__alpha__balance_tag::lost_attesting_rewards)
    - id: commitments__id_018__proxford__operation_metadata__alpha__balance
      size: 20
      if: (id_018__proxford__operation_metadata__alpha__balance_tag == id_018__proxford__operation_metadata__alpha__balance_tag::commitments)
    - id: frozen_bonds__id_018__proxford__operation_metadata__alpha__balance
      type: frozen_bonds__id_018__proxford__operation_metadata__alpha__balance
      if: (id_018__proxford__operation_metadata__alpha__balance_tag == id_018__proxford__operation_metadata__alpha__balance_tag::frozen_bonds)
    - id: unstaked_deposits__id_018__proxford__operation_metadata__alpha__balance
      type: unstaked_deposits__id_018__proxford__operation_metadata__alpha__balance
      if: (id_018__proxford__operation_metadata__alpha__balance_tag == id_018__proxford__operation_metadata__alpha__balance_tag::unstaked_deposits)
  id_018__proxford__operation_metadata__alpha__balance_updates_:
    seq:
    - id: len_id_018__proxford__operation_metadata__alpha__balance_updates_dyn
      type: u4
      valid:
        max: 1073741823
    - id: id_018__proxford__operation_metadata__alpha__balance_updates_dyn
      type: id_018__proxford__operation_metadata__alpha__balance_updates_dyn
      size: len_id_018__proxford__operation_metadata__alpha__balance_updates_dyn
  id_018__proxford__operation_metadata__alpha__balance_updates_dyn:
    seq:
    - id: id_018__proxford__operation_metadata__alpha__balance_updates_entries
      type: id_018__proxford__operation_metadata__alpha__balance_updates_entries
      repeat: eos
  id_018__proxford__operation_metadata__alpha__balance_updates_entries:
    seq:
    - id: id_018__proxford__operation_metadata__alpha__balance_
      type: id_018__proxford__operation_metadata__alpha__balance_
    - id: id_018__proxford__operation_metadata__alpha__balance_update
      type: s8
    - id: id_018__proxford__operation_metadata__alpha__update_origin
      type: u1
      enum: origin_tag
  lost_attesting_rewards__id_018__proxford__operation_metadata__alpha__balance:
    seq:
    - id: delegate
      type: lost_attesting_rewards__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: participation
      type: u1
      enum: bool
    - id: revelation
      type: u1
      enum: bool
  lost_attesting_rewards__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: lost_attesting_rewards__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: lost_attesting_rewards__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: lost_attesting_rewards__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: lost_attesting_rewards__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  unstaked_deposits__id_018__proxford__operation_metadata__alpha__balance:
    seq:
    - id: staker
      type: unstaked_deposits__id_018__proxford__staker_
      doc: ! >-
        staker: Abstract notion of staker used in operation receipts, either a single
        staker or all the stakers delegating to some delegate.
    - id: cycle
      type: s4
  unstaked_deposits__id_018__proxford__staker_:
    seq:
    - id: id_018__proxford__staker_tag
      type: u1
      enum: id_018__proxford__staker_tag
    - id: unstaked_deposits__single__id_018__proxford__staker
      type: unstaked_deposits__single__id_018__proxford__staker
      if: (id_018__proxford__staker_tag == id_018__proxford__staker_tag::single)
    - id: unstaked_deposits__shared__id_018__proxford__staker
      type: unstaked_deposits__shared__public_key_hash_
      if: (id_018__proxford__staker_tag == id_018__proxford__staker_tag::shared)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
  unstaked_deposits__shared__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: unstaked_deposits__shared__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: unstaked_deposits__shared__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: unstaked_deposits__shared__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: unstaked_deposits__shared__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  unstaked_deposits__single__id_018__proxford__contract_id_:
    seq:
    - id: id_018__proxford__contract_id_tag
      type: u1
      enum: id_018__proxford__contract_id_tag
    - id: unstaked_deposits__single__implicit__id_018__proxford__contract_id
      type: unstaked_deposits__single__implicit__public_key_hash_
      if: (id_018__proxford__contract_id_tag == id_018__proxford__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: unstaked_deposits__single__originated__id_018__proxford__contract_id
      type: unstaked_deposits__single__originated__id_018__proxford__contract_id
      if: (id_018__proxford__contract_id_tag == id_018__proxford__contract_id_tag::originated)
  unstaked_deposits__single__id_018__proxford__staker:
    seq:
    - id: contract
      type: unstaked_deposits__single__id_018__proxford__contract_id_
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: delegate
      type: unstaked_deposits__single__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
  unstaked_deposits__single__implicit__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: unstaked_deposits__single__implicit__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: unstaked_deposits__single__implicit__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: unstaked_deposits__single__implicit__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: unstaked_deposits__single__implicit__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  unstaked_deposits__single__originated__id_018__proxford__contract_id:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  unstaked_deposits__single__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: unstaked_deposits__single__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: unstaked_deposits__single__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: unstaked_deposits__single__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: unstaked_deposits__single__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
enums:
  origin_tag:
    0: block_application
    1: protocol_migration
    2: subsidy
    3: simulation
  id_018__proxford__bond_id_tag:
    1: smart_rollup_bond_id
  bool:
    0: false
    255: true
  id_018__proxford__staker_tag:
    0: single
    1: shared
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
    3: bls
  id_018__proxford__contract_id_tag:
    0: implicit
    1: originated
  id_018__proxford__operation_metadata__alpha__balance_tag:
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
seq:
- id: id_018__proxford__operation_metadata__alpha__balance_updates_
  type: id_018__proxford__operation_metadata__alpha__balance_updates_
