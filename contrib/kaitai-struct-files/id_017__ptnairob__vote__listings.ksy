meta:
  id: id_017__ptnairob__vote__listings
  endian: be
doc: ! 'Encoding id: 017-PtNairob.vote.listings'
types:
  id_017__ptnairob__vote__listings_entries:
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
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: public_key_hash_secp256k1
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: public_key_hash_p256
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: public_key_hash_bls
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
enums:
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
    3: bls
seq:
- id: size_of_id_017__ptnairob__vote__listings
  type: s4
- id: id_017__ptnairob__vote__listings
  type: id_017__ptnairob__vote__listings_entries
  size: size_of_id_017__ptnairob__vote__listings
  repeat: eos
