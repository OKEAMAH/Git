meta:
  id: sapling__wallet__spending_key
  endian: be
types:
  sapling__wallet__expanded_spending_key:
    meta:
      id: sapling__wallet__expanded_spending_key
      endian: be
    seq:
    - id: ask
      size: 32
    - id: nsk
      size: 32
    - id: ovk
      size: 32
seq:
- id: depth
  size: 1
- id: parent_fvk_tag
  size: 4
- id: child_index
  size: 4
- id: chain_code
  size: 32
- id: sapling__wallet__expanded_spending_key
  type: sapling__wallet__expanded_spending_key
- id: dk
  size: 32
