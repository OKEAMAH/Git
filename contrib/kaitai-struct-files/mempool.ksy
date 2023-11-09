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
    - id: known_valid_entries
      type: known_valid_entries
      repeat: eos
  known_valid_:
    seq:
    - id: len_known_valid
      type: u4
      valid:
        max: 1073741823
    - id: known_valid
      type: known_valid
      size: len_known_valid
  known_valid_entries:
    seq:
    - id: operation_hash
      size: 32
  pending:
    seq:
    - id: pending_entries
      type: known_valid_entries
      repeat: eos
  pending_:
    seq:
    - id: len_pending
      type: u4
      valid:
        max: 1073741823
    - id: pending
      type: pending
      size: len_pending
  pending__:
    seq:
    - id: len_pending
      type: u4
      valid:
        max: 1073741823
    - id: pending
      type: pending_
      size: len_pending
seq:
- id: known_valid
  type: known_valid_
- id: pending
  type: pending__
