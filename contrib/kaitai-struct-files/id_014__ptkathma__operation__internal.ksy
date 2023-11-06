meta:
  id: id_014__ptkathma__operation__internal
  endian: be
doc: ! 'Encoding id: 014-PtKathma.operation.internal'
types:
  id_014__ptkathma__apply_internal_results__alpha__operation_result:
    seq:
    - id: source
      type: id_014__ptkathma__contract_id
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: nonce
      type: u2
    - id: id_014__ptkathma__apply_internal_results__alpha__operation_result_tag
      type: u1
      enum: id_014__ptkathma__apply_internal_results__alpha__operation_result_tag
    - id: transaction__id_014__ptkathma__apply_internal_results__alpha__operation_result
      type: transaction__id_014__ptkathma__apply_internal_results__alpha__operation_result
      if: (id_014__ptkathma__apply_internal_results__alpha__operation_result_tag ==
        id_014__ptkathma__apply_internal_results__alpha__operation_result_tag::transaction)
    - id: origination__id_014__ptkathma__apply_internal_results__alpha__operation_result
      type: origination__id_014__ptkathma__apply_internal_results__alpha__operation_result
      if: (id_014__ptkathma__apply_internal_results__alpha__operation_result_tag ==
        id_014__ptkathma__apply_internal_results__alpha__operation_result_tag::origination)
    - id: delegation__id_014__ptkathma__apply_internal_results__alpha__operation_result
      type: delegation__id_014__ptkathma__apply_internal_results__alpha__operation_result
      if: (id_014__ptkathma__apply_internal_results__alpha__operation_result_tag ==
        id_014__ptkathma__apply_internal_results__alpha__operation_result_tag::delegation)
    - id: event__id_014__ptkathma__apply_internal_results__alpha__operation_result
      type: event__id_014__ptkathma__apply_internal_results__alpha__operation_result
      if: (id_014__ptkathma__apply_internal_results__alpha__operation_result_tag ==
        id_014__ptkathma__apply_internal_results__alpha__operation_result_tag::event)
  event__id_014__ptkathma__apply_internal_results__alpha__operation_result:
    seq:
    - id: type
      type: event__micheline__014__ptkathma__michelson_v1__expression
    - id: tag_tag
      type: u1
      enum: bool
    - id: tag
      type: event__id_014__ptkathma__entrypoint
      if: (tag_tag == bool::true)
      doc: ! 'entrypoint: Named entrypoint to a Michelson smart contract'
    - id: payload_tag
      type: u1
      enum: bool
    - id: payload
      type: micheline__014__ptkathma__michelson_v1__expression
      if: (payload_tag == bool::true)
  event__id_014__ptkathma__entrypoint:
    seq:
    - id: id_014__ptkathma__entrypoint_tag
      type: u1
      enum: id_014__ptkathma__entrypoint_tag
    - id: event__named__id_014__ptkathma__entrypoint
      type: event__named__id_014__ptkathma__entrypoint
      if: (id_014__ptkathma__entrypoint_tag == id_014__ptkathma__entrypoint_tag::named)
  event__named__id_014__ptkathma__entrypoint:
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
  event__micheline__014__ptkathma__michelson_v1__expression:
    seq:
    - id: micheline__014__ptkathma__michelson_v1__expression_tag
      type: u1
      enum: micheline__014__ptkathma__michelson_v1__expression_tag
    - id: event__int__micheline__014__ptkathma__michelson_v1__expression
      type: z
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == ::micheline__014__ptkathma__michelson_v1__expression_tag::micheline__014__ptkathma__michelson_v1__expression_tag::int)
    - id: event__string__micheline__014__ptkathma__michelson_v1__expression
      type: event__string__string
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == ::micheline__014__ptkathma__michelson_v1__expression_tag::micheline__014__ptkathma__michelson_v1__expression_tag::string)
    - id: event__sequence__micheline__014__ptkathma__michelson_v1__expression
      type: event__sequence__micheline__014__ptkathma__michelson_v1__expression
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::sequence)
    - id: event__prim__no_args__no_annots__micheline__014__ptkathma__michelson_v1__expression
      type: u1
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == ::micheline__014__ptkathma__michelson_v1__expression_tag::micheline__014__ptkathma__michelson_v1__expression_tag::prim__no_args__no_annots)
      enum: event__prim__no_args__no_annots__id_014__ptkathma__michelson__v1__primitives
    - id: event__prim__no_args__some_annots__micheline__014__ptkathma__michelson_v1__expression
      type: event__prim__no_args__some_annots__micheline__014__ptkathma__michelson_v1__expression
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::prim__no_args__some_annots)
    - id: event__prim__1_arg__no_annots__micheline__014__ptkathma__michelson_v1__expression
      type: event__prim__1_arg__no_annots__micheline__014__ptkathma__michelson_v1__expression
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::prim__1_arg__no_annots)
    - id: event__prim__1_arg__some_annots__micheline__014__ptkathma__michelson_v1__expression
      type: event__prim__1_arg__some_annots__micheline__014__ptkathma__michelson_v1__expression
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::prim__1_arg__some_annots)
    - id: event__prim__2_args__no_annots__micheline__014__ptkathma__michelson_v1__expression
      type: event__prim__2_args__no_annots__micheline__014__ptkathma__michelson_v1__expression
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::prim__2_args__no_annots)
    - id: event__prim__2_args__some_annots__micheline__014__ptkathma__michelson_v1__expression
      type: event__prim__2_args__some_annots__micheline__014__ptkathma__michelson_v1__expression
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::prim__2_args__some_annots)
    - id: event__prim__generic__micheline__014__ptkathma__michelson_v1__expression
      type: event__prim__generic__micheline__014__ptkathma__michelson_v1__expression
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::prim__generic)
    - id: event__bytes__micheline__014__ptkathma__michelson_v1__expression
      type: event__bytes__bytes
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == ::micheline__014__ptkathma__michelson_v1__expression_tag::micheline__014__ptkathma__michelson_v1__expression_tag::bytes)
  event__bytes__bytes:
    seq:
    - id: len_bytes
      type: u4
      valid:
        max: 1073741823
    - id: bytes
      size: len_bytes
  event__prim__generic__micheline__014__ptkathma__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: event__prim__generic__id_014__ptkathma__michelson__v1__primitives
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
      type: micheline__014__ptkathma__michelson_v1__expression
  event__prim__2_args__some_annots__micheline__014__ptkathma__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: event__prim__2_args__some_annots__id_014__ptkathma__michelson__v1__primitives
    - id: arg1
      type: micheline__014__ptkathma__michelson_v1__expression
    - id: arg2
      type: micheline__014__ptkathma__michelson_v1__expression
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
  event__prim__2_args__no_annots__micheline__014__ptkathma__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: event__prim__2_args__no_annots__id_014__ptkathma__michelson__v1__primitives
    - id: arg1
      type: micheline__014__ptkathma__michelson_v1__expression
    - id: arg2
      type: micheline__014__ptkathma__michelson_v1__expression
  event__prim__1_arg__some_annots__micheline__014__ptkathma__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: event__prim__1_arg__some_annots__id_014__ptkathma__michelson__v1__primitives
    - id: arg
      type: micheline__014__ptkathma__michelson_v1__expression
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
  event__prim__1_arg__no_annots__micheline__014__ptkathma__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: event__prim__1_arg__no_annots__id_014__ptkathma__michelson__v1__primitives
    - id: arg
      type: micheline__014__ptkathma__michelson_v1__expression
  event__prim__no_args__some_annots__micheline__014__ptkathma__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: event__prim__no_args__some_annots__id_014__ptkathma__michelson__v1__primitives
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
  event__sequence__micheline__014__ptkathma__michelson_v1__expression:
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
      type: micheline__014__ptkathma__michelson_v1__expression
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
  delegation__id_014__ptkathma__apply_internal_results__alpha__operation_result:
    seq:
    - id: delegate_tag
      type: u1
      enum: bool
    - id: delegate
      type: delegation__public_key_hash
      if: (delegate_tag == bool::true)
      doc: A Ed25519, Secp256k1, or P256 public key hash
  delegation__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: delegation__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::ed25519)
    - id: delegation__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::secp256k1)
    - id: delegation__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  origination__id_014__ptkathma__apply_internal_results__alpha__operation_result:
    seq:
    - id: balance
      type: n
    - id: delegate_tag
      type: u1
      enum: bool
    - id: delegate
      type: origination__public_key_hash
      if: (delegate_tag == bool::true)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: script
      type: origination__id_014__ptkathma__scripted__contracts
  origination__id_014__ptkathma__scripted__contracts:
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
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::ed25519)
    - id: origination__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::secp256k1)
    - id: origination__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  transaction__id_014__ptkathma__apply_internal_results__alpha__operation_result:
    seq:
    - id: amount
      type: n
    - id: destination
      type: transaction__id_014__ptkathma__transaction_destination
      doc: ! >-
        A destination of a transaction: A destination notation compatible with the
        contract notation as given to an RPC or inside scripts. Can be a base58 implicit
        contract hash, a base58 originated contract hash, a base58 originated transaction
        rollup, or a base58 originated smart-contract rollup.
    - id: parameters_tag
      type: u1
      enum: bool
    - id: transaction__parameters
      type: transaction__parameters
      if: (parameters_tag == bool::true)
  transaction__parameters:
    seq:
    - id: entrypoint
      type: transaction__id_014__ptkathma__entrypoint
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
  transaction__id_014__ptkathma__entrypoint:
    seq:
    - id: id_014__ptkathma__entrypoint_tag
      type: u1
      enum: id_014__ptkathma__entrypoint_tag
    - id: transaction__named__id_014__ptkathma__entrypoint
      type: transaction__named__id_014__ptkathma__entrypoint
      if: (id_014__ptkathma__entrypoint_tag == id_014__ptkathma__entrypoint_tag::named)
  transaction__named__id_014__ptkathma__entrypoint:
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
  transaction__id_014__ptkathma__transaction_destination:
    seq:
    - id: id_014__ptkathma__transaction_destination_tag
      type: u1
      enum: id_014__ptkathma__transaction_destination_tag
    - id: transaction__implicit__id_014__ptkathma__transaction_destination
      type: transaction__implicit__public_key_hash
      if: (id_014__ptkathma__transaction_destination_tag == ::id_014__ptkathma__transaction_destination_tag::id_014__ptkathma__transaction_destination_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: transaction__originated__id_014__ptkathma__transaction_destination
      type: transaction__originated__id_014__ptkathma__transaction_destination
      if: (id_014__ptkathma__transaction_destination_tag == id_014__ptkathma__transaction_destination_tag::originated)
    - id: transaction__tx_rollup__id_014__ptkathma__transaction_destination
      type: transaction__tx_rollup__id_014__ptkathma__transaction_destination
      if: (id_014__ptkathma__transaction_destination_tag == id_014__ptkathma__transaction_destination_tag::tx_rollup)
    - id: transaction__sc_rollup__id_014__ptkathma__transaction_destination
      type: transaction__sc_rollup__id_014__ptkathma__transaction_destination
      if: (id_014__ptkathma__transaction_destination_tag == id_014__ptkathma__transaction_destination_tag::sc_rollup)
  transaction__sc_rollup__id_014__ptkathma__transaction_destination:
    seq:
    - id: sc_rollup_hash
      size: 20
    - id: sc_rollup_padding
      size: 1
      doc: This field is for padding, ignore
  transaction__tx_rollup__id_014__ptkathma__transaction_destination:
    seq:
    - id: id_014__ptkathma__tx_rollup_id
      size: 20
      doc: ! >-
        A tx rollup handle: A tx rollup notation as given to an RPC or inside scripts,
        is a base58 tx rollup hash
    - id: tx_rollup_padding
      size: 1
      doc: This field is for padding, ignore
  transaction__originated__id_014__ptkathma__transaction_destination:
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
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::ed25519)
    - id: transaction__implicit__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::secp256k1)
    - id: transaction__implicit__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
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
  id_014__ptkathma__contract_id:
    seq:
    - id: id_014__ptkathma__contract_id_tag
      type: u1
      enum: id_014__ptkathma__contract_id_tag
    - id: implicit__id_014__ptkathma__contract_id
      type: implicit__public_key_hash
      if: (id_014__ptkathma__contract_id_tag == ::id_014__ptkathma__contract_id_tag::id_014__ptkathma__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: originated__id_014__ptkathma__contract_id
      type: originated__id_014__ptkathma__contract_id
      if: (id_014__ptkathma__contract_id_tag == id_014__ptkathma__contract_id_tag::originated)
  originated__id_014__ptkathma__contract_id:
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
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::ed25519)
    - id: implicit__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::secp256k1)
    - id: implicit__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
