meta:
  id: signer_messages__deterministic_nonce__response
  endian: be
doc: ! 'Encoding id: signer_messages.deterministic_nonce.response'
types:
  deterministic_nonce:
    seq:
    - id: len_deterministic_nonce
      type: uint30
    - id: deterministic_nonce
      size: len_deterministic_nonce
  uint30:
    seq:
    - id: uint30
      type: u4
      valid:
        max: 1073741823
seq:
- id: deterministic_nonce
  type: deterministic_nonce
