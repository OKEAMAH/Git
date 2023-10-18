meta:
  id: test__fixed_list_of_fixed_list_of_bool
  endian: be
doc: Fixed sized list of fixed sized list of boolean values
types:
  test__fixed_list_of_fixed_list_of_bool_entries:
    seq:
    - id: test__fixed_list_of_fixed_list_of_bool_elt_entries
      type: test__fixed_list_of_fixed_list_of_bool_elt_entries
      repeat: expr
      repeat-expr: 100
  test__fixed_list_of_fixed_list_of_bool_elt_entries:
    seq:
    - id: test__fixed_list_of_fixed_list_of_bool_elt_elt
      type: u1
      enum: bool
enums:
  bool:
    0: false
    255: true
seq:
- id: test__fixed_list_of_fixed_list_of_bool_entries
  type: test__fixed_list_of_fixed_list_of_bool_entries
  repeat: expr
  repeat-expr: 5
