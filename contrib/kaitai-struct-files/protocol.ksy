meta:
  id: protocol
  endian: be
doc: The environment a protocol relies on and the components a protocol is made of.
types:
  components:
    seq:
    - id: size_of_components
      type: s4
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
      type: s4
    - id: implementation
      size: size_of_implementation
  interface:
    seq:
    - id: size_of_interface
      type: s4
    - id: interface
      size: size_of_interface
  name:
    seq:
    - id: size_of_name
      type: s4
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
