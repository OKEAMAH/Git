meta:
  id: id_008__ptedo2zk__vote__listings
  endian: be
types:
  id_008__ptedo2zk__vote__listings_entries:
    seq:
    - id: pkh
      type: public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: rolls
      type: s4
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
seq:
- id: size_of_id_008__ptedo2zk__vote__listings
  type: s4
- id: id_008__ptedo2zk__vote__listings
  type: id_008__ptedo2zk__vote__listings_entries
  size: size_of_id_008__ptedo2zk__vote__listings
  repeat: eos
