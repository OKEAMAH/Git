meta:
  id: id_018__proxford__fitness
  endian: be
doc: ! 'Encoding id: 018-Proxford.fitness'
types:
  locked_round:
    seq:
    - id: locked_round_tag
      type: u1
      enum: locked_round_tag
    - id: locked_round_some
      type: s4
      if: (locked_round_tag == locked_round_tag::some)
enums:
  locked_round_tag:
    0: none
    1: some
seq:
- id: level
  type: s4
- id: locked_round
  type: locked_round
- id: predecessor_round
  type: s4
- id: round
  type: s4
