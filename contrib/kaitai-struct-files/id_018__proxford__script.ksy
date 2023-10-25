meta:
  id: id_018__proxford__script
  endian: be
doc: ! 'Encoding id: 018-Proxford.script'
types:
  id_018__proxford__scripted__contracts:
    seq:
    - id: code
      type: code
    - id: storage
      type: storage
  storage:
    seq:
    - id: size_of_storage
      type: u4
      valid:
        max: 1073741823
    - id: storage
      size: size_of_storage
  code:
    seq:
    - id: size_of_code
      type: u4
      valid:
        max: 1073741823
    - id: code
      size: size_of_code
seq:
- id: id_018__proxford__scripted__contracts
  type: id_018__proxford__scripted__contracts
