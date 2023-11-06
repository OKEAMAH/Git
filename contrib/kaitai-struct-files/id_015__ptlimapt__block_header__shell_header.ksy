meta:
  id: id_015__ptlimapt__block_header__shell_header
  endian: be
doc: ! 'Encoding id: 015-PtLimaPt.block_header.shell_header'
types:
  block_header__shell_:
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
      type: fitness_
      doc: ! >-
        Block fitness: The fitness, or score, of a block, that allow the Tezos to
        decide which chain is the best. A fitness value is a list of byte sequences.
        They are compared as follows: shortest lists are smaller; lists of the same
        length are compared according to the lexicographical order.
    - id: context
      size: 32
  fitness_:
    seq:
    - id: len_fitness_dyn
      type: u4
      valid:
        max: 1073741823
    - id: fitness_dyn
      type: fitness_dyn
      size: len_fitness_dyn
  fitness_dyn:
    seq:
    - id: fitness_entries
      type: fitness_entries
      repeat: eos
  fitness_entries:
    seq:
    - id: fitness__elem_
      type: fitness__elem_
  fitness__elem_:
    seq:
    - id: len_fitness__elem
      type: u4
      valid:
        max: 1073741823
    - id: fitness__elem
      size: len_fitness__elem
seq:
- id: block_header__shell_
  type: block_header__shell_
  doc: ! >-
    Shell header: Block header's shell-related content. It contains information such
    as the block level, its predecessor and timestamp.
