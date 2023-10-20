meta:
  id: signer_messages__deterministic_nonce__response
  endian: be
doc: ! 'Encoding id: signer_messages.deterministic_nonce.response'
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
