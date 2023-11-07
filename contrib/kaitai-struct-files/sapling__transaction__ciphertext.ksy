meta:
  id: sapling__transaction__ciphertext
  endian: be
  imports:
  - sapling__transaction__commitment_value
doc: ! 'Encoding id: sapling.transaction.ciphertext'
types:
  payload_enc:
    seq:
    - id: len_payload_enc
      type: uint30
    - id: payload_enc
      size: len_payload_enc
  uint30:
    seq:
    - id: uint30
      type: u4
      valid:
        max: 1073741823
seq:
- id: cv
  type: sapling__transaction__commitment_value
- id: epk
  size: 32
- id: payload_enc
  type: payload_enc
- id: nonce_enc
  size: 24
- id: payload_out
  size: 80
- id: nonce_out
  size: 24
