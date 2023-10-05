meta:
  id: network_version
  endian: be
doc: ! >-
  A version number for the network protocol (includes distributed DB version and p2p
  version)
types:
  distributed_db_version__name:
    meta:
      id: distributed_db_version__name
      endian: be
    doc: A name for the distributed DB protocol
    seq:
    - id: len_distributed_db_version__name
      type: s4
    - id: distributed_db_version__name
      size: len_distributed_db_version__name
seq:
- id: distributed_db_version__name
  type: distributed_db_version__name
- id: distributed_db_version
  type: u2
- id: p2p_version
  type: u2
