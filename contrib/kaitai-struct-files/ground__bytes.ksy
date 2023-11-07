meta:
  id: ground__bytes
  endian: be
doc: ! 'Encoding id: ground.bytes'
types:
  uint30:
    seq:
    - id: uint30
      type: u4
      valid:
        max: 1073741823
seq:
- id: len_ground__bytes
  type: uint30
- id: ground__bytes
  size: len_ground__bytes
