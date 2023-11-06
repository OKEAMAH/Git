meta:
  id: id_012__psithaca__script
  endian: be
doc: ! 'Encoding id: 012-Psithaca.script'
types:
  id_012__psithaca__scripted__contracts_:
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
- id: id_012__psithaca__scripted__contracts_
  type: id_012__psithaca__scripted__contracts_
