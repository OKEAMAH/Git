meta:
  id: signer_messages__request
  endian: be
doc: ! 'Encoding id: signer_messages.request'
types:
  bytes_dyn_uint30:
    seq:
    - id: len_bytes_dyn_uint30
      type: u4
      valid:
        max: 1073741823
    - id: bytes_dyn_uint30
      size: len_bytes_dyn_uint30
  public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  signer_messages__request:
    seq:
    - id: pkh
      type: public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: data
      type: bytes_dyn_uint30
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size-eos: true
      if: (signature_tag == bool::true)
  uint30:
    seq:
    - id: uint30
      type: u4
      valid:
        max: 1073741823
enums:
  bool:
    0: false
    255: true
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
    3: bls
  signer_messages__request_tag:
    0: sign
    1: public_key
    2: authorized_keys
    3: deterministic_nonce
    4: deterministic_nonce_hash
    5: supports_deterministic_nonces
seq:
- id: signer_messages__request_tag
  type: u1
  enum: signer_messages__request_tag
- id: signer_messages__request
  type: signer_messages__request
  if: (signer_messages__request_tag == signer_messages__request_tag::sign)
- id: signer_messages__request
  type: public_key_hash_
  if: (signer_messages__request_tag == signer_messages__request_tag::public_key)
  doc: A Ed25519, Secp256k1, P256, or BLS public key hash
- id: signer_messages__request
  type: signer_messages__request
  if: (signer_messages__request_tag == signer_messages__request_tag::deterministic_nonce)
- id: signer_messages__request
  type: signer_messages__request
  if: (signer_messages__request_tag == signer_messages__request_tag::deterministic_nonce_hash)
- id: signer_messages__request
  type: public_key_hash_
  if: (signer_messages__request_tag == signer_messages__request_tag::supports_deterministic_nonces)
  doc: A Ed25519, Secp256k1, P256, or BLS public key hash
