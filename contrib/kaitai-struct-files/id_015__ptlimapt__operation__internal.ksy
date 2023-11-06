meta:
  id: id_015__ptlimapt__operation__internal
  endian: be
doc: ! 'Encoding id: 015-PtLimaPt.operation.internal'
types:
  id_015__ptlimapt__apply_internal_results__alpha__operation_result:
    seq:
    - id: source
      type: id_015__ptlimapt__contract_id
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: nonce
      type: u2
    - id: id_015__ptlimapt__apply_internal_results__alpha__operation_result_tag
      type: u1
      enum: id_015__ptlimapt__apply_internal_results__alpha__operation_result_tag
    - id: transaction__id_015__ptlimapt__apply_internal_results__alpha__operation_result
      type: transaction__id_015__ptlimapt__apply_internal_results__alpha__operation_result
      if: (id_015__ptlimapt__apply_internal_results__alpha__operation_result_tag ==
        id_015__ptlimapt__apply_internal_results__alpha__operation_result_tag::transaction)
    - id: origination__id_015__ptlimapt__apply_internal_results__alpha__operation_result
      type: origination__id_015__ptlimapt__apply_internal_results__alpha__operation_result
      if: (id_015__ptlimapt__apply_internal_results__alpha__operation_result_tag ==
        id_015__ptlimapt__apply_internal_results__alpha__operation_result_tag::origination)
    - id: delegation__id_015__ptlimapt__apply_internal_results__alpha__operation_result
      type: delegation__id_015__ptlimapt__apply_internal_results__alpha__operation_result
      if: (id_015__ptlimapt__apply_internal_results__alpha__operation_result_tag ==
        id_015__ptlimapt__apply_internal_results__alpha__operation_result_tag::delegation)
    - id: event__id_015__ptlimapt__apply_internal_results__alpha__operation_result
      type: event__id_015__ptlimapt__apply_internal_results__alpha__operation_result
      if: (id_015__ptlimapt__apply_internal_results__alpha__operation_result_tag ==
        id_015__ptlimapt__apply_internal_results__alpha__operation_result_tag::event)
  event__id_015__ptlimapt__apply_internal_results__alpha__operation_result:
    seq:
    - id: type
      type: event__micheline__015__ptlimapt__michelson_v1__expression
    - id: tag_tag
      type: u1
      enum: bool
    - id: tag
      type: event__id_015__ptlimapt__entrypoint
      if: (tag_tag == bool::true)
      doc: ! 'entrypoint: Named entrypoint to a Michelson smart contract'
    - id: payload_tag
      type: u1
      enum: bool
    - id: payload
      type: micheline__015__ptlimapt__michelson_v1__expression
      if: (payload_tag == bool::true)
  event__id_015__ptlimapt__entrypoint:
    seq:
    - id: id_015__ptlimapt__entrypoint_tag
      type: u1
      enum: id_015__ptlimapt__entrypoint_tag
    - id: event__named__id_015__ptlimapt__entrypoint
      type: event__named__id_015__ptlimapt__entrypoint
      if: (id_015__ptlimapt__entrypoint_tag == id_015__ptlimapt__entrypoint_tag::named)
  event__named__id_015__ptlimapt__entrypoint:
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
  event__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: micheline__015__ptlimapt__michelson_v1__expression_tag
      type: u1
      enum: micheline__015__ptlimapt__michelson_v1__expression_tag
    - id: event__int__micheline__015__ptlimapt__michelson_v1__expression
      type: z
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == ::micheline__015__ptlimapt__michelson_v1__expression_tag::micheline__015__ptlimapt__michelson_v1__expression_tag::int)
    - id: event__string__micheline__015__ptlimapt__michelson_v1__expression
      type: event__string__string
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == ::micheline__015__ptlimapt__michelson_v1__expression_tag::micheline__015__ptlimapt__michelson_v1__expression_tag::string)
    - id: event__sequence__micheline__015__ptlimapt__michelson_v1__expression
      type: event__sequence__micheline__015__ptlimapt__michelson_v1__expression
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::sequence)
    - id: event__prim__no_args__no_annots__micheline__015__ptlimapt__michelson_v1__expression
      type: u1
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == ::micheline__015__ptlimapt__michelson_v1__expression_tag::micheline__015__ptlimapt__michelson_v1__expression_tag::prim__no_args__no_annots)
      enum: event__prim__no_args__no_annots__id_015__ptlimapt__michelson__v1__primitives
    - id: event__prim__no_args__some_annots__micheline__015__ptlimapt__michelson_v1__expression
      type: event__prim__no_args__some_annots__micheline__015__ptlimapt__michelson_v1__expression
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::prim__no_args__some_annots)
    - id: event__prim__1_arg__no_annots__micheline__015__ptlimapt__michelson_v1__expression
      type: event__prim__1_arg__no_annots__micheline__015__ptlimapt__michelson_v1__expression
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::prim__1_arg__no_annots)
    - id: event__prim__1_arg__some_annots__micheline__015__ptlimapt__michelson_v1__expression
      type: event__prim__1_arg__some_annots__micheline__015__ptlimapt__michelson_v1__expression
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::prim__1_arg__some_annots)
    - id: event__prim__2_args__no_annots__micheline__015__ptlimapt__michelson_v1__expression
      type: event__prim__2_args__no_annots__micheline__015__ptlimapt__michelson_v1__expression
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::prim__2_args__no_annots)
    - id: event__prim__2_args__some_annots__micheline__015__ptlimapt__michelson_v1__expression
      type: event__prim__2_args__some_annots__micheline__015__ptlimapt__michelson_v1__expression
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::prim__2_args__some_annots)
    - id: event__prim__generic__micheline__015__ptlimapt__michelson_v1__expression
      type: event__prim__generic__micheline__015__ptlimapt__michelson_v1__expression
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::prim__generic)
    - id: event__bytes__micheline__015__ptlimapt__michelson_v1__expression
      type: event__bytes__bytes
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == ::micheline__015__ptlimapt__michelson_v1__expression_tag::micheline__015__ptlimapt__michelson_v1__expression_tag::bytes)
  event__bytes__bytes:
    seq:
    - id: len_bytes
      type: u4
      valid:
        max: 1073741823
    - id: bytes
      size: len_bytes
  event__prim__generic__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: event__prim__generic__id_015__ptlimapt__michelson__v1__primitives
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
      type: micheline__015__ptlimapt__michelson_v1__expression
  event__prim__2_args__some_annots__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: event__prim__2_args__some_annots__id_015__ptlimapt__michelson__v1__primitives
    - id: arg1
      type: micheline__015__ptlimapt__michelson_v1__expression
    - id: arg2
      type: micheline__015__ptlimapt__michelson_v1__expression
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
  event__prim__2_args__no_annots__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: event__prim__2_args__no_annots__id_015__ptlimapt__michelson__v1__primitives
    - id: arg1
      type: micheline__015__ptlimapt__michelson_v1__expression
    - id: arg2
      type: micheline__015__ptlimapt__michelson_v1__expression
  event__prim__1_arg__some_annots__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: event__prim__1_arg__some_annots__id_015__ptlimapt__michelson__v1__primitives
    - id: arg
      type: micheline__015__ptlimapt__michelson_v1__expression
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
  event__prim__1_arg__no_annots__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: event__prim__1_arg__no_annots__id_015__ptlimapt__michelson__v1__primitives
    - id: arg
      type: micheline__015__ptlimapt__michelson_v1__expression
  event__prim__no_args__some_annots__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: event__prim__no_args__some_annots__id_015__ptlimapt__michelson__v1__primitives
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
  event__sequence__micheline__015__ptlimapt__michelson_v1__expression:
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
      type: micheline__015__ptlimapt__michelson_v1__expression
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
  delegation__id_015__ptlimapt__apply_internal_results__alpha__operation_result:
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
  origination__id_015__ptlimapt__apply_internal_results__alpha__operation_result:
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
      type: origination__id_015__ptlimapt__scripted__contracts
  origination__id_015__ptlimapt__scripted__contracts:
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
  transaction__id_015__ptlimapt__apply_internal_results__alpha__operation_result:
    seq:
    - id: amount
      type: n
    - id: destination
      type: transaction__id_015__ptlimapt__transaction_destination
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
      type: transaction__id_015__ptlimapt__entrypoint
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
  transaction__id_015__ptlimapt__entrypoint:
    seq:
    - id: id_015__ptlimapt__entrypoint_tag
      type: u1
      enum: id_015__ptlimapt__entrypoint_tag
    - id: transaction__named__id_015__ptlimapt__entrypoint
      type: transaction__named__id_015__ptlimapt__entrypoint
      if: (id_015__ptlimapt__entrypoint_tag == id_015__ptlimapt__entrypoint_tag::named)
  transaction__named__id_015__ptlimapt__entrypoint:
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
  transaction__id_015__ptlimapt__transaction_destination:
    seq:
    - id: id_015__ptlimapt__transaction_destination_tag
      type: u1
      enum: id_015__ptlimapt__transaction_destination_tag
    - id: transaction__implicit__id_015__ptlimapt__transaction_destination
      type: transaction__implicit__public_key_hash
      if: (id_015__ptlimapt__transaction_destination_tag == ::id_015__ptlimapt__transaction_destination_tag::id_015__ptlimapt__transaction_destination_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: transaction__originated__id_015__ptlimapt__transaction_destination
      type: transaction__originated__id_015__ptlimapt__transaction_destination
      if: (id_015__ptlimapt__transaction_destination_tag == id_015__ptlimapt__transaction_destination_tag::originated)
    - id: transaction__tx_rollup__id_015__ptlimapt__transaction_destination
      type: transaction__tx_rollup__id_015__ptlimapt__transaction_destination
      if: (id_015__ptlimapt__transaction_destination_tag == id_015__ptlimapt__transaction_destination_tag::tx_rollup)
    - id: transaction__sc_rollup__id_015__ptlimapt__transaction_destination
      type: transaction__sc_rollup__id_015__ptlimapt__transaction_destination
      if: (id_015__ptlimapt__transaction_destination_tag == id_015__ptlimapt__transaction_destination_tag::sc_rollup)
    - id: transaction__zk_rollup__id_015__ptlimapt__transaction_destination
      type: transaction__zk_rollup__id_015__ptlimapt__transaction_destination
      if: (id_015__ptlimapt__transaction_destination_tag == id_015__ptlimapt__transaction_destination_tag::zk_rollup)
  transaction__zk_rollup__id_015__ptlimapt__transaction_destination:
    seq:
    - id: zk_rollup_hash
      size: 20
    - id: zk_rollup_padding
      size: 1
      doc: This field is for padding, ignore
  transaction__sc_rollup__id_015__ptlimapt__transaction_destination:
    seq:
    - id: sc_rollup_hash
      size: 20
    - id: sc_rollup_padding
      size: 1
      doc: This field is for padding, ignore
  transaction__tx_rollup__id_015__ptlimapt__transaction_destination:
    seq:
    - id: id_015__ptlimapt__tx_rollup_id
      size: 20
      doc: ! >-
        A tx rollup handle: A tx rollup notation as given to an RPC or inside scripts,
        is a base58 tx rollup hash
    - id: tx_rollup_padding
      size: 1
      doc: This field is for padding, ignore
  transaction__originated__id_015__ptlimapt__transaction_destination:
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
  id_015__ptlimapt__contract_id:
    seq:
    - id: id_015__ptlimapt__contract_id_tag
      type: u1
      enum: id_015__ptlimapt__contract_id_tag
    - id: implicit__id_015__ptlimapt__contract_id
      type: implicit__public_key_hash
      if: (id_015__ptlimapt__contract_id_tag == ::id_015__ptlimapt__contract_id_tag::id_015__ptlimapt__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: originated__id_015__ptlimapt__contract_id
      type: originated__id_015__ptlimapt__contract_id
      if: (id_015__ptlimapt__contract_id_tag == id_015__ptlimapt__contract_id_tag::originated)
  originated__id_015__ptlimapt__contract_id:
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
  event__prim__generic__id_015__ptlimapt__michelson__v1__primitives:
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
  event__prim__2_args__some_annots__id_015__ptlimapt__michelson__v1__primitives:
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
  event__prim__2_args__no_annots__id_015__ptlimapt__michelson__v1__primitives:
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
  event__prim__1_arg__some_annots__id_015__ptlimapt__michelson__v1__primitives:
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
  event__prim__1_arg__no_annots__id_015__ptlimapt__michelson__v1__primitives:
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
  event__prim__no_args__some_annots__id_015__ptlimapt__michelson__v1__primitives:
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
  event__prim__no_args__no_annots__id_015__ptlimapt__michelson__v1__primitives:
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
  id_015__ptlimapt__entrypoint_tag:
    0: default
    1: root
    2: do
    3: set_delegate
    4: remove_delegate
    5: deposit
    255: named
  bool:
    0: false
    255: true
  id_015__ptlimapt__transaction_destination_tag:
    0: implicit
    1: originated
    2: tx_rollup
    3: sc_rollup
    4: zk_rollup
  id_015__ptlimapt__apply_internal_results__alpha__operation_result_tag:
    1: transaction
    2: origination
    3: delegation
    4: event
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
  id_015__ptlimapt__contract_id_tag:
    0: implicit
    1: originated
seq:
- id: id_015__ptlimapt__apply_internal_results__alpha__operation_result
  type: id_015__ptlimapt__apply_internal_results__alpha__operation_result
