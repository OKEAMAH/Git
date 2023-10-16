meta:
  id: id_007__psdelph1__delegate__frozen_balance_by_cycles
  endian: be
types:
  id_007__psdelph1__delegate__frozen_balance_by_cycles_entries:
    seq:
    - id: cycle
      type: s4
    - id: deposit
      type: id_007__psdelph1__mutez
      size: 10
    - id: fees
      type: id_007__psdelph1__mutez
      size: 10
    - id: rewards
      type: id_007__psdelph1__mutez
      size: 10
  id_007__psdelph1__mutez:
    seq:
    - id: id_007__psdelph1__mutez
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
- id: size_of_id_007__psdelph1__delegate__frozen_balance_by_cycles
  type: s4
- id: id_007__psdelph1__delegate__frozen_balance_by_cycles
  type: id_007__psdelph1__delegate__frozen_balance_by_cycles_entries
  size: size_of_id_007__psdelph1__delegate__frozen_balance_by_cycles
  repeat: eos
