meta:
  id: id_005__psbabym1__script__expr
  endian: be
doc: ! 'Encoding id: 005-PsBabyM1.script.expr'
types:
  micheline__005__psbabym1__michelson_v1__expression:
    seq:
    - id: micheline__005__psbabym1__michelson_v1__expression_tag
      type: u1
      enum: micheline__005__psbabym1__michelson_v1__expression_tag
    - id: int__micheline__005__psbabym1__michelson_v1__expression
      type: z
      if: (micheline__005__psbabym1__michelson_v1__expression_tag == micheline__005__psbabym1__michelson_v1__expression_tag::int)
    - id: string__micheline__005__psbabym1__michelson_v1__expression
      type: string__string
      if: (micheline__005__psbabym1__michelson_v1__expression_tag == micheline__005__psbabym1__michelson_v1__expression_tag::string)
    - id: sequence__micheline__005__psbabym1__michelson_v1__expression
      type: sequence__micheline__005__psbabym1__michelson_v1__expression
      if: (micheline__005__psbabym1__michelson_v1__expression_tag == micheline__005__psbabym1__michelson_v1__expression_tag::sequence)
    - id: prim__no_args__no_annots__micheline__005__psbabym1__michelson_v1__expression
      type: u1
      if: (micheline__005__psbabym1__michelson_v1__expression_tag == micheline__005__psbabym1__michelson_v1__expression_tag::prim__no_args__no_annots)
      enum: prim__no_args__no_annots__id_005__psbabym1__michelson__v1__primitives
    - id: prim__no_args__some_annots__micheline__005__psbabym1__michelson_v1__expression
      type: prim__no_args__some_annots__micheline__005__psbabym1__michelson_v1__expression
      if: (micheline__005__psbabym1__michelson_v1__expression_tag == micheline__005__psbabym1__michelson_v1__expression_tag::prim__no_args__some_annots)
    - id: prim__1_arg__no_annots__micheline__005__psbabym1__michelson_v1__expression
      type: prim__1_arg__no_annots__micheline__005__psbabym1__michelson_v1__expression
      if: (micheline__005__psbabym1__michelson_v1__expression_tag == micheline__005__psbabym1__michelson_v1__expression_tag::prim__1_arg__no_annots)
    - id: prim__1_arg__some_annots__micheline__005__psbabym1__michelson_v1__expression
      type: prim__1_arg__some_annots__micheline__005__psbabym1__michelson_v1__expression
      if: (micheline__005__psbabym1__michelson_v1__expression_tag == micheline__005__psbabym1__michelson_v1__expression_tag::prim__1_arg__some_annots)
    - id: prim__2_args__no_annots__micheline__005__psbabym1__michelson_v1__expression
      type: prim__2_args__no_annots__micheline__005__psbabym1__michelson_v1__expression
      if: (micheline__005__psbabym1__michelson_v1__expression_tag == micheline__005__psbabym1__michelson_v1__expression_tag::prim__2_args__no_annots)
    - id: prim__2_args__some_annots__micheline__005__psbabym1__michelson_v1__expression
      type: prim__2_args__some_annots__micheline__005__psbabym1__michelson_v1__expression
      if: (micheline__005__psbabym1__michelson_v1__expression_tag == micheline__005__psbabym1__michelson_v1__expression_tag::prim__2_args__some_annots)
    - id: prim__generic__micheline__005__psbabym1__michelson_v1__expression
      type: prim__generic__micheline__005__psbabym1__michelson_v1__expression
      if: (micheline__005__psbabym1__michelson_v1__expression_tag == micheline__005__psbabym1__michelson_v1__expression_tag::prim__generic)
    - id: bytes__micheline__005__psbabym1__michelson_v1__expression
      type: bytes__bytes
      if: (micheline__005__psbabym1__michelson_v1__expression_tag == micheline__005__psbabym1__michelson_v1__expression_tag::bytes)
  bytes__bytes:
    seq:
    - id: len_bytes
      type: u4
      valid:
        max: 1073741823
    - id: bytes
      size: len_bytes
  prim__generic__micheline__005__psbabym1__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__generic__id_005__psbabym1__michelson__v1__primitives
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
      type: micheline__005__psbabym1__michelson_v1__expression
  prim__2_args__some_annots__micheline__005__psbabym1__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__2_args__some_annots__id_005__psbabym1__michelson__v1__primitives
    - id: arg1
      type: micheline__005__psbabym1__michelson_v1__expression
    - id: arg2
      type: micheline__005__psbabym1__michelson_v1__expression
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
  prim__2_args__no_annots__micheline__005__psbabym1__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__2_args__no_annots__id_005__psbabym1__michelson__v1__primitives
    - id: arg1
      type: micheline__005__psbabym1__michelson_v1__expression
    - id: arg2
      type: micheline__005__psbabym1__michelson_v1__expression
  prim__1_arg__some_annots__micheline__005__psbabym1__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__1_arg__some_annots__id_005__psbabym1__michelson__v1__primitives
    - id: arg
      type: micheline__005__psbabym1__michelson_v1__expression
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
  prim__1_arg__no_annots__micheline__005__psbabym1__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__1_arg__no_annots__id_005__psbabym1__michelson__v1__primitives
    - id: arg
      type: micheline__005__psbabym1__michelson_v1__expression
  prim__no_args__some_annots__micheline__005__psbabym1__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: prim__no_args__some_annots__id_005__psbabym1__michelson__v1__primitives
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
  sequence__micheline__005__psbabym1__michelson_v1__expression:
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
      type: micheline__005__psbabym1__michelson_v1__expression
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
  prim__generic__id_005__psbabym1__michelson__v1__primitives:
    20: and
    2: code
    82: iter
    40: ge
    28: create_account
    34: ediv
    84: address
    7: pair
    79: unit
    63: not
    37: eq
    43: hash_key
    0: parameter
    39: failwith
    10: true
    109: operation
    88: rename
    89: bool
    115: apply
    112: dig
    61: nil
    35: empty_map
    32: drop
    108: unit
    93: key_hash
    69: size
    91: int
    87: cast
    5: left
    41: get
    70: some
    44: if
    62: none
    50: le
    27: cons
    22: car
    68: right
    45: if_cons
    72: sender
    106: mutez
    71: source
    33: dup
    80: update
    55: lt
    107: timestamp
    83: loop_left
    58: mul
    36: empty_set
    26: concat
    110: address
    6: none
    56: map
    57: mem
    104: string
    116: chain_id
    52: loop
    64: now
    38: exec
    86: isnat
    17: abs
    31: dip
    19: amount
    101: pair
    48: int
    60: neq
    13: unpack
    9: some
    11: unit
    99: option
    92: key
    25: compare
    94: lambda
    81: xor
    65: or
    54: lsr
    114: empty_big_map
    73: self
    113: dug
    103: signature
    21: balance
    117: chain_id
    16: sha512
    3: false
    67: push
    111: slice
    23: cdr
    77: transfer_tokens
    1: storage
    74: steps_to_quota
    51: left
    42: gt
    90: contract
    8: right
    66: pair
    95: list
    12: pack
    30: implicit_account
    75: sub
    53: lsl
    85: contract
    78: set_delegate
    15: sha256
    105: bytes
    14: blake2b
    100: or
    96: map
    97: big_map
    59: neg
    29: create_contract
    4: elt
    49: lambda
    46: if_left
    24: check_signature
    98: nat
    102: set
    76: swap
    47: if_none
    18: add
  prim__2_args__some_annots__id_005__psbabym1__michelson__v1__primitives:
    20: and
    2: code
    82: iter
    40: ge
    28: create_account
    34: ediv
    84: address
    7: pair
    79: unit
    63: not
    37: eq
    43: hash_key
    0: parameter
    39: failwith
    10: true
    109: operation
    88: rename
    89: bool
    115: apply
    112: dig
    61: nil
    35: empty_map
    32: drop
    108: unit
    93: key_hash
    69: size
    91: int
    87: cast
    5: left
    41: get
    70: some
    44: if
    62: none
    50: le
    27: cons
    22: car
    68: right
    45: if_cons
    72: sender
    106: mutez
    71: source
    33: dup
    80: update
    55: lt
    107: timestamp
    83: loop_left
    58: mul
    36: empty_set
    26: concat
    110: address
    6: none
    56: map
    57: mem
    104: string
    116: chain_id
    52: loop
    64: now
    38: exec
    86: isnat
    17: abs
    31: dip
    19: amount
    101: pair
    48: int
    60: neq
    13: unpack
    9: some
    11: unit
    99: option
    92: key
    25: compare
    94: lambda
    81: xor
    65: or
    54: lsr
    114: empty_big_map
    73: self
    113: dug
    103: signature
    21: balance
    117: chain_id
    16: sha512
    3: false
    67: push
    111: slice
    23: cdr
    77: transfer_tokens
    1: storage
    74: steps_to_quota
    51: left
    42: gt
    90: contract
    8: right
    66: pair
    95: list
    12: pack
    30: implicit_account
    75: sub
    53: lsl
    85: contract
    78: set_delegate
    15: sha256
    105: bytes
    14: blake2b
    100: or
    96: map
    97: big_map
    59: neg
    29: create_contract
    4: elt
    49: lambda
    46: if_left
    24: check_signature
    98: nat
    102: set
    76: swap
    47: if_none
    18: add
  prim__2_args__no_annots__id_005__psbabym1__michelson__v1__primitives:
    20: and
    2: code
    82: iter
    40: ge
    28: create_account
    34: ediv
    84: address
    7: pair
    79: unit
    63: not
    37: eq
    43: hash_key
    0: parameter
    39: failwith
    10: true
    109: operation
    88: rename
    89: bool
    115: apply
    112: dig
    61: nil
    35: empty_map
    32: drop
    108: unit
    93: key_hash
    69: size
    91: int
    87: cast
    5: left
    41: get
    70: some
    44: if
    62: none
    50: le
    27: cons
    22: car
    68: right
    45: if_cons
    72: sender
    106: mutez
    71: source
    33: dup
    80: update
    55: lt
    107: timestamp
    83: loop_left
    58: mul
    36: empty_set
    26: concat
    110: address
    6: none
    56: map
    57: mem
    104: string
    116: chain_id
    52: loop
    64: now
    38: exec
    86: isnat
    17: abs
    31: dip
    19: amount
    101: pair
    48: int
    60: neq
    13: unpack
    9: some
    11: unit
    99: option
    92: key
    25: compare
    94: lambda
    81: xor
    65: or
    54: lsr
    114: empty_big_map
    73: self
    113: dug
    103: signature
    21: balance
    117: chain_id
    16: sha512
    3: false
    67: push
    111: slice
    23: cdr
    77: transfer_tokens
    1: storage
    74: steps_to_quota
    51: left
    42: gt
    90: contract
    8: right
    66: pair
    95: list
    12: pack
    30: implicit_account
    75: sub
    53: lsl
    85: contract
    78: set_delegate
    15: sha256
    105: bytes
    14: blake2b
    100: or
    96: map
    97: big_map
    59: neg
    29: create_contract
    4: elt
    49: lambda
    46: if_left
    24: check_signature
    98: nat
    102: set
    76: swap
    47: if_none
    18: add
  prim__1_arg__some_annots__id_005__psbabym1__michelson__v1__primitives:
    20: and
    2: code
    82: iter
    40: ge
    28: create_account
    34: ediv
    84: address
    7: pair
    79: unit
    63: not
    37: eq
    43: hash_key
    0: parameter
    39: failwith
    10: true
    109: operation
    88: rename
    89: bool
    115: apply
    112: dig
    61: nil
    35: empty_map
    32: drop
    108: unit
    93: key_hash
    69: size
    91: int
    87: cast
    5: left
    41: get
    70: some
    44: if
    62: none
    50: le
    27: cons
    22: car
    68: right
    45: if_cons
    72: sender
    106: mutez
    71: source
    33: dup
    80: update
    55: lt
    107: timestamp
    83: loop_left
    58: mul
    36: empty_set
    26: concat
    110: address
    6: none
    56: map
    57: mem
    104: string
    116: chain_id
    52: loop
    64: now
    38: exec
    86: isnat
    17: abs
    31: dip
    19: amount
    101: pair
    48: int
    60: neq
    13: unpack
    9: some
    11: unit
    99: option
    92: key
    25: compare
    94: lambda
    81: xor
    65: or
    54: lsr
    114: empty_big_map
    73: self
    113: dug
    103: signature
    21: balance
    117: chain_id
    16: sha512
    3: false
    67: push
    111: slice
    23: cdr
    77: transfer_tokens
    1: storage
    74: steps_to_quota
    51: left
    42: gt
    90: contract
    8: right
    66: pair
    95: list
    12: pack
    30: implicit_account
    75: sub
    53: lsl
    85: contract
    78: set_delegate
    15: sha256
    105: bytes
    14: blake2b
    100: or
    96: map
    97: big_map
    59: neg
    29: create_contract
    4: elt
    49: lambda
    46: if_left
    24: check_signature
    98: nat
    102: set
    76: swap
    47: if_none
    18: add
  prim__1_arg__no_annots__id_005__psbabym1__michelson__v1__primitives:
    20: and
    2: code
    82: iter
    40: ge
    28: create_account
    34: ediv
    84: address
    7: pair
    79: unit
    63: not
    37: eq
    43: hash_key
    0: parameter
    39: failwith
    10: true
    109: operation
    88: rename
    89: bool
    115: apply
    112: dig
    61: nil
    35: empty_map
    32: drop
    108: unit
    93: key_hash
    69: size
    91: int
    87: cast
    5: left
    41: get
    70: some
    44: if
    62: none
    50: le
    27: cons
    22: car
    68: right
    45: if_cons
    72: sender
    106: mutez
    71: source
    33: dup
    80: update
    55: lt
    107: timestamp
    83: loop_left
    58: mul
    36: empty_set
    26: concat
    110: address
    6: none
    56: map
    57: mem
    104: string
    116: chain_id
    52: loop
    64: now
    38: exec
    86: isnat
    17: abs
    31: dip
    19: amount
    101: pair
    48: int
    60: neq
    13: unpack
    9: some
    11: unit
    99: option
    92: key
    25: compare
    94: lambda
    81: xor
    65: or
    54: lsr
    114: empty_big_map
    73: self
    113: dug
    103: signature
    21: balance
    117: chain_id
    16: sha512
    3: false
    67: push
    111: slice
    23: cdr
    77: transfer_tokens
    1: storage
    74: steps_to_quota
    51: left
    42: gt
    90: contract
    8: right
    66: pair
    95: list
    12: pack
    30: implicit_account
    75: sub
    53: lsl
    85: contract
    78: set_delegate
    15: sha256
    105: bytes
    14: blake2b
    100: or
    96: map
    97: big_map
    59: neg
    29: create_contract
    4: elt
    49: lambda
    46: if_left
    24: check_signature
    98: nat
    102: set
    76: swap
    47: if_none
    18: add
  prim__no_args__some_annots__id_005__psbabym1__michelson__v1__primitives:
    20: and
    2: code
    82: iter
    40: ge
    28: create_account
    34: ediv
    84: address
    7: pair
    79: unit
    63: not
    37: eq
    43: hash_key
    0: parameter
    39: failwith
    10: true
    109: operation
    88: rename
    89: bool
    115: apply
    112: dig
    61: nil
    35: empty_map
    32: drop
    108: unit
    93: key_hash
    69: size
    91: int
    87: cast
    5: left
    41: get
    70: some
    44: if
    62: none
    50: le
    27: cons
    22: car
    68: right
    45: if_cons
    72: sender
    106: mutez
    71: source
    33: dup
    80: update
    55: lt
    107: timestamp
    83: loop_left
    58: mul
    36: empty_set
    26: concat
    110: address
    6: none
    56: map
    57: mem
    104: string
    116: chain_id
    52: loop
    64: now
    38: exec
    86: isnat
    17: abs
    31: dip
    19: amount
    101: pair
    48: int
    60: neq
    13: unpack
    9: some
    11: unit
    99: option
    92: key
    25: compare
    94: lambda
    81: xor
    65: or
    54: lsr
    114: empty_big_map
    73: self
    113: dug
    103: signature
    21: balance
    117: chain_id
    16: sha512
    3: false
    67: push
    111: slice
    23: cdr
    77: transfer_tokens
    1: storage
    74: steps_to_quota
    51: left
    42: gt
    90: contract
    8: right
    66: pair
    95: list
    12: pack
    30: implicit_account
    75: sub
    53: lsl
    85: contract
    78: set_delegate
    15: sha256
    105: bytes
    14: blake2b
    100: or
    96: map
    97: big_map
    59: neg
    29: create_contract
    4: elt
    49: lambda
    46: if_left
    24: check_signature
    98: nat
    102: set
    76: swap
    47: if_none
    18: add
  prim__no_args__no_annots__id_005__psbabym1__michelson__v1__primitives:
    20: and
    2: code
    82: iter
    40: ge
    28: create_account
    34: ediv
    84: address
    7: pair
    79: unit
    63: not
    37: eq
    43: hash_key
    0: parameter
    39: failwith
    10: true
    109: operation
    88: rename
    89: bool
    115: apply
    112: dig
    61: nil
    35: empty_map
    32: drop
    108: unit
    93: key_hash
    69: size
    91: int
    87: cast
    5: left
    41: get
    70: some
    44: if
    62: none
    50: le
    27: cons
    22: car
    68: right
    45: if_cons
    72: sender
    106: mutez
    71: source
    33: dup
    80: update
    55: lt
    107: timestamp
    83: loop_left
    58: mul
    36: empty_set
    26: concat
    110: address
    6: none
    56: map
    57: mem
    104: string
    116: chain_id
    52: loop
    64: now
    38: exec
    86: isnat
    17: abs
    31: dip
    19: amount
    101: pair
    48: int
    60: neq
    13: unpack
    9: some
    11: unit
    99: option
    92: key
    25: compare
    94: lambda
    81: xor
    65: or
    54: lsr
    114: empty_big_map
    73: self
    113: dug
    103: signature
    21: balance
    117: chain_id
    16: sha512
    3: false
    67: push
    111: slice
    23: cdr
    77: transfer_tokens
    1: storage
    74: steps_to_quota
    51: left
    42: gt
    90: contract
    8: right
    66: pair
    95: list
    12: pack
    30: implicit_account
    75: sub
    53: lsl
    85: contract
    78: set_delegate
    15: sha256
    105: bytes
    14: blake2b
    100: or
    96: map
    97: big_map
    59: neg
    29: create_contract
    4: elt
    49: lambda
    46: if_left
    24: check_signature
    98: nat
    102: set
    76: swap
    47: if_none
    18: add
  micheline__005__psbabym1__michelson_v1__expression_tag:
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
- id: micheline__005__psbabym1__michelson_v1__expression
  type: micheline__005__psbabym1__michelson_v1__expression
