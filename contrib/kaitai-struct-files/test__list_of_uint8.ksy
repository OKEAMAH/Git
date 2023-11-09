meta:
  id: test__list_of_uint8
  endian: be
doc: ! 'Encoding id: test.list_of_uint8

  Description: List of uint8 values'
types:
  test__list_of_uint8_dyn:
    seq:
    - id: test__list_of_uint8_entries
      type: test__list_of_uint8_entries
      repeat: eos
  test__list_of_uint8_entries:
    seq:
    - id: test__list_of_uint8_elt
      type: u1
seq:
- id: len_test__list_of_uint8_dyn
  type: u4
  valid:
    max: 1073741823
- id: test__list_of_uint8_dyn
  type: test__list_of_uint8_dyn
  size: len_test__list_of_uint8_dyn
