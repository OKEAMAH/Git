meta:
  id: id_007__psdelph1__block_header__protocol_data
  endian: be
types:
  id_007__psdelph1__block_header__alpha__signed_contents:
    meta:
      id: id_007__psdelph1__block_header__alpha__signed_contents
      endian: be
    types:
      id_007__psdelph1__block_header__alpha__unsigned_contents:
        meta:
          id: id_007__psdelph1__block_header__alpha__unsigned_contents
          endian: be
        seq:
        - id: priority
          type: u2
        - id: proof_of_work_nonce
          size: 8
        - id: seed_nonce_hash_tag
          type: u1
          enum: bool
        - id: cycle_nonce
          size: 32
          if: (seed_nonce_hash_tag == bool::true)
    seq:
    - id: id_007__psdelph1__block_header__alpha__unsigned_contents
      type: id_007__psdelph1__block_header__alpha__unsigned_contents
    - id: signature__v0
      size: 64
enums:
  bool:
    0: false
    255: true
seq:
- id: id_007__psdelph1__block_header__alpha__signed_contents
  type: id_007__psdelph1__block_header__alpha__signed_contents
