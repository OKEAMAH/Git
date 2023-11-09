meta:
  id: test__nested_list_of_bool
  endian: be
doc: ! 'Encoding id: test.nested_list_of_bool

  Description: Nested list of boolean values'
types:
  test__nested_list_of_bool:
    seq:
    - id: test__nested_list_of_bool_entries
      type: test__nested_list_of_bool_entries
      repeat: eos
  test__nested_list_of_bool_elt:
    seq:
    - id: test__nested_list_of_bool_elt_entries
      type: test__nested_list_of_bool_elt_entries
      repeat: eos
  test__nested_list_of_bool_elt_entries:
    seq:
    - id: test__nested_list_of_bool_elt_elt
      type: u1
      enum: bool
  test__nested_list_of_bool_entries:
    seq:
    - id: len_test__nested_list_of_bool_elt
      type: u4
      valid:
        max: 1073741823
    - id: test__nested_list_of_bool_elt
      type: test__nested_list_of_bool_elt
      size: len_test__nested_list_of_bool_elt
enums:
  bool:
    0: false
    255: true
seq:
- id: len_test__nested_list_of_bool
  type: u4
  valid:
    max: 1073741823
- id: test__nested_list_of_bool
  type: test__nested_list_of_bool
  size: len_test__nested_list_of_bool
