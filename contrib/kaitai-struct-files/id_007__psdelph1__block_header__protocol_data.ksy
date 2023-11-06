meta:
  id: id_007__psdelph1__block_header__protocol_data
  endian: be
doc: ! 'Encoding id: 007-PsDELPH1.block_header.protocol_data'
types:
  id_007__psdelph1__block_header__alpha__signed_contents_:
    seq:
    - id: id_007__psdelph1__block_header__alpha__unsigned_contents_
      type: id_007__psdelph1__block_header__alpha__unsigned_contents_
    - id: signature
      size: 64
  id_007__psdelph1__block_header__alpha__unsigned_contents_:
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
enums:
  bool:
    0: false
    255: true
seq:
- id: id_007__psdelph1__block_header__alpha__signed_contents_
  type: id_007__psdelph1__block_header__alpha__signed_contents_
