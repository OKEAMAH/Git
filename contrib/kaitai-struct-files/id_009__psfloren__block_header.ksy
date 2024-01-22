meta:
  id: id_009__psfloren__block_header
  endian: be
  imports:
  - block_header__shell
doc: ! 'Encoding id: 009-PsFLoren.block_header'
types:
  id_009__psfloren__block_header__alpha__full_header:
    seq:
    - id: id_009__psfloren__block_header__alpha__full_header
      type: block_header__shell
    - id: id_009__psfloren__block_header__alpha__signed_contents
      type: id_009__psfloren__block_header__alpha__signed_contents
  id_009__psfloren__block_header__alpha__signed_contents:
    seq:
    - id: id_009__psfloren__block_header__alpha__unsigned_contents
      type: id_009__psfloren__block_header__alpha__unsigned_contents
    - id: signature
      size: 64
  id_009__psfloren__block_header__alpha__unsigned_contents:
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
- id: id_009__psfloren__block_header__alpha__full_header
  type: id_009__psfloren__block_header__alpha__full_header
