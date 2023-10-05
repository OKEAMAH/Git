meta:
  id: sapling__transaction__output
  endian: be
doc: Output of a transaction
types:
  sapling__transaction__ciphertext:
    meta:
      id: sapling__transaction__ciphertext
      endian: be
    types:
      payload_enc:
        meta:
          id: payload_enc
          endian: be
        seq:
        - id: len_payload_enc
          type: s4
        - id: payload_enc
          size: len_payload_enc
    seq:
    - id: sapling__transaction__commitment_value
      size: 32
    - id: sapling__dh__epk
      size: 32
    - id: payload_enc
      type: payload_enc
    - id: nonce_enc
      size: 24
    - id: payload_out
      size: 80
    - id: nonce_out
      size: 24
seq:
- id: sapling__transaction__commitment
  size: 32
- id: proof_o
  size: 192
- id: sapling__transaction__ciphertext
  type: sapling__transaction__ciphertext
