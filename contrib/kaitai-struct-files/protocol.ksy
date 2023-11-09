meta:
  id: protocol
  endian: be
doc: ! >-
  Encoding id: protocol

  Description: The environment a protocol relies on and the components a protocol
  is made of.
types:
  bytes_dyn_uint30:
    seq:
    - id: len_bytes_dyn_uint30
      type: u4
      valid:
        max: 1073741823
    - id: bytes_dyn_uint30
      size: len_bytes_dyn_uint30
  components:
    seq:
    - id: len_components_dyn
      type: u4
      valid:
        max: 1073741823
    - id: components_dyn
      type: components_dyn
      size: len_components_dyn
  components_dyn:
    seq:
    - id: components_entries
      type: components_entries
      repeat: eos
  components_entries:
    seq:
    - id: name
      type: bytes_dyn_uint30
    - id: interface_tag
      type: u1
      enum: bool
    - id: interface
      type: bytes_dyn_uint30
      if: (interface_tag == bool::true)
    - id: implementation
      type: bytes_dyn_uint30
  uint30:
    seq:
    - id: uint30
      type: u4
      valid:
        max: 1073741823
enums:
  bool:
    0: false
    255: true
seq:
- id: expected_env_version
  type: u2
- id: components
  type: components
