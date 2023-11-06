meta:
  id: id_008__ptedo2zk__script__expr
  endian: be
doc: ! 'Encoding id: 008-PtEdo2Zk.script.expr'
types:
  micheline__008__ptedo2zk__michelson_v1__expression:
    seq:
    - id: micheline__008__ptedo2zk__michelson_v1__expression_tag
      type: u1
      enum: micheline__008__ptedo2zk__michelson_v1__expression_tag
    - id: bytes__micheline__008__ptedo2zk__michelson_v1__expression
      type: bytes__bytes
      if: (micheline__008__ptedo2zk__michelson_v1__expression_tag == ::micheline__008__ptedo2zk__michelson_v1__expression_tag::micheline__008__ptedo2zk__michelson_v1__expression_tag::bytes)
  bytes__bytes:
    seq:
    - id: len_bytes
      type: u4
      valid:
        max: 1073741823
    - id: bytes
      size: len_bytes
  prim__generic__micheline__008__ptedo2zk__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__generic__id_008__ptedo2zk__michelson__v1__primitives
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
      type: micheline__008__ptedo2zk__michelson_v1__expression
  prim__2_args__some_annots__micheline__008__ptedo2zk__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__2_args__some_annots__id_008__ptedo2zk__michelson__v1__primitives
    - id: arg1
      type: micheline__008__ptedo2zk__michelson_v1__expression
    - id: arg2
      type: micheline__008__ptedo2zk__michelson_v1__expression
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
  prim__2_args__no_annots__micheline__008__ptedo2zk__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__2_args__no_annots__id_008__ptedo2zk__michelson__v1__primitives
    - id: arg1
      type: micheline__008__ptedo2zk__michelson_v1__expression
    - id: arg2
      type: micheline__008__ptedo2zk__michelson_v1__expression
  prim__1_arg__some_annots__micheline__008__ptedo2zk__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__1_arg__some_annots__id_008__ptedo2zk__michelson__v1__primitives
    - id: arg
      type: micheline__008__ptedo2zk__michelson_v1__expression
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
  prim__1_arg__no_annots__micheline__008__ptedo2zk__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__1_arg__no_annots__id_008__ptedo2zk__michelson__v1__primitives
    - id: arg
      type: micheline__008__ptedo2zk__michelson_v1__expression
  prim__no_args__some_annots__micheline__008__ptedo2zk__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__no_args__some_annots__id_008__ptedo2zk__michelson__v1__primitives
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
  sequence__micheline__008__ptedo2zk__michelson_v1__expression:
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
      type: micheline__008__ptedo2zk__michelson_v1__expression
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
  prim__generic__id_008__ptedo2zk__michelson__v1__primitives:
    2: code
    78: set_delegate
    40: ge
    28: create_account
    34: ediv
    75: sub
    61: nil
    42: gt
    39: failwith
    93: key_hash
    87: cast
    115: apply
    35: empty_map
    112: dig
    92: key
    133: sapling_empty_state
    83: loop_left
    67: push
    43: hash_key
    49: lambda
    66: pair
    130: bls12_381_fr
    44: if
    101: pair
    69: size
    90: contract
    68: right
    53: lsl
    129: bls12_381_g2
    91: int
    56: map
    36: empty_set
    94: lambda
    6: none
    54: lsr
    139: join_tickets
    110: address
    51: left
    62: none
    38: exec
    82: iter
    136: ticket
    47: if_none
    13: unpack
    9: some
    11: unit
    134: sapling_verify_update
    52: loop
    70: some
    138: split_ticket
    86: isnat
    117: chain_id
    131: sapling_state
    65: or
    23: cdr
    111: slice
    106: mutez
    96: map
    72: sender
    140: get_and_update
    88: rename
    64: now
    121: never
    12: pack
    30: implicit_account
    118: level
    73: self
    81: xor
    132: sapling_transaction
    74: steps_to_quota
    89: bool
    14: blake2b
    127: pairing_check
    57: mem
    29: create_contract
    48: int
    45: if_cons
    24: check_signature
    108: unit
    137: read_ticket
    107: timestamp
    20: and
    104: string
    80: update
    7: pair
    37: eq
    120: never
    0: parameter
    10: true
    84: address
    97: big_map
    85: contract
    59: neg
    32: drop
    122: unpair
    98: nat
    5: left
    41: get
    60: neq
    27: cons
    22: car
    105: bytes
    33: dup
    76: swap
    79: unit
    26: concat
    128: bls12_381_g1
    55: lt
    95: list
    17: abs
    31: dip
    19: amount
    103: signature
    58: mul
    116: chain_id
    126: sha3
    25: compare
    113: dug
    77: transfer_tokens
    100: or
    63: not
    109: operation
    114: empty_big_map
    21: balance
    16: sha512
    3: false
    71: source
    1: storage
    135: ticket
    102: set
    50: le
    8: right
    99: option
    15: sha256
    123: voting_power
    124: total_voting_power
    4: elt
    125: keccak
    119: self_address
    46: if_left
    18: add
  prim__2_args__some_annots__id_008__ptedo2zk__michelson__v1__primitives:
    2: code
    78: set_delegate
    40: ge
    28: create_account
    34: ediv
    75: sub
    61: nil
    42: gt
    39: failwith
    93: key_hash
    87: cast
    115: apply
    35: empty_map
    112: dig
    92: key
    133: sapling_empty_state
    83: loop_left
    67: push
    43: hash_key
    49: lambda
    66: pair
    130: bls12_381_fr
    44: if
    101: pair
    69: size
    90: contract
    68: right
    53: lsl
    129: bls12_381_g2
    91: int
    56: map
    36: empty_set
    94: lambda
    6: none
    54: lsr
    139: join_tickets
    110: address
    51: left
    62: none
    38: exec
    82: iter
    136: ticket
    47: if_none
    13: unpack
    9: some
    11: unit
    134: sapling_verify_update
    52: loop
    70: some
    138: split_ticket
    86: isnat
    117: chain_id
    131: sapling_state
    65: or
    23: cdr
    111: slice
    106: mutez
    96: map
    72: sender
    140: get_and_update
    88: rename
    64: now
    121: never
    12: pack
    30: implicit_account
    118: level
    73: self
    81: xor
    132: sapling_transaction
    74: steps_to_quota
    89: bool
    14: blake2b
    127: pairing_check
    57: mem
    29: create_contract
    48: int
    45: if_cons
    24: check_signature
    108: unit
    137: read_ticket
    107: timestamp
    20: and
    104: string
    80: update
    7: pair
    37: eq
    120: never
    0: parameter
    10: true
    84: address
    97: big_map
    85: contract
    59: neg
    32: drop
    122: unpair
    98: nat
    5: left
    41: get
    60: neq
    27: cons
    22: car
    105: bytes
    33: dup
    76: swap
    79: unit
    26: concat
    128: bls12_381_g1
    55: lt
    95: list
    17: abs
    31: dip
    19: amount
    103: signature
    58: mul
    116: chain_id
    126: sha3
    25: compare
    113: dug
    77: transfer_tokens
    100: or
    63: not
    109: operation
    114: empty_big_map
    21: balance
    16: sha512
    3: false
    71: source
    1: storage
    135: ticket
    102: set
    50: le
    8: right
    99: option
    15: sha256
    123: voting_power
    124: total_voting_power
    4: elt
    125: keccak
    119: self_address
    46: if_left
    18: add
  prim__2_args__no_annots__id_008__ptedo2zk__michelson__v1__primitives:
    2: code
    78: set_delegate
    40: ge
    28: create_account
    34: ediv
    75: sub
    61: nil
    42: gt
    39: failwith
    93: key_hash
    87: cast
    115: apply
    35: empty_map
    112: dig
    92: key
    133: sapling_empty_state
    83: loop_left
    67: push
    43: hash_key
    49: lambda
    66: pair
    130: bls12_381_fr
    44: if
    101: pair
    69: size
    90: contract
    68: right
    53: lsl
    129: bls12_381_g2
    91: int
    56: map
    36: empty_set
    94: lambda
    6: none
    54: lsr
    139: join_tickets
    110: address
    51: left
    62: none
    38: exec
    82: iter
    136: ticket
    47: if_none
    13: unpack
    9: some
    11: unit
    134: sapling_verify_update
    52: loop
    70: some
    138: split_ticket
    86: isnat
    117: chain_id
    131: sapling_state
    65: or
    23: cdr
    111: slice
    106: mutez
    96: map
    72: sender
    140: get_and_update
    88: rename
    64: now
    121: never
    12: pack
    30: implicit_account
    118: level
    73: self
    81: xor
    132: sapling_transaction
    74: steps_to_quota
    89: bool
    14: blake2b
    127: pairing_check
    57: mem
    29: create_contract
    48: int
    45: if_cons
    24: check_signature
    108: unit
    137: read_ticket
    107: timestamp
    20: and
    104: string
    80: update
    7: pair
    37: eq
    120: never
    0: parameter
    10: true
    84: address
    97: big_map
    85: contract
    59: neg
    32: drop
    122: unpair
    98: nat
    5: left
    41: get
    60: neq
    27: cons
    22: car
    105: bytes
    33: dup
    76: swap
    79: unit
    26: concat
    128: bls12_381_g1
    55: lt
    95: list
    17: abs
    31: dip
    19: amount
    103: signature
    58: mul
    116: chain_id
    126: sha3
    25: compare
    113: dug
    77: transfer_tokens
    100: or
    63: not
    109: operation
    114: empty_big_map
    21: balance
    16: sha512
    3: false
    71: source
    1: storage
    135: ticket
    102: set
    50: le
    8: right
    99: option
    15: sha256
    123: voting_power
    124: total_voting_power
    4: elt
    125: keccak
    119: self_address
    46: if_left
    18: add
  prim__1_arg__some_annots__id_008__ptedo2zk__michelson__v1__primitives:
    2: code
    78: set_delegate
    40: ge
    28: create_account
    34: ediv
    75: sub
    61: nil
    42: gt
    39: failwith
    93: key_hash
    87: cast
    115: apply
    35: empty_map
    112: dig
    92: key
    133: sapling_empty_state
    83: loop_left
    67: push
    43: hash_key
    49: lambda
    66: pair
    130: bls12_381_fr
    44: if
    101: pair
    69: size
    90: contract
    68: right
    53: lsl
    129: bls12_381_g2
    91: int
    56: map
    36: empty_set
    94: lambda
    6: none
    54: lsr
    139: join_tickets
    110: address
    51: left
    62: none
    38: exec
    82: iter
    136: ticket
    47: if_none
    13: unpack
    9: some
    11: unit
    134: sapling_verify_update
    52: loop
    70: some
    138: split_ticket
    86: isnat
    117: chain_id
    131: sapling_state
    65: or
    23: cdr
    111: slice
    106: mutez
    96: map
    72: sender
    140: get_and_update
    88: rename
    64: now
    121: never
    12: pack
    30: implicit_account
    118: level
    73: self
    81: xor
    132: sapling_transaction
    74: steps_to_quota
    89: bool
    14: blake2b
    127: pairing_check
    57: mem
    29: create_contract
    48: int
    45: if_cons
    24: check_signature
    108: unit
    137: read_ticket
    107: timestamp
    20: and
    104: string
    80: update
    7: pair
    37: eq
    120: never
    0: parameter
    10: true
    84: address
    97: big_map
    85: contract
    59: neg
    32: drop
    122: unpair
    98: nat
    5: left
    41: get
    60: neq
    27: cons
    22: car
    105: bytes
    33: dup
    76: swap
    79: unit
    26: concat
    128: bls12_381_g1
    55: lt
    95: list
    17: abs
    31: dip
    19: amount
    103: signature
    58: mul
    116: chain_id
    126: sha3
    25: compare
    113: dug
    77: transfer_tokens
    100: or
    63: not
    109: operation
    114: empty_big_map
    21: balance
    16: sha512
    3: false
    71: source
    1: storage
    135: ticket
    102: set
    50: le
    8: right
    99: option
    15: sha256
    123: voting_power
    124: total_voting_power
    4: elt
    125: keccak
    119: self_address
    46: if_left
    18: add
  prim__1_arg__no_annots__id_008__ptedo2zk__michelson__v1__primitives:
    2: code
    78: set_delegate
    40: ge
    28: create_account
    34: ediv
    75: sub
    61: nil
    42: gt
    39: failwith
    93: key_hash
    87: cast
    115: apply
    35: empty_map
    112: dig
    92: key
    133: sapling_empty_state
    83: loop_left
    67: push
    43: hash_key
    49: lambda
    66: pair
    130: bls12_381_fr
    44: if
    101: pair
    69: size
    90: contract
    68: right
    53: lsl
    129: bls12_381_g2
    91: int
    56: map
    36: empty_set
    94: lambda
    6: none
    54: lsr
    139: join_tickets
    110: address
    51: left
    62: none
    38: exec
    82: iter
    136: ticket
    47: if_none
    13: unpack
    9: some
    11: unit
    134: sapling_verify_update
    52: loop
    70: some
    138: split_ticket
    86: isnat
    117: chain_id
    131: sapling_state
    65: or
    23: cdr
    111: slice
    106: mutez
    96: map
    72: sender
    140: get_and_update
    88: rename
    64: now
    121: never
    12: pack
    30: implicit_account
    118: level
    73: self
    81: xor
    132: sapling_transaction
    74: steps_to_quota
    89: bool
    14: blake2b
    127: pairing_check
    57: mem
    29: create_contract
    48: int
    45: if_cons
    24: check_signature
    108: unit
    137: read_ticket
    107: timestamp
    20: and
    104: string
    80: update
    7: pair
    37: eq
    120: never
    0: parameter
    10: true
    84: address
    97: big_map
    85: contract
    59: neg
    32: drop
    122: unpair
    98: nat
    5: left
    41: get
    60: neq
    27: cons
    22: car
    105: bytes
    33: dup
    76: swap
    79: unit
    26: concat
    128: bls12_381_g1
    55: lt
    95: list
    17: abs
    31: dip
    19: amount
    103: signature
    58: mul
    116: chain_id
    126: sha3
    25: compare
    113: dug
    77: transfer_tokens
    100: or
    63: not
    109: operation
    114: empty_big_map
    21: balance
    16: sha512
    3: false
    71: source
    1: storage
    135: ticket
    102: set
    50: le
    8: right
    99: option
    15: sha256
    123: voting_power
    124: total_voting_power
    4: elt
    125: keccak
    119: self_address
    46: if_left
    18: add
  prim__no_args__some_annots__id_008__ptedo2zk__michelson__v1__primitives:
    2: code
    78: set_delegate
    40: ge
    28: create_account
    34: ediv
    75: sub
    61: nil
    42: gt
    39: failwith
    93: key_hash
    87: cast
    115: apply
    35: empty_map
    112: dig
    92: key
    133: sapling_empty_state
    83: loop_left
    67: push
    43: hash_key
    49: lambda
    66: pair
    130: bls12_381_fr
    44: if
    101: pair
    69: size
    90: contract
    68: right
    53: lsl
    129: bls12_381_g2
    91: int
    56: map
    36: empty_set
    94: lambda
    6: none
    54: lsr
    139: join_tickets
    110: address
    51: left
    62: none
    38: exec
    82: iter
    136: ticket
    47: if_none
    13: unpack
    9: some
    11: unit
    134: sapling_verify_update
    52: loop
    70: some
    138: split_ticket
    86: isnat
    117: chain_id
    131: sapling_state
    65: or
    23: cdr
    111: slice
    106: mutez
    96: map
    72: sender
    140: get_and_update
    88: rename
    64: now
    121: never
    12: pack
    30: implicit_account
    118: level
    73: self
    81: xor
    132: sapling_transaction
    74: steps_to_quota
    89: bool
    14: blake2b
    127: pairing_check
    57: mem
    29: create_contract
    48: int
    45: if_cons
    24: check_signature
    108: unit
    137: read_ticket
    107: timestamp
    20: and
    104: string
    80: update
    7: pair
    37: eq
    120: never
    0: parameter
    10: true
    84: address
    97: big_map
    85: contract
    59: neg
    32: drop
    122: unpair
    98: nat
    5: left
    41: get
    60: neq
    27: cons
    22: car
    105: bytes
    33: dup
    76: swap
    79: unit
    26: concat
    128: bls12_381_g1
    55: lt
    95: list
    17: abs
    31: dip
    19: amount
    103: signature
    58: mul
    116: chain_id
    126: sha3
    25: compare
    113: dug
    77: transfer_tokens
    100: or
    63: not
    109: operation
    114: empty_big_map
    21: balance
    16: sha512
    3: false
    71: source
    1: storage
    135: ticket
    102: set
    50: le
    8: right
    99: option
    15: sha256
    123: voting_power
    124: total_voting_power
    4: elt
    125: keccak
    119: self_address
    46: if_left
    18: add
  prim__no_args__no_annots__id_008__ptedo2zk__michelson__v1__primitives:
    2: code
    78: set_delegate
    40: ge
    28: create_account
    34: ediv
    75: sub
    61: nil
    42: gt
    39: failwith
    93: key_hash
    87: cast
    115: apply
    35: empty_map
    112: dig
    92: key
    133: sapling_empty_state
    83: loop_left
    67: push
    43: hash_key
    49: lambda
    66: pair
    130: bls12_381_fr
    44: if
    101: pair
    69: size
    90: contract
    68: right
    53: lsl
    129: bls12_381_g2
    91: int
    56: map
    36: empty_set
    94: lambda
    6: none
    54: lsr
    139: join_tickets
    110: address
    51: left
    62: none
    38: exec
    82: iter
    136: ticket
    47: if_none
    13: unpack
    9: some
    11: unit
    134: sapling_verify_update
    52: loop
    70: some
    138: split_ticket
    86: isnat
    117: chain_id
    131: sapling_state
    65: or
    23: cdr
    111: slice
    106: mutez
    96: map
    72: sender
    140: get_and_update
    88: rename
    64: now
    121: never
    12: pack
    30: implicit_account
    118: level
    73: self
    81: xor
    132: sapling_transaction
    74: steps_to_quota
    89: bool
    14: blake2b
    127: pairing_check
    57: mem
    29: create_contract
    48: int
    45: if_cons
    24: check_signature
    108: unit
    137: read_ticket
    107: timestamp
    20: and
    104: string
    80: update
    7: pair
    37: eq
    120: never
    0: parameter
    10: true
    84: address
    97: big_map
    85: contract
    59: neg
    32: drop
    122: unpair
    98: nat
    5: left
    41: get
    60: neq
    27: cons
    22: car
    105: bytes
    33: dup
    76: swap
    79: unit
    26: concat
    128: bls12_381_g1
    55: lt
    95: list
    17: abs
    31: dip
    19: amount
    103: signature
    58: mul
    116: chain_id
    126: sha3
    25: compare
    113: dug
    77: transfer_tokens
    100: or
    63: not
    109: operation
    114: empty_big_map
    21: balance
    16: sha512
    3: false
    71: source
    1: storage
    135: ticket
    102: set
    50: le
    8: right
    99: option
    15: sha256
    123: voting_power
    124: total_voting_power
    4: elt
    125: keccak
    119: self_address
    46: if_left
    18: add
  micheline__008__ptedo2zk__michelson_v1__expression_tag:
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
- id: micheline__008__ptedo2zk__michelson_v1__expression
  type: micheline__008__ptedo2zk__michelson_v1__expression
