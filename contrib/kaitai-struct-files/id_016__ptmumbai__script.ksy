meta:
  id: id_016__ptmumbai__script
  endian: be
doc: ! 'Encoding id: 016-PtMumbai.script'
types:
  id_016__ptmumbai__scripted__contracts_:
    seq:
    - id: code
      type: bytes_dyn_uint30
    - id: storage
      type: bytes_dyn_uint30
  bytes_dyn_uint30:
    seq:
    - id: len_bytes_dyn_uint30
      type: u4
      valid:
        max: 1073741823
    - id: bytes_dyn_uint30
      size: len_bytes_dyn_uint30
  uint30:
    seq:
    - id: uint30
      type: u4
      valid:
        max: 1073741823
seq:
- id: id_016__ptmumbai__scripted__contracts_
  type: id_016__ptmumbai__scripted__contracts_
