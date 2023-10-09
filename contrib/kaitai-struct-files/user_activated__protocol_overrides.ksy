meta:
  id: user_activated__protocol_overrides
  endian: be
doc: ! 'User activated protocol overrides: activate a protocol instead of another.'
types:
  user_activated__protocol_overrides_entries:
    seq:
    - id: protocol_hash
      size: 32
    - id: protocol_hash
      size: 32
seq:
- id: len_user_activated__protocol_overrides
  type: s4
- id: user_activated__protocol_overrides
  type: user_activated__protocol_overrides_entries
  size: len_user_activated__protocol_overrides
  repeat: eos
