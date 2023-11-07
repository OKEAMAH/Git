meta:
  id: ground__json
  endian: be
doc: ! 'Encoding id: ground.json

  Description: JSON values'
types:
  uint30:
    seq:
    - id: uint30
      type: u4
      valid:
        max: 1073741823
seq:
- id: len_ground__json
  type: uint30
- id: ground__json
  size: len_ground__json
