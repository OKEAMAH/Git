meta:
  id: protocol__meta
  endian: be
doc: ! >-
  Encoding id: protocol.meta

  Description: Protocol metadata: the hash of the protocol, the expected environment
  version and the list of modules comprising the protocol.
types:
  modules:
    seq:
    - id: len_modules_dyn
      type: u4
      valid:
        max: 1073741823
    - id: modules_dyn
      type: modules_dyn
      size: len_modules_dyn
  modules_dyn:
    seq:
    - id: modules_entries
      type: modules_entries
      repeat: eos
  modules_entries:
    seq:
    - id: modules_elt
      type: bytes_dyn_uint30
  bytes_dyn_uint30:
    seq:
    - id: len_bytes_dyn_uint30
      type: u4
      valid:
        max: 1073741823
    - id: bytes_dyn_uint30
      size: len_bytes_dyn_uint30
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
- id: hash_tag
  type: u1
  enum: bool
- id: hash
  size: 32
  if: (hash_tag == bool::true)
  doc: Used to force the hash of the protocol
- id: expected_env_version_tag
  type: u1
  enum: bool
- id: expected_env_version
  type: u2
  if: (expected_env_version_tag == bool::true)
- id: modules
  type: modules
  doc: Modules comprising the protocol
