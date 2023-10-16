meta:
  id: id_005__psbabym1__delegate__frozen_balance
  endian: be
types:
  id_005__psbabym1__mutez:
    seq:
    - id: id_005__psbabym1__mutez
      type: n
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
  type: id_005__psbabym1__mutez
  size: 10
- id: fees
  type: id_005__psbabym1__mutez
  size: 10
- id: rewards
  type: id_005__psbabym1__mutez
  size: 10
