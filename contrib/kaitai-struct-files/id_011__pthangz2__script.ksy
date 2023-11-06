meta:
  id: id_011__pthangz2__script
  endian: be
doc: ! 'Encoding id: 011-PtHangz2.script'
types:
  id_011__pthangz2__scripted__contracts:
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
- id: id_011__pthangz2__scripted__contracts
  type: id_011__pthangz2__scripted__contracts
