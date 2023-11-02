meta:
  id: p2p_connection__pool_event
  endian: be
doc: ! >-
  Encoding id: p2p_connection.pool_event

  Description: An event that may happen during maintenance of and other operations
  on the p2p connection pool. Typically, it includes connection errors, peer swaps,
  etc.
types:
  connection_established__p2p_connection__pool_event:
    seq:
    - id: id_point
      type: connection_established__p2p_connection__id
      doc: The identifier for a p2p connection. It includes an address and a port
        number.
    - id: peer_id
      size: 16
  connection_established__p2p_connection__id:
    seq:
    - id: addr
      type: connection_established__p2p_address
      doc: An address for locating peers.
    - id: port_tag
      type: u1
      enum: bool
    - id: port
      type: u2
      if: (port_tag == bool::true)
  connection_established__p2p_address:
    seq:
    - id: size_of_p2p_address
      type: u4
      valid:
        max: 1073741823
    - id: p2p_address
      size: size_of_p2p_address
  request_rejected__p2p_connection__pool_event:
    seq:
    - id: point
      type: request_rejected__p2p_point__id
      doc: Identifier for a peer point
    - id: identity_tag
      type: u1
      enum: bool
    - id: request_rejected__identity
      type: request_rejected__identity
      if: (identity_tag == bool::true)
  request_rejected__identity:
    seq:
    - id: identity_field0
      type: request_rejected__p2p_connection__id
      doc: ! >-
        The identifier for a p2p connection. It includes an address and a port number.


        request_rejected__p2p_connection__id
    - id: identity_field1
      size: 16
      doc: crypto_box__public_key_hash
  request_rejected__p2p_connection__id:
    seq:
    - id: addr
      type: request_rejected__p2p_address
      doc: An address for locating peers.
    - id: port_tag
      type: u1
      enum: bool
    - id: port
      type: u2
      if: (port_tag == bool::true)
  request_rejected__p2p_address:
    seq:
    - id: size_of_p2p_address
      type: u4
      valid:
        max: 1073741823
    - id: p2p_address
      size: size_of_p2p_address
  request_rejected__p2p_point__id:
    seq:
    - id: size_of_p2p_point__id
      type: u4
      valid:
        max: 1073741823
    - id: p2p_point__id
      size: size_of_p2p_point__id
  rejecting_request__p2p_connection__pool_event:
    seq:
    - id: point
      type: rejecting_request__p2p_point__id
      doc: Identifier for a peer point
    - id: id_point
      type: rejecting_request__p2p_connection__id
      doc: The identifier for a p2p connection. It includes an address and a port
        number.
    - id: peer_id
      size: 16
  rejecting_request__p2p_connection__id:
    seq:
    - id: addr
      type: rejecting_request__p2p_address
      doc: An address for locating peers.
    - id: port_tag
      type: u1
      enum: bool
    - id: port
      type: u2
      if: (port_tag == bool::true)
  rejecting_request__p2p_address:
    seq:
    - id: size_of_p2p_address
      type: u4
      valid:
        max: 1073741823
    - id: p2p_address
      size: size_of_p2p_address
  rejecting_request__p2p_point__id:
    seq:
    - id: size_of_p2p_point__id
      type: u4
      valid:
        max: 1073741823
    - id: p2p_point__id
      size: size_of_p2p_point__id
  accepting_request__p2p_connection__pool_event:
    seq:
    - id: point
      type: accepting_request__p2p_point__id
      doc: Identifier for a peer point
    - id: id_point
      type: accepting_request__p2p_connection__id
      doc: The identifier for a p2p connection. It includes an address and a port
        number.
    - id: peer_id
      size: 16
  accepting_request__p2p_connection__id:
    seq:
    - id: addr
      type: accepting_request__p2p_address
      doc: An address for locating peers.
    - id: port_tag
      type: u1
      enum: bool
    - id: port
      type: u2
      if: (port_tag == bool::true)
  accepting_request__p2p_address:
    seq:
    - id: size_of_p2p_address
      type: u4
      valid:
        max: 1073741823
    - id: p2p_address
      size: size_of_p2p_address
  accepting_request__p2p_point__id:
    seq:
    - id: size_of_p2p_point__id
      type: u4
      valid:
        max: 1073741823
    - id: p2p_point__id
      size: size_of_p2p_point__id
  authentication_failed__p2p_point__id:
    seq:
    - id: size_of_p2p_point__id
      type: u4
      valid:
        max: 1073741823
    - id: p2p_point__id
      size: size_of_p2p_point__id
  outgoing_connection__p2p_point__id:
    seq:
    - id: size_of_p2p_point__id
      type: u4
      valid:
        max: 1073741823
    - id: p2p_point__id
      size: size_of_p2p_point__id
  incoming_connection__p2p_point__id:
    seq:
    - id: size_of_p2p_point__id
      type: u4
      valid:
        max: 1073741823
    - id: p2p_point__id
      size: size_of_p2p_point__id
  new_point__p2p_point__id:
    seq:
    - id: size_of_p2p_point__id
      type: u4
      valid:
        max: 1073741823
    - id: p2p_point__id
      size: size_of_p2p_point__id
enums:
  bool:
    0: false
    255: true
  p2p_connection__pool_event_tag:
    0: too_few_connections
    1: too_many_connections
    2: new_point
    3: new_peer
    4: incoming_connection
    5: outgoing_connection
    6: authentication_failed
    7: accepting_request
    8: rejecting_request
    9: request_rejected
    10: connection_established
    11: disconnection
    12: external_disconnection
    13: gc_points
    14: gc_peer_ids
    15: swap_request_received
    16: swap_ack_received
    17: swap_request_sent
    18: swap_ack_sent
    19: swap_request_ignored
    20: swap_success
    21: swap_failure
    22: bootstrap_sent
    23: bootstrap_received
    24: advertise_sent
    25: advertise_received
seq:
- id: p2p_connection__pool_event_tag
  type: u1
  enum: p2p_connection__pool_event_tag
- id: advertise_received__p2p_connection__pool_event
  size: 16
  if: (p2p_connection__pool_event_tag == ::p2p_connection__pool_event_tag::p2p_connection__pool_event_tag::advertise_received)
