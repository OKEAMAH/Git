meta:
  id: protocol
  endian: be
doc: The environment a protocol relies on and the components a protocol is made of.
types:
  components:
    types:
      components:
        types:
          components_entries:
            types:
              implementation:
                seq:
                - id: len_implementation
                  type: s4
                - id: implementation
                  size: len_implementation
              interface:
                seq:
                - id: len_interface
                  type: s4
                - id: interface
                  size: len_interface
              name:
                seq:
                - id: len_name
                  type: s4
                - id: name
                  size: len_name
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
        seq:
        - id: components
          type: components_entries
          repeat: eos
    seq:
    - id: len_components
      type: s4
    - id: components
      type: components
      size: len_components
enums:
  bool:
    0: false
    255: true
seq:
- id: protocol__environment_version
  type: u2
- id: components
  type: components
