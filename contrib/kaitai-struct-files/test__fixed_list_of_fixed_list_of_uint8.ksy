meta:
  id: test__fixed_list_of_fixed_list_of_uint8
  endian: be
doc: ! >-
  Encoding id: test.fixed_list_of_fixed_list_of_uint8

  Description: Fixed sized list of fixed sized list of uint8 values
types:
  test__fixed_list_of_fixed_list_of_uint8_elt_entries:
    seq:
    - id: test__fixed_list_of_fixed_list_of_uint8_elt_elt
      type: u1
  test__fixed_list_of_fixed_list_of_uint8_entries:
    seq:
    - id: test__fixed_list_of_fixed_list_of_uint8_elt_entries
      type: test__fixed_list_of_fixed_list_of_uint8_elt_entries
      repeat: expr
      repeat-expr: 5
seq:
- id: test__fixed_list_of_fixed_list_of_uint8_entries
  type: test__fixed_list_of_fixed_list_of_uint8_entries
  repeat: expr
  repeat-expr: 100
