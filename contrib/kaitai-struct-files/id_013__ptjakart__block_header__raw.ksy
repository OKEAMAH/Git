meta:
  id: id_013__ptjakart__block_header__raw
  endian: be
types:
  block_header:
    seq:
    - id: block_header__shell
      type: block_header__shell
      doc: ! >-
        Shell header: Block header's shell-related content. It contains information
        such as the block level, its predecessor and timestamp.
    - id: protocol_data
      size-eos: true
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
      type: fitness__elem
      size: size_of_fitness
      repeat: eos
  fitness__elem:
    seq:
    - id: size_of_fitness__elem
      type: s4
    - id: fitness__elem
      size: size_of_fitness__elem
seq:
- id: block_header
  type: block_header
  doc: ! 'Block header: Block header. It contains both shell and protocol specific
    data.'
