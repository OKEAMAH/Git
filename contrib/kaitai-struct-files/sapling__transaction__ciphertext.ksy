meta:
  id: sapling__transaction__ciphertext
  endian: be
  imports:
  - sapling__transaction__commitment_value
doc: ! 'Encoding id: sapling.transaction.ciphertext'
types:
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
seq:
- id: cv
  type: sapling__transaction__commitment_value
- id: epk
  size: 32
- id: payload_enc
  type: bytes_dyn_uint30
- id: nonce_enc
  size: 24
- id: payload_out
  size: 80
- id: nonce_out
  size: 24
