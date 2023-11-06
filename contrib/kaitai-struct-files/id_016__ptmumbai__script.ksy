meta:
  id: id_016__ptmumbai__script
  endian: be
doc: ! 'Encoding id: 016-PtMumbai.script'
types:
  id_016__ptmumbai__scripted__contracts_:
    seq:
    - id: code
      type: code
    - id: storage
      type: storage
  storage:
    seq:
    - id: len_storage
      type: u4
      valid:
        max: 1073741823
    - id: storage
      size: len_storage
  code:
    seq:
    - id: len_code
      type: u4
      valid:
        max: 1073741823
    - id: code
      size: len_code
seq:
- id: id_016__ptmumbai__scripted__contracts_
  type: id_016__ptmumbai__scripted__contracts_
