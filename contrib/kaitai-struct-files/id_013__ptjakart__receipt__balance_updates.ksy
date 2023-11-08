meta:
  id: id_013__ptjakart__receipt__balance_updates
  endian: be
doc: ! 'Encoding id: 013-PtJakart.receipt.balance_updates'
types:
  id_013__ptjakart__operation_metadata__alpha__balance_updates_:
    seq:
    - id: len_id_013__ptjakart__operation_metadata__alpha__balance_updates_dyn
      type: uint30
    - id: id_013__ptjakart__operation_metadata__alpha__balance_updates_dyn
      type: id_013__ptjakart__operation_metadata__alpha__balance_updates_dyn
      size: len_id_013__ptjakart__operation_metadata__alpha__balance_updates_dyn
  id_013__ptjakart__operation_metadata__alpha__balance_updates_dyn:
    seq:
    - id: id_013__ptjakart__operation_metadata__alpha__balance_updates_entries
      type: id_013__ptjakart__operation_metadata__alpha__balance_updates_entries
      repeat: eos
  id_013__ptjakart__operation_metadata__alpha__balance_updates_entries:
    seq:
    - id: id_013__ptjakart__operation_metadata__alpha__balance_
      type: id_013__ptjakart__operation_metadata__alpha__balance_
    - id: id_013__ptjakart__operation_metadata__alpha__balance_update
      type: s8
    - id: id_013__ptjakart__operation_metadata__alpha__update_origin
      type: u1
      enum: origin_tag
  id_013__ptjakart__operation_metadata__alpha__balance_:
    seq:
    - id: id_013__ptjakart__operation_metadata__alpha__balance_tag
      type: u1
      enum: id_013__ptjakart__operation_metadata__alpha__balance_tag
    - id: contract__id_013__ptjakart__operation_metadata__alpha__balance
      type: contract__id_013__ptjakart__contract_id_
      if: (id_013__ptjakart__operation_metadata__alpha__balance_tag == id_013__ptjakart__operation_metadata__alpha__balance_tag::contract)
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: deposits__id_013__ptjakart__operation_metadata__alpha__balance
      type: deposits__public_key_hash_
      if: (id_013__ptjakart__operation_metadata__alpha__balance_tag == id_013__ptjakart__operation_metadata__alpha__balance_tag::deposits)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: lost_endorsing_rewards__id_013__ptjakart__operation_metadata__alpha__balance
      type: lost_endorsing_rewards__id_013__ptjakart__operation_metadata__alpha__balance
      if: (id_013__ptjakart__operation_metadata__alpha__balance_tag == id_013__ptjakart__operation_metadata__alpha__balance_tag::lost_endorsing_rewards)
    - id: commitments__id_013__ptjakart__operation_metadata__alpha__balance
      size: 20
      if: (id_013__ptjakart__operation_metadata__alpha__balance_tag == id_013__ptjakart__operation_metadata__alpha__balance_tag::commitments)
    - id: frozen_bonds__id_013__ptjakart__operation_metadata__alpha__balance
      type: frozen_bonds__id_013__ptjakart__operation_metadata__alpha__balance
      if: (id_013__ptjakart__operation_metadata__alpha__balance_tag == id_013__ptjakart__operation_metadata__alpha__balance_tag::frozen_bonds)
  frozen_bonds__id_013__ptjakart__operation_metadata__alpha__balance:
    seq:
    - id: contract
      type: frozen_bonds__id_013__ptjakart__contract_id_
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: bond_id
      type: frozen_bonds__id_013__ptjakart__bond_id_
  frozen_bonds__id_013__ptjakart__bond_id_:
    seq:
    - id: id_013__ptjakart__bond_id_tag
      type: u1
      enum: id_013__ptjakart__bond_id_tag
    - id: frozen_bonds__tx_rollup_bond_id__id_013__ptjakart__bond_id
      size: 20
      if: (id_013__ptjakart__bond_id_tag == id_013__ptjakart__bond_id_tag::tx_rollup_bond_id)
      doc: ! >-
        A tx rollup handle: A tx rollup notation as given to an RPC or inside scripts,
        is a base58 tx rollup hash
  frozen_bonds__id_013__ptjakart__contract_id_:
    seq:
    - id: id_013__ptjakart__contract_id_tag
      type: u1
      enum: id_013__ptjakart__contract_id_tag
    - id: frozen_bonds__implicit__id_013__ptjakart__contract_id
      type: frozen_bonds__implicit__public_key_hash_
      if: (id_013__ptjakart__contract_id_tag == id_013__ptjakart__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: frozen_bonds__originated__id_013__ptjakart__contract_id
      type: frozen_bonds__originated__id_013__ptjakart__contract_id
      if: (id_013__ptjakart__contract_id_tag == id_013__ptjakart__contract_id_tag::originated)
  frozen_bonds__originated__id_013__ptjakart__contract_id:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
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
  lost_endorsing_rewards__id_013__ptjakart__operation_metadata__alpha__balance:
    seq:
    - id: delegate
      type: lost_endorsing_rewards__public_key_hash_
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: participation
      type: u1
      enum: bool
    - id: revelation
      type: u1
      enum: bool
  lost_endorsing_rewards__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: lost_endorsing_rewards__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: lost_endorsing_rewards__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: lost_endorsing_rewards__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  deposits__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: deposits__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: deposits__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: deposits__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  contract__id_013__ptjakart__contract_id_:
    seq:
    - id: id_013__ptjakart__contract_id_tag
      type: u1
      enum: id_013__ptjakart__contract_id_tag
    - id: contract__implicit__id_013__ptjakart__contract_id
      type: contract__implicit__public_key_hash_
      if: (id_013__ptjakart__contract_id_tag == id_013__ptjakart__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: contract__originated__id_013__ptjakart__contract_id
      type: contract__originated__id_013__ptjakart__contract_id
      if: (id_013__ptjakart__contract_id_tag == id_013__ptjakart__contract_id_tag::originated)
  contract__originated__id_013__ptjakart__contract_id:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
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
  uint30:
    seq:
    - id: uint30
      type: u4
      valid:
        max: 1073741823
enums:
  origin_tag:
    0: block_application
    1: protocol_migration
    2: subsidy
    3: simulation
  id_013__ptjakart__bond_id_tag:
    0: tx_rollup_bond_id
  bool:
    0: false
    255: true
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
  id_013__ptjakart__contract_id_tag:
    0: implicit
    1: originated
  id_013__ptjakart__operation_metadata__alpha__balance_tag:
    0: contract
    2: block_fees
    4: deposits
    5: nonce_revelation_rewards
    6: double_signing_evidence_rewards
    7: endorsing_rewards
    8: baking_rewards
    9: baking_bonuses
    11: storage_fees
    12: double_signing_punishments
    13: lost_endorsing_rewards
    14: liquidity_baking_subsidies
    15: burned
    16: commitments
    17: bootstrap
    18: invoice
    19: initial_commitments
    20: minted
    21: frozen_bonds
    22: tx_rollup_rejection_rewards
    23: tx_rollup_rejection_punishments
seq:
- id: id_013__ptjakart__operation_metadata__alpha__balance_updates_
  type: id_013__ptjakart__operation_metadata__alpha__balance_updates_
