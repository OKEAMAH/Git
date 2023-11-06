meta:
  id: p2p_point__id
  endian: be
doc: ! 'Encoding id: p2p_point.id'
types:
  p2p_point__id:
    seq:
    - id: len_p2p_point__id
      type: u4
      valid:
        max: 1073741823
    - id: p2p_point__id
      size: len_p2p_point__id
seq:
- id: p2p_point__id
  type: p2p_point__id
  doc: Identifier for a peer point
