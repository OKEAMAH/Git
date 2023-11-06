meta:
  id: id_013__ptjakart__operation__protocol_data
  endian: be
doc: ! 'Encoding id: 013-PtJakart.operation.protocol_data'
types:
  id_013__ptjakart__operation__alpha__contents_and_signature:
    seq:
    - id: contents
      type: contents_entries
      repeat: eos
    - id: signature
      size: 64
  contents_entries:
    seq:
    - id: id_013__ptjakart__operation__alpha__contents
      type: id_013__ptjakart__operation__alpha__contents
  id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: id_013__ptjakart__operation__alpha__contents_tag
      type: u1
      enum: id_013__ptjakart__operation__alpha__contents_tag
    - id: endorsement__id_013__ptjakart__operation__alpha__contents
      type: endorsement__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::endorsement)
    - id: preendorsement__id_013__ptjakart__operation__alpha__contents
      type: preendorsement__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::preendorsement)
    - id: seed_nonce_revelation__id_013__ptjakart__operation__alpha__contents
      type: seed_nonce_revelation__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::seed_nonce_revelation)
    - id: double_endorsement_evidence__id_013__ptjakart__operation__alpha__contents
      type: double_endorsement_evidence__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::double_endorsement_evidence)
    - id: double_preendorsement_evidence__id_013__ptjakart__operation__alpha__contents
      type: double_preendorsement_evidence__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::double_preendorsement_evidence)
    - id: double_baking_evidence__id_013__ptjakart__operation__alpha__contents
      type: double_baking_evidence__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::double_baking_evidence)
    - id: activate_account__id_013__ptjakart__operation__alpha__contents
      type: activate_account__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::activate_account)
    - id: proposals__id_013__ptjakart__operation__alpha__contents
      type: proposals__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::proposals)
    - id: ballot__id_013__ptjakart__operation__alpha__contents
      type: ballot__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::ballot)
    - id: reveal__id_013__ptjakart__operation__alpha__contents
      type: reveal__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::reveal)
    - id: transaction__id_013__ptjakart__operation__alpha__contents
      type: transaction__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::transaction)
    - id: origination__id_013__ptjakart__operation__alpha__contents
      type: origination__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::origination)
    - id: delegation__id_013__ptjakart__operation__alpha__contents
      type: delegation__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::delegation)
    - id: set_deposits_limit__id_013__ptjakart__operation__alpha__contents
      type: set_deposits_limit__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::set_deposits_limit)
    - id: failing_noop__id_013__ptjakart__operation__alpha__contents
      type: failing_noop__arbitrary
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::failing_noop)
    - id: register_global_constant__id_013__ptjakart__operation__alpha__contents
      type: register_global_constant__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::register_global_constant)
    - id: tx_rollup_origination__id_013__ptjakart__operation__alpha__contents
      type: tx_rollup_origination__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::tx_rollup_origination)
    - id: tx_rollup_submit_batch__id_013__ptjakart__operation__alpha__contents
      type: tx_rollup_submit_batch__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::tx_rollup_submit_batch)
    - id: tx_rollup_commit__id_013__ptjakart__operation__alpha__contents
      type: tx_rollup_commit__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::tx_rollup_commit)
    - id: tx_rollup_return_bond__id_013__ptjakart__operation__alpha__contents
      type: tx_rollup_return_bond__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::tx_rollup_return_bond)
    - id: tx_rollup_finalize_commitment__id_013__ptjakart__operation__alpha__contents
      type: tx_rollup_finalize_commitment__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::tx_rollup_finalize_commitment)
    - id: tx_rollup_remove_commitment__id_013__ptjakart__operation__alpha__contents
      type: tx_rollup_remove_commitment__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::tx_rollup_remove_commitment)
    - id: tx_rollup_rejection__id_013__ptjakart__operation__alpha__contents
      type: tx_rollup_rejection__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::tx_rollup_rejection)
    - id: tx_rollup_dispatch_tickets__id_013__ptjakart__operation__alpha__contents
      type: tx_rollup_dispatch_tickets__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::tx_rollup_dispatch_tickets)
    - id: transfer_ticket__id_013__ptjakart__operation__alpha__contents
      type: transfer_ticket__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::transfer_ticket)
    - id: sc_rollup_originate__id_013__ptjakart__operation__alpha__contents
      type: sc_rollup_originate__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::sc_rollup_originate)
    - id: sc_rollup_add_messages__id_013__ptjakart__operation__alpha__contents
      type: sc_rollup_add_messages__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::sc_rollup_add_messages)
    - id: sc_rollup_cement__id_013__ptjakart__operation__alpha__contents
      type: sc_rollup_cement__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::sc_rollup_cement)
    - id: sc_rollup_publish__id_013__ptjakart__operation__alpha__contents
      type: sc_rollup_publish__id_013__ptjakart__operation__alpha__contents
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::sc_rollup_publish)
  sc_rollup_publish__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: source
      type: sc_rollup_publish__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: rollup
      type: sc_rollup_publish__id_013__ptjakart__rollup_address
      doc: ! >-
        A smart contract rollup address: A smart contract rollup is identified by
        a base58 address starting with scr1
    - id: sc_rollup_publish__commitment
      type: sc_rollup_publish__commitment
  sc_rollup_publish__commitment:
    seq:
    - id: compressed_state
      size: 32
    - id: inbox_level
      type: s4
    - id: predecessor
      size: 32
    - id: number_of_messages
      type: s4
    - id: number_of_ticks
      type: s4
  sc_rollup_publish__id_013__ptjakart__rollup_address:
    seq:
    - id: len_id_013__ptjakart__rollup_address
      type: u4
      valid:
        max: 1073741823
    - id: id_013__ptjakart__rollup_address
      size: len_id_013__ptjakart__rollup_address
  sc_rollup_publish__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: sc_rollup_publish__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: sc_rollup_publish__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: sc_rollup_publish__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  sc_rollup_cement__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: source
      type: sc_rollup_cement__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: rollup
      type: sc_rollup_cement__id_013__ptjakart__rollup_address
      doc: ! >-
        A smart contract rollup address: A smart contract rollup is identified by
        a base58 address starting with scr1
    - id: commitment
      size: 32
  sc_rollup_cement__id_013__ptjakart__rollup_address:
    seq:
    - id: len_id_013__ptjakart__rollup_address
      type: u4
      valid:
        max: 1073741823
    - id: id_013__ptjakart__rollup_address
      size: len_id_013__ptjakart__rollup_address
  sc_rollup_cement__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: sc_rollup_cement__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: sc_rollup_cement__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: sc_rollup_cement__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  sc_rollup_add_messages__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: source
      type: sc_rollup_add_messages__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: rollup
      type: sc_rollup_add_messages__id_013__ptjakart__rollup_address
      doc: ! >-
        A smart contract rollup address: A smart contract rollup is identified by
        a base58 address starting with scr1
    - id: sc_rollup_add_messages__message
      type: sc_rollup_add_messages__message
  sc_rollup_add_messages__message:
    seq:
    - id: len_message
      type: u4
      valid:
        max: 1073741823
    - id: message
      type: sc_rollup_add_messages__message_entries
      size: len_message
      repeat: eos
  sc_rollup_add_messages__message_entries:
    seq:
    - id: len_message_elt
      type: u4
      valid:
        max: 1073741823
    - id: message_elt
      size: len_message_elt
  sc_rollup_add_messages__id_013__ptjakart__rollup_address:
    seq:
    - id: len_id_013__ptjakart__rollup_address
      type: u4
      valid:
        max: 1073741823
    - id: id_013__ptjakart__rollup_address
      size: len_id_013__ptjakart__rollup_address
  sc_rollup_add_messages__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: sc_rollup_add_messages__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: sc_rollup_add_messages__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: sc_rollup_add_messages__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  sc_rollup_originate__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: source
      type: sc_rollup_originate__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: kind
      type: u2
      enum: kind_tag
    - id: sc_rollup_originate__boot_sector
      type: sc_rollup_originate__boot_sector
  sc_rollup_originate__boot_sector:
    seq:
    - id: len_boot_sector
      type: u4
      valid:
        max: 1073741823
    - id: boot_sector
      size: len_boot_sector
  sc_rollup_originate__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: sc_rollup_originate__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: sc_rollup_originate__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: sc_rollup_originate__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  transfer_ticket__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: source
      type: transfer_ticket__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: transfer_ticket__ticket_contents
      type: transfer_ticket__ticket_contents
    - id: transfer_ticket__ticket_ty
      type: transfer_ticket__ticket_ty
    - id: ticket_ticketer
      type: transfer_ticket__id_013__ptjakart__contract_id
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: ticket_amount
      type: n
    - id: destination
      type: transfer_ticket__id_013__ptjakart__contract_id
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: transfer_ticket__entrypoint
      type: transfer_ticket__entrypoint
  transfer_ticket__entrypoint:
    seq:
    - id: len_entrypoint
      type: u4
      valid:
        max: 1073741823
    - id: entrypoint
      size: len_entrypoint
  transfer_ticket__id_013__ptjakart__contract_id:
    seq:
    - id: id_013__ptjakart__contract_id_tag
      type: u1
      enum: id_013__ptjakart__contract_id_tag
    - id: transfer_ticket__implicit__id_013__ptjakart__contract_id
      type: transfer_ticket__implicit__public_key_hash
      if: (id_013__ptjakart__contract_id_tag == id_013__ptjakart__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: transfer_ticket__originated__id_013__ptjakart__contract_id
      type: transfer_ticket__originated__id_013__ptjakart__contract_id
      if: (id_013__ptjakart__contract_id_tag == id_013__ptjakart__contract_id_tag::originated)
  transfer_ticket__originated__id_013__ptjakart__contract_id:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  transfer_ticket__implicit__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: transfer_ticket__implicit__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: transfer_ticket__implicit__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: transfer_ticket__implicit__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  transfer_ticket__ticket_ty:
    seq:
    - id: len_ticket_ty
      type: u4
      valid:
        max: 1073741823
    - id: ticket_ty
      size: len_ticket_ty
  transfer_ticket__ticket_contents:
    seq:
    - id: len_ticket_contents
      type: u4
      valid:
        max: 1073741823
    - id: ticket_contents
      size: len_ticket_contents
  transfer_ticket__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: transfer_ticket__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: transfer_ticket__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: transfer_ticket__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  tx_rollup_dispatch_tickets__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: source
      type: tx_rollup_dispatch_tickets__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: tx_rollup
      size: 20
      doc: ! >-
        A tx rollup handle: A tx rollup notation as given to an RPC or inside scripts,
        is a base58 tx rollup hash
    - id: level
      type: s4
    - id: context_hash
      size: 32
    - id: message_index
      type: s4
      valid:
        min: -1073741824
        max: 1073741823
    - id: tx_rollup_dispatch_tickets__message_result_path
      type: tx_rollup_dispatch_tickets__message_result_path
    - id: tx_rollup_dispatch_tickets__tickets_info
      type: tx_rollup_dispatch_tickets__tickets_info
  tx_rollup_dispatch_tickets__tickets_info:
    seq:
    - id: len_tickets_info
      type: u4
      valid:
        max: 1073741823
    - id: tickets_info
      type: tx_rollup_dispatch_tickets__tickets_info_entries
      size: len_tickets_info
      repeat: eos
  tx_rollup_dispatch_tickets__tickets_info_entries:
    seq:
    - id: tx_rollup_dispatch_tickets__contents
      type: tx_rollup_dispatch_tickets__contents
    - id: tx_rollup_dispatch_tickets__ty
      type: tx_rollup_dispatch_tickets__ty
    - id: ticketer
      type: tx_rollup_dispatch_tickets__id_013__ptjakart__contract_id
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: tx_rollup_dispatch_tickets__amount
      type: tx_rollup_dispatch_tickets__amount
    - id: claimer
      type: tx_rollup_dispatch_tickets__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
  tx_rollup_dispatch_tickets__amount:
    seq:
    - id: amount_tag
      type: u1
      enum: amount_tag
    - id: tx_rollup_dispatch_tickets__case__0__amount
      type: u1
      if: (amount_tag == amount_tag::case__0)
    - id: tx_rollup_dispatch_tickets__case__1__amount
      type: u2
      if: (amount_tag == amount_tag::case__1)
    - id: tx_rollup_dispatch_tickets__case__2__amount
      type: s4
      if: (amount_tag == amount_tag::case__2)
    - id: tx_rollup_dispatch_tickets__case__3__amount
      type: s8
      if: (amount_tag == amount_tag::case__3)
  tx_rollup_dispatch_tickets__id_013__ptjakart__contract_id:
    seq:
    - id: id_013__ptjakart__contract_id_tag
      type: u1
      enum: id_013__ptjakart__contract_id_tag
    - id: tx_rollup_dispatch_tickets__implicit__id_013__ptjakart__contract_id
      type: tx_rollup_dispatch_tickets__implicit__public_key_hash
      if: (id_013__ptjakart__contract_id_tag == id_013__ptjakart__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: tx_rollup_dispatch_tickets__originated__id_013__ptjakart__contract_id
      type: tx_rollup_dispatch_tickets__originated__id_013__ptjakart__contract_id
      if: (id_013__ptjakart__contract_id_tag == id_013__ptjakart__contract_id_tag::originated)
  tx_rollup_dispatch_tickets__originated__id_013__ptjakart__contract_id:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  tx_rollup_dispatch_tickets__implicit__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: tx_rollup_dispatch_tickets__implicit__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: tx_rollup_dispatch_tickets__implicit__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: tx_rollup_dispatch_tickets__implicit__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  tx_rollup_dispatch_tickets__ty:
    seq:
    - id: len_ty
      type: u4
      valid:
        max: 1073741823
    - id: ty
      size: len_ty
  tx_rollup_dispatch_tickets__contents:
    seq:
    - id: len_contents
      type: u4
      valid:
        max: 1073741823
    - id: contents
      size: len_contents
  tx_rollup_dispatch_tickets__message_result_path:
    seq:
    - id: len_message_result_path
      type: u4
      valid:
        max: 1073741823
    - id: message_result_path
      type: tx_rollup_dispatch_tickets__message_result_path_entries
      size: len_message_result_path
      repeat: eos
  tx_rollup_dispatch_tickets__message_result_path_entries:
    seq:
    - id: message_result_list_hash
      size: 32
  tx_rollup_dispatch_tickets__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: tx_rollup_dispatch_tickets__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: tx_rollup_dispatch_tickets__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: tx_rollup_dispatch_tickets__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  tx_rollup_rejection__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: source
      type: tx_rollup_rejection__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: rollup
      size: 20
      doc: ! >-
        A tx rollup handle: A tx rollup notation as given to an RPC or inside scripts,
        is a base58 tx rollup hash
    - id: level
      type: s4
    - id: tx_rollup_rejection__message
      type: tx_rollup_rejection__message
    - id: message_position
      type: n
    - id: tx_rollup_rejection__message_path
      type: tx_rollup_rejection__message_path
    - id: message_result_hash
      size: 32
    - id: tx_rollup_rejection__message_result_path
      type: tx_rollup_rejection__message_result_path
    - id: tx_rollup_rejection__previous_message_result
      type: tx_rollup_rejection__previous_message_result
    - id: tx_rollup_rejection__previous_message_result_path
      type: tx_rollup_rejection__previous_message_result_path
    - id: tx_rollup_rejection__proof
      type: tx_rollup_rejection__proof
  tx_rollup_rejection__proof:
    seq:
    - id: proof_tag
      type: u1
      enum: proof_tag
    - id: tx_rollup_rejection__case__0__proof
      type: tx_rollup_rejection__case__0__proof
      if: (proof_tag == proof_tag::case__0)
    - id: tx_rollup_rejection__case__2__proof
      type: tx_rollup_rejection__case__2__proof
      if: (proof_tag == proof_tag::case__2)
    - id: tx_rollup_rejection__case__1__proof
      type: tx_rollup_rejection__case__1__proof
      if: (proof_tag == proof_tag::case__1)
    - id: tx_rollup_rejection__case__3__proof
      type: tx_rollup_rejection__case__3__proof
      if: (proof_tag == proof_tag::case__3)
  tx_rollup_rejection__case__3__proof:
    seq:
    - id: case__3_field0
      type: s2
    - id: case__3_field1
      size: 32
      doc: context_hash
    - id: case__3_field2
      size: 32
      doc: context_hash
    - id: tx_rollup_rejection__case__3__case__3_field3
      type: tx_rollup_rejection__case__3__case__3_field3
  tx_rollup_rejection__case__3__case__3_field3:
    seq:
    - id: len_case__3_field3
      type: u4
      valid:
        max: 1073741823
    - id: case__3_field3
      type: tx_rollup_rejection__case__3__case__3_field3_entries
      size: len_case__3_field3
      repeat: eos
  tx_rollup_rejection__case__3__case__3_field3_entries:
    seq:
    - id: case__3_field3_elt_tag
      type: u1
      enum: case__3_field3_elt_tag
    - id: tx_rollup_rejection__case__3__case__0__case__3_field3_elt
      type: u1
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__0)
    - id: tx_rollup_rejection__case__3__case__8__case__3_field3_elt
      type: tx_rollup_rejection__case__3__case__8__case__3_field3_elt
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__8)
    - id: tx_rollup_rejection__case__3__case__4__case__3_field3_elt
      type: tx_rollup_rejection__case__3__case__4__case__3_field3_elt
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__4)
    - id: tx_rollup_rejection__case__3__case__12__case__3_field3_elt
      type: tx_rollup_rejection__case__3__case__12__case__3_field3_elt
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__12)
    - id: tx_rollup_rejection__case__3__case__1__case__3_field3_elt
      type: u2
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__1)
    - id: tx_rollup_rejection__case__3__case__9__case__3_field3_elt
      type: tx_rollup_rejection__case__3__case__9__case__3_field3_elt
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__9)
    - id: tx_rollup_rejection__case__3__case__5__case__3_field3_elt
      type: tx_rollup_rejection__case__3__case__5__case__3_field3_elt
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__5)
    - id: tx_rollup_rejection__case__3__case__13__case__3_field3_elt
      type: tx_rollup_rejection__case__3__case__13__case__3_field3_elt
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__13)
    - id: tx_rollup_rejection__case__3__case__2__case__3_field3_elt
      type: s4
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__2)
    - id: tx_rollup_rejection__case__3__case__10__case__3_field3_elt
      type: tx_rollup_rejection__case__3__case__10__case__3_field3_elt
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__10)
    - id: tx_rollup_rejection__case__3__case__6__case__3_field3_elt
      type: tx_rollup_rejection__case__3__case__6__case__3_field3_elt
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__6)
    - id: tx_rollup_rejection__case__3__case__14__case__3_field3_elt
      type: tx_rollup_rejection__case__3__case__14__case__3_field3_elt
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__14)
    - id: tx_rollup_rejection__case__3__case__3__case__3_field3_elt
      type: s8
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__3)
    - id: tx_rollup_rejection__case__3__case__11__case__3_field3_elt
      type: tx_rollup_rejection__case__3__case__11__case__3_field3_elt
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__11)
    - id: tx_rollup_rejection__case__3__case__7__case__3_field3_elt
      type: tx_rollup_rejection__case__3__case__7__case__3_field3_elt
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__7)
    - id: tx_rollup_rejection__case__3__case__15__case__3_field3_elt
      type: tx_rollup_rejection__case__3__case__15__case__3_field3_elt
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__15)
    - id: tx_rollup_rejection__case__3__case__129__case__3_field3_elt
      type: tx_rollup_rejection__case__3__case__129__case__129_entries
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__129)
    - id: tx_rollup_rejection__case__3__case__130__case__3_field3_elt
      type: tx_rollup_rejection__case__3__case__130__case__130_entries
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__130)
    - id: tx_rollup_rejection__case__3__case__131__case__3_field3_elt
      type: tx_rollup_rejection__case__3__case__131__case__3_field3_elt
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__131)
    - id: tx_rollup_rejection__case__3__case__192__case__3_field3_elt
      type: tx_rollup_rejection__case__3__case__192__case__3_field3_elt
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__192)
    - id: tx_rollup_rejection__case__3__case__193__case__3_field3_elt
      type: tx_rollup_rejection__case__3__case__193__case__3_field3_elt
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__193)
    - id: tx_rollup_rejection__case__3__case__195__case__3_field3_elt
      type: tx_rollup_rejection__case__3__case__195__case__3_field3_elt
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__195)
    - id: tx_rollup_rejection__case__3__case__224__case__3_field3_elt
      type: tx_rollup_rejection__case__3__case__224__case__3_field3_elt
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__224)
    - id: tx_rollup_rejection__case__3__case__225__case__3_field3_elt
      type: tx_rollup_rejection__case__3__case__225__case__3_field3_elt
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__225)
    - id: tx_rollup_rejection__case__3__case__226__case__3_field3_elt
      type: tx_rollup_rejection__case__3__case__226__case__3_field3_elt
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__226)
    - id: tx_rollup_rejection__case__3__case__227__case__3_field3_elt
      type: tx_rollup_rejection__case__3__case__227__case__3_field3_elt
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__227)
  tx_rollup_rejection__case__3__case__227__case__3_field3_elt:
    seq:
    - id: case__227_field0
      type: s8
    - id: tx_rollup_rejection__case__3__case__227__case__227_field1
      type: tx_rollup_rejection__case__3__case__227__case__227_field1
    - id: case__227_field2
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__3__case__227__case__227_field1:
    seq:
    - id: len_case__227_field1
      type: u1
      valid:
        max: 255
    - id: case__227_field1
      size: len_case__227_field1
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__3__case__226__case__3_field3_elt:
    seq:
    - id: case__226_field0
      type: s4
    - id: tx_rollup_rejection__case__3__case__226__case__226_field1
      type: tx_rollup_rejection__case__3__case__226__case__226_field1
    - id: case__226_field2
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__3__case__226__case__226_field1:
    seq:
    - id: len_case__226_field1
      type: u1
      valid:
        max: 255
    - id: case__226_field1
      size: len_case__226_field1
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__3__case__225__case__3_field3_elt:
    seq:
    - id: case__225_field0
      type: u2
    - id: tx_rollup_rejection__case__3__case__225__case__225_field1
      type: tx_rollup_rejection__case__3__case__225__case__225_field1
    - id: case__225_field2
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__3__case__225__case__225_field1:
    seq:
    - id: len_case__225_field1
      type: u1
      valid:
        max: 255
    - id: case__225_field1
      size: len_case__225_field1
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__3__case__224__case__3_field3_elt:
    seq:
    - id: case__224_field0
      type: u1
    - id: tx_rollup_rejection__case__3__case__224__case__224_field1
      type: tx_rollup_rejection__case__3__case__224__case__224_field1
    - id: case__224_field2
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__3__case__224__case__224_field1:
    seq:
    - id: len_case__224_field1
      type: u1
      valid:
        max: 255
    - id: case__224_field1
      size: len_case__224_field1
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__3__case__195__case__3_field3_elt:
    seq:
    - id: len_case__195
      type: u4
      valid:
        max: 1073741823
    - id: case__195
      size: len_case__195
  tx_rollup_rejection__case__3__case__193__case__3_field3_elt:
    seq:
    - id: len_case__193
      type: u2
      valid:
        max: 65535
    - id: case__193
      size: len_case__193
      size-eos: true
      valid:
        max: 65535
  tx_rollup_rejection__case__3__case__192__case__3_field3_elt:
    seq:
    - id: len_case__192
      type: u1
      valid:
        max: 255
    - id: case__192
      size: len_case__192
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__3__case__131__case__3_field3_elt:
    seq:
    - id: len_case__131
      type: u4
      valid:
        max: 1073741823
    - id: case__131
      type: tx_rollup_rejection__case__3__case__131__case__131_entries
      size: len_case__131
      repeat: eos
  tx_rollup_rejection__case__3__case__131__case__131_entries:
    seq:
    - id: tx_rollup_rejection__case__3__case__131__case__131_elt_field0
      type: tx_rollup_rejection__case__3__case__131__case__131_elt_field0
    - id: tx_rollup_rejection__case__3__case__131__case__131_elt_field1
      type: tx_rollup_rejection__case__3__case__131__case__131_elt_field1
  tx_rollup_rejection__case__3__case__131__case__131_elt_field1:
    seq:
    - id: case__131_elt_field1_tag
      type: u1
      enum: case__131_elt_field1_tag
    - id: tx_rollup_rejection__case__3__case__131__case__0__case__131_elt_field1
      size: 32
      if: (case__131_elt_field1_tag == case__131_elt_field1_tag::case__0)
    - id: tx_rollup_rejection__case__3__case__131__case__1__case__131_elt_field1
      size: 32
      if: (case__131_elt_field1_tag == case__131_elt_field1_tag::case__1)
  tx_rollup_rejection__case__3__case__131__case__131_elt_field0:
    seq:
    - id: len_case__131_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__131_elt_field0
      size: len_case__131_elt_field0
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__3__case__130__case__130_entries:
    seq:
    - id: tx_rollup_rejection__case__3__case__130__case__130_elt_field0
      type: tx_rollup_rejection__case__3__case__130__case__130_elt_field0
    - id: tx_rollup_rejection__case__3__case__130__case__130_elt_field1
      type: tx_rollup_rejection__case__3__case__130__case__130_elt_field1
  tx_rollup_rejection__case__3__case__130__case__130_elt_field1:
    seq:
    - id: case__130_elt_field1_tag
      type: u1
      enum: case__130_elt_field1_tag
    - id: tx_rollup_rejection__case__3__case__130__case__0__case__130_elt_field1
      size: 32
      if: (case__130_elt_field1_tag == case__130_elt_field1_tag::case__0)
    - id: tx_rollup_rejection__case__3__case__130__case__1__case__130_elt_field1
      size: 32
      if: (case__130_elt_field1_tag == case__130_elt_field1_tag::case__1)
  tx_rollup_rejection__case__3__case__130__case__130_elt_field0:
    seq:
    - id: len_case__130_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__130_elt_field0
      size: len_case__130_elt_field0
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__3__case__129__case__129_entries:
    seq:
    - id: tx_rollup_rejection__case__3__case__129__case__129_elt_field0
      type: tx_rollup_rejection__case__3__case__129__case__129_elt_field0
    - id: tx_rollup_rejection__case__3__case__129__case__129_elt_field1
      type: tx_rollup_rejection__case__3__case__129__case__129_elt_field1
  tx_rollup_rejection__case__3__case__129__case__129_elt_field1:
    seq:
    - id: case__129_elt_field1_tag
      type: u1
      enum: case__129_elt_field1_tag
    - id: tx_rollup_rejection__case__3__case__129__case__0__case__129_elt_field1
      size: 32
      if: (case__129_elt_field1_tag == case__129_elt_field1_tag::case__0)
    - id: tx_rollup_rejection__case__3__case__129__case__1__case__129_elt_field1
      size: 32
      if: (case__129_elt_field1_tag == case__129_elt_field1_tag::case__1)
  tx_rollup_rejection__case__3__case__129__case__129_elt_field0:
    seq:
    - id: len_case__129_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__129_elt_field0
      size: len_case__129_elt_field0
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__3__case__15__case__3_field3_elt:
    seq:
    - id: case__15_field0
      type: s8
    - id: tx_rollup_rejection__case__3__case__15__case__15_field1
      type: tx_rollup_rejection__case__3__case__15__case__15_field1
  tx_rollup_rejection__case__3__case__15__case__15_field1:
    seq:
    - id: case__15_field1_field0
      size: 32
      doc: context_hash
    - id: case__15_field1_field1
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__3__case__7__case__3_field3_elt:
    seq:
    - id: case__7_field0
      type: s8
    - id: case__7_field1
      size: 32
      doc: ! 'context_hash


        case__7_field1_field0'
  tx_rollup_rejection__case__3__case__11__case__3_field3_elt:
    seq:
    - id: case__11_field0
      type: s8
    - id: case__11_field1
      size: 32
      doc: ! 'context_hash


        case__11_field1_field1'
  tx_rollup_rejection__case__3__case__14__case__3_field3_elt:
    seq:
    - id: case__14_field0
      type: s4
    - id: tx_rollup_rejection__case__3__case__14__case__14_field1
      type: tx_rollup_rejection__case__3__case__14__case__14_field1
  tx_rollup_rejection__case__3__case__14__case__14_field1:
    seq:
    - id: case__14_field1_field0
      size: 32
      doc: context_hash
    - id: case__14_field1_field1
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__3__case__6__case__3_field3_elt:
    seq:
    - id: case__6_field0
      type: s4
    - id: case__6_field1
      size: 32
      doc: ! 'context_hash


        case__6_field1_field0'
  tx_rollup_rejection__case__3__case__10__case__3_field3_elt:
    seq:
    - id: case__10_field0
      type: s4
    - id: case__10_field1
      size: 32
      doc: ! 'context_hash


        case__10_field1_field1'
  tx_rollup_rejection__case__3__case__13__case__3_field3_elt:
    seq:
    - id: case__13_field0
      type: u2
    - id: tx_rollup_rejection__case__3__case__13__case__13_field1
      type: tx_rollup_rejection__case__3__case__13__case__13_field1
  tx_rollup_rejection__case__3__case__13__case__13_field1:
    seq:
    - id: case__13_field1_field0
      size: 32
      doc: context_hash
    - id: case__13_field1_field1
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__3__case__5__case__3_field3_elt:
    seq:
    - id: case__5_field0
      type: u2
    - id: case__5_field1
      size: 32
      doc: ! 'context_hash


        case__5_field1_field0'
  tx_rollup_rejection__case__3__case__9__case__3_field3_elt:
    seq:
    - id: case__9_field0
      type: u2
    - id: case__9_field1
      size: 32
      doc: ! 'context_hash


        case__9_field1_field1'
  tx_rollup_rejection__case__3__case__12__case__3_field3_elt:
    seq:
    - id: case__12_field0
      type: u1
    - id: tx_rollup_rejection__case__3__case__12__case__12_field1
      type: tx_rollup_rejection__case__3__case__12__case__12_field1
  tx_rollup_rejection__case__3__case__12__case__12_field1:
    seq:
    - id: case__12_field1_field0
      size: 32
      doc: context_hash
    - id: case__12_field1_field1
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__3__case__4__case__3_field3_elt:
    seq:
    - id: case__4_field0
      type: u1
    - id: case__4_field1
      size: 32
      doc: ! 'context_hash


        case__4_field1_field0'
  tx_rollup_rejection__case__3__case__8__case__3_field3_elt:
    seq:
    - id: case__8_field0
      type: u1
    - id: case__8_field1
      size: 32
      doc: ! 'context_hash


        case__8_field1_field1'
  tx_rollup_rejection__case__1__proof:
    seq:
    - id: case__1_field0
      type: s2
    - id: case__1_field1
      size: 32
      doc: context_hash
    - id: case__1_field2
      size: 32
      doc: context_hash
    - id: tx_rollup_rejection__case__1__case__1_field3
      type: tx_rollup_rejection__case__1__case__1_field3
  tx_rollup_rejection__case__1__case__1_field3:
    seq:
    - id: len_case__1_field3
      type: u4
      valid:
        max: 1073741823
    - id: case__1_field3
      type: tx_rollup_rejection__case__1__case__1_field3_entries
      size: len_case__1_field3
      repeat: eos
  tx_rollup_rejection__case__1__case__1_field3_entries:
    seq:
    - id: case__1_field3_elt_tag
      type: u1
      enum: case__1_field3_elt_tag
    - id: tx_rollup_rejection__case__1__case__0__case__1_field3_elt
      type: u1
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__0)
    - id: tx_rollup_rejection__case__1__case__8__case__1_field3_elt
      type: tx_rollup_rejection__case__1__case__8__case__1_field3_elt
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__8)
    - id: tx_rollup_rejection__case__1__case__4__case__1_field3_elt
      type: tx_rollup_rejection__case__1__case__4__case__1_field3_elt
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__4)
    - id: tx_rollup_rejection__case__1__case__12__case__1_field3_elt
      type: tx_rollup_rejection__case__1__case__12__case__1_field3_elt
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__12)
    - id: tx_rollup_rejection__case__1__case__1__case__1_field3_elt
      type: u2
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__1)
    - id: tx_rollup_rejection__case__1__case__9__case__1_field3_elt
      type: tx_rollup_rejection__case__1__case__9__case__1_field3_elt
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__9)
    - id: tx_rollup_rejection__case__1__case__5__case__1_field3_elt
      type: tx_rollup_rejection__case__1__case__5__case__1_field3_elt
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__5)
    - id: tx_rollup_rejection__case__1__case__13__case__1_field3_elt
      type: tx_rollup_rejection__case__1__case__13__case__1_field3_elt
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__13)
    - id: tx_rollup_rejection__case__1__case__2__case__1_field3_elt
      type: s4
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__2)
    - id: tx_rollup_rejection__case__1__case__10__case__1_field3_elt
      type: tx_rollup_rejection__case__1__case__10__case__1_field3_elt
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__10)
    - id: tx_rollup_rejection__case__1__case__6__case__1_field3_elt
      type: tx_rollup_rejection__case__1__case__6__case__1_field3_elt
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__6)
    - id: tx_rollup_rejection__case__1__case__14__case__1_field3_elt
      type: tx_rollup_rejection__case__1__case__14__case__1_field3_elt
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__14)
    - id: tx_rollup_rejection__case__1__case__3__case__1_field3_elt
      type: s8
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__3)
    - id: tx_rollup_rejection__case__1__case__11__case__1_field3_elt
      type: tx_rollup_rejection__case__1__case__11__case__1_field3_elt
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__11)
    - id: tx_rollup_rejection__case__1__case__7__case__1_field3_elt
      type: tx_rollup_rejection__case__1__case__7__case__1_field3_elt
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__7)
    - id: tx_rollup_rejection__case__1__case__15__case__1_field3_elt
      type: tx_rollup_rejection__case__1__case__15__case__1_field3_elt
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__15)
    - id: tx_rollup_rejection__case__1__case__129__case__1_field3_elt
      type: tx_rollup_rejection__case__1__case__129__case__129_entries
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__129)
    - id: tx_rollup_rejection__case__1__case__130__case__1_field3_elt
      type: tx_rollup_rejection__case__1__case__130__case__130_entries
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__130)
    - id: tx_rollup_rejection__case__1__case__131__case__1_field3_elt
      type: tx_rollup_rejection__case__1__case__131__case__1_field3_elt
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__131)
    - id: tx_rollup_rejection__case__1__case__192__case__1_field3_elt
      type: tx_rollup_rejection__case__1__case__192__case__1_field3_elt
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__192)
    - id: tx_rollup_rejection__case__1__case__193__case__1_field3_elt
      type: tx_rollup_rejection__case__1__case__193__case__1_field3_elt
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__193)
    - id: tx_rollup_rejection__case__1__case__195__case__1_field3_elt
      type: tx_rollup_rejection__case__1__case__195__case__1_field3_elt
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__195)
    - id: tx_rollup_rejection__case__1__case__224__case__1_field3_elt
      type: tx_rollup_rejection__case__1__case__224__case__1_field3_elt
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__224)
    - id: tx_rollup_rejection__case__1__case__225__case__1_field3_elt
      type: tx_rollup_rejection__case__1__case__225__case__1_field3_elt
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__225)
    - id: tx_rollup_rejection__case__1__case__226__case__1_field3_elt
      type: tx_rollup_rejection__case__1__case__226__case__1_field3_elt
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__226)
    - id: tx_rollup_rejection__case__1__case__227__case__1_field3_elt
      type: tx_rollup_rejection__case__1__case__227__case__1_field3_elt
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__227)
  tx_rollup_rejection__case__1__case__227__case__1_field3_elt:
    seq:
    - id: case__227_field0
      type: s8
    - id: tx_rollup_rejection__case__1__case__227__case__227_field1
      type: tx_rollup_rejection__case__1__case__227__case__227_field1
    - id: case__227_field2
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__1__case__227__case__227_field1:
    seq:
    - id: len_case__227_field1
      type: u1
      valid:
        max: 255
    - id: case__227_field1
      size: len_case__227_field1
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__1__case__226__case__1_field3_elt:
    seq:
    - id: case__226_field0
      type: s4
    - id: tx_rollup_rejection__case__1__case__226__case__226_field1
      type: tx_rollup_rejection__case__1__case__226__case__226_field1
    - id: case__226_field2
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__1__case__226__case__226_field1:
    seq:
    - id: len_case__226_field1
      type: u1
      valid:
        max: 255
    - id: case__226_field1
      size: len_case__226_field1
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__1__case__225__case__1_field3_elt:
    seq:
    - id: case__225_field0
      type: u2
    - id: tx_rollup_rejection__case__1__case__225__case__225_field1
      type: tx_rollup_rejection__case__1__case__225__case__225_field1
    - id: case__225_field2
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__1__case__225__case__225_field1:
    seq:
    - id: len_case__225_field1
      type: u1
      valid:
        max: 255
    - id: case__225_field1
      size: len_case__225_field1
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__1__case__224__case__1_field3_elt:
    seq:
    - id: case__224_field0
      type: u1
    - id: tx_rollup_rejection__case__1__case__224__case__224_field1
      type: tx_rollup_rejection__case__1__case__224__case__224_field1
    - id: case__224_field2
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__1__case__224__case__224_field1:
    seq:
    - id: len_case__224_field1
      type: u1
      valid:
        max: 255
    - id: case__224_field1
      size: len_case__224_field1
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__1__case__195__case__1_field3_elt:
    seq:
    - id: len_case__195
      type: u4
      valid:
        max: 1073741823
    - id: case__195
      size: len_case__195
  tx_rollup_rejection__case__1__case__193__case__1_field3_elt:
    seq:
    - id: len_case__193
      type: u2
      valid:
        max: 65535
    - id: case__193
      size: len_case__193
      size-eos: true
      valid:
        max: 65535
  tx_rollup_rejection__case__1__case__192__case__1_field3_elt:
    seq:
    - id: len_case__192
      type: u1
      valid:
        max: 255
    - id: case__192
      size: len_case__192
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__1__case__131__case__1_field3_elt:
    seq:
    - id: len_case__131
      type: u4
      valid:
        max: 1073741823
    - id: case__131
      type: tx_rollup_rejection__case__1__case__131__case__131_entries
      size: len_case__131
      repeat: eos
  tx_rollup_rejection__case__1__case__131__case__131_entries:
    seq:
    - id: tx_rollup_rejection__case__1__case__131__case__131_elt_field0
      type: tx_rollup_rejection__case__1__case__131__case__131_elt_field0
    - id: tx_rollup_rejection__case__1__case__131__case__131_elt_field1
      type: tx_rollup_rejection__case__1__case__131__case__131_elt_field1
  tx_rollup_rejection__case__1__case__131__case__131_elt_field1:
    seq:
    - id: case__131_elt_field1_tag
      type: u1
      enum: case__131_elt_field1_tag
    - id: tx_rollup_rejection__case__1__case__131__case__0__case__131_elt_field1
      size: 32
      if: (case__131_elt_field1_tag == case__131_elt_field1_tag::case__0)
    - id: tx_rollup_rejection__case__1__case__131__case__1__case__131_elt_field1
      size: 32
      if: (case__131_elt_field1_tag == case__131_elt_field1_tag::case__1)
  tx_rollup_rejection__case__1__case__131__case__131_elt_field0:
    seq:
    - id: len_case__131_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__131_elt_field0
      size: len_case__131_elt_field0
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__1__case__130__case__130_entries:
    seq:
    - id: tx_rollup_rejection__case__1__case__130__case__130_elt_field0
      type: tx_rollup_rejection__case__1__case__130__case__130_elt_field0
    - id: tx_rollup_rejection__case__1__case__130__case__130_elt_field1
      type: tx_rollup_rejection__case__1__case__130__case__130_elt_field1
  tx_rollup_rejection__case__1__case__130__case__130_elt_field1:
    seq:
    - id: case__130_elt_field1_tag
      type: u1
      enum: case__130_elt_field1_tag
    - id: tx_rollup_rejection__case__1__case__130__case__0__case__130_elt_field1
      size: 32
      if: (case__130_elt_field1_tag == case__130_elt_field1_tag::case__0)
    - id: tx_rollup_rejection__case__1__case__130__case__1__case__130_elt_field1
      size: 32
      if: (case__130_elt_field1_tag == case__130_elt_field1_tag::case__1)
  tx_rollup_rejection__case__1__case__130__case__130_elt_field0:
    seq:
    - id: len_case__130_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__130_elt_field0
      size: len_case__130_elt_field0
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__1__case__129__case__129_entries:
    seq:
    - id: tx_rollup_rejection__case__1__case__129__case__129_elt_field0
      type: tx_rollup_rejection__case__1__case__129__case__129_elt_field0
    - id: tx_rollup_rejection__case__1__case__129__case__129_elt_field1
      type: tx_rollup_rejection__case__1__case__129__case__129_elt_field1
  tx_rollup_rejection__case__1__case__129__case__129_elt_field1:
    seq:
    - id: case__129_elt_field1_tag
      type: u1
      enum: case__129_elt_field1_tag
    - id: tx_rollup_rejection__case__1__case__129__case__0__case__129_elt_field1
      size: 32
      if: (case__129_elt_field1_tag == case__129_elt_field1_tag::case__0)
    - id: tx_rollup_rejection__case__1__case__129__case__1__case__129_elt_field1
      size: 32
      if: (case__129_elt_field1_tag == case__129_elt_field1_tag::case__1)
  tx_rollup_rejection__case__1__case__129__case__129_elt_field0:
    seq:
    - id: len_case__129_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__129_elt_field0
      size: len_case__129_elt_field0
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__1__case__15__case__1_field3_elt:
    seq:
    - id: case__15_field0
      type: s8
    - id: tx_rollup_rejection__case__1__case__15__case__15_field1
      type: tx_rollup_rejection__case__1__case__15__case__15_field1
  tx_rollup_rejection__case__1__case__15__case__15_field1:
    seq:
    - id: case__15_field1_field0
      size: 32
      doc: context_hash
    - id: case__15_field1_field1
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__1__case__7__case__1_field3_elt:
    seq:
    - id: case__7_field0
      type: s8
    - id: case__7_field1
      size: 32
      doc: ! 'context_hash


        case__7_field1_field0'
  tx_rollup_rejection__case__1__case__11__case__1_field3_elt:
    seq:
    - id: case__11_field0
      type: s8
    - id: case__11_field1
      size: 32
      doc: ! 'context_hash


        case__11_field1_field1'
  tx_rollup_rejection__case__1__case__14__case__1_field3_elt:
    seq:
    - id: case__14_field0
      type: s4
    - id: tx_rollup_rejection__case__1__case__14__case__14_field1
      type: tx_rollup_rejection__case__1__case__14__case__14_field1
  tx_rollup_rejection__case__1__case__14__case__14_field1:
    seq:
    - id: case__14_field1_field0
      size: 32
      doc: context_hash
    - id: case__14_field1_field1
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__1__case__6__case__1_field3_elt:
    seq:
    - id: case__6_field0
      type: s4
    - id: case__6_field1
      size: 32
      doc: ! 'context_hash


        case__6_field1_field0'
  tx_rollup_rejection__case__1__case__10__case__1_field3_elt:
    seq:
    - id: case__10_field0
      type: s4
    - id: case__10_field1
      size: 32
      doc: ! 'context_hash


        case__10_field1_field1'
  tx_rollup_rejection__case__1__case__13__case__1_field3_elt:
    seq:
    - id: case__13_field0
      type: u2
    - id: tx_rollup_rejection__case__1__case__13__case__13_field1
      type: tx_rollup_rejection__case__1__case__13__case__13_field1
  tx_rollup_rejection__case__1__case__13__case__13_field1:
    seq:
    - id: case__13_field1_field0
      size: 32
      doc: context_hash
    - id: case__13_field1_field1
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__1__case__5__case__1_field3_elt:
    seq:
    - id: case__5_field0
      type: u2
    - id: case__5_field1
      size: 32
      doc: ! 'context_hash


        case__5_field1_field0'
  tx_rollup_rejection__case__1__case__9__case__1_field3_elt:
    seq:
    - id: case__9_field0
      type: u2
    - id: case__9_field1
      size: 32
      doc: ! 'context_hash


        case__9_field1_field1'
  tx_rollup_rejection__case__1__case__12__case__1_field3_elt:
    seq:
    - id: case__12_field0
      type: u1
    - id: tx_rollup_rejection__case__1__case__12__case__12_field1
      type: tx_rollup_rejection__case__1__case__12__case__12_field1
  tx_rollup_rejection__case__1__case__12__case__12_field1:
    seq:
    - id: case__12_field1_field0
      size: 32
      doc: context_hash
    - id: case__12_field1_field1
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__1__case__4__case__1_field3_elt:
    seq:
    - id: case__4_field0
      type: u1
    - id: case__4_field1
      size: 32
      doc: ! 'context_hash


        case__4_field1_field0'
  tx_rollup_rejection__case__1__case__8__case__1_field3_elt:
    seq:
    - id: case__8_field0
      type: u1
    - id: case__8_field1
      size: 32
      doc: ! 'context_hash


        case__8_field1_field1'
  tx_rollup_rejection__case__2__proof:
    seq:
    - id: case__2_field0
      type: s2
    - id: case__2_field1
      size: 32
      doc: context_hash
    - id: case__2_field2
      size: 32
      doc: context_hash
    - id: tx_rollup_rejection__case__2__case__2_field3
      type: tx_rollup_rejection__case__2__case__2_field3
  tx_rollup_rejection__case__2__case__2_field3:
    seq:
    - id: len_case__2_field3
      type: u4
      valid:
        max: 1073741823
    - id: case__2_field3
      type: tx_rollup_rejection__case__2__case__2_field3_entries
      size: len_case__2_field3
      repeat: eos
  tx_rollup_rejection__case__2__case__2_field3_entries:
    seq:
    - id: case__2_field3_elt_tag
      type: u1
      enum: case__2_field3_elt_tag
    - id: tx_rollup_rejection__case__2__case__0__case__2_field3_elt
      type: u1
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__0)
    - id: tx_rollup_rejection__case__2__case__8__case__2_field3_elt
      type: tx_rollup_rejection__case__2__case__8__case__2_field3_elt
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__8)
    - id: tx_rollup_rejection__case__2__case__4__case__2_field3_elt
      type: tx_rollup_rejection__case__2__case__4__case__2_field3_elt
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__4)
    - id: tx_rollup_rejection__case__2__case__12__case__2_field3_elt
      type: tx_rollup_rejection__case__2__case__12__case__2_field3_elt
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__12)
    - id: tx_rollup_rejection__case__2__case__1__case__2_field3_elt
      type: u2
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__1)
    - id: tx_rollup_rejection__case__2__case__9__case__2_field3_elt
      type: tx_rollup_rejection__case__2__case__9__case__2_field3_elt
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__9)
    - id: tx_rollup_rejection__case__2__case__5__case__2_field3_elt
      type: tx_rollup_rejection__case__2__case__5__case__2_field3_elt
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__5)
    - id: tx_rollup_rejection__case__2__case__13__case__2_field3_elt
      type: tx_rollup_rejection__case__2__case__13__case__2_field3_elt
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__13)
    - id: tx_rollup_rejection__case__2__case__2__case__2_field3_elt
      type: s4
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__2)
    - id: tx_rollup_rejection__case__2__case__10__case__2_field3_elt
      type: tx_rollup_rejection__case__2__case__10__case__2_field3_elt
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__10)
    - id: tx_rollup_rejection__case__2__case__6__case__2_field3_elt
      type: tx_rollup_rejection__case__2__case__6__case__2_field3_elt
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__6)
    - id: tx_rollup_rejection__case__2__case__14__case__2_field3_elt
      type: tx_rollup_rejection__case__2__case__14__case__2_field3_elt
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__14)
    - id: tx_rollup_rejection__case__2__case__3__case__2_field3_elt
      type: s8
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__3)
    - id: tx_rollup_rejection__case__2__case__11__case__2_field3_elt
      type: tx_rollup_rejection__case__2__case__11__case__2_field3_elt
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__11)
    - id: tx_rollup_rejection__case__2__case__7__case__2_field3_elt
      type: tx_rollup_rejection__case__2__case__7__case__2_field3_elt
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__7)
    - id: tx_rollup_rejection__case__2__case__15__case__2_field3_elt
      type: tx_rollup_rejection__case__2__case__15__case__2_field3_elt
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__15)
    - id: tx_rollup_rejection__case__2__case__129__case__2_field3_elt
      type: tx_rollup_rejection__case__2__case__129__case__129_entries
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__129)
    - id: tx_rollup_rejection__case__2__case__130__case__2_field3_elt
      type: tx_rollup_rejection__case__2__case__130__case__130_entries
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__130)
    - id: tx_rollup_rejection__case__2__case__131__case__2_field3_elt
      type: tx_rollup_rejection__case__2__case__131__case__2_field3_elt
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__131)
    - id: tx_rollup_rejection__case__2__case__192__case__2_field3_elt
      type: tx_rollup_rejection__case__2__case__192__case__2_field3_elt
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__192)
    - id: tx_rollup_rejection__case__2__case__193__case__2_field3_elt
      type: tx_rollup_rejection__case__2__case__193__case__2_field3_elt
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__193)
    - id: tx_rollup_rejection__case__2__case__195__case__2_field3_elt
      type: tx_rollup_rejection__case__2__case__195__case__2_field3_elt
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__195)
    - id: tx_rollup_rejection__case__2__case__224__case__2_field3_elt
      type: tx_rollup_rejection__case__2__case__224__case__2_field3_elt
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__224)
    - id: tx_rollup_rejection__case__2__case__225__case__2_field3_elt
      type: tx_rollup_rejection__case__2__case__225__case__2_field3_elt
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__225)
    - id: tx_rollup_rejection__case__2__case__226__case__2_field3_elt
      type: tx_rollup_rejection__case__2__case__226__case__2_field3_elt
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__226)
    - id: tx_rollup_rejection__case__2__case__227__case__2_field3_elt
      type: tx_rollup_rejection__case__2__case__227__case__2_field3_elt
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__227)
  tx_rollup_rejection__case__2__case__227__case__2_field3_elt:
    seq:
    - id: case__227_field0
      type: s8
    - id: tx_rollup_rejection__case__2__case__227__case__227_field1
      type: tx_rollup_rejection__case__2__case__227__case__227_field1
    - id: case__227_field2
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__2__case__227__case__227_field1:
    seq:
    - id: len_case__227_field1
      type: u1
      valid:
        max: 255
    - id: case__227_field1
      size: len_case__227_field1
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__2__case__226__case__2_field3_elt:
    seq:
    - id: case__226_field0
      type: s4
    - id: tx_rollup_rejection__case__2__case__226__case__226_field1
      type: tx_rollup_rejection__case__2__case__226__case__226_field1
    - id: case__226_field2
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__2__case__226__case__226_field1:
    seq:
    - id: len_case__226_field1
      type: u1
      valid:
        max: 255
    - id: case__226_field1
      size: len_case__226_field1
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__2__case__225__case__2_field3_elt:
    seq:
    - id: case__225_field0
      type: u2
    - id: tx_rollup_rejection__case__2__case__225__case__225_field1
      type: tx_rollup_rejection__case__2__case__225__case__225_field1
    - id: case__225_field2
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__2__case__225__case__225_field1:
    seq:
    - id: len_case__225_field1
      type: u1
      valid:
        max: 255
    - id: case__225_field1
      size: len_case__225_field1
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__2__case__224__case__2_field3_elt:
    seq:
    - id: case__224_field0
      type: u1
    - id: tx_rollup_rejection__case__2__case__224__case__224_field1
      type: tx_rollup_rejection__case__2__case__224__case__224_field1
    - id: case__224_field2
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__2__case__224__case__224_field1:
    seq:
    - id: len_case__224_field1
      type: u1
      valid:
        max: 255
    - id: case__224_field1
      size: len_case__224_field1
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__2__case__195__case__2_field3_elt:
    seq:
    - id: len_case__195
      type: u4
      valid:
        max: 1073741823
    - id: case__195
      size: len_case__195
  tx_rollup_rejection__case__2__case__193__case__2_field3_elt:
    seq:
    - id: len_case__193
      type: u2
      valid:
        max: 65535
    - id: case__193
      size: len_case__193
      size-eos: true
      valid:
        max: 65535
  tx_rollup_rejection__case__2__case__192__case__2_field3_elt:
    seq:
    - id: len_case__192
      type: u1
      valid:
        max: 255
    - id: case__192
      size: len_case__192
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__2__case__131__case__2_field3_elt:
    seq:
    - id: len_case__131
      type: u4
      valid:
        max: 1073741823
    - id: case__131
      type: tx_rollup_rejection__case__2__case__131__case__131_entries
      size: len_case__131
      repeat: eos
  tx_rollup_rejection__case__2__case__131__case__131_entries:
    seq:
    - id: tx_rollup_rejection__case__2__case__131__case__131_elt_field0
      type: tx_rollup_rejection__case__2__case__131__case__131_elt_field0
    - id: tx_rollup_rejection__case__2__case__131__case__131_elt_field1
      type: tx_rollup_rejection__case__2__case__131__case__131_elt_field1
  tx_rollup_rejection__case__2__case__131__case__131_elt_field1:
    seq:
    - id: case__131_elt_field1_tag
      type: u1
      enum: case__131_elt_field1_tag
    - id: tx_rollup_rejection__case__2__case__131__case__0__case__131_elt_field1
      size: 32
      if: (case__131_elt_field1_tag == case__131_elt_field1_tag::case__0)
    - id: tx_rollup_rejection__case__2__case__131__case__1__case__131_elt_field1
      size: 32
      if: (case__131_elt_field1_tag == case__131_elt_field1_tag::case__1)
  tx_rollup_rejection__case__2__case__131__case__131_elt_field0:
    seq:
    - id: len_case__131_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__131_elt_field0
      size: len_case__131_elt_field0
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__2__case__130__case__130_entries:
    seq:
    - id: tx_rollup_rejection__case__2__case__130__case__130_elt_field0
      type: tx_rollup_rejection__case__2__case__130__case__130_elt_field0
    - id: tx_rollup_rejection__case__2__case__130__case__130_elt_field1
      type: tx_rollup_rejection__case__2__case__130__case__130_elt_field1
  tx_rollup_rejection__case__2__case__130__case__130_elt_field1:
    seq:
    - id: case__130_elt_field1_tag
      type: u1
      enum: case__130_elt_field1_tag
    - id: tx_rollup_rejection__case__2__case__130__case__0__case__130_elt_field1
      size: 32
      if: (case__130_elt_field1_tag == case__130_elt_field1_tag::case__0)
    - id: tx_rollup_rejection__case__2__case__130__case__1__case__130_elt_field1
      size: 32
      if: (case__130_elt_field1_tag == case__130_elt_field1_tag::case__1)
  tx_rollup_rejection__case__2__case__130__case__130_elt_field0:
    seq:
    - id: len_case__130_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__130_elt_field0
      size: len_case__130_elt_field0
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__2__case__129__case__129_entries:
    seq:
    - id: tx_rollup_rejection__case__2__case__129__case__129_elt_field0
      type: tx_rollup_rejection__case__2__case__129__case__129_elt_field0
    - id: tx_rollup_rejection__case__2__case__129__case__129_elt_field1
      type: tx_rollup_rejection__case__2__case__129__case__129_elt_field1
  tx_rollup_rejection__case__2__case__129__case__129_elt_field1:
    seq:
    - id: case__129_elt_field1_tag
      type: u1
      enum: case__129_elt_field1_tag
    - id: tx_rollup_rejection__case__2__case__129__case__0__case__129_elt_field1
      size: 32
      if: (case__129_elt_field1_tag == case__129_elt_field1_tag::case__0)
    - id: tx_rollup_rejection__case__2__case__129__case__1__case__129_elt_field1
      size: 32
      if: (case__129_elt_field1_tag == case__129_elt_field1_tag::case__1)
  tx_rollup_rejection__case__2__case__129__case__129_elt_field0:
    seq:
    - id: len_case__129_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__129_elt_field0
      size: len_case__129_elt_field0
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__2__case__15__case__2_field3_elt:
    seq:
    - id: case__15_field0
      type: s8
    - id: tx_rollup_rejection__case__2__case__15__case__15_field1
      type: tx_rollup_rejection__case__2__case__15__case__15_field1
  tx_rollup_rejection__case__2__case__15__case__15_field1:
    seq:
    - id: case__15_field1_field0
      size: 32
      doc: context_hash
    - id: case__15_field1_field1
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__2__case__7__case__2_field3_elt:
    seq:
    - id: case__7_field0
      type: s8
    - id: case__7_field1
      size: 32
      doc: ! 'context_hash


        case__7_field1_field0'
  tx_rollup_rejection__case__2__case__11__case__2_field3_elt:
    seq:
    - id: case__11_field0
      type: s8
    - id: case__11_field1
      size: 32
      doc: ! 'context_hash


        case__11_field1_field1'
  tx_rollup_rejection__case__2__case__14__case__2_field3_elt:
    seq:
    - id: case__14_field0
      type: s4
    - id: tx_rollup_rejection__case__2__case__14__case__14_field1
      type: tx_rollup_rejection__case__2__case__14__case__14_field1
  tx_rollup_rejection__case__2__case__14__case__14_field1:
    seq:
    - id: case__14_field1_field0
      size: 32
      doc: context_hash
    - id: case__14_field1_field1
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__2__case__6__case__2_field3_elt:
    seq:
    - id: case__6_field0
      type: s4
    - id: case__6_field1
      size: 32
      doc: ! 'context_hash


        case__6_field1_field0'
  tx_rollup_rejection__case__2__case__10__case__2_field3_elt:
    seq:
    - id: case__10_field0
      type: s4
    - id: case__10_field1
      size: 32
      doc: ! 'context_hash


        case__10_field1_field1'
  tx_rollup_rejection__case__2__case__13__case__2_field3_elt:
    seq:
    - id: case__13_field0
      type: u2
    - id: tx_rollup_rejection__case__2__case__13__case__13_field1
      type: tx_rollup_rejection__case__2__case__13__case__13_field1
  tx_rollup_rejection__case__2__case__13__case__13_field1:
    seq:
    - id: case__13_field1_field0
      size: 32
      doc: context_hash
    - id: case__13_field1_field1
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__2__case__5__case__2_field3_elt:
    seq:
    - id: case__5_field0
      type: u2
    - id: case__5_field1
      size: 32
      doc: ! 'context_hash


        case__5_field1_field0'
  tx_rollup_rejection__case__2__case__9__case__2_field3_elt:
    seq:
    - id: case__9_field0
      type: u2
    - id: case__9_field1
      size: 32
      doc: ! 'context_hash


        case__9_field1_field1'
  tx_rollup_rejection__case__2__case__12__case__2_field3_elt:
    seq:
    - id: case__12_field0
      type: u1
    - id: tx_rollup_rejection__case__2__case__12__case__12_field1
      type: tx_rollup_rejection__case__2__case__12__case__12_field1
  tx_rollup_rejection__case__2__case__12__case__12_field1:
    seq:
    - id: case__12_field1_field0
      size: 32
      doc: context_hash
    - id: case__12_field1_field1
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__2__case__4__case__2_field3_elt:
    seq:
    - id: case__4_field0
      type: u1
    - id: case__4_field1
      size: 32
      doc: ! 'context_hash


        case__4_field1_field0'
  tx_rollup_rejection__case__2__case__8__case__2_field3_elt:
    seq:
    - id: case__8_field0
      type: u1
    - id: case__8_field1
      size: 32
      doc: ! 'context_hash


        case__8_field1_field1'
  tx_rollup_rejection__case__0__proof:
    seq:
    - id: case__0_field0
      type: s2
    - id: case__0_field1
      size: 32
      doc: context_hash
    - id: case__0_field2
      size: 32
      doc: context_hash
    - id: tx_rollup_rejection__case__0__case__0_field3
      type: tx_rollup_rejection__case__0__case__0_field3
  tx_rollup_rejection__case__0__case__0_field3:
    seq:
    - id: len_case__0_field3
      type: u4
      valid:
        max: 1073741823
    - id: case__0_field3
      type: tx_rollup_rejection__case__0__case__0_field3_entries
      size: len_case__0_field3
      repeat: eos
  tx_rollup_rejection__case__0__case__0_field3_entries:
    seq:
    - id: case__0_field3_elt_tag
      type: u1
      enum: case__0_field3_elt_tag
    - id: tx_rollup_rejection__case__0__case__0__case__0_field3_elt
      type: u1
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__0)
    - id: tx_rollup_rejection__case__0__case__8__case__0_field3_elt
      type: tx_rollup_rejection__case__0__case__8__case__0_field3_elt
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__8)
    - id: tx_rollup_rejection__case__0__case__4__case__0_field3_elt
      type: tx_rollup_rejection__case__0__case__4__case__0_field3_elt
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__4)
    - id: tx_rollup_rejection__case__0__case__12__case__0_field3_elt
      type: tx_rollup_rejection__case__0__case__12__case__0_field3_elt
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__12)
    - id: tx_rollup_rejection__case__0__case__1__case__0_field3_elt
      type: u2
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__1)
    - id: tx_rollup_rejection__case__0__case__9__case__0_field3_elt
      type: tx_rollup_rejection__case__0__case__9__case__0_field3_elt
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__9)
    - id: tx_rollup_rejection__case__0__case__5__case__0_field3_elt
      type: tx_rollup_rejection__case__0__case__5__case__0_field3_elt
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__5)
    - id: tx_rollup_rejection__case__0__case__13__case__0_field3_elt
      type: tx_rollup_rejection__case__0__case__13__case__0_field3_elt
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__13)
    - id: tx_rollup_rejection__case__0__case__2__case__0_field3_elt
      type: s4
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__2)
    - id: tx_rollup_rejection__case__0__case__10__case__0_field3_elt
      type: tx_rollup_rejection__case__0__case__10__case__0_field3_elt
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__10)
    - id: tx_rollup_rejection__case__0__case__6__case__0_field3_elt
      type: tx_rollup_rejection__case__0__case__6__case__0_field3_elt
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__6)
    - id: tx_rollup_rejection__case__0__case__14__case__0_field3_elt
      type: tx_rollup_rejection__case__0__case__14__case__0_field3_elt
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__14)
    - id: tx_rollup_rejection__case__0__case__3__case__0_field3_elt
      type: s8
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__3)
    - id: tx_rollup_rejection__case__0__case__11__case__0_field3_elt
      type: tx_rollup_rejection__case__0__case__11__case__0_field3_elt
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__11)
    - id: tx_rollup_rejection__case__0__case__7__case__0_field3_elt
      type: tx_rollup_rejection__case__0__case__7__case__0_field3_elt
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__7)
    - id: tx_rollup_rejection__case__0__case__15__case__0_field3_elt
      type: tx_rollup_rejection__case__0__case__15__case__0_field3_elt
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__15)
    - id: tx_rollup_rejection__case__0__case__129__case__0_field3_elt
      type: tx_rollup_rejection__case__0__case__129__case__129_entries
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__129)
    - id: tx_rollup_rejection__case__0__case__130__case__0_field3_elt
      type: tx_rollup_rejection__case__0__case__130__case__130_entries
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__130)
    - id: tx_rollup_rejection__case__0__case__131__case__0_field3_elt
      type: tx_rollup_rejection__case__0__case__131__case__0_field3_elt
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__131)
    - id: tx_rollup_rejection__case__0__case__192__case__0_field3_elt
      type: tx_rollup_rejection__case__0__case__192__case__0_field3_elt
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__192)
    - id: tx_rollup_rejection__case__0__case__193__case__0_field3_elt
      type: tx_rollup_rejection__case__0__case__193__case__0_field3_elt
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__193)
    - id: tx_rollup_rejection__case__0__case__195__case__0_field3_elt
      type: tx_rollup_rejection__case__0__case__195__case__0_field3_elt
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__195)
    - id: tx_rollup_rejection__case__0__case__224__case__0_field3_elt
      type: tx_rollup_rejection__case__0__case__224__case__0_field3_elt
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__224)
    - id: tx_rollup_rejection__case__0__case__225__case__0_field3_elt
      type: tx_rollup_rejection__case__0__case__225__case__0_field3_elt
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__225)
    - id: tx_rollup_rejection__case__0__case__226__case__0_field3_elt
      type: tx_rollup_rejection__case__0__case__226__case__0_field3_elt
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__226)
    - id: tx_rollup_rejection__case__0__case__227__case__0_field3_elt
      type: tx_rollup_rejection__case__0__case__227__case__0_field3_elt
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__227)
  tx_rollup_rejection__case__0__case__227__case__0_field3_elt:
    seq:
    - id: case__227_field0
      type: s8
    - id: tx_rollup_rejection__case__0__case__227__case__227_field1
      type: tx_rollup_rejection__case__0__case__227__case__227_field1
    - id: case__227_field2
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__0__case__227__case__227_field1:
    seq:
    - id: len_case__227_field1
      type: u1
      valid:
        max: 255
    - id: case__227_field1
      size: len_case__227_field1
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__0__case__226__case__0_field3_elt:
    seq:
    - id: case__226_field0
      type: s4
    - id: tx_rollup_rejection__case__0__case__226__case__226_field1
      type: tx_rollup_rejection__case__0__case__226__case__226_field1
    - id: case__226_field2
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__0__case__226__case__226_field1:
    seq:
    - id: len_case__226_field1
      type: u1
      valid:
        max: 255
    - id: case__226_field1
      size: len_case__226_field1
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__0__case__225__case__0_field3_elt:
    seq:
    - id: case__225_field0
      type: u2
    - id: tx_rollup_rejection__case__0__case__225__case__225_field1
      type: tx_rollup_rejection__case__0__case__225__case__225_field1
    - id: case__225_field2
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__0__case__225__case__225_field1:
    seq:
    - id: len_case__225_field1
      type: u1
      valid:
        max: 255
    - id: case__225_field1
      size: len_case__225_field1
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__0__case__224__case__0_field3_elt:
    seq:
    - id: case__224_field0
      type: u1
    - id: tx_rollup_rejection__case__0__case__224__case__224_field1
      type: tx_rollup_rejection__case__0__case__224__case__224_field1
    - id: case__224_field2
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__0__case__224__case__224_field1:
    seq:
    - id: len_case__224_field1
      type: u1
      valid:
        max: 255
    - id: case__224_field1
      size: len_case__224_field1
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__0__case__195__case__0_field3_elt:
    seq:
    - id: len_case__195
      type: u4
      valid:
        max: 1073741823
    - id: case__195
      size: len_case__195
  tx_rollup_rejection__case__0__case__193__case__0_field3_elt:
    seq:
    - id: len_case__193
      type: u2
      valid:
        max: 65535
    - id: case__193
      size: len_case__193
      size-eos: true
      valid:
        max: 65535
  tx_rollup_rejection__case__0__case__192__case__0_field3_elt:
    seq:
    - id: len_case__192
      type: u1
      valid:
        max: 255
    - id: case__192
      size: len_case__192
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__0__case__131__case__0_field3_elt:
    seq:
    - id: len_case__131
      type: u4
      valid:
        max: 1073741823
    - id: case__131
      type: tx_rollup_rejection__case__0__case__131__case__131_entries
      size: len_case__131
      repeat: eos
  tx_rollup_rejection__case__0__case__131__case__131_entries:
    seq:
    - id: tx_rollup_rejection__case__0__case__131__case__131_elt_field0
      type: tx_rollup_rejection__case__0__case__131__case__131_elt_field0
    - id: tx_rollup_rejection__case__0__case__131__case__131_elt_field1
      type: tx_rollup_rejection__case__0__case__131__case__131_elt_field1
  tx_rollup_rejection__case__0__case__131__case__131_elt_field1:
    seq:
    - id: case__131_elt_field1_tag
      type: u1
      enum: case__131_elt_field1_tag
    - id: tx_rollup_rejection__case__0__case__131__case__0__case__131_elt_field1
      size: 32
      if: (case__131_elt_field1_tag == case__131_elt_field1_tag::case__0)
    - id: tx_rollup_rejection__case__0__case__131__case__1__case__131_elt_field1
      size: 32
      if: (case__131_elt_field1_tag == case__131_elt_field1_tag::case__1)
  tx_rollup_rejection__case__0__case__131__case__131_elt_field0:
    seq:
    - id: len_case__131_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__131_elt_field0
      size: len_case__131_elt_field0
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__0__case__130__case__130_entries:
    seq:
    - id: tx_rollup_rejection__case__0__case__130__case__130_elt_field0
      type: tx_rollup_rejection__case__0__case__130__case__130_elt_field0
    - id: tx_rollup_rejection__case__0__case__130__case__130_elt_field1
      type: tx_rollup_rejection__case__0__case__130__case__130_elt_field1
  tx_rollup_rejection__case__0__case__130__case__130_elt_field1:
    seq:
    - id: case__130_elt_field1_tag
      type: u1
      enum: case__130_elt_field1_tag
    - id: tx_rollup_rejection__case__0__case__130__case__0__case__130_elt_field1
      size: 32
      if: (case__130_elt_field1_tag == case__130_elt_field1_tag::case__0)
    - id: tx_rollup_rejection__case__0__case__130__case__1__case__130_elt_field1
      size: 32
      if: (case__130_elt_field1_tag == case__130_elt_field1_tag::case__1)
  tx_rollup_rejection__case__0__case__130__case__130_elt_field0:
    seq:
    - id: len_case__130_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__130_elt_field0
      size: len_case__130_elt_field0
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__0__case__129__case__129_entries:
    seq:
    - id: tx_rollup_rejection__case__0__case__129__case__129_elt_field0
      type: tx_rollup_rejection__case__0__case__129__case__129_elt_field0
    - id: tx_rollup_rejection__case__0__case__129__case__129_elt_field1
      type: tx_rollup_rejection__case__0__case__129__case__129_elt_field1
  tx_rollup_rejection__case__0__case__129__case__129_elt_field1:
    seq:
    - id: case__129_elt_field1_tag
      type: u1
      enum: case__129_elt_field1_tag
    - id: tx_rollup_rejection__case__0__case__129__case__0__case__129_elt_field1
      size: 32
      if: (case__129_elt_field1_tag == case__129_elt_field1_tag::case__0)
    - id: tx_rollup_rejection__case__0__case__129__case__1__case__129_elt_field1
      size: 32
      if: (case__129_elt_field1_tag == case__129_elt_field1_tag::case__1)
  tx_rollup_rejection__case__0__case__129__case__129_elt_field0:
    seq:
    - id: len_case__129_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__129_elt_field0
      size: len_case__129_elt_field0
      size-eos: true
      valid:
        max: 255
  tx_rollup_rejection__case__0__case__15__case__0_field3_elt:
    seq:
    - id: case__15_field0
      type: s8
    - id: tx_rollup_rejection__case__0__case__15__case__15_field1
      type: tx_rollup_rejection__case__0__case__15__case__15_field1
  tx_rollup_rejection__case__0__case__15__case__15_field1:
    seq:
    - id: case__15_field1_field0
      size: 32
      doc: context_hash
    - id: case__15_field1_field1
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__0__case__7__case__0_field3_elt:
    seq:
    - id: case__7_field0
      type: s8
    - id: case__7_field1
      size: 32
      doc: ! 'context_hash


        case__7_field1_field0'
  tx_rollup_rejection__case__0__case__11__case__0_field3_elt:
    seq:
    - id: case__11_field0
      type: s8
    - id: case__11_field1
      size: 32
      doc: ! 'context_hash


        case__11_field1_field1'
  tx_rollup_rejection__case__0__case__14__case__0_field3_elt:
    seq:
    - id: case__14_field0
      type: s4
    - id: tx_rollup_rejection__case__0__case__14__case__14_field1
      type: tx_rollup_rejection__case__0__case__14__case__14_field1
  tx_rollup_rejection__case__0__case__14__case__14_field1:
    seq:
    - id: case__14_field1_field0
      size: 32
      doc: context_hash
    - id: case__14_field1_field1
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__0__case__6__case__0_field3_elt:
    seq:
    - id: case__6_field0
      type: s4
    - id: case__6_field1
      size: 32
      doc: ! 'context_hash


        case__6_field1_field0'
  tx_rollup_rejection__case__0__case__10__case__0_field3_elt:
    seq:
    - id: case__10_field0
      type: s4
    - id: case__10_field1
      size: 32
      doc: ! 'context_hash


        case__10_field1_field1'
  tx_rollup_rejection__case__0__case__13__case__0_field3_elt:
    seq:
    - id: case__13_field0
      type: u2
    - id: tx_rollup_rejection__case__0__case__13__case__13_field1
      type: tx_rollup_rejection__case__0__case__13__case__13_field1
  tx_rollup_rejection__case__0__case__13__case__13_field1:
    seq:
    - id: case__13_field1_field0
      size: 32
      doc: context_hash
    - id: case__13_field1_field1
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__0__case__5__case__0_field3_elt:
    seq:
    - id: case__5_field0
      type: u2
    - id: case__5_field1
      size: 32
      doc: ! 'context_hash


        case__5_field1_field0'
  tx_rollup_rejection__case__0__case__9__case__0_field3_elt:
    seq:
    - id: case__9_field0
      type: u2
    - id: case__9_field1
      size: 32
      doc: ! 'context_hash


        case__9_field1_field1'
  tx_rollup_rejection__case__0__case__12__case__0_field3_elt:
    seq:
    - id: case__12_field0
      type: u1
    - id: tx_rollup_rejection__case__0__case__12__case__12_field1
      type: tx_rollup_rejection__case__0__case__12__case__12_field1
  tx_rollup_rejection__case__0__case__12__case__12_field1:
    seq:
    - id: case__12_field1_field0
      size: 32
      doc: context_hash
    - id: case__12_field1_field1
      size: 32
      doc: context_hash
  tx_rollup_rejection__case__0__case__4__case__0_field3_elt:
    seq:
    - id: case__4_field0
      type: u1
    - id: case__4_field1
      size: 32
      doc: ! 'context_hash


        case__4_field1_field0'
  tx_rollup_rejection__case__0__case__8__case__0_field3_elt:
    seq:
    - id: case__8_field0
      type: u1
    - id: case__8_field1
      size: 32
      doc: ! 'context_hash


        case__8_field1_field1'
  tx_rollup_rejection__previous_message_result_path:
    seq:
    - id: len_previous_message_result_path
      type: u4
      valid:
        max: 1073741823
    - id: previous_message_result_path
      type: tx_rollup_rejection__previous_message_result_path_entries
      size: len_previous_message_result_path
      repeat: eos
  tx_rollup_rejection__previous_message_result_path_entries:
    seq:
    - id: message_result_list_hash
      size: 32
  tx_rollup_rejection__previous_message_result:
    seq:
    - id: context_hash
      size: 32
    - id: withdraw_list_hash
      size: 32
  tx_rollup_rejection__message_result_path:
    seq:
    - id: len_message_result_path
      type: u4
      valid:
        max: 1073741823
    - id: message_result_path
      type: tx_rollup_rejection__message_result_path_entries
      size: len_message_result_path
      repeat: eos
  tx_rollup_rejection__message_result_path_entries:
    seq:
    - id: message_result_list_hash
      size: 32
  tx_rollup_rejection__message_path:
    seq:
    - id: len_message_path
      type: u4
      valid:
        max: 1073741823
    - id: message_path
      type: tx_rollup_rejection__message_path_entries
      size: len_message_path
      repeat: eos
  tx_rollup_rejection__message_path_entries:
    seq:
    - id: inbox_list_hash
      size: 32
  tx_rollup_rejection__message:
    seq:
    - id: message_tag
      type: u1
      enum: message_tag
    - id: tx_rollup_rejection__batch__message
      type: tx_rollup_rejection__batch__batch
      if: (message_tag == message_tag::batch)
    - id: tx_rollup_rejection__deposit__message
      type: tx_rollup_rejection__deposit__deposit
      if: (message_tag == message_tag::deposit)
  tx_rollup_rejection__deposit__deposit:
    seq:
    - id: sender
      type: tx_rollup_rejection__deposit__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: destination
      size: 20
    - id: ticket_hash
      size: 32
    - id: tx_rollup_rejection__deposit__amount
      type: tx_rollup_rejection__deposit__amount
  tx_rollup_rejection__deposit__amount:
    seq:
    - id: amount_tag
      type: u1
      enum: amount_tag
    - id: tx_rollup_rejection__deposit__case__0__amount
      type: u1
      if: (amount_tag == amount_tag::case__0)
    - id: tx_rollup_rejection__deposit__case__1__amount
      type: u2
      if: (amount_tag == amount_tag::case__1)
    - id: tx_rollup_rejection__deposit__case__2__amount
      type: s4
      if: (amount_tag == amount_tag::case__2)
    - id: tx_rollup_rejection__deposit__case__3__amount
      type: s8
      if: (amount_tag == amount_tag::case__3)
  tx_rollup_rejection__deposit__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: tx_rollup_rejection__deposit__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: tx_rollup_rejection__deposit__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: tx_rollup_rejection__deposit__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  tx_rollup_rejection__batch__batch:
    seq:
    - id: len_batch
      type: u4
      valid:
        max: 1073741823
    - id: batch
      size: len_batch
  tx_rollup_rejection__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: tx_rollup_rejection__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: tx_rollup_rejection__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: tx_rollup_rejection__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  tx_rollup_remove_commitment__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: source
      type: tx_rollup_remove_commitment__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: rollup
      size: 20
      doc: ! >-
        A tx rollup handle: A tx rollup notation as given to an RPC or inside scripts,
        is a base58 tx rollup hash
  tx_rollup_remove_commitment__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: tx_rollup_remove_commitment__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: tx_rollup_remove_commitment__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: tx_rollup_remove_commitment__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  tx_rollup_finalize_commitment__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: source
      type: tx_rollup_finalize_commitment__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: rollup
      size: 20
      doc: ! >-
        A tx rollup handle: A tx rollup notation as given to an RPC or inside scripts,
        is a base58 tx rollup hash
  tx_rollup_finalize_commitment__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: tx_rollup_finalize_commitment__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: tx_rollup_finalize_commitment__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: tx_rollup_finalize_commitment__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  tx_rollup_return_bond__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: source
      type: tx_rollup_return_bond__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: rollup
      size: 20
      doc: ! >-
        A tx rollup handle: A tx rollup notation as given to an RPC or inside scripts,
        is a base58 tx rollup hash
  tx_rollup_return_bond__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: tx_rollup_return_bond__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: tx_rollup_return_bond__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: tx_rollup_return_bond__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  tx_rollup_commit__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: source
      type: tx_rollup_commit__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: rollup
      size: 20
      doc: ! >-
        A tx rollup handle: A tx rollup notation as given to an RPC or inside scripts,
        is a base58 tx rollup hash
    - id: tx_rollup_commit__commitment
      type: tx_rollup_commit__commitment
  tx_rollup_commit__commitment:
    seq:
    - id: level
      type: s4
    - id: tx_rollup_commit__messages
      type: tx_rollup_commit__messages
    - id: tx_rollup_commit__predecessor
      type: tx_rollup_commit__predecessor
    - id: inbox_merkle_root
      size: 32
  tx_rollup_commit__predecessor:
    seq:
    - id: predecessor_tag
      type: u1
      enum: predecessor_tag
    - id: tx_rollup_commit__some__predecessor
      size: 32
      if: (predecessor_tag == predecessor_tag::some)
  tx_rollup_commit__messages:
    seq:
    - id: len_messages
      type: u4
      valid:
        max: 1073741823
    - id: messages
      type: tx_rollup_commit__messages_entries
      size: len_messages
      repeat: eos
  tx_rollup_commit__messages_entries:
    seq:
    - id: message_result_hash
      size: 32
  tx_rollup_commit__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: tx_rollup_commit__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: tx_rollup_commit__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: tx_rollup_commit__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  tx_rollup_submit_batch__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: source
      type: tx_rollup_submit_batch__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: rollup
      size: 20
      doc: ! >-
        A tx rollup handle: A tx rollup notation as given to an RPC or inside scripts,
        is a base58 tx rollup hash
    - id: tx_rollup_submit_batch__content
      type: tx_rollup_submit_batch__content
    - id: burn_limit_tag
      type: u1
      enum: bool
    - id: burn_limit
      type: n
      if: (burn_limit_tag == bool::true)
  tx_rollup_submit_batch__content:
    seq:
    - id: len_content
      type: u4
      valid:
        max: 1073741823
    - id: content
      size: len_content
  tx_rollup_submit_batch__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: tx_rollup_submit_batch__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: tx_rollup_submit_batch__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: tx_rollup_submit_batch__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  tx_rollup_origination__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: source
      type: tx_rollup_origination__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
  tx_rollup_origination__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: tx_rollup_origination__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: tx_rollup_origination__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: tx_rollup_origination__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  register_global_constant__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: source
      type: register_global_constant__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: register_global_constant__value
      type: register_global_constant__value
  register_global_constant__value:
    seq:
    - id: len_value
      type: u4
      valid:
        max: 1073741823
    - id: value
      size: len_value
  register_global_constant__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: register_global_constant__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: register_global_constant__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: register_global_constant__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  failing_noop__arbitrary:
    seq:
    - id: len_arbitrary
      type: u4
      valid:
        max: 1073741823
    - id: arbitrary
      size: len_arbitrary
  set_deposits_limit__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: source
      type: set_deposits_limit__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: n
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
      type: n
      if: (limit_tag == bool::true)
  set_deposits_limit__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: set_deposits_limit__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: set_deposits_limit__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: set_deposits_limit__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  delegation__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: source
      type: delegation__public_key_hash
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
      type: delegation__public_key_hash
      if: (delegate_tag == bool::true)
      doc: A Ed25519, Secp256k1, or P256 public key hash
  delegation__public_key_hash:
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
  origination__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: source
      type: origination__public_key_hash
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
      type: origination__public_key_hash
      if: (delegate_tag == bool::true)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: script
      type: origination__id_013__ptjakart__scripted__contracts
  origination__id_013__ptjakart__scripted__contracts:
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
  origination__public_key_hash:
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
  transaction__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: source
      type: transaction__public_key_hash
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
      type: transaction__id_013__ptjakart__transaction_destination
      doc: ! >-
        A destination of a transaction: A destination notation compatible with the
        contract notation as given to an RPC or inside scripts. Can be a base58 implicit
        contract hash, a base58 originated contract hash, or a base58 originated transaction
        rollup.
    - id: parameters_tag
      type: u1
      enum: bool
    - id: transaction__parameters
      type: transaction__parameters
      if: (parameters_tag == bool::true)
  transaction__parameters:
    seq:
    - id: entrypoint
      type: transaction__id_013__ptjakart__entrypoint
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
  transaction__id_013__ptjakart__entrypoint:
    seq:
    - id: id_013__ptjakart__entrypoint_tag
      type: u1
      enum: id_013__ptjakart__entrypoint_tag
    - id: transaction__named__id_013__ptjakart__entrypoint
      type: transaction__named__id_013__ptjakart__entrypoint
      if: (id_013__ptjakart__entrypoint_tag == id_013__ptjakart__entrypoint_tag::named)
  transaction__named__id_013__ptjakart__entrypoint:
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
  transaction__id_013__ptjakart__transaction_destination:
    seq:
    - id: id_013__ptjakart__transaction_destination_tag
      type: u1
      enum: id_013__ptjakart__transaction_destination_tag
    - id: transaction__implicit__id_013__ptjakart__transaction_destination
      type: transaction__implicit__public_key_hash
      if: (id_013__ptjakart__transaction_destination_tag == id_013__ptjakart__transaction_destination_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: transaction__originated__id_013__ptjakart__transaction_destination
      type: transaction__originated__id_013__ptjakart__transaction_destination
      if: (id_013__ptjakart__transaction_destination_tag == id_013__ptjakart__transaction_destination_tag::originated)
    - id: transaction__tx_rollup__id_013__ptjakart__transaction_destination
      type: transaction__tx_rollup__id_013__ptjakart__transaction_destination
      if: (id_013__ptjakart__transaction_destination_tag == id_013__ptjakart__transaction_destination_tag::tx_rollup)
  transaction__tx_rollup__id_013__ptjakart__transaction_destination:
    seq:
    - id: id_013__ptjakart__tx_rollup_id
      size: 20
      doc: ! >-
        A tx rollup handle: A tx rollup notation as given to an RPC or inside scripts,
        is a base58 tx rollup hash
    - id: tx_rollup_padding
      size: 1
      doc: This field is for padding, ignore
  transaction__originated__id_013__ptjakart__transaction_destination:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  transaction__implicit__public_key_hash:
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
  transaction__public_key_hash:
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
  reveal__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: source
      type: reveal__public_key_hash
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
      type: reveal__public_key
      doc: A Ed25519, Secp256k1, or P256 public key
  reveal__public_key:
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
  reveal__public_key_hash:
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
  ballot__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: source
      type: ballot__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: period
      type: s4
    - id: proposal
      size: 32
    - id: ballot
      type: s1
  ballot__public_key_hash:
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
  proposals__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: source
      type: proposals__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: period
      type: s4
    - id: proposals__proposals
      type: proposals__proposals
  proposals__proposals:
    seq:
    - id: len_proposals
      type: u4
      valid:
        max: 1073741823
    - id: proposals
      type: proposals__proposals_entries
      size: len_proposals
      repeat: eos
  proposals__proposals_entries:
    seq:
    - id: protocol_hash
      size: 32
  proposals__public_key_hash:
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
  activate_account__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: pkh
      size: 20
    - id: secret
      size: 20
  double_baking_evidence__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: double_baking_evidence__bh1
      type: double_baking_evidence__bh1
    - id: double_baking_evidence__bh2
      type: double_baking_evidence__bh2
  double_baking_evidence__bh2:
    seq:
    - id: len_bh2
      type: u4
      valid:
        max: 1073741823
    - id: bh2
      type: double_baking_evidence__id_013__ptjakart__block_header__alpha__full_header
      size: len_bh2
  double_baking_evidence__bh1:
    seq:
    - id: len_bh1
      type: u4
      valid:
        max: 1073741823
    - id: bh1
      type: double_baking_evidence__id_013__ptjakart__block_header__alpha__full_header
      size: len_bh1
  double_baking_evidence__id_013__ptjakart__block_header__alpha__full_header:
    seq:
    - id: double_baking_evidence__block_header__shell
      type: double_baking_evidence__block_header__shell
      doc: ! >-
        Shell header: Block header's shell-related content. It contains information
        such as the block level, its predecessor and timestamp.
    - id: double_baking_evidence__id_013__ptjakart__block_header__alpha__signed_contents
      type: double_baking_evidence__id_013__ptjakart__block_header__alpha__signed_contents
  double_baking_evidence__id_013__ptjakart__block_header__alpha__signed_contents:
    seq:
    - id: double_baking_evidence__id_013__ptjakart__block_header__alpha__unsigned_contents
      type: double_baking_evidence__id_013__ptjakart__block_header__alpha__unsigned_contents
    - id: signature
      size: 64
  double_baking_evidence__id_013__ptjakart__block_header__alpha__unsigned_contents:
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
    - id: liquidity_baking_toggle_vote
      type: s1
  double_baking_evidence__block_header__shell:
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
      type: double_baking_evidence__fitness
      doc: ! >-
        Block fitness: The fitness, or score, of a block, that allow the Tezos to
        decide which chain is the best. A fitness value is a list of byte sequences.
        They are compared as follows: shortest lists are smaller; lists of the same
        length are compared according to the lexicographical order.
    - id: context
      size: 32
  double_baking_evidence__fitness:
    seq:
    - id: len_fitness
      type: u4
      valid:
        max: 1073741823
    - id: fitness
      type: double_baking_evidence__fitness_entries
      size: len_fitness
      repeat: eos
  double_baking_evidence__fitness_entries:
    seq:
    - id: double_baking_evidence__fitness__elem
      type: double_baking_evidence__fitness__elem
  double_baking_evidence__fitness__elem:
    seq:
    - id: len_fitness__elem
      type: u4
      valid:
        max: 1073741823
    - id: fitness__elem
      size: len_fitness__elem
  double_preendorsement_evidence__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: double_preendorsement_evidence__op1
      type: double_preendorsement_evidence__op1
    - id: double_preendorsement_evidence__op2
      type: double_preendorsement_evidence__op2
  double_preendorsement_evidence__op2:
    seq:
    - id: len_op2
      type: u4
      valid:
        max: 1073741823
    - id: op2
      type: double_preendorsement_evidence__id_013__ptjakart__inlined__preendorsement
      size: len_op2
  double_preendorsement_evidence__op1:
    seq:
    - id: len_op1
      type: u4
      valid:
        max: 1073741823
    - id: op1
      type: double_preendorsement_evidence__id_013__ptjakart__inlined__preendorsement
      size: len_op1
  double_preendorsement_evidence__id_013__ptjakart__inlined__preendorsement:
    seq:
    - id: operation__shell_header
      size: 32
      doc: An operation's shell header.
    - id: operations
      type: double_preendorsement_evidence__id_013__ptjakart__inlined__preendorsement__contents
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size: 64
      if: (signature_tag == bool::true)
  double_preendorsement_evidence__id_013__ptjakart__inlined__preendorsement__contents:
    seq:
    - id: id_013__ptjakart__inlined__preendorsement__contents_tag
      type: u1
      enum: id_013__ptjakart__inlined__preendorsement__contents_tag
    - id: double_preendorsement_evidence__preendorsement__id_013__ptjakart__inlined__preendorsement__contents
      type: double_preendorsement_evidence__preendorsement__id_013__ptjakart__inlined__preendorsement__contents
      if: (id_013__ptjakart__inlined__preendorsement__contents_tag == id_013__ptjakart__inlined__preendorsement__contents_tag::preendorsement)
  double_preendorsement_evidence__preendorsement__id_013__ptjakart__inlined__preendorsement__contents:
    seq:
    - id: slot
      type: u2
    - id: level
      type: s4
    - id: round
      type: s4
    - id: block_payload_hash
      size: 32
  double_endorsement_evidence__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: double_endorsement_evidence__op1
      type: double_endorsement_evidence__op1
    - id: double_endorsement_evidence__op2
      type: double_endorsement_evidence__op2
  double_endorsement_evidence__op2:
    seq:
    - id: len_op2
      type: u4
      valid:
        max: 1073741823
    - id: op2
      type: double_endorsement_evidence__id_013__ptjakart__inlined__endorsement
      size: len_op2
  double_endorsement_evidence__op1:
    seq:
    - id: len_op1
      type: u4
      valid:
        max: 1073741823
    - id: op1
      type: double_endorsement_evidence__id_013__ptjakart__inlined__endorsement
      size: len_op1
  double_endorsement_evidence__id_013__ptjakart__inlined__endorsement:
    seq:
    - id: operation__shell_header
      size: 32
      doc: An operation's shell header.
    - id: operations
      type: double_endorsement_evidence__id_013__ptjakart__inlined__endorsement_mempool__contents
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size: 64
      if: (signature_tag == bool::true)
  double_endorsement_evidence__id_013__ptjakart__inlined__endorsement_mempool__contents:
    seq:
    - id: id_013__ptjakart__inlined__endorsement_mempool__contents_tag
      type: u1
      enum: id_013__ptjakart__inlined__endorsement_mempool__contents_tag
    - id: double_endorsement_evidence__endorsement__id_013__ptjakart__inlined__endorsement_mempool__contents
      type: double_endorsement_evidence__endorsement__id_013__ptjakart__inlined__endorsement_mempool__contents
      if: (id_013__ptjakart__inlined__endorsement_mempool__contents_tag == id_013__ptjakart__inlined__endorsement_mempool__contents_tag::endorsement)
  double_endorsement_evidence__endorsement__id_013__ptjakart__inlined__endorsement_mempool__contents:
    seq:
    - id: slot
      type: u2
    - id: level
      type: s4
    - id: round
      type: s4
    - id: block_payload_hash
      size: 32
  seed_nonce_revelation__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: level
      type: s4
    - id: nonce
      size: 32
  preendorsement__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: slot
      type: u2
    - id: level
      type: s4
    - id: round
      type: s4
    - id: block_payload_hash
      size: 32
  endorsement__id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: slot
      type: u2
    - id: level
      type: s4
    - id: round
      type: s4
    - id: block_payload_hash
      size: 32
enums:
  kind_tag:
    0: example_arith__smart__contract__rollup__kind
  id_013__ptjakart__contract_id_tag:
    0: implicit
    1: originated
  case__3_field3_elt_tag:
    0: case__0
    1: case__1
    2: case__2
    3: case__3
    4: case__4
    5: case__5
    6: case__6
    7: case__7
    8: case__8
    9: case__9
    10: case__10
    11: case__11
    12: case__12
    13: case__13
    14: case__14
    15: case__15
    128: case__128
    129: case__129
    130: case__130
    131: case__131
    192: case__192
    193: case__193
    195: case__195
    224: case__224
    225: case__225
    226: case__226
    227: case__227
  case__1_field3_elt_tag:
    0: case__0
    1: case__1
    2: case__2
    3: case__3
    4: case__4
    5: case__5
    6: case__6
    7: case__7
    8: case__8
    9: case__9
    10: case__10
    11: case__11
    12: case__12
    13: case__13
    14: case__14
    15: case__15
    128: case__128
    129: case__129
    130: case__130
    131: case__131
    192: case__192
    193: case__193
    195: case__195
    224: case__224
    225: case__225
    226: case__226
    227: case__227
  case__2_field3_elt_tag:
    0: case__0
    1: case__1
    2: case__2
    3: case__3
    4: case__4
    5: case__5
    6: case__6
    7: case__7
    8: case__8
    9: case__9
    10: case__10
    11: case__11
    12: case__12
    13: case__13
    14: case__14
    15: case__15
    128: case__128
    129: case__129
    130: case__130
    131: case__131
    192: case__192
    193: case__193
    195: case__195
    224: case__224
    225: case__225
    226: case__226
    227: case__227
  case__131_elt_field1_tag:
    0: case__0
    1: case__1
  case__130_elt_field1_tag:
    0: case__0
    1: case__1
  case__129_elt_field1_tag:
    0: case__0
    1: case__1
  case__0_field3_elt_tag:
    0: case__0
    1: case__1
    2: case__2
    3: case__3
    4: case__4
    5: case__5
    6: case__6
    7: case__7
    8: case__8
    9: case__9
    10: case__10
    11: case__11
    12: case__12
    13: case__13
    14: case__14
    15: case__15
    128: case__128
    129: case__129
    130: case__130
    131: case__131
    192: case__192
    193: case__193
    195: case__195
    224: case__224
    225: case__225
    226: case__226
    227: case__227
  proof_tag:
    0: case__0
    1: case__1
    2: case__2
    3: case__3
  amount_tag:
    0: case__0
    1: case__1
    2: case__2
    3: case__3
  message_tag:
    0: batch
    1: deposit
  predecessor_tag:
    0: none
    1: some
  id_013__ptjakart__entrypoint_tag:
    0: default
    1: root
    2: do
    3: set_delegate
    4: remove_delegate
    255: named
  id_013__ptjakart__transaction_destination_tag:
    0: implicit
    1: originated
    2: tx_rollup
  public_key_tag:
    0: ed25519
    1: secp256k1
    2: p256
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
  id_013__ptjakart__inlined__preendorsement__contents_tag:
    20: preendorsement
  bool:
    0: false
    255: true
  id_013__ptjakart__inlined__endorsement_mempool__contents_tag:
    21: endorsement
  id_013__ptjakart__operation__alpha__contents_tag:
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
    150: tx_rollup_origination
    151: tx_rollup_submit_batch
    152: tx_rollup_commit
    153: tx_rollup_return_bond
    154: tx_rollup_finalize_commitment
    155: tx_rollup_remove_commitment
    156: tx_rollup_rejection
    157: tx_rollup_dispatch_tickets
    158: transfer_ticket
    200: sc_rollup_originate
    201: sc_rollup_add_messages
    202: sc_rollup_cement
    203: sc_rollup_publish
seq:
- id: id_013__ptjakart__operation__alpha__contents_and_signature
  type: id_013__ptjakart__operation__alpha__contents_and_signature
