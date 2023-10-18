meta:
  id: test__variable_list_of_uint8
  endian: be
doc: Variable sized list of uint8 values
types:
  test__variable_list_of_uint8_entries:
    seq:
    - id: test__variable_list_of_uint8_elt
      type: u1
seq:
- id: test__variable_list_of_uint8_entries
  type: test__variable_list_of_uint8_entries
  repeat: eos
