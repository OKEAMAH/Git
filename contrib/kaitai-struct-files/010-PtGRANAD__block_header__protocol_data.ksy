meta:
  id: id_010__ptgranad__block_header__protocol_data
  endian: be
types:
  id_010__ptgranad__block_header__alpha__signed_contents:
    seq:
    - id: id_010__ptgranad__block_header__alpha__unsigned_contents
      type: id_010__ptgranad__block_header__alpha__unsigned_contents
    - id: signature__v0
      size: 64
  id_010__ptgranad__block_header__alpha__unsigned_contents:
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
    - id: liquidity_baking_escape_vote
      type: u1
      enum: bool
enums:
  bool:
    0: false
    255: true
seq:
- id: id_010__ptgranad__block_header__alpha__signed_contents
  type: id_010__ptgranad__block_header__alpha__signed_contents
