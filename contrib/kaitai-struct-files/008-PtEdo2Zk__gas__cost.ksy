meta:
  id: id_008__ptedo2zk__gas__cost
  endian: be
types:
  z:
    seq:
    - id: has_more_than_single_byte
      type: b1be
    - id: sign
      type: b1be
    - id: payload
      type: b6be
    - id: tail
      type: n_chunk
      repeat: until
      repeat-until: not (_.has_more).as<bool>
      if: not has_more_than_single_byte.as<bool>
  n_chunk:
    seq:
    - id: has_more
      type: b1be
    - id: payload
      type: b7be
seq:
- id: id_008__ptedo2zk__gas__cost
  type: z
