meta:
  id: id_009__psfloren__script
  endian: be
doc: ! 'Encoding id: 009-PsFLoren.script'
types:
  id_009__psfloren__scripted__contracts:
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
- id: id_009__psfloren__scripted__contracts
  type: id_009__psfloren__scripted__contracts
