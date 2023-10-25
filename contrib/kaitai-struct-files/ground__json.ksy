meta:
  id: ground__json
  endian: be
doc: ! 'Encoding id: ground.json

  Description: JSON values'
seq:
- id: size_of_ground__json
  type: u4
  valid:
    max: 1073741823
- id: ground__json
  size: size_of_ground__json
