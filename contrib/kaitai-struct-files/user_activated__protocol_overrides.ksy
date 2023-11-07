meta:
  id: user_activated__protocol_overrides
  endian: be
doc: ! >-
  Encoding id: user_activated.protocol_overrides

  Description: User activated protocol overrides: activate a protocol instead of another.
types:
  user_activated__protocol_overrides_dyn:
    seq:
    - id: user_activated__protocol_overrides_entries
      type: user_activated__protocol_overrides_entries
      repeat: eos
  user_activated__protocol_overrides_entries:
    seq:
    - id: replaced_protocol
      size: 32
    - id: replacement_protocol
      size: 32
  uint30:
    seq:
    - id: uint30
      type: u4
      valid:
        max: 1073741823
seq:
- id: len_user_activated__protocol_overrides_dyn
  type: uint30
- id: user_activated__protocol_overrides_dyn
  type: user_activated__protocol_overrides_dyn
  size: len_user_activated__protocol_overrides_dyn
