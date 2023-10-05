meta:
  id: ground__z
  endian: be
doc: Arbitrary precision integers
types:
  z:
    seq:
    - id: has_more
      type: b1be
    - id: sign
      type: b1be
    - id: payload
      type: b6be
    - id: tail
      type: n_chunk
      if: not (_.has_more).as<bool>
  n_chunk:
    seq:
    - id: has_more
      type: b1be
    - id: payload
      type: b7be
seq:
- id: ground__z
  type: z
