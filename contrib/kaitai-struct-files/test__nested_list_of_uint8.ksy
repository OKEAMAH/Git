meta:
  id: test__nested_list_of_uint8
  endian: be
doc: ! 'Encoding id: test.nested_list_of_uint8

  Description: Nested list of uint8 values'
types:
  test__nested_list_of_uint8_entries:
    seq:
    - id: size_of_test__nested_list_of_uint8_elt
      type: s4
    - id: test__nested_list_of_uint8_elt
      type: test__nested_list_of_uint8_elt_entries
      size: size_of_test__nested_list_of_uint8_elt
      repeat: eos
  test__nested_list_of_uint8_elt_entries:
    seq:
    - id: test__nested_list_of_uint8_elt_elt
      type: u1
seq:
- id: size_of_test__nested_list_of_uint8
  type: s4
- id: test__nested_list_of_uint8
  type: test__nested_list_of_uint8_entries
  size: size_of_test__nested_list_of_uint8
  repeat: eos
