meta:
  id: id_016__ptmumbai__script
  endian: be
types:
  id_016__ptmumbai__scripted__contracts:
    types:
      storage:
        seq:
        - id: len_storage
          type: s4
        - id: storage
          size: len_storage
      code:
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
- id: id_016__ptmumbai__scripted__contracts
  type: id_016__ptmumbai__scripted__contracts
