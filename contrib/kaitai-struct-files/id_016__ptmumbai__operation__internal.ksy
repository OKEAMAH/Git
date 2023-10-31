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
    - id: id_016__ptmumbai__apply_internal_results__alpha__operation_result_transaction
      type: id_016__ptmumbai__apply_internal_results__alpha__operation_result_transaction
      if: (id_016__ptmumbai__apply_internal_results__alpha__operation_result_tag ==
        id_016__ptmumbai__apply_internal_results__alpha__operation_result_tag::transaction)
    - id: id_016__ptmumbai__apply_internal_results__alpha__operation_result_origination
      type: id_016__ptmumbai__apply_internal_results__alpha__operation_result_origination
      if: (id_016__ptmumbai__apply_internal_results__alpha__operation_result_tag ==
        id_016__ptmumbai__apply_internal_results__alpha__operation_result_tag::origination)
    - id: id_016__ptmumbai__apply_internal_results__alpha__operation_result_delegation
      type: id_016__ptmumbai__apply_internal_results__alpha__operation_result_delegation
      if: (id_016__ptmumbai__apply_internal_results__alpha__operation_result_tag ==
        id_016__ptmumbai__apply_internal_results__alpha__operation_result_tag::delegation)
    - id: id_016__ptmumbai__apply_internal_results__alpha__operation_result_event
      type: id_016__ptmumbai__apply_internal_results__alpha__operation_result_event
      if: (id_016__ptmumbai__apply_internal_results__alpha__operation_result_tag ==
        id_016__ptmumbai__apply_internal_results__alpha__operation_result_tag::event)
  id_016__ptmumbai__apply_internal_results__alpha__operation_result_event:
    seq:
    - id: type
      type: micheline__016__ptmumbai__michelson_v1__expression
    - id: tag_tag
      type: u1
      enum: bool
    - id: tag
      type: id_016__ptmumbai__entrypoint
      if: (tag_tag == bool::true)
      doc: ! 'entrypoint: Named entrypoint to a Michelson smart contract'
    - id: payload_tag
      type: u1
      enum: bool
    - id: payload
      type: micheline__016__ptmumbai__michelson_v1__expression
      if: (payload_tag == bool::true)
  micheline__016__ptmumbai__michelson_v1__expression:
    seq:
    - id: micheline__016__ptmumbai__michelson_v1__expression_tag
      type: u1
      enum: micheline__016__ptmumbai__michelson_v1__expression_tag
    - id: micheline__016__ptmumbai__michelson_v1__expression_int
      type: z
      if: (micheline__016__ptmumbai__michelson_v1__expression_tag == micheline__016__ptmumbai__michelson_v1__expression_tag::int)
    - id: micheline__016__ptmumbai__michelson_v1__expression_string
      type: string
      if: (micheline__016__ptmumbai__michelson_v1__expression_tag == micheline__016__ptmumbai__michelson_v1__expression_tag::string)
    - id: micheline__016__ptmumbai__michelson_v1__expression_sequence
      type: micheline__016__ptmumbai__michelson_v1__expression_sequence
      if: (micheline__016__ptmumbai__michelson_v1__expression_tag == micheline__016__ptmumbai__michelson_v1__expression_tag::sequence)
    - id: micheline__016__ptmumbai__michelson_v1__expression_prim__no_args__no_annots
      type: u1
      if: (micheline__016__ptmumbai__michelson_v1__expression_tag == micheline__016__ptmumbai__michelson_v1__expression_tag::prim__no_args__no_annots)
      enum: id_016__ptmumbai__michelson__v1__primitives
    - id: micheline__016__ptmumbai__michelson_v1__expression_prim__no_args__some_annots
      type: micheline__016__ptmumbai__michelson_v1__expression_prim__no_args__some_annots
      if: (micheline__016__ptmumbai__michelson_v1__expression_tag == micheline__016__ptmumbai__michelson_v1__expression_tag::prim__no_args__some_annots)
    - id: micheline__016__ptmumbai__michelson_v1__expression_prim__1_arg__no_annots
      type: micheline__016__ptmumbai__michelson_v1__expression_prim__1_arg__no_annots
      if: (micheline__016__ptmumbai__michelson_v1__expression_tag == micheline__016__ptmumbai__michelson_v1__expression_tag::prim__1_arg__no_annots)
    - id: micheline__016__ptmumbai__michelson_v1__expression_prim__1_arg__some_annots
      type: micheline__016__ptmumbai__michelson_v1__expression_prim__1_arg__some_annots
      if: (micheline__016__ptmumbai__michelson_v1__expression_tag == micheline__016__ptmumbai__michelson_v1__expression_tag::prim__1_arg__some_annots)
    - id: micheline__016__ptmumbai__michelson_v1__expression_prim__2_args__no_annots
      type: micheline__016__ptmumbai__michelson_v1__expression_prim__2_args__no_annots
      if: (micheline__016__ptmumbai__michelson_v1__expression_tag == micheline__016__ptmumbai__michelson_v1__expression_tag::prim__2_args__no_annots)
    - id: micheline__016__ptmumbai__michelson_v1__expression_prim__2_args__some_annots
      type: micheline__016__ptmumbai__michelson_v1__expression_prim__2_args__some_annots
      if: (micheline__016__ptmumbai__michelson_v1__expression_tag == micheline__016__ptmumbai__michelson_v1__expression_tag::prim__2_args__some_annots)
    - id: micheline__016__ptmumbai__michelson_v1__expression_prim__generic
      type: micheline__016__ptmumbai__michelson_v1__expression_prim__generic
      if: (micheline__016__ptmumbai__michelson_v1__expression_tag == micheline__016__ptmumbai__michelson_v1__expression_tag::prim__generic)
    - id: micheline__016__ptmumbai__michelson_v1__expression_bytes
      type: bytes
      if: (micheline__016__ptmumbai__michelson_v1__expression_tag == micheline__016__ptmumbai__michelson_v1__expression_tag::bytes)
  bytes:
    seq:
    - id: size_of_bytes
      type: u4
      valid:
        max: 1073741823
    - id: bytes
      size: size_of_bytes
  micheline__016__ptmumbai__michelson_v1__expression_prim__generic:
    seq:
    - id: prim
      type: u1
      enum: id_016__ptmumbai__michelson__v1__primitives
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
      type: micheline__016__ptmumbai__michelson_v1__expression
  micheline__016__ptmumbai__michelson_v1__expression_prim__2_args__some_annots:
    seq:
    - id: prim
      type: u1
      enum: id_016__ptmumbai__michelson__v1__primitives
    - id: arg1
      type: micheline__016__ptmumbai__michelson_v1__expression
    - id: arg2
      type: micheline__016__ptmumbai__michelson_v1__expression
    - id: annots
      type: annots
  micheline__016__ptmumbai__michelson_v1__expression_prim__2_args__no_annots:
    seq:
    - id: prim
      type: u1
      enum: id_016__ptmumbai__michelson__v1__primitives
    - id: arg1
      type: micheline__016__ptmumbai__michelson_v1__expression
    - id: arg2
      type: micheline__016__ptmumbai__michelson_v1__expression
  micheline__016__ptmumbai__michelson_v1__expression_prim__1_arg__some_annots:
    seq:
    - id: prim
      type: u1
      enum: id_016__ptmumbai__michelson__v1__primitives
    - id: arg
      type: micheline__016__ptmumbai__michelson_v1__expression
    - id: annots
      type: annots
  micheline__016__ptmumbai__michelson_v1__expression_prim__1_arg__no_annots:
    seq:
    - id: prim
      type: u1
      enum: id_016__ptmumbai__michelson__v1__primitives
    - id: arg
      type: micheline__016__ptmumbai__michelson_v1__expression
  micheline__016__ptmumbai__michelson_v1__expression_prim__no_args__some_annots:
    seq:
    - id: prim
      type: u1
      enum: id_016__ptmumbai__michelson__v1__primitives
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
  micheline__016__ptmumbai__michelson_v1__expression_sequence:
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
      type: micheline__016__ptmumbai__michelson_v1__expression
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
  id_016__ptmumbai__apply_internal_results__alpha__operation_result_delegation:
    seq:
    - id: delegate_tag
      type: u1
      enum: bool
    - id: delegate
      type: public_key_hash
      if: (delegate_tag == bool::true)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
  id_016__ptmumbai__apply_internal_results__alpha__operation_result_origination:
    seq:
    - id: balance
      type: n
    - id: delegate_tag
      type: u1
      enum: bool
    - id: delegate
      type: public_key_hash
      if: (delegate_tag == bool::true)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: script
      type: id_016__ptmumbai__scripted__contracts
  id_016__ptmumbai__scripted__contracts:
    seq:
    - id: code
      type: code
    - id: storage
      type: storage
  storage:
    seq:
    - id: size_of_storage
      type: u4
      valid:
        max: 1073741823
    - id: storage
      size: size_of_storage
  code:
    seq:
    - id: size_of_code
      type: u4
      valid:
        max: 1073741823
    - id: code
      size: size_of_code
  id_016__ptmumbai__apply_internal_results__alpha__operation_result_transaction:
    seq:
    - id: amount
      type: n
    - id: destination
      type: id_016__ptmumbai__transaction_destination
      doc: ! >-
        A destination of a transaction: A destination notation compatible with the
        contract notation as given to an RPC or inside scripts. Can be a base58 implicit
        contract hash, a base58 originated contract hash, a base58 originated transaction
        rollup, or a base58 originated smart rollup.
    - id: parameters_tag
      type: u1
      enum: bool
    - id: parameters
      type: parameters
      if: (parameters_tag == bool::true)
  parameters:
    seq:
    - id: entrypoint
      type: id_016__ptmumbai__entrypoint
      doc: ! 'entrypoint: Named entrypoint to a Michelson smart contract'
    - id: value
      type: value
  value:
    seq:
    - id: size_of_value
      type: u4
      valid:
        max: 1073741823
    - id: value
      size: size_of_value
  id_016__ptmumbai__entrypoint:
    seq:
    - id: id_016__ptmumbai__entrypoint_tag
      type: u1
      enum: id_016__ptmumbai__entrypoint_tag
    - id: id_016__ptmumbai__entrypoint_named
      type: id_016__ptmumbai__entrypoint_named
      if: (id_016__ptmumbai__entrypoint_tag == id_016__ptmumbai__entrypoint_tag::named)
  id_016__ptmumbai__entrypoint_named:
    seq:
    - id: size_of_named
      type: u1
      valid:
        max: 31
    - id: named
      size: size_of_named
      size-eos: true
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
    - id: id_016__ptmumbai__transaction_destination_implicit
      type: public_key_hash
      if: (id_016__ptmumbai__transaction_destination_tag == id_016__ptmumbai__transaction_destination_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: id_016__ptmumbai__transaction_destination_originated
      type: id_016__ptmumbai__transaction_destination_originated
      if: (id_016__ptmumbai__transaction_destination_tag == id_016__ptmumbai__transaction_destination_tag::originated)
    - id: id_016__ptmumbai__transaction_destination_tx_rollup
      type: id_016__ptmumbai__transaction_destination_tx_rollup
      if: (id_016__ptmumbai__transaction_destination_tag == id_016__ptmumbai__transaction_destination_tag::tx_rollup)
    - id: id_016__ptmumbai__transaction_destination_smart_rollup
      type: id_016__ptmumbai__transaction_destination_smart_rollup
      if: (id_016__ptmumbai__transaction_destination_tag == id_016__ptmumbai__transaction_destination_tag::smart_rollup)
    - id: id_016__ptmumbai__transaction_destination_zk_rollup
      type: id_016__ptmumbai__transaction_destination_zk_rollup
      if: (id_016__ptmumbai__transaction_destination_tag == id_016__ptmumbai__transaction_destination_tag::zk_rollup)
  id_016__ptmumbai__transaction_destination_zk_rollup:
    seq:
    - id: zk_rollup_hash
      size: 20
    - id: zk_rollup_padding
      size: 1
      doc: This field is for padding, ignore
  id_016__ptmumbai__transaction_destination_smart_rollup:
    seq:
    - id: smart_rollup_hash
      size: 20
    - id: smart_rollup_padding
      size: 1
      doc: This field is for padding, ignore
  id_016__ptmumbai__transaction_destination_tx_rollup:
    seq:
    - id: id_016__ptmumbai__tx_rollup_id
      size: 20
      doc: ! >-
        A tx rollup handle: A tx rollup notation as given to an RPC or inside scripts,
        is a base58 tx rollup hash
    - id: tx_rollup_padding
      size: 1
      doc: This field is for padding, ignore
  id_016__ptmumbai__transaction_destination_originated:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: public_key_hash_ed25519
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: public_key_hash_secp256k1
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: public_key_hash_p256
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: public_key_hash_bls
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
enums:
  id_016__ptmumbai__michelson__v1__primitives:
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
    3: prim__no_args__no_annots
    4: prim__no_args__some_annots
    5: prim__1_arg__no_annots
    6: prim__1_arg__some_annots
    7: prim__2_args__no_annots
    8: prim__2_args__some_annots
    9: prim__generic
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
