meta:
  id: id_005__psbabym1__fitness
  endian: be
types:
  fitness:
    seq:
    - id: len_fitness
      type: s4
    - id: fitness
      type: fitness_entries
      size: len_fitness
      repeat: eos
  fitness_entries:
    seq:
    - id: fitness__elem
      type: fitness__elem
  fitness__elem:
    seq:
    - id: len_fitness__elem
      type: s4
    - id: fitness__elem
      size: len_fitness__elem
seq:
- id: fitness
  type: fitness
  doc: ! >-
    Block fitness: The fitness, or score, of a block, that allow the Tezos to decide
    which chain is the best. A fitness value is a list of byte sequences. They are
    compared as follows: shortest lists are smaller; lists of the same length are
    compared according to the lexicographical order.
