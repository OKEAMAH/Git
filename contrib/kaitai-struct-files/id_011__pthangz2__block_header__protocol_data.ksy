meta:
  id: id_011__pthangz2__block_header__protocol_data
  endian: be
types:
  id_011__pthangz2__block_header__alpha__signed_contents:
    types:
      id_011__pthangz2__block_header__alpha__unsigned_contents:
        seq:
        - id: priority
          type: u2
        - id: proof_of_work_nonce
          size: 8
        - id: seed_nonce_hash_tag
          type: u1
          enum: bool
        - id: seed_nonce_hash
          size: 32
          if: (seed_nonce_hash_tag == bool::true)
        - id: liquidity_baking_escape_vote
          type: u1
          enum: bool
    seq:
    - id: id_011__pthangz2__block_header__alpha__unsigned_contents
      type: id_011__pthangz2__block_header__alpha__unsigned_contents
    - id: signature
      size: 64
enums:
  bool:
    0: false
    255: true
seq:
- id: id_011__pthangz2__block_header__alpha__signed_contents
  type: id_011__pthangz2__block_header__alpha__signed_contents
