meta:
  id: test__fixed_list_of_uint8
  endian: be
doc: ! >-
  Encoding id: test.fixed_list_of_uint8

  Description: Fixed sized list of uint8 values
types:
  test__fixed_list_of_uint8_entries:
    seq:
    - id: test__fixed_list_of_uint8_elt
      type: u1
seq:
- id: test__fixed_list_of_uint8_entries
  type: test__fixed_list_of_uint8_entries
  repeat: expr
  repeat-expr: 5
