meta:
  id: block_locator
  endian: be
  imports:
  - block_header
doc: ! "Encoding id: block_locator\nDescription: A sparse block locator \xE0 la Bitcoin"
types:
  current_head:
    seq:
    - id: len_current_head_dyn
      type: u4
      valid:
        max: 1073741823
    - id: current_head_dyn
      type: current_head_dyn
      size: len_current_head_dyn
  current_head_dyn:
    seq:
    - id: current_head
      type: block_header
  history_entries:
    seq:
    - id: block_hash
      size: 32
seq:
- id: current_head
  type: current_head
- id: history
  type: history_entries
  repeat: eos
