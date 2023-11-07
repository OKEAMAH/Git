meta:
  id: id_008__ptedo2zk__errors
  endian: be
doc: ! >-
  Encoding id: 008-PtEdo2Zk.errors

  Description: The full list of RPC errors would be too long to include.It is

  available through the RPC `/errors` (GET).
types:
  uint30:
    seq:
    - id: uint30
      type: u4
      valid:
        max: 1073741823
seq:
- id: len_id_008__ptedo2zk__errors
  type: uint30
- id: id_008__ptedo2zk__errors
  size: len_id_008__ptedo2zk__errors
