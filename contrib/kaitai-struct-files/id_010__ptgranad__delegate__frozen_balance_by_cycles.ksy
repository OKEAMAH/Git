meta:
  id: id_010__ptgranad__delegate__frozen_balance_by_cycles
  endian: be
types:
  id_010__ptgranad__delegate__frozen_balance_by_cycles_entries:
    seq:
    - id: cycle
      type: s4
    - id: deposits
      type: n
    - id: fees
      type: n
    - id: rewards
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
- id: size_of_id_010__ptgranad__delegate__frozen_balance_by_cycles
  type: s4
- id: id_010__ptgranad__delegate__frozen_balance_by_cycles
  type: id_010__ptgranad__delegate__frozen_balance_by_cycles_entries
  size: size_of_id_010__ptgranad__delegate__frozen_balance_by_cycles
  repeat: eos
