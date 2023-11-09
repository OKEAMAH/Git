meta:
  id: id_015__ptlimapt__script
  endian: be
doc: ! 'Encoding id: 015-PtLimaPt.script'
types:
  code:
    seq:
    - id: len_code
      type: s4
    - id: code
      size: len_code
  id_015__ptlimapt__scripted__contracts:
    seq:
    - id: code
      type: code
    - id: storage
      type: storage
  storage:
    seq:
    - id: len_storage
      type: s4
    - id: storage
      size: len_storage
seq:
- id: id_015__ptlimapt__scripted__contracts
  type: id_015__ptlimapt__scripted__contracts
