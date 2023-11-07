meta:
  id: alpha__block_header__unsigned
  endian: be
  imports:
  - block_header__shell
doc: ! 'Encoding id: alpha.block_header.unsigned'
types:
  alpha__block_header__alpha__unsigned_contents_:
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
    - id: per_block_votes
      type: u1
      enum: alpha__per_block_votes_tag
enums:
  alpha__per_block_votes_tag:
    0: case__0
    1: case__1
    2: case__2
    4: case__4
    5: case__5
    6: case__6
    8: case__8
    9: case__9
    10: case__10
  bool:
    0: false
    255: true
seq:
- id: alpha__block_header__unsigned
  type: block_header__shell
- id: alpha__block_header__alpha__unsigned_contents_
  type: alpha__block_header__alpha__unsigned_contents_
