meta:
  id: id_006__pscartha__errors
  endian: be
doc: ! >-
  Encoding id: 006-PsCARTHA.errors

  Description: The full list of RPC errors would be too long to include.It is

  available through the RPC `/errors` (GET).
seq:
- id: size_of_id_006__pscartha__errors
  type: u4
  valid:
    max: 1073741823
- id: id_006__pscartha__errors
  size: size_of_id_006__pscartha__errors
