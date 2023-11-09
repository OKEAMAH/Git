meta:
  id: id_005__psbabym1__operation__internal
  endian: be
doc: ! 'Encoding id: 005-PsBabyM1.operation.internal'
types:
  bytes_dyn_uint30:
    seq:
    - id: len_bytes_dyn_uint30
      type: u4
      valid:
        max: 1073741823
    - id: bytes_dyn_uint30
      size: len_bytes_dyn_uint30
  delegation__id_005__psbabym1__operation__alpha__internal_operation:
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
  id_005__psbabym1__contract_id_:
    seq:
    - id: id_005__psbabym1__contract_id_tag
      type: u1
      enum: id_005__psbabym1__contract_id_tag
    - id: implicit__id_005__psbabym1__contract_id
      type: implicit__public_key_hash_
      if: (id_005__psbabym1__contract_id_tag == id_005__psbabym1__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: originated__id_005__psbabym1__contract_id
      type: originated__id_005__psbabym1__contract_id
      if: (id_005__psbabym1__contract_id_tag == id_005__psbabym1__contract_id_tag::originated)
  id_005__psbabym1__operation__alpha__internal_operation_:
    seq:
    - id: source
      type: id_005__psbabym1__contract_id_
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: nonce
      type: u2
    - id: id_005__psbabym1__operation__alpha__internal_operation_tag
      type: u1
      enum: id_005__psbabym1__operation__alpha__internal_operation_tag
    - id: reveal__id_005__psbabym1__operation__alpha__internal_operation
      type: reveal__public_key_
      if: (id_005__psbabym1__operation__alpha__internal_operation_tag == id_005__psbabym1__operation__alpha__internal_operation_tag::reveal)
      doc: A Ed25519, Secp256k1, or P256 public key
    - id: transaction__id_005__psbabym1__operation__alpha__internal_operation
      type: transaction__id_005__psbabym1__operation__alpha__internal_operation
      if: (id_005__psbabym1__operation__alpha__internal_operation_tag == id_005__psbabym1__operation__alpha__internal_operation_tag::transaction)
    - id: origination__id_005__psbabym1__operation__alpha__internal_operation
      type: origination__id_005__psbabym1__operation__alpha__internal_operation
      if: (id_005__psbabym1__operation__alpha__internal_operation_tag == id_005__psbabym1__operation__alpha__internal_operation_tag::origination)
    - id: delegation__id_005__psbabym1__operation__alpha__internal_operation
      type: delegation__id_005__psbabym1__operation__alpha__internal_operation
      if: (id_005__psbabym1__operation__alpha__internal_operation_tag == id_005__psbabym1__operation__alpha__internal_operation_tag::delegation)
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
  originated__id_005__psbabym1__contract_id:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  origination__id_005__psbabym1__operation__alpha__internal_operation:
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
      type: origination__id_005__psbabym1__scripted__contracts_
  origination__id_005__psbabym1__scripted__contracts_:
    seq:
    - id: code
      type: bytes_dyn_uint30
    - id: storage
      type: bytes_dyn_uint30
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
  transaction__id_005__psbabym1__contract_id_:
    seq:
    - id: id_005__psbabym1__contract_id_tag
      type: u1
      enum: id_005__psbabym1__contract_id_tag
    - id: transaction__implicit__id_005__psbabym1__contract_id
      type: transaction__implicit__public_key_hash_
      if: (id_005__psbabym1__contract_id_tag == id_005__psbabym1__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: transaction__originated__id_005__psbabym1__contract_id
      type: transaction__originated__id_005__psbabym1__contract_id
      if: (id_005__psbabym1__contract_id_tag == id_005__psbabym1__contract_id_tag::originated)
  transaction__id_005__psbabym1__entrypoint_:
    seq:
    - id: id_005__psbabym1__entrypoint_tag
      type: u1
      enum: id_005__psbabym1__entrypoint_tag
    - id: transaction__named__id_005__psbabym1__entrypoint
      type: transaction__named__id_005__psbabym1__entrypoint
      if: (id_005__psbabym1__entrypoint_tag == id_005__psbabym1__entrypoint_tag::named)
  transaction__id_005__psbabym1__operation__alpha__internal_operation:
    seq:
    - id: amount
      type: n
    - id: destination
      type: transaction__id_005__psbabym1__contract_id_
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: parameters_tag
      type: u1
      enum: bool
    - id: transaction__parameters_
      type: transaction__parameters_
      if: (parameters_tag == bool::true)
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
  transaction__named__id_005__psbabym1__entrypoint:
    seq:
    - id: len_transaction__named__named_dyn
      type: u1
      valid:
        max: 31
    - id: transaction__named__named_dyn
      type: transaction__named__named_dyn
      size: len_transaction__named__named_dyn
  transaction__named__named_dyn:
    seq:
    - id: named
      size-eos: true
  transaction__originated__id_005__psbabym1__contract_id:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  transaction__parameters_:
    seq:
    - id: entrypoint
      type: transaction__id_005__psbabym1__entrypoint_
      doc: ! 'entrypoint: Named entrypoint to a Michelson smart contract'
    - id: value
      type: bytes_dyn_uint30
  uint30:
    seq:
    - id: uint30
      type: u4
      valid:
        max: 1073741823
enums:
  id_005__psbabym1__entrypoint_tag:
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
  id_005__psbabym1__operation__alpha__internal_operation_tag:
    0: reveal
    1: transaction
    2: origination
    3: delegation
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
  id_005__psbabym1__contract_id_tag:
    0: implicit
    1: originated
seq:
- id: id_005__psbabym1__operation__alpha__internal_operation_
  type: id_005__psbabym1__operation__alpha__internal_operation_
