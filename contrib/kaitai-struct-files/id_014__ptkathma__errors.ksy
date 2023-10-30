meta:
  id: id_014__ptkathma__errors
  endian: be
doc: ! >-
  Encoding id: 014-PtKathma.errors

  Description: The full list of RPC errors would be too long to include.It is

  available through the RPC `/errors` (GET).
seq:
- id: size_of_id_014__ptkathma__errors
  type: u4
  valid:
    max: 1073741823
- id: id_014__ptkathma__errors
  size: size_of_id_014__ptkathma__errors
