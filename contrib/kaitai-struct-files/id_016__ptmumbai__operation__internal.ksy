meta:
  id: id_016__ptmumbai__operation__internal
  endian: be
doc: ! 'Encoding id: 016-PtMumbai.operation.internal'
types:
  id_016__ptmumbai__apply_internal_results__alpha__operation_result:
    seq:
    - id: source
      type: id_016__ptmumbai__transaction_destination
      doc: ! >-
        A destination of a transaction: A destination notation compatible with the
        contract notation as given to an RPC or inside scripts. Can be a base58 implicit
        contract hash, a base58 originated contract hash, a base58 originated transaction
        rollup, or a base58 originated smart rollup.
    - id: nonce
      type: u2
    - id: id_016__ptmumbai__apply_internal_results__alpha__operation_result_tag
      type: u1
      enum: id_016__ptmumbai__apply_internal_results__alpha__operation_result_tag
    - id: transaction__id_016__ptmumbai__apply_internal_results__alpha__operation_result
      type: transaction__id_016__ptmumbai__apply_internal_results__alpha__operation_result
      if: (id_016__ptmumbai__apply_internal_results__alpha__operation_result_tag ==
        id_016__ptmumbai__apply_internal_results__alpha__operation_result_tag::transaction)
    - id: origination__id_016__ptmumbai__apply_internal_results__alpha__operation_result
      type: origination__id_016__ptmumbai__apply_internal_results__alpha__operation_result
      if: (id_016__ptmumbai__apply_internal_results__alpha__operation_result_tag ==
        id_016__ptmumbai__apply_internal_results__alpha__operation_result_tag::origination)
    - id: delegation__id_016__ptmumbai__apply_internal_results__alpha__operation_result
      type: delegation__id_016__ptmumbai__apply_internal_results__alpha__operation_result
      if: (id_016__ptmumbai__apply_internal_results__alpha__operation_result_tag ==
        id_016__ptmumbai__apply_internal_results__alpha__operation_result_tag::delegation)
    - id: event__id_016__ptmumbai__apply_internal_results__alpha__operation_result
      type: event__id_016__ptmumbai__apply_internal_results__alpha__operation_result
      if: (id_016__ptmumbai__apply_internal_results__alpha__operation_result_tag ==
        id_016__ptmumbai__apply_internal_results__alpha__operation_result_tag::event)
  event__id_016__ptmumbai__apply_internal_results__alpha__operation_result:
    seq:
    - id: type
      type: event__micheline__016__ptmumbai__michelson_v1__expression
    - id: tag_tag
      type: u1
      enum: bool
    - id: tag
      type: event__id_016__ptmumbai__entrypoint
      if: (tag_tag == bool::true)
      doc: ! 'entrypoint: Named entrypoint to a Michelson smart contract'
    - id: payload_tag
      type: u1
      enum: bool
    - id: payload
      type: micheline__016__ptmumbai__michelson_v1__expression
      if: (payload_tag == bool::true)
  event__id_016__ptmumbai__entrypoint:
    seq:
    - id: id_016__ptmumbai__entrypoint_tag
      type: u1
      enum: id_016__ptmumbai__entrypoint_tag
    - id: event__named__id_016__ptmumbai__entrypoint
      type: event__named__id_016__ptmumbai__entrypoint
      if: (id_016__ptmumbai__entrypoint_tag == id_016__ptmumbai__entrypoint_tag::named)
  event__named__id_016__ptmumbai__entrypoint:
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
  event__micheline__016__ptmumbai__michelson_v1__expression:
    seq:
    - id: micheline__016__ptmumbai__michelson_v1__expression_tag
      type: u1
      enum: micheline__016__ptmumbai__michelson_v1__expression_tag
    - id: event__int__micheline__016__ptmumbai__michelson_v1__expression
      type: z
      if: (micheline__016__ptmumbai__michelson_v1__expression_tag == micheline__016__ptmumbai__michelson_v1__expression_tag::int)
    - id: event__string__micheline__016__ptmumbai__michelson_v1__expression
      type: event__string__string
      if: (micheline__016__ptmumbai__michelson_v1__expression_tag == micheline__016__ptmumbai__michelson_v1__expression_tag::string)
    - id: event__sequence__micheline__016__ptmumbai__michelson_v1__expression
      type: event__sequence__micheline__016__ptmumbai__michelson_v1__expression
      if: (micheline__016__ptmumbai__michelson_v1__expression_tag == micheline__016__ptmumbai__michelson_v1__expression_tag::sequence)
    - id: event__prim__no_args__no_annots__micheline__016__ptmumbai__michelson_v1__expression
      type: u1
      if: (micheline__016__ptmumbai__michelson_v1__expression_tag == micheline__016__ptmumbai__michelson_v1__expression_tag::prim__no_args__no_annots)
      enum: event__prim__no_args__no_annots__id_016__ptmumbai__michelson__v1__primitives
    - id: event__prim__no_args__some_annots__micheline__016__ptmumbai__michelson_v1__expression
      type: event__prim__no_args__some_annots__micheline__016__ptmumbai__michelson_v1__expression
      if: (micheline__016__ptmumbai__michelson_v1__expression_tag == micheline__016__ptmumbai__michelson_v1__expression_tag::prim__no_args__some_annots)
    - id: event__prim__1_arg__no_annots__micheline__016__ptmumbai__michelson_v1__expression
      type: event__prim__1_arg__no_annots__micheline__016__ptmumbai__michelson_v1__expression
      if: (micheline__016__ptmumbai__michelson_v1__expression_tag == micheline__016__ptmumbai__michelson_v1__expression_tag::prim__1_arg__no_annots)
    - id: event__prim__1_arg__some_annots__micheline__016__ptmumbai__michelson_v1__expression
      type: event__prim__1_arg__some_annots__micheline__016__ptmumbai__michelson_v1__expression
      if: (micheline__016__ptmumbai__michelson_v1__expression_tag == micheline__016__ptmumbai__michelson_v1__expression_tag::prim__1_arg__some_annots)
    - id: event__prim__2_args__no_annots__micheline__016__ptmumbai__michelson_v1__expression
      type: event__prim__2_args__no_annots__micheline__016__ptmumbai__michelson_v1__expression
      if: (micheline__016__ptmumbai__michelson_v1__expression_tag == micheline__016__ptmumbai__michelson_v1__expression_tag::prim__2_args__no_annots)
    - id: event__prim__2_args__some_annots__micheline__016__ptmumbai__michelson_v1__expression
      type: event__prim__2_args__some_annots__micheline__016__ptmumbai__michelson_v1__expression
      if: (micheline__016__ptmumbai__michelson_v1__expression_tag == micheline__016__ptmumbai__michelson_v1__expression_tag::prim__2_args__some_annots)
    - id: event__prim__generic__micheline__016__ptmumbai__michelson_v1__expression
      type: event__prim__generic__micheline__016__ptmumbai__michelson_v1__expression
      if: (micheline__016__ptmumbai__michelson_v1__expression_tag == micheline__016__ptmumbai__michelson_v1__expression_tag::prim__generic)
    - id: event__bytes__micheline__016__ptmumbai__michelson_v1__expression
      type: event__bytes__bytes
      if: (micheline__016__ptmumbai__michelson_v1__expression_tag == micheline__016__ptmumbai__michelson_v1__expression_tag::bytes)
  event__bytes__bytes:
    seq:
    - id: len_bytes
      type: u4
      valid:
        max: 1073741823
    - id: bytes
      size: len_bytes
  event__prim__generic__micheline__016__ptmumbai__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: event__prim__generic__id_016__ptmumbai__michelson__v1__primitives
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
      type: micheline__016__ptmumbai__michelson_v1__expression
  event__prim__2_args__some_annots__micheline__016__ptmumbai__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: event__prim__2_args__some_annots__id_016__ptmumbai__michelson__v1__primitives
    - id: arg1
      type: micheline__016__ptmumbai__michelson_v1__expression
    - id: arg2
      type: micheline__016__ptmumbai__michelson_v1__expression
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
  event__prim__2_args__no_annots__micheline__016__ptmumbai__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: event__prim__2_args__no_annots__id_016__ptmumbai__michelson__v1__primitives
    - id: arg1
      type: micheline__016__ptmumbai__michelson_v1__expression
    - id: arg2
      type: micheline__016__ptmumbai__michelson_v1__expression
  event__prim__1_arg__some_annots__micheline__016__ptmumbai__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: event__prim__1_arg__some_annots__id_016__ptmumbai__michelson__v1__primitives
    - id: arg
      type: micheline__016__ptmumbai__michelson_v1__expression
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
  event__prim__1_arg__no_annots__micheline__016__ptmumbai__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: event__prim__1_arg__no_annots__id_016__ptmumbai__michelson__v1__primitives
    - id: arg
      type: micheline__016__ptmumbai__michelson_v1__expression
  event__prim__no_args__some_annots__micheline__016__ptmumbai__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: event__prim__no_args__some_annots__id_016__ptmumbai__michelson__v1__primitives
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
  event__sequence__micheline__016__ptmumbai__michelson_v1__expression:
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
      type: micheline__016__ptmumbai__michelson_v1__expression
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
  delegation__id_016__ptmumbai__apply_internal_results__alpha__operation_result:
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
  origination__id_016__ptmumbai__apply_internal_results__alpha__operation_result:
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
      type: origination__id_016__ptmumbai__scripted__contracts
  origination__id_016__ptmumbai__scripted__contracts:
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
  transaction__id_016__ptmumbai__apply_internal_results__alpha__operation_result:
    seq:
    - id: amount
      type: n
    - id: destination
      type: transaction__id_016__ptmumbai__transaction_destination
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
      type: transaction__id_016__ptmumbai__entrypoint
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
  transaction__id_016__ptmumbai__entrypoint:
    seq:
    - id: id_016__ptmumbai__entrypoint_tag
      type: u1
      enum: id_016__ptmumbai__entrypoint_tag
    - id: transaction__named__id_016__ptmumbai__entrypoint
      type: transaction__named__id_016__ptmumbai__entrypoint
      if: (id_016__ptmumbai__entrypoint_tag == id_016__ptmumbai__entrypoint_tag::named)
  transaction__named__id_016__ptmumbai__entrypoint:
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
  transaction__id_016__ptmumbai__transaction_destination:
    seq:
    - id: id_016__ptmumbai__transaction_destination_tag
      type: u1
      enum: id_016__ptmumbai__transaction_destination_tag
    - id: transaction__implicit__id_016__ptmumbai__transaction_destination
      type: transaction__implicit__public_key_hash
      if: (id_016__ptmumbai__transaction_destination_tag == id_016__ptmumbai__transaction_destination_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: transaction__originated__id_016__ptmumbai__transaction_destination
      type: transaction__originated__id_016__ptmumbai__transaction_destination
      if: (id_016__ptmumbai__transaction_destination_tag == id_016__ptmumbai__transaction_destination_tag::originated)
    - id: transaction__tx_rollup__id_016__ptmumbai__transaction_destination
      type: transaction__tx_rollup__id_016__ptmumbai__transaction_destination
      if: (id_016__ptmumbai__transaction_destination_tag == id_016__ptmumbai__transaction_destination_tag::tx_rollup)
    - id: transaction__smart_rollup__id_016__ptmumbai__transaction_destination
      type: transaction__smart_rollup__id_016__ptmumbai__transaction_destination
      if: (id_016__ptmumbai__transaction_destination_tag == id_016__ptmumbai__transaction_destination_tag::smart_rollup)
    - id: transaction__zk_rollup__id_016__ptmumbai__transaction_destination
      type: transaction__zk_rollup__id_016__ptmumbai__transaction_destination
      if: (id_016__ptmumbai__transaction_destination_tag == id_016__ptmumbai__transaction_destination_tag::zk_rollup)
  transaction__zk_rollup__id_016__ptmumbai__transaction_destination:
    seq:
    - id: zk_rollup_hash
      size: 20
    - id: zk_rollup_padding
      size: 1
      doc: This field is for padding, ignore
  transaction__smart_rollup__id_016__ptmumbai__transaction_destination:
    seq:
    - id: smart_rollup_hash
      size: 20
    - id: smart_rollup_padding
      size: 1
      doc: This field is for padding, ignore
  transaction__tx_rollup__id_016__ptmumbai__transaction_destination:
    seq:
    - id: id_016__ptmumbai__tx_rollup_id
      size: 20
      doc: ! >-
        A tx rollup handle: A tx rollup notation as given to an RPC or inside scripts,
        is a base58 tx rollup hash
    - id: tx_rollup_padding
      size: 1
      doc: This field is for padding, ignore
  transaction__originated__id_016__ptmumbai__transaction_destination:
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
  id_016__ptmumbai__transaction_destination:
    seq:
    - id: id_016__ptmumbai__transaction_destination_tag
      type: u1
      enum: id_016__ptmumbai__transaction_destination_tag
    - id: implicit__id_016__ptmumbai__transaction_destination
      type: implicit__public_key_hash
      if: (id_016__ptmumbai__transaction_destination_tag == id_016__ptmumbai__transaction_destination_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: originated__id_016__ptmumbai__transaction_destination
      type: originated__id_016__ptmumbai__transaction_destination
      if: (id_016__ptmumbai__transaction_destination_tag == id_016__ptmumbai__transaction_destination_tag::originated)
    - id: tx_rollup__id_016__ptmumbai__transaction_destination
      type: tx_rollup__id_016__ptmumbai__transaction_destination
      if: (id_016__ptmumbai__transaction_destination_tag == id_016__ptmumbai__transaction_destination_tag::tx_rollup)
    - id: smart_rollup__id_016__ptmumbai__transaction_destination
      type: smart_rollup__id_016__ptmumbai__transaction_destination
      if: (id_016__ptmumbai__transaction_destination_tag == id_016__ptmumbai__transaction_destination_tag::smart_rollup)
    - id: zk_rollup__id_016__ptmumbai__transaction_destination
      type: zk_rollup__id_016__ptmumbai__transaction_destination
      if: (id_016__ptmumbai__transaction_destination_tag == id_016__ptmumbai__transaction_destination_tag::zk_rollup)
  zk_rollup__id_016__ptmumbai__transaction_destination:
    seq:
    - id: zk_rollup_hash
      size: 20
    - id: zk_rollup_padding
      size: 1
      doc: This field is for padding, ignore
  smart_rollup__id_016__ptmumbai__transaction_destination:
    seq:
    - id: smart_rollup_hash
      size: 20
    - id: smart_rollup_padding
      size: 1
      doc: This field is for padding, ignore
  tx_rollup__id_016__ptmumbai__transaction_destination:
    seq:
    - id: id_016__ptmumbai__tx_rollup_id
      size: 20
      doc: ! >-
        A tx rollup handle: A tx rollup notation as given to an RPC or inside scripts,
        is a base58 tx rollup hash
    - id: tx_rollup_padding
      size: 1
      doc: This field is for padding, ignore
  originated__id_016__ptmumbai__transaction_destination:
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
  event__prim__generic__id_016__ptmumbai__michelson__v1__primitives:
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
    120: never
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
    131: sapling_state
    106: mutez
    140: get_and_update
    90: contract
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    105: bytes
    52: loop
    34: ediv
    129: bls12_381_g2
    142: chest_key
    138: split_ticket
    141: chest
    5: left
    51: left
    125: keccak
    99: option
    48: int
    58: mul
    35: empty_map
    76: swap
    132: sapling_transaction_deprecated
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    146: constant
    66: pair
    124: total_voting_power
    80: update
    22: car
    101: pair
    61: nil
    21: balance
    95: list
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
    100: or
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    97: big_map
    123: voting_power
    96: map
    18: add
    93: key_hash
    75: sub
    6: none
    114: empty_big_map
    135: ticket
    103: signature
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    155: bytes
    4: elt
    115: apply
    56: map
    116: chain_id
    25: compare
    20: and
    94: lambda
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    104: string
    148: tx_rollup_l2_address
    109: operation
    128: bls12_381_g1
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    110: address
    92: key
    54: lsr
    102: set
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    89: bool
    59: neg
    98: nat
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    107: timestamp
    91: int
    47: if_none
    7: pair
    130: bls12_381_fr
    108: unit
    156: nat
    13: unpack
    150: sapling_transaction
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  event__prim__2_args__some_annots__id_016__ptmumbai__michelson__v1__primitives:
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
    120: never
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
    131: sapling_state
    106: mutez
    140: get_and_update
    90: contract
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    105: bytes
    52: loop
    34: ediv
    129: bls12_381_g2
    142: chest_key
    138: split_ticket
    141: chest
    5: left
    51: left
    125: keccak
    99: option
    48: int
    58: mul
    35: empty_map
    76: swap
    132: sapling_transaction_deprecated
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    146: constant
    66: pair
    124: total_voting_power
    80: update
    22: car
    101: pair
    61: nil
    21: balance
    95: list
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
    100: or
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    97: big_map
    123: voting_power
    96: map
    18: add
    93: key_hash
    75: sub
    6: none
    114: empty_big_map
    135: ticket
    103: signature
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    155: bytes
    4: elt
    115: apply
    56: map
    116: chain_id
    25: compare
    20: and
    94: lambda
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    104: string
    148: tx_rollup_l2_address
    109: operation
    128: bls12_381_g1
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    110: address
    92: key
    54: lsr
    102: set
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    89: bool
    59: neg
    98: nat
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    107: timestamp
    91: int
    47: if_none
    7: pair
    130: bls12_381_fr
    108: unit
    156: nat
    13: unpack
    150: sapling_transaction
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  event__prim__2_args__no_annots__id_016__ptmumbai__michelson__v1__primitives:
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
    120: never
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
    131: sapling_state
    106: mutez
    140: get_and_update
    90: contract
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    105: bytes
    52: loop
    34: ediv
    129: bls12_381_g2
    142: chest_key
    138: split_ticket
    141: chest
    5: left
    51: left
    125: keccak
    99: option
    48: int
    58: mul
    35: empty_map
    76: swap
    132: sapling_transaction_deprecated
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    146: constant
    66: pair
    124: total_voting_power
    80: update
    22: car
    101: pair
    61: nil
    21: balance
    95: list
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
    100: or
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    97: big_map
    123: voting_power
    96: map
    18: add
    93: key_hash
    75: sub
    6: none
    114: empty_big_map
    135: ticket
    103: signature
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    155: bytes
    4: elt
    115: apply
    56: map
    116: chain_id
    25: compare
    20: and
    94: lambda
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    104: string
    148: tx_rollup_l2_address
    109: operation
    128: bls12_381_g1
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    110: address
    92: key
    54: lsr
    102: set
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    89: bool
    59: neg
    98: nat
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    107: timestamp
    91: int
    47: if_none
    7: pair
    130: bls12_381_fr
    108: unit
    156: nat
    13: unpack
    150: sapling_transaction
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  event__prim__1_arg__some_annots__id_016__ptmumbai__michelson__v1__primitives:
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
    120: never
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
    131: sapling_state
    106: mutez
    140: get_and_update
    90: contract
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    105: bytes
    52: loop
    34: ediv
    129: bls12_381_g2
    142: chest_key
    138: split_ticket
    141: chest
    5: left
    51: left
    125: keccak
    99: option
    48: int
    58: mul
    35: empty_map
    76: swap
    132: sapling_transaction_deprecated
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    146: constant
    66: pair
    124: total_voting_power
    80: update
    22: car
    101: pair
    61: nil
    21: balance
    95: list
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
    100: or
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    97: big_map
    123: voting_power
    96: map
    18: add
    93: key_hash
    75: sub
    6: none
    114: empty_big_map
    135: ticket
    103: signature
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    155: bytes
    4: elt
    115: apply
    56: map
    116: chain_id
    25: compare
    20: and
    94: lambda
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    104: string
    148: tx_rollup_l2_address
    109: operation
    128: bls12_381_g1
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    110: address
    92: key
    54: lsr
    102: set
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    89: bool
    59: neg
    98: nat
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    107: timestamp
    91: int
    47: if_none
    7: pair
    130: bls12_381_fr
    108: unit
    156: nat
    13: unpack
    150: sapling_transaction
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  event__prim__1_arg__no_annots__id_016__ptmumbai__michelson__v1__primitives:
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
    120: never
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
    131: sapling_state
    106: mutez
    140: get_and_update
    90: contract
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    105: bytes
    52: loop
    34: ediv
    129: bls12_381_g2
    142: chest_key
    138: split_ticket
    141: chest
    5: left
    51: left
    125: keccak
    99: option
    48: int
    58: mul
    35: empty_map
    76: swap
    132: sapling_transaction_deprecated
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    146: constant
    66: pair
    124: total_voting_power
    80: update
    22: car
    101: pair
    61: nil
    21: balance
    95: list
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
    100: or
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    97: big_map
    123: voting_power
    96: map
    18: add
    93: key_hash
    75: sub
    6: none
    114: empty_big_map
    135: ticket
    103: signature
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    155: bytes
    4: elt
    115: apply
    56: map
    116: chain_id
    25: compare
    20: and
    94: lambda
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    104: string
    148: tx_rollup_l2_address
    109: operation
    128: bls12_381_g1
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    110: address
    92: key
    54: lsr
    102: set
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    89: bool
    59: neg
    98: nat
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    107: timestamp
    91: int
    47: if_none
    7: pair
    130: bls12_381_fr
    108: unit
    156: nat
    13: unpack
    150: sapling_transaction
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  event__prim__no_args__some_annots__id_016__ptmumbai__michelson__v1__primitives:
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
    120: never
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
    131: sapling_state
    106: mutez
    140: get_and_update
    90: contract
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    105: bytes
    52: loop
    34: ediv
    129: bls12_381_g2
    142: chest_key
    138: split_ticket
    141: chest
    5: left
    51: left
    125: keccak
    99: option
    48: int
    58: mul
    35: empty_map
    76: swap
    132: sapling_transaction_deprecated
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    146: constant
    66: pair
    124: total_voting_power
    80: update
    22: car
    101: pair
    61: nil
    21: balance
    95: list
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
    100: or
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    97: big_map
    123: voting_power
    96: map
    18: add
    93: key_hash
    75: sub
    6: none
    114: empty_big_map
    135: ticket
    103: signature
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    155: bytes
    4: elt
    115: apply
    56: map
    116: chain_id
    25: compare
    20: and
    94: lambda
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    104: string
    148: tx_rollup_l2_address
    109: operation
    128: bls12_381_g1
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    110: address
    92: key
    54: lsr
    102: set
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    89: bool
    59: neg
    98: nat
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    107: timestamp
    91: int
    47: if_none
    7: pair
    130: bls12_381_fr
    108: unit
    156: nat
    13: unpack
    150: sapling_transaction
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  event__prim__no_args__no_annots__id_016__ptmumbai__michelson__v1__primitives:
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
    120: never
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
    131: sapling_state
    106: mutez
    140: get_and_update
    90: contract
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    105: bytes
    52: loop
    34: ediv
    129: bls12_381_g2
    142: chest_key
    138: split_ticket
    141: chest
    5: left
    51: left
    125: keccak
    99: option
    48: int
    58: mul
    35: empty_map
    76: swap
    132: sapling_transaction_deprecated
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    146: constant
    66: pair
    124: total_voting_power
    80: update
    22: car
    101: pair
    61: nil
    21: balance
    95: list
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
    100: or
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    97: big_map
    123: voting_power
    96: map
    18: add
    93: key_hash
    75: sub
    6: none
    114: empty_big_map
    135: ticket
    103: signature
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    155: bytes
    4: elt
    115: apply
    56: map
    116: chain_id
    25: compare
    20: and
    94: lambda
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    104: string
    148: tx_rollup_l2_address
    109: operation
    128: bls12_381_g1
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    110: address
    92: key
    54: lsr
    102: set
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    89: bool
    59: neg
    98: nat
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    107: timestamp
    91: int
    47: if_none
    7: pair
    130: bls12_381_fr
    108: unit
    156: nat
    13: unpack
    150: sapling_transaction
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  micheline__016__ptmumbai__michelson_v1__expression_tag:
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
  id_016__ptmumbai__entrypoint_tag:
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
  id_016__ptmumbai__apply_internal_results__alpha__operation_result_tag:
    1: transaction
    2: origination
    3: delegation
    4: event
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
    3: bls
  id_016__ptmumbai__transaction_destination_tag:
    0: implicit
    1: originated
    2: tx_rollup
    3: smart_rollup
    4: zk_rollup
seq:
- id: id_016__ptmumbai__apply_internal_results__alpha__operation_result
  type: id_016__ptmumbai__apply_internal_results__alpha__operation_result
