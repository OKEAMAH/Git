meta:
  id: protocol
  endian: be
doc: ! >-
  Encoding id: protocol

  Description: The environment a protocol relies on and the components a protocol
  is made of.
types:
  components:
    seq:
    - id: size_of_components
      type: u4
      valid:
        max: 1073741823
    - id: components
      type: components_entries
      size: size_of_components
      repeat: eos
  components_entries:
    seq:
    - id: name
      type: name
    - id: interface_tag
      type: u1
      enum: bool
    - id: interface
      type: interface
      if: (interface_tag == bool::true)
    - id: implementation
      type: implementation
  implementation:
    seq:
    - id: size_of_implementation
      type: u4
      valid:
        max: 1073741823
    - id: implementation
      size: size_of_implementation
  interface:
    seq:
    - id: size_of_interface
      type: u4
      valid:
        max: 1073741823
    - id: interface
      size: size_of_interface
  name:
    seq:
    - id: size_of_name
      type: u4
      valid:
        max: 1073741823
    - id: name
      size: size_of_name
enums:
  bool:
    0: false
    255: true
seq:
- id: expected_env_version
  type: u2
- id: components
  type: components
