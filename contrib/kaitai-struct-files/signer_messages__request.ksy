meta:
  id: signer_messages__request
  endian: be
doc: ! 'Encoding id: signer_messages.request'
types:
  supports_deterministic_nonces__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: supports_deterministic_nonces__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: supports_deterministic_nonces__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: supports_deterministic_nonces__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: supports_deterministic_nonces__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  deterministic_nonce_hash__signer_messages__request:
    seq:
    - id: pkh
      type: deterministic_nonce_hash__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: data
      type: bytes_dyn_uint30
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size-eos: true
      if: (signature_tag == bool::true)
  deterministic_nonce_hash__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: deterministic_nonce_hash__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: deterministic_nonce_hash__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: deterministic_nonce_hash__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: deterministic_nonce_hash__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  deterministic_nonce__signer_messages__request:
    seq:
    - id: pkh
      type: deterministic_nonce__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: data
      type: bytes_dyn_uint30
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size-eos: true
      if: (signature_tag == bool::true)
  deterministic_nonce__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: deterministic_nonce__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: deterministic_nonce__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: deterministic_nonce__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: deterministic_nonce__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  public_key__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: public_key__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: public_key__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: public_key__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: public_key__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  sign__signer_messages__request:
    seq:
    - id: pkh
      type: sign__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: data
      type: bytes_dyn_uint30
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size-eos: true
      if: (signature_tag == bool::true)
  bytes_dyn_uint30:
    seq:
    - id: len_bytes_dyn_uint30
      type: uint30
    - id: bytes_dyn_uint30
      size: len_bytes_dyn_uint30
  uint30:
    seq:
    - id: uint30
      type: u4
      valid:
        max: 1073741823
  sign__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: sign__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: sign__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: sign__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: sign__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
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
- id: sign__signer_messages__request
  type: sign__signer_messages__request
  if: (signer_messages__request_tag == signer_messages__request_tag::sign)
- id: public_key__signer_messages__request
  type: public_key__public_key_hash_
  if: (signer_messages__request_tag == signer_messages__request_tag::public_key)
  doc: A Ed25519, Secp256k1, P256, or BLS public key hash
- id: deterministic_nonce__signer_messages__request
  type: deterministic_nonce__signer_messages__request
  if: (signer_messages__request_tag == signer_messages__request_tag::deterministic_nonce)
- id: deterministic_nonce_hash__signer_messages__request
  type: deterministic_nonce_hash__signer_messages__request
  if: (signer_messages__request_tag == signer_messages__request_tag::deterministic_nonce_hash)
- id: supports_deterministic_nonces__signer_messages__request
  type: supports_deterministic_nonces__public_key_hash_
  if: (signer_messages__request_tag == signer_messages__request_tag::supports_deterministic_nonces)
  doc: A Ed25519, Secp256k1, P256, or BLS public key hash
