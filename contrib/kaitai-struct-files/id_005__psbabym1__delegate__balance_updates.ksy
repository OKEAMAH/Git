meta:
  id: id_005__psbabym1__delegate__balance_updates
  endian: be
doc: ! 'Encoding id: 005-PsBabyM1.delegate.balance_updates'
types:
  id_005__psbabym1__contract_id:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  id_005__psbabym1__contract_id_:
    seq:
    - id: id_005__psbabym1__contract_id_tag
      type: u1
      enum: id_005__psbabym1__contract_id_tag
    - id: id_005__psbabym1__contract_id
      type: public_key_hash_
      if: (id_005__psbabym1__contract_id_tag == id_005__psbabym1__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: id_005__psbabym1__contract_id
      type: id_005__psbabym1__contract_id
      if: (id_005__psbabym1__contract_id_tag == id_005__psbabym1__contract_id_tag::originated)
  id_005__psbabym1__operation_metadata__alpha__balance:
    seq:
    - id: delegate
      type: public_key_hash_
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: cycle
      type: s4
  id_005__psbabym1__operation_metadata__alpha__balance_:
    seq:
    - id: id_005__psbabym1__operation_metadata__alpha__balance_tag
      type: u1
      enum: id_005__psbabym1__operation_metadata__alpha__balance_tag
    - id: id_005__psbabym1__operation_metadata__alpha__balance
      type: id_005__psbabym1__contract_id_
      if: (id_005__psbabym1__operation_metadata__alpha__balance_tag == id_005__psbabym1__operation_metadata__alpha__balance_tag::contract)
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: id_005__psbabym1__operation_metadata__alpha__balance
      type: id_005__psbabym1__operation_metadata__alpha__balance
      if: (id_005__psbabym1__operation_metadata__alpha__balance_tag == id_005__psbabym1__operation_metadata__alpha__balance_tag::rewards)
    - id: id_005__psbabym1__operation_metadata__alpha__balance
      type: id_005__psbabym1__operation_metadata__alpha__balance
      if: (id_005__psbabym1__operation_metadata__alpha__balance_tag == id_005__psbabym1__operation_metadata__alpha__balance_tag::fees)
    - id: id_005__psbabym1__operation_metadata__alpha__balance
      type: id_005__psbabym1__operation_metadata__alpha__balance
      if: (id_005__psbabym1__operation_metadata__alpha__balance_tag == id_005__psbabym1__operation_metadata__alpha__balance_tag::deposits)
  id_005__psbabym1__operation_metadata__alpha__balance_updates_:
    seq:
    - id: len_id_005__psbabym1__operation_metadata__alpha__balance_updates_dyn
      type: u4
      valid:
        max: 1073741823
    - id: id_005__psbabym1__operation_metadata__alpha__balance_updates_dyn
      type: id_005__psbabym1__operation_metadata__alpha__balance_updates_dyn
      size: len_id_005__psbabym1__operation_metadata__alpha__balance_updates_dyn
  id_005__psbabym1__operation_metadata__alpha__balance_updates_dyn:
    seq:
    - id: id_005__psbabym1__operation_metadata__alpha__balance_updates_entries
      type: id_005__psbabym1__operation_metadata__alpha__balance_updates_entries
      repeat: eos
  id_005__psbabym1__operation_metadata__alpha__balance_updates_entries:
    seq:
    - id: id_005__psbabym1__operation_metadata__alpha__balance_
      type: id_005__psbabym1__operation_metadata__alpha__balance_
    - id: id_005__psbabym1__operation_metadata__alpha__balance_update
      type: s8
  public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
enums:
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
  id_005__psbabym1__contract_id_tag:
    0: implicit
    1: originated
  id_005__psbabym1__operation_metadata__alpha__balance_tag:
    0: contract
    1: rewards
    2: fees
    3: deposits
seq:
- id: id_005__psbabym1__operation_metadata__alpha__balance_updates_
  type: id_005__psbabym1__operation_metadata__alpha__balance_updates_
