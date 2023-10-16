meta:
  id: signer_messages__deterministic_nonce_hash__response
  endian: be
types:
  deterministic_nonce_hash:
    seq:
    - id: size_of_deterministic_nonce_hash
      type: s4
    - id: deterministic_nonce_hash
      size: size_of_deterministic_nonce_hash
seq:
- id: deterministic_nonce_hash
  type: deterministic_nonce_hash
