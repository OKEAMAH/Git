meta:
  id: id_007__psdelph1__contract__big_map_diff
  endian: be
doc: ! 'Encoding id: 007-PsDELPH1.contract.big_map_diff'
types:
  id_007__psdelph1__contract__big_map_diff_entries:
    seq:
    - id: id_007__psdelph1__contract__big_map_diff_elt_tag
      type: u1
      enum: id_007__psdelph1__contract__big_map_diff_elt_tag
    - id: update__id_007__psdelph1__contract__big_map_diff_elt
      type: update__id_007__psdelph1__contract__big_map_diff_elt
      if: (id_007__psdelph1__contract__big_map_diff_elt_tag == id_007__psdelph1__contract__big_map_diff_elt_tag::update)
    - id: remove__id_007__psdelph1__contract__big_map_diff_elt
      type: z
      if: (id_007__psdelph1__contract__big_map_diff_elt_tag == id_007__psdelph1__contract__big_map_diff_elt_tag::remove)
    - id: copy__id_007__psdelph1__contract__big_map_diff_elt
      type: copy__id_007__psdelph1__contract__big_map_diff_elt
      if: (id_007__psdelph1__contract__big_map_diff_elt_tag == id_007__psdelph1__contract__big_map_diff_elt_tag::copy)
    - id: alloc__id_007__psdelph1__contract__big_map_diff_elt
      type: alloc__id_007__psdelph1__contract__big_map_diff_elt
      if: (id_007__psdelph1__contract__big_map_diff_elt_tag == id_007__psdelph1__contract__big_map_diff_elt_tag::alloc)
  alloc__id_007__psdelph1__contract__big_map_diff_elt:
    seq:
    - id: big_map
      type: z
    - id: key_type
      type: micheline__007__psdelph1__michelson_v1__expression
    - id: value_type
      type: micheline__007__psdelph1__michelson_v1__expression
  copy__id_007__psdelph1__contract__big_map_diff_elt:
    seq:
    - id: source_big_map
      type: z
    - id: destination_big_map
      type: z
  update__id_007__psdelph1__contract__big_map_diff_elt:
    seq:
    - id: big_map
      type: z
    - id: key_hash
      size: 32
    - id: key
      type: update__micheline__007__psdelph1__michelson_v1__expression
    - id: value_tag
      type: u1
      enum: bool
    - id: value
      type: micheline__007__psdelph1__michelson_v1__expression
      if: (value_tag == bool::true)
  update__micheline__007__psdelph1__michelson_v1__expression:
    seq:
    - id: micheline__007__psdelph1__michelson_v1__expression_tag
      type: u1
      enum: micheline__007__psdelph1__michelson_v1__expression_tag
    - id: update__int__micheline__007__psdelph1__michelson_v1__expression
      type: z
      if: (micheline__007__psdelph1__michelson_v1__expression_tag == micheline__007__psdelph1__michelson_v1__expression_tag::int)
    - id: update__string__micheline__007__psdelph1__michelson_v1__expression
      type: update__string__string
      if: (micheline__007__psdelph1__michelson_v1__expression_tag == micheline__007__psdelph1__michelson_v1__expression_tag::string)
    - id: update__sequence__micheline__007__psdelph1__michelson_v1__expression
      type: update__sequence__micheline__007__psdelph1__michelson_v1__expression
      if: (micheline__007__psdelph1__michelson_v1__expression_tag == micheline__007__psdelph1__michelson_v1__expression_tag::sequence)
    - id: update__prim__no_args__no_annots__micheline__007__psdelph1__michelson_v1__expression
      type: u1
      if: (micheline__007__psdelph1__michelson_v1__expression_tag == micheline__007__psdelph1__michelson_v1__expression_tag::prim__no_args__no_annots)
      enum: update__prim__no_args__no_annots__id_007__psdelph1__michelson__v1__primitives
    - id: update__prim__no_args__some_annots__micheline__007__psdelph1__michelson_v1__expression
      type: update__prim__no_args__some_annots__micheline__007__psdelph1__michelson_v1__expression
      if: (micheline__007__psdelph1__michelson_v1__expression_tag == micheline__007__psdelph1__michelson_v1__expression_tag::prim__no_args__some_annots)
    - id: update__prim__1_arg__no_annots__micheline__007__psdelph1__michelson_v1__expression
      type: update__prim__1_arg__no_annots__micheline__007__psdelph1__michelson_v1__expression
      if: (micheline__007__psdelph1__michelson_v1__expression_tag == micheline__007__psdelph1__michelson_v1__expression_tag::prim__1_arg__no_annots)
    - id: update__prim__1_arg__some_annots__micheline__007__psdelph1__michelson_v1__expression
      type: update__prim__1_arg__some_annots__micheline__007__psdelph1__michelson_v1__expression
      if: (micheline__007__psdelph1__michelson_v1__expression_tag == micheline__007__psdelph1__michelson_v1__expression_tag::prim__1_arg__some_annots)
    - id: update__prim__2_args__no_annots__micheline__007__psdelph1__michelson_v1__expression
      type: update__prim__2_args__no_annots__micheline__007__psdelph1__michelson_v1__expression
      if: (micheline__007__psdelph1__michelson_v1__expression_tag == micheline__007__psdelph1__michelson_v1__expression_tag::prim__2_args__no_annots)
    - id: update__prim__2_args__some_annots__micheline__007__psdelph1__michelson_v1__expression
      type: update__prim__2_args__some_annots__micheline__007__psdelph1__michelson_v1__expression
      if: (micheline__007__psdelph1__michelson_v1__expression_tag == micheline__007__psdelph1__michelson_v1__expression_tag::prim__2_args__some_annots)
    - id: update__prim__generic__micheline__007__psdelph1__michelson_v1__expression
      type: update__prim__generic__micheline__007__psdelph1__michelson_v1__expression
      if: (micheline__007__psdelph1__michelson_v1__expression_tag == micheline__007__psdelph1__michelson_v1__expression_tag::prim__generic)
    - id: update__bytes__micheline__007__psdelph1__michelson_v1__expression
      type: update__bytes__bytes
      if: (micheline__007__psdelph1__michelson_v1__expression_tag == micheline__007__psdelph1__michelson_v1__expression_tag::bytes)
  update__bytes__bytes:
    seq:
    - id: len_bytes
      type: u4
      valid:
        max: 1073741823
    - id: bytes
      size: len_bytes
  update__prim__generic__micheline__007__psdelph1__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: update__prim__generic__id_007__psdelph1__michelson__v1__primitives
    - id: update__prim__generic__args
      type: update__prim__generic__args
    - id: update__prim__generic__annots
      type: update__prim__generic__annots
  update__prim__generic__annots:
    seq:
    - id: len_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: len_annots
  update__prim__generic__args:
    seq:
    - id: len_args
      type: u4
      valid:
        max: 1073741823
    - id: args
      type: update__prim__generic__args_entries
      size: len_args
      repeat: eos
  update__prim__generic__args_entries:
    seq:
    - id: args_elt
      type: micheline__007__psdelph1__michelson_v1__expression
  update__prim__2_args__some_annots__micheline__007__psdelph1__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: update__prim__2_args__some_annots__id_007__psdelph1__michelson__v1__primitives
    - id: arg1
      type: micheline__007__psdelph1__michelson_v1__expression
    - id: arg2
      type: micheline__007__psdelph1__michelson_v1__expression
    - id: update__prim__2_args__some_annots__annots
      type: update__prim__2_args__some_annots__annots
  update__prim__2_args__some_annots__annots:
    seq:
    - id: len_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: len_annots
  update__prim__2_args__no_annots__micheline__007__psdelph1__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: update__prim__2_args__no_annots__id_007__psdelph1__michelson__v1__primitives
    - id: arg1
      type: micheline__007__psdelph1__michelson_v1__expression
    - id: arg2
      type: micheline__007__psdelph1__michelson_v1__expression
  update__prim__1_arg__some_annots__micheline__007__psdelph1__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: update__prim__1_arg__some_annots__id_007__psdelph1__michelson__v1__primitives
    - id: arg
      type: micheline__007__psdelph1__michelson_v1__expression
    - id: update__prim__1_arg__some_annots__annots
      type: update__prim__1_arg__some_annots__annots
  update__prim__1_arg__some_annots__annots:
    seq:
    - id: len_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: len_annots
  update__prim__1_arg__no_annots__micheline__007__psdelph1__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: update__prim__1_arg__no_annots__id_007__psdelph1__michelson__v1__primitives
    - id: arg
      type: micheline__007__psdelph1__michelson_v1__expression
  update__prim__no_args__some_annots__micheline__007__psdelph1__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: update__prim__no_args__some_annots__id_007__psdelph1__michelson__v1__primitives
    - id: update__prim__no_args__some_annots__annots
      type: update__prim__no_args__some_annots__annots
  update__prim__no_args__some_annots__annots:
    seq:
    - id: len_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: len_annots
  update__sequence__micheline__007__psdelph1__michelson_v1__expression:
    seq:
    - id: len_sequence
      type: u4
      valid:
        max: 1073741823
    - id: sequence
      type: update__sequence__sequence_entries
      size: len_sequence
      repeat: eos
  update__sequence__sequence_entries:
    seq:
    - id: sequence_elt
      type: micheline__007__psdelph1__michelson_v1__expression
  update__string__string:
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
  update__prim__generic__id_007__psdelph1__michelson__v1__primitives:
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
  update__prim__2_args__some_annots__id_007__psdelph1__michelson__v1__primitives:
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
  update__prim__2_args__no_annots__id_007__psdelph1__michelson__v1__primitives:
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
  update__prim__1_arg__some_annots__id_007__psdelph1__michelson__v1__primitives:
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
  update__prim__1_arg__no_annots__id_007__psdelph1__michelson__v1__primitives:
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
  update__prim__no_args__some_annots__id_007__psdelph1__michelson__v1__primitives:
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
  update__prim__no_args__no_annots__id_007__psdelph1__michelson__v1__primitives:
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
  micheline__007__psdelph1__michelson_v1__expression_tag:
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
  id_007__psdelph1__contract__big_map_diff_elt_tag:
    0: update
    1: remove
    2: copy
    3: alloc
seq:
- id: len_id_007__psdelph1__contract__big_map_diff
  type: u4
  valid:
    max: 1073741823
- id: id_007__psdelph1__contract__big_map_diff
  type: id_007__psdelph1__contract__big_map_diff_entries
  size: len_id_007__psdelph1__contract__big_map_diff
  repeat: eos
