meta:
  id: p2p_address
  endian: be
doc: ! 'Encoding id: p2p_address

  Description: An address for locating peers.'
seq:
- id: len_p2p_address
  type: u4
  valid:
    max: 1073741823
- id: p2p_address
  size: len_p2p_address
