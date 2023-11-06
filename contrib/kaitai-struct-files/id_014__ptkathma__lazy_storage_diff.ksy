meta:
  id: id_014__ptkathma__lazy_storage_diff
  endian: be
doc: ! 'Encoding id: 014-PtKathma.lazy_storage_diff'
types:
  id_014__ptkathma__lazy_storage_diff_entries:
    seq:
    - id: id_014__ptkathma__lazy_storage_diff_elt_tag
      type: u1
      enum: id_014__ptkathma__lazy_storage_diff_elt_tag
    - id: big_map__id_014__ptkathma__lazy_storage_diff_elt
      type: big_map__id_014__ptkathma__lazy_storage_diff_elt
      if: (id_014__ptkathma__lazy_storage_diff_elt_tag == id_014__ptkathma__lazy_storage_diff_elt_tag::big_map)
    - id: sapling_state__id_014__ptkathma__lazy_storage_diff_elt
      type: sapling_state__id_014__ptkathma__lazy_storage_diff_elt
      if: (id_014__ptkathma__lazy_storage_diff_elt_tag == id_014__ptkathma__lazy_storage_diff_elt_tag::sapling_state)
  sapling_state__id_014__ptkathma__lazy_storage_diff_elt:
    seq:
    - id: id
      type: z
      doc: ! 'Sapling state identifier: A sapling state identifier'
    - id: sapling_state__diff
      type: sapling_state__diff
  sapling_state__diff:
    seq:
    - id: diff_tag
      type: u1
      enum: diff_tag
    - id: sapling_state__update__diff
      type: sapling_state__update__updates
      if: (diff_tag == diff_tag::update)
    - id: sapling_state__copy__diff
      type: sapling_state__copy__diff
      if: (diff_tag == diff_tag::copy)
    - id: sapling_state__alloc__diff
      type: sapling_state__alloc__diff
      if: (diff_tag == diff_tag::alloc)
  sapling_state__alloc__diff:
    seq:
    - id: sapling_state__alloc__updates
      type: sapling_state__alloc__updates
    - id: memo_size
      type: u2
  sapling_state__alloc__updates:
    seq:
    - id: sapling_state__alloc__commitments_and_ciphertexts
      type: sapling_state__alloc__commitments_and_ciphertexts
    - id: sapling_state__alloc__nullifiers
      type: sapling_state__alloc__nullifiers
  sapling_state__alloc__nullifiers:
    seq:
    - id: len_nullifiers
      type: u4
      valid:
        max: 1073741823
    - id: nullifiers
      type: sapling_state__alloc__nullifiers_entries
      size: len_nullifiers
      repeat: eos
  sapling_state__alloc__nullifiers_entries:
    seq:
    - id: sapling__transaction__nullifier
      size: 32
  sapling_state__alloc__commitments_and_ciphertexts:
    seq:
    - id: len_commitments_and_ciphertexts
      type: u4
      valid:
        max: 1073741823
    - id: commitments_and_ciphertexts
      type: sapling_state__alloc__commitments_and_ciphertexts_entries
      size: len_commitments_and_ciphertexts
      repeat: eos
  sapling_state__alloc__commitments_and_ciphertexts_entries:
    seq:
    - id: commitments_and_ciphertexts_elt_field0
      size: 32
      doc: sapling__transaction__commitment
    - id: commitments_and_ciphertexts_elt_field1
      type: sapling_state__alloc__sapling__transaction__ciphertext
      doc: sapling_state__alloc__sapling__transaction__ciphertext
  sapling_state__alloc__sapling__transaction__ciphertext:
    seq:
    - id: cv
      size: 32
    - id: epk
      size: 32
    - id: sapling_state__alloc__payload_enc
      type: sapling_state__alloc__payload_enc
    - id: nonce_enc
      size: 24
    - id: payload_out
      size: 80
    - id: nonce_out
      size: 24
  sapling_state__alloc__payload_enc:
    seq:
    - id: len_payload_enc
      type: u4
      valid:
        max: 1073741823
    - id: payload_enc
      size: len_payload_enc
  sapling_state__copy__diff:
    seq:
    - id: source
      type: z
      doc: ! 'Sapling state identifier: A sapling state identifier'
    - id: sapling_state__copy__updates
      type: sapling_state__copy__updates
  sapling_state__copy__updates:
    seq:
    - id: sapling_state__copy__commitments_and_ciphertexts
      type: sapling_state__copy__commitments_and_ciphertexts
    - id: sapling_state__copy__nullifiers
      type: sapling_state__copy__nullifiers
  sapling_state__copy__nullifiers:
    seq:
    - id: len_nullifiers
      type: u4
      valid:
        max: 1073741823
    - id: nullifiers
      type: sapling_state__copy__nullifiers_entries
      size: len_nullifiers
      repeat: eos
  sapling_state__copy__nullifiers_entries:
    seq:
    - id: sapling__transaction__nullifier
      size: 32
  sapling_state__copy__commitments_and_ciphertexts:
    seq:
    - id: len_commitments_and_ciphertexts
      type: u4
      valid:
        max: 1073741823
    - id: commitments_and_ciphertexts
      type: sapling_state__copy__commitments_and_ciphertexts_entries
      size: len_commitments_and_ciphertexts
      repeat: eos
  sapling_state__copy__commitments_and_ciphertexts_entries:
    seq:
    - id: commitments_and_ciphertexts_elt_field0
      size: 32
      doc: sapling__transaction__commitment
    - id: commitments_and_ciphertexts_elt_field1
      type: sapling_state__copy__sapling__transaction__ciphertext
      doc: sapling_state__copy__sapling__transaction__ciphertext
  sapling_state__copy__sapling__transaction__ciphertext:
    seq:
    - id: cv
      size: 32
    - id: epk
      size: 32
    - id: sapling_state__copy__payload_enc
      type: sapling_state__copy__payload_enc
    - id: nonce_enc
      size: 24
    - id: payload_out
      size: 80
    - id: nonce_out
      size: 24
  sapling_state__copy__payload_enc:
    seq:
    - id: len_payload_enc
      type: u4
      valid:
        max: 1073741823
    - id: payload_enc
      size: len_payload_enc
  sapling_state__update__updates:
    seq:
    - id: sapling_state__update__commitments_and_ciphertexts
      type: sapling_state__update__commitments_and_ciphertexts
    - id: sapling_state__update__nullifiers
      type: sapling_state__update__nullifiers
  sapling_state__update__nullifiers:
    seq:
    - id: len_nullifiers
      type: u4
      valid:
        max: 1073741823
    - id: nullifiers
      type: sapling_state__update__nullifiers_entries
      size: len_nullifiers
      repeat: eos
  sapling_state__update__nullifiers_entries:
    seq:
    - id: sapling__transaction__nullifier
      size: 32
  sapling_state__update__commitments_and_ciphertexts:
    seq:
    - id: len_commitments_and_ciphertexts
      type: u4
      valid:
        max: 1073741823
    - id: commitments_and_ciphertexts
      type: sapling_state__update__commitments_and_ciphertexts_entries
      size: len_commitments_and_ciphertexts
      repeat: eos
  sapling_state__update__commitments_and_ciphertexts_entries:
    seq:
    - id: commitments_and_ciphertexts_elt_field0
      size: 32
      doc: sapling__transaction__commitment
    - id: commitments_and_ciphertexts_elt_field1
      type: sapling_state__update__sapling__transaction__ciphertext
      doc: sapling_state__update__sapling__transaction__ciphertext
  sapling_state__update__sapling__transaction__ciphertext:
    seq:
    - id: cv
      size: 32
    - id: epk
      size: 32
    - id: sapling_state__update__payload_enc
      type: sapling_state__update__payload_enc
    - id: nonce_enc
      size: 24
    - id: payload_out
      size: 80
    - id: nonce_out
      size: 24
  sapling_state__update__payload_enc:
    seq:
    - id: len_payload_enc
      type: u4
      valid:
        max: 1073741823
    - id: payload_enc
      size: len_payload_enc
  big_map__id_014__ptkathma__lazy_storage_diff_elt:
    seq:
    - id: id
      type: z
      doc: ! 'Big map identifier: A big map identifier'
    - id: big_map__diff
      type: big_map__diff
  big_map__diff:
    seq:
    - id: diff_tag
      type: u1
      enum: diff_tag
    - id: big_map__update__diff
      type: big_map__update__updates
      if: (diff_tag == diff_tag::update)
    - id: big_map__copy__diff
      type: big_map__copy__diff
      if: (diff_tag == diff_tag::copy)
    - id: big_map__alloc__diff
      type: big_map__alloc__diff
      if: (diff_tag == diff_tag::alloc)
  big_map__alloc__diff:
    seq:
    - id: big_map__alloc__updates
      type: big_map__alloc__updates
    - id: key_type
      type: micheline__014__ptkathma__michelson_v1__expression
    - id: value_type
      type: micheline__014__ptkathma__michelson_v1__expression
  big_map__alloc__updates:
    seq:
    - id: len_updates
      type: u4
      valid:
        max: 1073741823
    - id: updates
      type: big_map__alloc__updates_entries
      size: len_updates
      repeat: eos
  big_map__alloc__updates_entries:
    seq:
    - id: key_hash
      size: 32
    - id: key
      type: micheline__014__ptkathma__michelson_v1__expression
    - id: value_tag
      type: u1
      enum: bool
    - id: value
      type: micheline__014__ptkathma__michelson_v1__expression
      if: (value_tag == bool::true)
  big_map__copy__diff:
    seq:
    - id: source
      type: z
      doc: ! 'Big map identifier: A big map identifier'
    - id: big_map__copy__updates
      type: big_map__copy__updates
  big_map__copy__updates:
    seq:
    - id: len_updates
      type: u4
      valid:
        max: 1073741823
    - id: updates
      type: big_map__copy__updates_entries
      size: len_updates
      repeat: eos
  big_map__copy__updates_entries:
    seq:
    - id: key_hash
      size: 32
    - id: key
      type: micheline__014__ptkathma__michelson_v1__expression
    - id: value_tag
      type: u1
      enum: bool
    - id: value
      type: micheline__014__ptkathma__michelson_v1__expression
      if: (value_tag == bool::true)
  big_map__update__updates:
    seq:
    - id: len_updates
      type: u4
      valid:
        max: 1073741823
    - id: updates
      type: big_map__update__updates_entries
      size: len_updates
      repeat: eos
  big_map__update__updates_entries:
    seq:
    - id: key_hash
      size: 32
    - id: key
      type: big_map__update__micheline__014__ptkathma__michelson_v1__expression
    - id: value_tag
      type: u1
      enum: bool
    - id: value
      type: micheline__014__ptkathma__michelson_v1__expression
      if: (value_tag == bool::true)
  big_map__update__micheline__014__ptkathma__michelson_v1__expression:
    seq:
    - id: micheline__014__ptkathma__michelson_v1__expression_tag
      type: u1
      enum: micheline__014__ptkathma__michelson_v1__expression_tag
    - id: big_map__update__int__micheline__014__ptkathma__michelson_v1__expression
      type: z
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::int)
    - id: big_map__update__string__micheline__014__ptkathma__michelson_v1__expression
      type: big_map__update__string__string
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::string)
    - id: big_map__update__sequence__micheline__014__ptkathma__michelson_v1__expression
      type: big_map__update__sequence__micheline__014__ptkathma__michelson_v1__expression
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::sequence)
    - id: big_map__update__prim__no_args__no_annots__micheline__014__ptkathma__michelson_v1__expression
      type: u1
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::prim__no_args__no_annots)
      enum: big_map__update__prim__no_args__no_annots__id_014__ptkathma__michelson__v1__primitives
    - id: big_map__update__prim__no_args__some_annots__micheline__014__ptkathma__michelson_v1__expression
      type: big_map__update__prim__no_args__some_annots__micheline__014__ptkathma__michelson_v1__expression
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::prim__no_args__some_annots)
    - id: big_map__update__prim__1_arg__no_annots__micheline__014__ptkathma__michelson_v1__expression
      type: big_map__update__prim__1_arg__no_annots__micheline__014__ptkathma__michelson_v1__expression
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::prim__1_arg__no_annots)
    - id: big_map__update__prim__1_arg__some_annots__micheline__014__ptkathma__michelson_v1__expression
      type: big_map__update__prim__1_arg__some_annots__micheline__014__ptkathma__michelson_v1__expression
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::prim__1_arg__some_annots)
    - id: big_map__update__prim__2_args__no_annots__micheline__014__ptkathma__michelson_v1__expression
      type: big_map__update__prim__2_args__no_annots__micheline__014__ptkathma__michelson_v1__expression
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::prim__2_args__no_annots)
    - id: big_map__update__prim__2_args__some_annots__micheline__014__ptkathma__michelson_v1__expression
      type: big_map__update__prim__2_args__some_annots__micheline__014__ptkathma__michelson_v1__expression
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::prim__2_args__some_annots)
    - id: big_map__update__prim__generic__micheline__014__ptkathma__michelson_v1__expression
      type: big_map__update__prim__generic__micheline__014__ptkathma__michelson_v1__expression
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::prim__generic)
    - id: big_map__update__bytes__micheline__014__ptkathma__michelson_v1__expression
      type: big_map__update__bytes__bytes
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::bytes)
  big_map__update__bytes__bytes:
    seq:
    - id: len_bytes
      type: u4
      valid:
        max: 1073741823
    - id: bytes
      size: len_bytes
  big_map__update__prim__generic__micheline__014__ptkathma__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: big_map__update__prim__generic__id_014__ptkathma__michelson__v1__primitives
    - id: big_map__update__prim__generic__args
      type: big_map__update__prim__generic__args
    - id: big_map__update__prim__generic__annots
      type: big_map__update__prim__generic__annots
  big_map__update__prim__generic__annots:
    seq:
    - id: len_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: len_annots
  big_map__update__prim__generic__args:
    seq:
    - id: len_args
      type: u4
      valid:
        max: 1073741823
    - id: args
      type: big_map__update__prim__generic__args_entries
      size: len_args
      repeat: eos
  big_map__update__prim__generic__args_entries:
    seq:
    - id: args_elt
      type: micheline__014__ptkathma__michelson_v1__expression
  big_map__update__prim__2_args__some_annots__micheline__014__ptkathma__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: big_map__update__prim__2_args__some_annots__id_014__ptkathma__michelson__v1__primitives
    - id: arg1
      type: micheline__014__ptkathma__michelson_v1__expression
    - id: arg2
      type: micheline__014__ptkathma__michelson_v1__expression
    - id: big_map__update__prim__2_args__some_annots__annots
      type: big_map__update__prim__2_args__some_annots__annots
  big_map__update__prim__2_args__some_annots__annots:
    seq:
    - id: len_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: len_annots
  big_map__update__prim__2_args__no_annots__micheline__014__ptkathma__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: big_map__update__prim__2_args__no_annots__id_014__ptkathma__michelson__v1__primitives
    - id: arg1
      type: micheline__014__ptkathma__michelson_v1__expression
    - id: arg2
      type: micheline__014__ptkathma__michelson_v1__expression
  big_map__update__prim__1_arg__some_annots__micheline__014__ptkathma__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: big_map__update__prim__1_arg__some_annots__id_014__ptkathma__michelson__v1__primitives
    - id: arg
      type: micheline__014__ptkathma__michelson_v1__expression
    - id: big_map__update__prim__1_arg__some_annots__annots
      type: big_map__update__prim__1_arg__some_annots__annots
  big_map__update__prim__1_arg__some_annots__annots:
    seq:
    - id: len_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: len_annots
  big_map__update__prim__1_arg__no_annots__micheline__014__ptkathma__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: big_map__update__prim__1_arg__no_annots__id_014__ptkathma__michelson__v1__primitives
    - id: arg
      type: micheline__014__ptkathma__michelson_v1__expression
  big_map__update__prim__no_args__some_annots__micheline__014__ptkathma__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: big_map__update__prim__no_args__some_annots__id_014__ptkathma__michelson__v1__primitives
    - id: big_map__update__prim__no_args__some_annots__annots
      type: big_map__update__prim__no_args__some_annots__annots
  big_map__update__prim__no_args__some_annots__annots:
    seq:
    - id: len_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: len_annots
  big_map__update__sequence__micheline__014__ptkathma__michelson_v1__expression:
    seq:
    - id: len_sequence
      type: u4
      valid:
        max: 1073741823
    - id: sequence
      type: big_map__update__sequence__sequence_entries
      size: len_sequence
      repeat: eos
  big_map__update__sequence__sequence_entries:
    seq:
    - id: sequence_elt
      type: micheline__014__ptkathma__michelson_v1__expression
  big_map__update__string__string:
    seq:
    - id: len_string
      type: u4
      valid:
        max: 1073741823
    - id: string
      size: len_string
  z:
    seq:
    - id: has_tail
      type: b1be
    - id: sign
      type: b1be
    - id: payload
      type: b6be
    - id: tail
      type: n_chunk
      repeat: until
      repeat-until: not (_.has_more).as<bool>
      if: has_tail.as<bool>
  n_chunk:
    seq:
    - id: has_more
      type: b1be
    - id: payload
      type: b7be
