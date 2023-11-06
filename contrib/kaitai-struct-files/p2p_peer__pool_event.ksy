meta:
  id: p2p_peer__pool_event
  endian: be
doc: ! >-
  Encoding id: p2p_peer.pool_event

  Description: An event that may happen during maintenance of and other operations
  on the connection to a specific peer.
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
  kind:
    2: request_rejected
    3: connection_established
    5: external_disconnection
    4: disconnection
    0: incoming_request
    1: rejecting_request
seq:
- id: kind
  type: u1
  enum: kind
- id: timestamp
  type: s8
  doc: ! >-
    A timestamp as seen by the underlying, local computer: subsecond-level precision,
    epoch or rfc3339 based.
- id: addr
  type: p2p_address
  doc: An address for locating peers.
- id: port_tag
  type: u1
  enum: bool
- id: port
  type: u2
  if: (port_tag == bool::true)