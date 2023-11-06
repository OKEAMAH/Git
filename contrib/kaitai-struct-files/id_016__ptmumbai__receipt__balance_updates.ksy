meta:
  id: id_016__ptmumbai__receipt__balance_updates
  endian: be
doc: ! 'Encoding id: 016-PtMumbai.receipt.balance_updates'
types:
  id_016__ptmumbai__operation_metadata__alpha__balance_updates:
    seq:
    - id: len_id_016__ptmumbai__operation_metadata__alpha__balance_updates
      type: u4
      valid:
        max: 1073741823
    - id: id_016__ptmumbai__operation_metadata__alpha__balance_updates
      type: id_016__ptmumbai__operation_metadata__alpha__balance_updates_entries
      size: len_id_016__ptmumbai__operation_metadata__alpha__balance_updates
      repeat: eos
  id_016__ptmumbai__operation_metadata__alpha__balance_updates_entries:
    seq:
    - id: id_016__ptmumbai__operation_metadata__alpha__balance
      type: id_016__ptmumbai__operation_metadata__alpha__balance
    - id: id_016__ptmumbai__operation_metadata__alpha__balance_update
      type: s8
    - id: id_016__ptmumbai__operation_metadata__alpha__update_origin
      type: u1
      enum: origin_tag
  id_016__ptmumbai__operation_metadata__alpha__balance:
    seq:
    - id: id_016__ptmumbai__operation_metadata__alpha__balance_tag
      type: u1
      enum: id_016__ptmumbai__operation_metadata__alpha__balance_tag
    - id: commitments__id_016__ptmumbai__operation_metadata__alpha__balance
      size: 20
      if: (id_016__ptmumbai__operation_metadata__alpha__balance_tag == ::id_016__ptmumbai__operation_metadata__alpha__balance_tag::id_016__ptmumbai__operation_metadata__alpha__balance_tag::commitments)
    - id: frozen_bonds__id_016__ptmumbai__operation_metadata__alpha__balance
      type: frozen_bonds__id_016__ptmumbai__operation_metadata__alpha__balance
      if: (id_016__ptmumbai__operation_metadata__alpha__balance_tag == id_016__ptmumbai__operation_metadata__alpha__balance_tag::frozen_bonds)
  frozen_bonds__id_016__ptmumbai__operation_metadata__alpha__balance:
    seq:
    - id: contract
      type: frozen_bonds__id_016__ptmumbai__contract_id
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: bond_id
      type: frozen_bonds__id_016__ptmumbai__bond_id
  frozen_bonds__id_016__ptmumbai__bond_id:
    seq:
    - id: id_016__ptmumbai__bond_id_tag
      type: u1
      enum: id_016__ptmumbai__bond_id_tag
    - id: frozen_bonds__smart_rollup_bond_id__id_016__ptmumbai__bond_id
      size: 20
      if: (id_016__ptmumbai__bond_id_tag == ::id_016__ptmumbai__bond_id_tag::id_016__ptmumbai__bond_id_tag::smart_rollup_bond_id)
      doc: ! >-
        A smart rollup address: A smart rollup is identified by a base58 address starting
        with sr1
  frozen_bonds__id_016__ptmumbai__contract_id:
    seq:
    - id: id_016__ptmumbai__contract_id_tag
      type: u1
      enum: id_016__ptmumbai__contract_id_tag
    - id: frozen_bonds__implicit__id_016__ptmumbai__contract_id
      type: frozen_bonds__implicit__public_key_hash
      if: (id_016__ptmumbai__contract_id_tag == ::id_016__ptmumbai__contract_id_tag::id_016__ptmumbai__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: frozen_bonds__originated__id_016__ptmumbai__contract_id
      type: frozen_bonds__originated__id_016__ptmumbai__contract_id
      if: (id_016__ptmumbai__contract_id_tag == id_016__ptmumbai__contract_id_tag::originated)
  frozen_bonds__originated__id_016__ptmumbai__contract_id:
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
  lost_endorsing_rewards__id_016__ptmumbai__operation_metadata__alpha__balance:
    seq:
    - id: delegate
      type: lost_endorsing_rewards__public_key_hash
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: participation
      type: u1
      enum: bool
    - id: revelation
      type: u1
      enum: bool
  lost_endorsing_rewards__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: lost_endorsing_rewards__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  deposits__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: deposits__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  contract__id_016__ptmumbai__contract_id:
    seq:
    - id: id_016__ptmumbai__contract_id_tag
      type: u1
      enum: id_016__ptmumbai__contract_id_tag
    - id: contract__implicit__id_016__ptmumbai__contract_id
      type: contract__implicit__public_key_hash
      if: (id_016__ptmumbai__contract_id_tag == ::id_016__ptmumbai__contract_id_tag::id_016__ptmumbai__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: contract__originated__id_016__ptmumbai__contract_id
      type: contract__originated__id_016__ptmumbai__contract_id
      if: (id_016__ptmumbai__contract_id_tag == id_016__ptmumbai__contract_id_tag::originated)
  contract__originated__id_016__ptmumbai__contract_id:
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
  id_016__ptmumbai__bond_id_tag:
    0: tx_rollup_bond_id
    1: smart_rollup_bond_id
  bool:
    0: false
    255: true
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
    3: bls
  id_016__ptmumbai__contract_id_tag:
    0: implicit
    1: originated
  id_016__ptmumbai__operation_metadata__alpha__balance_tag:
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
    24: smart_rollup_refutation_punishments
    25: smart_rollup_refutation_rewards
seq:
- id: id_016__ptmumbai__operation_metadata__alpha__balance_updates
  type: id_016__ptmumbai__operation_metadata__alpha__balance_updates
