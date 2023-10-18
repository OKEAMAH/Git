meta:
  id: sapling__transaction__output
  endian: be
doc: Output of a transaction
types:
  sapling__transaction__ciphertext:
    types:
      payload_enc:
        seq:
        - id: len_payload_enc
          type: s4
        - id: payload_enc
          size: len_payload_enc
    seq:
    - id: cv
      size: 32
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
  payload_enc:
    seq:
    - id: len_payload_enc
      type: s4
    - id: payload_enc
      size: len_payload_enc
seq:
- id: cm
  size: 32
- id: proof_o
  size: 192
- id: ciphertext
  type: sapling__transaction__ciphertext