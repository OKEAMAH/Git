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
    - id: id_015__ptlimapt__apply_internal_results__alpha__operation_result_transaction
      type: id_015__ptlimapt__apply_internal_results__alpha__operation_result_transaction
      if: (id_015__ptlimapt__apply_internal_results__alpha__operation_result_tag ==
        id_015__ptlimapt__apply_internal_results__alpha__operation_result_tag::transaction)
    - id: id_015__ptlimapt__apply_internal_results__alpha__operation_result_origination
      type: id_015__ptlimapt__apply_internal_results__alpha__operation_result_origination
      if: (id_015__ptlimapt__apply_internal_results__alpha__operation_result_tag ==
        id_015__ptlimapt__apply_internal_results__alpha__operation_result_tag::origination)
    - id: id_015__ptlimapt__apply_internal_results__alpha__operation_result_delegation
      type: id_015__ptlimapt__apply_internal_results__alpha__operation_result_delegation
      if: (id_015__ptlimapt__apply_internal_results__alpha__operation_result_tag ==
        id_015__ptlimapt__apply_internal_results__alpha__operation_result_tag::delegation)
    - id: id_015__ptlimapt__apply_internal_results__alpha__operation_result_event
      type: id_015__ptlimapt__apply_internal_results__alpha__operation_result_event
      if: (id_015__ptlimapt__apply_internal_results__alpha__operation_result_tag ==
        id_015__ptlimapt__apply_internal_results__alpha__operation_result_tag::event)
  id_015__ptlimapt__apply_internal_results__alpha__operation_result_event:
    seq:
    - id: type
      type: micheline__015__ptlimapt__michelson_v1__expression
    - id: tag_tag
      type: u1
      enum: bool
    - id: tag
      type: id_015__ptlimapt__entrypoint
      if: (tag_tag == bool::true)
      doc: ! 'entrypoint: Named entrypoint to a Michelson smart contract'
    - id: payload_tag
      type: u1
      enum: bool
    - id: payload
      type: micheline__015__ptlimapt__michelson_v1__expression
      if: (payload_tag == bool::true)
  micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: micheline__015__ptlimapt__michelson_v1__expression_tag
      type: u1
      enum: micheline__015__ptlimapt__michelson_v1__expression_tag
    - id: micheline__015__ptlimapt__michelson_v1__expression_int
      type: z
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::int)
    - id: micheline__015__ptlimapt__michelson_v1__expression_string
      type: string
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::string)
    - id: micheline__015__ptlimapt__michelson_v1__expression_sequence
      type: micheline__015__ptlimapt__michelson_v1__expression_sequence
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::sequence)
    - id: micheline__015__ptlimapt__michelson_v1__expression_prim__no_args__no_annots
      type: u1
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::prim__no_args__no_annots)
      enum: id_015__ptlimapt__michelson__v1__primitives
    - id: micheline__015__ptlimapt__michelson_v1__expression_prim__no_args__some_annots
      type: micheline__015__ptlimapt__michelson_v1__expression_prim__no_args__some_annots
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::prim__no_args__some_annots)
    - id: micheline__015__ptlimapt__michelson_v1__expression_prim__1_arg__no_annots
      type: micheline__015__ptlimapt__michelson_v1__expression_prim__1_arg__no_annots
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::prim__1_arg__no_annots)
    - id: micheline__015__ptlimapt__michelson_v1__expression_prim__1_arg__some_annots
      type: micheline__015__ptlimapt__michelson_v1__expression_prim__1_arg__some_annots
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::prim__1_arg__some_annots)
    - id: micheline__015__ptlimapt__michelson_v1__expression_prim__2_args__no_annots
      type: micheline__015__ptlimapt__michelson_v1__expression_prim__2_args__no_annots
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::prim__2_args__no_annots)
    - id: micheline__015__ptlimapt__michelson_v1__expression_prim__2_args__some_annots
      type: micheline__015__ptlimapt__michelson_v1__expression_prim__2_args__some_annots
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::prim__2_args__some_annots)
    - id: micheline__015__ptlimapt__michelson_v1__expression_prim__generic
      type: micheline__015__ptlimapt__michelson_v1__expression_prim__generic
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::prim__generic)
    - id: micheline__015__ptlimapt__michelson_v1__expression_bytes
      type: bytes
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::bytes)
  bytes:
    seq:
    - id: size_of_bytes
      type: u4
      valid:
        max: 1073741823
    - id: bytes
      size: size_of_bytes
  micheline__015__ptlimapt__michelson_v1__expression_prim__generic:
    seq:
    - id: prim
      type: u1
      enum: id_015__ptlimapt__michelson__v1__primitives
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
      type: micheline__015__ptlimapt__michelson_v1__expression
  micheline__015__ptlimapt__michelson_v1__expression_prim__2_args__some_annots:
    seq:
    - id: prim
      type: u1
      enum: id_015__ptlimapt__michelson__v1__primitives
    - id: arg1
      type: micheline__015__ptlimapt__michelson_v1__expression
    - id: arg2
      type: micheline__015__ptlimapt__michelson_v1__expression
    - id: annots
      type: annots
  micheline__015__ptlimapt__michelson_v1__expression_prim__2_args__no_annots:
    seq:
    - id: prim
      type: u1
      enum: id_015__ptlimapt__michelson__v1__primitives
    - id: arg1
      type: micheline__015__ptlimapt__michelson_v1__expression
    - id: arg2
      type: micheline__015__ptlimapt__michelson_v1__expression
  micheline__015__ptlimapt__michelson_v1__expression_prim__1_arg__some_annots:
    seq:
    - id: prim
      type: u1
      enum: id_015__ptlimapt__michelson__v1__primitives
    - id: arg
      type: micheline__015__ptlimapt__michelson_v1__expression
    - id: annots
      type: annots
  micheline__015__ptlimapt__michelson_v1__expression_prim__1_arg__no_annots:
    seq:
    - id: prim
      type: u1
      enum: id_015__ptlimapt__michelson__v1__primitives
    - id: arg
      type: micheline__015__ptlimapt__michelson_v1__expression
  micheline__015__ptlimapt__michelson_v1__expression_prim__no_args__some_annots:
    seq:
    - id: prim
      type: u1
      enum: id_015__ptlimapt__michelson__v1__primitives
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
  micheline__015__ptlimapt__michelson_v1__expression_sequence:
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
      type: micheline__015__ptlimapt__michelson_v1__expression
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
  id_015__ptlimapt__apply_internal_results__alpha__operation_result_delegation:
    seq:
    - id: delegate_tag
      type: u1
      enum: bool
    - id: delegate
      type: public_key_hash
      if: (delegate_tag == bool::true)
      doc: A Ed25519, Secp256k1, or P256 public key hash
  id_015__ptlimapt__apply_internal_results__alpha__operation_result_origination:
    seq:
    - id: balance
      type: n
    - id: delegate_tag
      type: u1
      enum: bool
    - id: delegate
      type: public_key_hash
      if: (delegate_tag == bool::true)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: script
      type: id_015__ptlimapt__scripted__contracts
  id_015__ptlimapt__scripted__contracts:
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
  id_015__ptlimapt__apply_internal_results__alpha__operation_result_transaction:
    seq:
    - id: amount
      type: n
    - id: destination
      type: id_015__ptlimapt__transaction_destination
      doc: ! >-
        A destination of a transaction: A destination notation compatible with the
        contract notation as given to an RPC or inside scripts. Can be a base58 implicit
        contract hash, a base58 originated contract hash, a base58 originated transaction
        rollup, or a base58 originated smart-contract rollup.
    - id: parameters_tag
      type: u1
      enum: bool
    - id: parameters
      type: parameters
      if: (parameters_tag == bool::true)
  parameters:
    seq:
    - id: entrypoint
      type: id_015__ptlimapt__entrypoint
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
  id_015__ptlimapt__entrypoint:
    seq:
    - id: id_015__ptlimapt__entrypoint_tag
      type: u1
      enum: id_015__ptlimapt__entrypoint_tag
    - id: id_015__ptlimapt__entrypoint_named
      type: id_015__ptlimapt__entrypoint_named
      if: (id_015__ptlimapt__entrypoint_tag == id_015__ptlimapt__entrypoint_tag::named)
  id_015__ptlimapt__entrypoint_named:
    seq:
    - id: size_of_named
      type: u1
      valid:
        max: 31
    - id: named
      size: size_of_named
      size-eos: true
  id_015__ptlimapt__transaction_destination:
    seq:
    - id: id_015__ptlimapt__transaction_destination_tag
      type: u1
      enum: id_015__ptlimapt__transaction_destination_tag
    - id: id_015__ptlimapt__transaction_destination_implicit
      type: public_key_hash
      if: (id_015__ptlimapt__transaction_destination_tag == id_015__ptlimapt__transaction_destination_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: id_015__ptlimapt__transaction_destination_originated
      type: id_015__ptlimapt__transaction_destination_originated
      if: (id_015__ptlimapt__transaction_destination_tag == id_015__ptlimapt__transaction_destination_tag::originated)
    - id: id_015__ptlimapt__transaction_destination_tx_rollup
      type: id_015__ptlimapt__transaction_destination_tx_rollup
      if: (id_015__ptlimapt__transaction_destination_tag == id_015__ptlimapt__transaction_destination_tag::tx_rollup)
    - id: id_015__ptlimapt__transaction_destination_sc_rollup
      type: id_015__ptlimapt__transaction_destination_sc_rollup
      if: (id_015__ptlimapt__transaction_destination_tag == id_015__ptlimapt__transaction_destination_tag::sc_rollup)
    - id: id_015__ptlimapt__transaction_destination_zk_rollup
      type: id_015__ptlimapt__transaction_destination_zk_rollup
      if: (id_015__ptlimapt__transaction_destination_tag == id_015__ptlimapt__transaction_destination_tag::zk_rollup)
  id_015__ptlimapt__transaction_destination_zk_rollup:
    seq:
    - id: zk_rollup_hash
      size: 20
    - id: zk_rollup_padding
      size: 1
      doc: This field is for padding, ignore
  id_015__ptlimapt__transaction_destination_sc_rollup:
    seq:
    - id: sc_rollup_hash
      size: 20
    - id: sc_rollup_padding
      size: 1
      doc: This field is for padding, ignore
  id_015__ptlimapt__transaction_destination_tx_rollup:
    seq:
    - id: id_015__ptlimapt__tx_rollup_id
      size: 20
      doc: ! >-
        A tx rollup handle: A tx rollup notation as given to an RPC or inside scripts,
        is a base58 tx rollup hash
    - id: tx_rollup_padding
      size: 1
      doc: This field is for padding, ignore
  id_015__ptlimapt__transaction_destination_originated:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
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
    - id: id_015__ptlimapt__contract_id_implicit
      type: public_key_hash
      if: (id_015__ptlimapt__contract_id_tag == id_015__ptlimapt__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: id_015__ptlimapt__contract_id_originated
      type: id_015__ptlimapt__contract_id_originated
      if: (id_015__ptlimapt__contract_id_tag == id_015__ptlimapt__contract_id_tag::originated)
  id_015__ptlimapt__contract_id_originated:
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
enums:
  id_015__ptlimapt__michelson__v1__primitives:
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
