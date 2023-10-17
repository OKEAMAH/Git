meta:
  id: id_015__ptlimapt__block_header
  endian: be
types:
  id_015__ptlimapt__block_header__alpha__full_header:
    seq:
    - id: block_header__shell
      type: block_header__shell
      doc: ! >-
        Shell header: Block header's shell-related content. It contains information
        such as the block level, its predecessor and timestamp.
    - id: id_015__ptlimapt__block_header__alpha__signed_contents
      type: id_015__ptlimapt__block_header__alpha__signed_contents
  id_015__ptlimapt__block_header__alpha__signed_contents:
    seq:
    - id: id_015__ptlimapt__block_header__alpha__unsigned_contents
      type: id_015__ptlimapt__block_header__alpha__unsigned_contents
    - id: signature
      size: 64
  id_015__ptlimapt__block_header__alpha__unsigned_contents:
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
  block_header__shell:
    seq:
    - id: level
      type: s4
    - id: proto
      type: u1
    - id: predecessor
      size: 32
    - id: timestamp
      type: s8
      doc: ! 'A timestamp as seen by the protocol: second-level precision, epoch based.'
    - id: validation_pass
      type: u1
    - id: operations_hash
      size: 32
    - id: fitness
      type: fitness
      doc: ! >-
        Block fitness: The fitness, or score, of a block, that allow the Tezos to
        decide which chain is the best. A fitness value is a list of byte sequences.
        They are compared as follows: shortest lists are smaller; lists of the same
        length are compared according to the lexicographical order.
    - id: context
      size: 32
  fitness:
    seq:
    - id: size_of_fitness
      type: s4
    - id: fitness
      type: fitness_entries
      size: size_of_fitness
      repeat: eos
  fitness_entries:
    seq:
    - id: fitness__elem
      type: fitness__elem
  fitness__elem:
    seq:
    - id: size_of_fitness__elem
      type: s4
    - id: fitness__elem
      size: size_of_fitness__elem
enums:
  bool:
    0: false
    255: true
seq:
- id: id_015__ptlimapt__block_header__alpha__full_header
  type: id_015__ptlimapt__block_header__alpha__full_header
