meta:
  id: test__nested_list_of_bool
  endian: be
doc: ! 'Encoding id: test.nested_list_of_bool

  Description: Nested list of boolean values'
types:
  test__nested_list_of_bool_dyn:
    seq:
    - id: test__nested_list_of_bool_entries
      type: test__nested_list_of_bool_entries
      repeat: eos
  test__nested_list_of_bool_entries:
    seq:
    - id: len_test__nested_list_of_bool_elt_dyn
      type: u4
      valid:
        max: 1073741823
    - id: test__nested_list_of_bool_elt_dyn
      type: test__nested_list_of_bool_elt_dyn
      size: len_test__nested_list_of_bool_elt_dyn
  test__nested_list_of_bool_elt_dyn:
    seq:
    - id: test__nested_list_of_bool_elt_entries
      type: test__nested_list_of_bool_elt_entries
      repeat: eos
  test__nested_list_of_bool_elt_entries:
    seq:
    - id: test__nested_list_of_bool_elt_elt
      type: u1
      enum: bool
enums:
  bool:
    0: false
    255: true
seq:
- id: len_test__nested_list_of_bool_dyn
  type: u4
  valid:
    max: 1073741823
- id: test__nested_list_of_bool_dyn
  type: test__nested_list_of_bool_dyn
  size: len_test__nested_list_of_bool_dyn
