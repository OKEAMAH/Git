meta:
  id: id_007__psdelph1__errors
  endian: be
doc: ! >-
  Encoding id: 007-PsDELPH1.errors

  Description: The full list of RPC errors would be too long to include.It is

  available through the RPC `/errors` (GET).
seq:
- id: len_id_007__psdelph1__errors
  type: u4
  valid:
    max: 1073741823
- id: id_007__psdelph1__errors
  size: len_id_007__psdelph1__errors