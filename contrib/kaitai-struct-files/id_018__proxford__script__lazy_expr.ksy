meta:
  id: id_018__proxford__script__lazy_expr
  endian: be
doc: ! 'Encoding id: 018-Proxford.script.lazy_expr'
types:
  bytes_dyn_uint30:
    seq:
    - id: len_bytes_dyn_uint30
      type: uint30
    - id: bytes_dyn_uint30
      size: len_bytes_dyn_uint30
  uint30:
    seq:
    - id: uint30
      type: u4
      valid:
        max: 1073741823
seq:
- id: id_018__proxford__script__lazy_expr
  type: bytes_dyn_uint30
