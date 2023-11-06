meta:
  id: id_018__proxford__operation__internal
  endian: be
doc: ! 'Encoding id: 018-Proxford.operation.internal'
types:
  id_018__proxford__apply_internal_results__alpha__operation_result:
    seq:
    - id: source
      type: id_018__proxford__transaction_destination
      doc: ! >-
        A destination of a transaction: A destination notation compatible with the
        contract notation as given to an RPC or inside scripts. Can be a base58 implicit
        contract hash, a base58 originated contract hash, a base58 originated transaction
        rollup, or a base58 originated smart rollup.
    - id: nonce
      type: u2
    - id: id_018__proxford__apply_internal_results__alpha__operation_result_tag
      type: u1
      enum: id_018__proxford__apply_internal_results__alpha__operation_result_tag
    - id: transaction__id_018__proxford__apply_internal_results__alpha__operation_result
      type: transaction__id_018__proxford__apply_internal_results__alpha__operation_result
      if: (id_018__proxford__apply_internal_results__alpha__operation_result_tag ==
        id_018__proxford__apply_internal_results__alpha__operation_result_tag::transaction)
    - id: origination__id_018__proxford__apply_internal_results__alpha__operation_result
      type: origination__id_018__proxford__apply_internal_results__alpha__operation_result
      if: (id_018__proxford__apply_internal_results__alpha__operation_result_tag ==
        id_018__proxford__apply_internal_results__alpha__operation_result_tag::origination)
    - id: delegation__id_018__proxford__apply_internal_results__alpha__operation_result
      type: delegation__id_018__proxford__apply_internal_results__alpha__operation_result
      if: (id_018__proxford__apply_internal_results__alpha__operation_result_tag ==
        id_018__proxford__apply_internal_results__alpha__operation_result_tag::delegation)
    - id: event__id_018__proxford__apply_internal_results__alpha__operation_result
      type: event__id_018__proxford__apply_internal_results__alpha__operation_result
      if: (id_018__proxford__apply_internal_results__alpha__operation_result_tag ==
        id_018__proxford__apply_internal_results__alpha__operation_result_tag::event)
  event__id_018__proxford__apply_internal_results__alpha__operation_result:
    seq:
    - id: type
      type: event__micheline__018__proxford__michelson_v1__expression
    - id: tag_tag
      type: u1
      enum: bool
    - id: tag
      type: event__id_018__proxford__entrypoint
      if: (tag_tag == bool::true)
      doc: ! 'entrypoint: Named entrypoint to a Michelson smart contract'
    - id: payload_tag
      type: u1
      enum: bool
    - id: payload
      type: micheline__018__proxford__michelson_v1__expression
      if: (payload_tag == bool::true)
  event__id_018__proxford__entrypoint:
    seq:
    - id: id_018__proxford__entrypoint_tag
      type: u1
      enum: id_018__proxford__entrypoint_tag
    - id: event__named__id_018__proxford__entrypoint
      type: event__named__id_018__proxford__entrypoint
      if: (id_018__proxford__entrypoint_tag == id_018__proxford__entrypoint_tag::named)
  event__named__id_018__proxford__entrypoint:
    seq:
    - id: len_named
      type: u1
      valid:
        max: 31
    - id: named
      size: len_named
      size-eos: true
      valid:
        max: 31
  event__micheline__018__proxford__michelson_v1__expression:
    seq:
    - id: micheline__018__proxford__michelson_v1__expression_tag
      type: u1
      enum: micheline__018__proxford__michelson_v1__expression_tag
    - id: event__int__micheline__018__proxford__michelson_v1__expression
      type: z
      if: (micheline__018__proxford__michelson_v1__expression_tag == micheline__018__proxford__michelson_v1__expression_tag::int)
    - id: event__string__micheline__018__proxford__michelson_v1__expression
      type: event__string__string
      if: (micheline__018__proxford__michelson_v1__expression_tag == micheline__018__proxford__michelson_v1__expression_tag::string)
    - id: event__sequence__micheline__018__proxford__michelson_v1__expression
      type: event__sequence__micheline__018__proxford__michelson_v1__expression
      if: (micheline__018__proxford__michelson_v1__expression_tag == micheline__018__proxford__michelson_v1__expression_tag::sequence)
    - id: event__prim__no_args__no_annots__micheline__018__proxford__michelson_v1__expression
      type: u1
      if: (micheline__018__proxford__michelson_v1__expression_tag == micheline__018__proxford__michelson_v1__expression_tag::prim__no_args__no_annots)
      enum: event__prim__no_args__no_annots__id_018__proxford__michelson__v1__primitives
    - id: event__prim__no_args__some_annots__micheline__018__proxford__michelson_v1__expression
      type: event__prim__no_args__some_annots__micheline__018__proxford__michelson_v1__expression
      if: (micheline__018__proxford__michelson_v1__expression_tag == micheline__018__proxford__michelson_v1__expression_tag::prim__no_args__some_annots)
    - id: event__prim__1_arg__no_annots__micheline__018__proxford__michelson_v1__expression
      type: event__prim__1_arg__no_annots__micheline__018__proxford__michelson_v1__expression
      if: (micheline__018__proxford__michelson_v1__expression_tag == micheline__018__proxford__michelson_v1__expression_tag::prim__1_arg__no_annots)
    - id: event__prim__1_arg__some_annots__micheline__018__proxford__michelson_v1__expression
      type: event__prim__1_arg__some_annots__micheline__018__proxford__michelson_v1__expression
      if: (micheline__018__proxford__michelson_v1__expression_tag == micheline__018__proxford__michelson_v1__expression_tag::prim__1_arg__some_annots)
    - id: event__prim__2_args__no_annots__micheline__018__proxford__michelson_v1__expression
      type: event__prim__2_args__no_annots__micheline__018__proxford__michelson_v1__expression
      if: (micheline__018__proxford__michelson_v1__expression_tag == micheline__018__proxford__michelson_v1__expression_tag::prim__2_args__no_annots)
    - id: event__prim__2_args__some_annots__micheline__018__proxford__michelson_v1__expression
      type: event__prim__2_args__some_annots__micheline__018__proxford__michelson_v1__expression
      if: (micheline__018__proxford__michelson_v1__expression_tag == micheline__018__proxford__michelson_v1__expression_tag::prim__2_args__some_annots)
    - id: event__prim__generic__micheline__018__proxford__michelson_v1__expression
      type: event__prim__generic__micheline__018__proxford__michelson_v1__expression
      if: (micheline__018__proxford__michelson_v1__expression_tag == micheline__018__proxford__michelson_v1__expression_tag::prim__generic)
    - id: event__bytes__micheline__018__proxford__michelson_v1__expression
      type: event__bytes__bytes
      if: (micheline__018__proxford__michelson_v1__expression_tag == micheline__018__proxford__michelson_v1__expression_tag::bytes)
  event__bytes__bytes:
    seq:
    - id: len_bytes
      type: u4
      valid:
        max: 1073741823
    - id: bytes
      size: len_bytes
  event__prim__generic__micheline__018__proxford__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: event__prim__generic__id_018__proxford__michelson__v1__primitives
    - id: event__prim__generic__args
      type: event__prim__generic__args
    - id: event__prim__generic__annots
      type: event__prim__generic__annots
  event__prim__generic__annots:
    seq:
    - id: len_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: len_annots
  event__prim__generic__args:
    seq:
    - id: len_args
      type: u4
      valid:
        max: 1073741823
    - id: args
      type: event__prim__generic__args_entries
      size: len_args
      repeat: eos
  event__prim__generic__args_entries:
    seq:
    - id: args_elt
      type: micheline__018__proxford__michelson_v1__expression
  event__prim__2_args__some_annots__micheline__018__proxford__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: event__prim__2_args__some_annots__id_018__proxford__michelson__v1__primitives
    - id: arg1
      type: micheline__018__proxford__michelson_v1__expression
    - id: arg2
      type: micheline__018__proxford__michelson_v1__expression
    - id: event__prim__2_args__some_annots__annots
      type: event__prim__2_args__some_annots__annots
  event__prim__2_args__some_annots__annots:
    seq:
    - id: len_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: len_annots
  event__prim__2_args__no_annots__micheline__018__proxford__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: event__prim__2_args__no_annots__id_018__proxford__michelson__v1__primitives
    - id: arg1
      type: micheline__018__proxford__michelson_v1__expression
    - id: arg2
      type: micheline__018__proxford__michelson_v1__expression
  event__prim__1_arg__some_annots__micheline__018__proxford__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: event__prim__1_arg__some_annots__id_018__proxford__michelson__v1__primitives
    - id: arg
      type: micheline__018__proxford__michelson_v1__expression
    - id: event__prim__1_arg__some_annots__annots
      type: event__prim__1_arg__some_annots__annots
  event__prim__1_arg__some_annots__annots:
    seq:
    - id: len_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: len_annots
  event__prim__1_arg__no_annots__micheline__018__proxford__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: event__prim__1_arg__no_annots__id_018__proxford__michelson__v1__primitives
    - id: arg
      type: micheline__018__proxford__michelson_v1__expression
  event__prim__no_args__some_annots__micheline__018__proxford__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: event__prim__no_args__some_annots__id_018__proxford__michelson__v1__primitives
    - id: event__prim__no_args__some_annots__annots
      type: event__prim__no_args__some_annots__annots
  event__prim__no_args__some_annots__annots:
    seq:
    - id: len_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: len_annots
  event__sequence__micheline__018__proxford__michelson_v1__expression:
    seq:
    - id: len_sequence
      type: u4
      valid:
        max: 1073741823
    - id: sequence
      type: event__sequence__sequence_entries
      size: len_sequence
      repeat: eos
  event__sequence__sequence_entries:
    seq:
    - id: sequence_elt
      type: micheline__018__proxford__michelson_v1__expression
  event__string__string:
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
  delegation__id_018__proxford__apply_internal_results__alpha__operation_result:
    seq:
    - id: delegate_tag
      type: u1
      enum: bool
    - id: delegate
      type: delegation__public_key_hash
      if: (delegate_tag == bool::true)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
  delegation__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: delegation__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: delegation__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: delegation__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: delegation__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  origination__id_018__proxford__apply_internal_results__alpha__operation_result:
    seq:
    - id: balance
      type: n
    - id: delegate_tag
      type: u1
      enum: bool
    - id: delegate
      type: origination__public_key_hash
      if: (delegate_tag == bool::true)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: script
      type: origination__id_018__proxford__scripted__contracts
  origination__id_018__proxford__scripted__contracts:
    seq:
    - id: origination__code
      type: origination__code
    - id: origination__storage
      type: origination__storage
  origination__storage:
    seq:
    - id: len_storage
      type: u4
      valid:
        max: 1073741823
    - id: storage
      size: len_storage
  origination__code:
    seq:
    - id: len_code
      type: u4
      valid:
        max: 1073741823
    - id: code
      size: len_code
  origination__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: origination__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: origination__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: origination__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: origination__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  transaction__id_018__proxford__apply_internal_results__alpha__operation_result:
    seq:
    - id: amount
      type: n
    - id: destination
      type: transaction__id_018__proxford__transaction_destination
      doc: ! >-
        A destination of a transaction: A destination notation compatible with the
        contract notation as given to an RPC or inside scripts. Can be a base58 implicit
        contract hash, a base58 originated contract hash, a base58 originated transaction
        rollup, or a base58 originated smart rollup.
    - id: parameters_tag
      type: u1
      enum: bool
    - id: transaction__parameters
      type: transaction__parameters
      if: (parameters_tag == bool::true)
  transaction__parameters:
    seq:
    - id: entrypoint
      type: transaction__id_018__proxford__entrypoint
      doc: ! 'entrypoint: Named entrypoint to a Michelson smart contract'
    - id: transaction__value
      type: transaction__value
  transaction__value:
    seq:
    - id: len_value
      type: u4
      valid:
        max: 1073741823
    - id: value
      size: len_value
  transaction__id_018__proxford__entrypoint:
    seq:
    - id: id_018__proxford__entrypoint_tag
      type: u1
      enum: id_018__proxford__entrypoint_tag
    - id: transaction__named__id_018__proxford__entrypoint
      type: transaction__named__id_018__proxford__entrypoint
      if: (id_018__proxford__entrypoint_tag == id_018__proxford__entrypoint_tag::named)
  transaction__named__id_018__proxford__entrypoint:
    seq:
    - id: len_named
      type: u1
      valid:
        max: 31
    - id: named
      size: len_named
      size-eos: true
      valid:
        max: 31
  transaction__id_018__proxford__transaction_destination:
    seq:
    - id: id_018__proxford__transaction_destination_tag
      type: u1
      enum: id_018__proxford__transaction_destination_tag
    - id: transaction__implicit__id_018__proxford__transaction_destination
      type: transaction__implicit__public_key_hash
      if: (id_018__proxford__transaction_destination_tag == id_018__proxford__transaction_destination_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: transaction__originated__id_018__proxford__transaction_destination
      type: transaction__originated__id_018__proxford__transaction_destination
      if: (id_018__proxford__transaction_destination_tag == id_018__proxford__transaction_destination_tag::originated)
    - id: transaction__smart_rollup__id_018__proxford__transaction_destination
      type: transaction__smart_rollup__id_018__proxford__transaction_destination
      if: (id_018__proxford__transaction_destination_tag == id_018__proxford__transaction_destination_tag::smart_rollup)
    - id: transaction__zk_rollup__id_018__proxford__transaction_destination
      type: transaction__zk_rollup__id_018__proxford__transaction_destination
      if: (id_018__proxford__transaction_destination_tag == id_018__proxford__transaction_destination_tag::zk_rollup)
  transaction__zk_rollup__id_018__proxford__transaction_destination:
    seq:
    - id: zk_rollup_hash
      size: 20
    - id: zk_rollup_padding
      size: 1
      doc: This field is for padding, ignore
  transaction__smart_rollup__id_018__proxford__transaction_destination:
    seq:
    - id: smart_rollup_address
      size: 20
    - id: smart_rollup_padding
      size: 1
      doc: This field is for padding, ignore
  transaction__originated__id_018__proxford__transaction_destination:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  transaction__implicit__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: transaction__implicit__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: transaction__implicit__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: transaction__implicit__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: transaction__implicit__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
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
  id_018__proxford__transaction_destination:
    seq:
    - id: id_018__proxford__transaction_destination_tag
      type: u1
      enum: id_018__proxford__transaction_destination_tag
    - id: implicit__id_018__proxford__transaction_destination
      type: implicit__public_key_hash
      if: (id_018__proxford__transaction_destination_tag == id_018__proxford__transaction_destination_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: originated__id_018__proxford__transaction_destination
      type: originated__id_018__proxford__transaction_destination
      if: (id_018__proxford__transaction_destination_tag == id_018__proxford__transaction_destination_tag::originated)
    - id: smart_rollup__id_018__proxford__transaction_destination
      type: smart_rollup__id_018__proxford__transaction_destination
      if: (id_018__proxford__transaction_destination_tag == id_018__proxford__transaction_destination_tag::smart_rollup)
    - id: zk_rollup__id_018__proxford__transaction_destination
      type: zk_rollup__id_018__proxford__transaction_destination
      if: (id_018__proxford__transaction_destination_tag == id_018__proxford__transaction_destination_tag::zk_rollup)
  zk_rollup__id_018__proxford__transaction_destination:
    seq:
    - id: zk_rollup_hash
      size: 20
    - id: zk_rollup_padding
      size: 1
      doc: This field is for padding, ignore
  smart_rollup__id_018__proxford__transaction_destination:
    seq:
    - id: smart_rollup_address
      size: 20
    - id: smart_rollup_padding
      size: 1
      doc: This field is for padding, ignore
  originated__id_018__proxford__transaction_destination:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  implicit__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: implicit__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: implicit__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: implicit__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: implicit__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
enums:
  event__prim__generic__id_018__proxford__michelson__v1__primitives:
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
    118: level
    119: self_address
    120: never
    121: never
    122: unpair
    123: voting_power
    124: total_voting_power
    125: keccak
    126: sha3
    127: pairing_check
    128: bls12_381_g1
    129: bls12_381_g2
    130: bls12_381_fr
    131: sapling_state
    132: sapling_transaction_deprecated
    133: sapling_empty_state
    134: sapling_verify_update
    135: ticket
    136: ticket_deprecated
    137: read_ticket
    138: split_ticket
    139: join_tickets
    140: get_and_update
    141: chest
    142: chest_key
    143: open_chest
    144: view
    145: view
    146: constant
    147: sub_mutez
    148: tx_rollup_l2_address
    149: min_block_time
    150: sapling_transaction
    151: emit
    152: lambda_rec
    153: lambda_rec
    154: ticket
    155: bytes
    156: nat
  event__prim__2_args__some_annots__id_018__proxford__michelson__v1__primitives:
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
    118: level
    119: self_address
    120: never
    121: never
    122: unpair
    123: voting_power
    124: total_voting_power
    125: keccak
    126: sha3
    127: pairing_check
    128: bls12_381_g1
    129: bls12_381_g2
    130: bls12_381_fr
    131: sapling_state
    132: sapling_transaction_deprecated
    133: sapling_empty_state
    134: sapling_verify_update
    135: ticket
    136: ticket_deprecated
    137: read_ticket
    138: split_ticket
    139: join_tickets
    140: get_and_update
    141: chest
    142: chest_key
    143: open_chest
    144: view
    145: view
    146: constant
    147: sub_mutez
    148: tx_rollup_l2_address
    149: min_block_time
    150: sapling_transaction
    151: emit
    152: lambda_rec
    153: lambda_rec
    154: ticket
    155: bytes
    156: nat
  event__prim__2_args__no_annots__id_018__proxford__michelson__v1__primitives:
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
    118: level
    119: self_address
    120: never
    121: never
    122: unpair
    123: voting_power
    124: total_voting_power
    125: keccak
    126: sha3
    127: pairing_check
    128: bls12_381_g1
    129: bls12_381_g2
    130: bls12_381_fr
    131: sapling_state
    132: sapling_transaction_deprecated
    133: sapling_empty_state
    134: sapling_verify_update
    135: ticket
    136: ticket_deprecated
    137: read_ticket
    138: split_ticket
    139: join_tickets
    140: get_and_update
    141: chest
    142: chest_key
    143: open_chest
    144: view
    145: view
    146: constant
    147: sub_mutez
    148: tx_rollup_l2_address
    149: min_block_time
    150: sapling_transaction
    151: emit
    152: lambda_rec
    153: lambda_rec
    154: ticket
    155: bytes
    156: nat
  event__prim__1_arg__some_annots__id_018__proxford__michelson__v1__primitives:
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
    118: level
    119: self_address
    120: never
    121: never
    122: unpair
    123: voting_power
    124: total_voting_power
    125: keccak
    126: sha3
    127: pairing_check
    128: bls12_381_g1
    129: bls12_381_g2
    130: bls12_381_fr
    131: sapling_state
    132: sapling_transaction_deprecated
    133: sapling_empty_state
    134: sapling_verify_update
    135: ticket
    136: ticket_deprecated
    137: read_ticket
    138: split_ticket
    139: join_tickets
    140: get_and_update
    141: chest
    142: chest_key
    143: open_chest
    144: view
    145: view
    146: constant
    147: sub_mutez
    148: tx_rollup_l2_address
    149: min_block_time
    150: sapling_transaction
    151: emit
    152: lambda_rec
    153: lambda_rec
    154: ticket
    155: bytes
    156: nat
  event__prim__1_arg__no_annots__id_018__proxford__michelson__v1__primitives:
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
    118: level
    119: self_address
    120: never
    121: never
    122: unpair
    123: voting_power
    124: total_voting_power
    125: keccak
    126: sha3
    127: pairing_check
    128: bls12_381_g1
    129: bls12_381_g2
    130: bls12_381_fr
    131: sapling_state
    132: sapling_transaction_deprecated
    133: sapling_empty_state
    134: sapling_verify_update
    135: ticket
    136: ticket_deprecated
    137: read_ticket
    138: split_ticket
    139: join_tickets
    140: get_and_update
    141: chest
    142: chest_key
    143: open_chest
    144: view
    145: view
    146: constant
    147: sub_mutez
    148: tx_rollup_l2_address
    149: min_block_time
    150: sapling_transaction
    151: emit
    152: lambda_rec
    153: lambda_rec
    154: ticket
    155: bytes
    156: nat
  event__prim__no_args__some_annots__id_018__proxford__michelson__v1__primitives:
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
    118: level
    119: self_address
    120: never
    121: never
    122: unpair
    123: voting_power
    124: total_voting_power
    125: keccak
    126: sha3
    127: pairing_check
    128: bls12_381_g1
    129: bls12_381_g2
    130: bls12_381_fr
    131: sapling_state
    132: sapling_transaction_deprecated
    133: sapling_empty_state
    134: sapling_verify_update
    135: ticket
    136: ticket_deprecated
    137: read_ticket
    138: split_ticket
    139: join_tickets
    140: get_and_update
    141: chest
    142: chest_key
    143: open_chest
    144: view
    145: view
    146: constant
    147: sub_mutez
    148: tx_rollup_l2_address
    149: min_block_time
    150: sapling_transaction
    151: emit
    152: lambda_rec
    153: lambda_rec
    154: ticket
    155: bytes
    156: nat
  event__prim__no_args__no_annots__id_018__proxford__michelson__v1__primitives:
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
    118: level
    119: self_address
    120: never
    121: never
    122: unpair
    123: voting_power
    124: total_voting_power
    125: keccak
    126: sha3
    127: pairing_check
    128: bls12_381_g1
    129: bls12_381_g2
    130: bls12_381_fr
    131: sapling_state
    132: sapling_transaction_deprecated
    133: sapling_empty_state
    134: sapling_verify_update
    135: ticket
    136: ticket_deprecated
    137: read_ticket
    138: split_ticket
    139: join_tickets
    140: get_and_update
    141: chest
    142: chest_key
    143: open_chest
    144: view
    145: view
    146: constant
    147: sub_mutez
    148: tx_rollup_l2_address
    149: min_block_time
    150: sapling_transaction
    151: emit
    152: lambda_rec
    153: lambda_rec
    154: ticket
    155: bytes
    156: nat
  micheline__018__proxford__michelson_v1__expression_tag:
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
  id_018__proxford__entrypoint_tag:
    0: default
    1: root
    2: do
    3: set_delegate
    4: remove_delegate
    5: deposit
    6: stake
    7: unstake
    8: finalize_unstake
    9: set_delegate_parameters
    255: named
  bool:
    0: false
    255: true
  id_018__proxford__apply_internal_results__alpha__operation_result_tag:
    1: transaction
    2: origination
    3: delegation
    4: event
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
    3: bls
  id_018__proxford__transaction_destination_tag:
    0: implicit
    1: originated
    3: smart_rollup
    4: zk_rollup
seq:
- id: id_018__proxford__apply_internal_results__alpha__operation_result
  type: id_018__proxford__apply_internal_results__alpha__operation_result
