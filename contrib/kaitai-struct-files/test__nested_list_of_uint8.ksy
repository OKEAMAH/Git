meta:
  id: test__nested_list_of_uint8
  endian: be
doc: ! 'Encoding id: test.nested_list_of_uint8

  Description: Nested list of uint8 values'
types:
  test__nested_list_of_uint8_:
    seq:
    - id: test__nested_list_of_uint8_entries
      type: test__nested_list_of_uint8_entries
      repeat: eos
  test__nested_list_of_uint8_entries:
    seq:
    - id: len_test__nested_list_of_uint8_elt
      type: u4
      valid:
        max: 1073741823
    - id: test__nested_list_of_uint8_elt_
      type: test__nested_list_of_uint8_elt_
      size: len_test__nested_list_of_uint8_elt
  test__nested_list_of_uint8_elt_:
    seq:
    - id: test__nested_list_of_uint8_elt_entries
      type: test__nested_list_of_uint8_elt_entries
      repeat: eos
  test__nested_list_of_uint8_elt_entries:
    seq:
    - id: test__nested_list_of_uint8_elt_elt
      type: u1
seq:
- id: len_test__nested_list_of_uint8
  type: u4
  valid:
    max: 1073741823
- id: test__nested_list_of_uint8_
  type: test__nested_list_of_uint8_
  size: len_test__nested_list_of_uint8
