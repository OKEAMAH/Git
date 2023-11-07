meta:
  id: ground__string
  endian: be
doc: ! 'Encoding id: ground.string'
types:
  uint30:
    seq:
    - id: uint30
      type: u4
      valid:
        max: 1073741823
seq:
- id: len_ground__string
  type: uint30
- id: ground__string
  size: len_ground__string
