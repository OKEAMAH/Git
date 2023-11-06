meta:
  id: id_005__psbabym1__script
  endian: be
doc: ! 'Encoding id: 005-PsBabyM1.script'
types:
  id_005__psbabym1__scripted__contracts:
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
- id: id_005__psbabym1__scripted__contracts
  type: id_005__psbabym1__scripted__contracts
