meta:
  id: test__nested_list_of_uint8
  endian: be
doc: ! 'Encoding id: test.nested_list_of_uint8

  Description: Nested list of uint8 values'
types:
  test__nested_list_of_uint8_dyn:
    seq:
    - id: test__nested_list_of_uint8_entries
      type: test__nested_list_of_uint8_entries
      repeat: eos
  test__nested_list_of_uint8_entries:
    seq:
    - id: len_test__nested_list_of_uint8_elt_dyn
      type: uint30
    - id: test__nested_list_of_uint8_elt_dyn
      type: test__nested_list_of_uint8_elt_dyn
      size: len_test__nested_list_of_uint8_elt_dyn
  test__nested_list_of_uint8_elt_dyn:
    seq:
    - id: test__nested_list_of_uint8_elt_entries
      type: test__nested_list_of_uint8_elt_entries
      repeat: eos
  test__nested_list_of_uint8_elt_entries:
    seq:
    - id: test__nested_list_of_uint8_elt_elt
      type: u1
  uint30:
    seq:
    - id: uint30
      type: u4
      valid:
        max: 1073741823
seq:
- id: len_test__nested_list_of_uint8_dyn
  type: uint30
- id: test__nested_list_of_uint8_dyn
  type: test__nested_list_of_uint8_dyn
  size: len_test__nested_list_of_uint8_dyn
