meta:
  id: sapling__wallet__viewing_key
  endian: be
types:
  sapling__wallet__full_viewing_key:
    seq:
    - id: ak
      size: 32
    - id: nk
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
- id: sapling__wallet__full_viewing_key
  type: sapling__wallet__full_viewing_key
- id: dk
  size: 32
