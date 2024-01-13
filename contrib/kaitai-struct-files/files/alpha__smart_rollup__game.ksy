meta:
  id: alpha__smart_rollup__game
  endian: be
doc: ! 'Encoding id: alpha.smart_rollup.game'
types:
  agreed_start_chunk:
    seq:
    - id: state_tag
      type: u1
      enum: bool
    - id: state
      size: 32
      if: (state_tag == bool::true)
    - id: tick
      type: n
  back_pointers:
    seq:
    - id: back_pointers_entries
      type: back_pointers_entries
      repeat: eos
  back_pointers_0:
    seq:
    - id: len_back_pointers
      type: u4
      valid:
        max: 1073741823
    - id: back_pointers
      type: back_pointers
      size: len_back_pointers
  back_pointers_1:
    seq:
    - id: back_pointers_entries
      type: back_pointers_entries_0
      repeat: eos
  back_pointers_2:
    seq:
    - id: len_back_pointers
      type: u4
      valid:
        max: 1073741823
    - id: back_pointers
      type: back_pointers_1
      size: len_back_pointers
  back_pointers_entries:
    seq:
    - id: smart_rollup_inbox_hash
      size: 32
  back_pointers_entries_0:
    seq:
    - id: dal_skip_list_pointer
      size: 32
  content:
    seq:
    - id: hash
      size: 32
    - id: level
      type: s4
  content_0:
    seq:
    - id: published_level
      type: s4
    - id: slot_headers
      type: slot_headers_0
  dal_snapshot:
    seq:
    - id: dal_snapshot_tag
      type: u1
      enum: dal_snapshot_tag
    - id: legacy
      size: 57
      if: (dal_snapshot_tag == dal_snapshot_tag::legacy)
    - id: new
      type: new
      if: (dal_snapshot_tag == dal_snapshot_tag::new)
  dissecting:
    seq:
    - id: dissection
      type: dissection_0
    - id: default_number_of_sections
      type: u1
  dissection:
    seq:
    - id: dissection_entries
      type: dissection_entries
      repeat: eos
  dissection_0:
    seq:
    - id: len_dissection
      type: u4
      valid:
        max: 1073741823
    - id: dissection
      type: dissection
      size: len_dissection
  dissection_entries:
    seq:
    - id: state_tag
      type: u1
      enum: bool
    - id: state
      size: 32
      if: (state_tag == bool::true)
    - id: tick
      type: n
  final_move:
    seq:
    - id: agreed_start_chunk
      type: agreed_start_chunk
    - id: refuted_stop_chunk
      type: refuted_stop_chunk
  game_state:
    seq:
    - id: game_state_tag
      type: u1
      enum: game_state_tag
    - id: dissecting
      type: dissecting
      if: (game_state_tag == game_state_tag::dissecting)
    - id: final_move
      type: final_move
      if: (game_state_tag == game_state_tag::final_move)
  inbox_snapshot:
    seq:
    - id: index
      type: n
    - id: content
      type: content
    - id: back_pointers
      type: back_pointers_0
  n:
    seq:
    - id: n
      type: n_chunk
      repeat: until
      repeat-until: not (_.has_more).as<bool>
  n_chunk:
    seq:
    - id: has_more
      type: b1be
    - id: payload
      type: b7be
  new:
    seq:
    - id: index
      type: n
    - id: content
      type: content_0
    - id: back_pointers
      type: back_pointers_2
  refuted_stop_chunk:
    seq:
    - id: state_tag
      type: u1
      enum: bool
    - id: state
      size: 32
      if: (state_tag == bool::true)
    - id: tick
      type: n
  slot_headers:
    seq:
    - id: slot_headers_entries
      type: slot_headers_entries
      repeat: eos
  slot_headers_0:
    seq:
    - id: len_slot_headers
      type: u4
      valid:
        max: 1073741823
    - id: slot_headers
      type: slot_headers
      size: len_slot_headers
  slot_headers_entries:
    seq:
    - id: slot_commitment
      size: 48
    - id: slot_index
      type: u1
enums:
  bool:
    0: false
    255: true
  dal_snapshot_tag:
    0: legacy
    1: new
  game_state_tag:
    0: dissecting
    1: final_move
  turn_tag:
    0: alice
    1: bob
seq:
- id: turn
  type: u1
  enum: turn_tag
- id: inbox_snapshot
  type: inbox_snapshot
- id: dal_snapshot
  type: dal_snapshot
- id: start_level
  type: s4
- id: inbox_level
  type: s4
- id: game_state
  type: game_state
