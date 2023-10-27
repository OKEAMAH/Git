meta:
  id: id_013__ptjakart__script__expr
  endian: be
doc: ! 'Encoding id: 013-PtJakart.script.expr'
types:
  micheline__013__ptjakart__michelson_v1__expression:
    seq:
    - id: micheline__013__ptjakart__michelson_v1__expression_tag
      type: u1
      enum: micheline__013__ptjakart__michelson_v1__expression_tag
    - id: micheline__013__ptjakart__michelson_v1__expression_int
      type: z
      if: (micheline__013__ptjakart__michelson_v1__expression_tag == micheline__013__ptjakart__michelson_v1__expression_tag::int)
    - id: micheline__013__ptjakart__michelson_v1__expression_string
      type: string
      if: (micheline__013__ptjakart__michelson_v1__expression_tag == micheline__013__ptjakart__michelson_v1__expression_tag::string)
    - id: micheline__013__ptjakart__michelson_v1__expression_sequence
      type: micheline__013__ptjakart__michelson_v1__expression_sequence
      if: (micheline__013__ptjakart__michelson_v1__expression_tag == micheline__013__ptjakart__michelson_v1__expression_tag::sequence)
    - id: micheline__013__ptjakart__michelson_v1__expression_prim__no_args__no_annots
      type: u1
      if: (micheline__013__ptjakart__michelson_v1__expression_tag == micheline__013__ptjakart__michelson_v1__expression_tag::prim__no_args__no_annots)
      enum: id_013__ptjakart__michelson__v1__primitives
    - id: micheline__013__ptjakart__michelson_v1__expression_prim__no_args__some_annots
      type: micheline__013__ptjakart__michelson_v1__expression_prim__no_args__some_annots
      if: (micheline__013__ptjakart__michelson_v1__expression_tag == micheline__013__ptjakart__michelson_v1__expression_tag::prim__no_args__some_annots)
    - id: micheline__013__ptjakart__michelson_v1__expression_prim__1_arg__no_annots
      type: micheline__013__ptjakart__michelson_v1__expression_prim__1_arg__no_annots
      if: (micheline__013__ptjakart__michelson_v1__expression_tag == micheline__013__ptjakart__michelson_v1__expression_tag::prim__1_arg__no_annots)
    - id: micheline__013__ptjakart__michelson_v1__expression_prim__1_arg__some_annots
      type: micheline__013__ptjakart__michelson_v1__expression_prim__1_arg__some_annots
      if: (micheline__013__ptjakart__michelson_v1__expression_tag == micheline__013__ptjakart__michelson_v1__expression_tag::prim__1_arg__some_annots)
    - id: micheline__013__ptjakart__michelson_v1__expression_prim__2_args__no_annots
      type: micheline__013__ptjakart__michelson_v1__expression_prim__2_args__no_annots
      if: (micheline__013__ptjakart__michelson_v1__expression_tag == micheline__013__ptjakart__michelson_v1__expression_tag::prim__2_args__no_annots)
    - id: micheline__013__ptjakart__michelson_v1__expression_prim__2_args__some_annots
      type: micheline__013__ptjakart__michelson_v1__expression_prim__2_args__some_annots
      if: (micheline__013__ptjakart__michelson_v1__expression_tag == micheline__013__ptjakart__michelson_v1__expression_tag::prim__2_args__some_annots)
    - id: micheline__013__ptjakart__michelson_v1__expression_prim__generic
      type: micheline__013__ptjakart__michelson_v1__expression_prim__generic
      if: (micheline__013__ptjakart__michelson_v1__expression_tag == micheline__013__ptjakart__michelson_v1__expression_tag::prim__generic)
    - id: micheline__013__ptjakart__michelson_v1__expression_bytes
      type: bytes
      if: (micheline__013__ptjakart__michelson_v1__expression_tag == micheline__013__ptjakart__michelson_v1__expression_tag::bytes)
  bytes:
    seq:
    - id: size_of_bytes
      type: u4
      valid:
        max: 1073741823
    - id: bytes
      size: size_of_bytes
  micheline__013__ptjakart__michelson_v1__expression_prim__generic:
    seq:
    - id: prim
      type: u1
      enum: id_013__ptjakart__michelson__v1__primitives
    - id: args
      type: args
    - id: annots
      type: annots
  args:
    seq:
    - id: size_of_args
      type: u4
      valid:
        max: 1073741823
    - id: args
      type: args_entries
      size: size_of_args
      repeat: eos
  args_entries:
    seq:
    - id: args_elt
      type: micheline__013__ptjakart__michelson_v1__expression
  micheline__013__ptjakart__michelson_v1__expression_prim__2_args__some_annots:
    seq:
    - id: prim
      type: u1
      enum: id_013__ptjakart__michelson__v1__primitives
    - id: arg1
      type: micheline__013__ptjakart__michelson_v1__expression
    - id: arg2
      type: micheline__013__ptjakart__michelson_v1__expression
    - id: annots
      type: annots
  micheline__013__ptjakart__michelson_v1__expression_prim__2_args__no_annots:
    seq:
    - id: prim
      type: u1
      enum: id_013__ptjakart__michelson__v1__primitives
    - id: arg1
      type: micheline__013__ptjakart__michelson_v1__expression
    - id: arg2
      type: micheline__013__ptjakart__michelson_v1__expression
  micheline__013__ptjakart__michelson_v1__expression_prim__1_arg__some_annots:
    seq:
    - id: prim
      type: u1
      enum: id_013__ptjakart__michelson__v1__primitives
    - id: arg
      type: micheline__013__ptjakart__michelson_v1__expression
    - id: annots
      type: annots
  micheline__013__ptjakart__michelson_v1__expression_prim__1_arg__no_annots:
    seq:
    - id: prim
      type: u1
      enum: id_013__ptjakart__michelson__v1__primitives
    - id: arg
      type: micheline__013__ptjakart__michelson_v1__expression
  micheline__013__ptjakart__michelson_v1__expression_prim__no_args__some_annots:
    seq:
    - id: prim
      type: u1
      enum: id_013__ptjakart__michelson__v1__primitives
    - id: annots
      type: annots
  annots:
    seq:
    - id: size_of_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: size_of_annots
  micheline__013__ptjakart__michelson_v1__expression_sequence:
    seq:
    - id: size_of_sequence
      type: u4
      valid:
        max: 1073741823
    - id: sequence
      type: sequence_entries
      size: size_of_sequence
      repeat: eos
  sequence_entries:
    seq:
    - id: sequence_elt
      type: micheline__013__ptjakart__michelson_v1__expression
  string:
    seq:
    - id: size_of_string
      type: u4
      valid:
        max: 1073741823
    - id: string
      size: size_of_string
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
  id_013__ptjakart__michelson__v1__primitives:
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
    141: chest
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
    150: sapling_transaction
    135: ticket
    42: gt
    122: unpair
    96: map
    137: read_ticket
    66: pair
    118: level
    148: tx_rollup_l2_address
    138: split_ticket
    114: empty_big_map
    54: lsr
    89: bool
    5: left
    52: loop
    127: pairing_check
    105: bytes
    49: lambda
    60: neq
    36: empty_set
    78: set_delegate
    130: bls12_381_fr
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
    107: timestamp
    63: not
    22: car
    101: pair
    72: sender
    91: int
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
    106: mutez
    73: self
    136: ticket
    13: unpack
    123: voting_power
    55: lt
    28: create_account
    46: if_left
    43: hash_key
    117: chain_id
    103: signature
    125: keccak
    102: set
    19: amount
    99: option
    76: swap
    6: none
    35: empty_map
    109: operation
    0: parameter
    9: some
    80: update
    92: key
    81: xor
    57: mem
    31: dip
    149: min_block_time
    93: key_hash
    4: elt
    39: failwith
    58: mul
    142: chest_key
    26: concat
    21: balance
    100: or
    32: drop
    111: slice
    147: sub_mutez
    25: compare
    110: address
    128: bls12_381_g1
    116: chain_id
    146: constant
    53: lsl
    90: contract
    16: sha512
    30: implicit_account
    18: add
    120: never
    98: nat
    56: map
    108: unit
    121: never
    24: check_signature
    88: rename
    74: steps_to_quota
    95: list
    61: nil
    104: string
    144: view
    20: and
    15: sha256
    145: view
    68: right
    1: storage
    132: sapling_transaction_deprecated
    97: big_map
    48: int
    7: pair
    131: sapling_state
    94: lambda
    14: blake2b
    129: bls12_381_g2
    134: sapling_verify_update
    112: dig
    3: false
    113: dug
    71: source
    44: if
    17: abs
  micheline__013__ptjakart__michelson_v1__expression_tag:
    0: int
    1: string
    2: sequence
    3: prim__no_args__no_annots
    4: prim__no_args__some_annots
    5: prim__1_arg__no_annots
    6: prim__1_arg__some_annots
    7: prim__2_args__no_annots
    8: prim__2_args__some_annots
    9: prim__generic
    10: bytes
seq:
- id: micheline__013__ptjakart__michelson_v1__expression
  type: micheline__013__ptjakart__michelson_v1__expression
