meta:
  id: id_007__psdelph1__contract
  endian: be
types:
  id_007__psdelph1__contract_id:
    seq:
    - id: id_007__psdelph1__contract_id_tag
      type: u1
      enum: id_007__psdelph1__contract_id_tag
    - id: id_007__psdelph1__contract_id_implicit
      type: public_key_hash
      if: (id_007__psdelph1__contract_id_tag == id_007__psdelph1__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: id_007__psdelph1__contract_id_originated
      type: id_007__psdelph1__contract_id_originated
      if: (id_007__psdelph1__contract_id_tag == id_007__psdelph1__contract_id_tag::originated)
  id_007__psdelph1__contract_id_originated:
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
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
  id_007__psdelph1__contract_id_tag:
    0: implicit
    1: originated
seq:
- id: id_007__psdelph1__contract_id
  type: id_007__psdelph1__contract_id
  doc: ! >-
    A contract handle: A contract notation as given to an RPC or inside scripts. Can
    be a base58 implicit contract hash or a base58 originated contract hash.
