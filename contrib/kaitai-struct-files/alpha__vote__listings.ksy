meta:
  id: alpha__vote__listings
  endian: be
types:
  alpha__vote__listings_entries:
    seq:
    - id: pkh
      type: public_key_hash
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: voting_power
      type: s8
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
    - id: public_key_hash_bls
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::Bls)
enums:
  public_key_hash_tag:
    0: Ed25519
    1: Secp256k1
    2: P256
    3: Bls
seq:
- id: size_of_alpha__vote__listings
  type: s4
- id: alpha__vote__listings
  type: alpha__vote__listings_entries
  size: size_of_alpha__vote__listings
  repeat: eos
