meta:
  id: signer_messages__public_key__response
  endian: be
doc: ! 'Encoding id: signer_messages.public_key.response'
types:
  public_key_:
    seq:
    - id: public_key_tag
      type: u1
      enum: public_key_tag
    - id: ed25519__public_key
      size: 32
      if: (public_key_tag == public_key_tag::ed25519)
    - id: secp256k1__public_key
      size: 33
      if: (public_key_tag == public_key_tag::secp256k1)
    - id: p256__public_key
      size: 33
      if: (public_key_tag == public_key_tag::p256)
    - id: bls__public_key
      size: 48
      if: (public_key_tag == public_key_tag::bls)
enums:
  public_key_tag:
    0: ed25519
    1: secp256k1
    2: p256
    3: bls
seq:
- id: pubkey
  type: public_key_
  doc: A Ed25519, Secp256k1, or P256 public key
