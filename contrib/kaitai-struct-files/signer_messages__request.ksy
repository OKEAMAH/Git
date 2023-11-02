meta:
  id: signer_messages__request
  endian: be
doc: ! 'Encoding id: signer_messages.request'
types:
  supports_deterministic_nonces__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: supports_deterministic_nonces__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  deterministic_nonce_hash__signer_messages__request:
    seq:
    - id: pkh
      type: deterministic_nonce_hash__public_key_hash
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: deterministic_nonce_hash__data
      type: deterministic_nonce_hash__data
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size-eos: true
      if: (signature_tag == bool::true)
  deterministic_nonce_hash__data:
    seq:
    - id: size_of_data
      type: u4
      valid:
        max: 1073741823
    - id: data
      size: size_of_data
  deterministic_nonce_hash__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: deterministic_nonce_hash__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  deterministic_nonce__signer_messages__request:
    seq:
    - id: pkh
      type: deterministic_nonce__public_key_hash
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: deterministic_nonce__data
      type: deterministic_nonce__data
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size-eos: true
      if: (signature_tag == bool::true)
  deterministic_nonce__data:
    seq:
    - id: size_of_data
      type: u4
      valid:
        max: 1073741823
    - id: data
      size: size_of_data
  deterministic_nonce__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: deterministic_nonce__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  public_key__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: public_key__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  sign__signer_messages__request:
    seq:
    - id: pkh
      type: sign__public_key_hash
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: sign__data
      type: sign__data
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size-eos: true
      if: (signature_tag == bool::true)
  sign__data:
    seq:
    - id: size_of_data
      type: u4
      valid:
        max: 1073741823
    - id: data
      size: size_of_data
  sign__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: sign__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
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
- id: supports_deterministic_nonces__signer_messages__request
  type: supports_deterministic_nonces__public_key_hash
  if: (signer_messages__request_tag == ::signer_messages__request_tag::signer_messages__request_tag::supports_deterministic_nonces)
  doc: A Ed25519, Secp256k1, P256, or BLS public key hash
