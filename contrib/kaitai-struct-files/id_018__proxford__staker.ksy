meta:
  id: id_018__proxford__staker
  endian: be
doc: ! 'Encoding id: 018-Proxford.staker'
types:
  id_018__proxford__staker_:
    seq:
    - id: id_018__proxford__staker_tag
      type: u1
      enum: id_018__proxford__staker_tag
    - id: single__id_018__proxford__staker
      type: single__id_018__proxford__staker
      if: (id_018__proxford__staker_tag == id_018__proxford__staker_tag::single)
    - id: shared__id_018__proxford__staker
      type: shared__public_key_hash_
      if: (id_018__proxford__staker_tag == id_018__proxford__staker_tag::shared)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
  shared__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: shared__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: shared__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: shared__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: shared__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  single__id_018__proxford__contract_id_:
    seq:
    - id: id_018__proxford__contract_id_tag
      type: u1
      enum: id_018__proxford__contract_id_tag
    - id: single__implicit__id_018__proxford__contract_id
      type: single__implicit__public_key_hash_
      if: (id_018__proxford__contract_id_tag == id_018__proxford__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: single__originated__id_018__proxford__contract_id
      type: single__originated__id_018__proxford__contract_id
      if: (id_018__proxford__contract_id_tag == id_018__proxford__contract_id_tag::originated)
  single__id_018__proxford__staker:
    seq:
    - id: contract
      type: single__id_018__proxford__contract_id_
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: delegate
      type: single__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
  single__implicit__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: single__implicit__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: single__implicit__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: single__implicit__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: single__implicit__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  single__originated__id_018__proxford__contract_id:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  single__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: single__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: single__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: single__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: single__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
enums:
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
    3: bls
  id_018__proxford__contract_id_tag:
    0: implicit
    1: originated
  id_018__proxford__staker_tag:
    0: single
    1: shared
seq:
- id: id_018__proxford__staker_
  type: id_018__proxford__staker_
  doc: ! >-
    staker: Abstract notion of staker used in operation receipts, either a single
    staker or all the stakers delegating to some delegate.
