meta:
  id: alpha__staker
  endian: be
doc: ! 'Encoding id: alpha.staker'
types:
  alpha__contract_id:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  alpha__contract_id_:
    seq:
    - id: alpha__contract_id_tag
      type: u1
      enum: alpha__contract_id_tag
    - id: alpha__contract_id
      type: public_key_hash_
      if: (alpha__contract_id_tag == alpha__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: alpha__contract_id
      type: alpha__contract_id
      if: (alpha__contract_id_tag == alpha__contract_id_tag::originated)
  alpha__staker:
    seq:
    - id: contract
      type: alpha__contract_id_
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: delegate
      type: public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
  alpha__staker_:
    seq:
    - id: alpha__staker_tag
      type: u1
      enum: alpha__staker_tag
    - id: alpha__staker
      type: alpha__staker
      if: (alpha__staker_tag == alpha__staker_tag::single)
    - id: alpha__staker
      type: public_key_hash_
      if: (alpha__staker_tag == alpha__staker_tag::shared)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
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
    - id: public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
enums:
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
    3: bls
  alpha__contract_id_tag:
    0: implicit
    1: originated
  alpha__staker_tag:
    0: single
    1: shared
seq:
- id: alpha__staker_
  type: alpha__staker_
  doc: ! >-
    staker: Abstract notion of staker used in operation receipts, either a single
    staker or all the stakers delegating to some delegate.
