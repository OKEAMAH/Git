meta:
  id: id_008__ptedo2zk__gas__cost
  endian: be
types:
  z:
    seq:
    - id: continue
      type: b1be
    - id: sign
      type: b1be
    - id: payload
      type: b6be
    - id: tail
      type: n_chunk
  n_chunk:
    seq:
    - id: continue
      type: b1be
    - id: payload
      type: b7be
seq:
- id: id_008__ptedo2zk__gas__cost
  type: z
