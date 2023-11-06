meta:
  id: p2p_connection__id
  endian: be
doc: ! >-
  Encoding id: p2p_connection.id

  Description: The identifier for a p2p connection. It includes an address and a port
  number.
types:
  p2p_address:
    seq:
    - id: len_p2p_address
      type: u4
      valid:
        max: 1073741823
    - id: p2p_address
      size: len_p2p_address
enums:
  bool:
    0: false
    255: true
seq:
- id: addr
  type: p2p_address
  doc: An address for locating peers.
- id: port_tag
  type: u1
  enum: bool
- id: port
  type: u2
  if: (port_tag == bool::true)
