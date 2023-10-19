meta:
  id: alpha__staker
  endian: be
types:
  alpha__staker:
    seq:
    - id: alpha__staker_tag
      type: u1
      enum: alpha__staker_tag
    - id: alpha__staker_Single
      type: alpha__staker_Single
      if: (alpha__staker_tag == alpha__staker_tag::Single)
    - id: alpha__staker_Shared
      type: public_key_hash
      if: (alpha__staker_tag == alpha__staker_tag::Shared)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
  alpha__staker_Single:
    seq:
    - id: contract
      type: alpha__contract_id
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: delegate
      type: public_key_hash
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
  alpha__contract_id:
    seq:
    - id: alpha__contract_id_tag
      type: u1
      enum: alpha__contract_id_tag
    - id: alpha__contract_id_Implicit
      type: public_key_hash
      if: (alpha__contract_id_tag == alpha__contract_id_tag::Implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: alpha__contract_id_Originated
      type: alpha__contract_id_Originated
      if: (alpha__contract_id_tag == alpha__contract_id_tag::Originated)
  alpha__contract_id_Originated:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: public_key_hash_Ed25519
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::Ed25519)
    - id: public_key_hash_Secp256k1
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::Secp256k1)
    - id: public_key_hash_P256
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::P256)
    - id: public_key_hash_Bls
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::Bls)
enums:
  public_key_hash_tag:
    0: Ed25519
    1: Secp256k1
    2: P256
    3: Bls
  alpha__contract_id_tag:
    0: Implicit
    1: Originated
  alpha__staker_tag:
    0: Single
    1: Shared
seq:
- id: alpha__staker
  type: alpha__staker
  doc: ! >-
    staker: Abstract notion of staker used in operation receipts, either a single
    staker or all the stakers delegating to some delegate.
