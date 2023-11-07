meta:
  id: id_015__ptlimapt__errors
  endian: be
doc: ! >-
  Encoding id: 015-PtLimaPt.errors

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
- id: len_id_015__ptlimapt__errors
  type: uint30
- id: id_015__ptlimapt__errors
  size: len_id_015__ptlimapt__errors
