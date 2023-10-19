meta:
  id: id_018__proxford__block_header__protocol_data
  endian: be
types:
  id_018__proxford__block_header__alpha__signed_contents:
    seq:
    - id: id_018__proxford__block_header__alpha__unsigned_contents
      type: id_018__proxford__block_header__alpha__unsigned_contents
    - id: signature
      size-eos: true
  id_018__proxford__block_header__alpha__unsigned_contents:
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
      enum: id_018__proxford__per_block_votes_tag
enums:
  id_018__proxford__per_block_votes_tag:
    0: case 0
    4: case 4
    8: case 8
    1: case 1
    5: case 5
    9: case 9
    2: case 2
    6: case 6
    10: case 10
  bool:
    0: false
    255: true
seq:
- id: id_018__proxford__block_header__alpha__signed_contents
  type: id_018__proxford__block_header__alpha__signed_contents
