meta:
  id: id_006__pscartha__contract__big_map_diff
  endian: be
doc: ! 'Encoding id: 006-PsCARTHA.contract.big_map_diff'
types:
  id_006__pscartha__contract__big_map_diff_entries:
    seq:
    - id: id_006__pscartha__contract__big_map_diff_elt_tag
      type: u1
      enum: id_006__pscartha__contract__big_map_diff_elt_tag
    - id: update__id_006__pscartha__contract__big_map_diff_elt
      type: update__id_006__pscartha__contract__big_map_diff_elt
      if: (id_006__pscartha__contract__big_map_diff_elt_tag == id_006__pscartha__contract__big_map_diff_elt_tag::update)
    - id: remove__id_006__pscartha__contract__big_map_diff_elt
      type: z
      if: (id_006__pscartha__contract__big_map_diff_elt_tag == id_006__pscartha__contract__big_map_diff_elt_tag::remove)
    - id: copy__id_006__pscartha__contract__big_map_diff_elt
      type: copy__id_006__pscartha__contract__big_map_diff_elt
      if: (id_006__pscartha__contract__big_map_diff_elt_tag == id_006__pscartha__contract__big_map_diff_elt_tag::copy)
    - id: alloc__id_006__pscartha__contract__big_map_diff_elt
      type: alloc__id_006__pscartha__contract__big_map_diff_elt
      if: (id_006__pscartha__contract__big_map_diff_elt_tag == id_006__pscartha__contract__big_map_diff_elt_tag::alloc)
  alloc__id_006__pscartha__contract__big_map_diff_elt:
    seq:
    - id: big_map
      type: z
    - id: key_type
      type: micheline__006__pscartha__michelson_v1__expression
    - id: value_type
      type: micheline__006__pscartha__michelson_v1__expression
  copy__id_006__pscartha__contract__big_map_diff_elt:
    seq:
    - id: source_big_map
      type: z
    - id: destination_big_map
      type: z
  update__id_006__pscartha__contract__big_map_diff_elt:
    seq:
    - id: big_map
      type: z
    - id: key_hash
      size: 32
    - id: key
      type: update__micheline__006__pscartha__michelson_v1__expression
    - id: value_tag
      type: u1
      enum: bool
    - id: value
      type: micheline__006__pscartha__michelson_v1__expression
      if: (value_tag == bool::true)
  update__micheline__006__pscartha__michelson_v1__expression:
    seq:
    - id: micheline__006__pscartha__michelson_v1__expression_tag
      type: u1
      enum: micheline__006__pscartha__michelson_v1__expression_tag
    - id: update__int__micheline__006__pscartha__michelson_v1__expression
      type: z
      if: (micheline__006__pscartha__michelson_v1__expression_tag == micheline__006__pscartha__michelson_v1__expression_tag::int)
    - id: update__string__micheline__006__pscartha__michelson_v1__expression
      type: update__string__string
      if: (micheline__006__pscartha__michelson_v1__expression_tag == micheline__006__pscartha__michelson_v1__expression_tag::string)
    - id: update__sequence__micheline__006__pscartha__michelson_v1__expression
      type: update__sequence__micheline__006__pscartha__michelson_v1__expression
      if: (micheline__006__pscartha__michelson_v1__expression_tag == micheline__006__pscartha__michelson_v1__expression_tag::sequence)
    - id: update__prim__no_args__no_annots__micheline__006__pscartha__michelson_v1__expression
      type: u1
      if: (micheline__006__pscartha__michelson_v1__expression_tag == micheline__006__pscartha__michelson_v1__expression_tag::prim__no_args__no_annots)
      enum: update__prim__no_args__no_annots__id_006__pscartha__michelson__v1__primitives
    - id: update__prim__no_args__some_annots__micheline__006__pscartha__michelson_v1__expression
      type: update__prim__no_args__some_annots__micheline__006__pscartha__michelson_v1__expression
      if: (micheline__006__pscartha__michelson_v1__expression_tag == micheline__006__pscartha__michelson_v1__expression_tag::prim__no_args__some_annots)
    - id: update__prim__1_arg__no_annots__micheline__006__pscartha__michelson_v1__expression
      type: update__prim__1_arg__no_annots__micheline__006__pscartha__michelson_v1__expression
      if: (micheline__006__pscartha__michelson_v1__expression_tag == micheline__006__pscartha__michelson_v1__expression_tag::prim__1_arg__no_annots)
    - id: update__prim__1_arg__some_annots__micheline__006__pscartha__michelson_v1__expression
      type: update__prim__1_arg__some_annots__micheline__006__pscartha__michelson_v1__expression
      if: (micheline__006__pscartha__michelson_v1__expression_tag == micheline__006__pscartha__michelson_v1__expression_tag::prim__1_arg__some_annots)
    - id: update__prim__2_args__no_annots__micheline__006__pscartha__michelson_v1__expression
      type: update__prim__2_args__no_annots__micheline__006__pscartha__michelson_v1__expression
      if: (micheline__006__pscartha__michelson_v1__expression_tag == micheline__006__pscartha__michelson_v1__expression_tag::prim__2_args__no_annots)
    - id: update__prim__2_args__some_annots__micheline__006__pscartha__michelson_v1__expression
      type: update__prim__2_args__some_annots__micheline__006__pscartha__michelson_v1__expression
      if: (micheline__006__pscartha__michelson_v1__expression_tag == micheline__006__pscartha__michelson_v1__expression_tag::prim__2_args__some_annots)
    - id: update__prim__generic__micheline__006__pscartha__michelson_v1__expression
      type: update__prim__generic__micheline__006__pscartha__michelson_v1__expression
      if: (micheline__006__pscartha__michelson_v1__expression_tag == micheline__006__pscartha__michelson_v1__expression_tag::prim__generic)
    - id: update__bytes__micheline__006__pscartha__michelson_v1__expression
      type: update__bytes__bytes
      if: (micheline__006__pscartha__michelson_v1__expression_tag == micheline__006__pscartha__michelson_v1__expression_tag::bytes)
  update__bytes__bytes:
    seq:
    - id: len_bytes
      type: u4
      valid:
        max: 1073741823
    - id: bytes
      size: len_bytes
  update__prim__generic__micheline__006__pscartha__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: update__prim__generic__id_006__pscartha__michelson__v1__primitives
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
      type: micheline__006__pscartha__michelson_v1__expression
  update__prim__2_args__some_annots__micheline__006__pscartha__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: update__prim__2_args__some_annots__id_006__pscartha__michelson__v1__primitives
    - id: arg1
      type: micheline__006__pscartha__michelson_v1__expression
    - id: arg2
      type: micheline__006__pscartha__michelson_v1__expression
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
  update__prim__2_args__no_annots__micheline__006__pscartha__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: update__prim__2_args__no_annots__id_006__pscartha__michelson__v1__primitives
    - id: arg1
      type: micheline__006__pscartha__michelson_v1__expression
    - id: arg2
      type: micheline__006__pscartha__michelson_v1__expression
  update__prim__1_arg__some_annots__micheline__006__pscartha__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: update__prim__1_arg__some_annots__id_006__pscartha__michelson__v1__primitives
    - id: arg
      type: micheline__006__pscartha__michelson_v1__expression
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
  update__prim__1_arg__no_annots__micheline__006__pscartha__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: update__prim__1_arg__no_annots__id_006__pscartha__michelson__v1__primitives
    - id: arg
      type: micheline__006__pscartha__michelson_v1__expression
  update__prim__no_args__some_annots__micheline__006__pscartha__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: update__prim__no_args__some_annots__id_006__pscartha__michelson__v1__primitives
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
  update__sequence__micheline__006__pscartha__michelson_v1__expression:
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
      type: micheline__006__pscartha__michelson_v1__expression
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
  update__prim__generic__id_006__pscartha__michelson__v1__primitives:
    0: parameter
    1: storage
    2: code
    3: false
    4: elt
    5: left
    6: none
    7: pair
    8: right
    9: some
    10: true
    11: unit
    12: pack
    13: unpack
    14: blake2b
    15: sha256
    16: sha512
    17: abs
    18: add
    19: amount
    20: and
    21: balance
    22: car
    23: cdr
    24: check_signature
    25: compare
    26: concat
    27: cons
    28: create_account
    29: create_contract
    30: implicit_account
    31: dip
    32: drop
    33: dup
    34: ediv
    35: empty_map
    36: empty_set
    37: eq
    38: exec
    39: failwith
    40: ge
    41: get
    42: gt
    43: hash_key
    44: if
    45: if_cons
    46: if_left
    47: if_none
    48: int
    49: lambda
    50: le
    51: left
    52: loop
    53: lsl
    54: lsr
    55: lt
    56: map
    57: mem
    58: mul
    59: neg
    60: neq
    61: nil
    62: none
    63: not
    64: now
    65: or
    66: pair
    67: push
    68: right
    69: size
    70: some
    71: source
    72: sender
    73: self
    74: steps_to_quota
    75: sub
    76: swap
    77: transfer_tokens
    78: set_delegate
    79: unit
    80: update
    81: xor
    82: iter
    83: loop_left
    84: address
    85: contract
    86: isnat
    87: cast
    88: rename
    89: bool
    90: contract
    91: int
    92: key
    93: key_hash
    94: lambda
    95: list
    96: map
    97: big_map
    98: nat
    99: option
    100: or
    101: pair
    102: set
    103: signature
    104: string
    105: bytes
    106: mutez
    107: timestamp
    108: unit
    109: operation
    110: address
    111: slice
    112: dig
    113: dug
    114: empty_big_map
    115: apply
    116: chain_id
    117: chain_id
  update__prim__2_args__some_annots__id_006__pscartha__michelson__v1__primitives:
    0: parameter
    1: storage
    2: code
    3: false
    4: elt
    5: left
    6: none
    7: pair
    8: right
    9: some
    10: true
    11: unit
    12: pack
    13: unpack
    14: blake2b
    15: sha256
    16: sha512
    17: abs
    18: add
    19: amount
    20: and
    21: balance
    22: car
    23: cdr
    24: check_signature
    25: compare
    26: concat
    27: cons
    28: create_account
    29: create_contract
    30: implicit_account
    31: dip
    32: drop
    33: dup
    34: ediv
    35: empty_map
    36: empty_set
    37: eq
    38: exec
    39: failwith
    40: ge
    41: get
    42: gt
    43: hash_key
    44: if
    45: if_cons
    46: if_left
    47: if_none
    48: int
    49: lambda
    50: le
    51: left
    52: loop
    53: lsl
    54: lsr
    55: lt
    56: map
    57: mem
    58: mul
    59: neg
    60: neq
    61: nil
    62: none
    63: not
    64: now
    65: or
    66: pair
    67: push
    68: right
    69: size
    70: some
    71: source
    72: sender
    73: self
    74: steps_to_quota
    75: sub
    76: swap
    77: transfer_tokens
    78: set_delegate
    79: unit
    80: update
    81: xor
    82: iter
    83: loop_left
    84: address
    85: contract
    86: isnat
    87: cast
    88: rename
    89: bool
    90: contract
    91: int
    92: key
    93: key_hash
    94: lambda
    95: list
    96: map
    97: big_map
    98: nat
    99: option
    100: or
    101: pair
    102: set
    103: signature
    104: string
    105: bytes
    106: mutez
    107: timestamp
    108: unit
    109: operation
    110: address
    111: slice
    112: dig
    113: dug
    114: empty_big_map
    115: apply
    116: chain_id
    117: chain_id
  update__prim__2_args__no_annots__id_006__pscartha__michelson__v1__primitives:
    0: parameter
    1: storage
    2: code
    3: false
    4: elt
    5: left
    6: none
    7: pair
    8: right
    9: some
    10: true
    11: unit
    12: pack
    13: unpack
    14: blake2b
    15: sha256
    16: sha512
    17: abs
    18: add
    19: amount
    20: and
    21: balance
    22: car
    23: cdr
    24: check_signature
    25: compare
    26: concat
    27: cons
    28: create_account
    29: create_contract
    30: implicit_account
    31: dip
    32: drop
    33: dup
    34: ediv
    35: empty_map
    36: empty_set
    37: eq
    38: exec
    39: failwith
    40: ge
    41: get
    42: gt
    43: hash_key
    44: if
    45: if_cons
    46: if_left
    47: if_none
    48: int
    49: lambda
    50: le
    51: left
    52: loop
    53: lsl
    54: lsr
    55: lt
    56: map
    57: mem
    58: mul
    59: neg
    60: neq
    61: nil
    62: none
    63: not
    64: now
    65: or
    66: pair
    67: push
    68: right
    69: size
    70: some
    71: source
    72: sender
    73: self
    74: steps_to_quota
    75: sub
    76: swap
    77: transfer_tokens
    78: set_delegate
    79: unit
    80: update
    81: xor
    82: iter
    83: loop_left
    84: address
    85: contract
    86: isnat
    87: cast
    88: rename
    89: bool
    90: contract
    91: int
    92: key
    93: key_hash
    94: lambda
    95: list
    96: map
    97: big_map
    98: nat
    99: option
    100: or
    101: pair
    102: set
    103: signature
    104: string
    105: bytes
    106: mutez
    107: timestamp
    108: unit
    109: operation
    110: address
    111: slice
    112: dig
    113: dug
    114: empty_big_map
    115: apply
    116: chain_id
    117: chain_id
  update__prim__1_arg__some_annots__id_006__pscartha__michelson__v1__primitives:
    0: parameter
    1: storage
    2: code
    3: false
    4: elt
    5: left
    6: none
    7: pair
    8: right
    9: some
    10: true
    11: unit
    12: pack
    13: unpack
    14: blake2b
    15: sha256
    16: sha512
    17: abs
    18: add
    19: amount
    20: and
    21: balance
    22: car
    23: cdr
    24: check_signature
    25: compare
    26: concat
    27: cons
    28: create_account
    29: create_contract
    30: implicit_account
    31: dip
    32: drop
    33: dup
    34: ediv
    35: empty_map
    36: empty_set
    37: eq
    38: exec
    39: failwith
    40: ge
    41: get
    42: gt
    43: hash_key
    44: if
    45: if_cons
    46: if_left
    47: if_none
    48: int
    49: lambda
    50: le
    51: left
    52: loop
    53: lsl
    54: lsr
    55: lt
    56: map
    57: mem
    58: mul
    59: neg
    60: neq
    61: nil
    62: none
    63: not
    64: now
    65: or
    66: pair
    67: push
    68: right
    69: size
    70: some
    71: source
    72: sender
    73: self
    74: steps_to_quota
    75: sub
    76: swap
    77: transfer_tokens
    78: set_delegate
    79: unit
    80: update
    81: xor
    82: iter
    83: loop_left
    84: address
    85: contract
    86: isnat
    87: cast
    88: rename
    89: bool
    90: contract
    91: int
    92: key
    93: key_hash
    94: lambda
    95: list
    96: map
    97: big_map
    98: nat
    99: option
    100: or
    101: pair
    102: set
    103: signature
    104: string
    105: bytes
    106: mutez
    107: timestamp
    108: unit
    109: operation
    110: address
    111: slice
    112: dig
    113: dug
    114: empty_big_map
    115: apply
    116: chain_id
    117: chain_id
  update__prim__1_arg__no_annots__id_006__pscartha__michelson__v1__primitives:
    0: parameter
    1: storage
    2: code
    3: false
    4: elt
    5: left
    6: none
    7: pair
    8: right
    9: some
    10: true
    11: unit
    12: pack
    13: unpack
    14: blake2b
    15: sha256
    16: sha512
    17: abs
    18: add
    19: amount
    20: and
    21: balance
    22: car
    23: cdr
    24: check_signature
    25: compare
    26: concat
    27: cons
    28: create_account
    29: create_contract
    30: implicit_account
    31: dip
    32: drop
    33: dup
    34: ediv
    35: empty_map
    36: empty_set
    37: eq
    38: exec
    39: failwith
    40: ge
    41: get
    42: gt
    43: hash_key
    44: if
    45: if_cons
    46: if_left
    47: if_none
    48: int
    49: lambda
    50: le
    51: left
    52: loop
    53: lsl
    54: lsr
    55: lt
    56: map
    57: mem
    58: mul
    59: neg
    60: neq
    61: nil
    62: none
    63: not
    64: now
    65: or
    66: pair
    67: push
    68: right
    69: size
    70: some
    71: source
    72: sender
    73: self
    74: steps_to_quota
    75: sub
    76: swap
    77: transfer_tokens
    78: set_delegate
    79: unit
    80: update
    81: xor
    82: iter
    83: loop_left
    84: address
    85: contract
    86: isnat
    87: cast
    88: rename
    89: bool
    90: contract
    91: int
    92: key
    93: key_hash
    94: lambda
    95: list
    96: map
    97: big_map
    98: nat
    99: option
    100: or
    101: pair
    102: set
    103: signature
    104: string
    105: bytes
    106: mutez
    107: timestamp
    108: unit
    109: operation
    110: address
    111: slice
    112: dig
    113: dug
    114: empty_big_map
    115: apply
    116: chain_id
    117: chain_id
  update__prim__no_args__some_annots__id_006__pscartha__michelson__v1__primitives:
    0: parameter
    1: storage
    2: code
    3: false
    4: elt
    5: left
    6: none
    7: pair
    8: right
    9: some
    10: true
    11: unit
    12: pack
    13: unpack
    14: blake2b
    15: sha256
    16: sha512
    17: abs
    18: add
    19: amount
    20: and
    21: balance
    22: car
    23: cdr
    24: check_signature
    25: compare
    26: concat
    27: cons
    28: create_account
    29: create_contract
    30: implicit_account
    31: dip
    32: drop
    33: dup
    34: ediv
    35: empty_map
    36: empty_set
    37: eq
    38: exec
    39: failwith
    40: ge
    41: get
    42: gt
    43: hash_key
    44: if
    45: if_cons
    46: if_left
    47: if_none
    48: int
    49: lambda
    50: le
    51: left
    52: loop
    53: lsl
    54: lsr
    55: lt
    56: map
    57: mem
    58: mul
    59: neg
    60: neq
    61: nil
    62: none
    63: not
    64: now
    65: or
    66: pair
    67: push
    68: right
    69: size
    70: some
    71: source
    72: sender
    73: self
    74: steps_to_quota
    75: sub
    76: swap
    77: transfer_tokens
    78: set_delegate
    79: unit
    80: update
    81: xor
    82: iter
    83: loop_left
    84: address
    85: contract
    86: isnat
    87: cast
    88: rename
    89: bool
    90: contract
    91: int
    92: key
    93: key_hash
    94: lambda
    95: list
    96: map
    97: big_map
    98: nat
    99: option
    100: or
    101: pair
    102: set
    103: signature
    104: string
    105: bytes
    106: mutez
    107: timestamp
    108: unit
    109: operation
    110: address
    111: slice
    112: dig
    113: dug
    114: empty_big_map
    115: apply
    116: chain_id
    117: chain_id
  update__prim__no_args__no_annots__id_006__pscartha__michelson__v1__primitives:
    0: parameter
    1: storage
    2: code
    3: false
    4: elt
    5: left
    6: none
    7: pair
    8: right
    9: some
    10: true
    11: unit
    12: pack
    13: unpack
    14: blake2b
    15: sha256
    16: sha512
    17: abs
    18: add
    19: amount
    20: and
    21: balance
    22: car
    23: cdr
    24: check_signature
    25: compare
    26: concat
    27: cons
    28: create_account
    29: create_contract
    30: implicit_account
    31: dip
    32: drop
    33: dup
    34: ediv
    35: empty_map
    36: empty_set
    37: eq
    38: exec
    39: failwith
    40: ge
    41: get
    42: gt
    43: hash_key
    44: if
    45: if_cons
    46: if_left
    47: if_none
    48: int
    49: lambda
    50: le
    51: left
    52: loop
    53: lsl
    54: lsr
    55: lt
    56: map
    57: mem
    58: mul
    59: neg
    60: neq
    61: nil
    62: none
    63: not
    64: now
    65: or
    66: pair
    67: push
    68: right
    69: size
    70: some
    71: source
    72: sender
    73: self
    74: steps_to_quota
    75: sub
    76: swap
    77: transfer_tokens
    78: set_delegate
    79: unit
    80: update
    81: xor
    82: iter
    83: loop_left
    84: address
    85: contract
    86: isnat
    87: cast
    88: rename
    89: bool
    90: contract
    91: int
    92: key
    93: key_hash
    94: lambda
    95: list
    96: map
    97: big_map
    98: nat
    99: option
    100: or
    101: pair
    102: set
    103: signature
    104: string
    105: bytes
    106: mutez
    107: timestamp
    108: unit
    109: operation
    110: address
    111: slice
    112: dig
    113: dug
    114: empty_big_map
    115: apply
    116: chain_id
    117: chain_id
  micheline__006__pscartha__michelson_v1__expression_tag:
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
  id_006__pscartha__contract__big_map_diff_elt_tag:
    0: update
    1: remove
    2: copy
    3: alloc
seq:
- id: len_id_006__pscartha__contract__big_map_diff
  type: u4
  valid:
    max: 1073741823
- id: id_006__pscartha__contract__big_map_diff
  type: id_006__pscartha__contract__big_map_diff_entries
  size: len_id_006__pscartha__contract__big_map_diff
  repeat: eos
