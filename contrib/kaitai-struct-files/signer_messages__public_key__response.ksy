meta:
  id: signer_messages__public_key__response
  endian: be
types:
  public_key:
    seq:
    - id: public_key_tag
      type: u1
      enum: public_key_tag
    - id: public_key_ed25519
      size: 32
      if: (public_key_tag == public_key_tag::Ed25519)
    - id: public_key_secp256k1
      size: 33
      if: (public_key_tag == public_key_tag::Secp256k1)
    - id: public_key_p256
      size: 33
      if: (public_key_tag == public_key_tag::P256)
    - id: public_key_bls
      size: 48
      if: (public_key_tag == public_key_tag::Bls)
enums:
  public_key_tag:
    0: Ed25519
    1: Secp256k1
    2: P256
    3: Bls
seq:
- id: pubkey
  type: public_key
  doc: A Ed25519, Secp256k1, or P256 public key
