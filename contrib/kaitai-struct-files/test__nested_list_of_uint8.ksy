meta:
  id: test__nested_list_of_uint8
  endian: be
doc: ! 'Encoding id: test.nested_list_of_uint8

  Description: Nested list of uint8 values'
types:
  test__nested_list_of_uint8:
    seq:
    - id: test__nested_list_of_uint8_entries
      type: test__nested_list_of_uint8_entries
      repeat: eos
  test__nested_list_of_uint8_elt:
    seq:
    - id: test__nested_list_of_uint8_elt_entries
      type: test__nested_list_of_uint8_elt_entries
      repeat: eos
  test__nested_list_of_uint8_elt_entries:
    seq:
    - id: test__nested_list_of_uint8_elt_elt
      type: u1
  test__nested_list_of_uint8_entries:
    seq:
    - id: len_test__nested_list_of_uint8_elt
      type: u4
      valid:
        max: 1073741823
    - id: test__nested_list_of_uint8_elt
      type: test__nested_list_of_uint8_elt
      size: len_test__nested_list_of_uint8_elt
seq:
- id: len_test__nested_list_of_uint8
  type: u4
  valid:
    max: 1073741823
- id: test__nested_list_of_uint8
  type: test__nested_list_of_uint8
  size: len_test__nested_list_of_uint8
