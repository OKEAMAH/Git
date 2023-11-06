meta:
  id: ground__string
  endian: be
doc: ! 'Encoding id: ground.string'
seq:
- id: len_ground__string
  type: u4
  valid:
    max: 1073741823
- id: ground__string
  size: len_ground__string
