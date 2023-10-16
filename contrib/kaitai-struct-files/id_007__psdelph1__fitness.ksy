meta:
  id: id_007__psdelph1__fitness
  endian: be
types:
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
- id: fitness
  type: fitness
  doc: ! >-
    Block fitness: The fitness, or score, of a block, that allow the Tezos to decide
    which chain is the best. A fitness value is a list of byte sequences. They are
    compared as follows: shortest lists are smaller; lists of the same length are
    compared according to the lexicographical order.
