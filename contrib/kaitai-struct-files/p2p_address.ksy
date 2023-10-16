meta:
  id: p2p_address
  endian: be
doc: An address for locating peers.
seq:
- id: size_of_p2p_address
  type: s4
- id: p2p_address
  size: size_of_p2p_address
