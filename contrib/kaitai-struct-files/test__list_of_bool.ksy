meta:
  id: test__list_of_bool
  endian: be
doc: List of boolean values
types:
  test__list_of_bool_entries:
    seq:
    - id: test__list_of_bool_elt
      type: u1
      enum: bool
enums:
  bool:
    0: false
    255: true
seq:
- id: size_of_test__list_of_bool
  type: s4
- id: test__list_of_bool
  type: test__list_of_bool_entries
  size: size_of_test__list_of_bool
  repeat: eos
