meta:
  id: user_activated__upgrades
  endian: be
doc: ! >-
  Encoding id: user_activated.upgrades

  Description: User activated upgrades: at given level, switch to given protocol.
types:
  user_activated__upgrades_dyn:
    seq:
    - id: user_activated__upgrades_entries
      type: user_activated__upgrades_entries
      repeat: eos
  user_activated__upgrades_entries:
    seq:
    - id: level
      type: s4
    - id: replacement_protocol
      size: 32
  uint30:
    seq:
    - id: uint30
      type: u4
      valid:
        max: 1073741823
seq:
- id: len_user_activated__upgrades_dyn
  type: uint30
- id: user_activated__upgrades_dyn
  type: user_activated__upgrades_dyn
  size: len_user_activated__upgrades_dyn