enums:
  event__prim__generic__id_014__ptkathma__michelson__v1__primitives:
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
  event__prim__2_args__some_annots__id_014__ptkathma__michelson__v1__primitives:
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
  event__prim__2_args__no_annots__id_014__ptkathma__michelson__v1__primitives:
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
  event__prim__1_arg__some_annots__id_014__ptkathma__michelson__v1__primitives:
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
  event__prim__1_arg__no_annots__id_014__ptkathma__michelson__v1__primitives:
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
  event__prim__no_args__some_annots__id_014__ptkathma__michelson__v1__primitives:
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
  event__prim__no_args__no_annots__id_014__ptkathma__michelson__v1__primitives:
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
  id_014__ptkathma__entrypoint_tag:
    0: default
    1: root
    2: do
    3: set_delegate
    4: remove_delegate
    255: named
  bool:
    0: false
    255: true
  id_014__ptkathma__transaction_destination_tag:
    0: implicit
    1: originated
    2: tx_rollup
    3: sc_rollup
  id_014__ptkathma__apply_internal_results__alpha__operation_result_tag:
    1: transaction
    2: origination
    3: delegation
    4: event
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
  id_014__ptkathma__contract_id_tag:
    0: implicit
    1: originated
seq:
- id: id_014__ptkathma__apply_internal_results__alpha__operation_result
  type: id_014__ptkathma__apply_internal_results__alpha__operation_result
