meta:
  id: id_011__pthangz2__operation__internal
  endian: be
doc: ! 'Encoding id: 011-PtHangz2.operation.internal'
types:
  id_011__pthangz2__operation__alpha__internal_operation:
    seq:
    - id: source
      type: id_011__pthangz2__contract_id
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: nonce
      type: u2
    - id: id_011__pthangz2__operation__alpha__internal_operation_tag
      type: u1
      enum: id_011__pthangz2__operation__alpha__internal_operation_tag
    - id: id_011__pthangz2__operation__alpha__internal_operation_reveal
      type: public_key
      if: (id_011__pthangz2__operation__alpha__internal_operation_tag == id_011__pthangz2__operation__alpha__internal_operation_tag::reveal)
      doc: A Ed25519, Secp256k1, or P256 public key
    - id: id_011__pthangz2__operation__alpha__internal_operation_transaction
      type: id_011__pthangz2__operation__alpha__internal_operation_transaction
      if: (id_011__pthangz2__operation__alpha__internal_operation_tag == id_011__pthangz2__operation__alpha__internal_operation_tag::transaction)
    - id: id_011__pthangz2__operation__alpha__internal_operation_origination
      type: id_011__pthangz2__operation__alpha__internal_operation_origination
      if: (id_011__pthangz2__operation__alpha__internal_operation_tag == id_011__pthangz2__operation__alpha__internal_operation_tag::origination)
    - id: id_011__pthangz2__operation__alpha__internal_operation_delegation
      type: id_011__pthangz2__operation__alpha__internal_operation_delegation
      if: (id_011__pthangz2__operation__alpha__internal_operation_tag == id_011__pthangz2__operation__alpha__internal_operation_tag::delegation)
    - id: id_011__pthangz2__operation__alpha__internal_operation_register_global_constant
      type: value
      if: (id_011__pthangz2__operation__alpha__internal_operation_tag == id_011__pthangz2__operation__alpha__internal_operation_tag::register_global_constant)
  id_011__pthangz2__operation__alpha__internal_operation_delegation:
    seq:
    - id: delegate_tag
      type: u1
      enum: bool
    - id: delegate
      type: public_key_hash
      if: (delegate_tag == bool::true)
      doc: A Ed25519, Secp256k1, or P256 public key hash
  id_011__pthangz2__operation__alpha__internal_operation_origination:
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
      type: id_011__pthangz2__scripted__contracts
  id_011__pthangz2__scripted__contracts:
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
  id_011__pthangz2__operation__alpha__internal_operation_transaction:
    seq:
    - id: amount
      type: n
    - id: destination
      type: id_011__pthangz2__contract_id
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: parameters_tag
      type: u1
      enum: bool
    - id: parameters
      type: parameters
      if: (parameters_tag == bool::true)
  parameters:
    seq:
    - id: entrypoint
      type: id_011__pthangz2__entrypoint
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
  id_011__pthangz2__entrypoint:
    seq:
    - id: id_011__pthangz2__entrypoint_tag
      type: u1
      enum: id_011__pthangz2__entrypoint_tag
    - id: id_011__pthangz2__entrypoint_named
      type: id_011__pthangz2__entrypoint_named
      if: (id_011__pthangz2__entrypoint_tag == id_011__pthangz2__entrypoint_tag::named)
  id_011__pthangz2__entrypoint_named:
    seq:
    - id: size_of_named
      type: u1
    - id: named
      size: size_of_named
      size-eos: true
      valid:
        max: 31
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
  public_key:
    seq:
    - id: public_key_tag
      type: u1
      enum: public_key_tag
    - id: public_key_ed25519
      size: 32
      if: (public_key_tag == public_key_tag::ed25519)
    - id: public_key_secp256k1
      size: 33
      if: (public_key_tag == public_key_tag::secp256k1)
    - id: public_key_p256
      size: 33
      if: (public_key_tag == public_key_tag::p256)
  id_011__pthangz2__contract_id:
    seq:
    - id: id_011__pthangz2__contract_id_tag
      type: u1
      enum: id_011__pthangz2__contract_id_tag
    - id: id_011__pthangz2__contract_id_implicit
      type: public_key_hash
      if: (id_011__pthangz2__contract_id_tag == id_011__pthangz2__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: id_011__pthangz2__contract_id_originated
      type: id_011__pthangz2__contract_id_originated
      if: (id_011__pthangz2__contract_id_tag == id_011__pthangz2__contract_id_tag::originated)
  id_011__pthangz2__contract_id_originated:
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
  id_011__pthangz2__entrypoint_tag:
    0: default
    1: root
    2: do
    3: set_delegate
    4: remove_delegate
    255: named
  bool:
    0: false
    255: true
  public_key_tag:
    0: ed25519
    1: secp256k1
    2: p256
  id_011__pthangz2__operation__alpha__internal_operation_tag:
    0: reveal
    1: transaction
    2: origination
    3: delegation
    4: register_global_constant
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
  id_011__pthangz2__contract_id_tag:
    0: implicit
    1: originated
seq:
- id: id_011__pthangz2__operation__alpha__internal_operation
  type: id_011__pthangz2__operation__alpha__internal_operation
