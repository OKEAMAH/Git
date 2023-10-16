meta:
  id: signer_messages__deterministic_nonce__response
  endian: be
types:
  deterministic_nonce:
    seq:
    - id: size_of_deterministic_nonce
      type: s4
    - id: deterministic_nonce
      size: size_of_deterministic_nonce
seq:
- id: deterministic_nonce
  type: deterministic_nonce
