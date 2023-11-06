meta:
  id: id_017__ptnairob__operation__contents_list
  endian: be
doc: ! 'Encoding id: 017-PtNairob.operation.contents_list'
types:
  id_017__ptnairob__operation__contents_list_entries:
    seq:
    - id: id_017__ptnairob__operation__alpha__contents_
      type: id_017__ptnairob__operation__alpha__contents_
  id_017__ptnairob__operation__alpha__contents_:
    seq:
    - id: id_017__ptnairob__operation__alpha__contents_tag
      type: u1
      enum: id_017__ptnairob__operation__alpha__contents_tag
    - id: endorsement__id_017__ptnairob__operation__alpha__contents
      type: endorsement__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::endorsement)
    - id: preendorsement__id_017__ptnairob__operation__alpha__contents
      type: preendorsement__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::preendorsement)
    - id: dal_attestation__id_017__ptnairob__operation__alpha__contents
      type: dal_attestation__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::dal_attestation)
    - id: seed_nonce_revelation__id_017__ptnairob__operation__alpha__contents
      type: seed_nonce_revelation__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::seed_nonce_revelation)
    - id: vdf_revelation__id_017__ptnairob__operation__alpha__contents
      type: vdf_revelation__solution
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::vdf_revelation)
    - id: double_endorsement_evidence__id_017__ptnairob__operation__alpha__contents
      type: double_endorsement_evidence__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::double_endorsement_evidence)
    - id: double_preendorsement_evidence__id_017__ptnairob__operation__alpha__contents
      type: double_preendorsement_evidence__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::double_preendorsement_evidence)
    - id: double_baking_evidence__id_017__ptnairob__operation__alpha__contents
      type: double_baking_evidence__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::double_baking_evidence)
    - id: activate_account__id_017__ptnairob__operation__alpha__contents
      type: activate_account__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::activate_account)
    - id: proposals__id_017__ptnairob__operation__alpha__contents
      type: proposals__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::proposals)
    - id: ballot__id_017__ptnairob__operation__alpha__contents
      type: ballot__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::ballot)
    - id: reveal__id_017__ptnairob__operation__alpha__contents
      type: reveal__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::reveal)
    - id: transaction__id_017__ptnairob__operation__alpha__contents
      type: transaction__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::transaction)
    - id: origination__id_017__ptnairob__operation__alpha__contents
      type: origination__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::origination)
    - id: delegation__id_017__ptnairob__operation__alpha__contents
      type: delegation__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::delegation)
    - id: set_deposits_limit__id_017__ptnairob__operation__alpha__contents
      type: set_deposits_limit__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::set_deposits_limit)
    - id: increase_paid_storage__id_017__ptnairob__operation__alpha__contents
      type: increase_paid_storage__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::increase_paid_storage)
    - id: update_consensus_key__id_017__ptnairob__operation__alpha__contents
      type: update_consensus_key__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::update_consensus_key)
    - id: drain_delegate__id_017__ptnairob__operation__alpha__contents
      type: drain_delegate__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::drain_delegate)
    - id: failing_noop__id_017__ptnairob__operation__alpha__contents
      type: failing_noop__arbitrary
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::failing_noop)
    - id: register_global_constant__id_017__ptnairob__operation__alpha__contents
      type: register_global_constant__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::register_global_constant)
    - id: transfer_ticket__id_017__ptnairob__operation__alpha__contents
      type: transfer_ticket__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::transfer_ticket)
    - id: dal_publish_slot_header__id_017__ptnairob__operation__alpha__contents
      type: dal_publish_slot_header__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::dal_publish_slot_header)
    - id: smart_rollup_originate__id_017__ptnairob__operation__alpha__contents
      type: smart_rollup_originate__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::smart_rollup_originate)
    - id: smart_rollup_add_messages__id_017__ptnairob__operation__alpha__contents
      type: smart_rollup_add_messages__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::smart_rollup_add_messages)
    - id: smart_rollup_cement__id_017__ptnairob__operation__alpha__contents
      type: smart_rollup_cement__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::smart_rollup_cement)
    - id: smart_rollup_publish__id_017__ptnairob__operation__alpha__contents
      type: smart_rollup_publish__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::smart_rollup_publish)
    - id: smart_rollup_refute__id_017__ptnairob__operation__alpha__contents
      type: smart_rollup_refute__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::smart_rollup_refute)
    - id: smart_rollup_timeout__id_017__ptnairob__operation__alpha__contents
      type: smart_rollup_timeout__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::smart_rollup_timeout)
    - id: smart_rollup_execute_outbox_message__id_017__ptnairob__operation__alpha__contents
      type: smart_rollup_execute_outbox_message__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::smart_rollup_execute_outbox_message)
    - id: smart_rollup_recover_bond__id_017__ptnairob__operation__alpha__contents
      type: smart_rollup_recover_bond__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::smart_rollup_recover_bond)
    - id: zk_rollup_origination__id_017__ptnairob__operation__alpha__contents
      type: zk_rollup_origination__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::zk_rollup_origination)
    - id: zk_rollup_publish__id_017__ptnairob__operation__alpha__contents
      type: zk_rollup_publish__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::zk_rollup_publish)
    - id: zk_rollup_update__id_017__ptnairob__operation__alpha__contents
      type: zk_rollup_update__id_017__ptnairob__operation__alpha__contents
      if: (id_017__ptnairob__operation__alpha__contents_tag == id_017__ptnairob__operation__alpha__contents_tag::zk_rollup_update)
  zk_rollup_update__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: source
      type: zk_rollup_update__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: zk_rollup
      size: 20
    - id: zk_rollup_update__update
      type: zk_rollup_update__update
  zk_rollup_update__update:
    seq:
    - id: zk_rollup_update__pending_pis
      type: zk_rollup_update__pending_pis
    - id: zk_rollup_update__private_pis
      type: zk_rollup_update__private_pis
    - id: fee_pi
      type: zk_rollup_update__new_state
    - id: zk_rollup_update__proof
      type: zk_rollup_update__proof
  zk_rollup_update__proof:
    seq:
    - id: len_proof
      type: u4
      valid:
        max: 1073741823
    - id: proof
      size: len_proof
  zk_rollup_update__private_pis:
    seq:
    - id: len_zk_rollup_update__private_pis_dyn
      type: u4
      valid:
        max: 1073741823
    - id: zk_rollup_update__private_pis_dyn
      type: zk_rollup_update__private_pis_dyn
      size: len_zk_rollup_update__private_pis_dyn
  zk_rollup_update__private_pis_dyn:
    seq:
    - id: zk_rollup_update__private_pis_entries
      type: zk_rollup_update__private_pis_entries
      repeat: eos
  zk_rollup_update__private_pis_entries:
    seq:
    - id: zk_rollup_update__private_pis_elt_field0
      type: zk_rollup_update__private_pis_elt_field0
    - id: zk_rollup_update__private_pis_elt_field1
      type: zk_rollup_update__private_pis_elt_field1
  zk_rollup_update__private_pis_elt_field1:
    seq:
    - id: zk_rollup_update__new_state
      type: zk_rollup_update__new_state
    - id: fee
      size: 32
  zk_rollup_update__private_pis_elt_field0:
    seq:
    - id: len_private_pis_elt_field0
      type: u4
      valid:
        max: 1073741823
    - id: private_pis_elt_field0
      size: len_private_pis_elt_field0
  zk_rollup_update__pending_pis:
    seq:
    - id: len_zk_rollup_update__pending_pis_dyn
      type: u4
      valid:
        max: 1073741823
    - id: zk_rollup_update__pending_pis_dyn
      type: zk_rollup_update__pending_pis_dyn
      size: len_zk_rollup_update__pending_pis_dyn
  zk_rollup_update__pending_pis_dyn:
    seq:
    - id: zk_rollup_update__pending_pis_entries
      type: zk_rollup_update__pending_pis_entries
      repeat: eos
  zk_rollup_update__pending_pis_entries:
    seq:
    - id: zk_rollup_update__pending_pis_elt_field0
      type: zk_rollup_update__pending_pis_elt_field0
    - id: zk_rollup_update__pending_pis_elt_field1
      type: zk_rollup_update__pending_pis_elt_field1
  zk_rollup_update__pending_pis_elt_field1:
    seq:
    - id: zk_rollup_update__new_state
      type: zk_rollup_update__new_state
    - id: fee
      size: 32
    - id: exit_validity
      type: u1
      enum: bool
  zk_rollup_update__new_state:
    seq:
    - id: len_zk_rollup_update__new_state_dyn
      type: u4
      valid:
        max: 1073741823
    - id: zk_rollup_update__new_state_dyn
      type: zk_rollup_update__new_state_dyn
      size: len_zk_rollup_update__new_state_dyn
  zk_rollup_update__new_state_dyn:
    seq:
    - id: zk_rollup_update__new_state_entries
      type: zk_rollup_update__new_state_entries
      repeat: eos
  zk_rollup_update__new_state_entries:
    seq:
    - id: new_state_elt
      size: 32
  zk_rollup_update__pending_pis_elt_field0:
    seq:
    - id: len_pending_pis_elt_field0
      type: u4
      valid:
        max: 1073741823
    - id: pending_pis_elt_field0
      size: len_pending_pis_elt_field0
  zk_rollup_update__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: zk_rollup_update__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: zk_rollup_update__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: zk_rollup_update__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: zk_rollup_update__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  zk_rollup_publish__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: source
      type: zk_rollup_publish__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: zk_rollup
      size: 20
    - id: zk_rollup_publish__op
      type: zk_rollup_publish__op
  zk_rollup_publish__op:
    seq:
    - id: len_zk_rollup_publish__op_dyn
      type: u4
      valid:
        max: 1073741823
    - id: zk_rollup_publish__op_dyn
      type: zk_rollup_publish__op_dyn
      size: len_zk_rollup_publish__op_dyn
  zk_rollup_publish__op_dyn:
    seq:
    - id: zk_rollup_publish__op_entries
      type: zk_rollup_publish__op_entries
      repeat: eos
  zk_rollup_publish__op_entries:
    seq:
    - id: zk_rollup_publish__op_elt_field0
      type: zk_rollup_publish__op_elt_field0
    - id: zk_rollup_publish__op_elt_field1
      type: zk_rollup_publish__op_elt_field1
  zk_rollup_publish__op_elt_field1:
    seq:
    - id: op_elt_field1_tag
      type: u1
      enum: op_elt_field1_tag
    - id: zk_rollup_publish__some__op_elt_field1
      type: zk_rollup_publish__some__op_elt_field1
      if: (op_elt_field1_tag == op_elt_field1_tag::some)
  zk_rollup_publish__some__op_elt_field1:
    seq:
    - id: contents
      type: zk_rollup_publish__some__micheline__017__ptnairob__michelson_v1__expression
    - id: ty
      type: zk_rollup_publish__some__micheline__017__ptnairob__michelson_v1__expression
    - id: ticketer
      type: zk_rollup_publish__some__id_017__ptnairob__contract_id_
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
  zk_rollup_publish__some__id_017__ptnairob__contract_id_:
    seq:
    - id: id_017__ptnairob__contract_id_tag
      type: u1
      enum: id_017__ptnairob__contract_id_tag
    - id: zk_rollup_publish__some__implicit__id_017__ptnairob__contract_id
      type: zk_rollup_publish__some__implicit__public_key_hash_
      if: (id_017__ptnairob__contract_id_tag == id_017__ptnairob__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: zk_rollup_publish__some__originated__id_017__ptnairob__contract_id
      type: zk_rollup_publish__some__originated__id_017__ptnairob__contract_id
      if: (id_017__ptnairob__contract_id_tag == id_017__ptnairob__contract_id_tag::originated)
  zk_rollup_publish__some__originated__id_017__ptnairob__contract_id:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  zk_rollup_publish__some__implicit__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: zk_rollup_publish__some__implicit__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: zk_rollup_publish__some__implicit__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: zk_rollup_publish__some__implicit__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: zk_rollup_publish__some__implicit__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  zk_rollup_publish__some__micheline__017__ptnairob__michelson_v1__expression:
    seq:
    - id: micheline__017__ptnairob__michelson_v1__expression_tag
      type: u1
      enum: micheline__017__ptnairob__michelson_v1__expression_tag
    - id: zk_rollup_publish__some__int__micheline__017__ptnairob__michelson_v1__expression
      type: z
      if: (micheline__017__ptnairob__michelson_v1__expression_tag == micheline__017__ptnairob__michelson_v1__expression_tag::int)
    - id: zk_rollup_publish__some__string__micheline__017__ptnairob__michelson_v1__expression
      type: zk_rollup_publish__some__string__string
      if: (micheline__017__ptnairob__michelson_v1__expression_tag == micheline__017__ptnairob__michelson_v1__expression_tag::string)
    - id: zk_rollup_publish__some__sequence__micheline__017__ptnairob__michelson_v1__expression
      type: zk_rollup_publish__some__sequence__micheline__017__ptnairob__michelson_v1__expression
      if: (micheline__017__ptnairob__michelson_v1__expression_tag == micheline__017__ptnairob__michelson_v1__expression_tag::sequence)
    - id: zk_rollup_publish__some__prim__no_args__no_annots__micheline__017__ptnairob__michelson_v1__expression
      type: u1
      if: (micheline__017__ptnairob__michelson_v1__expression_tag == micheline__017__ptnairob__michelson_v1__expression_tag::prim__no_args__no_annots)
      enum: zk_rollup_publish__some__prim__no_args__no_annots__id_017__ptnairob__michelson__v1__primitives
    - id: zk_rollup_publish__some__prim__no_args__some_annots__micheline__017__ptnairob__michelson_v1__expression
      type: zk_rollup_publish__some__prim__no_args__some_annots__micheline__017__ptnairob__michelson_v1__expression
      if: (micheline__017__ptnairob__michelson_v1__expression_tag == micheline__017__ptnairob__michelson_v1__expression_tag::prim__no_args__some_annots)
    - id: zk_rollup_publish__some__prim__1_arg__no_annots__micheline__017__ptnairob__michelson_v1__expression
      type: zk_rollup_publish__some__prim__1_arg__no_annots__micheline__017__ptnairob__michelson_v1__expression
      if: (micheline__017__ptnairob__michelson_v1__expression_tag == micheline__017__ptnairob__michelson_v1__expression_tag::prim__1_arg__no_annots)
    - id: zk_rollup_publish__some__prim__1_arg__some_annots__micheline__017__ptnairob__michelson_v1__expression
      type: zk_rollup_publish__some__prim__1_arg__some_annots__micheline__017__ptnairob__michelson_v1__expression
      if: (micheline__017__ptnairob__michelson_v1__expression_tag == micheline__017__ptnairob__michelson_v1__expression_tag::prim__1_arg__some_annots)
    - id: zk_rollup_publish__some__prim__2_args__no_annots__micheline__017__ptnairob__michelson_v1__expression
      type: zk_rollup_publish__some__prim__2_args__no_annots__micheline__017__ptnairob__michelson_v1__expression
      if: (micheline__017__ptnairob__michelson_v1__expression_tag == micheline__017__ptnairob__michelson_v1__expression_tag::prim__2_args__no_annots)
    - id: zk_rollup_publish__some__prim__2_args__some_annots__micheline__017__ptnairob__michelson_v1__expression
      type: zk_rollup_publish__some__prim__2_args__some_annots__micheline__017__ptnairob__michelson_v1__expression
      if: (micheline__017__ptnairob__michelson_v1__expression_tag == micheline__017__ptnairob__michelson_v1__expression_tag::prim__2_args__some_annots)
    - id: zk_rollup_publish__some__prim__generic__micheline__017__ptnairob__michelson_v1__expression
      type: zk_rollup_publish__some__prim__generic__micheline__017__ptnairob__michelson_v1__expression
      if: (micheline__017__ptnairob__michelson_v1__expression_tag == micheline__017__ptnairob__michelson_v1__expression_tag::prim__generic)
    - id: zk_rollup_publish__some__bytes__micheline__017__ptnairob__michelson_v1__expression
      type: zk_rollup_publish__some__bytes__bytes
      if: (micheline__017__ptnairob__michelson_v1__expression_tag == micheline__017__ptnairob__michelson_v1__expression_tag::bytes)
  zk_rollup_publish__some__bytes__bytes:
    seq:
    - id: len_bytes
      type: u4
      valid:
        max: 1073741823
    - id: bytes
      size: len_bytes
  zk_rollup_publish__some__prim__generic__micheline__017__ptnairob__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__generic__id_017__ptnairob__michelson__v1__primitives
    - id: zk_rollup_publish__some__prim__generic__args
      type: zk_rollup_publish__some__prim__generic__args
    - id: zk_rollup_publish__some__prim__generic__annots
      type: zk_rollup_publish__some__prim__generic__annots
  zk_rollup_publish__some__prim__generic__annots:
    seq:
    - id: len_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: len_annots
  zk_rollup_publish__some__prim__generic__args:
    seq:
    - id: len_zk_rollup_publish__some__prim__generic__args_dyn
      type: u4
      valid:
        max: 1073741823
    - id: zk_rollup_publish__some__prim__generic__args_dyn
      type: zk_rollup_publish__some__prim__generic__args_dyn
      size: len_zk_rollup_publish__some__prim__generic__args_dyn
  zk_rollup_publish__some__prim__generic__args_dyn:
    seq:
    - id: zk_rollup_publish__some__prim__generic__args_entries
      type: zk_rollup_publish__some__prim__generic__args_entries
      repeat: eos
  zk_rollup_publish__some__prim__generic__args_entries:
    seq:
    - id: args_elt
      type: zk_rollup_publish__some__micheline__017__ptnairob__michelson_v1__expression
  zk_rollup_publish__some__prim__2_args__some_annots__micheline__017__ptnairob__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__2_args__some_annots__id_017__ptnairob__michelson__v1__primitives
    - id: arg1
      type: zk_rollup_publish__some__micheline__017__ptnairob__michelson_v1__expression
    - id: arg2
      type: zk_rollup_publish__some__micheline__017__ptnairob__michelson_v1__expression
    - id: zk_rollup_publish__some__prim__2_args__some_annots__annots
      type: zk_rollup_publish__some__prim__2_args__some_annots__annots
  zk_rollup_publish__some__prim__2_args__some_annots__annots:
    seq:
    - id: len_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: len_annots
  zk_rollup_publish__some__prim__2_args__no_annots__micheline__017__ptnairob__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__2_args__no_annots__id_017__ptnairob__michelson__v1__primitives
    - id: arg1
      type: zk_rollup_publish__some__micheline__017__ptnairob__michelson_v1__expression
    - id: arg2
      type: zk_rollup_publish__some__micheline__017__ptnairob__michelson_v1__expression
  zk_rollup_publish__some__prim__1_arg__some_annots__micheline__017__ptnairob__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__1_arg__some_annots__id_017__ptnairob__michelson__v1__primitives
    - id: arg
      type: zk_rollup_publish__some__micheline__017__ptnairob__michelson_v1__expression
    - id: zk_rollup_publish__some__prim__1_arg__some_annots__annots
      type: zk_rollup_publish__some__prim__1_arg__some_annots__annots
  zk_rollup_publish__some__prim__1_arg__some_annots__annots:
    seq:
    - id: len_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: len_annots
  zk_rollup_publish__some__prim__1_arg__no_annots__micheline__017__ptnairob__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__1_arg__no_annots__id_017__ptnairob__michelson__v1__primitives
    - id: arg
      type: zk_rollup_publish__some__micheline__017__ptnairob__michelson_v1__expression
  zk_rollup_publish__some__prim__no_args__some_annots__micheline__017__ptnairob__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__no_args__some_annots__id_017__ptnairob__michelson__v1__primitives
    - id: zk_rollup_publish__some__prim__no_args__some_annots__annots
      type: zk_rollup_publish__some__prim__no_args__some_annots__annots
  zk_rollup_publish__some__prim__no_args__some_annots__annots:
    seq:
    - id: len_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: len_annots
  zk_rollup_publish__some__sequence__micheline__017__ptnairob__michelson_v1__expression:
    seq:
    - id: len_zk_rollup_publish__some__sequence__sequence_dyn
      type: u4
      valid:
        max: 1073741823
    - id: zk_rollup_publish__some__sequence__sequence_dyn
      type: zk_rollup_publish__some__sequence__sequence_dyn
      size: len_zk_rollup_publish__some__sequence__sequence_dyn
  zk_rollup_publish__some__sequence__sequence_dyn:
    seq:
    - id: zk_rollup_publish__some__sequence__sequence_entries
      type: zk_rollup_publish__some__sequence__sequence_entries
      repeat: eos
  zk_rollup_publish__some__sequence__sequence_entries:
    seq:
    - id: sequence_elt
      type: zk_rollup_publish__some__micheline__017__ptnairob__michelson_v1__expression
  zk_rollup_publish__some__string__string:
    seq:
    - id: len_string
      type: u4
      valid:
        max: 1073741823
    - id: string
      size: len_string
  zk_rollup_publish__op_elt_field0:
    seq:
    - id: op_code
      type: s4
      valid:
        min: -1073741824
        max: 1073741823
    - id: zk_rollup_publish__price
      type: zk_rollup_publish__price
    - id: l1_dst
      type: zk_rollup_publish__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: rollup_id
      size: 20
    - id: zk_rollup_publish__payload
      type: zk_rollup_publish__payload
  zk_rollup_publish__payload:
    seq:
    - id: len_zk_rollup_publish__payload_dyn
      type: u4
      valid:
        max: 1073741823
    - id: zk_rollup_publish__payload_dyn
      type: zk_rollup_publish__payload_dyn
      size: len_zk_rollup_publish__payload_dyn
  zk_rollup_publish__payload_dyn:
    seq:
    - id: zk_rollup_publish__payload_entries
      type: zk_rollup_publish__payload_entries
      repeat: eos
  zk_rollup_publish__payload_entries:
    seq:
    - id: payload_elt
      size: 32
  zk_rollup_publish__price:
    seq:
    - id: id
      size: 32
    - id: amount
      type: z
  zk_rollup_publish__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: zk_rollup_publish__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: zk_rollup_publish__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: zk_rollup_publish__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: zk_rollup_publish__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  zk_rollup_origination__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: source
      type: zk_rollup_origination__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: zk_rollup_origination__public_parameters
      type: zk_rollup_origination__public_parameters
    - id: zk_rollup_origination__circuits_info
      type: zk_rollup_origination__circuits_info
    - id: zk_rollup_origination__init_state
      type: zk_rollup_origination__init_state
    - id: nb_ops
      type: s4
      valid:
        min: -1073741824
        max: 1073741823
  zk_rollup_origination__init_state:
    seq:
    - id: len_zk_rollup_origination__init_state_dyn
      type: u4
      valid:
        max: 1073741823
    - id: zk_rollup_origination__init_state_dyn
      type: zk_rollup_origination__init_state_dyn
      size: len_zk_rollup_origination__init_state_dyn
  zk_rollup_origination__init_state_dyn:
    seq:
    - id: zk_rollup_origination__init_state_entries
      type: zk_rollup_origination__init_state_entries
      repeat: eos
  zk_rollup_origination__init_state_entries:
    seq:
    - id: init_state_elt
      size: 32
  zk_rollup_origination__circuits_info:
    seq:
    - id: len_zk_rollup_origination__circuits_info_dyn
      type: u4
      valid:
        max: 1073741823
    - id: zk_rollup_origination__circuits_info_dyn
      type: zk_rollup_origination__circuits_info_dyn
      size: len_zk_rollup_origination__circuits_info_dyn
  zk_rollup_origination__circuits_info_dyn:
    seq:
    - id: zk_rollup_origination__circuits_info_entries
      type: zk_rollup_origination__circuits_info_entries
      repeat: eos
  zk_rollup_origination__circuits_info_entries:
    seq:
    - id: zk_rollup_origination__circuits_info_elt_field0
      type: zk_rollup_origination__circuits_info_elt_field0
    - id: circuits_info_elt_field1
      type: u1
      enum: circuits_info_elt_field1_tag
      doc: circuits_info_elt_field1_tag
  zk_rollup_origination__circuits_info_elt_field0:
    seq:
    - id: len_circuits_info_elt_field0
      type: u4
      valid:
        max: 1073741823
    - id: circuits_info_elt_field0
      size: len_circuits_info_elt_field0
  zk_rollup_origination__public_parameters:
    seq:
    - id: len_public_parameters
      type: u4
      valid:
        max: 1073741823
    - id: public_parameters
      size: len_public_parameters
  zk_rollup_origination__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: zk_rollup_origination__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: zk_rollup_origination__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: zk_rollup_origination__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: zk_rollup_origination__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  smart_rollup_recover_bond__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: source
      type: smart_rollup_recover_bond__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
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
    - id: staker
      type: smart_rollup_recover_bond__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
  smart_rollup_recover_bond__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: smart_rollup_recover_bond__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: smart_rollup_recover_bond__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: smart_rollup_recover_bond__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: smart_rollup_recover_bond__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  smart_rollup_execute_outbox_message__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: source
      type: smart_rollup_execute_outbox_message__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
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
        A smart rollup address: A smart rollup is identified by a base58 address starting
        with sr1
    - id: cemented_commitment
      size: 32
    - id: smart_rollup_execute_outbox_message__output_proof
      type: smart_rollup_execute_outbox_message__output_proof
  smart_rollup_execute_outbox_message__output_proof:
    seq:
    - id: len_output_proof
      type: u4
      valid:
        max: 1073741823
    - id: output_proof
      size: len_output_proof
  smart_rollup_execute_outbox_message__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: smart_rollup_execute_outbox_message__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: smart_rollup_execute_outbox_message__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: smart_rollup_execute_outbox_message__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: smart_rollup_execute_outbox_message__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  smart_rollup_timeout__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: source
      type: smart_rollup_timeout__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
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
        A smart rollup address: A smart rollup is identified by a base58 address starting
        with sr1
    - id: smart_rollup_timeout__stakers
      type: smart_rollup_timeout__stakers
  smart_rollup_timeout__stakers:
    seq:
    - id: alice
      type: smart_rollup_timeout__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: bob
      type: smart_rollup_timeout__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
  smart_rollup_timeout__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: smart_rollup_timeout__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: smart_rollup_timeout__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: smart_rollup_timeout__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: smart_rollup_timeout__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  smart_rollup_refute__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: source
      type: smart_rollup_refute__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
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
        A smart rollup address: A smart rollup is identified by a base58 address starting
        with sr1
    - id: opponent
      type: smart_rollup_refute__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: smart_rollup_refute__refutation
      type: smart_rollup_refute__refutation
  smart_rollup_refute__refutation:
    seq:
    - id: refutation_tag
      type: u1
      enum: refutation_tag
    - id: smart_rollup_refute__start__refutation
      type: smart_rollup_refute__start__refutation
      if: (refutation_tag == refutation_tag::start)
    - id: smart_rollup_refute__move__refutation
      type: smart_rollup_refute__move__refutation
      if: (refutation_tag == refutation_tag::move)
  smart_rollup_refute__move__refutation:
    seq:
    - id: choice
      type: n
    - id: smart_rollup_refute__move__step
      type: smart_rollup_refute__move__step
  smart_rollup_refute__move__step:
    seq:
    - id: step_tag
      type: u1
      enum: step_tag
    - id: smart_rollup_refute__move__dissection__step
      type: smart_rollup_refute__move__dissection__step
      if: (step_tag == step_tag::dissection)
    - id: smart_rollup_refute__move__proof__step
      type: smart_rollup_refute__move__proof__step
      if: (step_tag == step_tag::proof)
  smart_rollup_refute__move__proof__step:
    seq:
    - id: smart_rollup_refute__move__proof__pvm_step
      type: smart_rollup_refute__move__proof__pvm_step
    - id: input_proof_tag
      type: u1
      enum: bool
    - id: smart_rollup_refute__move__proof__input_proof_
      type: smart_rollup_refute__move__proof__input_proof_
      if: (input_proof_tag == bool::true)
  smart_rollup_refute__move__proof__input_proof_:
    seq:
    - id: input_proof_tag
      type: u1
      enum: input_proof_tag
    - id: smart_rollup_refute__move__proof__inbox__proof__input_proof
      type: smart_rollup_refute__move__proof__inbox__proof__input_proof
      if: (input_proof_tag == input_proof_tag::inbox__proof)
    - id: smart_rollup_refute__move__proof__reveal__proof__input_proof
      type: smart_rollup_refute__move__proof__reveal__proof__reveal_proof
      if: (input_proof_tag == input_proof_tag::reveal__proof)
  smart_rollup_refute__move__proof__reveal__proof__reveal_proof:
    seq:
    - id: reveal_proof_tag
      type: u1
      enum: reveal_proof_tag
    - id: smart_rollup_refute__move__proof__reveal__proof__raw__data__proof__reveal_proof
      type: smart_rollup_refute__move__proof__reveal__proof__raw__data__proof__raw_data
      if: (reveal_proof_tag == reveal_proof_tag::raw__data__proof)
    - id: smart_rollup_refute__move__proof__reveal__proof__dal__page__proof__reveal_proof
      type: smart_rollup_refute__move__proof__reveal__proof__dal__page__proof__reveal_proof
      if: (reveal_proof_tag == reveal_proof_tag::dal__page__proof)
  smart_rollup_refute__move__proof__reveal__proof__dal__page__proof__reveal_proof:
    seq:
    - id: smart_rollup_refute__move__proof__reveal__proof__dal__page__proof__dal_page_id
      type: smart_rollup_refute__move__proof__reveal__proof__dal__page__proof__dal_page_id
    - id: smart_rollup_refute__move__proof__reveal__proof__dal__page__proof__dal_proof
      type: smart_rollup_refute__move__proof__reveal__proof__dal__page__proof__dal_proof
  smart_rollup_refute__move__proof__reveal__proof__dal__page__proof__dal_proof:
    seq:
    - id: len_dal_proof
      type: u4
      valid:
        max: 1073741823
    - id: dal_proof
      size: len_dal_proof
  smart_rollup_refute__move__proof__reveal__proof__dal__page__proof__dal_page_id:
    seq:
    - id: published_level
      type: s4
    - id: slot_index
      type: u1
    - id: page_index
      type: s2
  smart_rollup_refute__move__proof__reveal__proof__raw__data__proof__raw_data:
    seq:
    - id: len_smart_rollup_refute__move__proof__reveal__proof__raw__data__proof__raw_data_dyn
      type: u2
      valid:
        max: 4096
    - id: smart_rollup_refute__move__proof__reveal__proof__raw__data__proof__raw_data_dyn
      type: smart_rollup_refute__move__proof__reveal__proof__raw__data__proof__raw_data_dyn
      size: len_smart_rollup_refute__move__proof__reveal__proof__raw__data__proof__raw_data_dyn
  smart_rollup_refute__move__proof__reveal__proof__raw__data__proof__raw_data_dyn:
    seq:
    - id: raw_data
      size-eos: true
  smart_rollup_refute__move__proof__inbox__proof__input_proof:
    seq:
    - id: level
      type: s4
    - id: message_counter
      type: n
    - id: smart_rollup_refute__move__proof__inbox__proof__serialized_proof
      type: smart_rollup_refute__move__proof__inbox__proof__serialized_proof
  smart_rollup_refute__move__proof__inbox__proof__serialized_proof:
    seq:
    - id: len_serialized_proof
      type: u4
      valid:
        max: 1073741823
    - id: serialized_proof
      size: len_serialized_proof
  smart_rollup_refute__move__proof__pvm_step:
    seq:
    - id: len_pvm_step
      type: u4
      valid:
        max: 1073741823
    - id: pvm_step
      size: len_pvm_step
  smart_rollup_refute__move__dissection__step:
    seq:
    - id: len_smart_rollup_refute__move__dissection__dissection_dyn
      type: u4
      valid:
        max: 1073741823
    - id: smart_rollup_refute__move__dissection__dissection_dyn
      type: smart_rollup_refute__move__dissection__dissection_dyn
      size: len_smart_rollup_refute__move__dissection__dissection_dyn
  smart_rollup_refute__move__dissection__dissection_dyn:
    seq:
    - id: smart_rollup_refute__move__dissection__dissection_entries
      type: smart_rollup_refute__move__dissection__dissection_entries
      repeat: eos
  smart_rollup_refute__move__dissection__dissection_entries:
    seq:
    - id: state_tag
      type: u1
      enum: bool
    - id: state
      size: 32
      if: (state_tag == bool::true)
    - id: tick
      type: n
  smart_rollup_refute__start__refutation:
    seq:
    - id: player_commitment_hash
      size: 32
    - id: opponent_commitment_hash
      size: 32
  smart_rollup_refute__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: smart_rollup_refute__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: smart_rollup_refute__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: smart_rollup_refute__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: smart_rollup_refute__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  smart_rollup_publish__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: source
      type: smart_rollup_publish__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
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
        A smart rollup address: A smart rollup is identified by a base58 address starting
        with sr1
    - id: smart_rollup_publish__commitment
      type: smart_rollup_publish__commitment
  smart_rollup_publish__commitment:
    seq:
    - id: compressed_state
      size: 32
    - id: inbox_level
      type: s4
    - id: predecessor
      size: 32
    - id: number_of_ticks
      type: s8
  smart_rollup_publish__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: smart_rollup_publish__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: smart_rollup_publish__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: smart_rollup_publish__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: smart_rollup_publish__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  smart_rollup_cement__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: source
      type: smart_rollup_cement__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
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
        A smart rollup address: A smart rollup is identified by a base58 address starting
        with sr1
    - id: commitment
      size: 32
      doc: ! >-
        DEPRECATED: This field is not used anymore by the protocol and will be removed
        in a future proposal.
  smart_rollup_cement__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: smart_rollup_cement__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: smart_rollup_cement__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: smart_rollup_cement__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: smart_rollup_cement__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  smart_rollup_add_messages__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: source
      type: smart_rollup_add_messages__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: smart_rollup_add_messages__message
      type: smart_rollup_add_messages__message
  smart_rollup_add_messages__message:
    seq:
    - id: len_smart_rollup_add_messages__message_dyn
      type: u4
      valid:
        max: 1073741823
    - id: smart_rollup_add_messages__message_dyn
      type: smart_rollup_add_messages__message_dyn
      size: len_smart_rollup_add_messages__message_dyn
  smart_rollup_add_messages__message_dyn:
    seq:
    - id: smart_rollup_add_messages__message_entries
      type: smart_rollup_add_messages__message_entries
      repeat: eos
  smart_rollup_add_messages__message_entries:
    seq:
    - id: len_message_elt
      type: u4
      valid:
        max: 1073741823
    - id: message_elt
      size: len_message_elt
  smart_rollup_add_messages__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: smart_rollup_add_messages__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: smart_rollup_add_messages__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: smart_rollup_add_messages__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: smart_rollup_add_messages__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  smart_rollup_originate__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: source
      type: smart_rollup_originate__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: pvm_kind
      type: u1
      enum: smart_rollup_originate__pvm_kind
    - id: smart_rollup_originate__kernel
      type: smart_rollup_originate__kernel
    - id: smart_rollup_originate__origination_proof
      type: smart_rollup_originate__origination_proof
    - id: smart_rollup_originate__parameters_ty
      type: smart_rollup_originate__parameters_ty
  smart_rollup_originate__parameters_ty:
    seq:
    - id: len_parameters_ty
      type: u4
      valid:
        max: 1073741823
    - id: parameters_ty
      size: len_parameters_ty
  smart_rollup_originate__origination_proof:
    seq:
    - id: len_origination_proof
      type: u4
      valid:
        max: 1073741823
    - id: origination_proof
      size: len_origination_proof
  smart_rollup_originate__kernel:
    seq:
    - id: len_kernel
      type: u4
      valid:
        max: 1073741823
    - id: kernel
      size: len_kernel
  smart_rollup_originate__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: smart_rollup_originate__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: smart_rollup_originate__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: smart_rollup_originate__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: smart_rollup_originate__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  dal_publish_slot_header__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: source
      type: dal_publish_slot_header__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: dal_publish_slot_header__slot_header
      type: dal_publish_slot_header__slot_header
  dal_publish_slot_header__slot_header:
    seq:
    - id: published_level
      type: s4
    - id: slot_index
      type: u1
    - id: commitment
      size: 48
    - id: commitment_proof
      size: 48
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
    - id: dal_publish_slot_header__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  transfer_ticket__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: source
      type: transfer_ticket__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
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
      type: transfer_ticket__id_017__ptnairob__contract_id_
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: ticket_amount
      type: n
    - id: destination
      type: transfer_ticket__id_017__ptnairob__contract_id_
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
  transfer_ticket__id_017__ptnairob__contract_id_:
    seq:
    - id: id_017__ptnairob__contract_id_tag
      type: u1
      enum: id_017__ptnairob__contract_id_tag
    - id: transfer_ticket__implicit__id_017__ptnairob__contract_id
      type: transfer_ticket__implicit__public_key_hash_
      if: (id_017__ptnairob__contract_id_tag == id_017__ptnairob__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: transfer_ticket__originated__id_017__ptnairob__contract_id
      type: transfer_ticket__originated__id_017__ptnairob__contract_id
      if: (id_017__ptnairob__contract_id_tag == id_017__ptnairob__contract_id_tag::originated)
  transfer_ticket__originated__id_017__ptnairob__contract_id:
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
    - id: transfer_ticket__implicit__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
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
    - id: transfer_ticket__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  register_global_constant__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: source
      type: register_global_constant__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
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
    - id: register_global_constant__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  failing_noop__arbitrary:
    seq:
    - id: len_arbitrary
      type: u4
      valid:
        max: 1073741823
    - id: arbitrary
      size: len_arbitrary
  drain_delegate__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: consensus_key
      type: drain_delegate__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: delegate
      type: drain_delegate__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: destination
      type: drain_delegate__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
  drain_delegate__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: drain_delegate__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: drain_delegate__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: drain_delegate__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: drain_delegate__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  update_consensus_key__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: source
      type: update_consensus_key__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: pk
      type: update_consensus_key__public_key_
      doc: A Ed25519, Secp256k1, or P256 public key
  update_consensus_key__public_key_:
    seq:
    - id: public_key_tag
      type: u1
      enum: public_key_tag
    - id: update_consensus_key__ed25519__public_key
      size: 32
      if: (public_key_tag == public_key_tag::ed25519)
    - id: update_consensus_key__secp256k1__public_key
      size: 33
      if: (public_key_tag == public_key_tag::secp256k1)
    - id: update_consensus_key__p256__public_key
      size: 33
      if: (public_key_tag == public_key_tag::p256)
    - id: update_consensus_key__bls__public_key
      size: 48
      if: (public_key_tag == public_key_tag::bls)
  update_consensus_key__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: update_consensus_key__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: update_consensus_key__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: update_consensus_key__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: update_consensus_key__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  increase_paid_storage__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: source
      type: increase_paid_storage__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
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
      type: increase_paid_storage__id_017__ptnairob__contract_id__originated_
      doc: ! >-
        A contract handle -- originated account: A contract notation as given to an
        RPC or inside scripts. Can be a base58 originated contract hash.
  increase_paid_storage__id_017__ptnairob__contract_id__originated_:
    seq:
    - id: id_017__ptnairob__contract_id__originated_tag
      type: u1
      enum: id_017__ptnairob__contract_id__originated_tag
    - id: increase_paid_storage__originated__id_017__ptnairob__contract_id__originated
      type: increase_paid_storage__originated__id_017__ptnairob__contract_id__originated
      if: (id_017__ptnairob__contract_id__originated_tag == id_017__ptnairob__contract_id__originated_tag::originated)
  increase_paid_storage__originated__id_017__ptnairob__contract_id__originated:
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
    - id: increase_paid_storage__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  set_deposits_limit__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: source
      type: set_deposits_limit__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
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
    - id: set_deposits_limit__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  delegation__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: source
      type: delegation__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
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
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
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
    - id: delegation__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  origination__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: source
      type: origination__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
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
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: script
      type: origination__id_017__ptnairob__scripted__contracts_
  origination__id_017__ptnairob__scripted__contracts_:
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
    - id: origination__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  transaction__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: source
      type: transaction__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
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
      type: transaction__id_017__ptnairob__contract_id_
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
      type: transaction__id_017__ptnairob__entrypoint_
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
  transaction__id_017__ptnairob__entrypoint_:
    seq:
    - id: id_017__ptnairob__entrypoint_tag
      type: u1
      enum: id_017__ptnairob__entrypoint_tag
    - id: transaction__named__id_017__ptnairob__entrypoint
      type: transaction__named__id_017__ptnairob__entrypoint
      if: (id_017__ptnairob__entrypoint_tag == id_017__ptnairob__entrypoint_tag::named)
  transaction__named__id_017__ptnairob__entrypoint:
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
  transaction__id_017__ptnairob__contract_id_:
    seq:
    - id: id_017__ptnairob__contract_id_tag
      type: u1
      enum: id_017__ptnairob__contract_id_tag
    - id: transaction__implicit__id_017__ptnairob__contract_id
      type: transaction__implicit__public_key_hash_
      if: (id_017__ptnairob__contract_id_tag == id_017__ptnairob__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: transaction__originated__id_017__ptnairob__contract_id
      type: transaction__originated__id_017__ptnairob__contract_id
      if: (id_017__ptnairob__contract_id_tag == id_017__ptnairob__contract_id_tag::originated)
  transaction__originated__id_017__ptnairob__contract_id:
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
    - id: transaction__implicit__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
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
    - id: transaction__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  reveal__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: source
      type: reveal__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
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
    - id: reveal__bls__public_key
      size: 48
      if: (public_key_tag == public_key_tag::bls)
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
    - id: reveal__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  ballot__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: source
      type: ballot__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
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
    - id: ballot__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  proposals__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: source
      type: proposals__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: period
      type: s4
    - id: proposals__proposals
      type: proposals__proposals
  proposals__proposals:
    seq:
    - id: len_proposals__proposals_dyn
      type: u4
      valid:
        max: 640
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
    - id: proposals__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  activate_account__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: pkh
      size: 20
    - id: secret
      size: 20
  double_baking_evidence__id_017__ptnairob__operation__alpha__contents:
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
    - id: double_baking_evidence__id_017__ptnairob__block_header__alpha__full_header_
      type: double_baking_evidence__id_017__ptnairob__block_header__alpha__full_header_
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
    - id: double_baking_evidence__id_017__ptnairob__block_header__alpha__full_header_
      type: double_baking_evidence__id_017__ptnairob__block_header__alpha__full_header_
  double_baking_evidence__id_017__ptnairob__block_header__alpha__full_header_:
    seq:
    - id: double_baking_evidence__block_header__shell_
      type: double_baking_evidence__block_header__shell_
      doc: ! >-
        Shell header: Block header's shell-related content. It contains information
        such as the block level, its predecessor and timestamp.
    - id: double_baking_evidence__id_017__ptnairob__block_header__alpha__signed_contents_
      type: double_baking_evidence__id_017__ptnairob__block_header__alpha__signed_contents_
  double_baking_evidence__id_017__ptnairob__block_header__alpha__signed_contents_:
    seq:
    - id: double_baking_evidence__id_017__ptnairob__block_header__alpha__unsigned_contents_
      type: double_baking_evidence__id_017__ptnairob__block_header__alpha__unsigned_contents_
    - id: signature
      size-eos: true
  double_baking_evidence__id_017__ptnairob__block_header__alpha__unsigned_contents_:
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
  double_baking_evidence__block_header__shell_:
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
      type: double_baking_evidence__fitness_
      doc: ! >-
        Block fitness: The fitness, or score, of a block, that allow the Tezos to
        decide which chain is the best. A fitness value is a list of byte sequences.
        They are compared as follows: shortest lists are smaller; lists of the same
        length are compared according to the lexicographical order.
    - id: context
      size: 32
  double_baking_evidence__fitness_:
    seq:
    - id: len_double_baking_evidence__fitness_dyn
      type: u4
      valid:
        max: 1073741823
    - id: double_baking_evidence__fitness_dyn
      type: double_baking_evidence__fitness_dyn
      size: len_double_baking_evidence__fitness_dyn
  double_baking_evidence__fitness_dyn:
    seq:
    - id: double_baking_evidence__fitness_entries
      type: double_baking_evidence__fitness_entries
      repeat: eos
  double_baking_evidence__fitness_entries:
    seq:
    - id: double_baking_evidence__fitness__elem_
      type: double_baking_evidence__fitness__elem_
  double_baking_evidence__fitness__elem_:
    seq:
    - id: len_fitness__elem
      type: u4
      valid:
        max: 1073741823
    - id: fitness__elem
      size: len_fitness__elem
  double_preendorsement_evidence__id_017__ptnairob__operation__alpha__contents:
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
    - id: double_preendorsement_evidence__id_017__ptnairob__inlined__preendorsement_
      type: double_preendorsement_evidence__id_017__ptnairob__inlined__preendorsement_
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
    - id: double_preendorsement_evidence__id_017__ptnairob__inlined__preendorsement_
      type: double_preendorsement_evidence__id_017__ptnairob__inlined__preendorsement_
  double_preendorsement_evidence__id_017__ptnairob__inlined__preendorsement_:
    seq:
    - id: operation__shell_header
      size: 32
      doc: An operation's shell header.
    - id: operations
      type: double_preendorsement_evidence__id_017__ptnairob__inlined__preendorsement__contents_
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size-eos: true
      if: (signature_tag == bool::true)
  double_preendorsement_evidence__id_017__ptnairob__inlined__preendorsement__contents_:
    seq:
    - id: id_017__ptnairob__inlined__preendorsement__contents_tag
      type: u1
      enum: id_017__ptnairob__inlined__preendorsement__contents_tag
    - id: double_preendorsement_evidence__preendorsement__id_017__ptnairob__inlined__preendorsement__contents
      type: double_preendorsement_evidence__preendorsement__id_017__ptnairob__inlined__preendorsement__contents
      if: (id_017__ptnairob__inlined__preendorsement__contents_tag == id_017__ptnairob__inlined__preendorsement__contents_tag::preendorsement)
  double_preendorsement_evidence__preendorsement__id_017__ptnairob__inlined__preendorsement__contents:
    seq:
    - id: slot
      type: u2
    - id: level
      type: s4
    - id: round
      type: s4
    - id: block_payload_hash
      size: 32
  double_endorsement_evidence__id_017__ptnairob__operation__alpha__contents:
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
    - id: double_endorsement_evidence__id_017__ptnairob__inlined__endorsement_
      type: double_endorsement_evidence__id_017__ptnairob__inlined__endorsement_
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
    - id: double_endorsement_evidence__id_017__ptnairob__inlined__endorsement_
      type: double_endorsement_evidence__id_017__ptnairob__inlined__endorsement_
  double_endorsement_evidence__id_017__ptnairob__inlined__endorsement_:
    seq:
    - id: operation__shell_header
      size: 32
      doc: An operation's shell header.
    - id: operations
      type: double_endorsement_evidence__id_017__ptnairob__inlined__endorsement_mempool__contents_
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size-eos: true
      if: (signature_tag == bool::true)
  double_endorsement_evidence__id_017__ptnairob__inlined__endorsement_mempool__contents_:
    seq:
    - id: id_017__ptnairob__inlined__endorsement_mempool__contents_tag
      type: u1
      enum: id_017__ptnairob__inlined__endorsement_mempool__contents_tag
    - id: double_endorsement_evidence__endorsement__id_017__ptnairob__inlined__endorsement_mempool__contents
      type: double_endorsement_evidence__endorsement__id_017__ptnairob__inlined__endorsement_mempool__contents
      if: (id_017__ptnairob__inlined__endorsement_mempool__contents_tag == id_017__ptnairob__inlined__endorsement_mempool__contents_tag::endorsement)
  double_endorsement_evidence__endorsement__id_017__ptnairob__inlined__endorsement_mempool__contents:
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
  seed_nonce_revelation__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: level
      type: s4
    - id: nonce
      size: 32
  dal_attestation__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: attestor
      type: dal_attestation__public_key_hash_
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: attestation
      type: z
    - id: level
      type: s4
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
  dal_attestation__public_key_hash_:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: dal_attestation__ed25519__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::ed25519)
    - id: dal_attestation__secp256k1__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::secp256k1)
    - id: dal_attestation__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::p256)
    - id: dal_attestation__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  preendorsement__id_017__ptnairob__operation__alpha__contents:
    seq:
    - id: slot
      type: u2
    - id: level
      type: s4
    - id: round
      type: s4
    - id: block_payload_hash
      size: 32
  endorsement__id_017__ptnairob__operation__alpha__contents:
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
  zk_rollup_publish__some__prim__generic__id_017__ptnairob__michelson__v1__primitives:
    0: parameter
    1: storage
    2: code
    3:
      id: false
      doc: False
    4:
      id: elt
      doc: Elt
    5:
      id: left
      doc: Left
    6:
      id: none_
      doc: None
    7:
      id: pair__
      doc: Pair
    8:
      id: right
      doc: Right
    9:
      id: some_
      doc: Some
    10:
      id: true
      doc: True
    11:
      id: unit_
      doc: Unit
    12:
      id: pack
      doc: PACK
    13:
      id: unpack
      doc: UNPACK
    14:
      id: blake2b
      doc: BLAKE2B
    15:
      id: sha256
      doc: SHA256
    16:
      id: sha512
      doc: SHA512
    17:
      id: abs
      doc: ABS
    18:
      id: add
      doc: ADD
    19:
      id: amount
      doc: AMOUNT
    20:
      id: and
      doc: AND
    21:
      id: balance
      doc: BALANCE
    22:
      id: car
      doc: CAR
    23:
      id: cdr
      doc: CDR
    24:
      id: check_signature
      doc: CHECK_SIGNATURE
    25:
      id: compare
      doc: COMPARE
    26:
      id: concat
      doc: CONCAT
    27:
      id: cons
      doc: CONS
    28:
      id: create_account
      doc: CREATE_ACCOUNT
    29:
      id: create_contract
      doc: CREATE_CONTRACT
    30:
      id: implicit_account
      doc: IMPLICIT_ACCOUNT
    31:
      id: dip
      doc: DIP
    32:
      id: drop
      doc: DROP
    33:
      id: dup
      doc: DUP
    34:
      id: ediv
      doc: EDIV
    35:
      id: empty_map
      doc: EMPTY_MAP
    36:
      id: empty_set
      doc: EMPTY_SET
    37:
      id: eq
      doc: EQ
    38:
      id: exec
      doc: EXEC
    39:
      id: failwith
      doc: FAILWITH
    40:
      id: ge
      doc: GE
    41:
      id: get
      doc: GET
    42:
      id: gt
      doc: GT
    43:
      id: hash_key
      doc: HASH_KEY
    44:
      id: if
      doc: IF
    45:
      id: if_cons
      doc: IF_CONS
    46:
      id: if_left
      doc: IF_LEFT
    47:
      id: if_none
      doc: IF_NONE
    48:
      id: int_
      doc: INT
    49:
      id: lambda_
      doc: LAMBDA
    50:
      id: le
      doc: LE
    51:
      id: left_
      doc: LEFT
    52:
      id: loop
      doc: LOOP
    53:
      id: lsl
      doc: LSL
    54:
      id: lsr
      doc: LSR
    55:
      id: lt
      doc: LT
    56:
      id: map_
      doc: MAP
    57:
      id: mem
      doc: MEM
    58:
      id: mul
      doc: MUL
    59:
      id: neg
      doc: NEG
    60:
      id: neq
      doc: NEQ
    61:
      id: nil
      doc: NIL
    62:
      id: none
      doc: NONE
    63:
      id: not
      doc: NOT
    64:
      id: now
      doc: NOW
    65:
      id: or_
      doc: OR
    66:
      id: pair_
      doc: PAIR
    67:
      id: push
      doc: PUSH
    68:
      id: right_
      doc: RIGHT
    69:
      id: size
      doc: SIZE
    70:
      id: some
      doc: SOME
    71:
      id: source
      doc: SOURCE
    72:
      id: sender
      doc: SENDER
    73:
      id: self
      doc: SELF
    74:
      id: steps_to_quota
      doc: STEPS_TO_QUOTA
    75:
      id: sub
      doc: SUB
    76:
      id: swap
      doc: SWAP
    77:
      id: transfer_tokens
      doc: TRANSFER_TOKENS
    78:
      id: set_delegate
      doc: SET_DELEGATE
    79:
      id: unit__
      doc: UNIT
    80:
      id: update
      doc: UPDATE
    81:
      id: xor
      doc: XOR
    82:
      id: iter
      doc: ITER
    83:
      id: loop_left
      doc: LOOP_LEFT
    84:
      id: address_
      doc: ADDRESS
    85:
      id: contract_
      doc: CONTRACT
    86:
      id: isnat
      doc: ISNAT
    87:
      id: cast
      doc: CAST
    88:
      id: rename
      doc: RENAME
    89: bool
    90: contract
    91: int
    92: key
    93: key_hash
    94: lambda
    95: list
    96: map
    97: big_map
    98: nat
    99: option
    100: or
    101: pair
    102: set
    103: signature
    104: string
    105: bytes
    106: mutez
    107: timestamp
    108: unit
    109: operation
    110: address
    111:
      id: slice
      doc: SLICE
    112:
      id: dig
      doc: DIG
    113:
      id: dug
      doc: DUG
    114:
      id: empty_big_map
      doc: EMPTY_BIG_MAP
    115:
      id: apply
      doc: APPLY
    116: chain_id
    117:
      id: chain_id_
      doc: CHAIN_ID
    118:
      id: level
      doc: LEVEL
    119:
      id: self_address
      doc: SELF_ADDRESS
    120: never
    121:
      id: never_
      doc: NEVER
    122:
      id: unpair
      doc: UNPAIR
    123:
      id: voting_power
      doc: VOTING_POWER
    124:
      id: total_voting_power
      doc: TOTAL_VOTING_POWER
    125:
      id: keccak
      doc: KECCAK
    126:
      id: sha3
      doc: SHA3
    127:
      id: pairing_check
      doc: PAIRING_CHECK
    128: bls12_381_g1
    129: bls12_381_g2
    130: bls12_381_fr
    131: sapling_state
    132: sapling_transaction_deprecated
    133:
      id: sapling_empty_state
      doc: SAPLING_EMPTY_STATE
    134:
      id: sapling_verify_update
      doc: SAPLING_VERIFY_UPDATE
    135: ticket
    136:
      id: ticket_deprecated
      doc: TICKET_DEPRECATED
    137:
      id: read_ticket
      doc: READ_TICKET
    138:
      id: split_ticket
      doc: SPLIT_TICKET
    139:
      id: join_tickets
      doc: JOIN_TICKETS
    140:
      id: get_and_update
      doc: GET_AND_UPDATE
    141: chest
    142: chest_key
    143:
      id: open_chest
      doc: OPEN_CHEST
    144:
      id: view_
      doc: VIEW
    145: view
    146: constant
    147:
      id: sub_mutez
      doc: SUB_MUTEZ
    148: tx_rollup_l2_address
    149:
      id: min_block_time
      doc: MIN_BLOCK_TIME
    150: sapling_transaction
    151:
      id: emit
      doc: EMIT
    152:
      id: lambda_rec
      doc: Lambda_rec
    153:
      id: lambda_rec_
      doc: LAMBDA_REC
    154:
      id: ticket_
      doc: TICKET
    155:
      id: bytes_
      doc: BYTES
    156:
      id: nat_
      doc: NAT
  zk_rollup_publish__some__prim__2_args__some_annots__id_017__ptnairob__michelson__v1__primitives:
    0: parameter
    1: storage
    2: code
    3:
      id: false
      doc: False
    4:
      id: elt
      doc: Elt
    5:
      id: left
      doc: Left
    6:
      id: none_
      doc: None
    7:
      id: pair__
      doc: Pair
    8:
      id: right
      doc: Right
    9:
      id: some_
      doc: Some
    10:
      id: true
      doc: True
    11:
      id: unit_
      doc: Unit
    12:
      id: pack
      doc: PACK
    13:
      id: unpack
      doc: UNPACK
    14:
      id: blake2b
      doc: BLAKE2B
    15:
      id: sha256
      doc: SHA256
    16:
      id: sha512
      doc: SHA512
    17:
      id: abs
      doc: ABS
    18:
      id: add
      doc: ADD
    19:
      id: amount
      doc: AMOUNT
    20:
      id: and
      doc: AND
    21:
      id: balance
      doc: BALANCE
    22:
      id: car
      doc: CAR
    23:
      id: cdr
      doc: CDR
    24:
      id: check_signature
      doc: CHECK_SIGNATURE
    25:
      id: compare
      doc: COMPARE
    26:
      id: concat
      doc: CONCAT
    27:
      id: cons
      doc: CONS
    28:
      id: create_account
      doc: CREATE_ACCOUNT
    29:
      id: create_contract
      doc: CREATE_CONTRACT
    30:
      id: implicit_account
      doc: IMPLICIT_ACCOUNT
    31:
      id: dip
      doc: DIP
    32:
      id: drop
      doc: DROP
    33:
      id: dup
      doc: DUP
    34:
      id: ediv
      doc: EDIV
    35:
      id: empty_map
      doc: EMPTY_MAP
    36:
      id: empty_set
      doc: EMPTY_SET
    37:
      id: eq
      doc: EQ
    38:
      id: exec
      doc: EXEC
    39:
      id: failwith
      doc: FAILWITH
    40:
      id: ge
      doc: GE
    41:
      id: get
      doc: GET
    42:
      id: gt
      doc: GT
    43:
      id: hash_key
      doc: HASH_KEY
    44:
      id: if
      doc: IF
    45:
      id: if_cons
      doc: IF_CONS
    46:
      id: if_left
      doc: IF_LEFT
    47:
      id: if_none
      doc: IF_NONE
    48:
      id: int_
      doc: INT
    49:
      id: lambda_
      doc: LAMBDA
    50:
      id: le
      doc: LE
    51:
      id: left_
      doc: LEFT
    52:
      id: loop
      doc: LOOP
    53:
      id: lsl
      doc: LSL
    54:
      id: lsr
      doc: LSR
    55:
      id: lt
      doc: LT
    56:
      id: map_
      doc: MAP
    57:
      id: mem
      doc: MEM
    58:
      id: mul
      doc: MUL
    59:
      id: neg
      doc: NEG
    60:
      id: neq
      doc: NEQ
    61:
      id: nil
      doc: NIL
    62:
      id: none
      doc: NONE
    63:
      id: not
      doc: NOT
    64:
      id: now
      doc: NOW
    65:
      id: or_
      doc: OR
    66:
      id: pair_
      doc: PAIR
    67:
      id: push
      doc: PUSH
    68:
      id: right_
      doc: RIGHT
    69:
      id: size
      doc: SIZE
    70:
      id: some
      doc: SOME
    71:
      id: source
      doc: SOURCE
    72:
      id: sender
      doc: SENDER
    73:
      id: self
      doc: SELF
    74:
      id: steps_to_quota
      doc: STEPS_TO_QUOTA
    75:
      id: sub
      doc: SUB
    76:
      id: swap
      doc: SWAP
    77:
      id: transfer_tokens
      doc: TRANSFER_TOKENS
    78:
      id: set_delegate
      doc: SET_DELEGATE
    79:
      id: unit__
      doc: UNIT
    80:
      id: update
      doc: UPDATE
    81:
      id: xor
      doc: XOR
    82:
      id: iter
      doc: ITER
    83:
      id: loop_left
      doc: LOOP_LEFT
    84:
      id: address_
      doc: ADDRESS
    85:
      id: contract_
      doc: CONTRACT
    86:
      id: isnat
      doc: ISNAT
    87:
      id: cast
      doc: CAST
    88:
      id: rename
      doc: RENAME
    89: bool
    90: contract
    91: int
    92: key
    93: key_hash
    94: lambda
    95: list
    96: map
    97: big_map
    98: nat
    99: option
    100: or
    101: pair
    102: set
    103: signature
    104: string
    105: bytes
    106: mutez
    107: timestamp
    108: unit
    109: operation
    110: address
    111:
      id: slice
      doc: SLICE
    112:
      id: dig
      doc: DIG
    113:
      id: dug
      doc: DUG
    114:
      id: empty_big_map
      doc: EMPTY_BIG_MAP
    115:
      id: apply
      doc: APPLY
    116: chain_id
    117:
      id: chain_id_
      doc: CHAIN_ID
    118:
      id: level
      doc: LEVEL
    119:
      id: self_address
      doc: SELF_ADDRESS
    120: never
    121:
      id: never_
      doc: NEVER
    122:
      id: unpair
      doc: UNPAIR
    123:
      id: voting_power
      doc: VOTING_POWER
    124:
      id: total_voting_power
      doc: TOTAL_VOTING_POWER
    125:
      id: keccak
      doc: KECCAK
    126:
      id: sha3
      doc: SHA3
    127:
      id: pairing_check
      doc: PAIRING_CHECK
    128: bls12_381_g1
    129: bls12_381_g2
    130: bls12_381_fr
    131: sapling_state
    132: sapling_transaction_deprecated
    133:
      id: sapling_empty_state
      doc: SAPLING_EMPTY_STATE
    134:
      id: sapling_verify_update
      doc: SAPLING_VERIFY_UPDATE
    135: ticket
    136:
      id: ticket_deprecated
      doc: TICKET_DEPRECATED
    137:
      id: read_ticket
      doc: READ_TICKET
    138:
      id: split_ticket
      doc: SPLIT_TICKET
    139:
      id: join_tickets
      doc: JOIN_TICKETS
    140:
      id: get_and_update
      doc: GET_AND_UPDATE
    141: chest
    142: chest_key
    143:
      id: open_chest
      doc: OPEN_CHEST
    144:
      id: view_
      doc: VIEW
    145: view
    146: constant
    147:
      id: sub_mutez
      doc: SUB_MUTEZ
    148: tx_rollup_l2_address
    149:
      id: min_block_time
      doc: MIN_BLOCK_TIME
    150: sapling_transaction
    151:
      id: emit
      doc: EMIT
    152:
      id: lambda_rec
      doc: Lambda_rec
    153:
      id: lambda_rec_
      doc: LAMBDA_REC
    154:
      id: ticket_
      doc: TICKET
    155:
      id: bytes_
      doc: BYTES
    156:
      id: nat_
      doc: NAT
  zk_rollup_publish__some__prim__2_args__no_annots__id_017__ptnairob__michelson__v1__primitives:
    0: parameter
    1: storage
    2: code
    3:
      id: false
      doc: False
    4:
      id: elt
      doc: Elt
    5:
      id: left
      doc: Left
    6:
      id: none_
      doc: None
    7:
      id: pair__
      doc: Pair
    8:
      id: right
      doc: Right
    9:
      id: some_
      doc: Some
    10:
      id: true
      doc: True
    11:
      id: unit_
      doc: Unit
    12:
      id: pack
      doc: PACK
    13:
      id: unpack
      doc: UNPACK
    14:
      id: blake2b
      doc: BLAKE2B
    15:
      id: sha256
      doc: SHA256
    16:
      id: sha512
      doc: SHA512
    17:
      id: abs
      doc: ABS
    18:
      id: add
      doc: ADD
    19:
      id: amount
      doc: AMOUNT
    20:
      id: and
      doc: AND
    21:
      id: balance
      doc: BALANCE
    22:
      id: car
      doc: CAR
    23:
      id: cdr
      doc: CDR
    24:
      id: check_signature
      doc: CHECK_SIGNATURE
    25:
      id: compare
      doc: COMPARE
    26:
      id: concat
      doc: CONCAT
    27:
      id: cons
      doc: CONS
    28:
      id: create_account
      doc: CREATE_ACCOUNT
    29:
      id: create_contract
      doc: CREATE_CONTRACT
    30:
      id: implicit_account
      doc: IMPLICIT_ACCOUNT
    31:
      id: dip
      doc: DIP
    32:
      id: drop
      doc: DROP
    33:
      id: dup
      doc: DUP
    34:
      id: ediv
      doc: EDIV
    35:
      id: empty_map
      doc: EMPTY_MAP
    36:
      id: empty_set
      doc: EMPTY_SET
    37:
      id: eq
      doc: EQ
    38:
      id: exec
      doc: EXEC
    39:
      id: failwith
      doc: FAILWITH
    40:
      id: ge
      doc: GE
    41:
      id: get
      doc: GET
    42:
      id: gt
      doc: GT
    43:
      id: hash_key
      doc: HASH_KEY
    44:
      id: if
      doc: IF
    45:
      id: if_cons
      doc: IF_CONS
    46:
      id: if_left
      doc: IF_LEFT
    47:
      id: if_none
      doc: IF_NONE
    48:
      id: int_
      doc: INT
    49:
      id: lambda_
      doc: LAMBDA
    50:
      id: le
      doc: LE
    51:
      id: left_
      doc: LEFT
    52:
      id: loop
      doc: LOOP
    53:
      id: lsl
      doc: LSL
    54:
      id: lsr
      doc: LSR
    55:
      id: lt
      doc: LT
    56:
      id: map_
      doc: MAP
    57:
      id: mem
      doc: MEM
    58:
      id: mul
      doc: MUL
    59:
      id: neg
      doc: NEG
    60:
      id: neq
      doc: NEQ
    61:
      id: nil
      doc: NIL
    62:
      id: none
      doc: NONE
    63:
      id: not
      doc: NOT
    64:
      id: now
      doc: NOW
    65:
      id: or_
      doc: OR
    66:
      id: pair_
      doc: PAIR
    67:
      id: push
      doc: PUSH
    68:
      id: right_
      doc: RIGHT
    69:
      id: size
      doc: SIZE
    70:
      id: some
      doc: SOME
    71:
      id: source
      doc: SOURCE
    72:
      id: sender
      doc: SENDER
    73:
      id: self
      doc: SELF
    74:
      id: steps_to_quota
      doc: STEPS_TO_QUOTA
    75:
      id: sub
      doc: SUB
    76:
      id: swap
      doc: SWAP
    77:
      id: transfer_tokens
      doc: TRANSFER_TOKENS
    78:
      id: set_delegate
      doc: SET_DELEGATE
    79:
      id: unit__
      doc: UNIT
    80:
      id: update
      doc: UPDATE
    81:
      id: xor
      doc: XOR
    82:
      id: iter
      doc: ITER
    83:
      id: loop_left
      doc: LOOP_LEFT
    84:
      id: address_
      doc: ADDRESS
    85:
      id: contract_
      doc: CONTRACT
    86:
      id: isnat
      doc: ISNAT
    87:
      id: cast
      doc: CAST
    88:
      id: rename
      doc: RENAME
    89: bool
    90: contract
    91: int
    92: key
    93: key_hash
    94: lambda
    95: list
    96: map
    97: big_map
    98: nat
    99: option
    100: or
    101: pair
    102: set
    103: signature
    104: string
    105: bytes
    106: mutez
    107: timestamp
    108: unit
    109: operation
    110: address
    111:
      id: slice
      doc: SLICE
    112:
      id: dig
      doc: DIG
    113:
      id: dug
      doc: DUG
    114:
      id: empty_big_map
      doc: EMPTY_BIG_MAP
    115:
      id: apply
      doc: APPLY
    116: chain_id
    117:
      id: chain_id_
      doc: CHAIN_ID
    118:
      id: level
      doc: LEVEL
    119:
      id: self_address
      doc: SELF_ADDRESS
    120: never
    121:
      id: never_
      doc: NEVER
    122:
      id: unpair
      doc: UNPAIR
    123:
      id: voting_power
      doc: VOTING_POWER
    124:
      id: total_voting_power
      doc: TOTAL_VOTING_POWER
    125:
      id: keccak
      doc: KECCAK
    126:
      id: sha3
      doc: SHA3
    127:
      id: pairing_check
      doc: PAIRING_CHECK
    128: bls12_381_g1
    129: bls12_381_g2
    130: bls12_381_fr
    131: sapling_state
    132: sapling_transaction_deprecated
    133:
      id: sapling_empty_state
      doc: SAPLING_EMPTY_STATE
    134:
      id: sapling_verify_update
      doc: SAPLING_VERIFY_UPDATE
    135: ticket
    136:
      id: ticket_deprecated
      doc: TICKET_DEPRECATED
    137:
      id: read_ticket
      doc: READ_TICKET
    138:
      id: split_ticket
      doc: SPLIT_TICKET
    139:
      id: join_tickets
      doc: JOIN_TICKETS
    140:
      id: get_and_update
      doc: GET_AND_UPDATE
    141: chest
    142: chest_key
    143:
      id: open_chest
      doc: OPEN_CHEST
    144:
      id: view_
      doc: VIEW
    145: view
    146: constant
    147:
      id: sub_mutez
      doc: SUB_MUTEZ
    148: tx_rollup_l2_address
    149:
      id: min_block_time
      doc: MIN_BLOCK_TIME
    150: sapling_transaction
    151:
      id: emit
      doc: EMIT
    152:
      id: lambda_rec
      doc: Lambda_rec
    153:
      id: lambda_rec_
      doc: LAMBDA_REC
    154:
      id: ticket_
      doc: TICKET
    155:
      id: bytes_
      doc: BYTES
    156:
      id: nat_
      doc: NAT
  zk_rollup_publish__some__prim__1_arg__some_annots__id_017__ptnairob__michelson__v1__primitives:
    0: parameter
    1: storage
    2: code
    3:
      id: false
      doc: False
    4:
      id: elt
      doc: Elt
    5:
      id: left
      doc: Left
    6:
      id: none_
      doc: None
    7:
      id: pair__
      doc: Pair
    8:
      id: right
      doc: Right
    9:
      id: some_
      doc: Some
    10:
      id: true
      doc: True
    11:
      id: unit_
      doc: Unit
    12:
      id: pack
      doc: PACK
    13:
      id: unpack
      doc: UNPACK
    14:
      id: blake2b
      doc: BLAKE2B
    15:
      id: sha256
      doc: SHA256
    16:
      id: sha512
      doc: SHA512
    17:
      id: abs
      doc: ABS
    18:
      id: add
      doc: ADD
    19:
      id: amount
      doc: AMOUNT
    20:
      id: and
      doc: AND
    21:
      id: balance
      doc: BALANCE
    22:
      id: car
      doc: CAR
    23:
      id: cdr
      doc: CDR
    24:
      id: check_signature
      doc: CHECK_SIGNATURE
    25:
      id: compare
      doc: COMPARE
    26:
      id: concat
      doc: CONCAT
    27:
      id: cons
      doc: CONS
    28:
      id: create_account
      doc: CREATE_ACCOUNT
    29:
      id: create_contract
      doc: CREATE_CONTRACT
    30:
      id: implicit_account
      doc: IMPLICIT_ACCOUNT
    31:
      id: dip
      doc: DIP
    32:
      id: drop
      doc: DROP
    33:
      id: dup
      doc: DUP
    34:
      id: ediv
      doc: EDIV
    35:
      id: empty_map
      doc: EMPTY_MAP
    36:
      id: empty_set
      doc: EMPTY_SET
    37:
      id: eq
      doc: EQ
    38:
      id: exec
      doc: EXEC
    39:
      id: failwith
      doc: FAILWITH
    40:
      id: ge
      doc: GE
    41:
      id: get
      doc: GET
    42:
      id: gt
      doc: GT
    43:
      id: hash_key
      doc: HASH_KEY
    44:
      id: if
      doc: IF
    45:
      id: if_cons
      doc: IF_CONS
    46:
      id: if_left
      doc: IF_LEFT
    47:
      id: if_none
      doc: IF_NONE
    48:
      id: int_
      doc: INT
    49:
      id: lambda_
      doc: LAMBDA
    50:
      id: le
      doc: LE
    51:
      id: left_
      doc: LEFT
    52:
      id: loop
      doc: LOOP
    53:
      id: lsl
      doc: LSL
    54:
      id: lsr
      doc: LSR
    55:
      id: lt
      doc: LT
    56:
      id: map_
      doc: MAP
    57:
      id: mem
      doc: MEM
    58:
      id: mul
      doc: MUL
    59:
      id: neg
      doc: NEG
    60:
      id: neq
      doc: NEQ
    61:
      id: nil
      doc: NIL
    62:
      id: none
      doc: NONE
    63:
      id: not
      doc: NOT
    64:
      id: now
      doc: NOW
    65:
      id: or_
      doc: OR
    66:
      id: pair_
      doc: PAIR
    67:
      id: push
      doc: PUSH
    68:
      id: right_
      doc: RIGHT
    69:
      id: size
      doc: SIZE
    70:
      id: some
      doc: SOME
    71:
      id: source
      doc: SOURCE
    72:
      id: sender
      doc: SENDER
    73:
      id: self
      doc: SELF
    74:
      id: steps_to_quota
      doc: STEPS_TO_QUOTA
    75:
      id: sub
      doc: SUB
    76:
      id: swap
      doc: SWAP
    77:
      id: transfer_tokens
      doc: TRANSFER_TOKENS
    78:
      id: set_delegate
      doc: SET_DELEGATE
    79:
      id: unit__
      doc: UNIT
    80:
      id: update
      doc: UPDATE
    81:
      id: xor
      doc: XOR
    82:
      id: iter
      doc: ITER
    83:
      id: loop_left
      doc: LOOP_LEFT
    84:
      id: address_
      doc: ADDRESS
    85:
      id: contract_
      doc: CONTRACT
    86:
      id: isnat
      doc: ISNAT
    87:
      id: cast
      doc: CAST
    88:
      id: rename
      doc: RENAME
    89: bool
    90: contract
    91: int
    92: key
    93: key_hash
    94: lambda
    95: list
    96: map
    97: big_map
    98: nat
    99: option
    100: or
    101: pair
    102: set
    103: signature
    104: string
    105: bytes
    106: mutez
    107: timestamp
    108: unit
    109: operation
    110: address
    111:
      id: slice
      doc: SLICE
    112:
      id: dig
      doc: DIG
    113:
      id: dug
      doc: DUG
    114:
      id: empty_big_map
      doc: EMPTY_BIG_MAP
    115:
      id: apply
      doc: APPLY
    116: chain_id
    117:
      id: chain_id_
      doc: CHAIN_ID
    118:
      id: level
      doc: LEVEL
    119:
      id: self_address
      doc: SELF_ADDRESS
    120: never
    121:
      id: never_
      doc: NEVER
    122:
      id: unpair
      doc: UNPAIR
    123:
      id: voting_power
      doc: VOTING_POWER
    124:
      id: total_voting_power
      doc: TOTAL_VOTING_POWER
    125:
      id: keccak
      doc: KECCAK
    126:
      id: sha3
      doc: SHA3
    127:
      id: pairing_check
      doc: PAIRING_CHECK
    128: bls12_381_g1
    129: bls12_381_g2
    130: bls12_381_fr
    131: sapling_state
    132: sapling_transaction_deprecated
    133:
      id: sapling_empty_state
      doc: SAPLING_EMPTY_STATE
    134:
      id: sapling_verify_update
      doc: SAPLING_VERIFY_UPDATE
    135: ticket
    136:
      id: ticket_deprecated
      doc: TICKET_DEPRECATED
    137:
      id: read_ticket
      doc: READ_TICKET
    138:
      id: split_ticket
      doc: SPLIT_TICKET
    139:
      id: join_tickets
      doc: JOIN_TICKETS
    140:
      id: get_and_update
      doc: GET_AND_UPDATE
    141: chest
    142: chest_key
    143:
      id: open_chest
      doc: OPEN_CHEST
    144:
      id: view_
      doc: VIEW
    145: view
    146: constant
    147:
      id: sub_mutez
      doc: SUB_MUTEZ
    148: tx_rollup_l2_address
    149:
      id: min_block_time
      doc: MIN_BLOCK_TIME
    150: sapling_transaction
    151:
      id: emit
      doc: EMIT
    152:
      id: lambda_rec
      doc: Lambda_rec
    153:
      id: lambda_rec_
      doc: LAMBDA_REC
    154:
      id: ticket_
      doc: TICKET
    155:
      id: bytes_
      doc: BYTES
    156:
      id: nat_
      doc: NAT
  zk_rollup_publish__some__prim__1_arg__no_annots__id_017__ptnairob__michelson__v1__primitives:
    0: parameter
    1: storage
    2: code
    3:
      id: false
      doc: False
    4:
      id: elt
      doc: Elt
    5:
      id: left
      doc: Left
    6:
      id: none_
      doc: None
    7:
      id: pair__
      doc: Pair
    8:
      id: right
      doc: Right
    9:
      id: some_
      doc: Some
    10:
      id: true
      doc: True
    11:
      id: unit_
      doc: Unit
    12:
      id: pack
      doc: PACK
    13:
      id: unpack
      doc: UNPACK
    14:
      id: blake2b
      doc: BLAKE2B
    15:
      id: sha256
      doc: SHA256
    16:
      id: sha512
      doc: SHA512
    17:
      id: abs
      doc: ABS
    18:
      id: add
      doc: ADD
    19:
      id: amount
      doc: AMOUNT
    20:
      id: and
      doc: AND
    21:
      id: balance
      doc: BALANCE
    22:
      id: car
      doc: CAR
    23:
      id: cdr
      doc: CDR
    24:
      id: check_signature
      doc: CHECK_SIGNATURE
    25:
      id: compare
      doc: COMPARE
    26:
      id: concat
      doc: CONCAT
    27:
      id: cons
      doc: CONS
    28:
      id: create_account
      doc: CREATE_ACCOUNT
    29:
      id: create_contract
      doc: CREATE_CONTRACT
    30:
      id: implicit_account
      doc: IMPLICIT_ACCOUNT
    31:
      id: dip
      doc: DIP
    32:
      id: drop
      doc: DROP
    33:
      id: dup
      doc: DUP
    34:
      id: ediv
      doc: EDIV
    35:
      id: empty_map
      doc: EMPTY_MAP
    36:
      id: empty_set
      doc: EMPTY_SET
    37:
      id: eq
      doc: EQ
    38:
      id: exec
      doc: EXEC
    39:
      id: failwith
      doc: FAILWITH
    40:
      id: ge
      doc: GE
    41:
      id: get
      doc: GET
    42:
      id: gt
      doc: GT
    43:
      id: hash_key
      doc: HASH_KEY
    44:
      id: if
      doc: IF
    45:
      id: if_cons
      doc: IF_CONS
    46:
      id: if_left
      doc: IF_LEFT
    47:
      id: if_none
      doc: IF_NONE
    48:
      id: int_
      doc: INT
    49:
      id: lambda_
      doc: LAMBDA
    50:
      id: le
      doc: LE
    51:
      id: left_
      doc: LEFT
    52:
      id: loop
      doc: LOOP
    53:
      id: lsl
      doc: LSL
    54:
      id: lsr
      doc: LSR
    55:
      id: lt
      doc: LT
    56:
      id: map_
      doc: MAP
    57:
      id: mem
      doc: MEM
    58:
      id: mul
      doc: MUL
    59:
      id: neg
      doc: NEG
    60:
      id: neq
      doc: NEQ
    61:
      id: nil
      doc: NIL
    62:
      id: none
      doc: NONE
    63:
      id: not
      doc: NOT
    64:
      id: now
      doc: NOW
    65:
      id: or_
      doc: OR
    66:
      id: pair_
      doc: PAIR
    67:
      id: push
      doc: PUSH
    68:
      id: right_
      doc: RIGHT
    69:
      id: size
      doc: SIZE
    70:
      id: some
      doc: SOME
    71:
      id: source
      doc: SOURCE
    72:
      id: sender
      doc: SENDER
    73:
      id: self
      doc: SELF
    74:
      id: steps_to_quota
      doc: STEPS_TO_QUOTA
    75:
      id: sub
      doc: SUB
    76:
      id: swap
      doc: SWAP
    77:
      id: transfer_tokens
      doc: TRANSFER_TOKENS
    78:
      id: set_delegate
      doc: SET_DELEGATE
    79:
      id: unit__
      doc: UNIT
    80:
      id: update
      doc: UPDATE
    81:
      id: xor
      doc: XOR
    82:
      id: iter
      doc: ITER
    83:
      id: loop_left
      doc: LOOP_LEFT
    84:
      id: address_
      doc: ADDRESS
    85:
      id: contract_
      doc: CONTRACT
    86:
      id: isnat
      doc: ISNAT
    87:
      id: cast
      doc: CAST
    88:
      id: rename
      doc: RENAME
    89: bool
    90: contract
    91: int
    92: key
    93: key_hash
    94: lambda
    95: list
    96: map
    97: big_map
    98: nat
    99: option
    100: or
    101: pair
    102: set
    103: signature
    104: string
    105: bytes
    106: mutez
    107: timestamp
    108: unit
    109: operation
    110: address
    111:
      id: slice
      doc: SLICE
    112:
      id: dig
      doc: DIG
    113:
      id: dug
      doc: DUG
    114:
      id: empty_big_map
      doc: EMPTY_BIG_MAP
    115:
      id: apply
      doc: APPLY
    116: chain_id
    117:
      id: chain_id_
      doc: CHAIN_ID
    118:
      id: level
      doc: LEVEL
    119:
      id: self_address
      doc: SELF_ADDRESS
    120: never
    121:
      id: never_
      doc: NEVER
    122:
      id: unpair
      doc: UNPAIR
    123:
      id: voting_power
      doc: VOTING_POWER
    124:
      id: total_voting_power
      doc: TOTAL_VOTING_POWER
    125:
      id: keccak
      doc: KECCAK
    126:
      id: sha3
      doc: SHA3
    127:
      id: pairing_check
      doc: PAIRING_CHECK
    128: bls12_381_g1
    129: bls12_381_g2
    130: bls12_381_fr
    131: sapling_state
    132: sapling_transaction_deprecated
    133:
      id: sapling_empty_state
      doc: SAPLING_EMPTY_STATE
    134:
      id: sapling_verify_update
      doc: SAPLING_VERIFY_UPDATE
    135: ticket
    136:
      id: ticket_deprecated
      doc: TICKET_DEPRECATED
    137:
      id: read_ticket
      doc: READ_TICKET
    138:
      id: split_ticket
      doc: SPLIT_TICKET
    139:
      id: join_tickets
      doc: JOIN_TICKETS
    140:
      id: get_and_update
      doc: GET_AND_UPDATE
    141: chest
    142: chest_key
    143:
      id: open_chest
      doc: OPEN_CHEST
    144:
      id: view_
      doc: VIEW
    145: view
    146: constant
    147:
      id: sub_mutez
      doc: SUB_MUTEZ
    148: tx_rollup_l2_address
    149:
      id: min_block_time
      doc: MIN_BLOCK_TIME
    150: sapling_transaction
    151:
      id: emit
      doc: EMIT
    152:
      id: lambda_rec
      doc: Lambda_rec
    153:
      id: lambda_rec_
      doc: LAMBDA_REC
    154:
      id: ticket_
      doc: TICKET
    155:
      id: bytes_
      doc: BYTES
    156:
      id: nat_
      doc: NAT
  zk_rollup_publish__some__prim__no_args__some_annots__id_017__ptnairob__michelson__v1__primitives:
    0: parameter
    1: storage
    2: code
    3:
      id: false
      doc: False
    4:
      id: elt
      doc: Elt
    5:
      id: left
      doc: Left
    6:
      id: none_
      doc: None
    7:
      id: pair__
      doc: Pair
    8:
      id: right
      doc: Right
    9:
      id: some_
      doc: Some
    10:
      id: true
      doc: True
    11:
      id: unit_
      doc: Unit
    12:
      id: pack
      doc: PACK
    13:
      id: unpack
      doc: UNPACK
    14:
      id: blake2b
      doc: BLAKE2B
    15:
      id: sha256
      doc: SHA256
    16:
      id: sha512
      doc: SHA512
    17:
      id: abs
      doc: ABS
    18:
      id: add
      doc: ADD
    19:
      id: amount
      doc: AMOUNT
    20:
      id: and
      doc: AND
    21:
      id: balance
      doc: BALANCE
    22:
      id: car
      doc: CAR
    23:
      id: cdr
      doc: CDR
    24:
      id: check_signature
      doc: CHECK_SIGNATURE
    25:
      id: compare
      doc: COMPARE
    26:
      id: concat
      doc: CONCAT
    27:
      id: cons
      doc: CONS
    28:
      id: create_account
      doc: CREATE_ACCOUNT
    29:
      id: create_contract
      doc: CREATE_CONTRACT
    30:
      id: implicit_account
      doc: IMPLICIT_ACCOUNT
    31:
      id: dip
      doc: DIP
    32:
      id: drop
      doc: DROP
    33:
      id: dup
      doc: DUP
    34:
      id: ediv
      doc: EDIV
    35:
      id: empty_map
      doc: EMPTY_MAP
    36:
      id: empty_set
      doc: EMPTY_SET
    37:
      id: eq
      doc: EQ
    38:
      id: exec
      doc: EXEC
    39:
      id: failwith
      doc: FAILWITH
    40:
      id: ge
      doc: GE
    41:
      id: get
      doc: GET
    42:
      id: gt
      doc: GT
    43:
      id: hash_key
      doc: HASH_KEY
    44:
      id: if
      doc: IF
    45:
      id: if_cons
      doc: IF_CONS
    46:
      id: if_left
      doc: IF_LEFT
    47:
      id: if_none
      doc: IF_NONE
    48:
      id: int_
      doc: INT
    49:
      id: lambda_
      doc: LAMBDA
    50:
      id: le
      doc: LE
    51:
      id: left_
      doc: LEFT
    52:
      id: loop
      doc: LOOP
    53:
      id: lsl
      doc: LSL
    54:
      id: lsr
      doc: LSR
    55:
      id: lt
      doc: LT
    56:
      id: map_
      doc: MAP
    57:
      id: mem
      doc: MEM
    58:
      id: mul
      doc: MUL
    59:
      id: neg
      doc: NEG
    60:
      id: neq
      doc: NEQ
    61:
      id: nil
      doc: NIL
    62:
      id: none
      doc: NONE
    63:
      id: not
      doc: NOT
    64:
      id: now
      doc: NOW
    65:
      id: or_
      doc: OR
    66:
      id: pair_
      doc: PAIR
    67:
      id: push
      doc: PUSH
    68:
      id: right_
      doc: RIGHT
    69:
      id: size
      doc: SIZE
    70:
      id: some
      doc: SOME
    71:
      id: source
      doc: SOURCE
    72:
      id: sender
      doc: SENDER
    73:
      id: self
      doc: SELF
    74:
      id: steps_to_quota
      doc: STEPS_TO_QUOTA
    75:
      id: sub
      doc: SUB
    76:
      id: swap
      doc: SWAP
    77:
      id: transfer_tokens
      doc: TRANSFER_TOKENS
    78:
      id: set_delegate
      doc: SET_DELEGATE
    79:
      id: unit__
      doc: UNIT
    80:
      id: update
      doc: UPDATE
    81:
      id: xor
      doc: XOR
    82:
      id: iter
      doc: ITER
    83:
      id: loop_left
      doc: LOOP_LEFT
    84:
      id: address_
      doc: ADDRESS
    85:
      id: contract_
      doc: CONTRACT
    86:
      id: isnat
      doc: ISNAT
    87:
      id: cast
      doc: CAST
    88:
      id: rename
      doc: RENAME
    89: bool
    90: contract
    91: int
    92: key
    93: key_hash
    94: lambda
    95: list
    96: map
    97: big_map
    98: nat
    99: option
    100: or
    101: pair
    102: set
    103: signature
    104: string
    105: bytes
    106: mutez
    107: timestamp
    108: unit
    109: operation
    110: address
    111:
      id: slice
      doc: SLICE
    112:
      id: dig
      doc: DIG
    113:
      id: dug
      doc: DUG
    114:
      id: empty_big_map
      doc: EMPTY_BIG_MAP
    115:
      id: apply
      doc: APPLY
    116: chain_id
    117:
      id: chain_id_
      doc: CHAIN_ID
    118:
      id: level
      doc: LEVEL
    119:
      id: self_address
      doc: SELF_ADDRESS
    120: never
    121:
      id: never_
      doc: NEVER
    122:
      id: unpair
      doc: UNPAIR
    123:
      id: voting_power
      doc: VOTING_POWER
    124:
      id: total_voting_power
      doc: TOTAL_VOTING_POWER
    125:
      id: keccak
      doc: KECCAK
    126:
      id: sha3
      doc: SHA3
    127:
      id: pairing_check
      doc: PAIRING_CHECK
    128: bls12_381_g1
    129: bls12_381_g2
    130: bls12_381_fr
    131: sapling_state
    132: sapling_transaction_deprecated
    133:
      id: sapling_empty_state
      doc: SAPLING_EMPTY_STATE
    134:
      id: sapling_verify_update
      doc: SAPLING_VERIFY_UPDATE
    135: ticket
    136:
      id: ticket_deprecated
      doc: TICKET_DEPRECATED
    137:
      id: read_ticket
      doc: READ_TICKET
    138:
      id: split_ticket
      doc: SPLIT_TICKET
    139:
      id: join_tickets
      doc: JOIN_TICKETS
    140:
      id: get_and_update
      doc: GET_AND_UPDATE
    141: chest
    142: chest_key
    143:
      id: open_chest
      doc: OPEN_CHEST
    144:
      id: view_
      doc: VIEW
    145: view
    146: constant
    147:
      id: sub_mutez
      doc: SUB_MUTEZ
    148: tx_rollup_l2_address
    149:
      id: min_block_time
      doc: MIN_BLOCK_TIME
    150: sapling_transaction
    151:
      id: emit
      doc: EMIT
    152:
      id: lambda_rec
      doc: Lambda_rec
    153:
      id: lambda_rec_
      doc: LAMBDA_REC
    154:
      id: ticket_
      doc: TICKET
    155:
      id: bytes_
      doc: BYTES
    156:
      id: nat_
      doc: NAT
  zk_rollup_publish__some__prim__no_args__no_annots__id_017__ptnairob__michelson__v1__primitives:
    0: parameter
    1: storage
    2: code
    3:
      id: false
      doc: False
    4:
      id: elt
      doc: Elt
    5:
      id: left
      doc: Left
    6:
      id: none_
      doc: None
    7:
      id: pair__
      doc: Pair
    8:
      id: right
      doc: Right
    9:
      id: some_
      doc: Some
    10:
      id: true
      doc: True
    11:
      id: unit_
      doc: Unit
    12:
      id: pack
      doc: PACK
    13:
      id: unpack
      doc: UNPACK
    14:
      id: blake2b
      doc: BLAKE2B
    15:
      id: sha256
      doc: SHA256
    16:
      id: sha512
      doc: SHA512
    17:
      id: abs
      doc: ABS
    18:
      id: add
      doc: ADD
    19:
      id: amount
      doc: AMOUNT
    20:
      id: and
      doc: AND
    21:
      id: balance
      doc: BALANCE
    22:
      id: car
      doc: CAR
    23:
      id: cdr
      doc: CDR
    24:
      id: check_signature
      doc: CHECK_SIGNATURE
    25:
      id: compare
      doc: COMPARE
    26:
      id: concat
      doc: CONCAT
    27:
      id: cons
      doc: CONS
    28:
      id: create_account
      doc: CREATE_ACCOUNT
    29:
      id: create_contract
      doc: CREATE_CONTRACT
    30:
      id: implicit_account
      doc: IMPLICIT_ACCOUNT
    31:
      id: dip
      doc: DIP
    32:
      id: drop
      doc: DROP
    33:
      id: dup
      doc: DUP
    34:
      id: ediv
      doc: EDIV
    35:
      id: empty_map
      doc: EMPTY_MAP
    36:
      id: empty_set
      doc: EMPTY_SET
    37:
      id: eq
      doc: EQ
    38:
      id: exec
      doc: EXEC
    39:
      id: failwith
      doc: FAILWITH
    40:
      id: ge
      doc: GE
    41:
      id: get
      doc: GET
    42:
      id: gt
      doc: GT
    43:
      id: hash_key
      doc: HASH_KEY
    44:
      id: if
      doc: IF
    45:
      id: if_cons
      doc: IF_CONS
    46:
      id: if_left
      doc: IF_LEFT
    47:
      id: if_none
      doc: IF_NONE
    48:
      id: int_
      doc: INT
    49:
      id: lambda_
      doc: LAMBDA
    50:
      id: le
      doc: LE
    51:
      id: left_
      doc: LEFT
    52:
      id: loop
      doc: LOOP
    53:
      id: lsl
      doc: LSL
    54:
      id: lsr
      doc: LSR
    55:
      id: lt
      doc: LT
    56:
      id: map_
      doc: MAP
    57:
      id: mem
      doc: MEM
    58:
      id: mul
      doc: MUL
    59:
      id: neg
      doc: NEG
    60:
      id: neq
      doc: NEQ
    61:
      id: nil
      doc: NIL
    62:
      id: none
      doc: NONE
    63:
      id: not
      doc: NOT
    64:
      id: now
      doc: NOW
    65:
      id: or_
      doc: OR
    66:
      id: pair_
      doc: PAIR
    67:
      id: push
      doc: PUSH
    68:
      id: right_
      doc: RIGHT
    69:
      id: size
      doc: SIZE
    70:
      id: some
      doc: SOME
    71:
      id: source
      doc: SOURCE
    72:
      id: sender
      doc: SENDER
    73:
      id: self
      doc: SELF
    74:
      id: steps_to_quota
      doc: STEPS_TO_QUOTA
    75:
      id: sub
      doc: SUB
    76:
      id: swap
      doc: SWAP
    77:
      id: transfer_tokens
      doc: TRANSFER_TOKENS
    78:
      id: set_delegate
      doc: SET_DELEGATE
    79:
      id: unit__
      doc: UNIT
    80:
      id: update
      doc: UPDATE
    81:
      id: xor
      doc: XOR
    82:
      id: iter
      doc: ITER
    83:
      id: loop_left
      doc: LOOP_LEFT
    84:
      id: address_
      doc: ADDRESS
    85:
      id: contract_
      doc: CONTRACT
    86:
      id: isnat
      doc: ISNAT
    87:
      id: cast
      doc: CAST
    88:
      id: rename
      doc: RENAME
    89: bool
    90: contract
    91: int
    92: key
    93: key_hash
    94: lambda
    95: list
    96: map
    97: big_map
    98: nat
    99: option
    100: or
    101: pair
    102: set
    103: signature
    104: string
    105: bytes
    106: mutez
    107: timestamp
    108: unit
    109: operation
    110: address
    111:
      id: slice
      doc: SLICE
    112:
      id: dig
      doc: DIG
    113:
      id: dug
      doc: DUG
    114:
      id: empty_big_map
      doc: EMPTY_BIG_MAP
    115:
      id: apply
      doc: APPLY
    116: chain_id
    117:
      id: chain_id_
      doc: CHAIN_ID
    118:
      id: level
      doc: LEVEL
    119:
      id: self_address
      doc: SELF_ADDRESS
    120: never
    121:
      id: never_
      doc: NEVER
    122:
      id: unpair
      doc: UNPAIR
    123:
      id: voting_power
      doc: VOTING_POWER
    124:
      id: total_voting_power
      doc: TOTAL_VOTING_POWER
    125:
      id: keccak
      doc: KECCAK
    126:
      id: sha3
      doc: SHA3
    127:
      id: pairing_check
      doc: PAIRING_CHECK
    128: bls12_381_g1
    129: bls12_381_g2
    130: bls12_381_fr
    131: sapling_state
    132: sapling_transaction_deprecated
    133:
      id: sapling_empty_state
      doc: SAPLING_EMPTY_STATE
    134:
      id: sapling_verify_update
      doc: SAPLING_VERIFY_UPDATE
    135: ticket
    136:
      id: ticket_deprecated
      doc: TICKET_DEPRECATED
    137:
      id: read_ticket
      doc: READ_TICKET
    138:
      id: split_ticket
      doc: SPLIT_TICKET
    139:
      id: join_tickets
      doc: JOIN_TICKETS
    140:
      id: get_and_update
      doc: GET_AND_UPDATE
    141: chest
    142: chest_key
    143:
      id: open_chest
      doc: OPEN_CHEST
    144:
      id: view_
      doc: VIEW
    145: view
    146: constant
    147:
      id: sub_mutez
      doc: SUB_MUTEZ
    148: tx_rollup_l2_address
    149:
      id: min_block_time
      doc: MIN_BLOCK_TIME
    150: sapling_transaction
    151:
      id: emit
      doc: EMIT
    152:
      id: lambda_rec
      doc: Lambda_rec
    153:
      id: lambda_rec_
      doc: LAMBDA_REC
    154:
      id: ticket_
      doc: TICKET
    155:
      id: bytes_
      doc: BYTES
    156:
      id: nat_
      doc: NAT
  micheline__017__ptnairob__michelson_v1__expression_tag:
    0: int
    1: string
    2: sequence
    3:
      id: prim__no_args__no_annots
      doc: Primitive with no arguments and no annotations
    4:
      id: prim__no_args__some_annots
      doc: Primitive with no arguments and some annotations
    5:
      id: prim__1_arg__no_annots
      doc: Primitive with one argument and no annotations
    6:
      id: prim__1_arg__some_annots
      doc: Primitive with one argument and some annotations
    7:
      id: prim__2_args__no_annots
      doc: Primitive with two arguments and no annotations
    8:
      id: prim__2_args__some_annots
      doc: Primitive with two arguments and some annotations
    9:
      id: prim__generic
      doc: Generic primitive (any number of args with or without annotations)
    10: bytes
  op_elt_field1_tag:
    0: none
    1: some
  circuits_info_elt_field1_tag:
    0: public
    1: private
    2: fee
  reveal_proof_tag:
    0: raw__data__proof
    1: metadata__proof
    2: dal__page__proof
  input_proof_tag:
    0: inbox__proof
    1: reveal__proof
    2: first__input
  step_tag:
    0: dissection
    1: proof
  refutation_tag:
    0: start
    1: move
  smart_rollup_originate__pvm_kind:
    0: arith
    1: wasm_2_0_0
  id_017__ptnairob__contract_id__originated_tag:
    1: originated
  id_017__ptnairob__entrypoint_tag:
    0: default
    1: root
    2: do
    3: set_delegate
    4: remove_delegate
    5: deposit
    255: named
  id_017__ptnairob__contract_id_tag:
    0: implicit
    1: originated
  public_key_tag:
    0: ed25519
    1: secp256k1
    2: p256
    3: bls
  id_017__ptnairob__inlined__preendorsement__contents_tag:
    20: preendorsement
  bool:
    0: false
    255: true
  id_017__ptnairob__inlined__endorsement_mempool__contents_tag:
    21: endorsement
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
    3: bls
  id_017__ptnairob__operation__alpha__contents_tag:
    1: seed_nonce_revelation
    2: double_endorsement_evidence
    3: double_baking_evidence
    4: activate_account
    5: proposals
    6: ballot
    7: double_preendorsement_evidence
    8: vdf_revelation
    9: drain_delegate
    17: failing_noop
    20: preendorsement
    21: endorsement
    22: dal_attestation
    107: reveal
    108: transaction
    109: origination
    110: delegation
    111: register_global_constant
    112: set_deposits_limit
    113: increase_paid_storage
    114: update_consensus_key
    158: transfer_ticket
    200: smart_rollup_originate
    201: smart_rollup_add_messages
    202: smart_rollup_cement
    203: smart_rollup_publish
    204: smart_rollup_refute
    205: smart_rollup_timeout
    206: smart_rollup_execute_outbox_message
    207: smart_rollup_recover_bond
    230: dal_publish_slot_header
    250: zk_rollup_origination
    251: zk_rollup_publish
    252: zk_rollup_update
seq:
- id: id_017__ptnairob__operation__contents_list_entries
  type: id_017__ptnairob__operation__contents_list_entries
  repeat: eos
