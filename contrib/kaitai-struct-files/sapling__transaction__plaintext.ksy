meta:
  id: sapling__transaction__plaintext
  endian: be
doc: ! 'Encoding id: sapling.transaction.plaintext'
types:
  memo:
    seq:
    - id: size_of_memo
      type: u4
      valid:
        max: 1073741823
    - id: memo
      size: size_of_memo
seq:
- id: diversifier
  size: 11
- id: amount
  type: s8
- id: rcm
  size: 32
- id: memo
  type: memo
