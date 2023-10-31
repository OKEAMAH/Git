meta:
  id: id_013__ptjakart__operation__internal
  endian: be
doc: ! 'Encoding id: 013-PtJakart.operation.internal'
types:
  id_013__ptjakart__apply_results__alpha__internal_operation_result:
    seq:
    - id: source
      type: id_013__ptjakart__contract_id
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: nonce
      type: u2
    - id: id_013__ptjakart__apply_results__alpha__internal_operation_result_tag
      type: u1
      enum: id_013__ptjakart__apply_results__alpha__internal_operation_result_tag
    - id: id_013__ptjakart__apply_results__alpha__internal_operation_result_transaction
      type: id_013__ptjakart__apply_results__alpha__internal_operation_result_transaction
      if: (id_013__ptjakart__apply_results__alpha__internal_operation_result_tag ==
        id_013__ptjakart__apply_results__alpha__internal_operation_result_tag::transaction)
    - id: id_013__ptjakart__apply_results__alpha__internal_operation_result_origination
      type: id_013__ptjakart__apply_results__alpha__internal_operation_result_origination
      if: (id_013__ptjakart__apply_results__alpha__internal_operation_result_tag ==
        id_013__ptjakart__apply_results__alpha__internal_operation_result_tag::origination)
    - id: id_013__ptjakart__apply_results__alpha__internal_operation_result_delegation
      type: id_013__ptjakart__apply_results__alpha__internal_operation_result_delegation
      if: (id_013__ptjakart__apply_results__alpha__internal_operation_result_tag ==
        id_013__ptjakart__apply_results__alpha__internal_operation_result_tag::delegation)
  id_013__ptjakart__apply_results__alpha__internal_operation_result_delegation:
    seq:
    - id: delegate_tag
      type: u1
      enum: bool
    - id: delegate
      type: public_key_hash
      if: (delegate_tag == bool::true)
      doc: A Ed25519, Secp256k1, or P256 public key hash
  id_013__ptjakart__apply_results__alpha__internal_operation_result_origination:
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
      type: id_013__ptjakart__scripted__contracts
  id_013__ptjakart__scripted__contracts:
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
  id_013__ptjakart__apply_results__alpha__internal_operation_result_transaction:
    seq:
    - id: amount
      type: n
    - id: destination
      type: id_013__ptjakart__transaction_destination
      doc: ! >-
        A destination of a transaction: A destination notation compatible with the
        contract notation as given to an RPC or inside scripts. Can be a base58 implicit
        contract hash, a base58 originated contract hash, or a base58 originated transaction
        rollup.
    - id: parameters_tag
      type: u1
      enum: bool
    - id: parameters
      type: parameters
      if: (parameters_tag == bool::true)
  parameters:
    seq:
    - id: entrypoint
      type: id_013__ptjakart__entrypoint
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
  id_013__ptjakart__entrypoint:
    seq:
    - id: id_013__ptjakart__entrypoint_tag
      type: u1
      enum: id_013__ptjakart__entrypoint_tag
    - id: id_013__ptjakart__entrypoint_named
      type: id_013__ptjakart__entrypoint_named
      if: (id_013__ptjakart__entrypoint_tag == id_013__ptjakart__entrypoint_tag::named)
  id_013__ptjakart__entrypoint_named:
    seq:
    - id: size_of_named
      type: u1
      valid:
        max: 31
    - id: named
      size: size_of_named
      size-eos: true
  id_013__ptjakart__transaction_destination:
    seq:
    - id: id_013__ptjakart__transaction_destination_tag
      type: u1
      enum: id_013__ptjakart__transaction_destination_tag
    - id: id_013__ptjakart__transaction_destination_implicit
      type: public_key_hash
      if: (id_013__ptjakart__transaction_destination_tag == id_013__ptjakart__transaction_destination_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: id_013__ptjakart__transaction_destination_originated
      type: id_013__ptjakart__transaction_destination_originated
      if: (id_013__ptjakart__transaction_destination_tag == id_013__ptjakart__transaction_destination_tag::originated)
    - id: id_013__ptjakart__transaction_destination_tx_rollup
      type: id_013__ptjakart__transaction_destination_tx_rollup
      if: (id_013__ptjakart__transaction_destination_tag == id_013__ptjakart__transaction_destination_tag::tx_rollup)
  id_013__ptjakart__transaction_destination_tx_rollup:
    seq:
    - id: id_013__ptjakart__tx_rollup_id
      size: 20
      doc: ! >-
        A tx rollup handle: A tx rollup notation as given to an RPC or inside scripts,
        is a base58 tx rollup hash
    - id: tx_rollup_padding
      size: 1
      doc: This field is for padding, ignore
  id_013__ptjakart__transaction_destination_originated:
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
  id_013__ptjakart__contract_id:
    seq:
    - id: id_013__ptjakart__contract_id_tag
      type: u1
      enum: id_013__ptjakart__contract_id_tag
    - id: id_013__ptjakart__contract_id_implicit
      type: public_key_hash
      if: (id_013__ptjakart__contract_id_tag == id_013__ptjakart__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: id_013__ptjakart__contract_id_originated
      type: id_013__ptjakart__contract_id_originated
      if: (id_013__ptjakart__contract_id_tag == id_013__ptjakart__contract_id_tag::originated)
  id_013__ptjakart__contract_id_originated:
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
  id_013__ptjakart__entrypoint_tag:
    0: default
    1: root
    2: do
    3: set_delegate
    4: remove_delegate
    255: named
  bool:
    0: false
    255: true
  id_013__ptjakart__transaction_destination_tag:
    0: implicit
    1: originated
    2: tx_rollup
  id_013__ptjakart__apply_results__alpha__internal_operation_result_tag:
    1: transaction
    2: origination
    3: delegation
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
  id_013__ptjakart__contract_id_tag:
    0: implicit
    1: originated
seq:
- id: id_013__ptjakart__apply_results__alpha__internal_operation_result
  type: id_013__ptjakart__apply_results__alpha__internal_operation_result
