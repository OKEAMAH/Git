meta:
  id: id_011__pthangz2__script__expr
  endian: be
doc: ! 'Encoding id: 011-PtHangz2.script.expr'
types:
  micheline__011__pthangz2__michelson_v1__expression:
    seq:
    - id: micheline__011__pthangz2__michelson_v1__expression_tag
      type: u1
      enum: micheline__011__pthangz2__michelson_v1__expression_tag
    - id: int__micheline__011__pthangz2__michelson_v1__expression
      type: z
      if: (micheline__011__pthangz2__michelson_v1__expression_tag == ::micheline__011__pthangz2__michelson_v1__expression_tag::micheline__011__pthangz2__michelson_v1__expression_tag::int)
    - id: string__micheline__011__pthangz2__michelson_v1__expression
      type: string__string
      if: (micheline__011__pthangz2__michelson_v1__expression_tag == ::micheline__011__pthangz2__michelson_v1__expression_tag::micheline__011__pthangz2__michelson_v1__expression_tag::string)
    - id: sequence__micheline__011__pthangz2__michelson_v1__expression
      type: sequence__micheline__011__pthangz2__michelson_v1__expression
      if: (micheline__011__pthangz2__michelson_v1__expression_tag == micheline__011__pthangz2__michelson_v1__expression_tag::sequence)
    - id: prim__no_args__no_annots__micheline__011__pthangz2__michelson_v1__expression
      type: u1
      if: (micheline__011__pthangz2__michelson_v1__expression_tag == ::micheline__011__pthangz2__michelson_v1__expression_tag::micheline__011__pthangz2__michelson_v1__expression_tag::prim__no_args__no_annots)
      enum: prim__no_args__no_annots__id_011__pthangz2__michelson__v1__primitives
    - id: prim__no_args__some_annots__micheline__011__pthangz2__michelson_v1__expression
      type: prim__no_args__some_annots__micheline__011__pthangz2__michelson_v1__expression
      if: (micheline__011__pthangz2__michelson_v1__expression_tag == micheline__011__pthangz2__michelson_v1__expression_tag::prim__no_args__some_annots)
    - id: prim__1_arg__no_annots__micheline__011__pthangz2__michelson_v1__expression
      type: prim__1_arg__no_annots__micheline__011__pthangz2__michelson_v1__expression
      if: (micheline__011__pthangz2__michelson_v1__expression_tag == micheline__011__pthangz2__michelson_v1__expression_tag::prim__1_arg__no_annots)
    - id: prim__1_arg__some_annots__micheline__011__pthangz2__michelson_v1__expression
      type: prim__1_arg__some_annots__micheline__011__pthangz2__michelson_v1__expression
      if: (micheline__011__pthangz2__michelson_v1__expression_tag == micheline__011__pthangz2__michelson_v1__expression_tag::prim__1_arg__some_annots)
    - id: prim__2_args__no_annots__micheline__011__pthangz2__michelson_v1__expression
      type: prim__2_args__no_annots__micheline__011__pthangz2__michelson_v1__expression
      if: (micheline__011__pthangz2__michelson_v1__expression_tag == micheline__011__pthangz2__michelson_v1__expression_tag::prim__2_args__no_annots)
    - id: prim__2_args__some_annots__micheline__011__pthangz2__michelson_v1__expression
      type: prim__2_args__some_annots__micheline__011__pthangz2__michelson_v1__expression
      if: (micheline__011__pthangz2__michelson_v1__expression_tag == micheline__011__pthangz2__michelson_v1__expression_tag::prim__2_args__some_annots)
    - id: prim__generic__micheline__011__pthangz2__michelson_v1__expression
      type: prim__generic__micheline__011__pthangz2__michelson_v1__expression
      if: (micheline__011__pthangz2__michelson_v1__expression_tag == micheline__011__pthangz2__michelson_v1__expression_tag::prim__generic)
    - id: bytes__micheline__011__pthangz2__michelson_v1__expression
      type: bytes__bytes
      if: (micheline__011__pthangz2__michelson_v1__expression_tag == ::micheline__011__pthangz2__michelson_v1__expression_tag::micheline__011__pthangz2__michelson_v1__expression_tag::bytes)
  bytes__bytes:
    seq:
    - id: len_bytes
      type: u4
      valid:
        max: 1073741823
    - id: bytes
      size: len_bytes
  prim__generic__micheline__011__pthangz2__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__generic__id_011__pthangz2__michelson__v1__primitives
    - id: prim__generic__args
      type: prim__generic__args
    - id: prim__generic__annots
      type: prim__generic__annots
  prim__generic__annots:
    seq:
    - id: len_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: len_annots
  prim__generic__args:
    seq:
    - id: len_args
      type: u4
      valid:
        max: 1073741823
    - id: args
      type: prim__generic__args_entries
      size: len_args
      repeat: eos
  prim__generic__args_entries:
    seq:
    - id: args_elt
      type: micheline__011__pthangz2__michelson_v1__expression
  prim__2_args__some_annots__micheline__011__pthangz2__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__2_args__some_annots__id_011__pthangz2__michelson__v1__primitives
    - id: arg1
      type: micheline__011__pthangz2__michelson_v1__expression
    - id: arg2
      type: micheline__011__pthangz2__michelson_v1__expression
    - id: prim__2_args__some_annots__annots
      type: prim__2_args__some_annots__annots
  prim__2_args__some_annots__annots:
    seq:
    - id: len_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: len_annots
  prim__2_args__no_annots__micheline__011__pthangz2__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__2_args__no_annots__id_011__pthangz2__michelson__v1__primitives
    - id: arg1
      type: micheline__011__pthangz2__michelson_v1__expression
    - id: arg2
      type: micheline__011__pthangz2__michelson_v1__expression
  prim__1_arg__some_annots__micheline__011__pthangz2__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__1_arg__some_annots__id_011__pthangz2__michelson__v1__primitives
    - id: arg
      type: micheline__011__pthangz2__michelson_v1__expression
    - id: prim__1_arg__some_annots__annots
      type: prim__1_arg__some_annots__annots
  prim__1_arg__some_annots__annots:
    seq:
    - id: len_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: len_annots
  prim__1_arg__no_annots__micheline__011__pthangz2__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__1_arg__no_annots__id_011__pthangz2__michelson__v1__primitives
    - id: arg
      type: micheline__011__pthangz2__michelson_v1__expression
  prim__no_args__some_annots__micheline__011__pthangz2__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__no_args__some_annots__id_011__pthangz2__michelson__v1__primitives
    - id: prim__no_args__some_annots__annots
      type: prim__no_args__some_annots__annots
  prim__no_args__some_annots__annots:
    seq:
    - id: len_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: len_annots
  sequence__micheline__011__pthangz2__michelson_v1__expression:
    seq:
    - id: len_sequence
      type: u4
      valid:
        max: 1073741823
    - id: sequence
      type: sequence__sequence_entries
      size: len_sequence
      repeat: eos
  sequence__sequence_entries:
    seq:
    - id: sequence_elt
      type: micheline__011__pthangz2__michelson_v1__expression
  string__string:
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
  prim__generic__id_011__pthangz2__michelson__v1__primitives:
    2: code
    115: apply
    76: swap
    27: cons
    33: dup
    111: slice
    59: neg
    41: get
    38: exec
    90: contract
    85: contract
    37: eq
    34: ediv
    133: sapling_empty_state
    89: bool
    87: cast
    81: xor
    140: get_and_update
    66: pair
    47: if_none
    64: now
    120: never
    42: gt
    98: nat
    67: push
    139: join_tickets
    122: unpair
    118: level
    143: open_chest
    116: chain_id
    114: empty_big_map
    54: lsr
    91: int
    5: left
    52: loop
    137: read_ticket
    107: timestamp
    49: lambda
    60: neq
    36: empty_set
    80: update
    146: constant
    126: sha3
    45: if_cons
    12: pack
    8: right
    10: true
    88: rename
    51: left
    68: right
    136: ticket
    84: address
    23: cdr
    109: operation
    63: not
    22: car
    103: signature
    73: self
    93: key_hash
    70: some
    40: ge
    86: isnat
    62: none
    112: dig
    11: unit
    29: create_contract
    71: source
    50: le
    79: unit
    108: unit
    119: self_address
    138: split_ticket
    13: unpack
    125: keccak
    55: lt
    28: create_account
    46: if_left
    43: hash_key
    117: chain_id
    105: bytes
    127: pairing_check
    104: string
    19: amount
    101: pair
    78: set_delegate
    6: none
    35: empty_map
    132: sapling_transaction
    0: parameter
    9: some
    82: iter
    94: lambda
    83: loop_left
    57: mem
    31: dip
    65: or
    95: list
    4: elt
    39: failwith
    58: mul
    26: concat
    21: balance
    102: set
    32: drop
    74: steps_to_quota
    77: transfer_tokens
    25: compare
    131: sapling_state
    142: chest_key
    130: bls12_381_fr
    53: lsl
    92: key
    16: sha512
    30: implicit_account
    18: add
    135: ticket
    100: or
    56: map
    110: address
    124: total_voting_power
    24: check_signature
    134: sapling_verify_update
    75: sub
    97: big_map
    61: nil
    106: mutez
    144: view
    20: and
    15: sha256
    145: view
    69: size
    1: storage
    128: bls12_381_g1
    99: option
    48: int
    7: pair
    129: bls12_381_g2
    96: map
    14: blake2b
    141: chest
    113: dug
    121: never
    3: false
    123: voting_power
    72: sender
    44: if
    17: abs
  prim__2_args__some_annots__id_011__pthangz2__michelson__v1__primitives:
    2: code
    115: apply
    76: swap
    27: cons
    33: dup
    111: slice
    59: neg
    41: get
    38: exec
    90: contract
    85: contract
    37: eq
    34: ediv
    133: sapling_empty_state
    89: bool
    87: cast
    81: xor
    140: get_and_update
    66: pair
    47: if_none
    64: now
    120: never
    42: gt
    98: nat
    67: push
    139: join_tickets
    122: unpair
    118: level
    143: open_chest
    116: chain_id
    114: empty_big_map
    54: lsr
    91: int
    5: left
    52: loop
    137: read_ticket
    107: timestamp
    49: lambda
    60: neq
    36: empty_set
    80: update
    146: constant
    126: sha3
    45: if_cons
    12: pack
    8: right
    10: true
    88: rename
    51: left
    68: right
    136: ticket
    84: address
    23: cdr
    109: operation
    63: not
    22: car
    103: signature
    73: self
    93: key_hash
    70: some
    40: ge
    86: isnat
    62: none
    112: dig
    11: unit
    29: create_contract
    71: source
    50: le
    79: unit
    108: unit
    119: self_address
    138: split_ticket
    13: unpack
    125: keccak
    55: lt
    28: create_account
    46: if_left
    43: hash_key
    117: chain_id
    105: bytes
    127: pairing_check
    104: string
    19: amount
    101: pair
    78: set_delegate
    6: none
    35: empty_map
    132: sapling_transaction
    0: parameter
    9: some
    82: iter
    94: lambda
    83: loop_left
    57: mem
    31: dip
    65: or
    95: list
    4: elt
    39: failwith
    58: mul
    26: concat
    21: balance
    102: set
    32: drop
    74: steps_to_quota
    77: transfer_tokens
    25: compare
    131: sapling_state
    142: chest_key
    130: bls12_381_fr
    53: lsl
    92: key
    16: sha512
    30: implicit_account
    18: add
    135: ticket
    100: or
    56: map
    110: address
    124: total_voting_power
    24: check_signature
    134: sapling_verify_update
    75: sub
    97: big_map
    61: nil
    106: mutez
    144: view
    20: and
    15: sha256
    145: view
    69: size
    1: storage
    128: bls12_381_g1
    99: option
    48: int
    7: pair
    129: bls12_381_g2
    96: map
    14: blake2b
    141: chest
    113: dug
    121: never
    3: false
    123: voting_power
    72: sender
    44: if
    17: abs
  prim__2_args__no_annots__id_011__pthangz2__michelson__v1__primitives:
    2: code
    115: apply
    76: swap
    27: cons
    33: dup
    111: slice
    59: neg
    41: get
    38: exec
    90: contract
    85: contract
    37: eq
    34: ediv
    133: sapling_empty_state
    89: bool
    87: cast
    81: xor
    140: get_and_update
    66: pair
    47: if_none
    64: now
    120: never
    42: gt
    98: nat
    67: push
    139: join_tickets
    122: unpair
    118: level
    143: open_chest
    116: chain_id
    114: empty_big_map
    54: lsr
    91: int
    5: left
    52: loop
    137: read_ticket
    107: timestamp
    49: lambda
    60: neq
    36: empty_set
    80: update
    146: constant
    126: sha3
    45: if_cons
    12: pack
    8: right
    10: true
    88: rename
    51: left
    68: right
    136: ticket
    84: address
    23: cdr
    109: operation
    63: not
    22: car
    103: signature
    73: self
    93: key_hash
    70: some
    40: ge
    86: isnat
    62: none
    112: dig
    11: unit
    29: create_contract
    71: source
    50: le
    79: unit
    108: unit
    119: self_address
    138: split_ticket
    13: unpack
    125: keccak
    55: lt
    28: create_account
    46: if_left
    43: hash_key
    117: chain_id
    105: bytes
    127: pairing_check
    104: string
    19: amount
    101: pair
    78: set_delegate
    6: none
    35: empty_map
    132: sapling_transaction
    0: parameter
    9: some
    82: iter
    94: lambda
    83: loop_left
    57: mem
    31: dip
    65: or
    95: list
    4: elt
    39: failwith
    58: mul
    26: concat
    21: balance
    102: set
    32: drop
    74: steps_to_quota
    77: transfer_tokens
    25: compare
    131: sapling_state
    142: chest_key
    130: bls12_381_fr
    53: lsl
    92: key
    16: sha512
    30: implicit_account
    18: add
    135: ticket
    100: or
    56: map
    110: address
    124: total_voting_power
    24: check_signature
    134: sapling_verify_update
    75: sub
    97: big_map
    61: nil
    106: mutez
    144: view
    20: and
    15: sha256
    145: view
    69: size
    1: storage
    128: bls12_381_g1
    99: option
    48: int
    7: pair
    129: bls12_381_g2
    96: map
    14: blake2b
    141: chest
    113: dug
    121: never
    3: false
    123: voting_power
    72: sender
    44: if
    17: abs
  prim__1_arg__some_annots__id_011__pthangz2__michelson__v1__primitives:
    2: code
    115: apply
    76: swap
    27: cons
    33: dup
    111: slice
    59: neg
    41: get
    38: exec
    90: contract
    85: contract
    37: eq
    34: ediv
    133: sapling_empty_state
    89: bool
    87: cast
    81: xor
    140: get_and_update
    66: pair
    47: if_none
    64: now
    120: never
    42: gt
    98: nat
    67: push
    139: join_tickets
    122: unpair
    118: level
    143: open_chest
    116: chain_id
    114: empty_big_map
    54: lsr
    91: int
    5: left
    52: loop
    137: read_ticket
    107: timestamp
    49: lambda
    60: neq
    36: empty_set
    80: update
    146: constant
    126: sha3
    45: if_cons
    12: pack
    8: right
    10: true
    88: rename
    51: left
    68: right
    136: ticket
    84: address
    23: cdr
    109: operation
    63: not
    22: car
    103: signature
    73: self
    93: key_hash
    70: some
    40: ge
    86: isnat
    62: none
    112: dig
    11: unit
    29: create_contract
    71: source
    50: le
    79: unit
    108: unit
    119: self_address
    138: split_ticket
    13: unpack
    125: keccak
    55: lt
    28: create_account
    46: if_left
    43: hash_key
    117: chain_id
    105: bytes
    127: pairing_check
    104: string
    19: amount
    101: pair
    78: set_delegate
    6: none
    35: empty_map
    132: sapling_transaction
    0: parameter
    9: some
    82: iter
    94: lambda
    83: loop_left
    57: mem
    31: dip
    65: or
    95: list
    4: elt
    39: failwith
    58: mul
    26: concat
    21: balance
    102: set
    32: drop
    74: steps_to_quota
    77: transfer_tokens
    25: compare
    131: sapling_state
    142: chest_key
    130: bls12_381_fr
    53: lsl
    92: key
    16: sha512
    30: implicit_account
    18: add
    135: ticket
    100: or
    56: map
    110: address
    124: total_voting_power
    24: check_signature
    134: sapling_verify_update
    75: sub
    97: big_map
    61: nil
    106: mutez
    144: view
    20: and
    15: sha256
    145: view
    69: size
    1: storage
    128: bls12_381_g1
    99: option
    48: int
    7: pair
    129: bls12_381_g2
    96: map
    14: blake2b
    141: chest
    113: dug
    121: never
    3: false
    123: voting_power
    72: sender
    44: if
    17: abs
  prim__1_arg__no_annots__id_011__pthangz2__michelson__v1__primitives:
    2: code
    115: apply
    76: swap
    27: cons
    33: dup
    111: slice
    59: neg
    41: get
    38: exec
    90: contract
    85: contract
    37: eq
    34: ediv
    133: sapling_empty_state
    89: bool
    87: cast
    81: xor
    140: get_and_update
    66: pair
    47: if_none
    64: now
    120: never
    42: gt
    98: nat
    67: push
    139: join_tickets
    122: unpair
    118: level
    143: open_chest
    116: chain_id
    114: empty_big_map
    54: lsr
    91: int
    5: left
    52: loop
    137: read_ticket
    107: timestamp
    49: lambda
    60: neq
    36: empty_set
    80: update
    146: constant
    126: sha3
    45: if_cons
    12: pack
    8: right
    10: true
    88: rename
    51: left
    68: right
    136: ticket
    84: address
    23: cdr
    109: operation
    63: not
    22: car
    103: signature
    73: self
    93: key_hash
    70: some
    40: ge
    86: isnat
    62: none
    112: dig
    11: unit
    29: create_contract
    71: source
    50: le
    79: unit
    108: unit
    119: self_address
    138: split_ticket
    13: unpack
    125: keccak
    55: lt
    28: create_account
    46: if_left
    43: hash_key
    117: chain_id
    105: bytes
    127: pairing_check
    104: string
    19: amount
    101: pair
    78: set_delegate
    6: none
    35: empty_map
    132: sapling_transaction
    0: parameter
    9: some
    82: iter
    94: lambda
    83: loop_left
    57: mem
    31: dip
    65: or
    95: list
    4: elt
    39: failwith
    58: mul
    26: concat
    21: balance
    102: set
    32: drop
    74: steps_to_quota
    77: transfer_tokens
    25: compare
    131: sapling_state
    142: chest_key
    130: bls12_381_fr
    53: lsl
    92: key
    16: sha512
    30: implicit_account
    18: add
    135: ticket
    100: or
    56: map
    110: address
    124: total_voting_power
    24: check_signature
    134: sapling_verify_update
    75: sub
    97: big_map
    61: nil
    106: mutez
    144: view
    20: and
    15: sha256
    145: view
    69: size
    1: storage
    128: bls12_381_g1
    99: option
    48: int
    7: pair
    129: bls12_381_g2
    96: map
    14: blake2b
    141: chest
    113: dug
    121: never
    3: false
    123: voting_power
    72: sender
    44: if
    17: abs
  prim__no_args__some_annots__id_011__pthangz2__michelson__v1__primitives:
    2: code
    115: apply
    76: swap
    27: cons
    33: dup
    111: slice
    59: neg
    41: get
    38: exec
    90: contract
    85: contract
    37: eq
    34: ediv
    133: sapling_empty_state
    89: bool
    87: cast
    81: xor
    140: get_and_update
    66: pair
    47: if_none
    64: now
    120: never
    42: gt
    98: nat
    67: push
    139: join_tickets
    122: unpair
    118: level
    143: open_chest
    116: chain_id
    114: empty_big_map
    54: lsr
    91: int
    5: left
    52: loop
    137: read_ticket
    107: timestamp
    49: lambda
    60: neq
    36: empty_set
    80: update
    146: constant
    126: sha3
    45: if_cons
    12: pack
    8: right
    10: true
    88: rename
    51: left
    68: right
    136: ticket
    84: address
    23: cdr
    109: operation
    63: not
    22: car
    103: signature
    73: self
    93: key_hash
    70: some
    40: ge
    86: isnat
    62: none
    112: dig
    11: unit
    29: create_contract
    71: source
    50: le
    79: unit
    108: unit
    119: self_address
    138: split_ticket
    13: unpack
    125: keccak
    55: lt
    28: create_account
    46: if_left
    43: hash_key
    117: chain_id
    105: bytes
    127: pairing_check
    104: string
    19: amount
    101: pair
    78: set_delegate
    6: none
    35: empty_map
    132: sapling_transaction
    0: parameter
    9: some
    82: iter
    94: lambda
    83: loop_left
    57: mem
    31: dip
    65: or
    95: list
    4: elt
    39: failwith
    58: mul
    26: concat
    21: balance
    102: set
    32: drop
    74: steps_to_quota
    77: transfer_tokens
    25: compare
    131: sapling_state
    142: chest_key
    130: bls12_381_fr
    53: lsl
    92: key
    16: sha512
    30: implicit_account
    18: add
    135: ticket
    100: or
    56: map
    110: address
    124: total_voting_power
    24: check_signature
    134: sapling_verify_update
    75: sub
    97: big_map
    61: nil
    106: mutez
    144: view
    20: and
    15: sha256
    145: view
    69: size
    1: storage
    128: bls12_381_g1
    99: option
    48: int
    7: pair
    129: bls12_381_g2
    96: map
    14: blake2b
    141: chest
    113: dug
    121: never
    3: false
    123: voting_power
    72: sender
    44: if
    17: abs
  prim__no_args__no_annots__id_011__pthangz2__michelson__v1__primitives:
    2: code
    115: apply
    76: swap
    27: cons
    33: dup
    111: slice
    59: neg
    41: get
    38: exec
    90: contract
    85: contract
    37: eq
    34: ediv
    133: sapling_empty_state
    89: bool
    87: cast
    81: xor
    140: get_and_update
    66: pair
    47: if_none
    64: now
    120: never
    42: gt
    98: nat
    67: push
    139: join_tickets
    122: unpair
    118: level
    143: open_chest
    116: chain_id
    114: empty_big_map
    54: lsr
    91: int
    5: left
    52: loop
    137: read_ticket
    107: timestamp
    49: lambda
    60: neq
    36: empty_set
    80: update
    146: constant
    126: sha3
    45: if_cons
    12: pack
    8: right
    10: true
    88: rename
    51: left
    68: right
    136: ticket
    84: address
    23: cdr
    109: operation
    63: not
    22: car
    103: signature
    73: self
    93: key_hash
    70: some
    40: ge
    86: isnat
    62: none
    112: dig
    11: unit
    29: create_contract
    71: source
    50: le
    79: unit
    108: unit
    119: self_address
    138: split_ticket
    13: unpack
    125: keccak
    55: lt
    28: create_account
    46: if_left
    43: hash_key
    117: chain_id
    105: bytes
    127: pairing_check
    104: string
    19: amount
    101: pair
    78: set_delegate
    6: none
    35: empty_map
    132: sapling_transaction
    0: parameter
    9: some
    82: iter
    94: lambda
    83: loop_left
    57: mem
    31: dip
    65: or
    95: list
    4: elt
    39: failwith
    58: mul
    26: concat
    21: balance
    102: set
    32: drop
    74: steps_to_quota
    77: transfer_tokens
    25: compare
    131: sapling_state
    142: chest_key
    130: bls12_381_fr
    53: lsl
    92: key
    16: sha512
    30: implicit_account
    18: add
    135: ticket
    100: or
    56: map
    110: address
    124: total_voting_power
    24: check_signature
    134: sapling_verify_update
    75: sub
    97: big_map
    61: nil
    106: mutez
    144: view
    20: and
    15: sha256
    145: view
    69: size
    1: storage
    128: bls12_381_g1
    99: option
    48: int
    7: pair
    129: bls12_381_g2
    96: map
    14: blake2b
    141: chest
    113: dug
    121: never
    3: false
    123: voting_power
    72: sender
    44: if
    17: abs
  micheline__011__pthangz2__michelson_v1__expression_tag:
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
seq:
- id: micheline__011__pthangz2__michelson_v1__expression
  type: micheline__011__pthangz2__michelson_v1__expression
