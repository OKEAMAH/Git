meta:
  id: signer_messages__public_key__response
  endian: be
doc: ! 'Encoding id: signer_messages.public_key.response'
types:
  public_key:
    seq:
    - id: public_key_tag
      type: u1
      enum: public_key_tag
    - id: bls__public_key
      size: 48
      if: (public_key_tag == ::public_key_tag::public_key_tag::bls)
enums:
  public_key_tag:
    0: ed25519
    1: secp256k1
    2: p256
    3: bls
seq:
- id: pubkey
  type: public_key
  doc: A Ed25519, Secp256k1, or P256 public key
