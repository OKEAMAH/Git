meta:
  id: sapling__transaction
  endian: be
doc: ! >-
  Encoding id: sapling.transaction

  Description: A Sapling transaction with inputs, outputs, balance, root, bound_data
  and binding sig.
types:
  bound_data:
    seq:
    - id: len_bound_data
      type: u4
      valid:
        max: 1073741823
    - id: bound_data
      size: len_bound_data
  outputs:
    seq:
    - id: len_outputs_dyn
      type: u4
      valid:
        max: 1073741823
    - id: outputs_dyn
      type: outputs_dyn
      size: len_outputs_dyn
  outputs_dyn:
    seq:
    - id: outputs_entries
      type: outputs_entries
      repeat: eos
  outputs_entries:
    seq:
    - id: sapling__transaction__output_
      type: sapling__transaction__output_
      doc: Output of a transaction
  sapling__transaction__output_:
    seq:
    - id: cm
      size: 32
    - id: proof_o
      size: 192
    - id: ciphertext
      type: sapling__transaction__ciphertext_
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
  inputs:
    seq:
    - id: len_inputs_dyn
      type: u4
      valid:
        max: 1833216
    - id: inputs_dyn
      type: inputs_dyn
      size: len_inputs_dyn
  inputs_dyn:
    seq:
    - id: inputs_entries
      type: inputs_entries
      repeat: eos
  inputs_entries:
    seq:
    - id: sapling__transaction__input_
      type: sapling__transaction__input_
      doc: Input of a transaction
  sapling__transaction__input_:
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
