meta:
  id: id_011__pthangz2__delegate__frozen_balance
  endian: be
types:
  id_011__pthangz2__mutez:
    seq:
    - id: id_011__pthangz2__mutez
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
- id: deposits
  type: id_011__pthangz2__mutez
  size: 10
- id: fees
  type: id_011__pthangz2__mutez
  size: 10
- id: rewards
  type: id_011__pthangz2__mutez
  size: 10
