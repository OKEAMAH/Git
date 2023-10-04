meta:
  id: ground__n
  endian: be
doc: Arbitrary precision natural numbers
types:
  n:
    seq:
    - id: n
      type: n_chunk
      repeat: until
      repeat-until: not (_.continue).as<bool>
  n_chunk:
    seq:
    - id: continue
      type: b1be
    - id: payload
      type: b7be
seq:
- id: ground__n
  type: n
