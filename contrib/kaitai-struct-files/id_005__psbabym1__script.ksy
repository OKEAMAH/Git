meta:
  id: id_005__psbabym1__script
  endian: be
doc: ! 'Encoding id: 005-PsBabyM1.script'
types:
  id_005__psbabym1__scripted__contracts_:
    seq:
    - id: code
      type: code
    - id: storage
      type: storage
  storage:
    seq:
    - id: len_storage
      type: uint30
    - id: storage
      size: len_storage
  code:
    seq:
    - id: len_code
      type: uint30
    - id: code
      size: len_code
  uint30:
    seq:
    - id: uint30
      type: u4
      valid:
        max: 1073741823
seq:
- id: id_005__psbabym1__scripted__contracts_
  type: id_005__psbabym1__scripted__contracts_
