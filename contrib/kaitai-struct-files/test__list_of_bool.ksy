meta:
  id: test__list_of_bool
  endian: be
doc: ! 'Encoding id: test.list_of_bool

  Description: List of boolean values'
types:
  test__list_of_bool:
    seq:
    - id: test__list_of_bool_entries
      type: test__list_of_bool_entries
      repeat: eos
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
- id: len_test__list_of_bool
  type: u4
  valid:
    max: 1073741823
- id: test__list_of_bool
  type: test__list_of_bool
  size: len_test__list_of_bool
