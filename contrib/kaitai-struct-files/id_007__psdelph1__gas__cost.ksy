meta:
  id: id_007__psdelph1__gas__cost
  endian: be
doc: ! 'Encoding id: 007-PsDELPH1.gas.cost'
types:
  z:
    seq:
    - id: has_tail
      type: b1be
    - id: sign
      type: b1be
    - id: payload
      type: b6be
    - id: tail
      type: n_chunk
      repeat: until
      repeat-until: not (_.has_more).as<bool>
      if: has_tail.as<bool>
  n_chunk:
    seq:
    - id: has_more
      type: b1be
    - id: payload
      type: b7be
seq:
- id: id_007__psdelph1__gas__cost
  type: z
