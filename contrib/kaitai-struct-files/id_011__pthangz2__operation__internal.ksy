meta:
  id: id_011__pthangz2__operation__internal
  endian: be
doc: ! 'Encoding id: 011-PtHangz2.operation.internal'
types:
  id_011__pthangz2__operation__alpha__internal_operation_:
    seq:
    - id: source
      type: id_011__pthangz2__contract_id_
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: nonce
      type: u2
    - id: id_011__pthangz2__operation__alpha__internal_operation_tag
      type: u1
      enum: id_011__pthangz2__operation__alpha__internal_operation_tag
    - id: reveal__id_011__pthangz2__operation__alpha__internal_operation
      type: reveal__public_key_
      if: (id_011__pthangz2__operation__alpha__internal_operation_tag == id_011__pthangz2__operation__alpha__internal_operation_tag::reveal)
      doc: A Ed25519, Secp256k1, or P256 public key
    - id: transaction__id_011__pthangz2__operation__alpha__internal_operation
      type: transaction__id_011__pthangz2__operation__alpha__internal_operation
      if: (id_011__pthangz2__operation__alpha__internal_operation_tag == id_011__pthangz2__operation__alpha__internal_operation_tag::transaction)
    - id: origination__id_011__pthangz2__operation__alpha__internal_operation
      type: origination__id_011__pthangz2__operation__alpha__internal_operation
      if: (id_011__pthangz2__operation__alpha__internal_operation_tag == id_011__pthangz2__operation__alpha__internal_operation_tag::origination)
    - id: delegation__id_011__pthangz2__operation__alpha__internal_operation
      type: delegation__id_011__pthangz2__operation__alpha__internal_operation
      if: (id_011__pthangz2__operation__alpha__internal_operation_tag == id_011__pthangz2__operation__alpha__internal_operation_tag::delegation)
    - id: register_global_constant__id_011__pthangz2__operation__alpha__internal_operation
      type: register_global_constant__value
      if: (id_011__pthangz2__operation__alpha__internal_operation_tag == id_011__pthangz2__operation__alpha__internal_operation_tag::register_global_constant)
  register_global_constant__value:
    seq:
    - id: len_value
      type: u4
      valid:
        max: 1073741823
    - id: value
      size: len_value
  delegation__id_011__pthangz2__operation__alpha__internal_operation:
    seq:
    - id: delegate_tag
      type: u1
      enum: bool
    - id: delegate
      type: delegation__public_key_hash_
      if: (delegate_tag == bool::true)
      doc: A Ed25519, Secp256k1, or P256 public key hash
  delegation__public_key_hash_:
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
  origination__id_011__pthangz2__operation__alpha__internal_operation:
    seq:
    - id: balance
      type: n
    - id: delegate_tag
      type: u1
      enum: bool
    - id: delegate
      type: origination__public_key_hash_
      if: (delegate_tag == bool::true)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: script
      type: origination__id_011__pthangz2__scripted__contracts_
  origination__id_011__pthangz2__scripted__contracts_:
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
  origination__public_key_hash_:
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
  transaction__id_011__pthangz2__operation__alpha__internal_operation:
    seq:
    - id: amount
      type: n
    - id: destination
      type: transaction__id_011__pthangz2__contract_id_
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: parameters_tag
      type: u1
      enum: bool
    - id: transaction__parameters_
      type: transaction__parameters_
      if: (parameters_tag == bool::true)
  transaction__parameters_:
    seq:
    - id: entrypoint
      type: transaction__id_011__pthangz2__entrypoint_
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
  transaction__id_011__pthangz2__entrypoint_:
    seq:
    - id: id_011__pthangz2__entrypoint_tag
      type: u1
      enum: id_011__pthangz2__entrypoint_tag
    - id: transaction__named__id_011__pthangz2__entrypoint
      type: transaction__named__id_011__pthangz2__entrypoint
      if: (id_011__pthangz2__entrypoint_tag == id_011__pthangz2__entrypoint_tag::named)
  transaction__named__id_011__pthangz2__entrypoint:
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
  transaction__id_011__pthangz2__contract_id_:
    seq:
    - id: id_011__pthangz2__contract_id_tag
      type: u1
      enum: id_011__pthangz2__contract_id_tag
    - id: transaction__implicit__id_011__pthangz2__contract_id
      type: transaction__implicit__public_key_hash_
      if: (id_011__pthangz2__contract_id_tag == id_011__pthangz2__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: transaction__originated__id_011__pthangz2__contract_id
      type: transaction__originated__id_011__pthangz2__contract_id
      if: (id_011__pthangz2__contract_id_tag == id_011__pthangz2__contract_id_tag::originated)
  transaction__originated__id_011__pthangz2__contract_id:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  transaction__implicit__public_key_hash_:
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
  reveal__public_key_:
    seq:
    - id: public_key_tag
      type: u1
      enum: public_key_tag
    - id: reveal__ed25519__public_key
      size: 32
      if: (public_key_tag == public_key_tag::ed25519)
    - id: reveal__secp256k1__public_key
      size: 33
      if: (public_key_tag == public_key_tag::secp256k1)
    - id: reveal__p256__public_key
      size: 33
      if: (public_key_tag == public_key_tag::p256)
  id_011__pthangz2__contract_id_:
    seq:
    - id: id_011__pthangz2__contract_id_tag
      type: u1
      enum: id_011__pthangz2__contract_id_tag
    - id: implicit__id_011__pthangz2__contract_id
      type: implicit__public_key_hash_
      if: (id_011__pthangz2__contract_id_tag == id_011__pthangz2__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: originated__id_011__pthangz2__contract_id
      type: originated__id_011__pthangz2__contract_id
      if: (id_011__pthangz2__contract_id_tag == id_011__pthangz2__contract_id_tag::originated)
  originated__id_011__pthangz2__contract_id:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  implicit__public_key_hash_:
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
- id: id_011__pthangz2__operation__alpha__internal_operation_
  type: id_011__pthangz2__operation__alpha__internal_operation_
