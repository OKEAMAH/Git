meta:
  id: protocol__meta
  endian: be
doc: ! >-
  Protocol metadata: the hash of the protocol, the expected environment version and
  the list of modules comprising the protocol.
types:
  modules:
    doc: Modules comprising the protocol
    types:
      modules:
        types:
          modules_entries:
            seq:
            - id: len_modules
              type: s4
            - id: modules
              size: len_modules
        seq:
        - id: modules
          type: modules_entries
          repeat: eos
    seq:
    - id: len_modules
      type: s4
    - id: modules
      type: modules
      size: len_modules
enums:
  bool:
    0: false
    255: true
seq:
- id: hash_tag
  type: u1
  enum: bool
- id: protocol_hash
  size: 32
  if: (hash_tag == bool::true)
  doc: Used to force the hash of the protocol
- id: expected_env_version_tag
  type: u1
  enum: bool
- id: protocol__environment_version
  type: u2
  if: (expected_env_version_tag == bool::true)
- id: modules
  type: modules
