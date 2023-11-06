meta:
  id: alpha__operation__protocol_data
  endian: be
doc: ! 'Encoding id: alpha.operation.protocol_data'
types:
  alpha__operation__alpha__contents_and_signature:
    seq:
    - id: contents_and_signature_prefix
      type: contents_and_signature_prefix_entries
      repeat: eos
    - id: signature_suffix
      size: 64
  contents_and_signature_prefix_entries:
    seq:
    - id: alpha__operation__alpha__contents_or_signature_prefix
      type: alpha__operation__alpha__contents_or_signature_prefix
  alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: alpha__operation__alpha__contents_or_signature_prefix_tag
      type: u1
      enum: alpha__operation__alpha__contents_or_signature_prefix_tag
    - id: signature_prefix__alpha__operation__alpha__contents_or_signature_prefix
      type: signature_prefix__bls_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::signature_prefix)
      doc: The prefix of a BLS signature, i.e. the first 32 bytes.
    - id: preattestation__alpha__operation__alpha__contents_or_signature_prefix
      type: preattestation__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::preattestation)
    - id: attestation__alpha__operation__alpha__contents_or_signature_prefix
      type: attestation__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::attestation)
    - id: double_preattestation_evidence__alpha__operation__alpha__contents_or_signature_prefix
      type: double_preattestation_evidence__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::double_preattestation_evidence)
    - id: double_attestation_evidence__alpha__operation__alpha__contents_or_signature_prefix
      type: double_attestation_evidence__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::double_attestation_evidence)
    - id: dal_attestation__alpha__operation__alpha__contents_or_signature_prefix
      type: dal_attestation__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::dal_attestation)
    - id: seed_nonce_revelation__alpha__operation__alpha__contents_or_signature_prefix
      type: seed_nonce_revelation__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::seed_nonce_revelation)
    - id: vdf_revelation__alpha__operation__alpha__contents_or_signature_prefix
      type: vdf_revelation__solution
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::vdf_revelation)
    - id: double_baking_evidence__alpha__operation__alpha__contents_or_signature_prefix
      type: double_baking_evidence__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::double_baking_evidence)
    - id: activate_account__alpha__operation__alpha__contents_or_signature_prefix
      type: activate_account__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::activate_account)
    - id: proposals__alpha__operation__alpha__contents_or_signature_prefix
      type: proposals__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::proposals)
    - id: ballot__alpha__operation__alpha__contents_or_signature_prefix
      type: ballot__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::ballot)
    - id: reveal__alpha__operation__alpha__contents_or_signature_prefix
      type: reveal__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::reveal)
    - id: transaction__alpha__operation__alpha__contents_or_signature_prefix
      type: transaction__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::transaction)
    - id: origination__alpha__operation__alpha__contents_or_signature_prefix
      type: origination__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::origination)
    - id: delegation__alpha__operation__alpha__contents_or_signature_prefix
      type: delegation__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::delegation)
    - id: increase_paid_storage__alpha__operation__alpha__contents_or_signature_prefix
      type: increase_paid_storage__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::increase_paid_storage)
    - id: update_consensus_key__alpha__operation__alpha__contents_or_signature_prefix
      type: update_consensus_key__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::update_consensus_key)
    - id: drain_delegate__alpha__operation__alpha__contents_or_signature_prefix
      type: drain_delegate__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::drain_delegate)
    - id: failing_noop__alpha__operation__alpha__contents_or_signature_prefix
      type: failing_noop__arbitrary
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::failing_noop)
    - id: register_global_constant__alpha__operation__alpha__contents_or_signature_prefix
      type: register_global_constant__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::register_global_constant)
    - id: transfer_ticket__alpha__operation__alpha__contents_or_signature_prefix
      type: transfer_ticket__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::transfer_ticket)
    - id: dal_publish_slot_header__alpha__operation__alpha__contents_or_signature_prefix
      type: dal_publish_slot_header__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::dal_publish_slot_header)
    - id: smart_rollup_originate__alpha__operation__alpha__contents_or_signature_prefix
      type: smart_rollup_originate__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::smart_rollup_originate)
    - id: smart_rollup_add_messages__alpha__operation__alpha__contents_or_signature_prefix
      type: smart_rollup_add_messages__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::smart_rollup_add_messages)
    - id: smart_rollup_cement__alpha__operation__alpha__contents_or_signature_prefix
      type: smart_rollup_cement__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::smart_rollup_cement)
    - id: smart_rollup_publish__alpha__operation__alpha__contents_or_signature_prefix
      type: smart_rollup_publish__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::smart_rollup_publish)
    - id: smart_rollup_refute__alpha__operation__alpha__contents_or_signature_prefix
      type: smart_rollup_refute__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::smart_rollup_refute)
    - id: smart_rollup_timeout__alpha__operation__alpha__contents_or_signature_prefix
      type: smart_rollup_timeout__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::smart_rollup_timeout)
    - id: smart_rollup_execute_outbox_message__alpha__operation__alpha__contents_or_signature_prefix
      type: smart_rollup_execute_outbox_message__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::smart_rollup_execute_outbox_message)
    - id: smart_rollup_recover_bond__alpha__operation__alpha__contents_or_signature_prefix
      type: smart_rollup_recover_bond__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::smart_rollup_recover_bond)
    - id: zk_rollup_origination__alpha__operation__alpha__contents_or_signature_prefix
      type: zk_rollup_origination__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::zk_rollup_origination)
    - id: zk_rollup_publish__alpha__operation__alpha__contents_or_signature_prefix
      type: zk_rollup_publish__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::zk_rollup_publish)
    - id: zk_rollup_update__alpha__operation__alpha__contents_or_signature_prefix
      type: zk_rollup_update__alpha__operation__alpha__contents_or_signature_prefix
      if: (alpha__operation__alpha__contents_or_signature_prefix_tag == alpha__operation__alpha__contents_or_signature_prefix_tag::zk_rollup_update)
  zk_rollup_update__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: source
      type: zk_rollup_update__public_key_hash
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
    - id: len_private_pis
      type: u4
      valid:
        max: 1073741823
    - id: private_pis
      type: zk_rollup_update__private_pis_entries
      size: len_private_pis
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
    - id: len_pending_pis
      type: u4
      valid:
        max: 1073741823
    - id: pending_pis
      type: zk_rollup_update__pending_pis_entries
      size: len_pending_pis
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
    - id: len_new_state
      type: u4
      valid:
        max: 1073741823
    - id: new_state
      type: zk_rollup_update__new_state_entries
      size: len_new_state
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
  zk_rollup_update__public_key_hash:
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
  zk_rollup_publish__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: source
      type: zk_rollup_publish__public_key_hash
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
    - id: len_op
      type: u4
      valid:
        max: 1073741823
    - id: op
      type: zk_rollup_publish__op_entries
      size: len_op
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
      type: zk_rollup_publish__some__micheline__alpha__michelson_v1__expression
    - id: ty
      type: micheline__alpha__michelson_v1__expression
    - id: ticketer
      type: zk_rollup_publish__some__alpha__contract_id
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
  zk_rollup_publish__some__alpha__contract_id:
    seq:
    - id: alpha__contract_id_tag
      type: u1
      enum: alpha__contract_id_tag
    - id: zk_rollup_publish__some__implicit__alpha__contract_id
      type: zk_rollup_publish__some__implicit__public_key_hash
      if: (alpha__contract_id_tag == alpha__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: zk_rollup_publish__some__originated__alpha__contract_id
      type: zk_rollup_publish__some__originated__alpha__contract_id
      if: (alpha__contract_id_tag == alpha__contract_id_tag::originated)
  zk_rollup_publish__some__originated__alpha__contract_id:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  zk_rollup_publish__some__implicit__public_key_hash:
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
  zk_rollup_publish__some__micheline__alpha__michelson_v1__expression:
    seq:
    - id: micheline__alpha__michelson_v1__expression_tag
      type: u1
      enum: micheline__alpha__michelson_v1__expression_tag
    - id: zk_rollup_publish__some__int__micheline__alpha__michelson_v1__expression
      type: z
      if: (micheline__alpha__michelson_v1__expression_tag == micheline__alpha__michelson_v1__expression_tag::int)
    - id: zk_rollup_publish__some__string__micheline__alpha__michelson_v1__expression
      type: zk_rollup_publish__some__string__string
      if: (micheline__alpha__michelson_v1__expression_tag == micheline__alpha__michelson_v1__expression_tag::string)
    - id: zk_rollup_publish__some__sequence__micheline__alpha__michelson_v1__expression
      type: zk_rollup_publish__some__sequence__micheline__alpha__michelson_v1__expression
      if: (micheline__alpha__michelson_v1__expression_tag == micheline__alpha__michelson_v1__expression_tag::sequence)
    - id: zk_rollup_publish__some__prim__no_args__no_annots__micheline__alpha__michelson_v1__expression
      type: u1
      if: (micheline__alpha__michelson_v1__expression_tag == micheline__alpha__michelson_v1__expression_tag::prim__no_args__no_annots)
      enum: zk_rollup_publish__some__prim__no_args__no_annots__alpha__michelson__v1__primitives
    - id: zk_rollup_publish__some__prim__no_args__some_annots__micheline__alpha__michelson_v1__expression
      type: zk_rollup_publish__some__prim__no_args__some_annots__micheline__alpha__michelson_v1__expression
      if: (micheline__alpha__michelson_v1__expression_tag == micheline__alpha__michelson_v1__expression_tag::prim__no_args__some_annots)
    - id: zk_rollup_publish__some__prim__1_arg__no_annots__micheline__alpha__michelson_v1__expression
      type: zk_rollup_publish__some__prim__1_arg__no_annots__micheline__alpha__michelson_v1__expression
      if: (micheline__alpha__michelson_v1__expression_tag == micheline__alpha__michelson_v1__expression_tag::prim__1_arg__no_annots)
    - id: zk_rollup_publish__some__prim__1_arg__some_annots__micheline__alpha__michelson_v1__expression
      type: zk_rollup_publish__some__prim__1_arg__some_annots__micheline__alpha__michelson_v1__expression
      if: (micheline__alpha__michelson_v1__expression_tag == micheline__alpha__michelson_v1__expression_tag::prim__1_arg__some_annots)
    - id: zk_rollup_publish__some__prim__2_args__no_annots__micheline__alpha__michelson_v1__expression
      type: zk_rollup_publish__some__prim__2_args__no_annots__micheline__alpha__michelson_v1__expression
      if: (micheline__alpha__michelson_v1__expression_tag == micheline__alpha__michelson_v1__expression_tag::prim__2_args__no_annots)
    - id: zk_rollup_publish__some__prim__2_args__some_annots__micheline__alpha__michelson_v1__expression
      type: zk_rollup_publish__some__prim__2_args__some_annots__micheline__alpha__michelson_v1__expression
      if: (micheline__alpha__michelson_v1__expression_tag == micheline__alpha__michelson_v1__expression_tag::prim__2_args__some_annots)
    - id: zk_rollup_publish__some__prim__generic__micheline__alpha__michelson_v1__expression
      type: zk_rollup_publish__some__prim__generic__micheline__alpha__michelson_v1__expression
      if: (micheline__alpha__michelson_v1__expression_tag == micheline__alpha__michelson_v1__expression_tag::prim__generic)
    - id: zk_rollup_publish__some__bytes__micheline__alpha__michelson_v1__expression
      type: zk_rollup_publish__some__bytes__bytes
      if: (micheline__alpha__michelson_v1__expression_tag == micheline__alpha__michelson_v1__expression_tag::bytes)
  zk_rollup_publish__some__bytes__bytes:
    seq:
    - id: len_bytes
      type: u4
      valid:
        max: 1073741823
    - id: bytes
      size: len_bytes
  zk_rollup_publish__some__prim__generic__micheline__alpha__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__generic__alpha__michelson__v1__primitives
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
    - id: len_args
      type: u4
      valid:
        max: 1073741823
    - id: args
      type: zk_rollup_publish__some__prim__generic__args_entries
      size: len_args
      repeat: eos
  zk_rollup_publish__some__prim__generic__args_entries:
    seq:
    - id: args_elt
      type: micheline__alpha__michelson_v1__expression
  zk_rollup_publish__some__prim__2_args__some_annots__micheline__alpha__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__2_args__some_annots__alpha__michelson__v1__primitives
    - id: arg1
      type: micheline__alpha__michelson_v1__expression
    - id: arg2
      type: micheline__alpha__michelson_v1__expression
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
  zk_rollup_publish__some__prim__2_args__no_annots__micheline__alpha__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__2_args__no_annots__alpha__michelson__v1__primitives
    - id: arg1
      type: micheline__alpha__michelson_v1__expression
    - id: arg2
      type: micheline__alpha__michelson_v1__expression
  zk_rollup_publish__some__prim__1_arg__some_annots__micheline__alpha__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__1_arg__some_annots__alpha__michelson__v1__primitives
    - id: arg
      type: micheline__alpha__michelson_v1__expression
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
  zk_rollup_publish__some__prim__1_arg__no_annots__micheline__alpha__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__1_arg__no_annots__alpha__michelson__v1__primitives
    - id: arg
      type: micheline__alpha__michelson_v1__expression
  zk_rollup_publish__some__prim__no_args__some_annots__micheline__alpha__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__no_args__some_annots__alpha__michelson__v1__primitives
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
  zk_rollup_publish__some__sequence__micheline__alpha__michelson_v1__expression:
    seq:
    - id: len_sequence
      type: u4
      valid:
        max: 1073741823
    - id: sequence
      type: zk_rollup_publish__some__sequence__sequence_entries
      size: len_sequence
      repeat: eos
  zk_rollup_publish__some__sequence__sequence_entries:
    seq:
    - id: sequence_elt
      type: micheline__alpha__michelson_v1__expression
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
      type: zk_rollup_publish__public_key_hash
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: rollup_id
      size: 20
    - id: zk_rollup_publish__payload
      type: zk_rollup_publish__payload
  zk_rollup_publish__payload:
    seq:
    - id: len_payload
      type: u4
      valid:
        max: 1073741823
    - id: payload
      type: zk_rollup_publish__payload_entries
      size: len_payload
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
  zk_rollup_publish__public_key_hash:
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
  zk_rollup_origination__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: source
      type: zk_rollup_origination__public_key_hash
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
    - id: len_init_state
      type: u4
      valid:
        max: 1073741823
    - id: init_state
      type: zk_rollup_origination__init_state_entries
      size: len_init_state
      repeat: eos
  zk_rollup_origination__init_state_entries:
    seq:
    - id: init_state_elt
      size: 32
  zk_rollup_origination__circuits_info:
    seq:
    - id: len_circuits_info
      type: u4
      valid:
        max: 1073741823
    - id: circuits_info
      type: zk_rollup_origination__circuits_info_entries
      size: len_circuits_info
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
  zk_rollup_origination__public_key_hash:
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
  smart_rollup_recover_bond__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: source
      type: smart_rollup_recover_bond__public_key_hash
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
      type: smart_rollup_recover_bond__public_key_hash
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
  smart_rollup_recover_bond__public_key_hash:
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
  smart_rollup_execute_outbox_message__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: source
      type: smart_rollup_execute_outbox_message__public_key_hash
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
  smart_rollup_execute_outbox_message__public_key_hash:
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
  smart_rollup_timeout__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: source
      type: smart_rollup_timeout__public_key_hash
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
    - id: smart_rollup_timeout__stakers
      type: smart_rollup_timeout__stakers
  smart_rollup_timeout__stakers:
    seq:
    - id: alice
      type: smart_rollup_timeout__public_key_hash
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: bob
      type: smart_rollup_timeout__public_key_hash
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
  smart_rollup_timeout__public_key_hash:
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
  smart_rollup_refute__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: source
      type: smart_rollup_refute__public_key_hash
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
    - id: opponent
      type: smart_rollup_refute__public_key_hash
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
    - id: smart_rollup_refute__move__proof__input_proof
      type: smart_rollup_refute__move__proof__input_proof
      if: (input_proof_tag == bool::true)
  smart_rollup_refute__move__proof__input_proof:
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
    - id: len_raw_data
      type: u2
      valid:
        max: 4096
    - id: raw_data
      size: len_raw_data
      size-eos: true
      valid:
        max: 4096
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
    - id: len_dissection
      type: u4
      valid:
        max: 1073741823
    - id: dissection
      type: smart_rollup_refute__move__dissection__dissection_entries
      size: len_dissection
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
  smart_rollup_refute__public_key_hash:
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
  smart_rollup_publish__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: source
      type: smart_rollup_publish__public_key_hash
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
  smart_rollup_publish__public_key_hash:
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
  smart_rollup_cement__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: source
      type: smart_rollup_cement__public_key_hash
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
  smart_rollup_cement__public_key_hash:
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
  smart_rollup_add_messages__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: source
      type: smart_rollup_add_messages__public_key_hash
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
    - id: len_message
      type: u4
      valid:
        max: 1073741823
    - id: message
      type: smart_rollup_add_messages__message_entries
      size: len_message
      repeat: eos
  smart_rollup_add_messages__message_entries:
    seq:
    - id: len_message_elt
      type: u4
      valid:
        max: 1073741823
    - id: message_elt
      size: len_message_elt
  smart_rollup_add_messages__public_key_hash:
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
  smart_rollup_originate__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: source
      type: smart_rollup_originate__public_key_hash
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
    - id: smart_rollup_originate__parameters_ty
      type: smart_rollup_originate__parameters_ty
    - id: whitelist_tag
      type: u1
      enum: bool
    - id: smart_rollup_originate__whitelist
      type: smart_rollup_originate__whitelist
      if: (whitelist_tag == bool::true)
  smart_rollup_originate__whitelist:
    seq:
    - id: len_whitelist
      type: u4
      valid:
        max: 1073741823
    - id: whitelist
      type: smart_rollup_originate__whitelist_entries
      size: len_whitelist
      repeat: eos
  smart_rollup_originate__whitelist_entries:
    seq:
    - id: signature__public_key_hash
      type: smart_rollup_originate__public_key_hash
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
  smart_rollup_originate__parameters_ty:
    seq:
    - id: len_parameters_ty
      type: u4
      valid:
        max: 1073741823
    - id: parameters_ty
      size: len_parameters_ty
  smart_rollup_originate__kernel:
    seq:
    - id: len_kernel
      type: u4
      valid:
        max: 1073741823
    - id: kernel
      size: len_kernel
  smart_rollup_originate__public_key_hash:
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
  dal_publish_slot_header__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: source
      type: dal_publish_slot_header__public_key_hash
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
    - id: slot_index
      type: u1
    - id: commitment
      size: 48
    - id: commitment_proof
      size: 48
  dal_publish_slot_header__public_key_hash:
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
  transfer_ticket__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: source
      type: transfer_ticket__public_key_hash
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
      type: transfer_ticket__alpha__contract_id
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: ticket_amount
      type: n
    - id: destination
      type: transfer_ticket__alpha__contract_id
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
  transfer_ticket__alpha__contract_id:
    seq:
    - id: alpha__contract_id_tag
      type: u1
      enum: alpha__contract_id_tag
    - id: transfer_ticket__implicit__alpha__contract_id
      type: transfer_ticket__implicit__public_key_hash
      if: (alpha__contract_id_tag == alpha__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: transfer_ticket__originated__alpha__contract_id
      type: transfer_ticket__originated__alpha__contract_id
      if: (alpha__contract_id_tag == alpha__contract_id_tag::originated)
  transfer_ticket__originated__alpha__contract_id:
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
    - id: transfer_ticket__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  register_global_constant__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: source
      type: register_global_constant__public_key_hash
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
  drain_delegate__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: consensus_key
      type: drain_delegate__public_key_hash
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: delegate
      type: drain_delegate__public_key_hash
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: destination
      type: drain_delegate__public_key_hash
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
  drain_delegate__public_key_hash:
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
  update_consensus_key__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: source
      type: update_consensus_key__public_key_hash
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
      type: update_consensus_key__public_key
      doc: A Ed25519, Secp256k1, or P256 public key
  update_consensus_key__public_key:
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
  update_consensus_key__public_key_hash:
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
  increase_paid_storage__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: source
      type: increase_paid_storage__public_key_hash
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
      type: increase_paid_storage__alpha__contract_id__originated
      doc: ! >-
        A contract handle -- originated account: A contract notation as given to an
        RPC or inside scripts. Can be a base58 originated contract hash.
  increase_paid_storage__alpha__contract_id__originated:
    seq:
    - id: alpha__contract_id__originated_tag
      type: u1
      enum: alpha__contract_id__originated_tag
    - id: increase_paid_storage__originated__alpha__contract_id__originated
      type: increase_paid_storage__originated__alpha__contract_id__originated
      if: (alpha__contract_id__originated_tag == alpha__contract_id__originated_tag::originated)
  increase_paid_storage__originated__alpha__contract_id__originated:
    seq:
    - id: contract_hash
      size: 20
    - id: originated_padding
      size: 1
      doc: This field is for padding, ignore
  increase_paid_storage__public_key_hash:
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
  delegation__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: source
      type: delegation__public_key_hash
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
      type: delegation__public_key_hash
      if: (delegate_tag == bool::true)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
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
    - id: delegation__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  origination__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: source
      type: origination__public_key_hash
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
      type: origination__public_key_hash
      if: (delegate_tag == bool::true)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: script
      type: origination__alpha__scripted__contracts
  origination__alpha__scripted__contracts:
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
    - id: origination__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  transaction__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: source
      type: transaction__public_key_hash
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
      type: transaction__alpha__contract_id
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: parameters_tag
      type: u1
      enum: bool
    - id: transaction__parameters
      type: transaction__parameters
      if: (parameters_tag == bool::true)
  transaction__parameters:
    seq:
    - id: entrypoint
      type: transaction__alpha__entrypoint
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
  transaction__alpha__entrypoint:
    seq:
    - id: alpha__entrypoint_tag
      type: u1
      enum: alpha__entrypoint_tag
    - id: transaction__named__alpha__entrypoint
      type: transaction__named__alpha__entrypoint
      if: (alpha__entrypoint_tag == alpha__entrypoint_tag::named)
  transaction__named__alpha__entrypoint:
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
  transaction__alpha__contract_id:
    seq:
    - id: alpha__contract_id_tag
      type: u1
      enum: alpha__contract_id_tag
    - id: transaction__implicit__alpha__contract_id
      type: transaction__implicit__public_key_hash
      if: (alpha__contract_id_tag == alpha__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: transaction__originated__alpha__contract_id
      type: transaction__originated__alpha__contract_id
      if: (alpha__contract_id_tag == alpha__contract_id_tag::originated)
  transaction__originated__alpha__contract_id:
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
    - id: transaction__implicit__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
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
    - id: transaction__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  reveal__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: source
      type: reveal__public_key_hash
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
    - id: reveal__bls__public_key
      size: 48
      if: (public_key_tag == public_key_tag::bls)
  n:
    seq:
    - id: n
      type: n_chunk
      repeat: until
      repeat-until: not (_.has_more).as<bool>
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
    - id: reveal__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  ballot__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: source
      type: ballot__public_key_hash
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
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
    - id: ballot__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  proposals__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: source
      type: proposals__public_key_hash
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: period
      type: s4
    - id: proposals__proposals
      type: proposals__proposals
  proposals__proposals:
    seq:
    - id: len_proposals
      type: u4
      valid:
        max: 640
    - id: proposals
      type: proposals__proposals_entries
      size: len_proposals
      repeat: eos
      valid:
        max: 640
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
    - id: proposals__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == public_key_hash_tag::bls)
  activate_account__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: pkh
      size: 20
    - id: secret
      size: 20
  double_baking_evidence__alpha__operation__alpha__contents_or_signature_prefix:
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
      type: double_baking_evidence__alpha__block_header__alpha__full_header
      size: len_bh2
  double_baking_evidence__bh1:
    seq:
    - id: len_bh1
      type: u4
      valid:
        max: 1073741823
    - id: bh1
      type: double_baking_evidence__alpha__block_header__alpha__full_header
      size: len_bh1
  double_baking_evidence__alpha__block_header__alpha__full_header:
    seq:
    - id: double_baking_evidence__block_header__shell
      type: double_baking_evidence__block_header__shell
      doc: ! >-
        Shell header: Block header's shell-related content. It contains information
        such as the block level, its predecessor and timestamp.
    - id: double_baking_evidence__alpha__block_header__alpha__signed_contents
      type: double_baking_evidence__alpha__block_header__alpha__signed_contents
  double_baking_evidence__alpha__block_header__alpha__signed_contents:
    seq:
    - id: double_baking_evidence__alpha__block_header__alpha__unsigned_contents
      type: double_baking_evidence__alpha__block_header__alpha__unsigned_contents
    - id: signature
      size-eos: true
  double_baking_evidence__alpha__block_header__alpha__unsigned_contents:
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
    - id: per_block_votes
      type: u1
      enum: alpha__per_block_votes_tag
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
  vdf_revelation__solution:
    seq:
    - id: solution_field0
      size: 100
    - id: solution_field1
      size: 100
  seed_nonce_revelation__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: level
      type: s4
    - id: nonce
      size: 32
  dal_attestation__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: attestation
      type: z
    - id: level
      type: s4
    - id: slot
      type: u2
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
  double_attestation_evidence__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: double_attestation_evidence__op1
      type: double_attestation_evidence__op1
    - id: double_attestation_evidence__op2
      type: double_attestation_evidence__op2
  double_attestation_evidence__op2:
    seq:
    - id: len_op2
      type: u4
      valid:
        max: 1073741823
    - id: op2
      type: double_attestation_evidence__alpha__inlined__attestation
      size: len_op2
  double_attestation_evidence__op1:
    seq:
    - id: len_op1
      type: u4
      valid:
        max: 1073741823
    - id: op1
      type: double_attestation_evidence__alpha__inlined__attestation
      size: len_op1
  double_attestation_evidence__alpha__inlined__attestation:
    seq:
    - id: operation__shell_header
      size: 32
      doc: An operation's shell header.
    - id: operations
      type: double_attestation_evidence__alpha__inlined__attestation_mempool__contents
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size-eos: true
      if: (signature_tag == bool::true)
  double_attestation_evidence__alpha__inlined__attestation_mempool__contents:
    seq:
    - id: alpha__inlined__attestation_mempool__contents_tag
      type: u1
      enum: alpha__inlined__attestation_mempool__contents_tag
    - id: double_attestation_evidence__attestation__alpha__inlined__attestation_mempool__contents
      type: double_attestation_evidence__attestation__alpha__inlined__attestation_mempool__contents
      if: (alpha__inlined__attestation_mempool__contents_tag == alpha__inlined__attestation_mempool__contents_tag::attestation)
  double_attestation_evidence__attestation__alpha__inlined__attestation_mempool__contents:
    seq:
    - id: slot
      type: u2
    - id: level
      type: s4
    - id: round
      type: s4
    - id: block_payload_hash
      size: 32
  double_preattestation_evidence__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: double_preattestation_evidence__op1
      type: double_preattestation_evidence__op1
    - id: double_preattestation_evidence__op2
      type: double_preattestation_evidence__op2
  double_preattestation_evidence__op2:
    seq:
    - id: len_op2
      type: u4
      valid:
        max: 1073741823
    - id: op2
      type: double_preattestation_evidence__alpha__inlined__preattestation
      size: len_op2
  double_preattestation_evidence__op1:
    seq:
    - id: len_op1
      type: u4
      valid:
        max: 1073741823
    - id: op1
      type: double_preattestation_evidence__alpha__inlined__preattestation
      size: len_op1
  double_preattestation_evidence__alpha__inlined__preattestation:
    seq:
    - id: operation__shell_header
      size: 32
      doc: An operation's shell header.
    - id: operations
      type: double_preattestation_evidence__alpha__inlined__preattestation__contents
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size-eos: true
      if: (signature_tag == bool::true)
  double_preattestation_evidence__alpha__inlined__preattestation__contents:
    seq:
    - id: alpha__inlined__preattestation__contents_tag
      type: u1
      enum: alpha__inlined__preattestation__contents_tag
    - id: double_preattestation_evidence__preattestation__alpha__inlined__preattestation__contents
      type: double_preattestation_evidence__preattestation__alpha__inlined__preattestation__contents
      if: (alpha__inlined__preattestation__contents_tag == alpha__inlined__preattestation__contents_tag::preattestation)
  double_preattestation_evidence__preattestation__alpha__inlined__preattestation__contents:
    seq:
    - id: slot
      type: u2
    - id: level
      type: s4
    - id: round
      type: s4
    - id: block_payload_hash
      size: 32
  attestation__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: slot
      type: u2
    - id: level
      type: s4
    - id: round
      type: s4
    - id: block_payload_hash
      size: 32
  preattestation__alpha__operation__alpha__contents_or_signature_prefix:
    seq:
    - id: slot
      type: u2
    - id: level
      type: s4
    - id: round
      type: s4
    - id: block_payload_hash
      size: 32
  signature_prefix__bls_signature_prefix:
    seq:
    - id: bls_signature_prefix_tag
      type: u1
      enum: bls_signature_prefix_tag
    - id: signature_prefix__bls_prefix__bls_signature_prefix
      size: 32
      if: (bls_signature_prefix_tag == bls_signature_prefix_tag::bls_prefix)
enums:
  zk_rollup_publish__some__prim__generic__alpha__michelson__v1__primitives:
    0: parameter
    1: storage
    2: code
    3: false
    4: elt
    5: left
    6: none
    7: pair
    8: right
    9: some
    10: true
    11: unit
    12: pack
    13: unpack
    14: blake2b
    15: sha256
    16: sha512
    17: abs
    18: add
    19: amount
    20: and
    21: balance
    22: car
    23: cdr
    24: check_signature
    25: compare
    26: concat
    27: cons
    28: create_account
    29: create_contract
    30: implicit_account
    31: dip
    32: drop
    33: dup
    34: ediv
    35: empty_map
    36: empty_set
    37: eq
    38: exec
    39: failwith
    40: ge
    41: get
    42: gt
    43: hash_key
    44: if
    45: if_cons
    46: if_left
    47: if_none
    48: int
    49: lambda
    50: le
    51: left
    52: loop
    53: lsl
    54: lsr
    55: lt
    56: map
    57: mem
    58: mul
    59: neg
    60: neq
    61: nil
    62: none
    63: not
    64: now
    65: or
    66: pair
    67: push
    68: right
    69: size
    70: some
    71: source
    72: sender
    73: self
    74: steps_to_quota
    75: sub
    76: swap
    77: transfer_tokens
    78: set_delegate
    79: unit
    80: update
    81: xor
    82: iter
    83: loop_left
    84: address
    85: contract
    86: isnat
    87: cast
    88: rename
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
    111: slice
    112: dig
    113: dug
    114: empty_big_map
    115: apply
    116: chain_id
    117: chain_id
    118: level
    119: self_address
    120: never
    121: never
    122: unpair
    123: voting_power
    124: total_voting_power
    125: keccak
    126: sha3
    127: pairing_check
    128: bls12_381_g1
    129: bls12_381_g2
    130: bls12_381_fr
    131: sapling_state
    132: sapling_transaction_deprecated
    133: sapling_empty_state
    134: sapling_verify_update
    135: ticket
    136: ticket_deprecated
    137: read_ticket
    138: split_ticket
    139: join_tickets
    140: get_and_update
    141: chest
    142: chest_key
    143: open_chest
    144: view
    145: view
    146: constant
    147: sub_mutez
    148: tx_rollup_l2_address
    149: min_block_time
    150: sapling_transaction
    151: emit
    152: lambda_rec
    153: lambda_rec
    154: ticket
    155: bytes
    156: nat
  zk_rollup_publish__some__prim__2_args__some_annots__alpha__michelson__v1__primitives:
    0: parameter
    1: storage
    2: code
    3: false
    4: elt
    5: left
    6: none
    7: pair
    8: right
    9: some
    10: true
    11: unit
    12: pack
    13: unpack
    14: blake2b
    15: sha256
    16: sha512
    17: abs
    18: add
    19: amount
    20: and
    21: balance
    22: car
    23: cdr
    24: check_signature
    25: compare
    26: concat
    27: cons
    28: create_account
    29: create_contract
    30: implicit_account
    31: dip
    32: drop
    33: dup
    34: ediv
    35: empty_map
    36: empty_set
    37: eq
    38: exec
    39: failwith
    40: ge
    41: get
    42: gt
    43: hash_key
    44: if
    45: if_cons
    46: if_left
    47: if_none
    48: int
    49: lambda
    50: le
    51: left
    52: loop
    53: lsl
    54: lsr
    55: lt
    56: map
    57: mem
    58: mul
    59: neg
    60: neq
    61: nil
    62: none
    63: not
    64: now
    65: or
    66: pair
    67: push
    68: right
    69: size
    70: some
    71: source
    72: sender
    73: self
    74: steps_to_quota
    75: sub
    76: swap
    77: transfer_tokens
    78: set_delegate
    79: unit
    80: update
    81: xor
    82: iter
    83: loop_left
    84: address
    85: contract
    86: isnat
    87: cast
    88: rename
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
    111: slice
    112: dig
    113: dug
    114: empty_big_map
    115: apply
    116: chain_id
    117: chain_id
    118: level
    119: self_address
    120: never
    121: never
    122: unpair
    123: voting_power
    124: total_voting_power
    125: keccak
    126: sha3
    127: pairing_check
    128: bls12_381_g1
    129: bls12_381_g2
    130: bls12_381_fr
    131: sapling_state
    132: sapling_transaction_deprecated
    133: sapling_empty_state
    134: sapling_verify_update
    135: ticket
    136: ticket_deprecated
    137: read_ticket
    138: split_ticket
    139: join_tickets
    140: get_and_update
    141: chest
    142: chest_key
    143: open_chest
    144: view
    145: view
    146: constant
    147: sub_mutez
    148: tx_rollup_l2_address
    149: min_block_time
    150: sapling_transaction
    151: emit
    152: lambda_rec
    153: lambda_rec
    154: ticket
    155: bytes
    156: nat
  zk_rollup_publish__some__prim__2_args__no_annots__alpha__michelson__v1__primitives:
    0: parameter
    1: storage
    2: code
    3: false
    4: elt
    5: left
    6: none
    7: pair
    8: right
    9: some
    10: true
    11: unit
    12: pack
    13: unpack
    14: blake2b
    15: sha256
    16: sha512
    17: abs
    18: add
    19: amount
    20: and
    21: balance
    22: car
    23: cdr
    24: check_signature
    25: compare
    26: concat
    27: cons
    28: create_account
    29: create_contract
    30: implicit_account
    31: dip
    32: drop
    33: dup
    34: ediv
    35: empty_map
    36: empty_set
    37: eq
    38: exec
    39: failwith
    40: ge
    41: get
    42: gt
    43: hash_key
    44: if
    45: if_cons
    46: if_left
    47: if_none
    48: int
    49: lambda
    50: le
    51: left
    52: loop
    53: lsl
    54: lsr
    55: lt
    56: map
    57: mem
    58: mul
    59: neg
    60: neq
    61: nil
    62: none
    63: not
    64: now
    65: or
    66: pair
    67: push
    68: right
    69: size
    70: some
    71: source
    72: sender
    73: self
    74: steps_to_quota
    75: sub
    76: swap
    77: transfer_tokens
    78: set_delegate
    79: unit
    80: update
    81: xor
    82: iter
    83: loop_left
    84: address
    85: contract
    86: isnat
    87: cast
    88: rename
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
    111: slice
    112: dig
    113: dug
    114: empty_big_map
    115: apply
    116: chain_id
    117: chain_id
    118: level
    119: self_address
    120: never
    121: never
    122: unpair
    123: voting_power
    124: total_voting_power
    125: keccak
    126: sha3
    127: pairing_check
    128: bls12_381_g1
    129: bls12_381_g2
    130: bls12_381_fr
    131: sapling_state
    132: sapling_transaction_deprecated
    133: sapling_empty_state
    134: sapling_verify_update
    135: ticket
    136: ticket_deprecated
    137: read_ticket
    138: split_ticket
    139: join_tickets
    140: get_and_update
    141: chest
    142: chest_key
    143: open_chest
    144: view
    145: view
    146: constant
    147: sub_mutez
    148: tx_rollup_l2_address
    149: min_block_time
    150: sapling_transaction
    151: emit
    152: lambda_rec
    153: lambda_rec
    154: ticket
    155: bytes
    156: nat
  zk_rollup_publish__some__prim__1_arg__some_annots__alpha__michelson__v1__primitives:
    0: parameter
    1: storage
    2: code
    3: false
    4: elt
    5: left
    6: none
    7: pair
    8: right
    9: some
    10: true
    11: unit
    12: pack
    13: unpack
    14: blake2b
    15: sha256
    16: sha512
    17: abs
    18: add
    19: amount
    20: and
    21: balance
    22: car
    23: cdr
    24: check_signature
    25: compare
    26: concat
    27: cons
    28: create_account
    29: create_contract
    30: implicit_account
    31: dip
    32: drop
    33: dup
    34: ediv
    35: empty_map
    36: empty_set
    37: eq
    38: exec
    39: failwith
    40: ge
    41: get
    42: gt
    43: hash_key
    44: if
    45: if_cons
    46: if_left
    47: if_none
    48: int
    49: lambda
    50: le
    51: left
    52: loop
    53: lsl
    54: lsr
    55: lt
    56: map
    57: mem
    58: mul
    59: neg
    60: neq
    61: nil
    62: none
    63: not
    64: now
    65: or
    66: pair
    67: push
    68: right
    69: size
    70: some
    71: source
    72: sender
    73: self
    74: steps_to_quota
    75: sub
    76: swap
    77: transfer_tokens
    78: set_delegate
    79: unit
    80: update
    81: xor
    82: iter
    83: loop_left
    84: address
    85: contract
    86: isnat
    87: cast
    88: rename
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
    111: slice
    112: dig
    113: dug
    114: empty_big_map
    115: apply
    116: chain_id
    117: chain_id
    118: level
    119: self_address
    120: never
    121: never
    122: unpair
    123: voting_power
    124: total_voting_power
    125: keccak
    126: sha3
    127: pairing_check
    128: bls12_381_g1
    129: bls12_381_g2
    130: bls12_381_fr
    131: sapling_state
    132: sapling_transaction_deprecated
    133: sapling_empty_state
    134: sapling_verify_update
    135: ticket
    136: ticket_deprecated
    137: read_ticket
    138: split_ticket
    139: join_tickets
    140: get_and_update
    141: chest
    142: chest_key
    143: open_chest
    144: view
    145: view
    146: constant
    147: sub_mutez
    148: tx_rollup_l2_address
    149: min_block_time
    150: sapling_transaction
    151: emit
    152: lambda_rec
    153: lambda_rec
    154: ticket
    155: bytes
    156: nat
  zk_rollup_publish__some__prim__1_arg__no_annots__alpha__michelson__v1__primitives:
    0: parameter
    1: storage
    2: code
    3: false
    4: elt
    5: left
    6: none
    7: pair
    8: right
    9: some
    10: true
    11: unit
    12: pack
    13: unpack
    14: blake2b
    15: sha256
    16: sha512
    17: abs
    18: add
    19: amount
    20: and
    21: balance
    22: car
    23: cdr
    24: check_signature
    25: compare
    26: concat
    27: cons
    28: create_account
    29: create_contract
    30: implicit_account
    31: dip
    32: drop
    33: dup
    34: ediv
    35: empty_map
    36: empty_set
    37: eq
    38: exec
    39: failwith
    40: ge
    41: get
    42: gt
    43: hash_key
    44: if
    45: if_cons
    46: if_left
    47: if_none
    48: int
    49: lambda
    50: le
    51: left
    52: loop
    53: lsl
    54: lsr
    55: lt
    56: map
    57: mem
    58: mul
    59: neg
    60: neq
    61: nil
    62: none
    63: not
    64: now
    65: or
    66: pair
    67: push
    68: right
    69: size
    70: some
    71: source
    72: sender
    73: self
    74: steps_to_quota
    75: sub
    76: swap
    77: transfer_tokens
    78: set_delegate
    79: unit
    80: update
    81: xor
    82: iter
    83: loop_left
    84: address
    85: contract
    86: isnat
    87: cast
    88: rename
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
    111: slice
    112: dig
    113: dug
    114: empty_big_map
    115: apply
    116: chain_id
    117: chain_id
    118: level
    119: self_address
    120: never
    121: never
    122: unpair
    123: voting_power
    124: total_voting_power
    125: keccak
    126: sha3
    127: pairing_check
    128: bls12_381_g1
    129: bls12_381_g2
    130: bls12_381_fr
    131: sapling_state
    132: sapling_transaction_deprecated
    133: sapling_empty_state
    134: sapling_verify_update
    135: ticket
    136: ticket_deprecated
    137: read_ticket
    138: split_ticket
    139: join_tickets
    140: get_and_update
    141: chest
    142: chest_key
    143: open_chest
    144: view
    145: view
    146: constant
    147: sub_mutez
    148: tx_rollup_l2_address
    149: min_block_time
    150: sapling_transaction
    151: emit
    152: lambda_rec
    153: lambda_rec
    154: ticket
    155: bytes
    156: nat
  zk_rollup_publish__some__prim__no_args__some_annots__alpha__michelson__v1__primitives:
    0: parameter
    1: storage
    2: code
    3: false
    4: elt
    5: left
    6: none
    7: pair
    8: right
    9: some
    10: true
    11: unit
    12: pack
    13: unpack
    14: blake2b
    15: sha256
    16: sha512
    17: abs
    18: add
    19: amount
    20: and
    21: balance
    22: car
    23: cdr
    24: check_signature
    25: compare
    26: concat
    27: cons
    28: create_account
    29: create_contract
    30: implicit_account
    31: dip
    32: drop
    33: dup
    34: ediv
    35: empty_map
    36: empty_set
    37: eq
    38: exec
    39: failwith
    40: ge
    41: get
    42: gt
    43: hash_key
    44: if
    45: if_cons
    46: if_left
    47: if_none
    48: int
    49: lambda
    50: le
    51: left
    52: loop
    53: lsl
    54: lsr
    55: lt
    56: map
    57: mem
    58: mul
    59: neg
    60: neq
    61: nil
    62: none
    63: not
    64: now
    65: or
    66: pair
    67: push
    68: right
    69: size
    70: some
    71: source
    72: sender
    73: self
    74: steps_to_quota
    75: sub
    76: swap
    77: transfer_tokens
    78: set_delegate
    79: unit
    80: update
    81: xor
    82: iter
    83: loop_left
    84: address
    85: contract
    86: isnat
    87: cast
    88: rename
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
    111: slice
    112: dig
    113: dug
    114: empty_big_map
    115: apply
    116: chain_id
    117: chain_id
    118: level
    119: self_address
    120: never
    121: never
    122: unpair
    123: voting_power
    124: total_voting_power
    125: keccak
    126: sha3
    127: pairing_check
    128: bls12_381_g1
    129: bls12_381_g2
    130: bls12_381_fr
    131: sapling_state
    132: sapling_transaction_deprecated
    133: sapling_empty_state
    134: sapling_verify_update
    135: ticket
    136: ticket_deprecated
    137: read_ticket
    138: split_ticket
    139: join_tickets
    140: get_and_update
    141: chest
    142: chest_key
    143: open_chest
    144: view
    145: view
    146: constant
    147: sub_mutez
    148: tx_rollup_l2_address
    149: min_block_time
    150: sapling_transaction
    151: emit
    152: lambda_rec
    153: lambda_rec
    154: ticket
    155: bytes
    156: nat
  zk_rollup_publish__some__prim__no_args__no_annots__alpha__michelson__v1__primitives:
    0: parameter
    1: storage
    2: code
    3: false
    4: elt
    5: left
    6: none
    7: pair
    8: right
    9: some
    10: true
    11: unit
    12: pack
    13: unpack
    14: blake2b
    15: sha256
    16: sha512
    17: abs
    18: add
    19: amount
    20: and
    21: balance
    22: car
    23: cdr
    24: check_signature
    25: compare
    26: concat
    27: cons
    28: create_account
    29: create_contract
    30: implicit_account
    31: dip
    32: drop
    33: dup
    34: ediv
    35: empty_map
    36: empty_set
    37: eq
    38: exec
    39: failwith
    40: ge
    41: get
    42: gt
    43: hash_key
    44: if
    45: if_cons
    46: if_left
    47: if_none
    48: int
    49: lambda
    50: le
    51: left
    52: loop
    53: lsl
    54: lsr
    55: lt
    56: map
    57: mem
    58: mul
    59: neg
    60: neq
    61: nil
    62: none
    63: not
    64: now
    65: or
    66: pair
    67: push
    68: right
    69: size
    70: some
    71: source
    72: sender
    73: self
    74: steps_to_quota
    75: sub
    76: swap
    77: transfer_tokens
    78: set_delegate
    79: unit
    80: update
    81: xor
    82: iter
    83: loop_left
    84: address
    85: contract
    86: isnat
    87: cast
    88: rename
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
    111: slice
    112: dig
    113: dug
    114: empty_big_map
    115: apply
    116: chain_id
    117: chain_id
    118: level
    119: self_address
    120: never
    121: never
    122: unpair
    123: voting_power
    124: total_voting_power
    125: keccak
    126: sha3
    127: pairing_check
    128: bls12_381_g1
    129: bls12_381_g2
    130: bls12_381_fr
    131: sapling_state
    132: sapling_transaction_deprecated
    133: sapling_empty_state
    134: sapling_verify_update
    135: ticket
    136: ticket_deprecated
    137: read_ticket
    138: split_ticket
    139: join_tickets
    140: get_and_update
    141: chest
    142: chest_key
    143: open_chest
    144: view
    145: view
    146: constant
    147: sub_mutez
    148: tx_rollup_l2_address
    149: min_block_time
    150: sapling_transaction
    151: emit
    152: lambda_rec
    153: lambda_rec
    154: ticket
    155: bytes
    156: nat
  micheline__alpha__michelson_v1__expression_tag:
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
    2: riscv
  alpha__contract_id__originated_tag:
    1: originated
  alpha__entrypoint_tag:
    0: default
    1: root
    2: do
    3: set_delegate
    4: remove_delegate
    5: deposit
    6: stake
    7: unstake
    8: finalize_unstake
    9: set_delegate_parameters
    255: named
  alpha__contract_id_tag:
    0: implicit
    1: originated
  public_key_tag:
    0: ed25519
    1: secp256k1
    2: p256
    3: bls
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
    3: bls
  alpha__per_block_votes_tag:
    0: case__0
    1: case__1
    2: case__2
    4: case__4
    5: case__5
    6: case__6
    8: case__8
    9: case__9
    10: case__10
  alpha__inlined__attestation_mempool__contents_tag:
    21: attestation
  bool:
    0: false
    255: true
  alpha__inlined__preattestation__contents_tag:
    20: preattestation
  bls_signature_prefix_tag:
    3: bls_prefix
  alpha__operation__alpha__contents_or_signature_prefix_tag:
    1: seed_nonce_revelation
    2: double_attestation_evidence
    3: double_baking_evidence
    4: activate_account
    5: proposals
    6: ballot
    7: double_preattestation_evidence
    8: vdf_revelation
    9: drain_delegate
    17: failing_noop
    20: preattestation
    21: attestation
    22: dal_attestation
    107: reveal
    108: transaction
    109: origination
    110: delegation
    111: register_global_constant
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
    255: signature_prefix
seq:
- id: alpha__operation__alpha__contents_and_signature
  type: alpha__operation__alpha__contents_and_signature
