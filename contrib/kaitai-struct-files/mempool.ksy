meta:
  id: mempool
  endian: be
doc: ! >-
  Encoding id: mempool

  Description: A batch of operation. This format is used to gossip operations between
  peers.
types:
  pending:
    seq:
    - id: len_pending_outer_dyn
      type: u4
      valid:
        max: 1073741823
    - id: pending_outer_dyn
      type: pending_outer_dyn
      size: len_pending_outer_dyn
  pending_outer_dyn:
    seq:
    - id: len_pending_dyn
      type: u4
      valid:
        max: 1073741823
    - id: pending_dyn
      type: pending_dyn
      size: len_pending_dyn
  pending_dyn:
    seq:
    - id: pending_entries
      type: pending_entries
      repeat: eos
  pending_entries:
    seq:
    - id: operation_hash
      size: 32
  known_valid:
    seq:
    - id: len_known_valid_dyn
      type: u4
      valid:
        max: 1073741823
    - id: known_valid_dyn
      type: known_valid_dyn
      size: len_known_valid_dyn
  known_valid_dyn:
    seq:
    - id: known_valid_entries
      type: known_valid_entries
      repeat: eos
  known_valid_entries:
    seq:
    - id: operation_hash
      size: 32
seq:
- id: known_valid
  type: known_valid
- id: pending
  type: pending
