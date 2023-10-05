meta:
  id: id_005__psbabym1__gas__cost
  endian: be
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
- id: allocations
  type: z
- id: steps
  type: z
- id: reads
  type: z
- id: writes
  type: z
- id: bytes_read
  type: z
- id: bytes_written
  type: z
