meta:
  id: sapling__transaction__output
  endian: be
doc: ! 'Encoding id: sapling.transaction.output

  Description: Output of a transaction'
types:
  sapling__transaction__ciphertext_:
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
      type: u4
      valid:
        max: 1073741823
    - id: payload_enc
      size: len_payload_enc
seq:
- id: cm
  size: 32
- id: proof_o
  size: 192
- id: ciphertext
  type: sapling__transaction__ciphertext_
