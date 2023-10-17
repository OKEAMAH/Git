meta:
  id: sapling__transaction
  endian: be
doc: ! >-
  A Sapling transaction with inputs, outputs, balance, root, bound_data and binding
  sig.
types:
  bound_data:
    seq:
    - id: size_of_bound_data
      type: s4
    - id: bound_data
      size: size_of_bound_data
  outputs:
    seq:
    - id: size_of_outputs
      type: s4
    - id: outputs
      type: sapling__transaction__output
      size: size_of_outputs
      repeat: eos
      doc: Output of a transaction
  sapling__transaction__output:
    seq:
    - id: cm
      size: 32
    - id: proof_o
      size: 192
    - id: ciphertext
      type: sapling__transaction__ciphertext
  sapling__transaction__ciphertext:
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
    - id: size_of_payload_enc
      type: s4
    - id: payload_enc
      size: size_of_payload_enc
  inputs:
    seq:
    - id: size_of_inputs
      type: s4
    - id: inputs
      type: sapling__transaction__input
      size: size_of_inputs
      repeat: eos
      valid:
        max: 1833216
      doc: Input of a transaction
  sapling__transaction__input:
    seq:
    - id: cv
      size: 32
    - id: nf
      size: 32
    - id: rk
      size: 32
    - id: proof_i
      size: 192
    - id: signature
      size: 64
seq:
- id: inputs
  type: inputs
- id: outputs
  type: outputs
- id: binding_sig
  size: 64
  doc: Binding signature of a transaction
- id: balance
  type: s8
- id: root
  size: 32
- id: bound_data
  type: bound_data
