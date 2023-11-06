meta:
  id: id_013__ptjakart__block_header__contents
  endian: be
doc: ! 'Encoding id: 013-PtJakart.block_header.contents'
types:
  id_013__ptjakart__block_header__alpha__unsigned_contents_:
    seq:
    - id: payload_hash
      size: 32
    - id: payload_round
      type: s4
    - id: proof_of_work_nonce
      size: 8
    - id: seed_nonce_hash_tag
      type: u1
      enum: bool
    - id: seed_nonce_hash
      size: 32
      if: (seed_nonce_hash_tag == bool::true)
    - id: liquidity_baking_toggle_vote
      type: s1
enums:
  bool:
    0: false
    255: true
seq:
- id: id_013__ptjakart__block_header__alpha__unsigned_contents_
  type: id_013__ptjakart__block_header__alpha__unsigned_contents_
