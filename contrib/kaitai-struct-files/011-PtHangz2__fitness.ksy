meta:
  id: id_011__pthangz2__fitness
  endian: be
types:
  fitness:
    doc: ! >-
      Block fitness: The fitness, or score, of a block, that allow the Tezos to decide
      which chain is the best. A fitness value is a list of byte sequences. They are
      compared as follows: shortest lists are smaller; lists of the same length are
      compared according to the lexicographical order.
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
- id: fitness
  type: fitness
