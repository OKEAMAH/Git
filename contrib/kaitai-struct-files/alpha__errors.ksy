meta:
  id: alpha__errors
  endian: be
doc: ! >-
  Encoding id: alpha.errors

  Description: The full list of RPC errors would be too long to include.It is

  available through the RPC `/errors` (GET).
seq:
- id: size_of_alpha__errors
  type: u4
  valid:
    max: 1073741823
- id: alpha__errors
  size: size_of_alpha__errors
