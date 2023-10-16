meta:
  id: id_013__ptjakart__gas__cost
  endian: be
types:
  id_013__ptjakart__gas__cost:
    seq:
    - id: id_013__ptjakart__gas__cost
      type: z
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
- id: id_013__ptjakart__gas__cost_with_checked_size
  type: id_013__ptjakart__gas__cost
  size: 9
