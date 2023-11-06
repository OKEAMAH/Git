meta:
  id: id_018__proxford__operation__contents
  endian: be
doc: ! 'Encoding id: 018-Proxford.operation.contents'
types:
  id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
    seq:
    - id: id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag
      type: u1
      enum: id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag
    - id: failing_noop__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      type: failing_noop__arbitrary
      if: (id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag
        == ::id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag::id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag::failing_noop)
    - id: register_global_constant__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      type: register_global_constant__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      if: (id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag
        == id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag::register_global_constant)
    - id: transfer_ticket__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      type: transfer_ticket__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      if: (id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag
        == id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag::transfer_ticket)
    - id: dal_publish_slot_header__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      type: dal_publish_slot_header__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      if: (id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag
        == id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag::dal_publish_slot_header)
    - id: smart_rollup_originate__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      type: smart_rollup_originate__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      if: (id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag
        == id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag::smart_rollup_originate)
    - id: smart_rollup_add_messages__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      type: smart_rollup_add_messages__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      if: (id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag
        == id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag::smart_rollup_add_messages)
    - id: smart_rollup_cement__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      type: smart_rollup_cement__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      if: (id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag
        == id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag::smart_rollup_cement)
    - id: smart_rollup_publish__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      type: smart_rollup_publish__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      if: (id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag
        == id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag::smart_rollup_publish)
    - id: smart_rollup_refute__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      type: smart_rollup_refute__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      if: (id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag
        == id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag::smart_rollup_refute)
    - id: smart_rollup_timeout__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      type: smart_rollup_timeout__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      if: (id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag
        == id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag::smart_rollup_timeout)
    - id: smart_rollup_execute_outbox_message__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      type: smart_rollup_execute_outbox_message__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      if: (id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag
        == id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag::smart_rollup_execute_outbox_message)
    - id: smart_rollup_recover_bond__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      type: smart_rollup_recover_bond__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      if: (id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag
        == id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag::smart_rollup_recover_bond)
    - id: zk_rollup_origination__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      type: zk_rollup_origination__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      if: (id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag
        == id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag::zk_rollup_origination)
    - id: zk_rollup_publish__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      type: zk_rollup_publish__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      if: (id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag
        == id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag::zk_rollup_publish)
    - id: zk_rollup_update__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      type: zk_rollup_update__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
      if: (id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag
        == id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag::zk_rollup_update)
  zk_rollup_update__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
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
    - id: zk_rollup_update__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  zk_rollup_publish__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
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
      type: zk_rollup_publish__some__micheline__018__proxford__michelson_v1__expression
    - id: ty
      type: micheline__018__proxford__michelson_v1__expression
    - id: ticketer
      type: zk_rollup_publish__some__id_018__proxford__contract_id
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
  zk_rollup_publish__some__id_018__proxford__contract_id:
    seq:
    - id: id_018__proxford__contract_id_tag
      type: u1
      enum: id_018__proxford__contract_id_tag
    - id: zk_rollup_publish__some__implicit__id_018__proxford__contract_id
      type: zk_rollup_publish__some__implicit__public_key_hash
      if: (id_018__proxford__contract_id_tag == ::id_018__proxford__contract_id_tag::id_018__proxford__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: zk_rollup_publish__some__originated__id_018__proxford__contract_id
      type: zk_rollup_publish__some__originated__id_018__proxford__contract_id
      if: (id_018__proxford__contract_id_tag == id_018__proxford__contract_id_tag::originated)
  zk_rollup_publish__some__originated__id_018__proxford__contract_id:
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
    - id: zk_rollup_publish__some__implicit__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  zk_rollup_publish__some__micheline__018__proxford__michelson_v1__expression:
    seq:
    - id: micheline__018__proxford__michelson_v1__expression_tag
      type: u1
      enum: micheline__018__proxford__michelson_v1__expression_tag
    - id: zk_rollup_publish__some__bytes__micheline__018__proxford__michelson_v1__expression
      type: zk_rollup_publish__some__bytes__bytes
      if: (micheline__018__proxford__michelson_v1__expression_tag == ::micheline__018__proxford__michelson_v1__expression_tag::micheline__018__proxford__michelson_v1__expression_tag::bytes)
  zk_rollup_publish__some__bytes__bytes:
    seq:
    - id: len_bytes
      type: u4
      valid:
        max: 1073741823
    - id: bytes
      size: len_bytes
  zk_rollup_publish__some__prim__generic__micheline__018__proxford__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__generic__id_018__proxford__michelson__v1__primitives
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
      type: micheline__018__proxford__michelson_v1__expression
  zk_rollup_publish__some__prim__2_args__some_annots__micheline__018__proxford__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__2_args__some_annots__id_018__proxford__michelson__v1__primitives
    - id: arg1
      type: micheline__018__proxford__michelson_v1__expression
    - id: arg2
      type: micheline__018__proxford__michelson_v1__expression
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
  zk_rollup_publish__some__prim__2_args__no_annots__micheline__018__proxford__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__2_args__no_annots__id_018__proxford__michelson__v1__primitives
    - id: arg1
      type: micheline__018__proxford__michelson_v1__expression
    - id: arg2
      type: micheline__018__proxford__michelson_v1__expression
  zk_rollup_publish__some__prim__1_arg__some_annots__micheline__018__proxford__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__1_arg__some_annots__id_018__proxford__michelson__v1__primitives
    - id: arg
      type: micheline__018__proxford__michelson_v1__expression
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
  zk_rollup_publish__some__prim__1_arg__no_annots__micheline__018__proxford__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__1_arg__no_annots__id_018__proxford__michelson__v1__primitives
    - id: arg
      type: micheline__018__proxford__michelson_v1__expression
  zk_rollup_publish__some__prim__no_args__some_annots__micheline__018__proxford__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__no_args__some_annots__id_018__proxford__michelson__v1__primitives
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
  zk_rollup_publish__some__sequence__micheline__018__proxford__michelson_v1__expression:
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
      type: micheline__018__proxford__michelson_v1__expression
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
    - id: zk_rollup_publish__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  zk_rollup_origination__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
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
    - id: zk_rollup_origination__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  smart_rollup_recover_bond__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
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
    - id: smart_rollup_recover_bond__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  smart_rollup_execute_outbox_message__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
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
    - id: smart_rollup_execute_outbox_message__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  smart_rollup_timeout__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
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
    - id: smart_rollup_timeout__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  smart_rollup_refute__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
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
    - id: smart_rollup_refute__move__proof__reveal__proof__input_proof
      type: smart_rollup_refute__move__proof__reveal__proof__reveal_proof
      if: (input_proof_tag == ::input_proof_tag::input_proof_tag::reveal__proof)
  smart_rollup_refute__move__proof__reveal__proof__reveal_proof:
    seq:
    - id: reveal_proof_tag
      type: u1
      enum: reveal_proof_tag
    - id: smart_rollup_refute__move__proof__reveal__proof__raw__data__proof__reveal_proof
      type: smart_rollup_refute__move__proof__reveal__proof__raw__data__proof__raw_data
      if: (reveal_proof_tag == ::reveal_proof_tag::reveal_proof_tag::raw__data__proof)
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
    - id: smart_rollup_refute__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  smart_rollup_publish__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
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
    - id: smart_rollup_publish__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  smart_rollup_cement__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
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
    - id: smart_rollup_cement__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  smart_rollup_add_messages__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
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
    - id: smart_rollup_add_messages__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  smart_rollup_originate__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
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
    - id: smart_rollup_originate__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  dal_publish_slot_header__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
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
    - id: dal_publish_slot_header__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  transfer_ticket__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
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
      type: transfer_ticket__id_018__proxford__contract_id
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: ticket_amount
      type: n
    - id: destination
      type: transfer_ticket__id_018__proxford__contract_id
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
  transfer_ticket__id_018__proxford__contract_id:
    seq:
    - id: id_018__proxford__contract_id_tag
      type: u1
      enum: id_018__proxford__contract_id_tag
    - id: transfer_ticket__implicit__id_018__proxford__contract_id
      type: transfer_ticket__implicit__public_key_hash
      if: (id_018__proxford__contract_id_tag == ::id_018__proxford__contract_id_tag::id_018__proxford__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: transfer_ticket__originated__id_018__proxford__contract_id
      type: transfer_ticket__originated__id_018__proxford__contract_id
      if: (id_018__proxford__contract_id_tag == id_018__proxford__contract_id_tag::originated)
  transfer_ticket__originated__id_018__proxford__contract_id:
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
    - id: transfer_ticket__implicit__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
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
    - id: transfer_ticket__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  register_global_constant__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
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
    - id: register_global_constant__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  failing_noop__arbitrary:
    seq:
    - id: len_arbitrary
      type: u4
      valid:
        max: 1073741823
    - id: arbitrary
      size: len_arbitrary
  drain_delegate__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
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
    - id: drain_delegate__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  update_consensus_key__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
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
    - id: update_consensus_key__bls__public_key
      size: 48
      if: (public_key_tag == ::public_key_tag::public_key_tag::bls)
  update_consensus_key__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: update_consensus_key__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  increase_paid_storage__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
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
      type: increase_paid_storage__id_018__proxford__contract_id__originated
      doc: ! >-
        A contract handle -- originated account: A contract notation as given to an
        RPC or inside scripts. Can be a base58 originated contract hash.
  increase_paid_storage__id_018__proxford__contract_id__originated:
    seq:
    - id: id_018__proxford__contract_id__originated_tag
      type: u1
      enum: id_018__proxford__contract_id__originated_tag
    - id: increase_paid_storage__originated__id_018__proxford__contract_id__originated
      type: increase_paid_storage__originated__id_018__proxford__contract_id__originated
      if: (id_018__proxford__contract_id__originated_tag == id_018__proxford__contract_id__originated_tag::originated)
  increase_paid_storage__originated__id_018__proxford__contract_id__originated:
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
    - id: increase_paid_storage__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  delegation__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
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
    - id: delegation__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  origination__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
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
      type: origination__id_018__proxford__scripted__contracts
  origination__id_018__proxford__scripted__contracts:
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
    - id: origination__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  transaction__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
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
      type: transaction__id_018__proxford__contract_id
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
      type: transaction__id_018__proxford__entrypoint
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
  transaction__id_018__proxford__entrypoint:
    seq:
    - id: id_018__proxford__entrypoint_tag
      type: u1
      enum: id_018__proxford__entrypoint_tag
    - id: transaction__named__id_018__proxford__entrypoint
      type: transaction__named__id_018__proxford__entrypoint
      if: (id_018__proxford__entrypoint_tag == id_018__proxford__entrypoint_tag::named)
  transaction__named__id_018__proxford__entrypoint:
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
  transaction__id_018__proxford__contract_id:
    seq:
    - id: id_018__proxford__contract_id_tag
      type: u1
      enum: id_018__proxford__contract_id_tag
    - id: transaction__implicit__id_018__proxford__contract_id
      type: transaction__implicit__public_key_hash
      if: (id_018__proxford__contract_id_tag == ::id_018__proxford__contract_id_tag::id_018__proxford__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, P256, or BLS public key hash
    - id: transaction__originated__id_018__proxford__contract_id
      type: transaction__originated__id_018__proxford__contract_id
      if: (id_018__proxford__contract_id_tag == id_018__proxford__contract_id_tag::originated)
  transaction__originated__id_018__proxford__contract_id:
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
    - id: transaction__implicit__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  transaction__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: transaction__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  reveal__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
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
    - id: reveal__bls__public_key
      size: 48
      if: (public_key_tag == ::public_key_tag::public_key_tag::bls)
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
    - id: reveal__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  ballot__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
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
    - id: ballot__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  proposals__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
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
    - id: proposals__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  activate_account__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
    seq:
    - id: pkh
      size: 20
    - id: secret
      size: 20
  double_baking_evidence__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
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
      type: double_baking_evidence__id_018__proxford__block_header__alpha__full_header
      size: len_bh2
  double_baking_evidence__bh1:
    seq:
    - id: len_bh1
      type: u4
      valid:
        max: 1073741823
    - id: bh1
      type: double_baking_evidence__id_018__proxford__block_header__alpha__full_header
      size: len_bh1
  double_baking_evidence__id_018__proxford__block_header__alpha__full_header:
    seq:
    - id: double_baking_evidence__block_header__shell
      type: double_baking_evidence__block_header__shell
      doc: ! >-
        Shell header: Block header's shell-related content. It contains information
        such as the block level, its predecessor and timestamp.
    - id: double_baking_evidence__id_018__proxford__block_header__alpha__signed_contents
      type: double_baking_evidence__id_018__proxford__block_header__alpha__signed_contents
  double_baking_evidence__id_018__proxford__block_header__alpha__signed_contents:
    seq:
    - id: double_baking_evidence__id_018__proxford__block_header__alpha__unsigned_contents
      type: double_baking_evidence__id_018__proxford__block_header__alpha__unsigned_contents
    - id: signature
      size-eos: true
  double_baking_evidence__id_018__proxford__block_header__alpha__unsigned_contents:
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
      enum: id_018__proxford__per_block_votes_tag
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
  seed_nonce_revelation__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
    seq:
    - id: level
      type: s4
    - id: nonce
      size: 32
  dal_attestation__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
    seq:
    - id: attestor
      type: dal_attestation__public_key_hash
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
  dal_attestation__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: dal_attestation__bls__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::bls)
  double_endorsement_evidence__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
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
      type: double_endorsement_evidence__id_018__proxford__inlined__endorsement
      size: len_op2
  double_endorsement_evidence__op1:
    seq:
    - id: len_op1
      type: u4
      valid:
        max: 1073741823
    - id: op1
      type: double_endorsement_evidence__id_018__proxford__inlined__endorsement
      size: len_op1
  double_endorsement_evidence__id_018__proxford__inlined__endorsement:
    seq:
    - id: operation__shell_header
      size: 32
      doc: An operation's shell header.
    - id: operations
      type: double_endorsement_evidence__id_018__proxford__inlined__endorsement_mempool__contents
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size-eos: true
      if: (signature_tag == bool::true)
  double_endorsement_evidence__id_018__proxford__inlined__endorsement_mempool__contents:
    seq:
    - id: id_018__proxford__inlined__endorsement_mempool__contents_tag
      type: u1
      enum: id_018__proxford__inlined__endorsement_mempool__contents_tag
    - id: double_endorsement_evidence__endorsement__id_018__proxford__inlined__endorsement_mempool__contents
      type: double_endorsement_evidence__endorsement__id_018__proxford__inlined__endorsement_mempool__contents
      if: (id_018__proxford__inlined__endorsement_mempool__contents_tag == id_018__proxford__inlined__endorsement_mempool__contents_tag::endorsement)
  double_endorsement_evidence__endorsement__id_018__proxford__inlined__endorsement_mempool__contents:
    seq:
    - id: slot
      type: u2
    - id: level
      type: s4
    - id: round
      type: s4
    - id: block_payload_hash
      size: 32
  double_preendorsement_evidence__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
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
      type: double_preendorsement_evidence__id_018__proxford__inlined__preendorsement
      size: len_op2
  double_preendorsement_evidence__op1:
    seq:
    - id: len_op1
      type: u4
      valid:
        max: 1073741823
    - id: op1
      type: double_preendorsement_evidence__id_018__proxford__inlined__preendorsement
      size: len_op1
  double_preendorsement_evidence__id_018__proxford__inlined__preendorsement:
    seq:
    - id: operation__shell_header
      size: 32
      doc: An operation's shell header.
    - id: operations
      type: double_preendorsement_evidence__id_018__proxford__inlined__preendorsement__contents
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size-eos: true
      if: (signature_tag == bool::true)
  double_preendorsement_evidence__id_018__proxford__inlined__preendorsement__contents:
    seq:
    - id: id_018__proxford__inlined__preendorsement__contents_tag
      type: u1
      enum: id_018__proxford__inlined__preendorsement__contents_tag
    - id: double_preendorsement_evidence__preendorsement__id_018__proxford__inlined__preendorsement__contents
      type: double_preendorsement_evidence__preendorsement__id_018__proxford__inlined__preendorsement__contents
      if: (id_018__proxford__inlined__preendorsement__contents_tag == id_018__proxford__inlined__preendorsement__contents_tag::preendorsement)
  double_preendorsement_evidence__preendorsement__id_018__proxford__inlined__preendorsement__contents:
    seq:
    - id: slot
      type: u2
    - id: level
      type: s4
    - id: round
      type: s4
    - id: block_payload_hash
      size: 32
  endorsement__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
    seq:
    - id: slot
      type: u2
    - id: level
      type: s4
    - id: round
      type: s4
    - id: block_payload_hash
      size: 32
  preendorsement__id_018__proxford__operation_with_legacy_attestation_name__alpha__contents:
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
  zk_rollup_publish__some__prim__generic__id_018__proxford__michelson__v1__primitives:
    2: code
    111: slice
    38: exec
    26: concat
    32: drop
    72: sender
    57: mem
    40: ge
    37: eq
    137: read_ticket
    120: never
    81: xor
    36: empty_set
    144: view
    136: ticket_deprecated
    85: contract
    83: loop_left
    77: transfer_tokens
    64: now
    41: get
    46: if_left
    62: none
    131: sapling_state
    106: mutez
    140: get_and_update
    90: contract
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    105: bytes
    52: loop
    34: ediv
    129: bls12_381_g2
    142: chest_key
    138: split_ticket
    141: chest
    5: left
    51: left
    125: keccak
    99: option
    48: int
    58: mul
    35: empty_map
    76: swap
    132: sapling_transaction_deprecated
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    146: constant
    66: pair
    124: total_voting_power
    80: update
    22: car
    101: pair
    61: nil
    21: balance
    95: list
    70: some
    143: open_chest
    67: push
    39: failwith
    82: iter
    60: neq
    87: cast
    11: unit
    28: create_account
    68: right
    49: lambda
    147: sub_mutez
    100: or
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    97: big_map
    123: voting_power
    96: map
    18: add
    93: key_hash
    75: sub
    6: none
    114: empty_big_map
    135: ticket
    103: signature
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    155: bytes
    4: elt
    115: apply
    56: map
    116: chain_id
    25: compare
    20: and
    94: lambda
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    104: string
    148: tx_rollup_l2_address
    109: operation
    128: bls12_381_g1
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    110: address
    92: key
    54: lsr
    102: set
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    89: bool
    59: neg
    98: nat
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    107: timestamp
    91: int
    47: if_none
    7: pair
    130: bls12_381_fr
    108: unit
    156: nat
    13: unpack
    150: sapling_transaction
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  zk_rollup_publish__some__prim__2_args__some_annots__id_018__proxford__michelson__v1__primitives:
    2: code
    111: slice
    38: exec
    26: concat
    32: drop
    72: sender
    57: mem
    40: ge
    37: eq
    137: read_ticket
    120: never
    81: xor
    36: empty_set
    144: view
    136: ticket_deprecated
    85: contract
    83: loop_left
    77: transfer_tokens
    64: now
    41: get
    46: if_left
    62: none
    131: sapling_state
    106: mutez
    140: get_and_update
    90: contract
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    105: bytes
    52: loop
    34: ediv
    129: bls12_381_g2
    142: chest_key
    138: split_ticket
    141: chest
    5: left
    51: left
    125: keccak
    99: option
    48: int
    58: mul
    35: empty_map
    76: swap
    132: sapling_transaction_deprecated
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    146: constant
    66: pair
    124: total_voting_power
    80: update
    22: car
    101: pair
    61: nil
    21: balance
    95: list
    70: some
    143: open_chest
    67: push
    39: failwith
    82: iter
    60: neq
    87: cast
    11: unit
    28: create_account
    68: right
    49: lambda
    147: sub_mutez
    100: or
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    97: big_map
    123: voting_power
    96: map
    18: add
    93: key_hash
    75: sub
    6: none
    114: empty_big_map
    135: ticket
    103: signature
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    155: bytes
    4: elt
    115: apply
    56: map
    116: chain_id
    25: compare
    20: and
    94: lambda
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    104: string
    148: tx_rollup_l2_address
    109: operation
    128: bls12_381_g1
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    110: address
    92: key
    54: lsr
    102: set
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    89: bool
    59: neg
    98: nat
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    107: timestamp
    91: int
    47: if_none
    7: pair
    130: bls12_381_fr
    108: unit
    156: nat
    13: unpack
    150: sapling_transaction
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  zk_rollup_publish__some__prim__2_args__no_annots__id_018__proxford__michelson__v1__primitives:
    2: code
    111: slice
    38: exec
    26: concat
    32: drop
    72: sender
    57: mem
    40: ge
    37: eq
    137: read_ticket
    120: never
    81: xor
    36: empty_set
    144: view
    136: ticket_deprecated
    85: contract
    83: loop_left
    77: transfer_tokens
    64: now
    41: get
    46: if_left
    62: none
    131: sapling_state
    106: mutez
    140: get_and_update
    90: contract
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    105: bytes
    52: loop
    34: ediv
    129: bls12_381_g2
    142: chest_key
    138: split_ticket
    141: chest
    5: left
    51: left
    125: keccak
    99: option
    48: int
    58: mul
    35: empty_map
    76: swap
    132: sapling_transaction_deprecated
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    146: constant
    66: pair
    124: total_voting_power
    80: update
    22: car
    101: pair
    61: nil
    21: balance
    95: list
    70: some
    143: open_chest
    67: push
    39: failwith
    82: iter
    60: neq
    87: cast
    11: unit
    28: create_account
    68: right
    49: lambda
    147: sub_mutez
    100: or
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    97: big_map
    123: voting_power
    96: map
    18: add
    93: key_hash
    75: sub
    6: none
    114: empty_big_map
    135: ticket
    103: signature
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    155: bytes
    4: elt
    115: apply
    56: map
    116: chain_id
    25: compare
    20: and
    94: lambda
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    104: string
    148: tx_rollup_l2_address
    109: operation
    128: bls12_381_g1
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    110: address
    92: key
    54: lsr
    102: set
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    89: bool
    59: neg
    98: nat
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    107: timestamp
    91: int
    47: if_none
    7: pair
    130: bls12_381_fr
    108: unit
    156: nat
    13: unpack
    150: sapling_transaction
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  zk_rollup_publish__some__prim__1_arg__some_annots__id_018__proxford__michelson__v1__primitives:
    2: code
    111: slice
    38: exec
    26: concat
    32: drop
    72: sender
    57: mem
    40: ge
    37: eq
    137: read_ticket
    120: never
    81: xor
    36: empty_set
    144: view
    136: ticket_deprecated
    85: contract
    83: loop_left
    77: transfer_tokens
    64: now
    41: get
    46: if_left
    62: none
    131: sapling_state
    106: mutez
    140: get_and_update
    90: contract
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    105: bytes
    52: loop
    34: ediv
    129: bls12_381_g2
    142: chest_key
    138: split_ticket
    141: chest
    5: left
    51: left
    125: keccak
    99: option
    48: int
    58: mul
    35: empty_map
    76: swap
    132: sapling_transaction_deprecated
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    146: constant
    66: pair
    124: total_voting_power
    80: update
    22: car
    101: pair
    61: nil
    21: balance
    95: list
    70: some
    143: open_chest
    67: push
    39: failwith
    82: iter
    60: neq
    87: cast
    11: unit
    28: create_account
    68: right
    49: lambda
    147: sub_mutez
    100: or
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    97: big_map
    123: voting_power
    96: map
    18: add
    93: key_hash
    75: sub
    6: none
    114: empty_big_map
    135: ticket
    103: signature
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    155: bytes
    4: elt
    115: apply
    56: map
    116: chain_id
    25: compare
    20: and
    94: lambda
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    104: string
    148: tx_rollup_l2_address
    109: operation
    128: bls12_381_g1
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    110: address
    92: key
    54: lsr
    102: set
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    89: bool
    59: neg
    98: nat
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    107: timestamp
    91: int
    47: if_none
    7: pair
    130: bls12_381_fr
    108: unit
    156: nat
    13: unpack
    150: sapling_transaction
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  zk_rollup_publish__some__prim__1_arg__no_annots__id_018__proxford__michelson__v1__primitives:
    2: code
    111: slice
    38: exec
    26: concat
    32: drop
    72: sender
    57: mem
    40: ge
    37: eq
    137: read_ticket
    120: never
    81: xor
    36: empty_set
    144: view
    136: ticket_deprecated
    85: contract
    83: loop_left
    77: transfer_tokens
    64: now
    41: get
    46: if_left
    62: none
    131: sapling_state
    106: mutez
    140: get_and_update
    90: contract
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    105: bytes
    52: loop
    34: ediv
    129: bls12_381_g2
    142: chest_key
    138: split_ticket
    141: chest
    5: left
    51: left
    125: keccak
    99: option
    48: int
    58: mul
    35: empty_map
    76: swap
    132: sapling_transaction_deprecated
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    146: constant
    66: pair
    124: total_voting_power
    80: update
    22: car
    101: pair
    61: nil
    21: balance
    95: list
    70: some
    143: open_chest
    67: push
    39: failwith
    82: iter
    60: neq
    87: cast
    11: unit
    28: create_account
    68: right
    49: lambda
    147: sub_mutez
    100: or
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    97: big_map
    123: voting_power
    96: map
    18: add
    93: key_hash
    75: sub
    6: none
    114: empty_big_map
    135: ticket
    103: signature
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    155: bytes
    4: elt
    115: apply
    56: map
    116: chain_id
    25: compare
    20: and
    94: lambda
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    104: string
    148: tx_rollup_l2_address
    109: operation
    128: bls12_381_g1
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    110: address
    92: key
    54: lsr
    102: set
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    89: bool
    59: neg
    98: nat
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    107: timestamp
    91: int
    47: if_none
    7: pair
    130: bls12_381_fr
    108: unit
    156: nat
    13: unpack
    150: sapling_transaction
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  zk_rollup_publish__some__prim__no_args__some_annots__id_018__proxford__michelson__v1__primitives:
    2: code
    111: slice
    38: exec
    26: concat
    32: drop
    72: sender
    57: mem
    40: ge
    37: eq
    137: read_ticket
    120: never
    81: xor
    36: empty_set
    144: view
    136: ticket_deprecated
    85: contract
    83: loop_left
    77: transfer_tokens
    64: now
    41: get
    46: if_left
    62: none
    131: sapling_state
    106: mutez
    140: get_and_update
    90: contract
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    105: bytes
    52: loop
    34: ediv
    129: bls12_381_g2
    142: chest_key
    138: split_ticket
    141: chest
    5: left
    51: left
    125: keccak
    99: option
    48: int
    58: mul
    35: empty_map
    76: swap
    132: sapling_transaction_deprecated
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    146: constant
    66: pair
    124: total_voting_power
    80: update
    22: car
    101: pair
    61: nil
    21: balance
    95: list
    70: some
    143: open_chest
    67: push
    39: failwith
    82: iter
    60: neq
    87: cast
    11: unit
    28: create_account
    68: right
    49: lambda
    147: sub_mutez
    100: or
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    97: big_map
    123: voting_power
    96: map
    18: add
    93: key_hash
    75: sub
    6: none
    114: empty_big_map
    135: ticket
    103: signature
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    155: bytes
    4: elt
    115: apply
    56: map
    116: chain_id
    25: compare
    20: and
    94: lambda
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    104: string
    148: tx_rollup_l2_address
    109: operation
    128: bls12_381_g1
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    110: address
    92: key
    54: lsr
    102: set
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    89: bool
    59: neg
    98: nat
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    107: timestamp
    91: int
    47: if_none
    7: pair
    130: bls12_381_fr
    108: unit
    156: nat
    13: unpack
    150: sapling_transaction
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  zk_rollup_publish__some__prim__no_args__no_annots__id_018__proxford__michelson__v1__primitives:
    2: code
    111: slice
    38: exec
    26: concat
    32: drop
    72: sender
    57: mem
    40: ge
    37: eq
    137: read_ticket
    120: never
    81: xor
    36: empty_set
    144: view
    136: ticket_deprecated
    85: contract
    83: loop_left
    77: transfer_tokens
    64: now
    41: get
    46: if_left
    62: none
    131: sapling_state
    106: mutez
    140: get_and_update
    90: contract
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    105: bytes
    52: loop
    34: ediv
    129: bls12_381_g2
    142: chest_key
    138: split_ticket
    141: chest
    5: left
    51: left
    125: keccak
    99: option
    48: int
    58: mul
    35: empty_map
    76: swap
    132: sapling_transaction_deprecated
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    146: constant
    66: pair
    124: total_voting_power
    80: update
    22: car
    101: pair
    61: nil
    21: balance
    95: list
    70: some
    143: open_chest
    67: push
    39: failwith
    82: iter
    60: neq
    87: cast
    11: unit
    28: create_account
    68: right
    49: lambda
    147: sub_mutez
    100: or
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    97: big_map
    123: voting_power
    96: map
    18: add
    93: key_hash
    75: sub
    6: none
    114: empty_big_map
    135: ticket
    103: signature
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    155: bytes
    4: elt
    115: apply
    56: map
    116: chain_id
    25: compare
    20: and
    94: lambda
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    104: string
    148: tx_rollup_l2_address
    109: operation
    128: bls12_381_g1
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    110: address
    92: key
    54: lsr
    102: set
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    89: bool
    59: neg
    98: nat
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    107: timestamp
    91: int
    47: if_none
    7: pair
    130: bls12_381_fr
    108: unit
    156: nat
    13: unpack
    150: sapling_transaction
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  micheline__018__proxford__michelson_v1__expression_tag:
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
  id_018__proxford__contract_id__originated_tag:
    1: originated
  id_018__proxford__entrypoint_tag:
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
  id_018__proxford__contract_id_tag:
    0: implicit
    1: originated
  public_key_tag:
    0: ed25519
    1: secp256k1
    2: p256
    3: bls
  id_018__proxford__per_block_votes_tag:
    0: case__0
    1: case__1
    2: case__2
    4: case__4
    5: case__5
    6: case__6
    8: case__8
    9: case__9
    10: case__10
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
    3: bls
  id_018__proxford__inlined__endorsement_mempool__contents_tag:
    21: endorsement
  bool:
    0: false
    255: true
  id_018__proxford__inlined__preendorsement__contents_tag:
    20: preendorsement
  id_018__proxford__operation_with_legacy_attestation_name__alpha__contents_tag:
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
- id: id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
  type: id_018__proxford__operation_with_legacy_attestation_name__alpha__contents
