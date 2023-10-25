meta:
  id: id_009__psfloren__constants__fixed
  endian: be
doc: ! 'Encoding id: 009-PsFLoren.constants.fixed'
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
