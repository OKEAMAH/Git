meta:
  id: user_activated__upgrades
  endian: be
doc: ! 'User activated upgrades: at given level, switch to given protocol.'
types:
  user_activated__upgrades_entries:
    seq:
    - id: level
      type: s4
    - id: protocol_hash
      size: 32
seq:
- id: len_user_activated__upgrades
  type: s4
- id: user_activated__upgrades
  type: user_activated__upgrades_entries
  size: len_user_activated__upgrades
  repeat: eos
