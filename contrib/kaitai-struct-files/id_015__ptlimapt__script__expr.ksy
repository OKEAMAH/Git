meta:
  id: id_015__ptlimapt__script__expr
  endian: be
doc: ! 'Encoding id: 015-PtLimaPt.script.expr'
types:
  micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: micheline__015__ptlimapt__michelson_v1__expression_tag
      type: u1
      enum: micheline__015__ptlimapt__michelson_v1__expression_tag
    - id: int__micheline__015__ptlimapt__michelson_v1__expression
      type: z
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == ::micheline__015__ptlimapt__michelson_v1__expression_tag::micheline__015__ptlimapt__michelson_v1__expression_tag::int)
    - id: string__micheline__015__ptlimapt__michelson_v1__expression
      type: string__string
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == ::micheline__015__ptlimapt__michelson_v1__expression_tag::micheline__015__ptlimapt__michelson_v1__expression_tag::string)
    - id: sequence__micheline__015__ptlimapt__michelson_v1__expression
      type: sequence__micheline__015__ptlimapt__michelson_v1__expression
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::sequence)
    - id: prim__no_args__no_annots__micheline__015__ptlimapt__michelson_v1__expression
      type: u1
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == ::micheline__015__ptlimapt__michelson_v1__expression_tag::micheline__015__ptlimapt__michelson_v1__expression_tag::prim__no_args__no_annots)
      enum: prim__no_args__no_annots__id_015__ptlimapt__michelson__v1__primitives
    - id: prim__no_args__some_annots__micheline__015__ptlimapt__michelson_v1__expression
      type: prim__no_args__some_annots__micheline__015__ptlimapt__michelson_v1__expression
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::prim__no_args__some_annots)
    - id: prim__1_arg__no_annots__micheline__015__ptlimapt__michelson_v1__expression
      type: prim__1_arg__no_annots__micheline__015__ptlimapt__michelson_v1__expression
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::prim__1_arg__no_annots)
    - id: prim__1_arg__some_annots__micheline__015__ptlimapt__michelson_v1__expression
      type: prim__1_arg__some_annots__micheline__015__ptlimapt__michelson_v1__expression
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::prim__1_arg__some_annots)
    - id: prim__2_args__no_annots__micheline__015__ptlimapt__michelson_v1__expression
      type: prim__2_args__no_annots__micheline__015__ptlimapt__michelson_v1__expression
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::prim__2_args__no_annots)
    - id: prim__2_args__some_annots__micheline__015__ptlimapt__michelson_v1__expression
      type: prim__2_args__some_annots__micheline__015__ptlimapt__michelson_v1__expression
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::prim__2_args__some_annots)
    - id: prim__generic__micheline__015__ptlimapt__michelson_v1__expression
      type: prim__generic__micheline__015__ptlimapt__michelson_v1__expression
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::prim__generic)
    - id: bytes__micheline__015__ptlimapt__michelson_v1__expression
      type: bytes__bytes
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == ::micheline__015__ptlimapt__michelson_v1__expression_tag::micheline__015__ptlimapt__michelson_v1__expression_tag::bytes)
  bytes__bytes:
    seq:
    - id: len_bytes
      type: u4
      valid:
        max: 1073741823
    - id: bytes
      size: len_bytes
  prim__generic__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__generic__id_015__ptlimapt__michelson__v1__primitives
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
      type: micheline__015__ptlimapt__michelson_v1__expression
  prim__2_args__some_annots__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__2_args__some_annots__id_015__ptlimapt__michelson__v1__primitives
    - id: arg1
      type: micheline__015__ptlimapt__michelson_v1__expression
    - id: arg2
      type: micheline__015__ptlimapt__michelson_v1__expression
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
  prim__2_args__no_annots__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__2_args__no_annots__id_015__ptlimapt__michelson__v1__primitives
    - id: arg1
      type: micheline__015__ptlimapt__michelson_v1__expression
    - id: arg2
      type: micheline__015__ptlimapt__michelson_v1__expression
  prim__1_arg__some_annots__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__1_arg__some_annots__id_015__ptlimapt__michelson__v1__primitives
    - id: arg
      type: micheline__015__ptlimapt__michelson_v1__expression
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
  prim__1_arg__no_annots__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__1_arg__no_annots__id_015__ptlimapt__michelson__v1__primitives
    - id: arg
      type: micheline__015__ptlimapt__michelson_v1__expression
  prim__no_args__some_annots__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__no_args__some_annots__id_015__ptlimapt__michelson__v1__primitives
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
  sequence__micheline__015__ptlimapt__michelson_v1__expression:
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
      type: micheline__015__ptlimapt__michelson_v1__expression
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
  prim__generic__id_015__ptlimapt__michelson__v1__primitives:
    2: code
    111: slice
    38: exec
    26: concat
    32: drop
    72: sender
    57: mem
    40: ge
    37: eq
    137: read_ticket
    129: bls12_381_g2
    81: xor
    36: empty_set
    144: view
    136: ticket_deprecated
    85: contract
    83: loop_left
    77: transfer_tokens
    64: now
    41: get
    46: if_left
    62: none
    120: never
    108: unit
    140: get_and_update
    92: key
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    107: timestamp
    52: loop
    34: ediv
    135: ticket
    146: constant
    138: split_ticket
    5: left
    51: left
    125: keccak
    101: pair
    48: int
    58: mul
    35: empty_map
    76: swap
    116: chain_id
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    66: pair
    124: total_voting_power
    80: update
    22: car
    103: signature
    61: nil
    21: balance
    97: big_map
    70: some
    143: open_chest
    67: push
    39: failwith
    82: iter
    60: neq
    87: cast
    11: unit
    28: create_account
    68: right
    49: lambda
    147: sub_mutez
    102: set
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    99: option
    123: voting_power
    98: nat
    18: add
    95: list
    75: sub
    6: none
    114: empty_big_map
    141: chest
    105: bytes
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    89: bool
    4: elt
    115: apply
    56: map
    128: bls12_381_g1
    25: compare
    20: and
    96: map
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    106: mutez
    148: tx_rollup_l2_address
    132: sapling_transaction_deprecated
    130: bls12_381_fr
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    150: sapling_transaction
    94: lambda
    54: lsr
    104: string
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    91: int
    59: neg
    100: or
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    109: operation
    93: key_hash
    47: if_none
    7: pair
    142: chest_key
    110: address
    90: contract
    13: unpack
    131: sapling_state
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  prim__2_args__some_annots__id_015__ptlimapt__michelson__v1__primitives:
    2: code
    111: slice
    38: exec
    26: concat
    32: drop
    72: sender
    57: mem
    40: ge
    37: eq
    137: read_ticket
    129: bls12_381_g2
    81: xor
    36: empty_set
    144: view
    136: ticket_deprecated
    85: contract
    83: loop_left
    77: transfer_tokens
    64: now
    41: get
    46: if_left
    62: none
    120: never
    108: unit
    140: get_and_update
    92: key
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    107: timestamp
    52: loop
    34: ediv
    135: ticket
    146: constant
    138: split_ticket
    5: left
    51: left
    125: keccak
    101: pair
    48: int
    58: mul
    35: empty_map
    76: swap
    116: chain_id
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    66: pair
    124: total_voting_power
    80: update
    22: car
    103: signature
    61: nil
    21: balance
    97: big_map
    70: some
    143: open_chest
    67: push
    39: failwith
    82: iter
    60: neq
    87: cast
    11: unit
    28: create_account
    68: right
    49: lambda
    147: sub_mutez
    102: set
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    99: option
    123: voting_power
    98: nat
    18: add
    95: list
    75: sub
    6: none
    114: empty_big_map
    141: chest
    105: bytes
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    89: bool
    4: elt
    115: apply
    56: map
    128: bls12_381_g1
    25: compare
    20: and
    96: map
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    106: mutez
    148: tx_rollup_l2_address
    132: sapling_transaction_deprecated
    130: bls12_381_fr
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    150: sapling_transaction
    94: lambda
    54: lsr
    104: string
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    91: int
    59: neg
    100: or
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    109: operation
    93: key_hash
    47: if_none
    7: pair
    142: chest_key
    110: address
    90: contract
    13: unpack
    131: sapling_state
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  prim__2_args__no_annots__id_015__ptlimapt__michelson__v1__primitives:
    2: code
    111: slice
    38: exec
    26: concat
    32: drop
    72: sender
    57: mem
    40: ge
    37: eq
    137: read_ticket
    129: bls12_381_g2
    81: xor
    36: empty_set
    144: view
    136: ticket_deprecated
    85: contract
    83: loop_left
    77: transfer_tokens
    64: now
    41: get
    46: if_left
    62: none
    120: never
    108: unit
    140: get_and_update
    92: key
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    107: timestamp
    52: loop
    34: ediv
    135: ticket
    146: constant
    138: split_ticket
    5: left
    51: left
    125: keccak
    101: pair
    48: int
    58: mul
    35: empty_map
    76: swap
    116: chain_id
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    66: pair
    124: total_voting_power
    80: update
    22: car
    103: signature
    61: nil
    21: balance
    97: big_map
    70: some
    143: open_chest
    67: push
    39: failwith
    82: iter
    60: neq
    87: cast
    11: unit
    28: create_account
    68: right
    49: lambda
    147: sub_mutez
    102: set
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    99: option
    123: voting_power
    98: nat
    18: add
    95: list
    75: sub
    6: none
    114: empty_big_map
    141: chest
    105: bytes
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    89: bool
    4: elt
    115: apply
    56: map
    128: bls12_381_g1
    25: compare
    20: and
    96: map
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    106: mutez
    148: tx_rollup_l2_address
    132: sapling_transaction_deprecated
    130: bls12_381_fr
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    150: sapling_transaction
    94: lambda
    54: lsr
    104: string
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    91: int
    59: neg
    100: or
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    109: operation
    93: key_hash
    47: if_none
    7: pair
    142: chest_key
    110: address
    90: contract
    13: unpack
    131: sapling_state
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  prim__1_arg__some_annots__id_015__ptlimapt__michelson__v1__primitives:
    2: code
    111: slice
    38: exec
    26: concat
    32: drop
    72: sender
    57: mem
    40: ge
    37: eq
    137: read_ticket
    129: bls12_381_g2
    81: xor
    36: empty_set
    144: view
    136: ticket_deprecated
    85: contract
    83: loop_left
    77: transfer_tokens
    64: now
    41: get
    46: if_left
    62: none
    120: never
    108: unit
    140: get_and_update
    92: key
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    107: timestamp
    52: loop
    34: ediv
    135: ticket
    146: constant
    138: split_ticket
    5: left
    51: left
    125: keccak
    101: pair
    48: int
    58: mul
    35: empty_map
    76: swap
    116: chain_id
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    66: pair
    124: total_voting_power
    80: update
    22: car
    103: signature
    61: nil
    21: balance
    97: big_map
    70: some
    143: open_chest
    67: push
    39: failwith
    82: iter
    60: neq
    87: cast
    11: unit
    28: create_account
    68: right
    49: lambda
    147: sub_mutez
    102: set
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    99: option
    123: voting_power
    98: nat
    18: add
    95: list
    75: sub
    6: none
    114: empty_big_map
    141: chest
    105: bytes
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    89: bool
    4: elt
    115: apply
    56: map
    128: bls12_381_g1
    25: compare
    20: and
    96: map
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    106: mutez
    148: tx_rollup_l2_address
    132: sapling_transaction_deprecated
    130: bls12_381_fr
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    150: sapling_transaction
    94: lambda
    54: lsr
    104: string
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    91: int
    59: neg
    100: or
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    109: operation
    93: key_hash
    47: if_none
    7: pair
    142: chest_key
    110: address
    90: contract
    13: unpack
    131: sapling_state
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  prim__1_arg__no_annots__id_015__ptlimapt__michelson__v1__primitives:
    2: code
    111: slice
    38: exec
    26: concat
    32: drop
    72: sender
    57: mem
    40: ge
    37: eq
    137: read_ticket
    129: bls12_381_g2
    81: xor
    36: empty_set
    144: view
    136: ticket_deprecated
    85: contract
    83: loop_left
    77: transfer_tokens
    64: now
    41: get
    46: if_left
    62: none
    120: never
    108: unit
    140: get_and_update
    92: key
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    107: timestamp
    52: loop
    34: ediv
    135: ticket
    146: constant
    138: split_ticket
    5: left
    51: left
    125: keccak
    101: pair
    48: int
    58: mul
    35: empty_map
    76: swap
    116: chain_id
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    66: pair
    124: total_voting_power
    80: update
    22: car
    103: signature
    61: nil
    21: balance
    97: big_map
    70: some
    143: open_chest
    67: push
    39: failwith
    82: iter
    60: neq
    87: cast
    11: unit
    28: create_account
    68: right
    49: lambda
    147: sub_mutez
    102: set
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    99: option
    123: voting_power
    98: nat
    18: add
    95: list
    75: sub
    6: none
    114: empty_big_map
    141: chest
    105: bytes
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    89: bool
    4: elt
    115: apply
    56: map
    128: bls12_381_g1
    25: compare
    20: and
    96: map
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    106: mutez
    148: tx_rollup_l2_address
    132: sapling_transaction_deprecated
    130: bls12_381_fr
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    150: sapling_transaction
    94: lambda
    54: lsr
    104: string
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    91: int
    59: neg
    100: or
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    109: operation
    93: key_hash
    47: if_none
    7: pair
    142: chest_key
    110: address
    90: contract
    13: unpack
    131: sapling_state
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  prim__no_args__some_annots__id_015__ptlimapt__michelson__v1__primitives:
    2: code
    111: slice
    38: exec
    26: concat
    32: drop
    72: sender
    57: mem
    40: ge
    37: eq
    137: read_ticket
    129: bls12_381_g2
    81: xor
    36: empty_set
    144: view
    136: ticket_deprecated
    85: contract
    83: loop_left
    77: transfer_tokens
    64: now
    41: get
    46: if_left
    62: none
    120: never
    108: unit
    140: get_and_update
    92: key
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    107: timestamp
    52: loop
    34: ediv
    135: ticket
    146: constant
    138: split_ticket
    5: left
    51: left
    125: keccak
    101: pair
    48: int
    58: mul
    35: empty_map
    76: swap
    116: chain_id
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    66: pair
    124: total_voting_power
    80: update
    22: car
    103: signature
    61: nil
    21: balance
    97: big_map
    70: some
    143: open_chest
    67: push
    39: failwith
    82: iter
    60: neq
    87: cast
    11: unit
    28: create_account
    68: right
    49: lambda
    147: sub_mutez
    102: set
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    99: option
    123: voting_power
    98: nat
    18: add
    95: list
    75: sub
    6: none
    114: empty_big_map
    141: chest
    105: bytes
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    89: bool
    4: elt
    115: apply
    56: map
    128: bls12_381_g1
    25: compare
    20: and
    96: map
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    106: mutez
    148: tx_rollup_l2_address
    132: sapling_transaction_deprecated
    130: bls12_381_fr
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    150: sapling_transaction
    94: lambda
    54: lsr
    104: string
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    91: int
    59: neg
    100: or
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    109: operation
    93: key_hash
    47: if_none
    7: pair
    142: chest_key
    110: address
    90: contract
    13: unpack
    131: sapling_state
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  prim__no_args__no_annots__id_015__ptlimapt__michelson__v1__primitives:
    2: code
    111: slice
    38: exec
    26: concat
    32: drop
    72: sender
    57: mem
    40: ge
    37: eq
    137: read_ticket
    129: bls12_381_g2
    81: xor
    36: empty_set
    144: view
    136: ticket_deprecated
    85: contract
    83: loop_left
    77: transfer_tokens
    64: now
    41: get
    46: if_left
    62: none
    120: never
    108: unit
    140: get_and_update
    92: key
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    107: timestamp
    52: loop
    34: ediv
    135: ticket
    146: constant
    138: split_ticket
    5: left
    51: left
    125: keccak
    101: pair
    48: int
    58: mul
    35: empty_map
    76: swap
    116: chain_id
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    66: pair
    124: total_voting_power
    80: update
    22: car
    103: signature
    61: nil
    21: balance
    97: big_map
    70: some
    143: open_chest
    67: push
    39: failwith
    82: iter
    60: neq
    87: cast
    11: unit
    28: create_account
    68: right
    49: lambda
    147: sub_mutez
    102: set
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    99: option
    123: voting_power
    98: nat
    18: add
    95: list
    75: sub
    6: none
    114: empty_big_map
    141: chest
    105: bytes
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    89: bool
    4: elt
    115: apply
    56: map
    128: bls12_381_g1
    25: compare
    20: and
    96: map
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    106: mutez
    148: tx_rollup_l2_address
    132: sapling_transaction_deprecated
    130: bls12_381_fr
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    150: sapling_transaction
    94: lambda
    54: lsr
    104: string
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    91: int
    59: neg
    100: or
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    109: operation
    93: key_hash
    47: if_none
    7: pair
    142: chest_key
    110: address
    90: contract
    13: unpack
    131: sapling_state
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  micheline__015__ptlimapt__michelson_v1__expression_tag:
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
- id: micheline__015__ptlimapt__michelson_v1__expression
  type: micheline__015__ptlimapt__michelson_v1__expression
