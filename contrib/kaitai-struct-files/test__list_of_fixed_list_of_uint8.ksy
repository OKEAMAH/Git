meta:
  id: test__list_of_fixed_list_of_uint8
  endian: be
doc: ! >-
  Encoding id: test.list_of_fixed_list_of_uint8

  Description: List of fixed sized list of uint8 values
types:
  test__list_of_fixed_list_of_uint8_entries:
    seq:
    - id: test__list_of_fixed_list_of_uint8_elt_entries
      type: test__list_of_fixed_list_of_uint8_elt_entries
      repeat: expr
      repeat-expr: 5
  test__list_of_fixed_list_of_uint8_elt_entries:
    seq:
    - id: test__list_of_fixed_list_of_uint8_elt_elt
      type: u1
seq:
- id: size_of_test__list_of_fixed_list_of_uint8
  type: s4
- id: test__list_of_fixed_list_of_uint8
  type: test__list_of_fixed_list_of_uint8_entries
  size: size_of_test__list_of_fixed_list_of_uint8
  repeat: eos
