meta:
  id: id_008__ptedo2zk__operation__protocol_data
  endian: be
  imports:
  - block_header__shell
  - operation__shell_header
doc: ! 'Encoding id: 008-PtEdo2Zk.operation.protocol_data'
types:
  activate_account__id_008__ptedo2zk__operation__alpha__contents:
    seq:
    - id: pkh
      size: 20
    - id: secret
      size: 20
  ballot__id_008__ptedo2zk__operation__alpha__contents:
    seq:
    - id: source
      type: ballot__public_key_hash_
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: period
      type: s4
    - id: proposal
      size: 32
    - id: ballot
      type: s1
  ballot__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: ballot__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: ballot__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: ballot__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  bytes_dyn_uint30:
    seq:
    - id: len_bytes_dyn_uint30
      type: u4
      valid:
        max: 1073741823
    - id: bytes_dyn_uint30
      size: len_bytes_dyn_uint30
  contents_entries:
    seq:
    - id: id_008__ptedo2zk__operation__alpha__contents_
      type: id_008__ptedo2zk__operation__alpha__contents_
  delegation__id_008__ptedo2zk__operation__alpha__contents:
    seq:
    - id: source
      type: delegation__public_key_hash_
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
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
  double_baking_evidence__bh1:
    seq:
    - id: len_double_baking_evidence__bh1_dyn
      type: u4
      valid:
        max: 1073741823
    - id: double_baking_evidence__bh1_dyn
      type: double_baking_evidence__bh1_dyn
      size: len_double_baking_evidence__bh1_dyn
  double_baking_evidence__bh1_dyn:
    seq:
    - id: double_baking_evidence__id_008__ptedo2zk__block_header__alpha__full_header_
      type: double_baking_evidence__id_008__ptedo2zk__block_header__alpha__full_header_
  double_baking_evidence__bh2:
    seq:
    - id: len_double_baking_evidence__bh2_dyn
      type: u4
      valid:
        max: 1073741823
    - id: double_baking_evidence__bh2_dyn
      type: double_baking_evidence__bh2_dyn
      size: len_double_baking_evidence__bh2_dyn
  double_baking_evidence__bh2_dyn:
    seq:
    - id: double_baking_evidence__id_008__ptedo2zk__block_header__alpha__full_header_
      type: double_baking_evidence__id_008__ptedo2zk__block_header__alpha__full_header_
  double_baking_evidence__id_008__ptedo2zk__block_header__alpha__full_header_:
    seq:
    - id: id_008__ptedo2zk__block_header__alpha__full_header
      type: block_header__shell
    - id: double_baking_evidence__id_008__ptedo2zk__block_header__alpha__signed_contents_
      type: double_baking_evidence__id_008__ptedo2zk__block_header__alpha__signed_contents_
  double_baking_evidence__id_008__ptedo2zk__block_header__alpha__signed_contents_:
    seq:
    - id: double_baking_evidence__id_008__ptedo2zk__block_header__alpha__unsigned_contents_
      type: double_baking_evidence__id_008__ptedo2zk__block_header__alpha__unsigned_contents_
    - id: signature
      size: 64
  double_baking_evidence__id_008__ptedo2zk__block_header__alpha__unsigned_contents_:
    seq:
    - id: priority
      type: u2
    - id: proof_of_work_nonce
      size: 8
    - id: seed_nonce_hash_tag
      type: u1
      enum: bool
    - id: seed_nonce_hash
      size: 32
      if: (seed_nonce_hash_tag == bool::true)
  double_baking_evidence__id_008__ptedo2zk__operation__alpha__contents:
    seq:
    - id: double_baking_evidence__bh1
      type: double_baking_evidence__bh1
    - id: double_baking_evidence__bh2
      type: double_baking_evidence__bh2
  double_endorsement_evidence__id_008__ptedo2zk__inlined__endorsement_:
    seq:
    - id: id_008__ptedo2zk__inlined__endorsement
      type: operation__shell_header
    - id: operations
      type: double_endorsement_evidence__id_008__ptedo2zk__inlined__endorsement__contents_
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size: 64
      if: (signature_tag == bool::true)
  double_endorsement_evidence__id_008__ptedo2zk__inlined__endorsement__contents_:
    seq:
    - id: id_008__ptedo2zk__inlined__endorsement__contents_tag
      type: u1
      enum: id_008__ptedo2zk__inlined__endorsement__contents_tag
    - id: double_endorsement_evidence__endorsement__id_008__ptedo2zk__inlined__endorsement__contents
      type: s4
      if: (id_008__ptedo2zk__inlined__endorsement__contents_tag == id_008__ptedo2zk__inlined__endorsement__contents_tag::endorsement)
  double_endorsement_evidence__id_008__ptedo2zk__operation__alpha__contents:
    seq:
    - id: double_endorsement_evidence__op1
      type: double_endorsement_evidence__op1
    - id: double_endorsement_evidence__op2
      type: double_endorsement_evidence__op2
  double_endorsement_evidence__op1:
    seq:
    - id: len_double_endorsement_evidence__op1_dyn
      type: u4
      valid:
        max: 1073741823
    - id: double_endorsement_evidence__op1_dyn
      type: double_endorsement_evidence__op1_dyn
      size: len_double_endorsement_evidence__op1_dyn
  double_endorsement_evidence__op1_dyn:
    seq:
    - id: double_endorsement_evidence__id_008__ptedo2zk__inlined__endorsement_
      type: double_endorsement_evidence__id_008__ptedo2zk__inlined__endorsement_
  double_endorsement_evidence__op2:
    seq:
    - id: len_double_endorsement_evidence__op2_dyn
      type: u4
      valid:
        max: 1073741823
    - id: double_endorsement_evidence__op2_dyn
      type: double_endorsement_evidence__op2_dyn
      size: len_double_endorsement_evidence__op2_dyn
  double_endorsement_evidence__op2_dyn:
    seq:
    - id: double_endorsement_evidence__id_008__ptedo2zk__inlined__endorsement_
      type: double_endorsement_evidence__id_008__ptedo2zk__inlined__endorsement_
  id_008__ptedo2zk__operation__alpha__contents_:
    seq:
    - id: id_008__ptedo2zk__operation__alpha__contents_tag
      type: u1
      enum: id_008__ptedo2zk__operation__alpha__contents_tag
    - id: endorsement__id_008__ptedo2zk__operation__alpha__contents
      type: s4
      if: (id_008__ptedo2zk__operation__alpha__contents_tag == id_008__ptedo2zk__operation__alpha__contents_tag::endorsement)
    - id: seed_nonce_revelation__id_008__ptedo2zk__operation__alpha__contents
      type: seed_nonce_revelation__id_008__ptedo2zk__operation__alpha__contents
      if: (id_008__ptedo2zk__operation__alpha__contents_tag == id_008__ptedo2zk__operation__alpha__contents_tag::seed_nonce_revelation)
    - id: double_endorsement_evidence__id_008__ptedo2zk__operation__alpha__contents
      type: double_endorsement_evidence__id_008__ptedo2zk__operation__alpha__contents
      if: (id_008__ptedo2zk__operation__alpha__contents_tag == id_008__ptedo2zk__operation__alpha__contents_tag::double_endorsement_evidence)
    - id: double_baking_evidence__id_008__ptedo2zk__operation__alpha__contents
      type: double_baking_evidence__id_008__ptedo2zk__operation__alpha__contents
      if: (id_008__ptedo2zk__operation__alpha__contents_tag == id_008__ptedo2zk__operation__alpha__contents_tag::double_baking_evidence)
    - id: activate_account__id_008__ptedo2zk__operation__alpha__contents
      type: activate_account__id_008__ptedo2zk__operation__alpha__contents
      if: (id_008__ptedo2zk__operation__alpha__contents_tag == id_008__ptedo2zk__operation__alpha__contents_tag::activate_account)
    - id: proposals__id_008__ptedo2zk__operation__alpha__contents
      type: proposals__id_008__ptedo2zk__operation__alpha__contents
      if: (id_008__ptedo2zk__operation__alpha__contents_tag == id_008__ptedo2zk__operation__alpha__contents_tag::proposals)
    - id: ballot__id_008__ptedo2zk__operation__alpha__contents
      type: ballot__id_008__ptedo2zk__operation__alpha__contents
      if: (id_008__ptedo2zk__operation__alpha__contents_tag == id_008__ptedo2zk__operation__alpha__contents_tag::ballot)
    - id: reveal__id_008__ptedo2zk__operation__alpha__contents
      type: reveal__id_008__ptedo2zk__operation__alpha__contents
      if: (id_008__ptedo2zk__operation__alpha__contents_tag == id_008__ptedo2zk__operation__alpha__contents_tag::reveal)
    - id: transaction__id_008__ptedo2zk__operation__alpha__contents
      type: transaction__id_008__ptedo2zk__operation__alpha__contents
      if: (id_008__ptedo2zk__operation__alpha__contents_tag == id_008__ptedo2zk__operation__alpha__contents_tag::transaction)
    - id: origination__id_008__ptedo2zk__operation__alpha__contents
      type: origination__id_008__ptedo2zk__operation__alpha__contents
      if: (id_008__ptedo2zk__operation__alpha__contents_tag == id_008__ptedo2zk__operation__alpha__contents_tag::origination)
    - id: delegation__id_008__ptedo2zk__operation__alpha__contents
      type: delegation__id_008__ptedo2zk__operation__alpha__contents
      if: (id_008__ptedo2zk__operation__alpha__contents_tag == id_008__ptedo2zk__operation__alpha__contents_tag::delegation)
  id_008__ptedo2zk__operation__alpha__contents_and_signature_:
    seq:
    - id: contents
      type: contents_entries
      repeat: eos
    - id: signature
      size: 64
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
  origination__id_008__ptedo2zk__operation__alpha__contents:
    seq:
    - id: source
      type: origination__public_key_hash_
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
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
      type: origination__id_008__ptedo2zk__scripted__contracts_
  origination__id_008__ptedo2zk__scripted__contracts_:
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
  proposals__id_008__ptedo2zk__operation__alpha__contents:
    seq:
    - id: source
      type: proposals__public_key_hash_
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: period
      type: s4
    - id: proposals__proposals
      type: proposals__proposals
  proposals__proposals:
    seq:
    - id: len_proposals__proposals_dyn
      type: u4
      valid:
        max: 1073741823
    - id: proposals__proposals_dyn
      type: proposals__proposals_dyn
      size: len_proposals__proposals_dyn
  proposals__proposals_dyn:
    seq:
    - id: proposals__proposals_entries
      type: proposals__proposals_entries
      repeat: eos
  proposals__proposals_entries:
    seq:
    - id: protocol_hash
      size: 32
  proposals__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: proposals__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: proposals__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: proposals__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  reveal__id_008__ptedo2zk__operation__alpha__contents:
    seq:
    - id: source
      type: reveal__public_key_hash_
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: public_key
      type: reveal__public_key_
      doc: A Ed25519, Secp256k1, or P256 public key
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
  reveal__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: reveal__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: reveal__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: reveal__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  seed_nonce_revelation__id_008__ptedo2zk__operation__alpha__contents:
    seq:
    - id: level
      type: s4
    - id: nonce
      size: 32
  transaction__id_008__ptedo2zk__contract_id_:
    seq:
    - id: id_008__ptedo2zk__contract_id_tag
      type: u1
      enum: id_008__ptedo2zk__contract_id_tag
    - id: transaction__implicit__id_008__ptedo2zk__contract_id
      type: transaction__implicit__public_key_hash_
      if: (id_008__ptedo2zk__contract_id_tag == id_008__ptedo2zk__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: transaction__originated__id_008__ptedo2zk__contract_id
      type: transaction__originated__id_008__ptedo2zk__contract_id
      if: (id_008__ptedo2zk__contract_id_tag == id_008__ptedo2zk__contract_id_tag::originated)
  transaction__id_008__ptedo2zk__entrypoint_:
    seq:
    - id: id_008__ptedo2zk__entrypoint_tag
      type: u1
      enum: id_008__ptedo2zk__entrypoint_tag
    - id: transaction__named__id_008__ptedo2zk__entrypoint
      type: transaction__named__id_008__ptedo2zk__entrypoint
      if: (id_008__ptedo2zk__entrypoint_tag == id_008__ptedo2zk__entrypoint_tag::named)
  transaction__id_008__ptedo2zk__operation__alpha__contents:
    seq:
    - id: source
      type: transaction__public_key_hash_
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: amount
      type: n
    - id: destination
      type: transaction__id_008__ptedo2zk__contract_id_
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
  transaction__named__id_008__ptedo2zk__entrypoint:
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
  transaction__originated__id_008__ptedo2zk__contract_id:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  transaction__parameters_:
    seq:
    - id: entrypoint
      type: transaction__id_008__ptedo2zk__entrypoint_
      doc: ! 'entrypoint: Named entrypoint to a Michelson smart contract'
    - id: value
      type: bytes_dyn_uint30
  transaction__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: transaction__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: transaction__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: transaction__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  uint30:
    seq:
    - id: uint30
      type: u4
      valid:
        max: 1073741823
enums:
  id_008__ptedo2zk__entrypoint_tag:
    0: default
    1: root
    2: do
    3: set_delegate
    4: remove_delegate
    255: named
  id_008__ptedo2zk__contract_id_tag:
    0: implicit
    1: originated
  public_key_tag:
    0: ed25519
    1: secp256k1
    2: p256
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
  bool:
    0: false
    255: true
  id_008__ptedo2zk__inlined__endorsement__contents_tag:
    0: endorsement
  id_008__ptedo2zk__operation__alpha__contents_tag:
    0: endorsement
    1: seed_nonce_revelation
    2: double_endorsement_evidence
    3: double_baking_evidence
    4: activate_account
    5: proposals
    6: ballot
    107: reveal
    108: transaction
    109: origination
    110: delegation
seq:
- id: id_008__ptedo2zk__operation__alpha__contents_and_signature_
  type: id_008__ptedo2zk__operation__alpha__contents_and_signature_
