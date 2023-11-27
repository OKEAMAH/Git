meta:
  id: id_012__psithaca__receipt__balance_updates
  endian: be
types:
  id_012__psithaca__operation_metadata__alpha__balance_updates:
    seq:
    - id: len_id_012__psithaca__operation_metadata__alpha__balance_updates
      type: s4
    - id: id_012__psithaca__operation_metadata__alpha__balance_updates
      type: id_012__psithaca__operation_metadata__alpha__balance_updates_entries
      size: len_id_012__psithaca__operation_metadata__alpha__balance_updates
      repeat: eos
  id_012__psithaca__operation_metadata__alpha__balance_updates_entries:
    seq:
    - id: id_012__psithaca__operation_metadata__alpha__balance
      type: id_012__psithaca__operation_metadata__alpha__balance
    - id: change
      type: s8
    - id: origin
      type: u1
      enum: origin_tag
  id_012__psithaca__operation_metadata__alpha__balance:
    seq:
    - id: id_012__psithaca__operation_metadata__alpha__balance_tag
      type: u1
      enum: id_012__psithaca__operation_metadata__alpha__balance_tag
    - id: id_012__psithaca__operation_metadata__alpha__balance_contract
      type: id_012__psithaca__contract_id
      if: (id_012__psithaca__operation_metadata__alpha__balance_tag == id_012__psithaca__operation_metadata__alpha__balance_tag::contract)
    - id: id_012__psithaca__operation_metadata__alpha__balance_legacy_rewards
      type: id_012__psithaca__operation_metadata__alpha__balance_legacy_rewards
      if: (id_012__psithaca__operation_metadata__alpha__balance_tag == id_012__psithaca__operation_metadata__alpha__balance_tag::legacy_rewards)
    - id: id_012__psithaca__operation_metadata__alpha__balance_legacy_deposits
      type: id_012__psithaca__operation_metadata__alpha__balance_legacy_deposits
      if: (id_012__psithaca__operation_metadata__alpha__balance_tag == id_012__psithaca__operation_metadata__alpha__balance_tag::legacy_deposits)
    - id: id_012__psithaca__operation_metadata__alpha__balance_deposits
      type: public_key_hash
      if: (id_012__psithaca__operation_metadata__alpha__balance_tag == id_012__psithaca__operation_metadata__alpha__balance_tag::deposits)
    - id: id_012__psithaca__operation_metadata__alpha__balance_legacy_fees
      type: id_012__psithaca__operation_metadata__alpha__balance_legacy_fees
      if: (id_012__psithaca__operation_metadata__alpha__balance_tag == id_012__psithaca__operation_metadata__alpha__balance_tag::legacy_fees)
    - id: id_012__psithaca__operation_metadata__alpha__balance_lost_endorsing_rewards
      type: id_012__psithaca__operation_metadata__alpha__balance_lost_endorsing_rewards
      if: (id_012__psithaca__operation_metadata__alpha__balance_tag == id_012__psithaca__operation_metadata__alpha__balance_tag::lost_endorsing_rewards)
    - id: id_012__psithaca__operation_metadata__alpha__balance_commitments
      size: 20
      if: (id_012__psithaca__operation_metadata__alpha__balance_tag == id_012__psithaca__operation_metadata__alpha__balance_tag::commitments)
  id_012__psithaca__operation_metadata__alpha__balance_lost_endorsing_rewards:
    seq:
    - id: delegate
      type: public_key_hash
    - id: participation
      type: u1
      enum: bool
    - id: revelation
      type: u1
      enum: bool
  id_012__psithaca__operation_metadata__alpha__balance_legacy_fees:
    seq:
    - id: delegate
      type: public_key_hash
    - id: cycle
      type: s4
  id_012__psithaca__operation_metadata__alpha__balance_legacy_deposits:
    seq:
    - id: delegate
      type: public_key_hash
    - id: cycle
      type: s4
  id_012__psithaca__operation_metadata__alpha__balance_legacy_rewards:
    seq:
    - id: delegate
      type: public_key_hash
    - id: cycle
      type: s4
  id_012__psithaca__contract_id:
    doc: ! >-
      A contract handle: A contract notation as given to an RPC or inside scripts.
      Can be a base58 implicit contract hash or a base58 originated contract hash.
    seq:
    - id: id_012__psithaca__contract_id_tag
      type: u1
      enum: id_012__psithaca__contract_id_tag
    - id: id_012__psithaca__contract_id_implicit
      type: public_key_hash
      if: (id_012__psithaca__contract_id_tag == id_012__psithaca__contract_id_tag::implicit)
    - id: id_012__psithaca__contract_id_originated
      type: id_012__psithaca__contract_id_originated
      if: (id_012__psithaca__contract_id_tag == id_012__psithaca__contract_id_tag::originated)
  id_012__psithaca__contract_id_originated:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  public_key_hash:
    doc: A Ed25519, Secp256k1, or P256 public key hash
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: public_key_hash_ed25519
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: public_key_hash_secp256k1
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: public_key_hash_p256
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
enums:
  origin_tag:
    0: block_application
    1: protocol_migration
    2: subsidy
    3: simulation
  bool:
    0: false
    255: true
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
  id_012__psithaca__contract_id_tag:
    0: implicit
    1: originated
  id_012__psithaca__operation_metadata__alpha__balance_tag:
    0: contract
    1: legacy_rewards
    2: block_fees
    3: legacy_deposits
    4: deposits
    5: nonce_revelation_rewards
    6: double_signing_evidence_rewards
    7: endorsing_rewards
    8: baking_rewards
    9: baking_bonuses
    10: legacy_fees
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
seq:
- id: id_012__psithaca__operation_metadata__alpha__balance_updates
  type: id_012__psithaca__operation_metadata__alpha__balance_updates
