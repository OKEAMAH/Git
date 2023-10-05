meta:
  id: sapling__transaction__plaintext
  endian: be
types:
  memo:
    meta:
      id: memo
      endian: be
    seq:
    - id: len_memo
      type: s4
    - id: memo
      size: len_memo
seq:
- id: sapling__wallet__diversifier
  size: 11
- id: amount
  type: s8
- id: sapling__transaction__rcm
  size: 32
- id: memo
  type: memo
