meta:
  id: test__variable_list_of_bool
  endian: be
doc: ! >-
  Encoding id: test.variable_list_of_bool

  Description: Variable sized list of boolean values
types:
  test__variable_list_of_bool_entries:
    seq:
    - id: test__variable_list_of_bool_elt
      type: u1
      enum: bool
enums:
  bool:
    0: false
    255: true
seq:
- id: test__variable_list_of_bool_entries
  type: test__variable_list_of_bool_entries
  repeat: eos
