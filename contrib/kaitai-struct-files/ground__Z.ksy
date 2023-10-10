meta:
  id: ground__z
  endian: be
doc: Arbitrary precision integers
types:
  n:
    meta:
      id: n
      endian: be
    types:
      n_group:
        instances:
          has_next:
            value: ((b & 128) != 0)
          value:
            value: (b & 127)
        seq:
        - id: b
          type: u1
    seq:
    - id: n
      type: n_group
      repeat: until
      repeat-until: not (_.has_next)
seq:
- id: z
  type: n
