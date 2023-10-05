meta:
  id: sapling__transaction__input
  endian: be
doc: Input of a transaction
seq:
- id: sapling__transaction__commitment_value
  size: 32
- id: sapling__transaction__nullifier
  size: 32
- id: rk
  size: 32
- id: proof_i
  size: 192
- id: signature
  size: 64
