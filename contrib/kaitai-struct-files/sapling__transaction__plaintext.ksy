meta:
  id: sapling__transaction__plaintext
  endian: be
  imports:
  - sapling__transaction__rcm
doc: ! 'Encoding id: sapling.transaction.plaintext'
types:
  bytes_dyn_uint30:
    seq:
    - id: len_bytes_dyn_uint30
      type: u4
      valid:
        max: 1073741823
    - id: bytes_dyn_uint30
      size: len_bytes_dyn_uint30
  uint30:
    seq:
    - id: uint30
      type: u4
      valid:
        max: 1073741823
seq:
- id: diversifier
  size: 11
- id: amount
  type: s8
- id: rcm
  type: sapling__transaction__rcm
- id: memo
  type: bytes_dyn_uint30
