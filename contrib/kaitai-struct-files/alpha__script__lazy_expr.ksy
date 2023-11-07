meta:
  id: alpha__script__lazy_expr
  endian: be
doc: ! 'Encoding id: alpha.script.lazy_expr'
types:
  uint30:
    seq:
    - id: uint30
      type: u4
      valid:
        max: 1073741823
seq:
- id: len_alpha__script__lazy_expr
  type: uint30
- id: alpha__script__lazy_expr
  size: len_alpha__script__lazy_expr
