meta:
  id: id_012__psithaca__constants__fixed
  endian: be
doc: ! 'Encoding id: 012-Psithaca.constants.fixed'
types:
  cache_layout:
    seq:
    - id: size_of_cache_layout
      type: u4
      valid:
        max: 1073741823
    - id: cache_layout
      type: cache_layout_entries
      size: size_of_cache_layout
      repeat: eos
  cache_layout_entries:
    seq:
    - id: cache_layout_elt
      type: s8
seq:
- id: proof_of_work_nonce_size
  type: u1
- id: nonce_length
  type: u1
- id: max_anon_ops_per_block
  type: u1
- id: max_operation_data_length
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: max_proposals_per_delegate
  type: u1
- id: max_micheline_node_count
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: max_micheline_bytes_limit
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: max_allowed_global_constants_depth
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: cache_layout
  type: cache_layout
- id: michelson_maximum_type_size
  type: u2
