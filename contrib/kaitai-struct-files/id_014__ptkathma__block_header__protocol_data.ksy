meta:
  id: id_014__ptkathma__block_header__protocol_data
  endian: be
doc: ! 'Encoding id: 014-PtKathma.block_header.protocol_data'
types:
  id_014__ptkathma__block_header__alpha__signed_contents:
    seq:
    - id: id_014__ptkathma__block_header__alpha__unsigned_contents
      type: id_014__ptkathma__block_header__alpha__unsigned_contents
    - id: signature
      size: 64
  id_014__ptkathma__block_header__alpha__unsigned_contents:
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
      type: id_014__ptkathma__liquidity_baking_toggle_vote
  id_014__ptkathma__liquidity_baking_toggle_vote:
    seq:
    - id: id_014__ptkathma__liquidity_baking_toggle_vote
      type: s1
enums:
  bool:
    0: false
    255: true
seq:
- id: id_014__ptkathma__block_header__alpha__signed_contents
  type: id_014__ptkathma__block_header__alpha__signed_contents
