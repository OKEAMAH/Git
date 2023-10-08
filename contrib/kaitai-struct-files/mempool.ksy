meta:
  id: mempool
  endian: be
doc: A batch of operation. This format is used to gossip operations between peers.
types:
  pending:
    types:
      pending:
        types:
          pending:
            types:
              pending_entries:
                seq:
                - id: operation_hash
                  size: 32
            seq:
            - id: pending
              type: pending_entries
              repeat: eos
        seq:
        - id: len_pending
          type: s4
        - id: pending
          type: pending
          size: len_pending
    seq:
    - id: len_pending
      type: s4
    - id: pending
      type: pending
      size: len_pending
  known_valid:
    types:
      known_valid:
        types:
          known_valid_entries:
            seq:
            - id: operation_hash
              size: 32
        seq:
        - id: known_valid
          type: known_valid_entries
          repeat: eos
    seq:
    - id: len_known_valid
      type: s4
    - id: known_valid
      type: known_valid
      size: len_known_valid
seq:
- id: known_valid
  type: known_valid
- id: pending
  type: pending
