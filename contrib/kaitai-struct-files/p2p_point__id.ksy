meta:
  id: p2p_point__id
  endian: be
doc: ! 'Encoding id: p2p_point.id'
types:
  p2p_point__id:
    seq:
    - id: size_of_p2p_point__id
      type: s4
    - id: p2p_point__id
      size: size_of_p2p_point__id
seq:
- id: p2p_point__id
  type: p2p_point__id
  doc: Identifier for a peer point
