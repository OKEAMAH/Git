meta:
  id: mempool
  endian: be
doc: ! >-
  Encoding id: mempool

  Description: A batch of operation. This format is used to gossip operations between
  peers.
types:
  known_valid:
    seq:
    - id: len_known_valid
      type: s4
    - id: known_valid
      type: known_valid_entries
      size: len_known_valid
      repeat: eos
  known_valid_entries:
    seq:
    - id: operation_hash
      size: 32
  pending:
    seq:
    - id: len_pending
      type: s4
    - id: pending
      type: pending_entries
      size: len_pending
      repeat: eos
  pending_:
    seq:
    - id: len_pending
      type: s4
    - id: pending
      type: pending
      size: len_pending
  pending_entries:
    seq:
    - id: operation_hash
      size: 32
seq:
- id: known_valid
  type: known_valid
- id: pending
  type: pending_
