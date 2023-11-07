meta:
  id: p2p_address
  endian: be
doc: ! 'Encoding id: p2p_address

  Description: An address for locating peers.'
types:
  uint30:
    seq:
    - id: uint30
      type: u4
      valid:
        max: 1073741823
seq:
- id: len_p2p_address
  type: uint30
- id: p2p_address
  size: len_p2p_address
