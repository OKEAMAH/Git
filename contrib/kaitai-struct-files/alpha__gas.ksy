meta:
  id: alpha__gas
  endian: be
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
enums:
  alpha__gas_tag:
    0: Limited
    1: Unaccounted
seq:
- id: alpha__gas_tag
  type: u1
  enum: alpha__gas_tag
- id: alpha__gas_limited
  type: z
  if: (alpha__gas_tag == alpha__gas_tag::Limited)
