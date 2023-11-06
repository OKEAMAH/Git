meta:
  id: id_010__ptgranad__fitness
  endian: be
doc: ! 'Encoding id: 010-PtGRANAD.fitness'
types:
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
- id: fitness_
  type: fitness_
  doc: ! >-
    Block fitness: The fitness, or score, of a block, that allow the Tezos to decide
    which chain is the best. A fitness value is a list of byte sequences. They are
    compared as follows: shortest lists are smaller; lists of the same length are
    compared according to the lexicographical order.
