meta:
  id: sapling__transaction
  endian: be
  imports:
  - sapling__transaction__binding_sig
  - sapling__transaction__commitment_hash
  - sapling__transaction__input
  - sapling__transaction__output
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
    - id: outputs_elt
      type: sapling__transaction__output
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
    - id: inputs_elt
      type: sapling__transaction__input
seq:
- id: inputs
  type: inputs
- id: outputs
  type: outputs
- id: binding_sig
  type: sapling__transaction__binding_sig
- id: balance
  type: s8
- id: root
  type: sapling__transaction__commitment_hash
- id: bound_data
  type: bound_data
