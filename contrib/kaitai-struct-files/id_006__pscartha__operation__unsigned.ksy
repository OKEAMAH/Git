meta:
  id: id_006__pscartha__operation__unsigned
  endian: be
doc: ! 'Encoding id: 006-PsCARTHA.operation.unsigned'
types:
  id_006__pscartha__operation__alpha__unsigned_operation:
    seq:
    - id: operation__shell_header
      size: 32
      doc: An operation's shell header.
    - id: contents
      type: contents_entries
      repeat: eos
  contents_entries:
    seq:
    - id: id_006__pscartha__operation__alpha__contents
      type: id_006__pscartha__operation__alpha__contents
  id_006__pscartha__operation__alpha__contents:
    seq:
    - id: id_006__pscartha__operation__alpha__contents_tag
      type: u1
      enum: id_006__pscartha__operation__alpha__contents_tag
    - id: id_006__pscartha__operation__alpha__contents_endorsement
      type: s4
      if: (id_006__pscartha__operation__alpha__contents_tag == id_006__pscartha__operation__alpha__contents_tag::endorsement)
    - id: id_006__pscartha__operation__alpha__contents_seed_nonce_revelation
      type: id_006__pscartha__operation__alpha__contents_seed_nonce_revelation
      if: (id_006__pscartha__operation__alpha__contents_tag == id_006__pscartha__operation__alpha__contents_tag::seed_nonce_revelation)
    - id: id_006__pscartha__operation__alpha__contents_double_endorsement_evidence
      type: id_006__pscartha__operation__alpha__contents_double_endorsement_evidence
      if: (id_006__pscartha__operation__alpha__contents_tag == id_006__pscartha__operation__alpha__contents_tag::double_endorsement_evidence)
    - id: id_006__pscartha__operation__alpha__contents_double_baking_evidence
      type: id_006__pscartha__operation__alpha__contents_double_baking_evidence
      if: (id_006__pscartha__operation__alpha__contents_tag == id_006__pscartha__operation__alpha__contents_tag::double_baking_evidence)
    - id: id_006__pscartha__operation__alpha__contents_activate_account
      type: id_006__pscartha__operation__alpha__contents_activate_account
      if: (id_006__pscartha__operation__alpha__contents_tag == id_006__pscartha__operation__alpha__contents_tag::activate_account)
    - id: id_006__pscartha__operation__alpha__contents_proposals
      type: id_006__pscartha__operation__alpha__contents_proposals
      if: (id_006__pscartha__operation__alpha__contents_tag == id_006__pscartha__operation__alpha__contents_tag::proposals)
    - id: id_006__pscartha__operation__alpha__contents_ballot
      type: id_006__pscartha__operation__alpha__contents_ballot
      if: (id_006__pscartha__operation__alpha__contents_tag == id_006__pscartha__operation__alpha__contents_tag::ballot)
    - id: id_006__pscartha__operation__alpha__contents_reveal
      type: id_006__pscartha__operation__alpha__contents_reveal
      if: (id_006__pscartha__operation__alpha__contents_tag == id_006__pscartha__operation__alpha__contents_tag::reveal)
    - id: id_006__pscartha__operation__alpha__contents_transaction
      type: id_006__pscartha__operation__alpha__contents_transaction
      if: (id_006__pscartha__operation__alpha__contents_tag == id_006__pscartha__operation__alpha__contents_tag::transaction)
    - id: id_006__pscartha__operation__alpha__contents_origination
      type: id_006__pscartha__operation__alpha__contents_origination
      if: (id_006__pscartha__operation__alpha__contents_tag == id_006__pscartha__operation__alpha__contents_tag::origination)
    - id: id_006__pscartha__operation__alpha__contents_delegation
      type: id_006__pscartha__operation__alpha__contents_delegation
      if: (id_006__pscartha__operation__alpha__contents_tag == id_006__pscartha__operation__alpha__contents_tag::delegation)
  id_006__pscartha__operation__alpha__contents_delegation:
    seq:
    - id: source
      type: public_key_hash
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
      type: public_key_hash
      if: (delegate_tag == bool::true)
      doc: A Ed25519, Secp256k1, or P256 public key hash
  id_006__pscartha__operation__alpha__contents_origination:
    seq:
    - id: source
      type: public_key_hash
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
      type: public_key_hash
      if: (delegate_tag == bool::true)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: script
      type: id_006__pscartha__scripted__contracts
  id_006__pscartha__scripted__contracts:
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
  id_006__pscartha__operation__alpha__contents_transaction:
    seq:
    - id: source
      type: public_key_hash
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
      type: id_006__pscartha__contract_id
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
      type: id_006__pscartha__entrypoint
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
  id_006__pscartha__entrypoint:
    seq:
    - id: id_006__pscartha__entrypoint_tag
      type: u1
      enum: id_006__pscartha__entrypoint_tag
    - id: id_006__pscartha__entrypoint_named
      type: id_006__pscartha__entrypoint_named
      if: (id_006__pscartha__entrypoint_tag == id_006__pscartha__entrypoint_tag::named)
  id_006__pscartha__entrypoint_named:
    seq:
    - id: size_of_named
      type: u1
    - id: named
      size: size_of_named
      size-eos: true
      valid:
        max: 31
  id_006__pscartha__contract_id:
    seq:
    - id: id_006__pscartha__contract_id_tag
      type: u1
      enum: id_006__pscartha__contract_id_tag
    - id: id_006__pscartha__contract_id_implicit
      type: public_key_hash
      if: (id_006__pscartha__contract_id_tag == id_006__pscartha__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: id_006__pscartha__contract_id_originated
      type: id_006__pscartha__contract_id_originated
      if: (id_006__pscartha__contract_id_tag == id_006__pscartha__contract_id_tag::originated)
  id_006__pscartha__contract_id_originated:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  id_006__pscartha__operation__alpha__contents_reveal:
    seq:
    - id: source
      type: public_key_hash
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
      type: public_key
      doc: A Ed25519, Secp256k1, or P256 public key
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
  id_006__pscartha__operation__alpha__contents_ballot:
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
  id_006__pscartha__operation__alpha__contents_proposals:
    seq:
    - id: source
      type: public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: period
      type: s4
    - id: proposals
      type: proposals
  proposals:
    seq:
    - id: size_of_proposals
      type: u4
      valid:
        max: 1073741823
    - id: proposals
      type: proposals_entries
      size: size_of_proposals
      repeat: eos
  proposals_entries:
    seq:
    - id: protocol_hash
      size: 32
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
  id_006__pscartha__operation__alpha__contents_activate_account:
    seq:
    - id: pkh
      size: 20
    - id: secret
      size: 20
  id_006__pscartha__operation__alpha__contents_double_baking_evidence:
    seq:
    - id: bh1
      type: bh1
    - id: bh2
      type: bh2
  bh2:
    seq:
    - id: size_of_bh2
      type: u4
      valid:
        max: 1073741823
    - id: bh2
      type: id_006__pscartha__block_header__alpha__full_header
      size: size_of_bh2
  bh1:
    seq:
    - id: size_of_bh1
      type: u4
      valid:
        max: 1073741823
    - id: bh1
      type: id_006__pscartha__block_header__alpha__full_header
      size: size_of_bh1
  id_006__pscartha__block_header__alpha__full_header:
    seq:
    - id: block_header__shell
      type: block_header__shell
      doc: ! >-
        Shell header: Block header's shell-related content. It contains information
        such as the block level, its predecessor and timestamp.
    - id: id_006__pscartha__block_header__alpha__signed_contents
      type: id_006__pscartha__block_header__alpha__signed_contents
  id_006__pscartha__block_header__alpha__signed_contents:
    seq:
    - id: id_006__pscartha__block_header__alpha__unsigned_contents
      type: id_006__pscartha__block_header__alpha__unsigned_contents
    - id: signature
      size: 64
  id_006__pscartha__block_header__alpha__unsigned_contents:
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
  block_header__shell:
    seq:
    - id: level
      type: s4
    - id: proto
      type: u1
    - id: predecessor
      size: 32
    - id: timestamp
      type: s8
      doc: ! 'A timestamp as seen by the protocol: second-level precision, epoch based.'
    - id: validation_pass
      type: u1
    - id: operations_hash
      size: 32
    - id: fitness
      type: fitness
      doc: ! >-
        Block fitness: The fitness, or score, of a block, that allow the Tezos to
        decide which chain is the best. A fitness value is a list of byte sequences.
        They are compared as follows: shortest lists are smaller; lists of the same
        length are compared according to the lexicographical order.
    - id: context
      size: 32
  fitness:
    seq:
    - id: size_of_fitness
      type: u4
      valid:
        max: 1073741823
    - id: fitness
      type: fitness_entries
      size: size_of_fitness
      repeat: eos
  fitness_entries:
    seq:
    - id: fitness__elem
      type: fitness__elem
  fitness__elem:
    seq:
    - id: size_of_fitness__elem
      type: u4
      valid:
        max: 1073741823
    - id: fitness__elem
      size: size_of_fitness__elem
  id_006__pscartha__operation__alpha__contents_double_endorsement_evidence:
    seq:
    - id: op1
      type: op1
    - id: op2
      type: op2
  op2:
    seq:
    - id: size_of_op2
      type: u4
      valid:
        max: 1073741823
    - id: op2
      type: id_006__pscartha__inlined__endorsement
      size: size_of_op2
  op1:
    seq:
    - id: size_of_op1
      type: u4
      valid:
        max: 1073741823
    - id: op1
      type: id_006__pscartha__inlined__endorsement
      size: size_of_op1
  id_006__pscartha__inlined__endorsement:
    seq:
    - id: operation__shell_header
      size: 32
      doc: An operation's shell header.
    - id: operations
      type: id_006__pscartha__inlined__endorsement__contents
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size: 64
      if: (signature_tag == bool::true)
  id_006__pscartha__inlined__endorsement__contents:
    seq:
    - id: id_006__pscartha__inlined__endorsement__contents_tag
      type: u1
      enum: id_006__pscartha__inlined__endorsement__contents_tag
    - id: id_006__pscartha__inlined__endorsement__contents_endorsement
      type: s4
      if: (id_006__pscartha__inlined__endorsement__contents_tag == id_006__pscartha__inlined__endorsement__contents_tag::endorsement)
  id_006__pscartha__operation__alpha__contents_seed_nonce_revelation:
    seq:
    - id: level
      type: s4
    - id: nonce
      size: 32
enums:
  id_006__pscartha__entrypoint_tag:
    0: default
    1: root
    2: do
    3: set_delegate
    4: remove_delegate
    255: named
  id_006__pscartha__contract_id_tag:
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
  id_006__pscartha__inlined__endorsement__contents_tag:
    0: endorsement
  id_006__pscartha__operation__alpha__contents_tag:
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
- id: id_006__pscartha__operation__alpha__unsigned_operation
  type: id_006__pscartha__operation__alpha__unsigned_operation
