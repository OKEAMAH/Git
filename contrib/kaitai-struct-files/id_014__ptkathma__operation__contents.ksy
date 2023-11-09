meta:
  id: id_014__ptkathma__operation__contents
  endian: be
  imports:
  - block_header__shell
  - operation__shell_header
doc: ! 'Encoding id: 014-PtKathma.operation.contents'
types:
  id_014__ptkathma__operation__alpha__contents_:
    seq:
    - id: id_014__ptkathma__operation__alpha__contents_tag
      type: u1
      enum: id_014__ptkathma__operation__alpha__contents_tag
    - id: endorsement__id_014__ptkathma__operation__alpha__contents
      type: endorsement__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::endorsement)
    - id: preendorsement__id_014__ptkathma__operation__alpha__contents
      type: preendorsement__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::preendorsement)
    - id: dal_slot_availability__id_014__ptkathma__operation__alpha__contents
      type: dal_slot_availability__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::dal_slot_availability)
    - id: seed_nonce_revelation__id_014__ptkathma__operation__alpha__contents
      type: seed_nonce_revelation__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::seed_nonce_revelation)
    - id: vdf_revelation__id_014__ptkathma__operation__alpha__contents
      type: vdf_revelation__solution
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::vdf_revelation)
    - id: double_endorsement_evidence__id_014__ptkathma__operation__alpha__contents
      type: double_endorsement_evidence__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::double_endorsement_evidence)
    - id: double_preendorsement_evidence__id_014__ptkathma__operation__alpha__contents
      type: double_preendorsement_evidence__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::double_preendorsement_evidence)
    - id: double_baking_evidence__id_014__ptkathma__operation__alpha__contents
      type: double_baking_evidence__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::double_baking_evidence)
    - id: activate_account__id_014__ptkathma__operation__alpha__contents
      type: activate_account__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::activate_account)
    - id: proposals__id_014__ptkathma__operation__alpha__contents
      type: proposals__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::proposals)
    - id: ballot__id_014__ptkathma__operation__alpha__contents
      type: ballot__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::ballot)
    - id: reveal__id_014__ptkathma__operation__alpha__contents
      type: reveal__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::reveal)
    - id: transaction__id_014__ptkathma__operation__alpha__contents
      type: transaction__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::transaction)
    - id: origination__id_014__ptkathma__operation__alpha__contents
      type: origination__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::origination)
    - id: delegation__id_014__ptkathma__operation__alpha__contents
      type: delegation__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::delegation)
    - id: set_deposits_limit__id_014__ptkathma__operation__alpha__contents
      type: set_deposits_limit__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::set_deposits_limit)
    - id: increase_paid_storage__id_014__ptkathma__operation__alpha__contents
      type: increase_paid_storage__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::increase_paid_storage)
    - id: failing_noop__id_014__ptkathma__operation__alpha__contents
      type: bytes_dyn_uint30
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::failing_noop)
    - id: register_global_constant__id_014__ptkathma__operation__alpha__contents
      type: register_global_constant__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::register_global_constant)
    - id: tx_rollup_origination__id_014__ptkathma__operation__alpha__contents
      type: tx_rollup_origination__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::tx_rollup_origination)
    - id: tx_rollup_submit_batch__id_014__ptkathma__operation__alpha__contents
      type: tx_rollup_submit_batch__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::tx_rollup_submit_batch)
    - id: tx_rollup_commit__id_014__ptkathma__operation__alpha__contents
      type: tx_rollup_commit__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::tx_rollup_commit)
    - id: tx_rollup_return_bond__id_014__ptkathma__operation__alpha__contents
      type: tx_rollup_return_bond__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::tx_rollup_return_bond)
    - id: tx_rollup_finalize_commitment__id_014__ptkathma__operation__alpha__contents
      type: tx_rollup_finalize_commitment__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::tx_rollup_finalize_commitment)
    - id: tx_rollup_remove_commitment__id_014__ptkathma__operation__alpha__contents
      type: tx_rollup_remove_commitment__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::tx_rollup_remove_commitment)
    - id: tx_rollup_rejection__id_014__ptkathma__operation__alpha__contents
      type: tx_rollup_rejection__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::tx_rollup_rejection)
    - id: tx_rollup_dispatch_tickets__id_014__ptkathma__operation__alpha__contents
      type: tx_rollup_dispatch_tickets__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::tx_rollup_dispatch_tickets)
    - id: transfer_ticket__id_014__ptkathma__operation__alpha__contents
      type: transfer_ticket__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::transfer_ticket)
    - id: dal_publish_slot_header__id_014__ptkathma__operation__alpha__contents
      type: dal_publish_slot_header__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::dal_publish_slot_header)
    - id: sc_rollup_originate__id_014__ptkathma__operation__alpha__contents
      type: sc_rollup_originate__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::sc_rollup_originate)
    - id: sc_rollup_add_messages__id_014__ptkathma__operation__alpha__contents
      type: sc_rollup_add_messages__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::sc_rollup_add_messages)
    - id: sc_rollup_cement__id_014__ptkathma__operation__alpha__contents
      type: sc_rollup_cement__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::sc_rollup_cement)
    - id: sc_rollup_publish__id_014__ptkathma__operation__alpha__contents
      type: sc_rollup_publish__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::sc_rollup_publish)
    - id: sc_rollup_refute__id_014__ptkathma__operation__alpha__contents
      type: sc_rollup_refute__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::sc_rollup_refute)
    - id: sc_rollup_timeout__id_014__ptkathma__operation__alpha__contents
      type: sc_rollup_timeout__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::sc_rollup_timeout)
    - id: sc_rollup_execute_outbox_message__id_014__ptkathma__operation__alpha__contents
      type: sc_rollup_execute_outbox_message__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::sc_rollup_execute_outbox_message)
    - id: sc_rollup_recover_bond__id_014__ptkathma__operation__alpha__contents
      type: sc_rollup_recover_bond__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::sc_rollup_recover_bond)
    - id: sc_rollup_dal_slot_subscribe__id_014__ptkathma__operation__alpha__contents
      type: sc_rollup_dal_slot_subscribe__id_014__ptkathma__operation__alpha__contents
      if: (id_014__ptkathma__operation__alpha__contents_tag == id_014__ptkathma__operation__alpha__contents_tag::sc_rollup_dal_slot_subscribe)
  sc_rollup_dal_slot_subscribe__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: source
      type: sc_rollup_dal_slot_subscribe__public_key_hash_
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
      type: bytes_dyn_uint30
      doc: ! >-
        A smart contract rollup address: A smart contract rollup is identified by
        a base58 address starting with scr1
    - id: slot_index
      type: u1
  sc_rollup_dal_slot_subscribe__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: sc_rollup_dal_slot_subscribe__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: sc_rollup_dal_slot_subscribe__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: sc_rollup_dal_slot_subscribe__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  sc_rollup_recover_bond__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: source
      type: sc_rollup_recover_bond__public_key_hash_
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
  sc_rollup_recover_bond__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: sc_rollup_recover_bond__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: sc_rollup_recover_bond__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: sc_rollup_recover_bond__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  sc_rollup_execute_outbox_message__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: source
      type: sc_rollup_execute_outbox_message__public_key_hash_
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
      type: bytes_dyn_uint30
      doc: ! >-
        A smart contract rollup address: A smart contract rollup is identified by
        a base58 address starting with scr1
    - id: cemented_commitment
      size: 32
    - id: outbox_level
      type: s4
    - id: message_index
      type: int31
    - id: inclusion__proof
      type: bytes_dyn_uint30
    - id: message
      type: bytes_dyn_uint30
  sc_rollup_execute_outbox_message__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: sc_rollup_execute_outbox_message__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: sc_rollup_execute_outbox_message__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: sc_rollup_execute_outbox_message__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  sc_rollup_timeout__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: source
      type: sc_rollup_timeout__public_key_hash_
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
      type: bytes_dyn_uint30
      doc: ! >-
        A smart contract rollup address: A smart contract rollup is identified by
        a base58 address starting with scr1
    - id: sc_rollup_timeout__stakers
      type: sc_rollup_timeout__stakers
  sc_rollup_timeout__stakers:
    seq:
    - id: alice
      type: sc_rollup_timeout__public_key_hash_
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: bob
      type: sc_rollup_timeout__public_key_hash_
      doc: A Ed25519, Secp256k1, or P256 public key hash
  sc_rollup_timeout__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: sc_rollup_timeout__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: sc_rollup_timeout__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: sc_rollup_timeout__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  sc_rollup_refute__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: source
      type: sc_rollup_refute__public_key_hash_
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
      type: bytes_dyn_uint30
      doc: ! >-
        A smart contract rollup address: A smart contract rollup is identified by
        a base58 address starting with scr1
    - id: opponent
      type: sc_rollup_refute__public_key_hash_
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: sc_rollup_refute__refutation
      type: sc_rollup_refute__refutation
    - id: is_opening_move
      type: u1
      enum: bool
  sc_rollup_refute__refutation:
    seq:
    - id: choice
      type: n
    - id: sc_rollup_refute__step
      type: sc_rollup_refute__step
  sc_rollup_refute__step:
    seq:
    - id: step_tag
      type: u1
      enum: step_tag
    - id: sc_rollup_refute__dissection__step
      type: sc_rollup_refute__dissection__step
      if: (step_tag == step_tag::dissection)
    - id: sc_rollup_refute__proof__step
      type: sc_rollup_refute__proof__step
      if: (step_tag == step_tag::proof)
  sc_rollup_refute__proof__step:
    seq:
    - id: sc_rollup_refute__proof__pvm_step
      type: sc_rollup_refute__proof__pvm_step
    - id: sc_rollup_refute__proof__inbox
      type: sc_rollup_refute__proof__inbox
  sc_rollup_refute__proof__inbox:
    seq:
    - id: inbox_tag
      type: u1
      enum: inbox_tag
    - id: sc_rollup_refute__proof__some__inbox
      type: sc_rollup_refute__proof__some__inbox
      if: (inbox_tag == inbox_tag::some)
  sc_rollup_refute__proof__some__inbox:
    seq:
    - id: sc_rollup_refute__proof__some__skips
      type: sc_rollup_refute__proof__some__skips
    - id: sc_rollup_refute__proof__some__level
      type: sc_rollup_refute__proof__some__level
    - id: sc_rollup_refute__proof__some__inc
      type: sc_rollup_refute__proof__some__inc
    - id: sc_rollup_refute__proof__some__message_proof
      type: sc_rollup_refute__proof__some__message_proof
  sc_rollup_refute__proof__some__message_proof:
    seq:
    - id: version
      type: s2
    - id: sc_rollup_refute__proof__some__before
      type: sc_rollup_refute__proof__some__before
    - id: sc_rollup_refute__proof__some__after
      type: sc_rollup_refute__proof__some__after
    - id: state
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__tree_encoding
  sc_rollup_refute__proof__some__after:
    seq:
    - id: after_tag
      type: u1
      enum: after_tag
    - id: sc_rollup_refute__proof__some__value__after
      size: 32
      if: (after_tag == after_tag::value)
    - id: sc_rollup_refute__proof__some__node__after
      size: 32
      if: (after_tag == after_tag::node)
  sc_rollup_refute__proof__some__before:
    seq:
    - id: before_tag
      type: u1
      enum: before_tag
    - id: sc_rollup_refute__proof__some__value__before
      size: 32
      if: (before_tag == before_tag::value)
    - id: sc_rollup_refute__proof__some__node__before
      size: 32
      if: (before_tag == before_tag::node)
  sc_rollup_refute__proof__some__inc:
    seq:
    - id: len_sc_rollup_refute__proof__some__inc_dyn
      type: u4
      valid:
        max: 1073741823
    - id: sc_rollup_refute__proof__some__inc_dyn
      type: sc_rollup_refute__proof__some__inc_dyn
      size: len_sc_rollup_refute__proof__some__inc_dyn
  sc_rollup_refute__proof__some__inc_dyn:
    seq:
    - id: sc_rollup_refute__proof__some__inc_entries
      type: sc_rollup_refute__proof__some__inc_entries
      repeat: eos
  sc_rollup_refute__proof__some__inc_entries:
    seq:
    - id: index
      type: int31
    - id: content
      size: 32
    - id: sc_rollup_refute__proof__some__back_pointers
      type: sc_rollup_refute__proof__some__back_pointers
  sc_rollup_refute__proof__some__level:
    seq:
    - id: rollup
      type: bytes_dyn_uint30
      doc: ! >-
        A smart contract rollup address: A smart contract rollup is identified by
        a base58 address starting with scr1
    - id: message_counter
      type: n
    - id: nb_available_messages
      type: s8
    - id: nb_messages_in_commitment_period
      type: s8
    - id: starting_level_of_current_commitment_period
      type: s4
    - id: level
      type: s4
    - id: current_messages_hash
      size: 32
    - id: sc_rollup_refute__proof__some__old_levels_messages
      type: sc_rollup_refute__proof__some__old_levels_messages
  sc_rollup_refute__proof__some__skips:
    seq:
    - id: len_sc_rollup_refute__proof__some__skips_dyn
      type: u4
      valid:
        max: 1073741823
    - id: sc_rollup_refute__proof__some__skips_dyn
      type: sc_rollup_refute__proof__some__skips_dyn
      size: len_sc_rollup_refute__proof__some__skips_dyn
  sc_rollup_refute__proof__some__skips_dyn:
    seq:
    - id: sc_rollup_refute__proof__some__skips_entries
      type: sc_rollup_refute__proof__some__skips_entries
      repeat: eos
  sc_rollup_refute__proof__some__skips_entries:
    seq:
    - id: sc_rollup_refute__proof__some__skips_elt_field0
      type: sc_rollup_refute__proof__some__skips_elt_field0
    - id: sc_rollup_refute__proof__some__skips_elt_field1
      type: sc_rollup_refute__proof__some__skips_elt_field1
  sc_rollup_refute__proof__some__skips_elt_field1:
    seq:
    - id: len_sc_rollup_refute__proof__some__skips_elt_field1_dyn
      type: u4
      valid:
        max: 1073741823
    - id: sc_rollup_refute__proof__some__skips_elt_field1_dyn
      type: sc_rollup_refute__proof__some__skips_elt_field1_dyn
      size: len_sc_rollup_refute__proof__some__skips_elt_field1_dyn
  sc_rollup_refute__proof__some__skips_elt_field1_dyn:
    seq:
    - id: sc_rollup_refute__proof__some__skips_elt_field1_entries
      type: sc_rollup_refute__proof__some__skips_elt_field1_entries
      repeat: eos
  sc_rollup_refute__proof__some__skips_elt_field1_entries:
    seq:
    - id: index
      type: int31
    - id: content
      size: 32
    - id: sc_rollup_refute__proof__some__back_pointers
      type: sc_rollup_refute__proof__some__back_pointers
  sc_rollup_refute__proof__some__skips_elt_field0:
    seq:
    - id: rollup
      type: bytes_dyn_uint30
      doc: ! >-
        A smart contract rollup address: A smart contract rollup is identified by
        a base58 address starting with scr1
    - id: message_counter
      type: n
    - id: nb_available_messages
      type: s8
    - id: nb_messages_in_commitment_period
      type: s8
    - id: starting_level_of_current_commitment_period
      type: s4
    - id: level
      type: s4
    - id: current_messages_hash
      size: 32
    - id: sc_rollup_refute__proof__some__old_levels_messages
      type: sc_rollup_refute__proof__some__old_levels_messages
  sc_rollup_refute__proof__some__old_levels_messages:
    seq:
    - id: index
      type: int31
    - id: content
      size: 32
    - id: sc_rollup_refute__proof__some__back_pointers
      type: sc_rollup_refute__proof__some__back_pointers
  sc_rollup_refute__proof__some__back_pointers:
    seq:
    - id: len_sc_rollup_refute__proof__some__back_pointers_dyn
      type: u4
      valid:
        max: 1073741823
    - id: sc_rollup_refute__proof__some__back_pointers_dyn
      type: sc_rollup_refute__proof__some__back_pointers_dyn
      size: len_sc_rollup_refute__proof__some__back_pointers_dyn
  sc_rollup_refute__proof__some__back_pointers_dyn:
    seq:
    - id: sc_rollup_refute__proof__some__back_pointers_entries
      type: sc_rollup_refute__proof__some__back_pointers_entries
      repeat: eos
  sc_rollup_refute__proof__some__back_pointers_entries:
    seq:
    - id: inbox_hash
      size: 32
  sc_rollup_refute__proof__pvm_step:
    seq:
    - id: pvm_step_tag
      type: u1
      enum: pvm_step_tag
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__pvm_step
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__pvm_step
      if: (pvm_step_tag == pvm_step_tag::arithmetic__pvm__with__proof)
    - id: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__pvm_step
      type: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__pvm_step
      if: (pvm_step_tag == pvm_step_tag::wasm__2__0__0__pvm__with__proof)
  sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__pvm_step:
    seq:
    - id: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__tree_proof
      type: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__tree_proof
    - id: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__given
      type: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__given
    - id: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__requested
      type: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__requested
  sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__requested:
    seq:
    - id: requested_tag
      type: u1
      enum: requested_tag
    - id: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__first_after__requested
      type: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__first_after__requested
      if: (requested_tag == requested_tag::first_after)
  sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__first_after__requested:
    seq:
    - id: first_after_field0
      type: s4
    - id: first_after_field1
      type: n
  sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__given:
    seq:
    - id: given_tag
      type: u1
      enum: given_tag
    - id: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__some__given
      type: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__some__given
      if: (given_tag == given_tag::some)
  sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__some__given:
    seq:
    - id: inbox_level
      type: s4
    - id: message_counter
      type: n
    - id: payload
      type: bytes_dyn_uint30
  sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__tree_proof:
    seq:
    - id: version
      type: s2
    - id: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__before
      type: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__before
    - id: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__after
      type: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__after
    - id: state
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__tree_encoding
  sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__after:
    seq:
    - id: after_tag
      type: u1
      enum: after_tag
    - id: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__value__after
      size: 32
      if: (after_tag == after_tag::value)
    - id: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__node__after
      size: 32
      if: (after_tag == after_tag::node)
  sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__before:
    seq:
    - id: before_tag
      type: u1
      enum: before_tag
    - id: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__value__before
      size: 32
      if: (before_tag == before_tag::value)
    - id: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__node__before
      size: 32
      if: (before_tag == before_tag::node)
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__pvm_step:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__tree_proof
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__tree_proof
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__given
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__given
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__requested
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__requested
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__requested:
    seq:
    - id: requested_tag
      type: u1
      enum: requested_tag
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__first_after__requested
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__first_after__requested
      if: (requested_tag == requested_tag::first_after)
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__first_after__requested:
    seq:
    - id: first_after_field0
      type: s4
    - id: first_after_field1
      type: n
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__given:
    seq:
    - id: given_tag
      type: u1
      enum: given_tag
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__some__given
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__some__given
      if: (given_tag == given_tag::some)
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__some__given:
    seq:
    - id: inbox_level
      type: s4
    - id: message_counter
      type: n
    - id: payload
      type: bytes_dyn_uint30
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__tree_proof:
    seq:
    - id: version
      type: s2
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__before
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__before
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__after
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__after
    - id: state
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__tree_encoding:
    seq:
    - id: tree_encoding_tag
      type: u1
      enum: tree_encoding_tag
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__value__tree_encoding
      type: bytes_dyn_uint30
      if: (tree_encoding_tag == tree_encoding_tag::value)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__blinded_value__tree_encoding
      size: 32
      if: (tree_encoding_tag == tree_encoding_tag::blinded_value)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__node__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__node__node
      if: (tree_encoding_tag == tree_encoding_tag::node)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__blinded_node__tree_encoding
      size: 32
      if: (tree_encoding_tag == tree_encoding_tag::blinded_node)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__inode
      if: (tree_encoding_tag == tree_encoding_tag::inode)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__extender__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__extender__extender
      if: (tree_encoding_tag == tree_encoding_tag::extender)
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__extender__extender:
    seq:
    - id: length
      type: s8
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__extender__segment
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__extender__segment
    - id: proof
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__extender__segment:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__extender__segment_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__extender__segment_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__extender__segment_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__extender__segment_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__extender__segment_dyn:
    seq:
    - id: segment
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__inode:
    seq:
    - id: length
      type: s8
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__proofs
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__proofs
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__proofs:
    seq:
    - id: proofs_tag
      type: u1
      enum: proofs_tag
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__proofs
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__sparse_proof
      if: (proofs_tag == proofs_tag::sparse_proof)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__dense_proof__proofs
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__dense_proof__dense_proof_entries
      if: (proofs_tag == proofs_tag::dense_proof)
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__dense_proof__dense_proof_entries:
    seq:
    - id: dense_proof_elt
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__sparse_proof:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__sparse_proof_dyn
      type: u4
      valid:
        max: 1073741823
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__sparse_proof_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__sparse_proof_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__sparse_proof_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__sparse_proof_dyn:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__sparse_proof_entries
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__sparse_proof_entries
      repeat: eos
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__sparse_proof_entries:
    seq:
    - id: sparse_proof_elt_field0
      type: u1
    - id: sparse_proof_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree:
    seq:
    - id: inode_tree_tag
      type: u1
      enum: inode_tree_tag
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__blinded_inode__inode_tree
      size: 32
      if: (inode_tree_tag == inode_tree_tag::blinded_inode)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_values__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_values__inode_values
      if: (inode_tree_tag == inode_tree_tag::inode_values)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree__inode_tree
      if: (inode_tree_tag == inode_tree_tag::inode_tree)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_extender__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_extender__inode_extender
      if: (inode_tree_tag == inode_tree_tag::inode_extender)
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_extender__inode_extender:
    seq:
    - id: length
      type: s8
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_extender__segment
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_extender__segment
    - id: proof
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_extender__segment:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_extender__segment_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_extender__segment_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_extender__segment_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_extender__segment_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_extender__segment_dyn:
    seq:
    - id: segment
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree__inode_tree:
    seq:
    - id: length
      type: s8
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree__proofs
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree__proofs
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree__proofs:
    seq:
    - id: proofs_tag
      type: u1
      enum: proofs_tag
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree__sparse_proof__proofs
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree__sparse_proof__sparse_proof
      if: (proofs_tag == proofs_tag::sparse_proof)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree__dense_proof__proofs
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree__dense_proof__dense_proof_entries
      if: (proofs_tag == proofs_tag::dense_proof)
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree__dense_proof__dense_proof_entries:
    seq:
    - id: dense_proof_elt
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree__sparse_proof__sparse_proof:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree__sparse_proof__sparse_proof_dyn
      type: u4
      valid:
        max: 1073741823
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree__sparse_proof__sparse_proof_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree__sparse_proof__sparse_proof_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree__sparse_proof__sparse_proof_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree__sparse_proof__sparse_proof_dyn:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree__sparse_proof__sparse_proof_entries
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree__sparse_proof__sparse_proof_entries
      repeat: eos
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree__sparse_proof__sparse_proof_entries:
    seq:
    - id: sparse_proof_elt_field0
      type: u1
    - id: sparse_proof_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_values__inode_values:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_values__inode_values_dyn
      type: u4
      valid:
        max: 1073741823
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_values__inode_values_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_values__inode_values_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_values__inode_values_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_values__inode_values_dyn:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_values__inode_values_entries
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_values__inode_values_entries
      repeat: eos
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_values__inode_values_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_values__inode_values_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_values__inode_values_elt_field0
    - id: inode_values_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_values__inode_values_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_values__inode_values_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_values__inode_values_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_values__inode_values_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_values__inode_values_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__inode__sparse_proof__inode_values__inode_values_elt_field0_dyn:
    seq:
    - id: inode_values_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__node__node:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__node__node_dyn
      type: u4
      valid:
        max: 1073741823
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__node__node_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__node__node_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__node__node_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__node__node_dyn:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__node__node_entries
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__node__node_entries
      repeat: eos
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__node__node_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__node__node_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__node__node_elt_field0
    - id: node_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__node__node_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__node__node_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__node__node_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__node__node_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__node__node_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__node__node_elt_field0_dyn:
    seq:
    - id: node_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__after:
    seq:
    - id: after_tag
      type: u1
      enum: after_tag
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__value__after
      size: 32
      if: (after_tag == after_tag::value)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__node__after
      size: 32
      if: (after_tag == after_tag::node)
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__before:
    seq:
    - id: before_tag
      type: u1
      enum: before_tag
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__value__before
      size: 32
      if: (before_tag == before_tag::value)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__node__before
      size: 32
      if: (before_tag == before_tag::node)
  sc_rollup_refute__dissection__step:
    seq:
    - id: len_sc_rollup_refute__dissection__dissection_dyn
      type: u4
      valid:
        max: 1073741823
    - id: sc_rollup_refute__dissection__dissection_dyn
      type: sc_rollup_refute__dissection__dissection_dyn
      size: len_sc_rollup_refute__dissection__dissection_dyn
  sc_rollup_refute__dissection__dissection_dyn:
    seq:
    - id: sc_rollup_refute__dissection__dissection_entries
      type: sc_rollup_refute__dissection__dissection_entries
      repeat: eos
  sc_rollup_refute__dissection__dissection_entries:
    seq:
    - id: sc_rollup_refute__dissection__dissection_elt_field0
      type: sc_rollup_refute__dissection__dissection_elt_field0
    - id: dissection_elt_field1
      type: n
  sc_rollup_refute__dissection__dissection_elt_field0:
    seq:
    - id: dissection_elt_field0_tag
      type: u1
      enum: dissection_elt_field0_tag
    - id: sc_rollup_refute__dissection__some__dissection_elt_field0
      size: 32
      if: (dissection_elt_field0_tag == dissection_elt_field0_tag::some)
  sc_rollup_refute__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: sc_rollup_refute__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: sc_rollup_refute__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: sc_rollup_refute__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  sc_rollup_publish__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: source
      type: sc_rollup_publish__public_key_hash_
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
      type: bytes_dyn_uint30
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
  sc_rollup_publish__public_key_hash_:
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
  sc_rollup_cement__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: source
      type: sc_rollup_cement__public_key_hash_
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
      type: bytes_dyn_uint30
      doc: ! >-
        A smart contract rollup address: A smart contract rollup is identified by
        a base58 address starting with scr1
    - id: commitment
      size: 32
  sc_rollup_cement__public_key_hash_:
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
  sc_rollup_add_messages__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: source
      type: sc_rollup_add_messages__public_key_hash_
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
      type: bytes_dyn_uint30
      doc: ! >-
        A smart contract rollup address: A smart contract rollup is identified by
        a base58 address starting with scr1
    - id: sc_rollup_add_messages__message
      type: sc_rollup_add_messages__message
  sc_rollup_add_messages__message:
    seq:
    - id: len_sc_rollup_add_messages__message_dyn
      type: u4
      valid:
        max: 1073741823
    - id: sc_rollup_add_messages__message_dyn
      type: sc_rollup_add_messages__message_dyn
      size: len_sc_rollup_add_messages__message_dyn
  sc_rollup_add_messages__message_dyn:
    seq:
    - id: sc_rollup_add_messages__message_entries
      type: sc_rollup_add_messages__message_entries
      repeat: eos
  sc_rollup_add_messages__message_entries:
    seq:
    - id: message_elt
      type: bytes_dyn_uint30
  sc_rollup_add_messages__public_key_hash_:
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
  sc_rollup_originate__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: source
      type: sc_rollup_originate__public_key_hash_
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
    - id: boot_sector
      type: bytes_dyn_uint30
    - id: parameters_ty
      type: bytes_dyn_uint30
  sc_rollup_originate__public_key_hash_:
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
  dal_publish_slot_header__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: source
      type: dal_publish_slot_header__public_key_hash_
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: dal_publish_slot_header__slot
      type: dal_publish_slot_header__slot
  dal_publish_slot_header__slot:
    seq:
    - id: level
      type: s4
    - id: index
      type: u1
    - id: header
      type: int31
  dal_publish_slot_header__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: dal_publish_slot_header__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: dal_publish_slot_header__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: dal_publish_slot_header__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  transfer_ticket__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: source
      type: transfer_ticket__public_key_hash_
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: ticket_contents
      type: bytes_dyn_uint30
    - id: ticket_ty
      type: bytes_dyn_uint30
    - id: ticket_ticketer
      type: transfer_ticket__id_014__ptkathma__contract_id_
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: ticket_amount
      type: n
    - id: destination
      type: transfer_ticket__id_014__ptkathma__contract_id_
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: entrypoint
      type: bytes_dyn_uint30
  transfer_ticket__id_014__ptkathma__contract_id_:
    seq:
    - id: id_014__ptkathma__contract_id_tag
      type: u1
      enum: id_014__ptkathma__contract_id_tag
    - id: transfer_ticket__implicit__id_014__ptkathma__contract_id
      type: transfer_ticket__implicit__public_key_hash_
      if: (id_014__ptkathma__contract_id_tag == id_014__ptkathma__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: transfer_ticket__originated__id_014__ptkathma__contract_id
      type: transfer_ticket__originated__id_014__ptkathma__contract_id
      if: (id_014__ptkathma__contract_id_tag == id_014__ptkathma__contract_id_tag::originated)
  transfer_ticket__originated__id_014__ptkathma__contract_id:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  transfer_ticket__implicit__public_key_hash_:
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
  transfer_ticket__public_key_hash_:
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
  tx_rollup_dispatch_tickets__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: source
      type: tx_rollup_dispatch_tickets__public_key_hash_
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
      type: int31
    - id: tx_rollup_dispatch_tickets__message_result_path
      type: tx_rollup_dispatch_tickets__message_result_path
    - id: tx_rollup_dispatch_tickets__tickets_info
      type: tx_rollup_dispatch_tickets__tickets_info
  tx_rollup_dispatch_tickets__tickets_info:
    seq:
    - id: len_tx_rollup_dispatch_tickets__tickets_info_dyn
      type: u4
      valid:
        max: 1073741823
    - id: tx_rollup_dispatch_tickets__tickets_info_dyn
      type: tx_rollup_dispatch_tickets__tickets_info_dyn
      size: len_tx_rollup_dispatch_tickets__tickets_info_dyn
  tx_rollup_dispatch_tickets__tickets_info_dyn:
    seq:
    - id: tx_rollup_dispatch_tickets__tickets_info_entries
      type: tx_rollup_dispatch_tickets__tickets_info_entries
      repeat: eos
  tx_rollup_dispatch_tickets__tickets_info_entries:
    seq:
    - id: contents
      type: bytes_dyn_uint30
    - id: ty
      type: bytes_dyn_uint30
    - id: ticketer
      type: tx_rollup_dispatch_tickets__id_014__ptkathma__contract_id_
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: tx_rollup_dispatch_tickets__amount
      type: tx_rollup_dispatch_tickets__amount
    - id: claimer
      type: tx_rollup_dispatch_tickets__public_key_hash_
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
  tx_rollup_dispatch_tickets__id_014__ptkathma__contract_id_:
    seq:
    - id: id_014__ptkathma__contract_id_tag
      type: u1
      enum: id_014__ptkathma__contract_id_tag
    - id: tx_rollup_dispatch_tickets__implicit__id_014__ptkathma__contract_id
      type: tx_rollup_dispatch_tickets__implicit__public_key_hash_
      if: (id_014__ptkathma__contract_id_tag == id_014__ptkathma__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: tx_rollup_dispatch_tickets__originated__id_014__ptkathma__contract_id
      type: tx_rollup_dispatch_tickets__originated__id_014__ptkathma__contract_id
      if: (id_014__ptkathma__contract_id_tag == id_014__ptkathma__contract_id_tag::originated)
  tx_rollup_dispatch_tickets__originated__id_014__ptkathma__contract_id:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  tx_rollup_dispatch_tickets__implicit__public_key_hash_:
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
  tx_rollup_dispatch_tickets__message_result_path:
    seq:
    - id: len_tx_rollup_dispatch_tickets__message_result_path_dyn
      type: u4
      valid:
        max: 1073741823
    - id: tx_rollup_dispatch_tickets__message_result_path_dyn
      type: tx_rollup_dispatch_tickets__message_result_path_dyn
      size: len_tx_rollup_dispatch_tickets__message_result_path_dyn
  tx_rollup_dispatch_tickets__message_result_path_dyn:
    seq:
    - id: tx_rollup_dispatch_tickets__message_result_path_entries
      type: tx_rollup_dispatch_tickets__message_result_path_entries
      repeat: eos
  tx_rollup_dispatch_tickets__message_result_path_entries:
    seq:
    - id: message_result_list_hash
      size: 32
  int31:
    seq:
    - id: int31
      type: s4
      valid:
        min: -1073741824
        max: 1073741823
  tx_rollup_dispatch_tickets__public_key_hash_:
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
  tx_rollup_rejection__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: source
      type: tx_rollup_rejection__public_key_hash_
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
    - id: len_tx_rollup_rejection__case__3__case__3_field3_dyn
      type: u4
      valid:
        max: 1073741823
    - id: tx_rollup_rejection__case__3__case__3_field3_dyn
      type: tx_rollup_rejection__case__3__case__3_field3_dyn
      size: len_tx_rollup_rejection__case__3__case__3_field3_dyn
  tx_rollup_rejection__case__3__case__3_field3_dyn:
    seq:
    - id: tx_rollup_rejection__case__3__case__3_field3_entries
      type: tx_rollup_rejection__case__3__case__3_field3_entries
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
      type: bytes_dyn_uint30
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
    - id: len_tx_rollup_rejection__case__3__case__227__case__227_field1_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__3__case__227__case__227_field1_dyn
      type: tx_rollup_rejection__case__3__case__227__case__227_field1_dyn
      size: len_tx_rollup_rejection__case__3__case__227__case__227_field1_dyn
  tx_rollup_rejection__case__3__case__227__case__227_field1_dyn:
    seq:
    - id: case__227_field1
      size-eos: true
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
    - id: len_tx_rollup_rejection__case__3__case__226__case__226_field1_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__3__case__226__case__226_field1_dyn
      type: tx_rollup_rejection__case__3__case__226__case__226_field1_dyn
      size: len_tx_rollup_rejection__case__3__case__226__case__226_field1_dyn
  tx_rollup_rejection__case__3__case__226__case__226_field1_dyn:
    seq:
    - id: case__226_field1
      size-eos: true
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
    - id: len_tx_rollup_rejection__case__3__case__225__case__225_field1_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__3__case__225__case__225_field1_dyn
      type: tx_rollup_rejection__case__3__case__225__case__225_field1_dyn
      size: len_tx_rollup_rejection__case__3__case__225__case__225_field1_dyn
  tx_rollup_rejection__case__3__case__225__case__225_field1_dyn:
    seq:
    - id: case__225_field1
      size-eos: true
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
    - id: len_tx_rollup_rejection__case__3__case__224__case__224_field1_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__3__case__224__case__224_field1_dyn
      type: tx_rollup_rejection__case__3__case__224__case__224_field1_dyn
      size: len_tx_rollup_rejection__case__3__case__224__case__224_field1_dyn
  tx_rollup_rejection__case__3__case__224__case__224_field1_dyn:
    seq:
    - id: case__224_field1
      size-eos: true
  tx_rollup_rejection__case__3__case__193__case__3_field3_elt:
    seq:
    - id: len_tx_rollup_rejection__case__3__case__193__case__193_dyn
      type: u2
      valid:
        max: 65535
    - id: tx_rollup_rejection__case__3__case__193__case__193_dyn
      type: tx_rollup_rejection__case__3__case__193__case__193_dyn
      size: len_tx_rollup_rejection__case__3__case__193__case__193_dyn
  tx_rollup_rejection__case__3__case__193__case__193_dyn:
    seq:
    - id: case__193
      size-eos: true
  tx_rollup_rejection__case__3__case__192__case__3_field3_elt:
    seq:
    - id: len_tx_rollup_rejection__case__3__case__192__case__192_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__3__case__192__case__192_dyn
      type: tx_rollup_rejection__case__3__case__192__case__192_dyn
      size: len_tx_rollup_rejection__case__3__case__192__case__192_dyn
  tx_rollup_rejection__case__3__case__192__case__192_dyn:
    seq:
    - id: case__192
      size-eos: true
  tx_rollup_rejection__case__3__case__131__case__3_field3_elt:
    seq:
    - id: len_tx_rollup_rejection__case__3__case__131__case__131_dyn
      type: u4
      valid:
        max: 1073741823
    - id: tx_rollup_rejection__case__3__case__131__case__131_dyn
      type: tx_rollup_rejection__case__3__case__131__case__131_dyn
      size: len_tx_rollup_rejection__case__3__case__131__case__131_dyn
  tx_rollup_rejection__case__3__case__131__case__131_dyn:
    seq:
    - id: tx_rollup_rejection__case__3__case__131__case__131_entries
      type: tx_rollup_rejection__case__3__case__131__case__131_entries
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
    - id: len_tx_rollup_rejection__case__3__case__131__case__131_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__3__case__131__case__131_elt_field0_dyn
      type: tx_rollup_rejection__case__3__case__131__case__131_elt_field0_dyn
      size: len_tx_rollup_rejection__case__3__case__131__case__131_elt_field0_dyn
  tx_rollup_rejection__case__3__case__131__case__131_elt_field0_dyn:
    seq:
    - id: case__131_elt_field0
      size-eos: true
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
    - id: len_tx_rollup_rejection__case__3__case__130__case__130_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__3__case__130__case__130_elt_field0_dyn
      type: tx_rollup_rejection__case__3__case__130__case__130_elt_field0_dyn
      size: len_tx_rollup_rejection__case__3__case__130__case__130_elt_field0_dyn
  tx_rollup_rejection__case__3__case__130__case__130_elt_field0_dyn:
    seq:
    - id: case__130_elt_field0
      size-eos: true
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
    - id: len_tx_rollup_rejection__case__3__case__129__case__129_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__3__case__129__case__129_elt_field0_dyn
      type: tx_rollup_rejection__case__3__case__129__case__129_elt_field0_dyn
      size: len_tx_rollup_rejection__case__3__case__129__case__129_elt_field0_dyn
  tx_rollup_rejection__case__3__case__129__case__129_elt_field0_dyn:
    seq:
    - id: case__129_elt_field0
      size-eos: true
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
    - id: len_tx_rollup_rejection__case__1__case__1_field3_dyn
      type: u4
      valid:
        max: 1073741823
    - id: tx_rollup_rejection__case__1__case__1_field3_dyn
      type: tx_rollup_rejection__case__1__case__1_field3_dyn
      size: len_tx_rollup_rejection__case__1__case__1_field3_dyn
  tx_rollup_rejection__case__1__case__1_field3_dyn:
    seq:
    - id: tx_rollup_rejection__case__1__case__1_field3_entries
      type: tx_rollup_rejection__case__1__case__1_field3_entries
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
      type: bytes_dyn_uint30
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
    - id: len_tx_rollup_rejection__case__1__case__227__case__227_field1_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__1__case__227__case__227_field1_dyn
      type: tx_rollup_rejection__case__1__case__227__case__227_field1_dyn
      size: len_tx_rollup_rejection__case__1__case__227__case__227_field1_dyn
  tx_rollup_rejection__case__1__case__227__case__227_field1_dyn:
    seq:
    - id: case__227_field1
      size-eos: true
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
    - id: len_tx_rollup_rejection__case__1__case__226__case__226_field1_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__1__case__226__case__226_field1_dyn
      type: tx_rollup_rejection__case__1__case__226__case__226_field1_dyn
      size: len_tx_rollup_rejection__case__1__case__226__case__226_field1_dyn
  tx_rollup_rejection__case__1__case__226__case__226_field1_dyn:
    seq:
    - id: case__226_field1
      size-eos: true
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
    - id: len_tx_rollup_rejection__case__1__case__225__case__225_field1_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__1__case__225__case__225_field1_dyn
      type: tx_rollup_rejection__case__1__case__225__case__225_field1_dyn
      size: len_tx_rollup_rejection__case__1__case__225__case__225_field1_dyn
  tx_rollup_rejection__case__1__case__225__case__225_field1_dyn:
    seq:
    - id: case__225_field1
      size-eos: true
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
    - id: len_tx_rollup_rejection__case__1__case__224__case__224_field1_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__1__case__224__case__224_field1_dyn
      type: tx_rollup_rejection__case__1__case__224__case__224_field1_dyn
      size: len_tx_rollup_rejection__case__1__case__224__case__224_field1_dyn
  tx_rollup_rejection__case__1__case__224__case__224_field1_dyn:
    seq:
    - id: case__224_field1
      size-eos: true
  tx_rollup_rejection__case__1__case__193__case__1_field3_elt:
    seq:
    - id: len_tx_rollup_rejection__case__1__case__193__case__193_dyn
      type: u2
      valid:
        max: 65535
    - id: tx_rollup_rejection__case__1__case__193__case__193_dyn
      type: tx_rollup_rejection__case__1__case__193__case__193_dyn
      size: len_tx_rollup_rejection__case__1__case__193__case__193_dyn
  tx_rollup_rejection__case__1__case__193__case__193_dyn:
    seq:
    - id: case__193
      size-eos: true
  tx_rollup_rejection__case__1__case__192__case__1_field3_elt:
    seq:
    - id: len_tx_rollup_rejection__case__1__case__192__case__192_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__1__case__192__case__192_dyn
      type: tx_rollup_rejection__case__1__case__192__case__192_dyn
      size: len_tx_rollup_rejection__case__1__case__192__case__192_dyn
  tx_rollup_rejection__case__1__case__192__case__192_dyn:
    seq:
    - id: case__192
      size-eos: true
  tx_rollup_rejection__case__1__case__131__case__1_field3_elt:
    seq:
    - id: len_tx_rollup_rejection__case__1__case__131__case__131_dyn
      type: u4
      valid:
        max: 1073741823
    - id: tx_rollup_rejection__case__1__case__131__case__131_dyn
      type: tx_rollup_rejection__case__1__case__131__case__131_dyn
      size: len_tx_rollup_rejection__case__1__case__131__case__131_dyn
  tx_rollup_rejection__case__1__case__131__case__131_dyn:
    seq:
    - id: tx_rollup_rejection__case__1__case__131__case__131_entries
      type: tx_rollup_rejection__case__1__case__131__case__131_entries
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
    - id: len_tx_rollup_rejection__case__1__case__131__case__131_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__1__case__131__case__131_elt_field0_dyn
      type: tx_rollup_rejection__case__1__case__131__case__131_elt_field0_dyn
      size: len_tx_rollup_rejection__case__1__case__131__case__131_elt_field0_dyn
  tx_rollup_rejection__case__1__case__131__case__131_elt_field0_dyn:
    seq:
    - id: case__131_elt_field0
      size-eos: true
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
    - id: len_tx_rollup_rejection__case__1__case__130__case__130_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__1__case__130__case__130_elt_field0_dyn
      type: tx_rollup_rejection__case__1__case__130__case__130_elt_field0_dyn
      size: len_tx_rollup_rejection__case__1__case__130__case__130_elt_field0_dyn
  tx_rollup_rejection__case__1__case__130__case__130_elt_field0_dyn:
    seq:
    - id: case__130_elt_field0
      size-eos: true
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
    - id: len_tx_rollup_rejection__case__1__case__129__case__129_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__1__case__129__case__129_elt_field0_dyn
      type: tx_rollup_rejection__case__1__case__129__case__129_elt_field0_dyn
      size: len_tx_rollup_rejection__case__1__case__129__case__129_elt_field0_dyn
  tx_rollup_rejection__case__1__case__129__case__129_elt_field0_dyn:
    seq:
    - id: case__129_elt_field0
      size-eos: true
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
    - id: len_tx_rollup_rejection__case__2__case__2_field3_dyn
      type: u4
      valid:
        max: 1073741823
    - id: tx_rollup_rejection__case__2__case__2_field3_dyn
      type: tx_rollup_rejection__case__2__case__2_field3_dyn
      size: len_tx_rollup_rejection__case__2__case__2_field3_dyn
  tx_rollup_rejection__case__2__case__2_field3_dyn:
    seq:
    - id: tx_rollup_rejection__case__2__case__2_field3_entries
      type: tx_rollup_rejection__case__2__case__2_field3_entries
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
      type: bytes_dyn_uint30
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
    - id: len_tx_rollup_rejection__case__2__case__227__case__227_field1_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__2__case__227__case__227_field1_dyn
      type: tx_rollup_rejection__case__2__case__227__case__227_field1_dyn
      size: len_tx_rollup_rejection__case__2__case__227__case__227_field1_dyn
  tx_rollup_rejection__case__2__case__227__case__227_field1_dyn:
    seq:
    - id: case__227_field1
      size-eos: true
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
    - id: len_tx_rollup_rejection__case__2__case__226__case__226_field1_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__2__case__226__case__226_field1_dyn
      type: tx_rollup_rejection__case__2__case__226__case__226_field1_dyn
      size: len_tx_rollup_rejection__case__2__case__226__case__226_field1_dyn
  tx_rollup_rejection__case__2__case__226__case__226_field1_dyn:
    seq:
    - id: case__226_field1
      size-eos: true
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
    - id: len_tx_rollup_rejection__case__2__case__225__case__225_field1_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__2__case__225__case__225_field1_dyn
      type: tx_rollup_rejection__case__2__case__225__case__225_field1_dyn
      size: len_tx_rollup_rejection__case__2__case__225__case__225_field1_dyn
  tx_rollup_rejection__case__2__case__225__case__225_field1_dyn:
    seq:
    - id: case__225_field1
      size-eos: true
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
    - id: len_tx_rollup_rejection__case__2__case__224__case__224_field1_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__2__case__224__case__224_field1_dyn
      type: tx_rollup_rejection__case__2__case__224__case__224_field1_dyn
      size: len_tx_rollup_rejection__case__2__case__224__case__224_field1_dyn
  tx_rollup_rejection__case__2__case__224__case__224_field1_dyn:
    seq:
    - id: case__224_field1
      size-eos: true
  tx_rollup_rejection__case__2__case__193__case__2_field3_elt:
    seq:
    - id: len_tx_rollup_rejection__case__2__case__193__case__193_dyn
      type: u2
      valid:
        max: 65535
    - id: tx_rollup_rejection__case__2__case__193__case__193_dyn
      type: tx_rollup_rejection__case__2__case__193__case__193_dyn
      size: len_tx_rollup_rejection__case__2__case__193__case__193_dyn
  tx_rollup_rejection__case__2__case__193__case__193_dyn:
    seq:
    - id: case__193
      size-eos: true
  tx_rollup_rejection__case__2__case__192__case__2_field3_elt:
    seq:
    - id: len_tx_rollup_rejection__case__2__case__192__case__192_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__2__case__192__case__192_dyn
      type: tx_rollup_rejection__case__2__case__192__case__192_dyn
      size: len_tx_rollup_rejection__case__2__case__192__case__192_dyn
  tx_rollup_rejection__case__2__case__192__case__192_dyn:
    seq:
    - id: case__192
      size-eos: true
  tx_rollup_rejection__case__2__case__131__case__2_field3_elt:
    seq:
    - id: len_tx_rollup_rejection__case__2__case__131__case__131_dyn
      type: u4
      valid:
        max: 1073741823
    - id: tx_rollup_rejection__case__2__case__131__case__131_dyn
      type: tx_rollup_rejection__case__2__case__131__case__131_dyn
      size: len_tx_rollup_rejection__case__2__case__131__case__131_dyn
  tx_rollup_rejection__case__2__case__131__case__131_dyn:
    seq:
    - id: tx_rollup_rejection__case__2__case__131__case__131_entries
      type: tx_rollup_rejection__case__2__case__131__case__131_entries
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
    - id: len_tx_rollup_rejection__case__2__case__131__case__131_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__2__case__131__case__131_elt_field0_dyn
      type: tx_rollup_rejection__case__2__case__131__case__131_elt_field0_dyn
      size: len_tx_rollup_rejection__case__2__case__131__case__131_elt_field0_dyn
  tx_rollup_rejection__case__2__case__131__case__131_elt_field0_dyn:
    seq:
    - id: case__131_elt_field0
      size-eos: true
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
    - id: len_tx_rollup_rejection__case__2__case__130__case__130_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__2__case__130__case__130_elt_field0_dyn
      type: tx_rollup_rejection__case__2__case__130__case__130_elt_field0_dyn
      size: len_tx_rollup_rejection__case__2__case__130__case__130_elt_field0_dyn
  tx_rollup_rejection__case__2__case__130__case__130_elt_field0_dyn:
    seq:
    - id: case__130_elt_field0
      size-eos: true
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
    - id: len_tx_rollup_rejection__case__2__case__129__case__129_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__2__case__129__case__129_elt_field0_dyn
      type: tx_rollup_rejection__case__2__case__129__case__129_elt_field0_dyn
      size: len_tx_rollup_rejection__case__2__case__129__case__129_elt_field0_dyn
  tx_rollup_rejection__case__2__case__129__case__129_elt_field0_dyn:
    seq:
    - id: case__129_elt_field0
      size-eos: true
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
    - id: len_tx_rollup_rejection__case__0__case__0_field3_dyn
      type: u4
      valid:
        max: 1073741823
    - id: tx_rollup_rejection__case__0__case__0_field3_dyn
      type: tx_rollup_rejection__case__0__case__0_field3_dyn
      size: len_tx_rollup_rejection__case__0__case__0_field3_dyn
  tx_rollup_rejection__case__0__case__0_field3_dyn:
    seq:
    - id: tx_rollup_rejection__case__0__case__0_field3_entries
      type: tx_rollup_rejection__case__0__case__0_field3_entries
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
      type: bytes_dyn_uint30
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
    - id: len_tx_rollup_rejection__case__0__case__227__case__227_field1_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__0__case__227__case__227_field1_dyn
      type: tx_rollup_rejection__case__0__case__227__case__227_field1_dyn
      size: len_tx_rollup_rejection__case__0__case__227__case__227_field1_dyn
  tx_rollup_rejection__case__0__case__227__case__227_field1_dyn:
    seq:
    - id: case__227_field1
      size-eos: true
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
    - id: len_tx_rollup_rejection__case__0__case__226__case__226_field1_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__0__case__226__case__226_field1_dyn
      type: tx_rollup_rejection__case__0__case__226__case__226_field1_dyn
      size: len_tx_rollup_rejection__case__0__case__226__case__226_field1_dyn
  tx_rollup_rejection__case__0__case__226__case__226_field1_dyn:
    seq:
    - id: case__226_field1
      size-eos: true
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
    - id: len_tx_rollup_rejection__case__0__case__225__case__225_field1_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__0__case__225__case__225_field1_dyn
      type: tx_rollup_rejection__case__0__case__225__case__225_field1_dyn
      size: len_tx_rollup_rejection__case__0__case__225__case__225_field1_dyn
  tx_rollup_rejection__case__0__case__225__case__225_field1_dyn:
    seq:
    - id: case__225_field1
      size-eos: true
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
    - id: len_tx_rollup_rejection__case__0__case__224__case__224_field1_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__0__case__224__case__224_field1_dyn
      type: tx_rollup_rejection__case__0__case__224__case__224_field1_dyn
      size: len_tx_rollup_rejection__case__0__case__224__case__224_field1_dyn
  tx_rollup_rejection__case__0__case__224__case__224_field1_dyn:
    seq:
    - id: case__224_field1
      size-eos: true
  tx_rollup_rejection__case__0__case__193__case__0_field3_elt:
    seq:
    - id: len_tx_rollup_rejection__case__0__case__193__case__193_dyn
      type: u2
      valid:
        max: 65535
    - id: tx_rollup_rejection__case__0__case__193__case__193_dyn
      type: tx_rollup_rejection__case__0__case__193__case__193_dyn
      size: len_tx_rollup_rejection__case__0__case__193__case__193_dyn
  tx_rollup_rejection__case__0__case__193__case__193_dyn:
    seq:
    - id: case__193
      size-eos: true
  tx_rollup_rejection__case__0__case__192__case__0_field3_elt:
    seq:
    - id: len_tx_rollup_rejection__case__0__case__192__case__192_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__0__case__192__case__192_dyn
      type: tx_rollup_rejection__case__0__case__192__case__192_dyn
      size: len_tx_rollup_rejection__case__0__case__192__case__192_dyn
  tx_rollup_rejection__case__0__case__192__case__192_dyn:
    seq:
    - id: case__192
      size-eos: true
  tx_rollup_rejection__case__0__case__131__case__0_field3_elt:
    seq:
    - id: len_tx_rollup_rejection__case__0__case__131__case__131_dyn
      type: u4
      valid:
        max: 1073741823
    - id: tx_rollup_rejection__case__0__case__131__case__131_dyn
      type: tx_rollup_rejection__case__0__case__131__case__131_dyn
      size: len_tx_rollup_rejection__case__0__case__131__case__131_dyn
  tx_rollup_rejection__case__0__case__131__case__131_dyn:
    seq:
    - id: tx_rollup_rejection__case__0__case__131__case__131_entries
      type: tx_rollup_rejection__case__0__case__131__case__131_entries
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
    - id: len_tx_rollup_rejection__case__0__case__131__case__131_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__0__case__131__case__131_elt_field0_dyn
      type: tx_rollup_rejection__case__0__case__131__case__131_elt_field0_dyn
      size: len_tx_rollup_rejection__case__0__case__131__case__131_elt_field0_dyn
  tx_rollup_rejection__case__0__case__131__case__131_elt_field0_dyn:
    seq:
    - id: case__131_elt_field0
      size-eos: true
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
    - id: len_tx_rollup_rejection__case__0__case__130__case__130_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__0__case__130__case__130_elt_field0_dyn
      type: tx_rollup_rejection__case__0__case__130__case__130_elt_field0_dyn
      size: len_tx_rollup_rejection__case__0__case__130__case__130_elt_field0_dyn
  tx_rollup_rejection__case__0__case__130__case__130_elt_field0_dyn:
    seq:
    - id: case__130_elt_field0
      size-eos: true
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
    - id: len_tx_rollup_rejection__case__0__case__129__case__129_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: tx_rollup_rejection__case__0__case__129__case__129_elt_field0_dyn
      type: tx_rollup_rejection__case__0__case__129__case__129_elt_field0_dyn
      size: len_tx_rollup_rejection__case__0__case__129__case__129_elt_field0_dyn
  tx_rollup_rejection__case__0__case__129__case__129_elt_field0_dyn:
    seq:
    - id: case__129_elt_field0
      size-eos: true
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
    - id: len_tx_rollup_rejection__previous_message_result_path_dyn
      type: u4
      valid:
        max: 1073741823
    - id: tx_rollup_rejection__previous_message_result_path_dyn
      type: tx_rollup_rejection__previous_message_result_path_dyn
      size: len_tx_rollup_rejection__previous_message_result_path_dyn
  tx_rollup_rejection__previous_message_result_path_dyn:
    seq:
    - id: tx_rollup_rejection__previous_message_result_path_entries
      type: tx_rollup_rejection__previous_message_result_path_entries
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
    - id: len_tx_rollup_rejection__message_result_path_dyn
      type: u4
      valid:
        max: 1073741823
    - id: tx_rollup_rejection__message_result_path_dyn
      type: tx_rollup_rejection__message_result_path_dyn
      size: len_tx_rollup_rejection__message_result_path_dyn
  tx_rollup_rejection__message_result_path_dyn:
    seq:
    - id: tx_rollup_rejection__message_result_path_entries
      type: tx_rollup_rejection__message_result_path_entries
      repeat: eos
  tx_rollup_rejection__message_result_path_entries:
    seq:
    - id: message_result_list_hash
      size: 32
  tx_rollup_rejection__message_path:
    seq:
    - id: len_tx_rollup_rejection__message_path_dyn
      type: u4
      valid:
        max: 1073741823
    - id: tx_rollup_rejection__message_path_dyn
      type: tx_rollup_rejection__message_path_dyn
      size: len_tx_rollup_rejection__message_path_dyn
  tx_rollup_rejection__message_path_dyn:
    seq:
    - id: tx_rollup_rejection__message_path_entries
      type: tx_rollup_rejection__message_path_entries
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
      type: bytes_dyn_uint30
      if: (message_tag == message_tag::batch)
    - id: tx_rollup_rejection__deposit__message
      type: tx_rollup_rejection__deposit__deposit
      if: (message_tag == message_tag::deposit)
  tx_rollup_rejection__deposit__deposit:
    seq:
    - id: sender
      type: tx_rollup_rejection__deposit__public_key_hash_
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
  tx_rollup_rejection__deposit__public_key_hash_:
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
  tx_rollup_rejection__public_key_hash_:
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
  tx_rollup_remove_commitment__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: source
      type: tx_rollup_remove_commitment__public_key_hash_
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
  tx_rollup_remove_commitment__public_key_hash_:
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
  tx_rollup_finalize_commitment__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: source
      type: tx_rollup_finalize_commitment__public_key_hash_
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
  tx_rollup_finalize_commitment__public_key_hash_:
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
  tx_rollup_return_bond__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: source
      type: tx_rollup_return_bond__public_key_hash_
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
  tx_rollup_return_bond__public_key_hash_:
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
  tx_rollup_commit__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: source
      type: tx_rollup_commit__public_key_hash_
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
    - id: len_tx_rollup_commit__messages_dyn
      type: u4
      valid:
        max: 1073741823
    - id: tx_rollup_commit__messages_dyn
      type: tx_rollup_commit__messages_dyn
      size: len_tx_rollup_commit__messages_dyn
  tx_rollup_commit__messages_dyn:
    seq:
    - id: tx_rollup_commit__messages_entries
      type: tx_rollup_commit__messages_entries
      repeat: eos
  tx_rollup_commit__messages_entries:
    seq:
    - id: message_result_hash
      size: 32
  tx_rollup_commit__public_key_hash_:
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
  tx_rollup_submit_batch__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: source
      type: tx_rollup_submit_batch__public_key_hash_
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
    - id: content
      type: bytes_dyn_uint30
    - id: burn_limit_tag
      type: u1
      enum: bool
    - id: burn_limit
      type: n
      if: (burn_limit_tag == bool::true)
  tx_rollup_submit_batch__public_key_hash_:
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
  tx_rollup_origination__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: source
      type: tx_rollup_origination__public_key_hash_
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
  tx_rollup_origination__public_key_hash_:
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
  register_global_constant__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: source
      type: register_global_constant__public_key_hash_
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: value
      type: bytes_dyn_uint30
  register_global_constant__public_key_hash_:
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
  increase_paid_storage__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: source
      type: increase_paid_storage__public_key_hash_
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
      type: z
    - id: destination
      type: increase_paid_storage__id_014__ptkathma__contract_id__originated_
      doc: ! >-
        A contract handle -- originated account: A contract notation as given to an
        RPC or inside scripts. Can be a base58 originated contract hash.
  increase_paid_storage__id_014__ptkathma__contract_id__originated_:
    seq:
    - id: id_014__ptkathma__contract_id__originated_tag
      type: u1
      enum: id_014__ptkathma__contract_id__originated_tag
    - id: increase_paid_storage__originated__id_014__ptkathma__contract_id__originated
      type: increase_paid_storage__originated__id_014__ptkathma__contract_id__originated
      if: (id_014__ptkathma__contract_id__originated_tag == id_014__ptkathma__contract_id__originated_tag::originated)
  increase_paid_storage__originated__id_014__ptkathma__contract_id__originated:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  increase_paid_storage__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: increase_paid_storage__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: increase_paid_storage__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: increase_paid_storage__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  set_deposits_limit__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: source
      type: set_deposits_limit__public_key_hash_
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
  set_deposits_limit__public_key_hash_:
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
  delegation__id_014__ptkathma__operation__alpha__contents:
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
  origination__id_014__ptkathma__operation__alpha__contents:
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
      type: origination__id_014__ptkathma__scripted__contracts_
  origination__id_014__ptkathma__scripted__contracts_:
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
  transaction__id_014__ptkathma__operation__alpha__contents:
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
      type: transaction__id_014__ptkathma__contract_id_
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
      type: transaction__id_014__ptkathma__entrypoint_
      doc: ! 'entrypoint: Named entrypoint to a Michelson smart contract'
    - id: value
      type: bytes_dyn_uint30
  bytes_dyn_uint30:
    seq:
    - id: len_bytes_dyn_uint30
      type: u4
      valid:
        max: 1073741823
    - id: bytes_dyn_uint30
      size: len_bytes_dyn_uint30
  uint30:
    seq:
    - id: uint30
      type: u4
      valid:
        max: 1073741823
  transaction__id_014__ptkathma__entrypoint_:
    seq:
    - id: id_014__ptkathma__entrypoint_tag
      type: u1
      enum: id_014__ptkathma__entrypoint_tag
    - id: transaction__named__id_014__ptkathma__entrypoint
      type: transaction__named__id_014__ptkathma__entrypoint
      if: (id_014__ptkathma__entrypoint_tag == id_014__ptkathma__entrypoint_tag::named)
  transaction__named__id_014__ptkathma__entrypoint:
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
  transaction__id_014__ptkathma__contract_id_:
    seq:
    - id: id_014__ptkathma__contract_id_tag
      type: u1
      enum: id_014__ptkathma__contract_id_tag
    - id: transaction__implicit__id_014__ptkathma__contract_id
      type: transaction__implicit__public_key_hash_
      if: (id_014__ptkathma__contract_id_tag == id_014__ptkathma__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: transaction__originated__id_014__ptkathma__contract_id
      type: transaction__originated__id_014__ptkathma__contract_id
      if: (id_014__ptkathma__contract_id_tag == id_014__ptkathma__contract_id_tag::originated)
  transaction__originated__id_014__ptkathma__contract_id:
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
  reveal__id_014__ptkathma__operation__alpha__contents:
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
  n:
    seq:
    - id: n
      type: n_chunk
      repeat: until
      repeat-until: not (_.has_more).as<bool>
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
  ballot__id_014__ptkathma__operation__alpha__contents:
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
  proposals__id_014__ptkathma__operation__alpha__contents:
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
  activate_account__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: pkh
      size: 20
    - id: secret
      size: 20
  double_baking_evidence__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: double_baking_evidence__bh1
      type: double_baking_evidence__bh1
    - id: double_baking_evidence__bh2
      type: double_baking_evidence__bh2
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
    - id: double_baking_evidence__id_014__ptkathma__block_header__alpha__full_header_
      type: double_baking_evidence__id_014__ptkathma__block_header__alpha__full_header_
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
    - id: double_baking_evidence__id_014__ptkathma__block_header__alpha__full_header_
      type: double_baking_evidence__id_014__ptkathma__block_header__alpha__full_header_
  double_baking_evidence__id_014__ptkathma__block_header__alpha__full_header_:
    seq:
    - id: id_014__ptkathma__block_header__alpha__full_header
      type: block_header__shell
    - id: double_baking_evidence__id_014__ptkathma__block_header__alpha__signed_contents_
      type: double_baking_evidence__id_014__ptkathma__block_header__alpha__signed_contents_
  double_baking_evidence__id_014__ptkathma__block_header__alpha__signed_contents_:
    seq:
    - id: double_baking_evidence__id_014__ptkathma__block_header__alpha__unsigned_contents_
      type: double_baking_evidence__id_014__ptkathma__block_header__alpha__unsigned_contents_
    - id: signature
      size: 64
  double_baking_evidence__id_014__ptkathma__block_header__alpha__unsigned_contents_:
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
  double_preendorsement_evidence__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: double_preendorsement_evidence__op1
      type: double_preendorsement_evidence__op1
    - id: double_preendorsement_evidence__op2
      type: double_preendorsement_evidence__op2
  double_preendorsement_evidence__op2:
    seq:
    - id: len_double_preendorsement_evidence__op2_dyn
      type: u4
      valid:
        max: 1073741823
    - id: double_preendorsement_evidence__op2_dyn
      type: double_preendorsement_evidence__op2_dyn
      size: len_double_preendorsement_evidence__op2_dyn
  double_preendorsement_evidence__op2_dyn:
    seq:
    - id: double_preendorsement_evidence__id_014__ptkathma__inlined__preendorsement_
      type: double_preendorsement_evidence__id_014__ptkathma__inlined__preendorsement_
  double_preendorsement_evidence__op1:
    seq:
    - id: len_double_preendorsement_evidence__op1_dyn
      type: u4
      valid:
        max: 1073741823
    - id: double_preendorsement_evidence__op1_dyn
      type: double_preendorsement_evidence__op1_dyn
      size: len_double_preendorsement_evidence__op1_dyn
  double_preendorsement_evidence__op1_dyn:
    seq:
    - id: double_preendorsement_evidence__id_014__ptkathma__inlined__preendorsement_
      type: double_preendorsement_evidence__id_014__ptkathma__inlined__preendorsement_
  double_preendorsement_evidence__id_014__ptkathma__inlined__preendorsement_:
    seq:
    - id: id_014__ptkathma__inlined__preendorsement
      type: operation__shell_header
    - id: operations
      type: double_preendorsement_evidence__id_014__ptkathma__inlined__preendorsement__contents_
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size: 64
      if: (signature_tag == bool::true)
  double_preendorsement_evidence__id_014__ptkathma__inlined__preendorsement__contents_:
    seq:
    - id: id_014__ptkathma__inlined__preendorsement__contents_tag
      type: u1
      enum: id_014__ptkathma__inlined__preendorsement__contents_tag
    - id: double_preendorsement_evidence__preendorsement__id_014__ptkathma__inlined__preendorsement__contents
      type: double_preendorsement_evidence__preendorsement__id_014__ptkathma__inlined__preendorsement__contents
      if: (id_014__ptkathma__inlined__preendorsement__contents_tag == id_014__ptkathma__inlined__preendorsement__contents_tag::preendorsement)
  double_preendorsement_evidence__preendorsement__id_014__ptkathma__inlined__preendorsement__contents:
    seq:
    - id: slot
      type: u2
    - id: level
      type: s4
    - id: round
      type: s4
    - id: block_payload_hash
      size: 32
  double_endorsement_evidence__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: double_endorsement_evidence__op1
      type: double_endorsement_evidence__op1
    - id: double_endorsement_evidence__op2
      type: double_endorsement_evidence__op2
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
    - id: double_endorsement_evidence__id_014__ptkathma__inlined__endorsement_
      type: double_endorsement_evidence__id_014__ptkathma__inlined__endorsement_
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
    - id: double_endorsement_evidence__id_014__ptkathma__inlined__endorsement_
      type: double_endorsement_evidence__id_014__ptkathma__inlined__endorsement_
  double_endorsement_evidence__id_014__ptkathma__inlined__endorsement_:
    seq:
    - id: id_014__ptkathma__inlined__endorsement
      type: operation__shell_header
    - id: operations
      type: double_endorsement_evidence__id_014__ptkathma__inlined__endorsement_mempool__contents_
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size: 64
      if: (signature_tag == bool::true)
  double_endorsement_evidence__id_014__ptkathma__inlined__endorsement_mempool__contents_:
    seq:
    - id: id_014__ptkathma__inlined__endorsement_mempool__contents_tag
      type: u1
      enum: id_014__ptkathma__inlined__endorsement_mempool__contents_tag
    - id: double_endorsement_evidence__endorsement__id_014__ptkathma__inlined__endorsement_mempool__contents
      type: double_endorsement_evidence__endorsement__id_014__ptkathma__inlined__endorsement_mempool__contents
      if: (id_014__ptkathma__inlined__endorsement_mempool__contents_tag == id_014__ptkathma__inlined__endorsement_mempool__contents_tag::endorsement)
  double_endorsement_evidence__endorsement__id_014__ptkathma__inlined__endorsement_mempool__contents:
    seq:
    - id: slot
      type: u2
    - id: level
      type: s4
    - id: round
      type: s4
    - id: block_payload_hash
      size: 32
  vdf_revelation__solution:
    seq:
    - id: solution_field0
      size: 100
    - id: solution_field1
      size: 100
  seed_nonce_revelation__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: level
      type: s4
    - id: nonce
      size: 32
  dal_slot_availability__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: endorser
      type: dal_slot_availability__public_key_hash_
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: endorsement
      type: z
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
  n_chunk:
    seq:
    - id: has_more
      type: b1be
    - id: payload
      type: b7be
  dal_slot_availability__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: dal_slot_availability__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: dal_slot_availability__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: dal_slot_availability__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
  preendorsement__id_014__ptkathma__operation__alpha__contents:
    seq:
    - id: slot
      type: u2
    - id: level
      type: s4
    - id: round
      type: s4
    - id: block_payload_hash
      size: 32
  endorsement__id_014__ptkathma__operation__alpha__contents:
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
  inbox_tag:
    0: none
    1: some
  requested_tag:
    0: no_input_required
    1: initial
    2: first_after
  given_tag:
    0: none
    1: some
  inode_tree_tag:
    0: blinded_inode
    1: inode_values
    2: inode_tree
    3: inode_extender
    4: none
  proofs_tag:
    0: sparse_proof
    1: dense_proof
  tree_encoding_tag:
    0: value
    1: blinded_value
    2: node
    3: blinded_node
    4: inode
    5: extender
    6: none
  after_tag:
    0: value
    1: node
  before_tag:
    0: value
    1: node
  pvm_step_tag:
    0: arithmetic__pvm__with__proof
    1: wasm__2__0__0__pvm__with__proof
  dissection_elt_field0_tag:
    0: none
    1: some
  step_tag:
    0: dissection
    1: proof
  kind_tag:
    0: example_arith__smart__contract__rollup__kind
    1: wasm__2__0__0__smart__contract__rollup__kind
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
  id_014__ptkathma__contract_id__originated_tag:
    1: originated
  id_014__ptkathma__entrypoint_tag:
    0: default
    1: root
    2: do
    3: set_delegate
    4: remove_delegate
    255: named
  id_014__ptkathma__contract_id_tag:
    0: implicit
    1: originated
  public_key_tag:
    0: ed25519
    1: secp256k1
    2: p256
  id_014__ptkathma__inlined__preendorsement__contents_tag:
    20: preendorsement
  bool:
    0: false
    255: true
  id_014__ptkathma__inlined__endorsement_mempool__contents_tag:
    21: endorsement
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
  id_014__ptkathma__operation__alpha__contents_tag:
    1: seed_nonce_revelation
    2: double_endorsement_evidence
    3: double_baking_evidence
    4: activate_account
    5: proposals
    6: ballot
    7: double_preendorsement_evidence
    8: vdf_revelation
    17: failing_noop
    20: preendorsement
    21: endorsement
    22: dal_slot_availability
    107: reveal
    108: transaction
    109: origination
    110: delegation
    111: register_global_constant
    112: set_deposits_limit
    113: increase_paid_storage
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
    204: sc_rollup_refute
    205: sc_rollup_timeout
    206: sc_rollup_execute_outbox_message
    207: sc_rollup_recover_bond
    208: sc_rollup_dal_slot_subscribe
    230: dal_publish_slot_header
seq:
- id: id_014__ptkathma__operation__alpha__contents_
  type: id_014__ptkathma__operation__alpha__contents_
