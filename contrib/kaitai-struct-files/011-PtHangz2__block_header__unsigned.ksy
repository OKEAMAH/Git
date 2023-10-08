meta:
  id: id_011__pthangz2__block_header__unsigned
  endian: be
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
    - id: cycle_nonce
      size: 32
      if: (seed_nonce_hash_tag == bool::true)
    - id: liquidity_baking_escape_vote
      type: u1
      enum: bool
  block_header__shell:
    doc: ! >-
      Shell header: Block header's shell-related content. It contains information
      such as the block level, its predecessor and timestamp.
    types:
      fitness:
        doc: ! >-
          Block fitness: The fitness, or score, of a block, that allow the Tezos to
          decide which chain is the best. A fitness value is a list of byte sequences.
          They are compared as follows: shortest lists are smaller; lists of the same
          length are compared according to the lexicographical order.
        types:
          fitness:
            types:
              fitness_entries:
                types:
                  fitness__elem:
                    seq:
                    - id: len_fitness__elem
                      type: s4
                    - id: fitness__elem
                      size: len_fitness__elem
                seq:
                - id: fitness__elem
                  type: fitness__elem
            seq:
            - id: fitness
              type: fitness_entries
              repeat: eos
        seq:
        - id: len_fitness
          type: s4
        - id: fitness
          type: fitness
          size: len_fitness
    seq:
    - id: level
      type: s4
    - id: proto
      type: u1
    - id: block_hash
      size: 32
    - id: timestamp__protocol
      type: s8
    - id: validation_pass
      type: u1
    - id: operation_list_list_hash
      size: 32
    - id: fitness
      type: fitness
    - id: context_hash
      size: 32
enums:
  bool:
    0: false
    255: true
seq:
- id: block_header__shell
  type: block_header__shell
- id: id_011__pthangz2__block_header__alpha__unsigned_contents
  type: id_011__pthangz2__block_header__alpha__unsigned_contents
