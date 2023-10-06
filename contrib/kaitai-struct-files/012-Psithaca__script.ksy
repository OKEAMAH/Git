meta:
  id: id_012__psithaca__script
  endian: be
types:
  id_012__psithaca__scripted__contracts:
    meta:
      id: id_012__psithaca__scripted__contracts
      endian: be
    types:
      storage:
        meta:
          id: storage
          endian: be
        seq:
        - id: len_storage
          type: s4
        - id: storage
          size: len_storage
      code:
        meta:
          id: code
          endian: be
        seq:
        - id: len_code
          type: s4
        - id: code
          size: len_code
    seq:
    - id: code
      type: code
    - id: storage
      type: storage
seq:
- id: id_012__psithaca__scripted__contracts
  type: id_012__psithaca__scripted__contracts
