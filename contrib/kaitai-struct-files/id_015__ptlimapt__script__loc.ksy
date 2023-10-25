meta:
  id: id_015__ptlimapt__script__loc
  endian: be
doc: ! 'Encoding id: 015-PtLimaPt.script.loc'
seq:
- id: micheline__location
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
  doc: ! >-
    Canonical location in a Micheline expression: The location of a node in a Micheline
    expression tree in prefix order, with zero being the root and adding one for every
    basic node, sequence and primitive application.
