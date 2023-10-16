meta:
  id: id_009__psfloren__delegate__frozen_balance_by_cycles
  endian: be
types:
  id_009__psfloren__delegate__frozen_balance_by_cycles_entries:
    seq:
    - id: cycle
      type: s4
    - id: deposit
      type: id_009__psfloren__mutez
      size: 10
    - id: fees
      type: id_009__psfloren__mutez
      size: 10
    - id: rewards
      type: id_009__psfloren__mutez
      size: 10
  id_009__psfloren__mutez:
    seq:
    - id: id_009__psfloren__mutez
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
- id: len_id_009__psfloren__delegate__frozen_balance_by_cycles
  type: s4
- id: id_009__psfloren__delegate__frozen_balance_by_cycles
  type: id_009__psfloren__delegate__frozen_balance_by_cycles_entries
  size: len_id_009__psfloren__delegate__frozen_balance_by_cycles
  repeat: eos
