meta:
  id: id_005__psbabym1__errors
  endian: be
doc: ! >-
  Encoding id: 005-PsBabyM1.errors

  Description: The full list of RPC errors would be too long to include.It is

  available through the RPC `/errors` (GET).
seq:
- id: size_of_id_005__psbabym1__errors
  type: u4
  valid:
    max: 1073741823
- id: id_005__psbabym1__errors
  size: size_of_id_005__psbabym1__errors
