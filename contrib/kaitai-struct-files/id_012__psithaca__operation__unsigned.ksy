meta:
  id: id_012__psithaca__operation__unsigned
  endian: be
  imports:
  - block_header__shell
  - operation__shell_header
doc: ! 'Encoding id: 012-Psithaca.operation.unsigned'
types:
  activate_account:
    seq:
    - id: pkh
      size: 20
    - id: secret
      size: 20
  arbitrary:
    seq:
    - id: len_arbitrary
      type: s4
    - id: arbitrary
      size: len_arbitrary
  ballot:
    seq:
    - id: source
      type: public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: period
      type: s4
    - id: proposal
      size: 32
    - id: ballot
      type: s1
  bh1:
    seq:
    - id: id_012__psithaca__block_header__alpha__full_header
      type: id_012__psithaca__block_header__alpha__full_header
  bh1_0:
    seq:
    - id: len_bh1
      type: s4
    - id: bh1
      type: bh1
      size: len_bh1
  bh2:
    seq:
    - id: id_012__psithaca__block_header__alpha__full_header
      type: id_012__psithaca__block_header__alpha__full_header
  bh2_0:
    seq:
    - id: len_bh2
      type: s4
    - id: bh2
      type: bh2
      size: len_bh2
  code:
    seq:
    - id: len_code
      type: s4
    - id: code
      size: len_code
  contents_entries:
    seq:
    - id: id_012__psithaca__operation__alpha__contents
      type: id_012__psithaca__operation__alpha__contents
  delegation:
    seq:
    - id: source
      type: public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: id_012__psithaca__mutez
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
      type: public_key_hash
      if: (delegate_tag == bool::true)
      doc: A Ed25519, Secp256k1, or P256 public key hash
  double_baking_evidence:
    seq:
    - id: bh1
      type: bh1_0
    - id: bh2
      type: bh2_0
  double_endorsement_evidence:
    seq:
    - id: op1
      type: op1_0
    - id: op2
      type: op2_0
  double_preendorsement_evidence:
    seq:
    - id: op1
      type: op1_2
    - id: op2
      type: op2_2
  endorsement:
    seq:
    - id: slot
      type: u2
    - id: level
      type: s4
    - id: round
      type: s4
    - id: block_payload_hash
      size: 32
  endorsement_0:
    seq:
    - id: slot
      type: u2
    - id: level
      type: s4
    - id: round
      type: s4
    - id: block_payload_hash
      size: 32
  id_012__psithaca__block_header__alpha__full_header:
    seq:
    - id: id_012__psithaca__block_header__alpha__full_header
      type: block_header__shell
    - id: id_012__psithaca__block_header__alpha__signed_contents
      type: id_012__psithaca__block_header__alpha__signed_contents
  id_012__psithaca__block_header__alpha__signed_contents:
    seq:
    - id: id_012__psithaca__block_header__alpha__unsigned_contents
      type: id_012__psithaca__block_header__alpha__unsigned_contents
    - id: signature
      size: 64
  id_012__psithaca__block_header__alpha__unsigned_contents:
    seq:
    - id: payload_hash
      size: 32
    - id: payload_round
      type: s4
    - id: proof_of_work_nonce
      size: 8
    - id: seed_nonce_hash_tag
      type: u1
      enum: bool
    - id: seed_nonce_hash
      size: 32
      if: (seed_nonce_hash_tag == bool::true)
    - id: liquidity_baking_escape_vote
      type: u1
      enum: bool
  id_012__psithaca__contract_id:
    seq:
    - id: id_012__psithaca__contract_id_tag
      type: u1
      enum: id_012__psithaca__contract_id_tag
    - id: implicit
      type: public_key_hash
      if: (id_012__psithaca__contract_id_tag == id_012__psithaca__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: originated
      type: originated
      if: (id_012__psithaca__contract_id_tag == id_012__psithaca__contract_id_tag::originated)
  id_012__psithaca__entrypoint:
    seq:
    - id: id_012__psithaca__entrypoint_tag
      type: u1
      enum: id_012__psithaca__entrypoint_tag
    - id: named
      type: named_0
      if: (id_012__psithaca__entrypoint_tag == id_012__psithaca__entrypoint_tag::named)
  id_012__psithaca__inlined__endorsement:
    seq:
    - id: id_012__psithaca__inlined__endorsement
      type: operation__shell_header
    - id: operations
      type: id_012__psithaca__inlined__endorsement_mempool__contents
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size: 64
      if: (signature_tag == bool::true)
  id_012__psithaca__inlined__endorsement_mempool__contents:
    seq:
    - id: id_012__psithaca__inlined__endorsement_mempool__contents_tag
      type: u1
      enum: id_012__psithaca__inlined__endorsement_mempool__contents_tag
    - id: endorsement
      type: endorsement_0
      if: (id_012__psithaca__inlined__endorsement_mempool__contents_tag == id_012__psithaca__inlined__endorsement_mempool__contents_tag::endorsement)
  id_012__psithaca__inlined__preendorsement:
    seq:
    - id: id_012__psithaca__inlined__preendorsement
      type: operation__shell_header
    - id: operations
      type: id_012__psithaca__inlined__preendorsement__contents
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size: 64
      if: (signature_tag == bool::true)
  id_012__psithaca__inlined__preendorsement__contents:
    seq:
    - id: id_012__psithaca__inlined__preendorsement__contents_tag
      type: u1
      enum: id_012__psithaca__inlined__preendorsement__contents_tag
    - id: preendorsement
      type: preendorsement_0
      if: (id_012__psithaca__inlined__preendorsement__contents_tag == id_012__psithaca__inlined__preendorsement__contents_tag::preendorsement)
  id_012__psithaca__mutez:
    seq:
    - id: id_012__psithaca__mutez
      type: n
  id_012__psithaca__operation__alpha__contents:
    seq:
    - id: id_012__psithaca__operation__alpha__contents_tag
      type: u1
      enum: id_012__psithaca__operation__alpha__contents_tag
    - id: endorsement
      type: endorsement
      if: (id_012__psithaca__operation__alpha__contents_tag == id_012__psithaca__operation__alpha__contents_tag::endorsement)
    - id: preendorsement
      type: preendorsement
      if: (id_012__psithaca__operation__alpha__contents_tag == id_012__psithaca__operation__alpha__contents_tag::preendorsement)
    - id: seed_nonce_revelation
      type: seed_nonce_revelation
      if: (id_012__psithaca__operation__alpha__contents_tag == id_012__psithaca__operation__alpha__contents_tag::seed_nonce_revelation)
    - id: double_endorsement_evidence
      type: double_endorsement_evidence
      if: (id_012__psithaca__operation__alpha__contents_tag == id_012__psithaca__operation__alpha__contents_tag::double_endorsement_evidence)
    - id: double_preendorsement_evidence
      type: double_preendorsement_evidence
      if: (id_012__psithaca__operation__alpha__contents_tag == id_012__psithaca__operation__alpha__contents_tag::double_preendorsement_evidence)
    - id: double_baking_evidence
      type: double_baking_evidence
      if: (id_012__psithaca__operation__alpha__contents_tag == id_012__psithaca__operation__alpha__contents_tag::double_baking_evidence)
    - id: activate_account
      type: activate_account
      if: (id_012__psithaca__operation__alpha__contents_tag == id_012__psithaca__operation__alpha__contents_tag::activate_account)
    - id: proposals
      type: proposals_1
      if: (id_012__psithaca__operation__alpha__contents_tag == id_012__psithaca__operation__alpha__contents_tag::proposals)
    - id: ballot
      type: ballot
      if: (id_012__psithaca__operation__alpha__contents_tag == id_012__psithaca__operation__alpha__contents_tag::ballot)
    - id: reveal
      type: reveal
      if: (id_012__psithaca__operation__alpha__contents_tag == id_012__psithaca__operation__alpha__contents_tag::reveal)
    - id: transaction
      type: transaction
      if: (id_012__psithaca__operation__alpha__contents_tag == id_012__psithaca__operation__alpha__contents_tag::transaction)
    - id: origination
      type: origination
      if: (id_012__psithaca__operation__alpha__contents_tag == id_012__psithaca__operation__alpha__contents_tag::origination)
    - id: delegation
      type: delegation
      if: (id_012__psithaca__operation__alpha__contents_tag == id_012__psithaca__operation__alpha__contents_tag::delegation)
    - id: set_deposits_limit
      type: set_deposits_limit
      if: (id_012__psithaca__operation__alpha__contents_tag == id_012__psithaca__operation__alpha__contents_tag::set_deposits_limit)
    - id: failing_noop
      type: arbitrary
      if: (id_012__psithaca__operation__alpha__contents_tag == id_012__psithaca__operation__alpha__contents_tag::failing_noop)
    - id: register_global_constant
      type: register_global_constant
      if: (id_012__psithaca__operation__alpha__contents_tag == id_012__psithaca__operation__alpha__contents_tag::register_global_constant)
  id_012__psithaca__operation__alpha__unsigned_operation:
    seq:
    - id: id_012__psithaca__operation__alpha__unsigned_operation
      type: operation__shell_header
    - id: contents
      type: contents_entries
      repeat: eos
  id_012__psithaca__scripted__contracts:
    seq:
    - id: code
      type: code
    - id: storage
      type: storage
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
  named:
    seq:
    - id: named
      size-eos: true
  named_0:
    seq:
    - id: len_named
      type: u1
    - id: named
      type: named
      size: len_named
  op1:
    seq:
    - id: id_012__psithaca__inlined__endorsement
      type: id_012__psithaca__inlined__endorsement
  op1_0:
    seq:
    - id: len_op1
      type: s4
    - id: op1
      type: op1
      size: len_op1
  op1_1:
    seq:
    - id: id_012__psithaca__inlined__preendorsement
      type: id_012__psithaca__inlined__preendorsement
  op1_2:
    seq:
    - id: len_op1
      type: s4
    - id: op1
      type: op1_1
      size: len_op1
  op2:
    seq:
    - id: id_012__psithaca__inlined__endorsement
      type: id_012__psithaca__inlined__endorsement
  op2_0:
    seq:
    - id: len_op2
      type: s4
    - id: op2
      type: op2
      size: len_op2
  op2_1:
    seq:
    - id: id_012__psithaca__inlined__preendorsement
      type: id_012__psithaca__inlined__preendorsement
  op2_2:
    seq:
    - id: len_op2
      type: s4
    - id: op2
      type: op2_1
      size: len_op2
  originated:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  origination:
    seq:
    - id: source
      type: public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: id_012__psithaca__mutez
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: balance
      type: id_012__psithaca__mutez
    - id: delegate_tag
      type: u1
      enum: bool
    - id: delegate
      type: public_key_hash
      if: (delegate_tag == bool::true)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: script
      type: id_012__psithaca__scripted__contracts
  parameters:
    seq:
    - id: entrypoint
      type: id_012__psithaca__entrypoint
      doc: ! 'entrypoint: Named entrypoint to a Michelson smart contract'
    - id: value
      type: value
  preendorsement:
    seq:
    - id: slot
      type: u2
    - id: level
      type: s4
    - id: round
      type: s4
    - id: block_payload_hash
      size: 32
  preendorsement_0:
    seq:
    - id: slot
      type: u2
    - id: level
      type: s4
    - id: round
      type: s4
    - id: block_payload_hash
      size: 32
  proposals:
    seq:
    - id: proposals_entries
      type: proposals_entries
      repeat: eos
  proposals_0:
    seq:
    - id: len_proposals
      type: s4
    - id: proposals
      type: proposals
      size: len_proposals
  proposals_1:
    seq:
    - id: source
      type: public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: period
      type: s4
    - id: proposals
      type: proposals_0
  proposals_entries:
    seq:
    - id: protocol_hash
      size: 32
  public_key:
    seq:
    - id: public_key_tag
      type: u1
      enum: public_key_tag
    - id: ed25519
      size: 32
      if: (public_key_tag == public_key_tag::ed25519)
    - id: secp256k1
      size: 33
      if: (public_key_tag == public_key_tag::secp256k1)
    - id: p256
      size: 33
      if: (public_key_tag == public_key_tag::p256)
  public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: ed25519
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: secp256k1
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: p256
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  register_global_constant:
    seq:
    - id: source
      type: public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: id_012__psithaca__mutez
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: value
      type: value
  reveal:
    seq:
    - id: source
      type: public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: id_012__psithaca__mutez
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: public_key
      type: public_key
      doc: A Ed25519, Secp256k1, or P256 public key
  seed_nonce_revelation:
    seq:
    - id: level
      type: s4
    - id: nonce
      size: 32
  set_deposits_limit:
    seq:
    - id: source
      type: public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: id_012__psithaca__mutez
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: limit_tag
      type: u1
      enum: bool
    - id: limit
      type: id_012__psithaca__mutez
      if: (limit_tag == bool::true)
  storage:
    seq:
    - id: len_storage
      type: s4
    - id: storage
      size: len_storage
  transaction:
    seq:
    - id: source
      type: public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: id_012__psithaca__mutez
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: amount
      type: id_012__psithaca__mutez
    - id: destination
      type: id_012__psithaca__contract_id
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: parameters_tag
      type: u1
      enum: bool
    - id: parameters
      type: parameters
      if: (parameters_tag == bool::true)
  value:
    seq:
    - id: len_value
      type: s4
    - id: value
      size: len_value
enums:
  bool:
    0: false
    255: true
  id_012__psithaca__contract_id_tag:
    0: implicit
    1: originated
  id_012__psithaca__entrypoint_tag:
    0: default
    1: root
    2: do
    3: set_delegate
    4: remove_delegate
    255: named
  id_012__psithaca__inlined__endorsement_mempool__contents_tag:
    21: endorsement
  id_012__psithaca__inlined__preendorsement__contents_tag:
    20: preendorsement
  id_012__psithaca__operation__alpha__contents_tag:
    1: seed_nonce_revelation
    2: double_endorsement_evidence
    3: double_baking_evidence
    4: activate_account
    5: proposals
    6: ballot
    7: double_preendorsement_evidence
    17: failing_noop
    20: preendorsement
    21: endorsement
    107: reveal
    108: transaction
    109: origination
    110: delegation
    111: register_global_constant
    112: set_deposits_limit
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
  public_key_tag:
    0: ed25519
    1: secp256k1
    2: p256
seq:
- id: id_012__psithaca__operation__alpha__unsigned_operation
  type: id_012__psithaca__operation__alpha__unsigned_operation
