meta:
  id: id_012__psithaca__script__expr
  endian: be
doc: ! 'Encoding id: 012-Psithaca.script.expr'
types:
  micheline__012__psithaca__michelson_v1__expression:
    seq:
    - id: micheline__012__psithaca__michelson_v1__expression_tag
      type: u1
      enum: micheline__012__psithaca__michelson_v1__expression_tag
    - id: int__micheline__012__psithaca__michelson_v1__expression
      type: z
      if: (micheline__012__psithaca__michelson_v1__expression_tag == ::micheline__012__psithaca__michelson_v1__expression_tag::micheline__012__psithaca__michelson_v1__expression_tag::int)
    - id: string__micheline__012__psithaca__michelson_v1__expression
      type: string__string
      if: (micheline__012__psithaca__michelson_v1__expression_tag == ::micheline__012__psithaca__michelson_v1__expression_tag::micheline__012__psithaca__michelson_v1__expression_tag::string)
    - id: sequence__micheline__012__psithaca__michelson_v1__expression
      type: sequence__micheline__012__psithaca__michelson_v1__expression
      if: (micheline__012__psithaca__michelson_v1__expression_tag == micheline__012__psithaca__michelson_v1__expression_tag::sequence)
    - id: prim__no_args__no_annots__micheline__012__psithaca__michelson_v1__expression
      type: u1
      if: (micheline__012__psithaca__michelson_v1__expression_tag == ::micheline__012__psithaca__michelson_v1__expression_tag::micheline__012__psithaca__michelson_v1__expression_tag::prim__no_args__no_annots)
      enum: prim__no_args__no_annots__id_012__psithaca__michelson__v1__primitives
    - id: prim__no_args__some_annots__micheline__012__psithaca__michelson_v1__expression
      type: prim__no_args__some_annots__micheline__012__psithaca__michelson_v1__expression
      if: (micheline__012__psithaca__michelson_v1__expression_tag == micheline__012__psithaca__michelson_v1__expression_tag::prim__no_args__some_annots)
    - id: prim__1_arg__no_annots__micheline__012__psithaca__michelson_v1__expression
      type: prim__1_arg__no_annots__micheline__012__psithaca__michelson_v1__expression
      if: (micheline__012__psithaca__michelson_v1__expression_tag == micheline__012__psithaca__michelson_v1__expression_tag::prim__1_arg__no_annots)
    - id: prim__1_arg__some_annots__micheline__012__psithaca__michelson_v1__expression
      type: prim__1_arg__some_annots__micheline__012__psithaca__michelson_v1__expression
      if: (micheline__012__psithaca__michelson_v1__expression_tag == micheline__012__psithaca__michelson_v1__expression_tag::prim__1_arg__some_annots)
    - id: prim__2_args__no_annots__micheline__012__psithaca__michelson_v1__expression
      type: prim__2_args__no_annots__micheline__012__psithaca__michelson_v1__expression
      if: (micheline__012__psithaca__michelson_v1__expression_tag == micheline__012__psithaca__michelson_v1__expression_tag::prim__2_args__no_annots)
    - id: prim__2_args__some_annots__micheline__012__psithaca__michelson_v1__expression
      type: prim__2_args__some_annots__micheline__012__psithaca__michelson_v1__expression
      if: (micheline__012__psithaca__michelson_v1__expression_tag == micheline__012__psithaca__michelson_v1__expression_tag::prim__2_args__some_annots)
    - id: prim__generic__micheline__012__psithaca__michelson_v1__expression
      type: prim__generic__micheline__012__psithaca__michelson_v1__expression
      if: (micheline__012__psithaca__michelson_v1__expression_tag == micheline__012__psithaca__michelson_v1__expression_tag::prim__generic)
    - id: bytes__micheline__012__psithaca__michelson_v1__expression
      type: bytes__bytes
      if: (micheline__012__psithaca__michelson_v1__expression_tag == ::micheline__012__psithaca__michelson_v1__expression_tag::micheline__012__psithaca__michelson_v1__expression_tag::bytes)
  bytes__bytes:
    seq:
    - id: len_bytes
      type: u4
      valid:
        max: 1073741823
    - id: bytes
      size: len_bytes
  prim__generic__micheline__012__psithaca__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__generic__id_012__psithaca__michelson__v1__primitives
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
      type: micheline__012__psithaca__michelson_v1__expression
  prim__2_args__some_annots__micheline__012__psithaca__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__2_args__some_annots__id_012__psithaca__michelson__v1__primitives
    - id: arg1
      type: micheline__012__psithaca__michelson_v1__expression
    - id: arg2
      type: micheline__012__psithaca__michelson_v1__expression
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
  prim__2_args__no_annots__micheline__012__psithaca__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__2_args__no_annots__id_012__psithaca__michelson__v1__primitives
    - id: arg1
      type: micheline__012__psithaca__michelson_v1__expression
    - id: arg2
      type: micheline__012__psithaca__michelson_v1__expression
  prim__1_arg__some_annots__micheline__012__psithaca__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__1_arg__some_annots__id_012__psithaca__michelson__v1__primitives
    - id: arg
      type: micheline__012__psithaca__michelson_v1__expression
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
  prim__1_arg__no_annots__micheline__012__psithaca__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__1_arg__no_annots__id_012__psithaca__michelson__v1__primitives
    - id: arg
      type: micheline__012__psithaca__michelson_v1__expression
  prim__no_args__some_annots__micheline__012__psithaca__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__no_args__some_annots__id_012__psithaca__michelson__v1__primitives
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
  sequence__micheline__012__psithaca__michelson_v1__expression:
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
      type: micheline__012__psithaca__michelson_v1__expression
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
  prim__generic__id_012__psithaca__michelson__v1__primitives:
    2: code
    147: sub_mutez
    115: apply
    27: cons
    33: dup
    111: slice
    59: neg
    41: get
    38: exec
    89: bool
    84: address
    37: eq
    34: ediv
    143: open_chest
    88: rename
    86: isnat
    80: update
    140: get_and_update
    66: pair
    47: if_none
    64: now
    146: constant
    116: chain_id
    42: gt
    97: big_map
    67: push
    138: split_ticket
    122: unpair
    118: level
    139: join_tickets
    131: sapling_state
    114: empty_big_map
    54: lsr
    90: contract
    5: left
    52: loop
    136: ticket
    106: mutez
    49: lambda
    60: neq
    36: empty_set
    79: unit
    141: chest
    125: keccak
    45: if_cons
    12: pack
    8: right
    10: true
    87: cast
    51: left
    68: right
    127: pairing_check
    83: loop_left
    23: cdr
    108: unit
    63: not
    22: car
    102: set
    73: self
    92: key
    70: some
    40: ge
    85: contract
    62: none
    134: sapling_verify_update
    11: unit
    29: create_contract
    71: source
    50: le
    78: set_delegate
    107: timestamp
    119: self_address
    137: read_ticket
    13: unpack
    124: total_voting_power
    55: lt
    28: create_account
    46: if_left
    43: hash_key
    117: chain_id
    104: string
    126: sha3
    103: signature
    19: amount
    100: or
    77: transfer_tokens
    6: none
    35: empty_map
    110: address
    0: parameter
    9: some
    81: xor
    93: key_hash
    82: iter
    57: mem
    31: dip
    65: or
    94: lambda
    4: elt
    39: failwith
    58: mul
    26: concat
    21: balance
    101: pair
    32: drop
    74: steps_to_quota
    76: swap
    25: compare
    132: sapling_transaction
    135: ticket
    129: bls12_381_g2
    53: lsl
    91: int
    16: sha512
    30: implicit_account
    18: add
    130: bls12_381_fr
    99: option
    56: map
    109: operation
    123: voting_power
    24: check_signature
    133: sapling_empty_state
    75: sub
    96: map
    61: nil
    105: bytes
    144: view
    20: and
    15: sha256
    145: view
    69: size
    1: storage
    120: never
    98: nat
    48: int
    7: pair
    128: bls12_381_g1
    95: list
    14: blake2b
    142: chest_key
    112: dig
    113: dug
    3: false
    121: never
    72: sender
    44: if
    17: abs
  prim__2_args__some_annots__id_012__psithaca__michelson__v1__primitives:
    2: code
    147: sub_mutez
    115: apply
    27: cons
    33: dup
    111: slice
    59: neg
    41: get
    38: exec
    89: bool
    84: address
    37: eq
    34: ediv
    143: open_chest
    88: rename
    86: isnat
    80: update
    140: get_and_update
    66: pair
    47: if_none
    64: now
    146: constant
    116: chain_id
    42: gt
    97: big_map
    67: push
    138: split_ticket
    122: unpair
    118: level
    139: join_tickets
    131: sapling_state
    114: empty_big_map
    54: lsr
    90: contract
    5: left
    52: loop
    136: ticket
    106: mutez
    49: lambda
    60: neq
    36: empty_set
    79: unit
    141: chest
    125: keccak
    45: if_cons
    12: pack
    8: right
    10: true
    87: cast
    51: left
    68: right
    127: pairing_check
    83: loop_left
    23: cdr
    108: unit
    63: not
    22: car
    102: set
    73: self
    92: key
    70: some
    40: ge
    85: contract
    62: none
    134: sapling_verify_update
    11: unit
    29: create_contract
    71: source
    50: le
    78: set_delegate
    107: timestamp
    119: self_address
    137: read_ticket
    13: unpack
    124: total_voting_power
    55: lt
    28: create_account
    46: if_left
    43: hash_key
    117: chain_id
    104: string
    126: sha3
    103: signature
    19: amount
    100: or
    77: transfer_tokens
    6: none
    35: empty_map
    110: address
    0: parameter
    9: some
    81: xor
    93: key_hash
    82: iter
    57: mem
    31: dip
    65: or
    94: lambda
    4: elt
    39: failwith
    58: mul
    26: concat
    21: balance
    101: pair
    32: drop
    74: steps_to_quota
    76: swap
    25: compare
    132: sapling_transaction
    135: ticket
    129: bls12_381_g2
    53: lsl
    91: int
    16: sha512
    30: implicit_account
    18: add
    130: bls12_381_fr
    99: option
    56: map
    109: operation
    123: voting_power
    24: check_signature
    133: sapling_empty_state
    75: sub
    96: map
    61: nil
    105: bytes
    144: view
    20: and
    15: sha256
    145: view
    69: size
    1: storage
    120: never
    98: nat
    48: int
    7: pair
    128: bls12_381_g1
    95: list
    14: blake2b
    142: chest_key
    112: dig
    113: dug
    3: false
    121: never
    72: sender
    44: if
    17: abs
  prim__2_args__no_annots__id_012__psithaca__michelson__v1__primitives:
    2: code
    147: sub_mutez
    115: apply
    27: cons
    33: dup
    111: slice
    59: neg
    41: get
    38: exec
    89: bool
    84: address
    37: eq
    34: ediv
    143: open_chest
    88: rename
    86: isnat
    80: update
    140: get_and_update
    66: pair
    47: if_none
    64: now
    146: constant
    116: chain_id
    42: gt
    97: big_map
    67: push
    138: split_ticket
    122: unpair
    118: level
    139: join_tickets
    131: sapling_state
    114: empty_big_map
    54: lsr
    90: contract
    5: left
    52: loop
    136: ticket
    106: mutez
    49: lambda
    60: neq
    36: empty_set
    79: unit
    141: chest
    125: keccak
    45: if_cons
    12: pack
    8: right
    10: true
    87: cast
    51: left
    68: right
    127: pairing_check
    83: loop_left
    23: cdr
    108: unit
    63: not
    22: car
    102: set
    73: self
    92: key
    70: some
    40: ge
    85: contract
    62: none
    134: sapling_verify_update
    11: unit
    29: create_contract
    71: source
    50: le
    78: set_delegate
    107: timestamp
    119: self_address
    137: read_ticket
    13: unpack
    124: total_voting_power
    55: lt
    28: create_account
    46: if_left
    43: hash_key
    117: chain_id
    104: string
    126: sha3
    103: signature
    19: amount
    100: or
    77: transfer_tokens
    6: none
    35: empty_map
    110: address
    0: parameter
    9: some
    81: xor
    93: key_hash
    82: iter
    57: mem
    31: dip
    65: or
    94: lambda
    4: elt
    39: failwith
    58: mul
    26: concat
    21: balance
    101: pair
    32: drop
    74: steps_to_quota
    76: swap
    25: compare
    132: sapling_transaction
    135: ticket
    129: bls12_381_g2
    53: lsl
    91: int
    16: sha512
    30: implicit_account
    18: add
    130: bls12_381_fr
    99: option
    56: map
    109: operation
    123: voting_power
    24: check_signature
    133: sapling_empty_state
    75: sub
    96: map
    61: nil
    105: bytes
    144: view
    20: and
    15: sha256
    145: view
    69: size
    1: storage
    120: never
    98: nat
    48: int
    7: pair
    128: bls12_381_g1
    95: list
    14: blake2b
    142: chest_key
    112: dig
    113: dug
    3: false
    121: never
    72: sender
    44: if
    17: abs
  prim__1_arg__some_annots__id_012__psithaca__michelson__v1__primitives:
    2: code
    147: sub_mutez
    115: apply
    27: cons
    33: dup
    111: slice
    59: neg
    41: get
    38: exec
    89: bool
    84: address
    37: eq
    34: ediv
    143: open_chest
    88: rename
    86: isnat
    80: update
    140: get_and_update
    66: pair
    47: if_none
    64: now
    146: constant
    116: chain_id
    42: gt
    97: big_map
    67: push
    138: split_ticket
    122: unpair
    118: level
    139: join_tickets
    131: sapling_state
    114: empty_big_map
    54: lsr
    90: contract
    5: left
    52: loop
    136: ticket
    106: mutez
    49: lambda
    60: neq
    36: empty_set
    79: unit
    141: chest
    125: keccak
    45: if_cons
    12: pack
    8: right
    10: true
    87: cast
    51: left
    68: right
    127: pairing_check
    83: loop_left
    23: cdr
    108: unit
    63: not
    22: car
    102: set
    73: self
    92: key
    70: some
    40: ge
    85: contract
    62: none
    134: sapling_verify_update
    11: unit
    29: create_contract
    71: source
    50: le
    78: set_delegate
    107: timestamp
    119: self_address
    137: read_ticket
    13: unpack
    124: total_voting_power
    55: lt
    28: create_account
    46: if_left
    43: hash_key
    117: chain_id
    104: string
    126: sha3
    103: signature
    19: amount
    100: or
    77: transfer_tokens
    6: none
    35: empty_map
    110: address
    0: parameter
    9: some
    81: xor
    93: key_hash
    82: iter
    57: mem
    31: dip
    65: or
    94: lambda
    4: elt
    39: failwith
    58: mul
    26: concat
    21: balance
    101: pair
    32: drop
    74: steps_to_quota
    76: swap
    25: compare
    132: sapling_transaction
    135: ticket
    129: bls12_381_g2
    53: lsl
    91: int
    16: sha512
    30: implicit_account
    18: add
    130: bls12_381_fr
    99: option
    56: map
    109: operation
    123: voting_power
    24: check_signature
    133: sapling_empty_state
    75: sub
    96: map
    61: nil
    105: bytes
    144: view
    20: and
    15: sha256
    145: view
    69: size
    1: storage
    120: never
    98: nat
    48: int
    7: pair
    128: bls12_381_g1
    95: list
    14: blake2b
    142: chest_key
    112: dig
    113: dug
    3: false
    121: never
    72: sender
    44: if
    17: abs
  prim__1_arg__no_annots__id_012__psithaca__michelson__v1__primitives:
    2: code
    147: sub_mutez
    115: apply
    27: cons
    33: dup
    111: slice
    59: neg
    41: get
    38: exec
    89: bool
    84: address
    37: eq
    34: ediv
    143: open_chest
    88: rename
    86: isnat
    80: update
    140: get_and_update
    66: pair
    47: if_none
    64: now
    146: constant
    116: chain_id
    42: gt
    97: big_map
    67: push
    138: split_ticket
    122: unpair
    118: level
    139: join_tickets
    131: sapling_state
    114: empty_big_map
    54: lsr
    90: contract
    5: left
    52: loop
    136: ticket
    106: mutez
    49: lambda
    60: neq
    36: empty_set
    79: unit
    141: chest
    125: keccak
    45: if_cons
    12: pack
    8: right
    10: true
    87: cast
    51: left
    68: right
    127: pairing_check
    83: loop_left
    23: cdr
    108: unit
    63: not
    22: car
    102: set
    73: self
    92: key
    70: some
    40: ge
    85: contract
    62: none
    134: sapling_verify_update
    11: unit
    29: create_contract
    71: source
    50: le
    78: set_delegate
    107: timestamp
    119: self_address
    137: read_ticket
    13: unpack
    124: total_voting_power
    55: lt
    28: create_account
    46: if_left
    43: hash_key
    117: chain_id
    104: string
    126: sha3
    103: signature
    19: amount
    100: or
    77: transfer_tokens
    6: none
    35: empty_map
    110: address
    0: parameter
    9: some
    81: xor
    93: key_hash
    82: iter
    57: mem
    31: dip
    65: or
    94: lambda
    4: elt
    39: failwith
    58: mul
    26: concat
    21: balance
    101: pair
    32: drop
    74: steps_to_quota
    76: swap
    25: compare
    132: sapling_transaction
    135: ticket
    129: bls12_381_g2
    53: lsl
    91: int
    16: sha512
    30: implicit_account
    18: add
    130: bls12_381_fr
    99: option
    56: map
    109: operation
    123: voting_power
    24: check_signature
    133: sapling_empty_state
    75: sub
    96: map
    61: nil
    105: bytes
    144: view
    20: and
    15: sha256
    145: view
    69: size
    1: storage
    120: never
    98: nat
    48: int
    7: pair
    128: bls12_381_g1
    95: list
    14: blake2b
    142: chest_key
    112: dig
    113: dug
    3: false
    121: never
    72: sender
    44: if
    17: abs
  prim__no_args__some_annots__id_012__psithaca__michelson__v1__primitives:
    2: code
    147: sub_mutez
    115: apply
    27: cons
    33: dup
    111: slice
    59: neg
    41: get
    38: exec
    89: bool
    84: address
    37: eq
    34: ediv
    143: open_chest
    88: rename
    86: isnat
    80: update
    140: get_and_update
    66: pair
    47: if_none
    64: now
    146: constant
    116: chain_id
    42: gt
    97: big_map
    67: push
    138: split_ticket
    122: unpair
    118: level
    139: join_tickets
    131: sapling_state
    114: empty_big_map
    54: lsr
    90: contract
    5: left
    52: loop
    136: ticket
    106: mutez
    49: lambda
    60: neq
    36: empty_set
    79: unit
    141: chest
    125: keccak
    45: if_cons
    12: pack
    8: right
    10: true
    87: cast
    51: left
    68: right
    127: pairing_check
    83: loop_left
    23: cdr
    108: unit
    63: not
    22: car
    102: set
    73: self
    92: key
    70: some
    40: ge
    85: contract
    62: none
    134: sapling_verify_update
    11: unit
    29: create_contract
    71: source
    50: le
    78: set_delegate
    107: timestamp
    119: self_address
    137: read_ticket
    13: unpack
    124: total_voting_power
    55: lt
    28: create_account
    46: if_left
    43: hash_key
    117: chain_id
    104: string
    126: sha3
    103: signature
    19: amount
    100: or
    77: transfer_tokens
    6: none
    35: empty_map
    110: address
    0: parameter
    9: some
    81: xor
    93: key_hash
    82: iter
    57: mem
    31: dip
    65: or
    94: lambda
    4: elt
    39: failwith
    58: mul
    26: concat
    21: balance
    101: pair
    32: drop
    74: steps_to_quota
    76: swap
    25: compare
    132: sapling_transaction
    135: ticket
    129: bls12_381_g2
    53: lsl
    91: int
    16: sha512
    30: implicit_account
    18: add
    130: bls12_381_fr
    99: option
    56: map
    109: operation
    123: voting_power
    24: check_signature
    133: sapling_empty_state
    75: sub
    96: map
    61: nil
    105: bytes
    144: view
    20: and
    15: sha256
    145: view
    69: size
    1: storage
    120: never
    98: nat
    48: int
    7: pair
    128: bls12_381_g1
    95: list
    14: blake2b
    142: chest_key
    112: dig
    113: dug
    3: false
    121: never
    72: sender
    44: if
    17: abs
  prim__no_args__no_annots__id_012__psithaca__michelson__v1__primitives:
    2: code
    147: sub_mutez
    115: apply
    27: cons
    33: dup
    111: slice
    59: neg
    41: get
    38: exec
    89: bool
    84: address
    37: eq
    34: ediv
    143: open_chest
    88: rename
    86: isnat
    80: update
    140: get_and_update
    66: pair
    47: if_none
    64: now
    146: constant
    116: chain_id
    42: gt
    97: big_map
    67: push
    138: split_ticket
    122: unpair
    118: level
    139: join_tickets
    131: sapling_state
    114: empty_big_map
    54: lsr
    90: contract
    5: left
    52: loop
    136: ticket
    106: mutez
    49: lambda
    60: neq
    36: empty_set
    79: unit
    141: chest
    125: keccak
    45: if_cons
    12: pack
    8: right
    10: true
    87: cast
    51: left
    68: right
    127: pairing_check
    83: loop_left
    23: cdr
    108: unit
    63: not
    22: car
    102: set
    73: self
    92: key
    70: some
    40: ge
    85: contract
    62: none
    134: sapling_verify_update
    11: unit
    29: create_contract
    71: source
    50: le
    78: set_delegate
    107: timestamp
    119: self_address
    137: read_ticket
    13: unpack
    124: total_voting_power
    55: lt
    28: create_account
    46: if_left
    43: hash_key
    117: chain_id
    104: string
    126: sha3
    103: signature
    19: amount
    100: or
    77: transfer_tokens
    6: none
    35: empty_map
    110: address
    0: parameter
    9: some
    81: xor
    93: key_hash
    82: iter
    57: mem
    31: dip
    65: or
    94: lambda
    4: elt
    39: failwith
    58: mul
    26: concat
    21: balance
    101: pair
    32: drop
    74: steps_to_quota
    76: swap
    25: compare
    132: sapling_transaction
    135: ticket
    129: bls12_381_g2
    53: lsl
    91: int
    16: sha512
    30: implicit_account
    18: add
    130: bls12_381_fr
    99: option
    56: map
    109: operation
    123: voting_power
    24: check_signature
    133: sapling_empty_state
    75: sub
    96: map
    61: nil
    105: bytes
    144: view
    20: and
    15: sha256
    145: view
    69: size
    1: storage
    120: never
    98: nat
    48: int
    7: pair
    128: bls12_381_g1
    95: list
    14: blake2b
    142: chest_key
    112: dig
    113: dug
    3: false
    121: never
    72: sender
    44: if
    17: abs
  micheline__012__psithaca__michelson_v1__expression_tag:
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
- id: micheline__012__psithaca__michelson_v1__expression
  type: micheline__012__psithaca__michelson_v1__expression