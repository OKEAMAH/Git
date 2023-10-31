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
    - id: id_014__ptkathma__apply_internal_results__alpha__operation_result_transaction
      type: id_014__ptkathma__apply_internal_results__alpha__operation_result_transaction
      if: (id_014__ptkathma__apply_internal_results__alpha__operation_result_tag ==
        id_014__ptkathma__apply_internal_results__alpha__operation_result_tag::transaction)
    - id: id_014__ptkathma__apply_internal_results__alpha__operation_result_origination
      type: id_014__ptkathma__apply_internal_results__alpha__operation_result_origination
      if: (id_014__ptkathma__apply_internal_results__alpha__operation_result_tag ==
        id_014__ptkathma__apply_internal_results__alpha__operation_result_tag::origination)
    - id: id_014__ptkathma__apply_internal_results__alpha__operation_result_delegation
      type: id_014__ptkathma__apply_internal_results__alpha__operation_result_delegation
      if: (id_014__ptkathma__apply_internal_results__alpha__operation_result_tag ==
        id_014__ptkathma__apply_internal_results__alpha__operation_result_tag::delegation)
    - id: id_014__ptkathma__apply_internal_results__alpha__operation_result_event
      type: id_014__ptkathma__apply_internal_results__alpha__operation_result_event
      if: (id_014__ptkathma__apply_internal_results__alpha__operation_result_tag ==
        id_014__ptkathma__apply_internal_results__alpha__operation_result_tag::event)
  id_014__ptkathma__apply_internal_results__alpha__operation_result_event:
    seq:
    - id: type
      type: micheline__014__ptkathma__michelson_v1__expression
    - id: tag_tag
      type: u1
      enum: bool
    - id: tag
      type: id_014__ptkathma__entrypoint
      if: (tag_tag == bool::true)
      doc: ! 'entrypoint: Named entrypoint to a Michelson smart contract'
    - id: payload_tag
      type: u1
      enum: bool
    - id: payload
      type: micheline__014__ptkathma__michelson_v1__expression
      if: (payload_tag == bool::true)
  micheline__014__ptkathma__michelson_v1__expression:
    seq:
    - id: micheline__014__ptkathma__michelson_v1__expression_tag
      type: u1
      enum: micheline__014__ptkathma__michelson_v1__expression_tag
    - id: micheline__014__ptkathma__michelson_v1__expression_int
      type: z
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::int)
    - id: micheline__014__ptkathma__michelson_v1__expression_string
      type: string
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::string)
    - id: micheline__014__ptkathma__michelson_v1__expression_sequence
      type: micheline__014__ptkathma__michelson_v1__expression_sequence
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::sequence)
    - id: micheline__014__ptkathma__michelson_v1__expression_prim__no_args__no_annots
      type: u1
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::prim__no_args__no_annots)
      enum: id_014__ptkathma__michelson__v1__primitives
    - id: micheline__014__ptkathma__michelson_v1__expression_prim__no_args__some_annots
      type: micheline__014__ptkathma__michelson_v1__expression_prim__no_args__some_annots
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::prim__no_args__some_annots)
    - id: micheline__014__ptkathma__michelson_v1__expression_prim__1_arg__no_annots
      type: micheline__014__ptkathma__michelson_v1__expression_prim__1_arg__no_annots
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::prim__1_arg__no_annots)
    - id: micheline__014__ptkathma__michelson_v1__expression_prim__1_arg__some_annots
      type: micheline__014__ptkathma__michelson_v1__expression_prim__1_arg__some_annots
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::prim__1_arg__some_annots)
    - id: micheline__014__ptkathma__michelson_v1__expression_prim__2_args__no_annots
      type: micheline__014__ptkathma__michelson_v1__expression_prim__2_args__no_annots
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::prim__2_args__no_annots)
    - id: micheline__014__ptkathma__michelson_v1__expression_prim__2_args__some_annots
      type: micheline__014__ptkathma__michelson_v1__expression_prim__2_args__some_annots
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::prim__2_args__some_annots)
    - id: micheline__014__ptkathma__michelson_v1__expression_prim__generic
      type: micheline__014__ptkathma__michelson_v1__expression_prim__generic
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::prim__generic)
    - id: micheline__014__ptkathma__michelson_v1__expression_bytes
      type: bytes
      if: (micheline__014__ptkathma__michelson_v1__expression_tag == micheline__014__ptkathma__michelson_v1__expression_tag::bytes)
  bytes:
    seq:
    - id: size_of_bytes
      type: u4
      valid:
        max: 1073741823
    - id: bytes
      size: size_of_bytes
  micheline__014__ptkathma__michelson_v1__expression_prim__generic:
    seq:
    - id: prim
      type: u1
      enum: id_014__ptkathma__michelson__v1__primitives
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
      type: micheline__014__ptkathma__michelson_v1__expression
  micheline__014__ptkathma__michelson_v1__expression_prim__2_args__some_annots:
    seq:
    - id: prim
      type: u1
      enum: id_014__ptkathma__michelson__v1__primitives
    - id: arg1
      type: micheline__014__ptkathma__michelson_v1__expression
    - id: arg2
      type: micheline__014__ptkathma__michelson_v1__expression
    - id: annots
      type: annots
  micheline__014__ptkathma__michelson_v1__expression_prim__2_args__no_annots:
    seq:
    - id: prim
      type: u1
      enum: id_014__ptkathma__michelson__v1__primitives
    - id: arg1
      type: micheline__014__ptkathma__michelson_v1__expression
    - id: arg2
      type: micheline__014__ptkathma__michelson_v1__expression
  micheline__014__ptkathma__michelson_v1__expression_prim__1_arg__some_annots:
    seq:
    - id: prim
      type: u1
      enum: id_014__ptkathma__michelson__v1__primitives
    - id: arg
      type: micheline__014__ptkathma__michelson_v1__expression
    - id: annots
      type: annots
  micheline__014__ptkathma__michelson_v1__expression_prim__1_arg__no_annots:
    seq:
    - id: prim
      type: u1
      enum: id_014__ptkathma__michelson__v1__primitives
    - id: arg
      type: micheline__014__ptkathma__michelson_v1__expression
  micheline__014__ptkathma__michelson_v1__expression_prim__no_args__some_annots:
    seq:
    - id: prim
      type: u1
      enum: id_014__ptkathma__michelson__v1__primitives
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
  micheline__014__ptkathma__michelson_v1__expression_sequence:
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
      type: micheline__014__ptkathma__michelson_v1__expression
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
  id_014__ptkathma__apply_internal_results__alpha__operation_result_delegation:
    seq:
    - id: delegate_tag
      type: u1
      enum: bool
    - id: delegate
      type: public_key_hash
      if: (delegate_tag == bool::true)
      doc: A Ed25519, Secp256k1, or P256 public key hash
  id_014__ptkathma__apply_internal_results__alpha__operation_result_origination:
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
      type: id_014__ptkathma__scripted__contracts
  id_014__ptkathma__scripted__contracts:
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
  id_014__ptkathma__apply_internal_results__alpha__operation_result_transaction:
    seq:
    - id: amount
      type: n
    - id: destination
      type: id_014__ptkathma__transaction_destination
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
      type: id_014__ptkathma__entrypoint
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
  id_014__ptkathma__entrypoint:
    seq:
    - id: id_014__ptkathma__entrypoint_tag
      type: u1
      enum: id_014__ptkathma__entrypoint_tag
    - id: id_014__ptkathma__entrypoint_named
      type: id_014__ptkathma__entrypoint_named
      if: (id_014__ptkathma__entrypoint_tag == id_014__ptkathma__entrypoint_tag::named)
  id_014__ptkathma__entrypoint_named:
    seq:
    - id: size_of_named
      type: u1
      valid:
        max: 31
    - id: named
      size: size_of_named
      size-eos: true
  id_014__ptkathma__transaction_destination:
    seq:
    - id: id_014__ptkathma__transaction_destination_tag
      type: u1
      enum: id_014__ptkathma__transaction_destination_tag
    - id: id_014__ptkathma__transaction_destination_implicit
      type: public_key_hash
      if: (id_014__ptkathma__transaction_destination_tag == id_014__ptkathma__transaction_destination_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: id_014__ptkathma__transaction_destination_originated
      type: id_014__ptkathma__transaction_destination_originated
      if: (id_014__ptkathma__transaction_destination_tag == id_014__ptkathma__transaction_destination_tag::originated)
    - id: id_014__ptkathma__transaction_destination_tx_rollup
      type: id_014__ptkathma__transaction_destination_tx_rollup
      if: (id_014__ptkathma__transaction_destination_tag == id_014__ptkathma__transaction_destination_tag::tx_rollup)
    - id: id_014__ptkathma__transaction_destination_sc_rollup
      type: id_014__ptkathma__transaction_destination_sc_rollup
      if: (id_014__ptkathma__transaction_destination_tag == id_014__ptkathma__transaction_destination_tag::sc_rollup)
  id_014__ptkathma__transaction_destination_sc_rollup:
    seq:
    - id: sc_rollup_hash
      size: 20
    - id: sc_rollup_padding
      size: 1
      doc: This field is for padding, ignore
  id_014__ptkathma__transaction_destination_tx_rollup:
    seq:
    - id: id_014__ptkathma__tx_rollup_id
      size: 20
      doc: ! >-
        A tx rollup handle: A tx rollup notation as given to an RPC or inside scripts,
        is a base58 tx rollup hash
    - id: tx_rollup_padding
      size: 1
      doc: This field is for padding, ignore
  id_014__ptkathma__transaction_destination_originated:
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
  id_014__ptkathma__contract_id:
    seq:
    - id: id_014__ptkathma__contract_id_tag
      type: u1
      enum: id_014__ptkathma__contract_id_tag
    - id: id_014__ptkathma__contract_id_implicit
      type: public_key_hash
      if: (id_014__ptkathma__contract_id_tag == id_014__ptkathma__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: id_014__ptkathma__contract_id_originated
      type: id_014__ptkathma__contract_id_originated
      if: (id_014__ptkathma__contract_id_tag == id_014__ptkathma__contract_id_tag::originated)
  id_014__ptkathma__contract_id_originated:
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
  id_014__ptkathma__michelson__v1__primitives:
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
    3: prim__no_args__no_annots
    4: prim__no_args__some_annots
    5: prim__1_arg__no_annots
    6: prim__1_arg__some_annots
    7: prim__2_args__no_annots
    8: prim__2_args__some_annots
    9: prim__generic
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
