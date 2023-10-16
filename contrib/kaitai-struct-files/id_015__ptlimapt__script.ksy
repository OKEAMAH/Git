meta:
  id: id_015__ptlimapt__script
  endian: be
types:
  id_015__ptlimapt__scripted__contracts:
    seq:
    - id: code
      type: code
    - id: storage
      type: storage
  storage:
    seq:
    - id: size_of_storage
      type: s4
    - id: storage
      size: size_of_storage
  code:
    seq:
    - id: size_of_code
      type: s4
    - id: code
      size: size_of_code
seq:
- id: id_015__ptlimapt__scripted__contracts
  type: id_015__ptlimapt__scripted__contracts
