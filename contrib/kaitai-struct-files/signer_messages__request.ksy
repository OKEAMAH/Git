meta:
  id: signer_messages__request
  endian: be
types:
  data:
    seq:
    - id: len_data
      type: s4
    - id: data
      size: len_data
  public_key_hash:
    doc: A Ed25519, Secp256k1, P256, or BLS public key hash
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
  signer_messages__request_deterministic_nonce:
    seq:
    - id: pkh
      type: public_key_hash
    - id: data
      type: data
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size-eos: true
      if: (signature_tag == bool::true)
  signer_messages__request_deterministic_nonce_hash:
    seq:
    - id: pkh
      type: public_key_hash
    - id: data
      type: data
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size-eos: true
      if: (signature_tag == bool::true)
  signer_messages__request_sign:
    seq:
    - id: pkh
      type: public_key_hash
    - id: data
      type: data
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size-eos: true
      if: (signature_tag == bool::true)
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
- id: signer_messages__request_sign
  type: signer_messages__request_sign
  if: (signer_messages__request_tag == signer_messages__request_tag::sign)
- id: signer_messages__request_public_key
  type: public_key_hash
  if: (signer_messages__request_tag == signer_messages__request_tag::public_key)
- id: signer_messages__request_deterministic_nonce
  type: signer_messages__request_deterministic_nonce
  if: (signer_messages__request_tag == signer_messages__request_tag::deterministic_nonce)
- id: signer_messages__request_deterministic_nonce_hash
  type: signer_messages__request_deterministic_nonce_hash
  if: (signer_messages__request_tag == signer_messages__request_tag::deterministic_nonce_hash)
- id: signer_messages__request_supports_deterministic_nonces
  type: public_key_hash
  if: (signer_messages__request_tag == signer_messages__request_tag::supports_deterministic_nonces)
