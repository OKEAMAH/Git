meta:
  id: ground__bytes
  endian: be
doc: ! 'Encoding id: ground.bytes'
seq:
- id: size_of_ground__bytes
  type: u4
  valid:
    max: 1073741823
- id: ground__bytes
  size: size_of_ground__bytes