enums:
  bool:
    0: false
    255: true
  big_map__update__prim__generic__id_014__ptkathma__michelson__v1__primitives:
    2: code
    115: apply
    75: sub
    27: cons
    33: dup
    119: self_address
    59: neg
    41: get
    38: exec
    143: open_chest
    142: chest_key
    83: loop_left
    37: eq
    34: ediv
    139: join_tickets
    87: cast
    85: contract
    79: unit
    140: get_and_update
    65: or
    47: if_none
    64: now
    148: tx_rollup_l2_address
    130: bls12_381_fr
    42: gt
    122: unpair
    95: list
    137: read_ticket
    66: pair
    118: level
    138: split_ticket
    110: address
    114: empty_big_map
    54: lsr
    146: constant
    151: emit
    5: left
    52: loop
    127: pairing_check
    104: string
    49: lambda
    60: neq
    36: empty_set
    78: set_delegate
    129: bls12_381_g2
    124: total_voting_power
    45: if_cons
    12: pack
    8: right
    10: true
    86: isnat
    51: left
    67: push
    126: sha3
    82: iter
    23: cdr
    106: mutez
    63: not
    22: car
    100: or
    72: sender
    90: contract
    69: size
    40: ge
    84: address
    62: none
    133: sapling_empty_state
    11: unit
    29: create_contract
    70: some
    50: le
    77: transfer_tokens
    105: bytes
    73: self
    136: ticket
    13: unpack
    123: voting_power
    55: lt
    28: create_account
    46: if_left
    43: hash_key
    117: chain_id
    102: set
    125: keccak
    101: pair
    19: amount
    98: nat
    76: swap
    6: none
    35: empty_map
    108: unit
    0: parameter
    9: some
    80: update
    91: int
    81: xor
    57: mem
    31: dip
    149: min_block_time
    92: key
    4: elt
    39: failwith
    58: mul
    135: ticket
    26: concat
    21: balance
    99: option
    32: drop
    111: slice
    147: sub_mutez
    25: compare
    109: operation
    131: sapling_state
    120: never
    141: chest
    53: lsl
    89: bool
    16: sha512
    30: implicit_account
    18: add
    116: chain_id
    97: big_map
    56: map
    107: timestamp
    121: never
    24: check_signature
    88: rename
    74: steps_to_quota
    94: lambda
    61: nil
    103: signature
    144: view
    20: and
    15: sha256
    145: view
    68: right
    1: storage
    150: sapling_transaction
    96: map
    48: int
    7: pair
    132: sapling_transaction_deprecated
    93: key_hash
    14: blake2b
    128: bls12_381_g1
    134: sapling_verify_update
    112: dig
    3: false
    113: dug
    71: source
    44: if
    17: abs
  big_map__update__prim__2_args__some_annots__id_014__ptkathma__michelson__v1__primitives:
    2: code
    115: apply
    75: sub
    27: cons
    33: dup
    119: self_address
    59: neg
    41: get
    38: exec
    143: open_chest
    142: chest_key
    83: loop_left
    37: eq
    34: ediv
    139: join_tickets
    87: cast
    85: contract
    79: unit
    140: get_and_update
    65: or
    47: if_none
    64: now
    148: tx_rollup_l2_address
    130: bls12_381_fr
    42: gt
    122: unpair
    95: list
    137: read_ticket
    66: pair
    118: level
    138: split_ticket
    110: address
    114: empty_big_map
    54: lsr
    146: constant
    151: emit
    5: left
    52: loop
    127: pairing_check
    104: string
    49: lambda
    60: neq
    36: empty_set
    78: set_delegate
    129: bls12_381_g2
    124: total_voting_power
    45: if_cons
    12: pack
    8: right
    10: true
    86: isnat
    51: left
    67: push
    126: sha3
    82: iter
    23: cdr
    106: mutez
    63: not
    22: car
    100: or
    72: sender
    90: contract
    69: size
    40: ge
    84: address
    62: none
    133: sapling_empty_state
    11: unit
    29: create_contract
    70: some
    50: le
    77: transfer_tokens
    105: bytes
    73: self
    136: ticket
    13: unpack
    123: voting_power
    55: lt
    28: create_account
    46: if_left
    43: hash_key
    117: chain_id
    102: set
    125: keccak
    101: pair
    19: amount
    98: nat
    76: swap
    6: none
    35: empty_map
    108: unit
    0: parameter
    9: some
    80: update
    91: int
    81: xor
    57: mem
    31: dip
    149: min_block_time
    92: key
    4: elt
    39: failwith
    58: mul
    135: ticket
    26: concat
    21: balance
    99: option
    32: drop
    111: slice
    147: sub_mutez
    25: compare
    109: operation
    131: sapling_state
    120: never
    141: chest
    53: lsl
    89: bool
    16: sha512
    30: implicit_account
    18: add
    116: chain_id
    97: big_map
    56: map
    107: timestamp
    121: never
    24: check_signature
    88: rename
    74: steps_to_quota
    94: lambda
    61: nil
    103: signature
    144: view
    20: and
    15: sha256
    145: view
    68: right
    1: storage
    150: sapling_transaction
    96: map
    48: int
    7: pair
    132: sapling_transaction_deprecated
    93: key_hash
    14: blake2b
    128: bls12_381_g1
    134: sapling_verify_update
    112: dig
    3: false
    113: dug
    71: source
    44: if
    17: abs
  big_map__update__prim__2_args__no_annots__id_014__ptkathma__michelson__v1__primitives:
    2: code
    115: apply
    75: sub
    27: cons
    33: dup
    119: self_address
    59: neg
    41: get
    38: exec
    143: open_chest
    142: chest_key
    83: loop_left
    37: eq
    34: ediv
    139: join_tickets
    87: cast
    85: contract
    79: unit
    140: get_and_update
    65: or
    47: if_none
    64: now
    148: tx_rollup_l2_address
    130: bls12_381_fr
    42: gt
    122: unpair
    95: list
    137: read_ticket
    66: pair
    118: level
    138: split_ticket
    110: address
    114: empty_big_map
    54: lsr
    146: constant
    151: emit
    5: left
    52: loop
    127: pairing_check
    104: string
    49: lambda
    60: neq
    36: empty_set
    78: set_delegate
    129: bls12_381_g2
    124: total_voting_power
    45: if_cons
    12: pack
    8: right
    10: true
    86: isnat
    51: left
    67: push
    126: sha3
    82: iter
    23: cdr
    106: mutez
    63: not
    22: car
    100: or
    72: sender
    90: contract
    69: size
    40: ge
    84: address
    62: none
    133: sapling_empty_state
    11: unit
    29: create_contract
    70: some
    50: le
    77: transfer_tokens
    105: bytes
    73: self
    136: ticket
    13: unpack
    123: voting_power
    55: lt
    28: create_account
    46: if_left
    43: hash_key
    117: chain_id
    102: set
    125: keccak
    101: pair
    19: amount
    98: nat
    76: swap
    6: none
    35: empty_map
    108: unit
    0: parameter
    9: some
    80: update
    91: int
    81: xor
    57: mem
    31: dip
    149: min_block_time
    92: key
    4: elt
    39: failwith
    58: mul
    135: ticket
    26: concat
    21: balance
    99: option
    32: drop
    111: slice
    147: sub_mutez
    25: compare
    109: operation
    131: sapling_state
    120: never
    141: chest
    53: lsl
    89: bool
    16: sha512
    30: implicit_account
    18: add
    116: chain_id
    97: big_map
    56: map
    107: timestamp
    121: never
    24: check_signature
    88: rename
    74: steps_to_quota
    94: lambda
    61: nil
    103: signature
    144: view
    20: and
    15: sha256
    145: view
    68: right
    1: storage
    150: sapling_transaction
    96: map
    48: int
    7: pair
    132: sapling_transaction_deprecated
    93: key_hash
    14: blake2b
    128: bls12_381_g1
    134: sapling_verify_update
    112: dig
    3: false
    113: dug
    71: source
    44: if
    17: abs
  big_map__update__prim__1_arg__some_annots__id_014__ptkathma__michelson__v1__primitives:
    2: code
    115: apply
    75: sub
    27: cons
    33: dup
    119: self_address
    59: neg
    41: get
    38: exec
    143: open_chest
    142: chest_key
    83: loop_left
    37: eq
    34: ediv
    139: join_tickets
    87: cast
    85: contract
    79: unit
    140: get_and_update
    65: or
    47: if_none
    64: now
    148: tx_rollup_l2_address
    130: bls12_381_fr
    42: gt
    122: unpair
    95: list
    137: read_ticket
    66: pair
    118: level
    138: split_ticket
    110: address
    114: empty_big_map
    54: lsr
    146: constant
    151: emit
    5: left
    52: loop
    127: pairing_check
    104: string
    49: lambda
    60: neq
    36: empty_set
    78: set_delegate
    129: bls12_381_g2
    124: total_voting_power
    45: if_cons
    12: pack
    8: right
    10: true
    86: isnat
    51: left
    67: push
    126: sha3
    82: iter
    23: cdr
    106: mutez
    63: not
    22: car
    100: or
    72: sender
    90: contract
    69: size
    40: ge
    84: address
    62: none
    133: sapling_empty_state
    11: unit
    29: create_contract
    70: some
    50: le
    77: transfer_tokens
    105: bytes
    73: self
    136: ticket
    13: unpack
    123: voting_power
    55: lt
    28: create_account
    46: if_left
    43: hash_key
    117: chain_id
    102: set
    125: keccak
    101: pair
    19: amount
    98: nat
    76: swap
    6: none
    35: empty_map
    108: unit
    0: parameter
    9: some
    80: update
    91: int
    81: xor
    57: mem
    31: dip
    149: min_block_time
    92: key
    4: elt
    39: failwith
    58: mul
    135: ticket
    26: concat
    21: balance
    99: option
    32: drop
    111: slice
    147: sub_mutez
    25: compare
    109: operation
    131: sapling_state
    120: never
    141: chest
    53: lsl
    89: bool
    16: sha512
    30: implicit_account
    18: add
    116: chain_id
    97: big_map
    56: map
    107: timestamp
    121: never
    24: check_signature
    88: rename
    74: steps_to_quota
    94: lambda
    61: nil
    103: signature
    144: view
    20: and
    15: sha256
    145: view
    68: right
    1: storage
    150: sapling_transaction
    96: map
    48: int
    7: pair
    132: sapling_transaction_deprecated
    93: key_hash
    14: blake2b
    128: bls12_381_g1
    134: sapling_verify_update
    112: dig
    3: false
    113: dug
    71: source
    44: if
    17: abs
  big_map__update__prim__1_arg__no_annots__id_014__ptkathma__michelson__v1__primitives:
    2: code
    115: apply
    75: sub
    27: cons
    33: dup
    119: self_address
    59: neg
    41: get
    38: exec
    143: open_chest
    142: chest_key
    83: loop_left
    37: eq
    34: ediv
    139: join_tickets
    87: cast
    85: contract
    79: unit
    140: get_and_update
    65: or
    47: if_none
    64: now
    148: tx_rollup_l2_address
    130: bls12_381_fr
    42: gt
    122: unpair
    95: list
    137: read_ticket
    66: pair
    118: level
    138: split_ticket
    110: address
    114: empty_big_map
    54: lsr
    146: constant
    151: emit
    5: left
    52: loop
    127: pairing_check
    104: string
    49: lambda
    60: neq
    36: empty_set
    78: set_delegate
    129: bls12_381_g2
    124: total_voting_power
    45: if_cons
    12: pack
    8: right
    10: true
    86: isnat
    51: left
    67: push
    126: sha3
    82: iter
    23: cdr
    106: mutez
    63: not
    22: car
    100: or
    72: sender
    90: contract
    69: size
    40: ge
    84: address
    62: none
    133: sapling_empty_state
    11: unit
    29: create_contract
    70: some
    50: le
    77: transfer_tokens
    105: bytes
    73: self
    136: ticket
    13: unpack
    123: voting_power
    55: lt
    28: create_account
    46: if_left
    43: hash_key
    117: chain_id
    102: set
    125: keccak
    101: pair
    19: amount
    98: nat
    76: swap
    6: none
    35: empty_map
    108: unit
    0: parameter
    9: some
    80: update
    91: int
    81: xor
    57: mem
    31: dip
    149: min_block_time
    92: key
    4: elt
    39: failwith
    58: mul
    135: ticket
    26: concat
    21: balance
    99: option
    32: drop
    111: slice
    147: sub_mutez
    25: compare
    109: operation
    131: sapling_state
    120: never
    141: chest
    53: lsl
    89: bool
    16: sha512
    30: implicit_account
    18: add
    116: chain_id
    97: big_map
    56: map
    107: timestamp
    121: never
    24: check_signature
    88: rename
    74: steps_to_quota
    94: lambda
    61: nil
    103: signature
    144: view
    20: and
    15: sha256
    145: view
    68: right
    1: storage
    150: sapling_transaction
    96: map
    48: int
    7: pair
    132: sapling_transaction_deprecated
    93: key_hash
    14: blake2b
    128: bls12_381_g1
    134: sapling_verify_update
    112: dig
    3: false
    113: dug
    71: source
    44: if
    17: abs
  big_map__update__prim__no_args__some_annots__id_014__ptkathma__michelson__v1__primitives:
    2: code
    115: apply
    75: sub
    27: cons
    33: dup
    119: self_address
    59: neg
    41: get
    38: exec
    143: open_chest
    142: chest_key
    83: loop_left
    37: eq
    34: ediv
    139: join_tickets
    87: cast
    85: contract
    79: unit
    140: get_and_update
    65: or
    47: if_none
    64: now
    148: tx_rollup_l2_address
    130: bls12_381_fr
    42: gt
    122: unpair
    95: list
    137: read_ticket
    66: pair
    118: level
    138: split_ticket
    110: address
    114: empty_big_map
    54: lsr
    146: constant
    151: emit
    5: left
    52: loop
    127: pairing_check
    104: string
    49: lambda
    60: neq
    36: empty_set
    78: set_delegate
    129: bls12_381_g2
    124: total_voting_power
    45: if_cons
    12: pack
    8: right
    10: true
    86: isnat
    51: left
    67: push
    126: sha3
    82: iter
    23: cdr
    106: mutez
    63: not
    22: car
    100: or
    72: sender
    90: contract
    69: size
    40: ge
    84: address
    62: none
    133: sapling_empty_state
    11: unit
    29: create_contract
    70: some
    50: le
    77: transfer_tokens
    105: bytes
    73: self
    136: ticket
    13: unpack
    123: voting_power
    55: lt
    28: create_account
    46: if_left
    43: hash_key
    117: chain_id
    102: set
    125: keccak
    101: pair
    19: amount
    98: nat
    76: swap
    6: none
    35: empty_map
    108: unit
    0: parameter
    9: some
    80: update
    91: int
    81: xor
    57: mem
    31: dip
    149: min_block_time
    92: key
    4: elt
    39: failwith
    58: mul
    135: ticket
    26: concat
    21: balance
    99: option
    32: drop
    111: slice
    147: sub_mutez
    25: compare
    109: operation
    131: sapling_state
    120: never
    141: chest
    53: lsl
    89: bool
    16: sha512
    30: implicit_account
    18: add
    116: chain_id
    97: big_map
    56: map
    107: timestamp
    121: never
    24: check_signature
    88: rename
    74: steps_to_quota
    94: lambda
    61: nil
    103: signature
    144: view
    20: and
    15: sha256
    145: view
    68: right
    1: storage
    150: sapling_transaction
    96: map
    48: int
    7: pair
    132: sapling_transaction_deprecated
    93: key_hash
    14: blake2b
    128: bls12_381_g1
    134: sapling_verify_update
    112: dig
    3: false
    113: dug
    71: source
    44: if
    17: abs
  big_map__update__prim__no_args__no_annots__id_014__ptkathma__michelson__v1__primitives:
    2: code
    115: apply
    75: sub
    27: cons
    33: dup
    119: self_address
    59: neg
    41: get
    38: exec
    143: open_chest
    142: chest_key
    83: loop_left
    37: eq
    34: ediv
    139: join_tickets
    87: cast
    85: contract
    79: unit
    140: get_and_update
    65: or
    47: if_none
    64: now
    148: tx_rollup_l2_address
    130: bls12_381_fr
    42: gt
    122: unpair
    95: list
    137: read_ticket
    66: pair
    118: level
    138: split_ticket
    110: address
    114: empty_big_map
    54: lsr
    146: constant
    151: emit
    5: left
    52: loop
    127: pairing_check
    104: string
    49: lambda
    60: neq
    36: empty_set
    78: set_delegate
    129: bls12_381_g2
    124: total_voting_power
    45: if_cons
    12: pack
    8: right
    10: true
    86: isnat
    51: left
    67: push
    126: sha3
    82: iter
    23: cdr
    106: mutez
    63: not
    22: car
    100: or
    72: sender
    90: contract
    69: size
    40: ge
    84: address
    62: none
    133: sapling_empty_state
    11: unit
    29: create_contract
    70: some
    50: le
    77: transfer_tokens
    105: bytes
    73: self
    136: ticket
    13: unpack
    123: voting_power
    55: lt
    28: create_account
    46: if_left
    43: hash_key
    117: chain_id
    102: set
    125: keccak
    101: pair
    19: amount
    98: nat
    76: swap
    6: none
    35: empty_map
    108: unit
    0: parameter
    9: some
    80: update
    91: int
    81: xor
    57: mem
    31: dip
    149: min_block_time
    92: key
    4: elt
    39: failwith
    58: mul
    135: ticket
    26: concat
    21: balance
    99: option
    32: drop
    111: slice
    147: sub_mutez
    25: compare
    109: operation
    131: sapling_state
    120: never
    141: chest
    53: lsl
    89: bool
    16: sha512
    30: implicit_account
    18: add
    116: chain_id
    97: big_map
    56: map
    107: timestamp
    121: never
    24: check_signature
    88: rename
    74: steps_to_quota
    94: lambda
    61: nil
    103: signature
    144: view
    20: and
    15: sha256
    145: view
    68: right
    1: storage
    150: sapling_transaction
    96: map
    48: int
    7: pair
    132: sapling_transaction_deprecated
    93: key_hash
    14: blake2b
    128: bls12_381_g1
    134: sapling_verify_update
    112: dig
    3: false
    113: dug
    71: source
    44: if
    17: abs
  micheline__014__ptkathma__michelson_v1__expression_tag:
    0: int
    1: string
    2: sequence
    3:
      id: prim__no_args__no_annots
      doc: Primitive with no arguments and no annotations
    4:
      id: prim__no_args__some_annots
      doc: Primitive with no arguments and some annotations
    5:
      id: prim__1_arg__no_annots
      doc: Primitive with one argument and no annotations
    6:
      id: prim__1_arg__some_annots
      doc: Primitive with one argument and some annotations
    7:
      id: prim__2_args__no_annots
      doc: Primitive with two arguments and no annotations
    8:
      id: prim__2_args__some_annots
      doc: Primitive with two arguments and some annotations
    9:
      id: prim__generic
      doc: Generic primitive (any number of args with or without annotations)
    10: bytes
  diff_tag:
    0: update
    1: remove
    2: copy
    3: alloc
  id_014__ptkathma__lazy_storage_diff_elt_tag:
    0: big_map
    1: sapling_state
seq:
- id: len_id_014__ptkathma__lazy_storage_diff
  type: u4
  valid:
    max: 1073741823
- id: id_014__ptkathma__lazy_storage_diff
  type: id_014__ptkathma__lazy_storage_diff_entries
  size: len_id_014__ptkathma__lazy_storage_diff
  repeat: eos
