meta:
  id: id_007__psdelph1__delegate__frozen_balance
  endian: be
types:
  n:
    seq:
    - id: n
      type: n_chunk
      repeat: until
      repeat-until: not (_.has_more).as<bool>
  n_chunk:
    seq:
    - id: has_more
      type: b1be
    - id: payload
      type: b7be
seq:
- id: deposit
  type: n
- id: fees
  type: n
- id: rewards
  type: n
