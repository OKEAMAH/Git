meta:
  id: id_014__ptkathma__constants__fixed
  endian: be
doc: ! 'Encoding id: 014-PtKathma.constants.fixed'
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
- id: cache_layout_size
  type: u1
- id: michelson_maximum_type_size
  type: u2
- id: max_wrapped_proof_binary_size
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
