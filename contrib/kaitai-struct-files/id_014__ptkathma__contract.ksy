meta:
  id: id_014__ptkathma__contract
  endian: be
types:
  id_014__ptkathma__contract_id:
    seq:
    - id: id_014__ptkathma__contract_id_tag
      type: u1
      enum: id_014__ptkathma__contract_id_tag
    - id: id_014__ptkathma__contract_id_implicit
      type: public_key_hash
      if: (id_014__ptkathma__contract_id_tag == id_014__ptkathma__contract_id_tag::Implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: id_014__ptkathma__contract_id_originated
      type: id_014__ptkathma__contract_id_originated
      if: (id_014__ptkathma__contract_id_tag == id_014__ptkathma__contract_id_tag::Originated)
  id_014__ptkathma__contract_id_originated:
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
      if: (public_key_hash_tag == public_key_hash_tag::Ed25519)
    - id: public_key_hash_secp256k1
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::Secp256k1)
    - id: public_key_hash_p256
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::P256)
enums:
  public_key_hash_tag:
    0: Ed25519
    1: Secp256k1
    2: P256
  id_014__ptkathma__contract_id_tag:
    0: Implicit
    1: Originated
seq:
- id: id_014__ptkathma__contract_id
  type: id_014__ptkathma__contract_id
  doc: ! >-
    A contract handle: A contract notation as given to an RPC or inside scripts. Can
    be a base58 implicit contract hash or a base58 originated contract hash.
