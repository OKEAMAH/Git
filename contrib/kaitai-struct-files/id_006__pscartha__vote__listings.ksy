meta:
  id: id_006__pscartha__vote__listings
  endian: be
doc: ! 'Encoding id: 006-PsCARTHA.vote.listings'
types:
  id_006__pscartha__vote__listings_dyn:
    seq:
    - id: id_006__pscartha__vote__listings_entries
      type: id_006__pscartha__vote__listings_entries
      repeat: eos
  id_006__pscartha__vote__listings_entries:
    seq:
    - id: pkh
      type: public_key_hash_
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: rolls
      type: s4
  public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  uint30:
    seq:
    - id: uint30
      type: u4
      valid:
        max: 1073741823
enums:
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
seq:
- id: len_id_006__pscartha__vote__listings_dyn
  type: uint30
- id: id_006__pscartha__vote__listings_dyn
  type: id_006__pscartha__vote__listings_dyn
  size: len_id_006__pscartha__vote__listings_dyn
