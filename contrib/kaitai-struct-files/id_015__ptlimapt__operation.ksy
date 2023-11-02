meta:
  id: id_015__ptlimapt__operation
  endian: be
doc: ! 'Encoding id: 015-PtLimaPt.operation'
types:
  id_015__ptlimapt__operation__alpha__contents_and_signature:
    seq:
    - id: contents
      type: contents_entries
      repeat: eos
    - id: signature
      size: 64
  contents_entries:
    seq:
    - id: id_015__ptlimapt__operation__alpha__contents
      type: id_015__ptlimapt__operation__alpha__contents
  id_015__ptlimapt__operation__alpha__contents:
    seq:
    - id: id_015__ptlimapt__operation__alpha__contents_tag
      type: u1
      enum: id_015__ptlimapt__operation__alpha__contents_tag
    - id: failing_noop__id_015__ptlimapt__operation__alpha__contents
      type: failing_noop__arbitrary
      if: (id_015__ptlimapt__operation__alpha__contents_tag == ::id_015__ptlimapt__operation__alpha__contents_tag::id_015__ptlimapt__operation__alpha__contents_tag::failing_noop)
    - id: register_global_constant__id_015__ptlimapt__operation__alpha__contents
      type: register_global_constant__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::register_global_constant)
    - id: tx_rollup_origination__id_015__ptlimapt__operation__alpha__contents
      type: tx_rollup_origination__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::tx_rollup_origination)
    - id: tx_rollup_submit_batch__id_015__ptlimapt__operation__alpha__contents
      type: tx_rollup_submit_batch__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::tx_rollup_submit_batch)
    - id: tx_rollup_commit__id_015__ptlimapt__operation__alpha__contents
      type: tx_rollup_commit__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::tx_rollup_commit)
    - id: tx_rollup_return_bond__id_015__ptlimapt__operation__alpha__contents
      type: tx_rollup_return_bond__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::tx_rollup_return_bond)
    - id: tx_rollup_finalize_commitment__id_015__ptlimapt__operation__alpha__contents
      type: tx_rollup_finalize_commitment__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::tx_rollup_finalize_commitment)
    - id: tx_rollup_remove_commitment__id_015__ptlimapt__operation__alpha__contents
      type: tx_rollup_remove_commitment__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::tx_rollup_remove_commitment)
    - id: tx_rollup_rejection__id_015__ptlimapt__operation__alpha__contents
      type: tx_rollup_rejection__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::tx_rollup_rejection)
    - id: tx_rollup_dispatch_tickets__id_015__ptlimapt__operation__alpha__contents
      type: tx_rollup_dispatch_tickets__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::tx_rollup_dispatch_tickets)
    - id: transfer_ticket__id_015__ptlimapt__operation__alpha__contents
      type: transfer_ticket__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::transfer_ticket)
    - id: dal_publish_slot_header__id_015__ptlimapt__operation__alpha__contents
      type: dal_publish_slot_header__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::dal_publish_slot_header)
    - id: sc_rollup_originate__id_015__ptlimapt__operation__alpha__contents
      type: sc_rollup_originate__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::sc_rollup_originate)
    - id: sc_rollup_add_messages__id_015__ptlimapt__operation__alpha__contents
      type: sc_rollup_add_messages__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::sc_rollup_add_messages)
    - id: sc_rollup_cement__id_015__ptlimapt__operation__alpha__contents
      type: sc_rollup_cement__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::sc_rollup_cement)
    - id: sc_rollup_publish__id_015__ptlimapt__operation__alpha__contents
      type: sc_rollup_publish__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::sc_rollup_publish)
    - id: sc_rollup_refute__id_015__ptlimapt__operation__alpha__contents
      type: sc_rollup_refute__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::sc_rollup_refute)
    - id: sc_rollup_timeout__id_015__ptlimapt__operation__alpha__contents
      type: sc_rollup_timeout__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::sc_rollup_timeout)
    - id: sc_rollup_execute_outbox_message__id_015__ptlimapt__operation__alpha__contents
      type: sc_rollup_execute_outbox_message__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::sc_rollup_execute_outbox_message)
    - id: sc_rollup_recover_bond__id_015__ptlimapt__operation__alpha__contents
      type: sc_rollup_recover_bond__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::sc_rollup_recover_bond)
    - id: sc_rollup_dal_slot_subscribe__id_015__ptlimapt__operation__alpha__contents
      type: sc_rollup_dal_slot_subscribe__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::sc_rollup_dal_slot_subscribe)
    - id: zk_rollup_origination__id_015__ptlimapt__operation__alpha__contents
      type: zk_rollup_origination__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::zk_rollup_origination)
    - id: zk_rollup_publish__id_015__ptlimapt__operation__alpha__contents
      type: zk_rollup_publish__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::zk_rollup_publish)
  zk_rollup_publish__id_015__ptlimapt__operation__alpha__contents:
    seq:
    - id: source
      type: zk_rollup_publish__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
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
    - id: size_of_op
      type: u4
      valid:
        max: 1073741823
    - id: op
      type: zk_rollup_publish__op_entries
      size: size_of_op
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
      type: zk_rollup_publish__some__micheline__015__ptlimapt__michelson_v1__expression
    - id: ty
      type: micheline__015__ptlimapt__michelson_v1__expression
    - id: ticketer
      type: zk_rollup_publish__some__id_015__ptlimapt__contract_id
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
  zk_rollup_publish__some__id_015__ptlimapt__contract_id:
    seq:
    - id: id_015__ptlimapt__contract_id_tag
      type: u1
      enum: id_015__ptlimapt__contract_id_tag
    - id: zk_rollup_publish__some__implicit__id_015__ptlimapt__contract_id
      type: zk_rollup_publish__some__implicit__public_key_hash
      if: (id_015__ptlimapt__contract_id_tag == ::id_015__ptlimapt__contract_id_tag::id_015__ptlimapt__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: zk_rollup_publish__some__originated__id_015__ptlimapt__contract_id
      type: zk_rollup_publish__some__originated__id_015__ptlimapt__contract_id
      if: (id_015__ptlimapt__contract_id_tag == id_015__ptlimapt__contract_id_tag::originated)
  zk_rollup_publish__some__originated__id_015__ptlimapt__contract_id:
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
    - id: zk_rollup_publish__some__implicit__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  zk_rollup_publish__some__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: micheline__015__ptlimapt__michelson_v1__expression_tag
      type: u1
      enum: micheline__015__ptlimapt__michelson_v1__expression_tag
    - id: zk_rollup_publish__some__bytes__micheline__015__ptlimapt__michelson_v1__expression
      type: zk_rollup_publish__some__bytes__bytes
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == ::micheline__015__ptlimapt__michelson_v1__expression_tag::micheline__015__ptlimapt__michelson_v1__expression_tag::bytes)
  zk_rollup_publish__some__bytes__bytes:
    seq:
    - id: size_of_bytes
      type: u4
      valid:
        max: 1073741823
    - id: bytes
      size: size_of_bytes
  zk_rollup_publish__some__prim__generic__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__generic__id_015__ptlimapt__michelson__v1__primitives
    - id: zk_rollup_publish__some__prim__generic__args
      type: zk_rollup_publish__some__prim__generic__args
    - id: zk_rollup_publish__some__prim__generic__annots
      type: zk_rollup_publish__some__prim__generic__annots
  zk_rollup_publish__some__prim__generic__annots:
    seq:
    - id: size_of_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: size_of_annots
  zk_rollup_publish__some__prim__generic__args:
    seq:
    - id: size_of_args
      type: u4
      valid:
        max: 1073741823
    - id: args
      type: zk_rollup_publish__some__prim__generic__args_entries
      size: size_of_args
      repeat: eos
  zk_rollup_publish__some__prim__generic__args_entries:
    seq:
    - id: args_elt
      type: micheline__015__ptlimapt__michelson_v1__expression
  zk_rollup_publish__some__prim__2_args__some_annots__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__2_args__some_annots__id_015__ptlimapt__michelson__v1__primitives
    - id: arg1
      type: micheline__015__ptlimapt__michelson_v1__expression
    - id: arg2
      type: micheline__015__ptlimapt__michelson_v1__expression
    - id: zk_rollup_publish__some__prim__2_args__some_annots__annots
      type: zk_rollup_publish__some__prim__2_args__some_annots__annots
  zk_rollup_publish__some__prim__2_args__some_annots__annots:
    seq:
    - id: size_of_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: size_of_annots
  zk_rollup_publish__some__prim__2_args__no_annots__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__2_args__no_annots__id_015__ptlimapt__michelson__v1__primitives
    - id: arg1
      type: micheline__015__ptlimapt__michelson_v1__expression
    - id: arg2
      type: micheline__015__ptlimapt__michelson_v1__expression
  zk_rollup_publish__some__prim__1_arg__some_annots__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__1_arg__some_annots__id_015__ptlimapt__michelson__v1__primitives
    - id: arg
      type: micheline__015__ptlimapt__michelson_v1__expression
    - id: zk_rollup_publish__some__prim__1_arg__some_annots__annots
      type: zk_rollup_publish__some__prim__1_arg__some_annots__annots
  zk_rollup_publish__some__prim__1_arg__some_annots__annots:
    seq:
    - id: size_of_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: size_of_annots
  zk_rollup_publish__some__prim__1_arg__no_annots__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__1_arg__no_annots__id_015__ptlimapt__michelson__v1__primitives
    - id: arg
      type: micheline__015__ptlimapt__michelson_v1__expression
  zk_rollup_publish__some__prim__no_args__some_annots__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__no_args__some_annots__id_015__ptlimapt__michelson__v1__primitives
    - id: zk_rollup_publish__some__prim__no_args__some_annots__annots
      type: zk_rollup_publish__some__prim__no_args__some_annots__annots
  zk_rollup_publish__some__prim__no_args__some_annots__annots:
    seq:
    - id: size_of_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: size_of_annots
  zk_rollup_publish__some__sequence__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: size_of_sequence
      type: u4
      valid:
        max: 1073741823
    - id: sequence
      type: zk_rollup_publish__some__sequence__sequence_entries
      size: size_of_sequence
      repeat: eos
  zk_rollup_publish__some__sequence__sequence_entries:
    seq:
    - id: sequence_elt
      type: micheline__015__ptlimapt__michelson_v1__expression
  zk_rollup_publish__some__string__string:
    seq:
    - id: size_of_string
      type: u4
      valid:
        max: 1073741823
    - id: string
      size: size_of_string
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
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: rollup_id
      size: 20
    - id: zk_rollup_publish__payload
      type: zk_rollup_publish__payload
  zk_rollup_publish__payload:
    seq:
    - id: size_of_payload
      type: u4
      valid:
        max: 1073741823
    - id: payload
      type: zk_rollup_publish__payload_entries
      size: size_of_payload
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
    - id: zk_rollup_publish__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  zk_rollup_origination__id_015__ptlimapt__operation__alpha__contents:
    seq:
    - id: source
      type: zk_rollup_origination__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
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
    - id: size_of_init_state
      type: u4
      valid:
        max: 1073741823
    - id: init_state
      type: zk_rollup_origination__init_state_entries
      size: size_of_init_state
      repeat: eos
  zk_rollup_origination__init_state_entries:
    seq:
    - id: init_state_elt
      size: 32
  zk_rollup_origination__circuits_info:
    seq:
    - id: size_of_circuits_info
      type: u4
      valid:
        max: 1073741823
    - id: circuits_info
      type: zk_rollup_origination__circuits_info_entries
      size: size_of_circuits_info
      repeat: eos
  zk_rollup_origination__circuits_info_entries:
    seq:
    - id: zk_rollup_origination__circuits_info_elt_field0
      type: zk_rollup_origination__circuits_info_elt_field0
    - id: circuits_info_elt_field1
      type: u1
      enum: bool
  zk_rollup_origination__circuits_info_elt_field0:
    seq:
    - id: size_of_circuits_info_elt_field0
      type: u4
      valid:
        max: 1073741823
    - id: circuits_info_elt_field0
      size: size_of_circuits_info_elt_field0
  zk_rollup_origination__public_parameters:
    seq:
    - id: zk_rollup_origination__public_parameters_field0
      type: zk_rollup_origination__public_parameters_field0
    - id: zk_rollup_origination__public_parameters_field1
      type: zk_rollup_origination__public_parameters_field1
  zk_rollup_origination__public_parameters_field1:
    seq:
    - id: size_of_public_parameters_field1
      type: u4
      valid:
        max: 1073741823
    - id: public_parameters_field1
      size: size_of_public_parameters_field1
  zk_rollup_origination__public_parameters_field0:
    seq:
    - id: size_of_public_parameters_field0
      type: u4
      valid:
        max: 1073741823
    - id: public_parameters_field0
      size: size_of_public_parameters_field0
  zk_rollup_origination__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: zk_rollup_origination__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  sc_rollup_dal_slot_subscribe__id_015__ptlimapt__operation__alpha__contents:
    seq:
    - id: source
      type: sc_rollup_dal_slot_subscribe__public_key_hash
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
      type: sc_rollup_dal_slot_subscribe__id_015__ptlimapt__rollup_address
      doc: ! >-
        A smart contract rollup address: A smart contract rollup is identified by
        a base58 address starting with scr1
    - id: slot_index
      type: u1
  sc_rollup_dal_slot_subscribe__id_015__ptlimapt__rollup_address:
    seq:
    - id: size_of_id_015__ptlimapt__rollup_address
      type: u4
      valid:
        max: 1073741823
    - id: id_015__ptlimapt__rollup_address
      size: size_of_id_015__ptlimapt__rollup_address
  sc_rollup_dal_slot_subscribe__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: sc_rollup_dal_slot_subscribe__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  sc_rollup_recover_bond__id_015__ptlimapt__operation__alpha__contents:
    seq:
    - id: source
      type: sc_rollup_recover_bond__public_key_hash
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
  sc_rollup_recover_bond__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: sc_rollup_recover_bond__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  sc_rollup_execute_outbox_message__id_015__ptlimapt__operation__alpha__contents:
    seq:
    - id: source
      type: sc_rollup_execute_outbox_message__public_key_hash
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
      type: sc_rollup_execute_outbox_message__id_015__ptlimapt__rollup_address
      doc: ! >-
        A smart contract rollup address: A smart contract rollup is identified by
        a base58 address starting with scr1
    - id: cemented_commitment
      size: 32
    - id: sc_rollup_execute_outbox_message__output_proof
      type: sc_rollup_execute_outbox_message__output_proof
  sc_rollup_execute_outbox_message__output_proof:
    seq:
    - id: size_of_output_proof
      type: u4
      valid:
        max: 1073741823
    - id: output_proof
      size: size_of_output_proof
  sc_rollup_execute_outbox_message__id_015__ptlimapt__rollup_address:
    seq:
    - id: size_of_id_015__ptlimapt__rollup_address
      type: u4
      valid:
        max: 1073741823
    - id: id_015__ptlimapt__rollup_address
      size: size_of_id_015__ptlimapt__rollup_address
  sc_rollup_execute_outbox_message__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: sc_rollup_execute_outbox_message__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  sc_rollup_timeout__id_015__ptlimapt__operation__alpha__contents:
    seq:
    - id: source
      type: sc_rollup_timeout__public_key_hash
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
      type: sc_rollup_timeout__id_015__ptlimapt__rollup_address
      doc: ! >-
        A smart contract rollup address: A smart contract rollup is identified by
        a base58 address starting with scr1
    - id: sc_rollup_timeout__stakers
      type: sc_rollup_timeout__stakers
  sc_rollup_timeout__stakers:
    seq:
    - id: alice
      type: sc_rollup_timeout__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: bob
      type: sc_rollup_timeout__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
  sc_rollup_timeout__id_015__ptlimapt__rollup_address:
    seq:
    - id: size_of_id_015__ptlimapt__rollup_address
      type: u4
      valid:
        max: 1073741823
    - id: id_015__ptlimapt__rollup_address
      size: size_of_id_015__ptlimapt__rollup_address
  sc_rollup_timeout__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: sc_rollup_timeout__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  sc_rollup_refute__id_015__ptlimapt__operation__alpha__contents:
    seq:
    - id: source
      type: sc_rollup_refute__public_key_hash
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
      type: sc_rollup_refute__id_015__ptlimapt__rollup_address
      doc: ! >-
        A smart contract rollup address: A smart contract rollup is identified by
        a base58 address starting with scr1
    - id: opponent
      type: sc_rollup_refute__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: refutation_tag
      type: u1
      enum: bool
    - id: sc_rollup_refute__refutation
      type: sc_rollup_refute__refutation
      if: (refutation_tag == bool::true)
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
    - id: input_proof_tag
      type: u1
      enum: bool
    - id: sc_rollup_refute__proof__input_proof
      type: sc_rollup_refute__proof__input_proof
      if: (input_proof_tag == bool::true)
  sc_rollup_refute__proof__input_proof:
    seq:
    - id: input_proof_tag
      type: u1
      enum: input_proof_tag
    - id: sc_rollup_refute__proof__reveal__proof__input_proof
      type: sc_rollup_refute__proof__reveal__proof__reveal_proof
      if: (input_proof_tag == ::input_proof_tag::input_proof_tag::reveal__proof)
  sc_rollup_refute__proof__reveal__proof__reveal_proof:
    seq:
    - id: reveal_proof_tag
      type: u1
      enum: reveal_proof_tag
    - id: sc_rollup_refute__proof__reveal__proof__raw__data__proof__reveal_proof
      type: sc_rollup_refute__proof__reveal__proof__raw__data__proof__raw_data
      if: (reveal_proof_tag == ::reveal_proof_tag::reveal_proof_tag::raw__data__proof)
  sc_rollup_refute__proof__reveal__proof__raw__data__proof__raw_data:
    seq:
    - id: size_of_raw_data
      type: u4
      valid:
        max: 1073741823
    - id: raw_data
      size: size_of_raw_data
  sc_rollup_refute__proof__inbox__proof__input_proof:
    seq:
    - id: level
      type: s4
    - id: message_counter
      type: n
    - id: sc_rollup_refute__proof__inbox__proof__serialized_proof
      type: sc_rollup_refute__proof__inbox__proof__serialized_proof
  sc_rollup_refute__proof__inbox__proof__serialized_proof:
    seq:
    - id: size_of_serialized_proof
      type: u4
      valid:
        max: 1073741823
    - id: serialized_proof
      size: size_of_serialized_proof
  sc_rollup_refute__proof__pvm_step:
    seq:
    - id: pvm_step_tag
      type: u1
      enum: pvm_step_tag
    - id: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__pvm_step
      type: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__proof
      if: (pvm_step_tag == ::pvm_step_tag::pvm_step_tag::wasm__2__0__0__pvm__with__proof)
  sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__proof:
    seq:
    - id: proof_tag
      type: u1
      enum: proof_tag
    - id: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__case__0__proof
      type: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__case__0__proof
      if: (proof_tag == proof_tag::case__0)
    - id: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__case__2__proof
      type: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__case__2__proof
      if: (proof_tag == proof_tag::case__2)
    - id: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__case__1__proof
      type: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__case__1__proof
      if: (proof_tag == proof_tag::case__1)
    - id: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__case__3__proof
      type: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__case__3__proof
      if: (proof_tag == proof_tag::case__3)
  sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__case__3__proof:
    seq:
    - id: case__3_field0
      type: s2
    - id: case__3_field1
      size: 32
      doc: context_hash
    - id: case__3_field2
      size: 32
      doc: context_hash
    - id: case__3_field3
      type: tree_encoding
  sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__case__1__proof:
    seq:
    - id: case__1_field0
      type: s2
    - id: case__1_field1
      size: 32
      doc: context_hash
    - id: case__1_field2
      size: 32
      doc: context_hash
    - id: case__1_field3
      type: tree_encoding
  sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__case__2__proof:
    seq:
    - id: case__2_field0
      type: s2
    - id: case__2_field1
      size: 32
      doc: context_hash
    - id: case__2_field2
      size: 32
      doc: context_hash
    - id: case__2_field3
      type: tree_encoding
  sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__case__0__proof:
    seq:
    - id: case__0_field0
      type: s2
    - id: case__0_field1
      size: 32
      doc: context_hash
    - id: case__0_field2
      size: 32
      doc: context_hash
    - id: case__0_field3
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__proof:
    seq:
    - id: proof_tag
      type: u1
      enum: proof_tag
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__proof
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__proof
      if: (proof_tag == proof_tag::case__0)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__2__proof
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__2__proof
      if: (proof_tag == proof_tag::case__2)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__1__proof
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__1__proof
      if: (proof_tag == proof_tag::case__1)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__3__proof
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__3__proof
      if: (proof_tag == proof_tag::case__3)
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__3__proof:
    seq:
    - id: case__3_field0
      type: s2
    - id: case__3_field1
      size: 32
      doc: context_hash
    - id: case__3_field2
      size: 32
      doc: context_hash
    - id: case__3_field3
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__1__proof:
    seq:
    - id: case__1_field0
      type: s2
    - id: case__1_field1
      size: 32
      doc: context_hash
    - id: case__1_field2
      size: 32
      doc: context_hash
    - id: case__1_field3
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__2__proof:
    seq:
    - id: case__2_field0
      type: s2
    - id: case__2_field1
      size: 32
      doc: context_hash
    - id: case__2_field2
      size: 32
      doc: context_hash
    - id: case__2_field3
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__proof:
    seq:
    - id: case__0_field0
      type: s2
    - id: case__0_field1
      size: 32
      doc: context_hash
    - id: case__0_field2
      size: 32
      doc: context_hash
    - id: case__0_field3
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
      doc: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding:
    seq:
    - id: tree_encoding_tag
      type: u1
      enum: tree_encoding_tag
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__208__tree_encoding
      size: 32
      if: (tree_encoding_tag == ::tree_encoding_tag::tree_encoding_tag::case__208)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__216__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__216__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__216)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__217__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__217__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__217)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__218__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__218__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__218)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__219__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__219__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__219)
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__219__tree_encoding:
    seq:
    - id: case__219_field0
      type: s8
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__219__case__219_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__219__case__219_field1
    - id: case__219_field2
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__219__case__219_field1:
    seq:
    - id: size_of_case__219_field1
      type: u1
      valid:
        max: 255
    - id: case__219_field1
      size: size_of_case__219_field1
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__218__tree_encoding:
    seq:
    - id: case__218_field0
      type: s4
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__218__case__218_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__218__case__218_field1
    - id: case__218_field2
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__218__case__218_field1:
    seq:
    - id: size_of_case__218_field1
      type: u1
      valid:
        max: 255
    - id: case__218_field1
      size: size_of_case__218_field1
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__217__tree_encoding:
    seq:
    - id: case__217_field0
      type: u2
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__217__case__217_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__217__case__217_field1
    - id: case__217_field2
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__217__case__217_field1:
    seq:
    - id: size_of_case__217_field1
      type: u1
      valid:
        max: 255
    - id: case__217_field1
      size: size_of_case__217_field1
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__216__tree_encoding:
    seq:
    - id: case__216_field0
      type: u1
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__216__case__216_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__216__case__216_field1
    - id: case__216_field2
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__216__case__216_field1:
    seq:
    - id: size_of_case__216_field1
      type: u1
      valid:
        max: 255
    - id: case__216_field1
      size: size_of_case__216_field1
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__195__tree_encoding:
    seq:
    - id: size_of_case__195
      type: u4
      valid:
        max: 1073741823
    - id: case__195
      size: size_of_case__195
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__193__tree_encoding:
    seq:
    - id: size_of_case__193
      type: u2
      valid:
        max: 65535
    - id: case__193
      size: size_of_case__193
      size-eos: true
      valid:
        max: 65535
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__192__tree_encoding:
    seq:
    - id: size_of_case__192
      type: u1
      valid:
        max: 255
    - id: case__192
      size: size_of_case__192
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__191__tree_encoding:
    seq:
    - id: size_of_case__191
      type: u4
      valid:
        max: 1073741823
    - id: case__191
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__191__case__191_entries
      size: size_of_case__191
      repeat: eos
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__191__case__191_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__191__case__191_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__191__case__191_elt_field0
    - id: case__191_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__191__case__191_elt_field0:
    seq:
    - id: size_of_case__191_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__191_elt_field0
      size: size_of_case__191_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__190__case__190_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__190__case__190_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__190__case__190_elt_field0
    - id: case__190_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__190__case__190_elt_field0:
    seq:
    - id: size_of_case__190_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__190_elt_field0
      size: size_of_case__190_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__189__case__189_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__189__case__189_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__189__case__189_elt_field0
    - id: case__189_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__189__case__189_elt_field0:
    seq:
    - id: size_of_case__189_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__189_elt_field0
      size: size_of_case__189_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__188__case__188_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__188__case__188_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__188__case__188_elt_field0
    - id: case__188_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__188__case__188_elt_field0:
    seq:
    - id: size_of_case__188_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__188_elt_field0
      size: size_of_case__188_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__187__case__187_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__187__case__187_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__187__case__187_elt_field0
    - id: case__187_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__187__case__187_elt_field0:
    seq:
    - id: size_of_case__187_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__187_elt_field0
      size: size_of_case__187_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__186__case__186_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__186__case__186_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__186__case__186_elt_field0
    - id: case__186_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__186__case__186_elt_field0:
    seq:
    - id: size_of_case__186_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__186_elt_field0
      size: size_of_case__186_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__185__case__185_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__185__case__185_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__185__case__185_elt_field0
    - id: case__185_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__185__case__185_elt_field0:
    seq:
    - id: size_of_case__185_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__185_elt_field0
      size: size_of_case__185_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__184__case__184_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__184__case__184_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__184__case__184_elt_field0
    - id: case__184_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__184__case__184_elt_field0:
    seq:
    - id: size_of_case__184_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__184_elt_field0
      size: size_of_case__184_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__183__case__183_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__183__case__183_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__183__case__183_elt_field0
    - id: case__183_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__183__case__183_elt_field0:
    seq:
    - id: size_of_case__183_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__183_elt_field0
      size: size_of_case__183_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__182__case__182_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__182__case__182_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__182__case__182_elt_field0
    - id: case__182_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__182__case__182_elt_field0:
    seq:
    - id: size_of_case__182_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__182_elt_field0
      size: size_of_case__182_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__181__case__181_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__181__case__181_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__181__case__181_elt_field0
    - id: case__181_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__181__case__181_elt_field0:
    seq:
    - id: size_of_case__181_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__181_elt_field0
      size: size_of_case__181_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__180__case__180_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__180__case__180_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__180__case__180_elt_field0
    - id: case__180_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__180__case__180_elt_field0:
    seq:
    - id: size_of_case__180_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__180_elt_field0
      size: size_of_case__180_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__179__case__179_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__179__case__179_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__179__case__179_elt_field0
    - id: case__179_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__179__case__179_elt_field0:
    seq:
    - id: size_of_case__179_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__179_elt_field0
      size: size_of_case__179_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__178__case__178_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__178__case__178_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__178__case__178_elt_field0
    - id: case__178_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__178__case__178_elt_field0:
    seq:
    - id: size_of_case__178_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__178_elt_field0
      size: size_of_case__178_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__177__case__177_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__177__case__177_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__177__case__177_elt_field0
    - id: case__177_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__177__case__177_elt_field0:
    seq:
    - id: size_of_case__177_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__177_elt_field0
      size: size_of_case__177_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__176__case__176_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__176__case__176_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__176__case__176_elt_field0
    - id: case__176_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__176__case__176_elt_field0:
    seq:
    - id: size_of_case__176_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__176_elt_field0
      size: size_of_case__176_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__175__case__175_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__175__case__175_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__175__case__175_elt_field0
    - id: case__175_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__175__case__175_elt_field0:
    seq:
    - id: size_of_case__175_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__175_elt_field0
      size: size_of_case__175_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__174__case__174_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__174__case__174_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__174__case__174_elt_field0
    - id: case__174_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__174__case__174_elt_field0:
    seq:
    - id: size_of_case__174_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__174_elt_field0
      size: size_of_case__174_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__173__case__173_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__173__case__173_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__173__case__173_elt_field0
    - id: case__173_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__173__case__173_elt_field0:
    seq:
    - id: size_of_case__173_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__173_elt_field0
      size: size_of_case__173_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__172__case__172_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__172__case__172_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__172__case__172_elt_field0
    - id: case__172_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__172__case__172_elt_field0:
    seq:
    - id: size_of_case__172_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__172_elt_field0
      size: size_of_case__172_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__171__case__171_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__171__case__171_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__171__case__171_elt_field0
    - id: case__171_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__171__case__171_elt_field0:
    seq:
    - id: size_of_case__171_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__171_elt_field0
      size: size_of_case__171_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__170__case__170_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__170__case__170_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__170__case__170_elt_field0
    - id: case__170_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__170__case__170_elt_field0:
    seq:
    - id: size_of_case__170_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__170_elt_field0
      size: size_of_case__170_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__169__case__169_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__169__case__169_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__169__case__169_elt_field0
    - id: case__169_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__169__case__169_elt_field0:
    seq:
    - id: size_of_case__169_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__169_elt_field0
      size: size_of_case__169_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__168__case__168_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__168__case__168_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__168__case__168_elt_field0
    - id: case__168_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__168__case__168_elt_field0:
    seq:
    - id: size_of_case__168_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__168_elt_field0
      size: size_of_case__168_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__167__case__167_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__167__case__167_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__167__case__167_elt_field0
    - id: case__167_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__167__case__167_elt_field0:
    seq:
    - id: size_of_case__167_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__167_elt_field0
      size: size_of_case__167_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__166__case__166_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__166__case__166_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__166__case__166_elt_field0
    - id: case__166_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__166__case__166_elt_field0:
    seq:
    - id: size_of_case__166_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__166_elt_field0
      size: size_of_case__166_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__165__case__165_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__165__case__165_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__165__case__165_elt_field0
    - id: case__165_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__165__case__165_elt_field0:
    seq:
    - id: size_of_case__165_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__165_elt_field0
      size: size_of_case__165_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__164__case__164_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__164__case__164_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__164__case__164_elt_field0
    - id: case__164_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__164__case__164_elt_field0:
    seq:
    - id: size_of_case__164_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__164_elt_field0
      size: size_of_case__164_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__163__case__163_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__163__case__163_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__163__case__163_elt_field0
    - id: case__163_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__163__case__163_elt_field0:
    seq:
    - id: size_of_case__163_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__163_elt_field0
      size: size_of_case__163_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__162__case__162_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__162__case__162_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__162__case__162_elt_field0
    - id: case__162_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__162__case__162_elt_field0:
    seq:
    - id: size_of_case__162_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__162_elt_field0
      size: size_of_case__162_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__161__case__161_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__161__case__161_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__161__case__161_elt_field0
    - id: case__161_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__161__case__161_elt_field0:
    seq:
    - id: size_of_case__161_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__161_elt_field0
      size: size_of_case__161_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__160__case__160_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__160__case__160_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__160__case__160_elt_field0
    - id: case__160_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__160__case__160_elt_field0:
    seq:
    - id: size_of_case__160_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__160_elt_field0
      size: size_of_case__160_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__159__case__159_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__159__case__159_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__159__case__159_elt_field0
    - id: case__159_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__159__case__159_elt_field0:
    seq:
    - id: size_of_case__159_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__159_elt_field0
      size: size_of_case__159_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__158__case__158_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__158__case__158_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__158__case__158_elt_field0
    - id: case__158_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__158__case__158_elt_field0:
    seq:
    - id: size_of_case__158_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__158_elt_field0
      size: size_of_case__158_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__157__case__157_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__157__case__157_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__157__case__157_elt_field0
    - id: case__157_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__157__case__157_elt_field0:
    seq:
    - id: size_of_case__157_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__157_elt_field0
      size: size_of_case__157_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__156__case__156_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__156__case__156_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__156__case__156_elt_field0
    - id: case__156_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__156__case__156_elt_field0:
    seq:
    - id: size_of_case__156_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__156_elt_field0
      size: size_of_case__156_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__155__case__155_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__155__case__155_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__155__case__155_elt_field0
    - id: case__155_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__155__case__155_elt_field0:
    seq:
    - id: size_of_case__155_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__155_elt_field0
      size: size_of_case__155_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__154__case__154_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__154__case__154_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__154__case__154_elt_field0
    - id: case__154_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__154__case__154_elt_field0:
    seq:
    - id: size_of_case__154_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__154_elt_field0
      size: size_of_case__154_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__153__case__153_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__153__case__153_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__153__case__153_elt_field0
    - id: case__153_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__153__case__153_elt_field0:
    seq:
    - id: size_of_case__153_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__153_elt_field0
      size: size_of_case__153_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__152__case__152_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__152__case__152_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__152__case__152_elt_field0
    - id: case__152_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__152__case__152_elt_field0:
    seq:
    - id: size_of_case__152_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__152_elt_field0
      size: size_of_case__152_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__151__case__151_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__151__case__151_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__151__case__151_elt_field0
    - id: case__151_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__151__case__151_elt_field0:
    seq:
    - id: size_of_case__151_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__151_elt_field0
      size: size_of_case__151_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__150__case__150_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__150__case__150_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__150__case__150_elt_field0
    - id: case__150_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__150__case__150_elt_field0:
    seq:
    - id: size_of_case__150_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__150_elt_field0
      size: size_of_case__150_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__149__case__149_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__149__case__149_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__149__case__149_elt_field0
    - id: case__149_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__149__case__149_elt_field0:
    seq:
    - id: size_of_case__149_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__149_elt_field0
      size: size_of_case__149_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__148__case__148_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__148__case__148_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__148__case__148_elt_field0
    - id: case__148_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__148__case__148_elt_field0:
    seq:
    - id: size_of_case__148_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__148_elt_field0
      size: size_of_case__148_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__147__case__147_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__147__case__147_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__147__case__147_elt_field0
    - id: case__147_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__147__case__147_elt_field0:
    seq:
    - id: size_of_case__147_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__147_elt_field0
      size: size_of_case__147_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__146__case__146_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__146__case__146_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__146__case__146_elt_field0
    - id: case__146_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__146__case__146_elt_field0:
    seq:
    - id: size_of_case__146_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__146_elt_field0
      size: size_of_case__146_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__145__case__145_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__145__case__145_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__145__case__145_elt_field0
    - id: case__145_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__145__case__145_elt_field0:
    seq:
    - id: size_of_case__145_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__145_elt_field0
      size: size_of_case__145_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__144__case__144_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__144__case__144_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__144__case__144_elt_field0
    - id: case__144_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__144__case__144_elt_field0:
    seq:
    - id: size_of_case__144_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__144_elt_field0
      size: size_of_case__144_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__143__case__143_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__143__case__143_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__143__case__143_elt_field0
    - id: case__143_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__143__case__143_elt_field0:
    seq:
    - id: size_of_case__143_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__143_elt_field0
      size: size_of_case__143_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__142__case__142_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__142__case__142_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__142__case__142_elt_field0
    - id: case__142_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__142__case__142_elt_field0:
    seq:
    - id: size_of_case__142_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__142_elt_field0
      size: size_of_case__142_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__141__case__141_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__141__case__141_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__141__case__141_elt_field0
    - id: case__141_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__141__case__141_elt_field0:
    seq:
    - id: size_of_case__141_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__141_elt_field0
      size: size_of_case__141_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__140__case__140_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__140__case__140_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__140__case__140_elt_field0
    - id: case__140_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__140__case__140_elt_field0:
    seq:
    - id: size_of_case__140_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__140_elt_field0
      size: size_of_case__140_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__139__case__139_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__139__case__139_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__139__case__139_elt_field0
    - id: case__139_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__139__case__139_elt_field0:
    seq:
    - id: size_of_case__139_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__139_elt_field0
      size: size_of_case__139_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__138__case__138_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__138__case__138_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__138__case__138_elt_field0
    - id: case__138_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__138__case__138_elt_field0:
    seq:
    - id: size_of_case__138_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__138_elt_field0
      size: size_of_case__138_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__137__case__137_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__137__case__137_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__137__case__137_elt_field0
    - id: case__137_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__137__case__137_elt_field0:
    seq:
    - id: size_of_case__137_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__137_elt_field0
      size: size_of_case__137_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__136__case__136_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__136__case__136_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__136__case__136_elt_field0
    - id: case__136_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__136__case__136_elt_field0:
    seq:
    - id: size_of_case__136_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__136_elt_field0
      size: size_of_case__136_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__135__case__135_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__135__case__135_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__135__case__135_elt_field0
    - id: case__135_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__135__case__135_elt_field0:
    seq:
    - id: size_of_case__135_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__135_elt_field0
      size: size_of_case__135_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__134__case__134_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__134__case__134_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__134__case__134_elt_field0
    - id: case__134_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__134__case__134_elt_field0:
    seq:
    - id: size_of_case__134_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__134_elt_field0
      size: size_of_case__134_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__133__case__133_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__133__case__133_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__133__case__133_elt_field0
    - id: case__133_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__133__case__133_elt_field0:
    seq:
    - id: size_of_case__133_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__133_elt_field0
      size: size_of_case__133_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__132__case__132_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__132__case__132_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__132__case__132_elt_field0
    - id: case__132_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__132__case__132_elt_field0:
    seq:
    - id: size_of_case__132_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__132_elt_field0
      size: size_of_case__132_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__131__case__131_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__131__case__131_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__131__case__131_elt_field0
    - id: case__131_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__131__case__131_elt_field0:
    seq:
    - id: size_of_case__131_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__131_elt_field0
      size: size_of_case__131_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__130__case__130_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__130__case__130_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__130__case__130_elt_field0
    - id: case__130_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__130__case__130_elt_field0:
    seq:
    - id: size_of_case__130_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__130_elt_field0
      size: size_of_case__130_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__129__case__129_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__129__case__129_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__129__case__129_elt_field0
    - id: case__129_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__129__case__129_elt_field0:
    seq:
    - id: size_of_case__129_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__129_elt_field0
      size: size_of_case__129_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__67__tree_encoding:
    seq:
    - id: case__67_field0
      type: s8
    - id: case__67_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__67__case__67_field1_entries
      repeat: expr
      repeat-expr: 32
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__67__case__67_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__67__case__67_field1_entries:
    seq:
    - id: case__67_field1_elt
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__63__tree_encoding:
    seq:
    - id: case__63_field0
      type: s8
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__63__case__63_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__63__case__63_field1
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__63__case__63_field1:
    seq:
    - id: size_of_case__63_field1
      type: u4
      valid:
        max: 1073741823
    - id: case__63_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__63__case__63_field1_entries
      size: size_of_case__63_field1
      repeat: eos
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__63__case__63_field1_entries:
    seq:
    - id: case__63_field1_elt_field0
      type: u1
    - id: case__63_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__59__tree_encoding:
    seq:
    - id: case__59_field0
      type: s8
    - id: case__59_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__59__case__59_field1_entries
      repeat: expr
      repeat-expr: 14
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__59__case__59_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__59__case__59_field1_entries:
    seq:
    - id: case__59_field1_elt_field0
      type: u1
    - id: case__59_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__55__tree_encoding:
    seq:
    - id: case__55_field0
      type: s8
    - id: case__55_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__55__case__55_field1_entries
      repeat: expr
      repeat-expr: 13
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__55__case__55_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__55__case__55_field1_entries:
    seq:
    - id: case__55_field1_elt_field0
      type: u1
    - id: case__55_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__51__tree_encoding:
    seq:
    - id: case__51_field0
      type: s8
    - id: case__51_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__51__case__51_field1_entries
      repeat: expr
      repeat-expr: 12
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__51__case__51_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__51__case__51_field1_entries:
    seq:
    - id: case__51_field1_elt_field0
      type: u1
    - id: case__51_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__47__tree_encoding:
    seq:
    - id: case__47_field0
      type: s8
    - id: case__47_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__47__case__47_field1_entries
      repeat: expr
      repeat-expr: 11
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__47__case__47_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__47__case__47_field1_entries:
    seq:
    - id: case__47_field1_elt_field0
      type: u1
    - id: case__47_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__43__tree_encoding:
    seq:
    - id: case__43_field0
      type: s8
    - id: case__43_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__43__case__43_field1_entries
      repeat: expr
      repeat-expr: 10
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__43__case__43_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__43__case__43_field1_entries:
    seq:
    - id: case__43_field1_elt_field0
      type: u1
    - id: case__43_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__39__tree_encoding:
    seq:
    - id: case__39_field0
      type: s8
    - id: case__39_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__39__case__39_field1_entries
      repeat: expr
      repeat-expr: 9
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__39__case__39_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__39__case__39_field1_entries:
    seq:
    - id: case__39_field1_elt_field0
      type: u1
    - id: case__39_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__35__tree_encoding:
    seq:
    - id: case__35_field0
      type: s8
    - id: case__35_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__35__case__35_field1_entries
      repeat: expr
      repeat-expr: 8
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__35__case__35_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__35__case__35_field1_entries:
    seq:
    - id: case__35_field1_elt_field0
      type: u1
    - id: case__35_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__31__tree_encoding:
    seq:
    - id: case__31_field0
      type: s8
    - id: case__31_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__31__case__31_field1_entries
      repeat: expr
      repeat-expr: 7
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__31__case__31_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__31__case__31_field1_entries:
    seq:
    - id: case__31_field1_elt_field0
      type: u1
    - id: case__31_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__27__tree_encoding:
    seq:
    - id: case__27_field0
      type: s8
    - id: case__27_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__27__case__27_field1_entries
      repeat: expr
      repeat-expr: 6
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__27__case__27_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__27__case__27_field1_entries:
    seq:
    - id: case__27_field1_elt_field0
      type: u1
    - id: case__27_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__23__tree_encoding:
    seq:
    - id: case__23_field0
      type: s8
    - id: case__23_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__23__case__23_field1_entries
      repeat: expr
      repeat-expr: 5
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__23__case__23_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__23__case__23_field1_entries:
    seq:
    - id: case__23_field1_elt_field0
      type: u1
    - id: case__23_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__19__tree_encoding:
    seq:
    - id: case__19_field0
      type: s8
    - id: case__19_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__19__case__19_field1_entries
      repeat: expr
      repeat-expr: 4
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__19__case__19_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__19__case__19_field1_entries:
    seq:
    - id: case__19_field1_elt_field0
      type: u1
    - id: case__19_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__15__tree_encoding:
    seq:
    - id: case__15_field0
      type: s8
    - id: case__15_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__15__case__15_field1_entries
      repeat: expr
      repeat-expr: 3
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__15__case__15_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__15__case__15_field1_entries:
    seq:
    - id: case__15_field1_elt_field0
      type: u1
    - id: case__15_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__11__tree_encoding:
    seq:
    - id: case__11_field0
      type: s8
    - id: case__11_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__11__case__11_field1_entries
      repeat: expr
      repeat-expr: 2
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__11__case__11_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__11__case__11_field1_entries:
    seq:
    - id: case__11_field1_elt_field0
      type: u1
    - id: case__11_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__7__tree_encoding:
    seq:
    - id: case__7_field0
      type: s8
    - id: case__7_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__7__case__7_field1_entries
      repeat: expr
      repeat-expr: 1
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__7__case__7_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__7__case__7_field1_entries:
    seq:
    - id: case__7_field1_elt_field0
      type: u1
    - id: case__7_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__66__tree_encoding:
    seq:
    - id: case__66_field0
      type: s4
    - id: case__66_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__66__case__66_field1_entries
      repeat: expr
      repeat-expr: 32
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__66__case__66_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__66__case__66_field1_entries:
    seq:
    - id: case__66_field1_elt
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__62__tree_encoding:
    seq:
    - id: case__62_field0
      type: s4
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__62__case__62_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__62__case__62_field1
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__62__case__62_field1:
    seq:
    - id: size_of_case__62_field1
      type: u4
      valid:
        max: 1073741823
    - id: case__62_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__62__case__62_field1_entries
      size: size_of_case__62_field1
      repeat: eos
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__62__case__62_field1_entries:
    seq:
    - id: case__62_field1_elt_field0
      type: u1
    - id: case__62_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__58__tree_encoding:
    seq:
    - id: case__58_field0
      type: s4
    - id: case__58_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__58__case__58_field1_entries
      repeat: expr
      repeat-expr: 14
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__58__case__58_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__58__case__58_field1_entries:
    seq:
    - id: case__58_field1_elt_field0
      type: u1
    - id: case__58_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__54__tree_encoding:
    seq:
    - id: case__54_field0
      type: s4
    - id: case__54_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__54__case__54_field1_entries
      repeat: expr
      repeat-expr: 13
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__54__case__54_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__54__case__54_field1_entries:
    seq:
    - id: case__54_field1_elt_field0
      type: u1
    - id: case__54_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__50__tree_encoding:
    seq:
    - id: case__50_field0
      type: s4
    - id: case__50_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__50__case__50_field1_entries
      repeat: expr
      repeat-expr: 12
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__50__case__50_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__50__case__50_field1_entries:
    seq:
    - id: case__50_field1_elt_field0
      type: u1
    - id: case__50_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__46__tree_encoding:
    seq:
    - id: case__46_field0
      type: s4
    - id: case__46_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__46__case__46_field1_entries
      repeat: expr
      repeat-expr: 11
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__46__case__46_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__46__case__46_field1_entries:
    seq:
    - id: case__46_field1_elt_field0
      type: u1
    - id: case__46_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__42__tree_encoding:
    seq:
    - id: case__42_field0
      type: s4
    - id: case__42_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__42__case__42_field1_entries
      repeat: expr
      repeat-expr: 10
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__42__case__42_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__42__case__42_field1_entries:
    seq:
    - id: case__42_field1_elt_field0
      type: u1
    - id: case__42_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__38__tree_encoding:
    seq:
    - id: case__38_field0
      type: s4
    - id: case__38_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__38__case__38_field1_entries
      repeat: expr
      repeat-expr: 9
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__38__case__38_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__38__case__38_field1_entries:
    seq:
    - id: case__38_field1_elt_field0
      type: u1
    - id: case__38_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__34__tree_encoding:
    seq:
    - id: case__34_field0
      type: s4
    - id: case__34_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__34__case__34_field1_entries
      repeat: expr
      repeat-expr: 8
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__34__case__34_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__34__case__34_field1_entries:
    seq:
    - id: case__34_field1_elt_field0
      type: u1
    - id: case__34_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__30__tree_encoding:
    seq:
    - id: case__30_field0
      type: s4
    - id: case__30_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__30__case__30_field1_entries
      repeat: expr
      repeat-expr: 7
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__30__case__30_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__30__case__30_field1_entries:
    seq:
    - id: case__30_field1_elt_field0
      type: u1
    - id: case__30_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__26__tree_encoding:
    seq:
    - id: case__26_field0
      type: s4
    - id: case__26_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__26__case__26_field1_entries
      repeat: expr
      repeat-expr: 6
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__26__case__26_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__26__case__26_field1_entries:
    seq:
    - id: case__26_field1_elt_field0
      type: u1
    - id: case__26_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__22__tree_encoding:
    seq:
    - id: case__22_field0
      type: s4
    - id: case__22_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__22__case__22_field1_entries
      repeat: expr
      repeat-expr: 5
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__22__case__22_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__22__case__22_field1_entries:
    seq:
    - id: case__22_field1_elt_field0
      type: u1
    - id: case__22_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__18__tree_encoding:
    seq:
    - id: case__18_field0
      type: s4
    - id: case__18_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__18__case__18_field1_entries
      repeat: expr
      repeat-expr: 4
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__18__case__18_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__18__case__18_field1_entries:
    seq:
    - id: case__18_field1_elt_field0
      type: u1
    - id: case__18_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__14__tree_encoding:
    seq:
    - id: case__14_field0
      type: s4
    - id: case__14_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__14__case__14_field1_entries
      repeat: expr
      repeat-expr: 3
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__14__case__14_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__14__case__14_field1_entries:
    seq:
    - id: case__14_field1_elt_field0
      type: u1
    - id: case__14_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__10__tree_encoding:
    seq:
    - id: case__10_field0
      type: s4
    - id: case__10_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__10__case__10_field1_entries
      repeat: expr
      repeat-expr: 2
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__10__case__10_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__10__case__10_field1_entries:
    seq:
    - id: case__10_field1_elt_field0
      type: u1
    - id: case__10_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__6__tree_encoding:
    seq:
    - id: case__6_field0
      type: s4
    - id: case__6_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__6__case__6_field1_entries
      repeat: expr
      repeat-expr: 1
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__6__case__6_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__6__case__6_field1_entries:
    seq:
    - id: case__6_field1_elt_field0
      type: u1
    - id: case__6_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__65__tree_encoding:
    seq:
    - id: case__65_field0
      type: u2
    - id: case__65_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__65__case__65_field1_entries
      repeat: expr
      repeat-expr: 32
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__65__case__65_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__65__case__65_field1_entries:
    seq:
    - id: case__65_field1_elt
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__61__tree_encoding:
    seq:
    - id: case__61_field0
      type: u2
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__61__case__61_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__61__case__61_field1
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__61__case__61_field1:
    seq:
    - id: size_of_case__61_field1
      type: u4
      valid:
        max: 1073741823
    - id: case__61_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__61__case__61_field1_entries
      size: size_of_case__61_field1
      repeat: eos
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__61__case__61_field1_entries:
    seq:
    - id: case__61_field1_elt_field0
      type: u1
    - id: case__61_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__57__tree_encoding:
    seq:
    - id: case__57_field0
      type: u2
    - id: case__57_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__57__case__57_field1_entries
      repeat: expr
      repeat-expr: 14
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__57__case__57_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__57__case__57_field1_entries:
    seq:
    - id: case__57_field1_elt_field0
      type: u1
    - id: case__57_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__53__tree_encoding:
    seq:
    - id: case__53_field0
      type: u2
    - id: case__53_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__53__case__53_field1_entries
      repeat: expr
      repeat-expr: 13
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__53__case__53_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__53__case__53_field1_entries:
    seq:
    - id: case__53_field1_elt_field0
      type: u1
    - id: case__53_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__49__tree_encoding:
    seq:
    - id: case__49_field0
      type: u2
    - id: case__49_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__49__case__49_field1_entries
      repeat: expr
      repeat-expr: 12
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__49__case__49_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__49__case__49_field1_entries:
    seq:
    - id: case__49_field1_elt_field0
      type: u1
    - id: case__49_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__45__tree_encoding:
    seq:
    - id: case__45_field0
      type: u2
    - id: case__45_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__45__case__45_field1_entries
      repeat: expr
      repeat-expr: 11
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__45__case__45_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__45__case__45_field1_entries:
    seq:
    - id: case__45_field1_elt_field0
      type: u1
    - id: case__45_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__41__tree_encoding:
    seq:
    - id: case__41_field0
      type: u2
    - id: case__41_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__41__case__41_field1_entries
      repeat: expr
      repeat-expr: 10
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__41__case__41_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__41__case__41_field1_entries:
    seq:
    - id: case__41_field1_elt_field0
      type: u1
    - id: case__41_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__37__tree_encoding:
    seq:
    - id: case__37_field0
      type: u2
    - id: case__37_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__37__case__37_field1_entries
      repeat: expr
      repeat-expr: 9
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__37__case__37_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__37__case__37_field1_entries:
    seq:
    - id: case__37_field1_elt_field0
      type: u1
    - id: case__37_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__33__tree_encoding:
    seq:
    - id: case__33_field0
      type: u2
    - id: case__33_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__33__case__33_field1_entries
      repeat: expr
      repeat-expr: 8
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__33__case__33_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__33__case__33_field1_entries:
    seq:
    - id: case__33_field1_elt_field0
      type: u1
    - id: case__33_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__29__tree_encoding:
    seq:
    - id: case__29_field0
      type: u2
    - id: case__29_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__29__case__29_field1_entries
      repeat: expr
      repeat-expr: 7
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__29__case__29_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__29__case__29_field1_entries:
    seq:
    - id: case__29_field1_elt_field0
      type: u1
    - id: case__29_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__25__tree_encoding:
    seq:
    - id: case__25_field0
      type: u2
    - id: case__25_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__25__case__25_field1_entries
      repeat: expr
      repeat-expr: 6
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__25__case__25_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__25__case__25_field1_entries:
    seq:
    - id: case__25_field1_elt_field0
      type: u1
    - id: case__25_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__21__tree_encoding:
    seq:
    - id: case__21_field0
      type: u2
    - id: case__21_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__21__case__21_field1_entries
      repeat: expr
      repeat-expr: 5
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__21__case__21_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__21__case__21_field1_entries:
    seq:
    - id: case__21_field1_elt_field0
      type: u1
    - id: case__21_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__17__tree_encoding:
    seq:
    - id: case__17_field0
      type: u2
    - id: case__17_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__17__case__17_field1_entries
      repeat: expr
      repeat-expr: 4
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__17__case__17_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__17__case__17_field1_entries:
    seq:
    - id: case__17_field1_elt_field0
      type: u1
    - id: case__17_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__13__tree_encoding:
    seq:
    - id: case__13_field0
      type: u2
    - id: case__13_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__13__case__13_field1_entries
      repeat: expr
      repeat-expr: 3
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__13__case__13_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__13__case__13_field1_entries:
    seq:
    - id: case__13_field1_elt_field0
      type: u1
    - id: case__13_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__9__tree_encoding:
    seq:
    - id: case__9_field0
      type: u2
    - id: case__9_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__9__case__9_field1_entries
      repeat: expr
      repeat-expr: 2
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__9__case__9_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__9__case__9_field1_entries:
    seq:
    - id: case__9_field1_elt_field0
      type: u1
    - id: case__9_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__5__tree_encoding:
    seq:
    - id: case__5_field0
      type: u2
    - id: case__5_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__5__case__5_field1_entries
      repeat: expr
      repeat-expr: 1
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__5__case__5_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__5__case__5_field1_entries:
    seq:
    - id: case__5_field1_elt_field0
      type: u1
    - id: case__5_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__64__tree_encoding:
    seq:
    - id: case__64_field0
      type: u1
    - id: case__64_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__64__case__64_field1_entries
      repeat: expr
      repeat-expr: 32
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__64__case__64_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__64__case__64_field1_entries:
    seq:
    - id: case__64_field1_elt
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__60__tree_encoding:
    seq:
    - id: case__60_field0
      type: u1
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__60__case__60_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__60__case__60_field1
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__60__case__60_field1:
    seq:
    - id: size_of_case__60_field1
      type: u4
      valid:
        max: 1073741823
    - id: case__60_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__60__case__60_field1_entries
      size: size_of_case__60_field1
      repeat: eos
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__60__case__60_field1_entries:
    seq:
    - id: case__60_field1_elt_field0
      type: u1
    - id: case__60_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__56__tree_encoding:
    seq:
    - id: case__56_field0
      type: u1
    - id: case__56_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__56__case__56_field1_entries
      repeat: expr
      repeat-expr: 14
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__56__case__56_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__56__case__56_field1_entries:
    seq:
    - id: case__56_field1_elt_field0
      type: u1
    - id: case__56_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__52__tree_encoding:
    seq:
    - id: case__52_field0
      type: u1
    - id: case__52_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__52__case__52_field1_entries
      repeat: expr
      repeat-expr: 13
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__52__case__52_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__52__case__52_field1_entries:
    seq:
    - id: case__52_field1_elt_field0
      type: u1
    - id: case__52_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__48__tree_encoding:
    seq:
    - id: case__48_field0
      type: u1
    - id: case__48_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__48__case__48_field1_entries
      repeat: expr
      repeat-expr: 12
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__48__case__48_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__48__case__48_field1_entries:
    seq:
    - id: case__48_field1_elt_field0
      type: u1
    - id: case__48_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__44__tree_encoding:
    seq:
    - id: case__44_field0
      type: u1
    - id: case__44_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__44__case__44_field1_entries
      repeat: expr
      repeat-expr: 11
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__44__case__44_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__44__case__44_field1_entries:
    seq:
    - id: case__44_field1_elt_field0
      type: u1
    - id: case__44_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__40__tree_encoding:
    seq:
    - id: case__40_field0
      type: u1
    - id: case__40_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__40__case__40_field1_entries
      repeat: expr
      repeat-expr: 10
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__40__case__40_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__40__case__40_field1_entries:
    seq:
    - id: case__40_field1_elt_field0
      type: u1
    - id: case__40_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__36__tree_encoding:
    seq:
    - id: case__36_field0
      type: u1
    - id: case__36_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__36__case__36_field1_entries
      repeat: expr
      repeat-expr: 9
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__36__case__36_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__36__case__36_field1_entries:
    seq:
    - id: case__36_field1_elt_field0
      type: u1
    - id: case__36_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__32__tree_encoding:
    seq:
    - id: case__32_field0
      type: u1
    - id: case__32_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__32__case__32_field1_entries
      repeat: expr
      repeat-expr: 8
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__32__case__32_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__32__case__32_field1_entries:
    seq:
    - id: case__32_field1_elt_field0
      type: u1
    - id: case__32_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__28__tree_encoding:
    seq:
    - id: case__28_field0
      type: u1
    - id: case__28_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__28__case__28_field1_entries
      repeat: expr
      repeat-expr: 7
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__28__case__28_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__28__case__28_field1_entries:
    seq:
    - id: case__28_field1_elt_field0
      type: u1
    - id: case__28_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__24__tree_encoding:
    seq:
    - id: case__24_field0
      type: u1
    - id: case__24_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__24__case__24_field1_entries
      repeat: expr
      repeat-expr: 6
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__24__case__24_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__24__case__24_field1_entries:
    seq:
    - id: case__24_field1_elt_field0
      type: u1
    - id: case__24_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__20__tree_encoding:
    seq:
    - id: case__20_field0
      type: u1
    - id: case__20_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__20__case__20_field1_entries
      repeat: expr
      repeat-expr: 5
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__20__case__20_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__20__case__20_field1_entries:
    seq:
    - id: case__20_field1_elt_field0
      type: u1
    - id: case__20_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__16__tree_encoding:
    seq:
    - id: case__16_field0
      type: u1
    - id: case__16_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__16__case__16_field1_entries
      repeat: expr
      repeat-expr: 4
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__16__case__16_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__16__case__16_field1_entries:
    seq:
    - id: case__16_field1_elt_field0
      type: u1
    - id: case__16_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__12__tree_encoding:
    seq:
    - id: case__12_field0
      type: u1
    - id: case__12_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__12__case__12_field1_entries
      repeat: expr
      repeat-expr: 3
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__12__case__12_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__12__case__12_field1_entries:
    seq:
    - id: case__12_field1_elt_field0
      type: u1
    - id: case__12_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__8__tree_encoding:
    seq:
    - id: case__8_field0
      type: u1
    - id: case__8_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__8__case__8_field1_entries
      repeat: expr
      repeat-expr: 2
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__8__case__8_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__8__case__8_field1_entries:
    seq:
    - id: case__8_field1_elt_field0
      type: u1
    - id: case__8_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__tree_encoding:
    seq:
    - id: case__4_field0
      type: u1
    - id: case__4_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__4_field1_entries
      repeat: expr
      repeat-expr: 1
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__4_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__4_field1_entries:
    seq:
    - id: case__4_field1_elt_field0
      type: u1
    - id: case__4_field1_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree:
    seq:
    - id: inode_tree_tag
      type: u1
      enum: inode_tree_tag
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__192__inode_tree
      size: 32
      if: (inode_tree_tag == ::inode_tree_tag::inode_tree_tag::case__192)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__208__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__208__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__208)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__209__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__209__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__209)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__210__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__210__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__210)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__211__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__211__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__211)
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__211__inode_tree:
    seq:
    - id: case__211_field0
      type: s8
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__211__case__211_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__211__case__211_field1
    - id: case__211_field2
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__211__case__211_field1:
    seq:
    - id: size_of_case__211_field1
      type: u1
      valid:
        max: 255
    - id: case__211_field1
      size: size_of_case__211_field1
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__210__inode_tree:
    seq:
    - id: case__210_field0
      type: s4
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__210__case__210_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__210__case__210_field1
    - id: case__210_field2
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__210__case__210_field1:
    seq:
    - id: size_of_case__210_field1
      type: u1
      valid:
        max: 255
    - id: case__210_field1
      size: size_of_case__210_field1
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__209__inode_tree:
    seq:
    - id: case__209_field0
      type: u2
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__209__case__209_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__209__case__209_field1
    - id: case__209_field2
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__209__case__209_field1:
    seq:
    - id: size_of_case__209_field1
      type: u1
      valid:
        max: 255
    - id: case__209_field1
      size: size_of_case__209_field1
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__208__inode_tree:
    seq:
    - id: case__208_field0
      type: u1
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__208__case__208_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__208__case__208_field1
    - id: case__208_field2
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__208__case__208_field1:
    seq:
    - id: size_of_case__208_field1
      type: u1
      valid:
        max: 255
    - id: case__208_field1
      size: size_of_case__208_field1
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__191__inode_tree:
    seq:
    - id: size_of_case__191
      type: u4
      valid:
        max: 1073741823
    - id: case__191
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__191__case__191_entries
      size: size_of_case__191
      repeat: eos
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__191__case__191_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__191__case__191_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__191__case__191_elt_field0
    - id: case__191_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__191__case__191_elt_field0:
    seq:
    - id: size_of_case__191_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__191_elt_field0
      size: size_of_case__191_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__190__case__190_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__190__case__190_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__190__case__190_elt_field0
    - id: case__190_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__190__case__190_elt_field0:
    seq:
    - id: size_of_case__190_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__190_elt_field0
      size: size_of_case__190_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__189__case__189_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__189__case__189_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__189__case__189_elt_field0
    - id: case__189_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__189__case__189_elt_field0:
    seq:
    - id: size_of_case__189_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__189_elt_field0
      size: size_of_case__189_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__188__case__188_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__188__case__188_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__188__case__188_elt_field0
    - id: case__188_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__188__case__188_elt_field0:
    seq:
    - id: size_of_case__188_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__188_elt_field0
      size: size_of_case__188_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__187__case__187_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__187__case__187_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__187__case__187_elt_field0
    - id: case__187_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__187__case__187_elt_field0:
    seq:
    - id: size_of_case__187_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__187_elt_field0
      size: size_of_case__187_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__186__case__186_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__186__case__186_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__186__case__186_elt_field0
    - id: case__186_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__186__case__186_elt_field0:
    seq:
    - id: size_of_case__186_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__186_elt_field0
      size: size_of_case__186_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__185__case__185_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__185__case__185_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__185__case__185_elt_field0
    - id: case__185_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__185__case__185_elt_field0:
    seq:
    - id: size_of_case__185_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__185_elt_field0
      size: size_of_case__185_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__184__case__184_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__184__case__184_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__184__case__184_elt_field0
    - id: case__184_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__184__case__184_elt_field0:
    seq:
    - id: size_of_case__184_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__184_elt_field0
      size: size_of_case__184_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__183__case__183_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__183__case__183_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__183__case__183_elt_field0
    - id: case__183_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__183__case__183_elt_field0:
    seq:
    - id: size_of_case__183_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__183_elt_field0
      size: size_of_case__183_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__182__case__182_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__182__case__182_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__182__case__182_elt_field0
    - id: case__182_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__182__case__182_elt_field0:
    seq:
    - id: size_of_case__182_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__182_elt_field0
      size: size_of_case__182_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__181__case__181_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__181__case__181_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__181__case__181_elt_field0
    - id: case__181_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__181__case__181_elt_field0:
    seq:
    - id: size_of_case__181_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__181_elt_field0
      size: size_of_case__181_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__180__case__180_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__180__case__180_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__180__case__180_elt_field0
    - id: case__180_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__180__case__180_elt_field0:
    seq:
    - id: size_of_case__180_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__180_elt_field0
      size: size_of_case__180_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__179__case__179_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__179__case__179_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__179__case__179_elt_field0
    - id: case__179_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__179__case__179_elt_field0:
    seq:
    - id: size_of_case__179_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__179_elt_field0
      size: size_of_case__179_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__178__case__178_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__178__case__178_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__178__case__178_elt_field0
    - id: case__178_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__178__case__178_elt_field0:
    seq:
    - id: size_of_case__178_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__178_elt_field0
      size: size_of_case__178_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__177__case__177_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__177__case__177_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__177__case__177_elt_field0
    - id: case__177_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__177__case__177_elt_field0:
    seq:
    - id: size_of_case__177_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__177_elt_field0
      size: size_of_case__177_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__176__case__176_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__176__case__176_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__176__case__176_elt_field0
    - id: case__176_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__176__case__176_elt_field0:
    seq:
    - id: size_of_case__176_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__176_elt_field0
      size: size_of_case__176_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__175__case__175_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__175__case__175_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__175__case__175_elt_field0
    - id: case__175_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__175__case__175_elt_field0:
    seq:
    - id: size_of_case__175_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__175_elt_field0
      size: size_of_case__175_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__174__case__174_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__174__case__174_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__174__case__174_elt_field0
    - id: case__174_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__174__case__174_elt_field0:
    seq:
    - id: size_of_case__174_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__174_elt_field0
      size: size_of_case__174_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__173__case__173_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__173__case__173_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__173__case__173_elt_field0
    - id: case__173_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__173__case__173_elt_field0:
    seq:
    - id: size_of_case__173_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__173_elt_field0
      size: size_of_case__173_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__172__case__172_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__172__case__172_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__172__case__172_elt_field0
    - id: case__172_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__172__case__172_elt_field0:
    seq:
    - id: size_of_case__172_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__172_elt_field0
      size: size_of_case__172_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__171__case__171_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__171__case__171_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__171__case__171_elt_field0
    - id: case__171_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__171__case__171_elt_field0:
    seq:
    - id: size_of_case__171_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__171_elt_field0
      size: size_of_case__171_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__170__case__170_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__170__case__170_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__170__case__170_elt_field0
    - id: case__170_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__170__case__170_elt_field0:
    seq:
    - id: size_of_case__170_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__170_elt_field0
      size: size_of_case__170_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__169__case__169_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__169__case__169_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__169__case__169_elt_field0
    - id: case__169_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__169__case__169_elt_field0:
    seq:
    - id: size_of_case__169_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__169_elt_field0
      size: size_of_case__169_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__168__case__168_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__168__case__168_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__168__case__168_elt_field0
    - id: case__168_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__168__case__168_elt_field0:
    seq:
    - id: size_of_case__168_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__168_elt_field0
      size: size_of_case__168_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__167__case__167_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__167__case__167_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__167__case__167_elt_field0
    - id: case__167_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__167__case__167_elt_field0:
    seq:
    - id: size_of_case__167_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__167_elt_field0
      size: size_of_case__167_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__166__case__166_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__166__case__166_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__166__case__166_elt_field0
    - id: case__166_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__166__case__166_elt_field0:
    seq:
    - id: size_of_case__166_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__166_elt_field0
      size: size_of_case__166_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__165__case__165_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__165__case__165_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__165__case__165_elt_field0
    - id: case__165_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__165__case__165_elt_field0:
    seq:
    - id: size_of_case__165_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__165_elt_field0
      size: size_of_case__165_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__164__case__164_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__164__case__164_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__164__case__164_elt_field0
    - id: case__164_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__164__case__164_elt_field0:
    seq:
    - id: size_of_case__164_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__164_elt_field0
      size: size_of_case__164_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__163__case__163_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__163__case__163_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__163__case__163_elt_field0
    - id: case__163_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__163__case__163_elt_field0:
    seq:
    - id: size_of_case__163_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__163_elt_field0
      size: size_of_case__163_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__162__case__162_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__162__case__162_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__162__case__162_elt_field0
    - id: case__162_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__162__case__162_elt_field0:
    seq:
    - id: size_of_case__162_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__162_elt_field0
      size: size_of_case__162_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__161__case__161_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__161__case__161_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__161__case__161_elt_field0
    - id: case__161_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__161__case__161_elt_field0:
    seq:
    - id: size_of_case__161_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__161_elt_field0
      size: size_of_case__161_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__160__case__160_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__160__case__160_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__160__case__160_elt_field0
    - id: case__160_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__160__case__160_elt_field0:
    seq:
    - id: size_of_case__160_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__160_elt_field0
      size: size_of_case__160_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__159__case__159_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__159__case__159_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__159__case__159_elt_field0
    - id: case__159_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__159__case__159_elt_field0:
    seq:
    - id: size_of_case__159_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__159_elt_field0
      size: size_of_case__159_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__158__case__158_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__158__case__158_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__158__case__158_elt_field0
    - id: case__158_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__158__case__158_elt_field0:
    seq:
    - id: size_of_case__158_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__158_elt_field0
      size: size_of_case__158_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__157__case__157_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__157__case__157_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__157__case__157_elt_field0
    - id: case__157_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__157__case__157_elt_field0:
    seq:
    - id: size_of_case__157_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__157_elt_field0
      size: size_of_case__157_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__156__case__156_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__156__case__156_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__156__case__156_elt_field0
    - id: case__156_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__156__case__156_elt_field0:
    seq:
    - id: size_of_case__156_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__156_elt_field0
      size: size_of_case__156_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__155__case__155_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__155__case__155_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__155__case__155_elt_field0
    - id: case__155_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__155__case__155_elt_field0:
    seq:
    - id: size_of_case__155_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__155_elt_field0
      size: size_of_case__155_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__154__case__154_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__154__case__154_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__154__case__154_elt_field0
    - id: case__154_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__154__case__154_elt_field0:
    seq:
    - id: size_of_case__154_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__154_elt_field0
      size: size_of_case__154_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__153__case__153_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__153__case__153_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__153__case__153_elt_field0
    - id: case__153_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__153__case__153_elt_field0:
    seq:
    - id: size_of_case__153_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__153_elt_field0
      size: size_of_case__153_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__152__case__152_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__152__case__152_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__152__case__152_elt_field0
    - id: case__152_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__152__case__152_elt_field0:
    seq:
    - id: size_of_case__152_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__152_elt_field0
      size: size_of_case__152_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__151__case__151_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__151__case__151_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__151__case__151_elt_field0
    - id: case__151_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__151__case__151_elt_field0:
    seq:
    - id: size_of_case__151_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__151_elt_field0
      size: size_of_case__151_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__150__case__150_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__150__case__150_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__150__case__150_elt_field0
    - id: case__150_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__150__case__150_elt_field0:
    seq:
    - id: size_of_case__150_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__150_elt_field0
      size: size_of_case__150_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__149__case__149_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__149__case__149_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__149__case__149_elt_field0
    - id: case__149_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__149__case__149_elt_field0:
    seq:
    - id: size_of_case__149_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__149_elt_field0
      size: size_of_case__149_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__148__case__148_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__148__case__148_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__148__case__148_elt_field0
    - id: case__148_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__148__case__148_elt_field0:
    seq:
    - id: size_of_case__148_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__148_elt_field0
      size: size_of_case__148_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__147__case__147_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__147__case__147_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__147__case__147_elt_field0
    - id: case__147_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__147__case__147_elt_field0:
    seq:
    - id: size_of_case__147_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__147_elt_field0
      size: size_of_case__147_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__146__case__146_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__146__case__146_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__146__case__146_elt_field0
    - id: case__146_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__146__case__146_elt_field0:
    seq:
    - id: size_of_case__146_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__146_elt_field0
      size: size_of_case__146_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__145__case__145_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__145__case__145_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__145__case__145_elt_field0
    - id: case__145_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__145__case__145_elt_field0:
    seq:
    - id: size_of_case__145_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__145_elt_field0
      size: size_of_case__145_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__144__case__144_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__144__case__144_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__144__case__144_elt_field0
    - id: case__144_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__144__case__144_elt_field0:
    seq:
    - id: size_of_case__144_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__144_elt_field0
      size: size_of_case__144_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__143__case__143_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__143__case__143_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__143__case__143_elt_field0
    - id: case__143_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__143__case__143_elt_field0:
    seq:
    - id: size_of_case__143_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__143_elt_field0
      size: size_of_case__143_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__142__case__142_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__142__case__142_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__142__case__142_elt_field0
    - id: case__142_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__142__case__142_elt_field0:
    seq:
    - id: size_of_case__142_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__142_elt_field0
      size: size_of_case__142_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__141__case__141_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__141__case__141_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__141__case__141_elt_field0
    - id: case__141_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__141__case__141_elt_field0:
    seq:
    - id: size_of_case__141_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__141_elt_field0
      size: size_of_case__141_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__140__case__140_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__140__case__140_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__140__case__140_elt_field0
    - id: case__140_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__140__case__140_elt_field0:
    seq:
    - id: size_of_case__140_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__140_elt_field0
      size: size_of_case__140_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__139__case__139_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__139__case__139_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__139__case__139_elt_field0
    - id: case__139_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__139__case__139_elt_field0:
    seq:
    - id: size_of_case__139_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__139_elt_field0
      size: size_of_case__139_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__138__case__138_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__138__case__138_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__138__case__138_elt_field0
    - id: case__138_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__138__case__138_elt_field0:
    seq:
    - id: size_of_case__138_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__138_elt_field0
      size: size_of_case__138_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__137__case__137_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__137__case__137_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__137__case__137_elt_field0
    - id: case__137_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__137__case__137_elt_field0:
    seq:
    - id: size_of_case__137_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__137_elt_field0
      size: size_of_case__137_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__136__case__136_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__136__case__136_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__136__case__136_elt_field0
    - id: case__136_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__136__case__136_elt_field0:
    seq:
    - id: size_of_case__136_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__136_elt_field0
      size: size_of_case__136_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__135__case__135_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__135__case__135_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__135__case__135_elt_field0
    - id: case__135_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__135__case__135_elt_field0:
    seq:
    - id: size_of_case__135_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__135_elt_field0
      size: size_of_case__135_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__134__case__134_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__134__case__134_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__134__case__134_elt_field0
    - id: case__134_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__134__case__134_elt_field0:
    seq:
    - id: size_of_case__134_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__134_elt_field0
      size: size_of_case__134_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__133__case__133_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__133__case__133_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__133__case__133_elt_field0
    - id: case__133_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__133__case__133_elt_field0:
    seq:
    - id: size_of_case__133_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__133_elt_field0
      size: size_of_case__133_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__132__case__132_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__132__case__132_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__132__case__132_elt_field0
    - id: case__132_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__132__case__132_elt_field0:
    seq:
    - id: size_of_case__132_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__132_elt_field0
      size: size_of_case__132_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__131__case__131_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__131__case__131_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__131__case__131_elt_field0
    - id: case__131_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__131__case__131_elt_field0:
    seq:
    - id: size_of_case__131_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__131_elt_field0
      size: size_of_case__131_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__130__case__130_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__130__case__130_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__130__case__130_elt_field0
    - id: case__130_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__130__case__130_elt_field0:
    seq:
    - id: size_of_case__130_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__130_elt_field0
      size: size_of_case__130_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__129__case__129_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__129__case__129_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__129__case__129_elt_field0
    - id: case__129_elt_field1
      type: tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__129__case__129_elt_field0:
    seq:
    - id: size_of_case__129_elt_field0
      type: u1
      valid:
        max: 255
    - id: case__129_elt_field0
      size: size_of_case__129_elt_field0
      size-eos: true
      valid:
        max: 255
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__67__inode_tree:
    seq:
    - id: case__67_field0
      type: s8
    - id: case__67_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__67__case__67_field1_entries
      repeat: expr
      repeat-expr: 32
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__67__case__67_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__67__case__67_field1_entries:
    seq:
    - id: case__67_field1_elt
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__63__inode_tree:
    seq:
    - id: case__63_field0
      type: s8
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__63__case__63_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__63__case__63_field1
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__63__case__63_field1:
    seq:
    - id: size_of_case__63_field1
      type: u4
      valid:
        max: 1073741823
    - id: case__63_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__63__case__63_field1_entries
      size: size_of_case__63_field1
      repeat: eos
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__63__case__63_field1_entries:
    seq:
    - id: case__63_field1_elt_field0
      type: u1
    - id: case__63_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__59__inode_tree:
    seq:
    - id: case__59_field0
      type: s8
    - id: case__59_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__59__case__59_field1_entries
      repeat: expr
      repeat-expr: 14
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__59__case__59_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__59__case__59_field1_entries:
    seq:
    - id: case__59_field1_elt_field0
      type: u1
    - id: case__59_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__55__inode_tree:
    seq:
    - id: case__55_field0
      type: s8
    - id: case__55_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__55__case__55_field1_entries
      repeat: expr
      repeat-expr: 13
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__55__case__55_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__55__case__55_field1_entries:
    seq:
    - id: case__55_field1_elt_field0
      type: u1
    - id: case__55_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__51__inode_tree:
    seq:
    - id: case__51_field0
      type: s8
    - id: case__51_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__51__case__51_field1_entries
      repeat: expr
      repeat-expr: 12
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__51__case__51_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__51__case__51_field1_entries:
    seq:
    - id: case__51_field1_elt_field0
      type: u1
    - id: case__51_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__47__inode_tree:
    seq:
    - id: case__47_field0
      type: s8
    - id: case__47_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__47__case__47_field1_entries
      repeat: expr
      repeat-expr: 11
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__47__case__47_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__47__case__47_field1_entries:
    seq:
    - id: case__47_field1_elt_field0
      type: u1
    - id: case__47_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__43__inode_tree:
    seq:
    - id: case__43_field0
      type: s8
    - id: case__43_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__43__case__43_field1_entries
      repeat: expr
      repeat-expr: 10
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__43__case__43_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__43__case__43_field1_entries:
    seq:
    - id: case__43_field1_elt_field0
      type: u1
    - id: case__43_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__39__inode_tree:
    seq:
    - id: case__39_field0
      type: s8
    - id: case__39_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__39__case__39_field1_entries
      repeat: expr
      repeat-expr: 9
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__39__case__39_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__39__case__39_field1_entries:
    seq:
    - id: case__39_field1_elt_field0
      type: u1
    - id: case__39_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__35__inode_tree:
    seq:
    - id: case__35_field0
      type: s8
    - id: case__35_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__35__case__35_field1_entries
      repeat: expr
      repeat-expr: 8
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__35__case__35_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__35__case__35_field1_entries:
    seq:
    - id: case__35_field1_elt_field0
      type: u1
    - id: case__35_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__31__inode_tree:
    seq:
    - id: case__31_field0
      type: s8
    - id: case__31_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__31__case__31_field1_entries
      repeat: expr
      repeat-expr: 7
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__31__case__31_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__31__case__31_field1_entries:
    seq:
    - id: case__31_field1_elt_field0
      type: u1
    - id: case__31_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__27__inode_tree:
    seq:
    - id: case__27_field0
      type: s8
    - id: case__27_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__27__case__27_field1_entries
      repeat: expr
      repeat-expr: 6
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__27__case__27_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__27__case__27_field1_entries:
    seq:
    - id: case__27_field1_elt_field0
      type: u1
    - id: case__27_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__23__inode_tree:
    seq:
    - id: case__23_field0
      type: s8
    - id: case__23_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__23__case__23_field1_entries
      repeat: expr
      repeat-expr: 5
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__23__case__23_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__23__case__23_field1_entries:
    seq:
    - id: case__23_field1_elt_field0
      type: u1
    - id: case__23_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__19__inode_tree:
    seq:
    - id: case__19_field0
      type: s8
    - id: case__19_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__19__case__19_field1_entries
      repeat: expr
      repeat-expr: 4
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__19__case__19_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__19__case__19_field1_entries:
    seq:
    - id: case__19_field1_elt_field0
      type: u1
    - id: case__19_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__15__inode_tree:
    seq:
    - id: case__15_field0
      type: s8
    - id: case__15_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__15__case__15_field1_entries
      repeat: expr
      repeat-expr: 3
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__15__case__15_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__15__case__15_field1_entries:
    seq:
    - id: case__15_field1_elt_field0
      type: u1
    - id: case__15_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__11__inode_tree:
    seq:
    - id: case__11_field0
      type: s8
    - id: case__11_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__11__case__11_field1_entries
      repeat: expr
      repeat-expr: 2
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__11__case__11_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__11__case__11_field1_entries:
    seq:
    - id: case__11_field1_elt_field0
      type: u1
    - id: case__11_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__7__inode_tree:
    seq:
    - id: case__7_field0
      type: s8
    - id: case__7_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__7__case__7_field1_entries
      repeat: expr
      repeat-expr: 1
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__7__case__7_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__7__case__7_field1_entries:
    seq:
    - id: case__7_field1_elt_field0
      type: u1
    - id: case__7_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__66__inode_tree:
    seq:
    - id: case__66_field0
      type: s4
    - id: case__66_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__66__case__66_field1_entries
      repeat: expr
      repeat-expr: 32
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__66__case__66_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__66__case__66_field1_entries:
    seq:
    - id: case__66_field1_elt
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__62__inode_tree:
    seq:
    - id: case__62_field0
      type: s4
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__62__case__62_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__62__case__62_field1
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__62__case__62_field1:
    seq:
    - id: size_of_case__62_field1
      type: u4
      valid:
        max: 1073741823
    - id: case__62_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__62__case__62_field1_entries
      size: size_of_case__62_field1
      repeat: eos
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__62__case__62_field1_entries:
    seq:
    - id: case__62_field1_elt_field0
      type: u1
    - id: case__62_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__58__inode_tree:
    seq:
    - id: case__58_field0
      type: s4
    - id: case__58_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__58__case__58_field1_entries
      repeat: expr
      repeat-expr: 14
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__58__case__58_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__58__case__58_field1_entries:
    seq:
    - id: case__58_field1_elt_field0
      type: u1
    - id: case__58_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__54__inode_tree:
    seq:
    - id: case__54_field0
      type: s4
    - id: case__54_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__54__case__54_field1_entries
      repeat: expr
      repeat-expr: 13
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__54__case__54_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__54__case__54_field1_entries:
    seq:
    - id: case__54_field1_elt_field0
      type: u1
    - id: case__54_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__50__inode_tree:
    seq:
    - id: case__50_field0
      type: s4
    - id: case__50_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__50__case__50_field1_entries
      repeat: expr
      repeat-expr: 12
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__50__case__50_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__50__case__50_field1_entries:
    seq:
    - id: case__50_field1_elt_field0
      type: u1
    - id: case__50_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__46__inode_tree:
    seq:
    - id: case__46_field0
      type: s4
    - id: case__46_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__46__case__46_field1_entries
      repeat: expr
      repeat-expr: 11
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__46__case__46_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__46__case__46_field1_entries:
    seq:
    - id: case__46_field1_elt_field0
      type: u1
    - id: case__46_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__42__inode_tree:
    seq:
    - id: case__42_field0
      type: s4
    - id: case__42_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__42__case__42_field1_entries
      repeat: expr
      repeat-expr: 10
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__42__case__42_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__42__case__42_field1_entries:
    seq:
    - id: case__42_field1_elt_field0
      type: u1
    - id: case__42_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__38__inode_tree:
    seq:
    - id: case__38_field0
      type: s4
    - id: case__38_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__38__case__38_field1_entries
      repeat: expr
      repeat-expr: 9
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__38__case__38_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__38__case__38_field1_entries:
    seq:
    - id: case__38_field1_elt_field0
      type: u1
    - id: case__38_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__34__inode_tree:
    seq:
    - id: case__34_field0
      type: s4
    - id: case__34_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__34__case__34_field1_entries
      repeat: expr
      repeat-expr: 8
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__34__case__34_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__34__case__34_field1_entries:
    seq:
    - id: case__34_field1_elt_field0
      type: u1
    - id: case__34_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__30__inode_tree:
    seq:
    - id: case__30_field0
      type: s4
    - id: case__30_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__30__case__30_field1_entries
      repeat: expr
      repeat-expr: 7
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__30__case__30_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__30__case__30_field1_entries:
    seq:
    - id: case__30_field1_elt_field0
      type: u1
    - id: case__30_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__26__inode_tree:
    seq:
    - id: case__26_field0
      type: s4
    - id: case__26_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__26__case__26_field1_entries
      repeat: expr
      repeat-expr: 6
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__26__case__26_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__26__case__26_field1_entries:
    seq:
    - id: case__26_field1_elt_field0
      type: u1
    - id: case__26_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__22__inode_tree:
    seq:
    - id: case__22_field0
      type: s4
    - id: case__22_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__22__case__22_field1_entries
      repeat: expr
      repeat-expr: 5
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__22__case__22_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__22__case__22_field1_entries:
    seq:
    - id: case__22_field1_elt_field0
      type: u1
    - id: case__22_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__18__inode_tree:
    seq:
    - id: case__18_field0
      type: s4
    - id: case__18_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__18__case__18_field1_entries
      repeat: expr
      repeat-expr: 4
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__18__case__18_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__18__case__18_field1_entries:
    seq:
    - id: case__18_field1_elt_field0
      type: u1
    - id: case__18_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__14__inode_tree:
    seq:
    - id: case__14_field0
      type: s4
    - id: case__14_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__14__case__14_field1_entries
      repeat: expr
      repeat-expr: 3
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__14__case__14_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__14__case__14_field1_entries:
    seq:
    - id: case__14_field1_elt_field0
      type: u1
    - id: case__14_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__10__inode_tree:
    seq:
    - id: case__10_field0
      type: s4
    - id: case__10_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__10__case__10_field1_entries
      repeat: expr
      repeat-expr: 2
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__10__case__10_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__10__case__10_field1_entries:
    seq:
    - id: case__10_field1_elt_field0
      type: u1
    - id: case__10_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__6__inode_tree:
    seq:
    - id: case__6_field0
      type: s4
    - id: case__6_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__6__case__6_field1_entries
      repeat: expr
      repeat-expr: 1
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__6__case__6_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__6__case__6_field1_entries:
    seq:
    - id: case__6_field1_elt_field0
      type: u1
    - id: case__6_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__65__inode_tree:
    seq:
    - id: case__65_field0
      type: u2
    - id: case__65_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__65__case__65_field1_entries
      repeat: expr
      repeat-expr: 32
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__65__case__65_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__65__case__65_field1_entries:
    seq:
    - id: case__65_field1_elt
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__61__inode_tree:
    seq:
    - id: case__61_field0
      type: u2
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__61__case__61_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__61__case__61_field1
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__61__case__61_field1:
    seq:
    - id: size_of_case__61_field1
      type: u4
      valid:
        max: 1073741823
    - id: case__61_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__61__case__61_field1_entries
      size: size_of_case__61_field1
      repeat: eos
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__61__case__61_field1_entries:
    seq:
    - id: case__61_field1_elt_field0
      type: u1
    - id: case__61_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__57__inode_tree:
    seq:
    - id: case__57_field0
      type: u2
    - id: case__57_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__57__case__57_field1_entries
      repeat: expr
      repeat-expr: 14
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__57__case__57_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__57__case__57_field1_entries:
    seq:
    - id: case__57_field1_elt_field0
      type: u1
    - id: case__57_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__53__inode_tree:
    seq:
    - id: case__53_field0
      type: u2
    - id: case__53_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__53__case__53_field1_entries
      repeat: expr
      repeat-expr: 13
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__53__case__53_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__53__case__53_field1_entries:
    seq:
    - id: case__53_field1_elt_field0
      type: u1
    - id: case__53_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__49__inode_tree:
    seq:
    - id: case__49_field0
      type: u2
    - id: case__49_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__49__case__49_field1_entries
      repeat: expr
      repeat-expr: 12
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__49__case__49_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__49__case__49_field1_entries:
    seq:
    - id: case__49_field1_elt_field0
      type: u1
    - id: case__49_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__45__inode_tree:
    seq:
    - id: case__45_field0
      type: u2
    - id: case__45_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__45__case__45_field1_entries
      repeat: expr
      repeat-expr: 11
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__45__case__45_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__45__case__45_field1_entries:
    seq:
    - id: case__45_field1_elt_field0
      type: u1
    - id: case__45_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__41__inode_tree:
    seq:
    - id: case__41_field0
      type: u2
    - id: case__41_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__41__case__41_field1_entries
      repeat: expr
      repeat-expr: 10
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__41__case__41_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__41__case__41_field1_entries:
    seq:
    - id: case__41_field1_elt_field0
      type: u1
    - id: case__41_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__37__inode_tree:
    seq:
    - id: case__37_field0
      type: u2
    - id: case__37_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__37__case__37_field1_entries
      repeat: expr
      repeat-expr: 9
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__37__case__37_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__37__case__37_field1_entries:
    seq:
    - id: case__37_field1_elt_field0
      type: u1
    - id: case__37_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__33__inode_tree:
    seq:
    - id: case__33_field0
      type: u2
    - id: case__33_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__33__case__33_field1_entries
      repeat: expr
      repeat-expr: 8
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__33__case__33_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__33__case__33_field1_entries:
    seq:
    - id: case__33_field1_elt_field0
      type: u1
    - id: case__33_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__29__inode_tree:
    seq:
    - id: case__29_field0
      type: u2
    - id: case__29_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__29__case__29_field1_entries
      repeat: expr
      repeat-expr: 7
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__29__case__29_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__29__case__29_field1_entries:
    seq:
    - id: case__29_field1_elt_field0
      type: u1
    - id: case__29_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__25__inode_tree:
    seq:
    - id: case__25_field0
      type: u2
    - id: case__25_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__25__case__25_field1_entries
      repeat: expr
      repeat-expr: 6
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__25__case__25_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__25__case__25_field1_entries:
    seq:
    - id: case__25_field1_elt_field0
      type: u1
    - id: case__25_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__21__inode_tree:
    seq:
    - id: case__21_field0
      type: u2
    - id: case__21_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__21__case__21_field1_entries
      repeat: expr
      repeat-expr: 5
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__21__case__21_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__21__case__21_field1_entries:
    seq:
    - id: case__21_field1_elt_field0
      type: u1
    - id: case__21_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__17__inode_tree:
    seq:
    - id: case__17_field0
      type: u2
    - id: case__17_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__17__case__17_field1_entries
      repeat: expr
      repeat-expr: 4
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__17__case__17_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__17__case__17_field1_entries:
    seq:
    - id: case__17_field1_elt_field0
      type: u1
    - id: case__17_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__13__inode_tree:
    seq:
    - id: case__13_field0
      type: u2
    - id: case__13_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__13__case__13_field1_entries
      repeat: expr
      repeat-expr: 3
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__13__case__13_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__13__case__13_field1_entries:
    seq:
    - id: case__13_field1_elt_field0
      type: u1
    - id: case__13_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__9__inode_tree:
    seq:
    - id: case__9_field0
      type: u2
    - id: case__9_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__9__case__9_field1_entries
      repeat: expr
      repeat-expr: 2
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__9__case__9_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__9__case__9_field1_entries:
    seq:
    - id: case__9_field1_elt_field0
      type: u1
    - id: case__9_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__5__inode_tree:
    seq:
    - id: case__5_field0
      type: u2
    - id: case__5_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__5__case__5_field1_entries
      repeat: expr
      repeat-expr: 1
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__5__case__5_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__5__case__5_field1_entries:
    seq:
    - id: case__5_field1_elt_field0
      type: u1
    - id: case__5_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__64__inode_tree:
    seq:
    - id: case__64_field0
      type: u1
    - id: case__64_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__64__case__64_field1_entries
      repeat: expr
      repeat-expr: 32
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__64__case__64_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__64__case__64_field1_entries:
    seq:
    - id: case__64_field1_elt
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__60__inode_tree:
    seq:
    - id: case__60_field0
      type: u1
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__60__case__60_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__60__case__60_field1
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__60__case__60_field1:
    seq:
    - id: size_of_case__60_field1
      type: u4
      valid:
        max: 1073741823
    - id: case__60_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__60__case__60_field1_entries
      size: size_of_case__60_field1
      repeat: eos
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__60__case__60_field1_entries:
    seq:
    - id: case__60_field1_elt_field0
      type: u1
    - id: case__60_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__56__inode_tree:
    seq:
    - id: case__56_field0
      type: u1
    - id: case__56_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__56__case__56_field1_entries
      repeat: expr
      repeat-expr: 14
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__56__case__56_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__56__case__56_field1_entries:
    seq:
    - id: case__56_field1_elt_field0
      type: u1
    - id: case__56_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__52__inode_tree:
    seq:
    - id: case__52_field0
      type: u1
    - id: case__52_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__52__case__52_field1_entries
      repeat: expr
      repeat-expr: 13
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__52__case__52_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__52__case__52_field1_entries:
    seq:
    - id: case__52_field1_elt_field0
      type: u1
    - id: case__52_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__48__inode_tree:
    seq:
    - id: case__48_field0
      type: u1
    - id: case__48_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__48__case__48_field1_entries
      repeat: expr
      repeat-expr: 12
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__48__case__48_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__48__case__48_field1_entries:
    seq:
    - id: case__48_field1_elt_field0
      type: u1
    - id: case__48_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__44__inode_tree:
    seq:
    - id: case__44_field0
      type: u1
    - id: case__44_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__44__case__44_field1_entries
      repeat: expr
      repeat-expr: 11
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__44__case__44_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__44__case__44_field1_entries:
    seq:
    - id: case__44_field1_elt_field0
      type: u1
    - id: case__44_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__40__inode_tree:
    seq:
    - id: case__40_field0
      type: u1
    - id: case__40_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__40__case__40_field1_entries
      repeat: expr
      repeat-expr: 10
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__40__case__40_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__40__case__40_field1_entries:
    seq:
    - id: case__40_field1_elt_field0
      type: u1
    - id: case__40_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__36__inode_tree:
    seq:
    - id: case__36_field0
      type: u1
    - id: case__36_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__36__case__36_field1_entries
      repeat: expr
      repeat-expr: 9
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__36__case__36_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__36__case__36_field1_entries:
    seq:
    - id: case__36_field1_elt_field0
      type: u1
    - id: case__36_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__32__inode_tree:
    seq:
    - id: case__32_field0
      type: u1
    - id: case__32_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__32__case__32_field1_entries
      repeat: expr
      repeat-expr: 8
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__32__case__32_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__32__case__32_field1_entries:
    seq:
    - id: case__32_field1_elt_field0
      type: u1
    - id: case__32_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__28__inode_tree:
    seq:
    - id: case__28_field0
      type: u1
    - id: case__28_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__28__case__28_field1_entries
      repeat: expr
      repeat-expr: 7
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__28__case__28_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__28__case__28_field1_entries:
    seq:
    - id: case__28_field1_elt_field0
      type: u1
    - id: case__28_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__24__inode_tree:
    seq:
    - id: case__24_field0
      type: u1
    - id: case__24_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__24__case__24_field1_entries
      repeat: expr
      repeat-expr: 6
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__24__case__24_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__24__case__24_field1_entries:
    seq:
    - id: case__24_field1_elt_field0
      type: u1
    - id: case__24_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__20__inode_tree:
    seq:
    - id: case__20_field0
      type: u1
    - id: case__20_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__20__case__20_field1_entries
      repeat: expr
      repeat-expr: 5
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__20__case__20_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__20__case__20_field1_entries:
    seq:
    - id: case__20_field1_elt_field0
      type: u1
    - id: case__20_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__16__inode_tree:
    seq:
    - id: case__16_field0
      type: u1
    - id: case__16_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__16__case__16_field1_entries
      repeat: expr
      repeat-expr: 4
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__16__case__16_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__16__case__16_field1_entries:
    seq:
    - id: case__16_field1_elt_field0
      type: u1
    - id: case__16_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__12__inode_tree:
    seq:
    - id: case__12_field0
      type: u1
    - id: case__12_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__12__case__12_field1_entries
      repeat: expr
      repeat-expr: 3
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__12__case__12_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__12__case__12_field1_entries:
    seq:
    - id: case__12_field1_elt_field0
      type: u1
    - id: case__12_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__8__inode_tree:
    seq:
    - id: case__8_field0
      type: u1
    - id: case__8_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__8__case__8_field1_entries
      repeat: expr
      repeat-expr: 2
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__8__case__8_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__8__case__8_field1_entries:
    seq:
    - id: case__8_field1_elt_field0
      type: u1
    - id: case__8_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__4__inode_tree:
    seq:
    - id: case__4_field0
      type: u1
    - id: case__4_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__4__case__4_field1_entries
      repeat: expr
      repeat-expr: 1
      doc: ! >-
        sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__4__case__4_field1_entries
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__4__case__4_field1_entries:
    seq:
    - id: case__4_field1_elt_field0
      type: u1
    - id: case__4_field1_elt_field1
      type: inode_tree
  sc_rollup_refute__dissection__step:
    seq:
    - id: size_of_dissection
      type: u4
      valid:
        max: 1073741823
    - id: dissection
      type: sc_rollup_refute__dissection__dissection_entries
      size: size_of_dissection
      repeat: eos
  sc_rollup_refute__dissection__dissection_entries:
    seq:
    - id: state_tag
      type: u1
      enum: bool
    - id: state
      size: 32
      if: (state_tag == bool::true)
    - id: tick
      type: n
  sc_rollup_refute__id_015__ptlimapt__rollup_address:
    seq:
    - id: size_of_id_015__ptlimapt__rollup_address
      type: u4
      valid:
        max: 1073741823
    - id: id_015__ptlimapt__rollup_address
      size: size_of_id_015__ptlimapt__rollup_address
  sc_rollup_refute__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: sc_rollup_refute__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  sc_rollup_publish__id_015__ptlimapt__operation__alpha__contents:
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
      type: sc_rollup_publish__id_015__ptlimapt__rollup_address
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
    - id: number_of_ticks
      type: s8
  sc_rollup_publish__id_015__ptlimapt__rollup_address:
    seq:
    - id: size_of_id_015__ptlimapt__rollup_address
      type: u4
      valid:
        max: 1073741823
    - id: id_015__ptlimapt__rollup_address
      size: size_of_id_015__ptlimapt__rollup_address
  sc_rollup_publish__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: sc_rollup_publish__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  sc_rollup_cement__id_015__ptlimapt__operation__alpha__contents:
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
      type: sc_rollup_cement__id_015__ptlimapt__rollup_address
      doc: ! >-
        A smart contract rollup address: A smart contract rollup is identified by
        a base58 address starting with scr1
    - id: commitment
      size: 32
  sc_rollup_cement__id_015__ptlimapt__rollup_address:
    seq:
    - id: size_of_id_015__ptlimapt__rollup_address
      type: u4
      valid:
        max: 1073741823
    - id: id_015__ptlimapt__rollup_address
      size: size_of_id_015__ptlimapt__rollup_address
  sc_rollup_cement__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: sc_rollup_cement__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  sc_rollup_add_messages__id_015__ptlimapt__operation__alpha__contents:
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
      type: sc_rollup_add_messages__id_015__ptlimapt__rollup_address
      doc: ! >-
        A smart contract rollup address: A smart contract rollup is identified by
        a base58 address starting with scr1
    - id: sc_rollup_add_messages__message
      type: sc_rollup_add_messages__message
  sc_rollup_add_messages__message:
    seq:
    - id: size_of_message
      type: u4
      valid:
        max: 1073741823
    - id: message
      type: sc_rollup_add_messages__message_entries
      size: size_of_message
      repeat: eos
  sc_rollup_add_messages__message_entries:
    seq:
    - id: size_of_message_elt
      type: u4
      valid:
        max: 1073741823
    - id: message_elt
      size: size_of_message_elt
  sc_rollup_add_messages__id_015__ptlimapt__rollup_address:
    seq:
    - id: size_of_id_015__ptlimapt__rollup_address
      type: u4
      valid:
        max: 1073741823
    - id: id_015__ptlimapt__rollup_address
      size: size_of_id_015__ptlimapt__rollup_address
  sc_rollup_add_messages__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: sc_rollup_add_messages__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  sc_rollup_originate__id_015__ptlimapt__operation__alpha__contents:
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
    - id: pvm_kind
      type: u1
      enum: sc_rollup_originate__pvm_kind
    - id: sc_rollup_originate__boot_sector
      type: sc_rollup_originate__boot_sector
    - id: sc_rollup_originate__origination_proof
      type: sc_rollup_originate__origination_proof
    - id: sc_rollup_originate__parameters_ty
      type: sc_rollup_originate__parameters_ty
  sc_rollup_originate__parameters_ty:
    seq:
    - id: size_of_parameters_ty
      type: u4
      valid:
        max: 1073741823
    - id: parameters_ty
      size: size_of_parameters_ty
  sc_rollup_originate__origination_proof:
    seq:
    - id: size_of_origination_proof
      type: u4
      valid:
        max: 1073741823
    - id: origination_proof
      size: size_of_origination_proof
  sc_rollup_originate__boot_sector:
    seq:
    - id: size_of_boot_sector
      type: u4
      valid:
        max: 1073741823
    - id: boot_sector
      size: size_of_boot_sector
  sc_rollup_originate__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: sc_rollup_originate__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  dal_publish_slot_header__id_015__ptlimapt__operation__alpha__contents:
    seq:
    - id: source
      type: dal_publish_slot_header__public_key_hash
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
      size: 48
  dal_publish_slot_header__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: dal_publish_slot_header__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  transfer_ticket__id_015__ptlimapt__operation__alpha__contents:
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
      type: transfer_ticket__id_015__ptlimapt__contract_id
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: ticket_amount
      type: n
    - id: destination
      type: transfer_ticket__id_015__ptlimapt__contract_id
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: transfer_ticket__entrypoint
      type: transfer_ticket__entrypoint
  transfer_ticket__entrypoint:
    seq:
    - id: size_of_entrypoint
      type: u4
      valid:
        max: 1073741823
    - id: entrypoint
      size: size_of_entrypoint
  transfer_ticket__id_015__ptlimapt__contract_id:
    seq:
    - id: id_015__ptlimapt__contract_id_tag
      type: u1
      enum: id_015__ptlimapt__contract_id_tag
    - id: transfer_ticket__implicit__id_015__ptlimapt__contract_id
      type: transfer_ticket__implicit__public_key_hash
      if: (id_015__ptlimapt__contract_id_tag == ::id_015__ptlimapt__contract_id_tag::id_015__ptlimapt__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: transfer_ticket__originated__id_015__ptlimapt__contract_id
      type: transfer_ticket__originated__id_015__ptlimapt__contract_id
      if: (id_015__ptlimapt__contract_id_tag == id_015__ptlimapt__contract_id_tag::originated)
  transfer_ticket__originated__id_015__ptlimapt__contract_id:
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
    - id: transfer_ticket__implicit__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  transfer_ticket__ticket_ty:
    seq:
    - id: size_of_ticket_ty
      type: u4
      valid:
        max: 1073741823
    - id: ticket_ty
      size: size_of_ticket_ty
  transfer_ticket__ticket_contents:
    seq:
    - id: size_of_ticket_contents
      type: u4
      valid:
        max: 1073741823
    - id: ticket_contents
      size: size_of_ticket_contents
  transfer_ticket__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: transfer_ticket__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  tx_rollup_dispatch_tickets__id_015__ptlimapt__operation__alpha__contents:
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
    - id: size_of_tickets_info
      type: u4
      valid:
        max: 1073741823
    - id: tickets_info
      type: tx_rollup_dispatch_tickets__tickets_info_entries
      size: size_of_tickets_info
      repeat: eos
  tx_rollup_dispatch_tickets__tickets_info_entries:
    seq:
    - id: tx_rollup_dispatch_tickets__contents
      type: tx_rollup_dispatch_tickets__contents
    - id: tx_rollup_dispatch_tickets__ty
      type: tx_rollup_dispatch_tickets__ty
    - id: ticketer
      type: tx_rollup_dispatch_tickets__id_015__ptlimapt__contract_id
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
    - id: tx_rollup_dispatch_tickets__case__3__amount
      type: s8
      if: (amount_tag == ::amount_tag::amount_tag::case__3)
  tx_rollup_dispatch_tickets__id_015__ptlimapt__contract_id:
    seq:
    - id: id_015__ptlimapt__contract_id_tag
      type: u1
      enum: id_015__ptlimapt__contract_id_tag
    - id: tx_rollup_dispatch_tickets__implicit__id_015__ptlimapt__contract_id
      type: tx_rollup_dispatch_tickets__implicit__public_key_hash
      if: (id_015__ptlimapt__contract_id_tag == ::id_015__ptlimapt__contract_id_tag::id_015__ptlimapt__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: tx_rollup_dispatch_tickets__originated__id_015__ptlimapt__contract_id
      type: tx_rollup_dispatch_tickets__originated__id_015__ptlimapt__contract_id
      if: (id_015__ptlimapt__contract_id_tag == id_015__ptlimapt__contract_id_tag::originated)
  tx_rollup_dispatch_tickets__originated__id_015__ptlimapt__contract_id:
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
    - id: tx_rollup_dispatch_tickets__implicit__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  tx_rollup_dispatch_tickets__ty:
    seq:
    - id: size_of_ty
      type: u4
      valid:
        max: 1073741823
    - id: ty
      size: size_of_ty
  tx_rollup_dispatch_tickets__contents:
    seq:
    - id: size_of_contents
      type: u4
      valid:
        max: 1073741823
    - id: contents
      size: size_of_contents
  tx_rollup_dispatch_tickets__message_result_path:
    seq:
    - id: size_of_message_result_path
      type: u4
      valid:
        max: 1073741823
    - id: message_result_path
      type: tx_rollup_dispatch_tickets__message_result_path_entries
      size: size_of_message_result_path
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
    - id: tx_rollup_dispatch_tickets__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  tx_rollup_rejection__id_015__ptlimapt__operation__alpha__contents:
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
    - id: size_of_proof
      type: u4
      valid:
        max: 1073741823
    - id: proof
      size: size_of_proof
  tx_rollup_rejection__previous_message_result_path:
    seq:
    - id: size_of_previous_message_result_path
      type: u4
      valid:
        max: 1073741823
    - id: previous_message_result_path
      type: tx_rollup_rejection__previous_message_result_path_entries
      size: size_of_previous_message_result_path
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
    - id: size_of_message_result_path
      type: u4
      valid:
        max: 1073741823
    - id: message_result_path
      type: tx_rollup_rejection__message_result_path_entries
      size: size_of_message_result_path
      repeat: eos
  tx_rollup_rejection__message_result_path_entries:
    seq:
    - id: message_result_list_hash
      size: 32
  tx_rollup_rejection__message_path:
    seq:
    - id: size_of_message_path
      type: u4
      valid:
        max: 1073741823
    - id: message_path
      type: tx_rollup_rejection__message_path_entries
      size: size_of_message_path
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
    - id: tx_rollup_rejection__deposit__message
      type: tx_rollup_rejection__deposit__deposit
      if: (message_tag == ::message_tag::message_tag::deposit)
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
    - id: tx_rollup_rejection__deposit__case__3__amount
      type: s8
      if: (amount_tag == ::amount_tag::amount_tag::case__3)
  tx_rollup_rejection__deposit__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: tx_rollup_rejection__deposit__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  tx_rollup_rejection__batch__batch:
    seq:
    - id: size_of_batch
      type: u4
      valid:
        max: 1073741823
    - id: batch
      size: size_of_batch
  tx_rollup_rejection__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: tx_rollup_rejection__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  tx_rollup_remove_commitment__id_015__ptlimapt__operation__alpha__contents:
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
    - id: tx_rollup_remove_commitment__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  tx_rollup_finalize_commitment__id_015__ptlimapt__operation__alpha__contents:
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
    - id: tx_rollup_finalize_commitment__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  tx_rollup_return_bond__id_015__ptlimapt__operation__alpha__contents:
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
    - id: tx_rollup_return_bond__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  tx_rollup_commit__id_015__ptlimapt__operation__alpha__contents:
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
      if: (predecessor_tag == ::predecessor_tag::predecessor_tag::some)
  tx_rollup_commit__messages:
    seq:
    - id: size_of_messages
      type: u4
      valid:
        max: 1073741823
    - id: messages
      type: tx_rollup_commit__messages_entries
      size: size_of_messages
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
    - id: tx_rollup_commit__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  tx_rollup_submit_batch__id_015__ptlimapt__operation__alpha__contents:
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
    - id: size_of_content
      type: u4
      valid:
        max: 1073741823
    - id: content
      size: size_of_content
  tx_rollup_submit_batch__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: tx_rollup_submit_batch__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  tx_rollup_origination__id_015__ptlimapt__operation__alpha__contents:
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
    - id: tx_rollup_origination__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  register_global_constant__id_015__ptlimapt__operation__alpha__contents:
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
    - id: size_of_value
      type: u4
      valid:
        max: 1073741823
    - id: value
      size: size_of_value
  register_global_constant__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: register_global_constant__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  failing_noop__arbitrary:
    seq:
    - id: size_of_arbitrary
      type: u4
      valid:
        max: 1073741823
    - id: arbitrary
      size: size_of_arbitrary
  drain_delegate__id_015__ptlimapt__operation__alpha__contents:
    seq:
    - id: consensus_key
      type: drain_delegate__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: delegate
      type: drain_delegate__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: destination
      type: drain_delegate__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
  drain_delegate__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: drain_delegate__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  update_consensus_key__id_015__ptlimapt__operation__alpha__contents:
    seq:
    - id: source
      type: update_consensus_key__public_key_hash
      doc: A Ed25519, Secp256k1, or P256 public key hash
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
    - id: update_consensus_key__p256__public_key
      size: 33
      if: (public_key_tag == ::public_key_tag::public_key_tag::p256)
  update_consensus_key__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: update_consensus_key__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  increase_paid_storage__id_015__ptlimapt__operation__alpha__contents:
    seq:
    - id: source
      type: increase_paid_storage__public_key_hash
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
      type: increase_paid_storage__id_015__ptlimapt__contract_id__originated
      doc: ! >-
        A contract handle -- originated account: A contract notation as given to an
        RPC or inside scripts. Can be a base58 originated contract hash.
  increase_paid_storage__id_015__ptlimapt__contract_id__originated:
    seq:
    - id: id_015__ptlimapt__contract_id__originated_tag
      type: u1
      enum: id_015__ptlimapt__contract_id__originated_tag
    - id: increase_paid_storage__originated__id_015__ptlimapt__contract_id__originated
      type: increase_paid_storage__originated__id_015__ptlimapt__contract_id__originated
      if: (id_015__ptlimapt__contract_id__originated_tag == id_015__ptlimapt__contract_id__originated_tag::originated)
  increase_paid_storage__originated__id_015__ptlimapt__contract_id__originated:
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
    - id: increase_paid_storage__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  set_deposits_limit__id_015__ptlimapt__operation__alpha__contents:
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
    - id: set_deposits_limit__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  delegation__id_015__ptlimapt__operation__alpha__contents:
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
    - id: delegation__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  origination__id_015__ptlimapt__operation__alpha__contents:
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
      type: origination__id_015__ptlimapt__scripted__contracts
  origination__id_015__ptlimapt__scripted__contracts:
    seq:
    - id: origination__code
      type: origination__code
    - id: origination__storage
      type: origination__storage
  origination__storage:
    seq:
    - id: size_of_storage
      type: u4
      valid:
        max: 1073741823
    - id: storage
      size: size_of_storage
  origination__code:
    seq:
    - id: size_of_code
      type: u4
      valid:
        max: 1073741823
    - id: code
      size: size_of_code
  origination__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: origination__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  transaction__id_015__ptlimapt__operation__alpha__contents:
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
      type: transaction__id_015__ptlimapt__contract_id
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
      type: transaction__id_015__ptlimapt__entrypoint
      doc: ! 'entrypoint: Named entrypoint to a Michelson smart contract'
    - id: transaction__value
      type: transaction__value
  transaction__value:
    seq:
    - id: size_of_value
      type: u4
      valid:
        max: 1073741823
    - id: value
      size: size_of_value
  transaction__id_015__ptlimapt__entrypoint:
    seq:
    - id: id_015__ptlimapt__entrypoint_tag
      type: u1
      enum: id_015__ptlimapt__entrypoint_tag
    - id: transaction__named__id_015__ptlimapt__entrypoint
      type: transaction__named__id_015__ptlimapt__entrypoint
      if: (id_015__ptlimapt__entrypoint_tag == id_015__ptlimapt__entrypoint_tag::named)
  transaction__named__id_015__ptlimapt__entrypoint:
    seq:
    - id: size_of_named
      type: u1
      valid:
        max: 31
    - id: named
      size: size_of_named
      size-eos: true
      valid:
        max: 31
  transaction__id_015__ptlimapt__contract_id:
    seq:
    - id: id_015__ptlimapt__contract_id_tag
      type: u1
      enum: id_015__ptlimapt__contract_id_tag
    - id: transaction__implicit__id_015__ptlimapt__contract_id
      type: transaction__implicit__public_key_hash
      if: (id_015__ptlimapt__contract_id_tag == ::id_015__ptlimapt__contract_id_tag::id_015__ptlimapt__contract_id_tag::implicit)
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: transaction__originated__id_015__ptlimapt__contract_id
      type: transaction__originated__id_015__ptlimapt__contract_id
      if: (id_015__ptlimapt__contract_id_tag == id_015__ptlimapt__contract_id_tag::originated)
  transaction__originated__id_015__ptlimapt__contract_id:
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
    - id: transaction__implicit__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  transaction__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: transaction__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  reveal__id_015__ptlimapt__operation__alpha__contents:
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
    - id: reveal__p256__public_key
      size: 33
      if: (public_key_tag == ::public_key_tag::public_key_tag::p256)
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
    - id: reveal__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  ballot__id_015__ptlimapt__operation__alpha__contents:
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
    - id: ballot__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  proposals__id_015__ptlimapt__operation__alpha__contents:
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
    - id: size_of_proposals
      type: u4
      valid:
        max: 640
    - id: proposals
      type: proposals__proposals_entries
      size: size_of_proposals
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
    - id: proposals__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  activate_account__id_015__ptlimapt__operation__alpha__contents:
    seq:
    - id: pkh
      size: 20
    - id: secret
      size: 20
  double_baking_evidence__id_015__ptlimapt__operation__alpha__contents:
    seq:
    - id: double_baking_evidence__bh1
      type: double_baking_evidence__bh1
    - id: double_baking_evidence__bh2
      type: double_baking_evidence__bh2
  double_baking_evidence__bh2:
    seq:
    - id: size_of_bh2
      type: u4
      valid:
        max: 1073741823
    - id: bh2
      type: double_baking_evidence__id_015__ptlimapt__block_header__alpha__full_header
      size: size_of_bh2
  double_baking_evidence__bh1:
    seq:
    - id: size_of_bh1
      type: u4
      valid:
        max: 1073741823
    - id: bh1
      type: double_baking_evidence__id_015__ptlimapt__block_header__alpha__full_header
      size: size_of_bh1
  double_baking_evidence__id_015__ptlimapt__block_header__alpha__full_header:
    seq:
    - id: double_baking_evidence__block_header__shell
      type: double_baking_evidence__block_header__shell
      doc: ! >-
        Shell header: Block header's shell-related content. It contains information
        such as the block level, its predecessor and timestamp.
    - id: double_baking_evidence__id_015__ptlimapt__block_header__alpha__signed_contents
      type: double_baking_evidence__id_015__ptlimapt__block_header__alpha__signed_contents
  double_baking_evidence__id_015__ptlimapt__block_header__alpha__signed_contents:
    seq:
    - id: double_baking_evidence__id_015__ptlimapt__block_header__alpha__unsigned_contents
      type: double_baking_evidence__id_015__ptlimapt__block_header__alpha__unsigned_contents
    - id: signature
      size: 64
  double_baking_evidence__id_015__ptlimapt__block_header__alpha__unsigned_contents:
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
    - id: size_of_fitness
      type: u4
      valid:
        max: 1073741823
    - id: fitness
      type: double_baking_evidence__fitness_entries
      size: size_of_fitness
      repeat: eos
  double_baking_evidence__fitness_entries:
    seq:
    - id: double_baking_evidence__fitness__elem
      type: double_baking_evidence__fitness__elem
  double_baking_evidence__fitness__elem:
    seq:
    - id: size_of_fitness__elem
      type: u4
      valid:
        max: 1073741823
    - id: fitness__elem
      size: size_of_fitness__elem
  double_preendorsement_evidence__id_015__ptlimapt__operation__alpha__contents:
    seq:
    - id: double_preendorsement_evidence__op1
      type: double_preendorsement_evidence__op1
    - id: double_preendorsement_evidence__op2
      type: double_preendorsement_evidence__op2
  double_preendorsement_evidence__op2:
    seq:
    - id: size_of_op2
      type: u4
      valid:
        max: 1073741823
    - id: op2
      type: double_preendorsement_evidence__id_015__ptlimapt__inlined__preendorsement
      size: size_of_op2
  double_preendorsement_evidence__op1:
    seq:
    - id: size_of_op1
      type: u4
      valid:
        max: 1073741823
    - id: op1
      type: double_preendorsement_evidence__id_015__ptlimapt__inlined__preendorsement
      size: size_of_op1
  double_preendorsement_evidence__id_015__ptlimapt__inlined__preendorsement:
    seq:
    - id: operation__shell_header
      size: 32
      doc: An operation's shell header.
    - id: operations
      type: double_preendorsement_evidence__id_015__ptlimapt__inlined__preendorsement__contents
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size: 64
      if: (signature_tag == bool::true)
  double_preendorsement_evidence__id_015__ptlimapt__inlined__preendorsement__contents:
    seq:
    - id: id_015__ptlimapt__inlined__preendorsement__contents_tag
      type: u1
      enum: id_015__ptlimapt__inlined__preendorsement__contents_tag
    - id: double_preendorsement_evidence__preendorsement__id_015__ptlimapt__inlined__preendorsement__contents
      type: double_preendorsement_evidence__preendorsement__id_015__ptlimapt__inlined__preendorsement__contents
      if: (id_015__ptlimapt__inlined__preendorsement__contents_tag == id_015__ptlimapt__inlined__preendorsement__contents_tag::preendorsement)
  double_preendorsement_evidence__preendorsement__id_015__ptlimapt__inlined__preendorsement__contents:
    seq:
    - id: slot
      type: u2
    - id: level
      type: s4
    - id: round
      type: s4
    - id: block_payload_hash
      size: 32
  double_endorsement_evidence__id_015__ptlimapt__operation__alpha__contents:
    seq:
    - id: double_endorsement_evidence__op1
      type: double_endorsement_evidence__op1
    - id: double_endorsement_evidence__op2
      type: double_endorsement_evidence__op2
  double_endorsement_evidence__op2:
    seq:
    - id: size_of_op2
      type: u4
      valid:
        max: 1073741823
    - id: op2
      type: double_endorsement_evidence__id_015__ptlimapt__inlined__endorsement
      size: size_of_op2
  double_endorsement_evidence__op1:
    seq:
    - id: size_of_op1
      type: u4
      valid:
        max: 1073741823
    - id: op1
      type: double_endorsement_evidence__id_015__ptlimapt__inlined__endorsement
      size: size_of_op1
  double_endorsement_evidence__id_015__ptlimapt__inlined__endorsement:
    seq:
    - id: operation__shell_header
      size: 32
      doc: An operation's shell header.
    - id: operations
      type: double_endorsement_evidence__id_015__ptlimapt__inlined__endorsement_mempool__contents
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size: 64
      if: (signature_tag == bool::true)
  double_endorsement_evidence__id_015__ptlimapt__inlined__endorsement_mempool__contents:
    seq:
    - id: id_015__ptlimapt__inlined__endorsement_mempool__contents_tag
      type: u1
      enum: id_015__ptlimapt__inlined__endorsement_mempool__contents_tag
    - id: double_endorsement_evidence__endorsement__id_015__ptlimapt__inlined__endorsement_mempool__contents
      type: double_endorsement_evidence__endorsement__id_015__ptlimapt__inlined__endorsement_mempool__contents
      if: (id_015__ptlimapt__inlined__endorsement_mempool__contents_tag == id_015__ptlimapt__inlined__endorsement_mempool__contents_tag::endorsement)
  double_endorsement_evidence__endorsement__id_015__ptlimapt__inlined__endorsement_mempool__contents:
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
  seed_nonce_revelation__id_015__ptlimapt__operation__alpha__contents:
    seq:
    - id: level
      type: s4
    - id: nonce
      size: 32
  dal_slot_availability__id_015__ptlimapt__operation__alpha__contents:
    seq:
    - id: endorser
      type: dal_slot_availability__public_key_hash
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
  dal_slot_availability__public_key_hash:
    seq:
    - id: public_key_hash_tag
      type: u1
      enum: public_key_hash_tag
    - id: dal_slot_availability__p256__public_key_hash
      size: 20
      if: (public_key_hash_tag == ::public_key_hash_tag::public_key_hash_tag::p256)
  preendorsement__id_015__ptlimapt__operation__alpha__contents:
    seq:
    - id: slot
      type: u2
    - id: level
      type: s4
    - id: round
      type: s4
    - id: block_payload_hash
      size: 32
  endorsement__id_015__ptlimapt__operation__alpha__contents:
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
  zk_rollup_publish__some__prim__generic__id_015__ptlimapt__michelson__v1__primitives:
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
    129: bls12_381_g2
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
    120: never
    108: unit
    140: get_and_update
    92: key
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    107: timestamp
    52: loop
    34: ediv
    135: ticket
    146: constant
    138: split_ticket
    5: left
    51: left
    125: keccak
    101: pair
    48: int
    58: mul
    35: empty_map
    76: swap
    116: chain_id
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    66: pair
    124: total_voting_power
    80: update
    22: car
    103: signature
    61: nil
    21: balance
    97: big_map
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
    102: set
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    99: option
    123: voting_power
    98: nat
    18: add
    95: list
    75: sub
    6: none
    114: empty_big_map
    141: chest
    105: bytes
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    89: bool
    4: elt
    115: apply
    56: map
    128: bls12_381_g1
    25: compare
    20: and
    96: map
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    106: mutez
    148: tx_rollup_l2_address
    132: sapling_transaction_deprecated
    130: bls12_381_fr
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    150: sapling_transaction
    94: lambda
    54: lsr
    104: string
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    91: int
    59: neg
    100: or
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    109: operation
    93: key_hash
    47: if_none
    7: pair
    142: chest_key
    110: address
    90: contract
    13: unpack
    131: sapling_state
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  zk_rollup_publish__some__prim__2_args__some_annots__id_015__ptlimapt__michelson__v1__primitives:
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
    129: bls12_381_g2
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
    120: never
    108: unit
    140: get_and_update
    92: key
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    107: timestamp
    52: loop
    34: ediv
    135: ticket
    146: constant
    138: split_ticket
    5: left
    51: left
    125: keccak
    101: pair
    48: int
    58: mul
    35: empty_map
    76: swap
    116: chain_id
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    66: pair
    124: total_voting_power
    80: update
    22: car
    103: signature
    61: nil
    21: balance
    97: big_map
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
    102: set
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    99: option
    123: voting_power
    98: nat
    18: add
    95: list
    75: sub
    6: none
    114: empty_big_map
    141: chest
    105: bytes
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    89: bool
    4: elt
    115: apply
    56: map
    128: bls12_381_g1
    25: compare
    20: and
    96: map
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    106: mutez
    148: tx_rollup_l2_address
    132: sapling_transaction_deprecated
    130: bls12_381_fr
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    150: sapling_transaction
    94: lambda
    54: lsr
    104: string
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    91: int
    59: neg
    100: or
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    109: operation
    93: key_hash
    47: if_none
    7: pair
    142: chest_key
    110: address
    90: contract
    13: unpack
    131: sapling_state
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  zk_rollup_publish__some__prim__2_args__no_annots__id_015__ptlimapt__michelson__v1__primitives:
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
    129: bls12_381_g2
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
    120: never
    108: unit
    140: get_and_update
    92: key
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    107: timestamp
    52: loop
    34: ediv
    135: ticket
    146: constant
    138: split_ticket
    5: left
    51: left
    125: keccak
    101: pair
    48: int
    58: mul
    35: empty_map
    76: swap
    116: chain_id
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    66: pair
    124: total_voting_power
    80: update
    22: car
    103: signature
    61: nil
    21: balance
    97: big_map
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
    102: set
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    99: option
    123: voting_power
    98: nat
    18: add
    95: list
    75: sub
    6: none
    114: empty_big_map
    141: chest
    105: bytes
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    89: bool
    4: elt
    115: apply
    56: map
    128: bls12_381_g1
    25: compare
    20: and
    96: map
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    106: mutez
    148: tx_rollup_l2_address
    132: sapling_transaction_deprecated
    130: bls12_381_fr
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    150: sapling_transaction
    94: lambda
    54: lsr
    104: string
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    91: int
    59: neg
    100: or
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    109: operation
    93: key_hash
    47: if_none
    7: pair
    142: chest_key
    110: address
    90: contract
    13: unpack
    131: sapling_state
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  zk_rollup_publish__some__prim__1_arg__some_annots__id_015__ptlimapt__michelson__v1__primitives:
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
    129: bls12_381_g2
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
    120: never
    108: unit
    140: get_and_update
    92: key
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    107: timestamp
    52: loop
    34: ediv
    135: ticket
    146: constant
    138: split_ticket
    5: left
    51: left
    125: keccak
    101: pair
    48: int
    58: mul
    35: empty_map
    76: swap
    116: chain_id
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    66: pair
    124: total_voting_power
    80: update
    22: car
    103: signature
    61: nil
    21: balance
    97: big_map
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
    102: set
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    99: option
    123: voting_power
    98: nat
    18: add
    95: list
    75: sub
    6: none
    114: empty_big_map
    141: chest
    105: bytes
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    89: bool
    4: elt
    115: apply
    56: map
    128: bls12_381_g1
    25: compare
    20: and
    96: map
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    106: mutez
    148: tx_rollup_l2_address
    132: sapling_transaction_deprecated
    130: bls12_381_fr
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    150: sapling_transaction
    94: lambda
    54: lsr
    104: string
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    91: int
    59: neg
    100: or
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    109: operation
    93: key_hash
    47: if_none
    7: pair
    142: chest_key
    110: address
    90: contract
    13: unpack
    131: sapling_state
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  zk_rollup_publish__some__prim__1_arg__no_annots__id_015__ptlimapt__michelson__v1__primitives:
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
    129: bls12_381_g2
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
    120: never
    108: unit
    140: get_and_update
    92: key
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    107: timestamp
    52: loop
    34: ediv
    135: ticket
    146: constant
    138: split_ticket
    5: left
    51: left
    125: keccak
    101: pair
    48: int
    58: mul
    35: empty_map
    76: swap
    116: chain_id
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    66: pair
    124: total_voting_power
    80: update
    22: car
    103: signature
    61: nil
    21: balance
    97: big_map
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
    102: set
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    99: option
    123: voting_power
    98: nat
    18: add
    95: list
    75: sub
    6: none
    114: empty_big_map
    141: chest
    105: bytes
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    89: bool
    4: elt
    115: apply
    56: map
    128: bls12_381_g1
    25: compare
    20: and
    96: map
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    106: mutez
    148: tx_rollup_l2_address
    132: sapling_transaction_deprecated
    130: bls12_381_fr
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    150: sapling_transaction
    94: lambda
    54: lsr
    104: string
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    91: int
    59: neg
    100: or
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    109: operation
    93: key_hash
    47: if_none
    7: pair
    142: chest_key
    110: address
    90: contract
    13: unpack
    131: sapling_state
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  zk_rollup_publish__some__prim__no_args__some_annots__id_015__ptlimapt__michelson__v1__primitives:
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
    129: bls12_381_g2
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
    120: never
    108: unit
    140: get_and_update
    92: key
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    107: timestamp
    52: loop
    34: ediv
    135: ticket
    146: constant
    138: split_ticket
    5: left
    51: left
    125: keccak
    101: pair
    48: int
    58: mul
    35: empty_map
    76: swap
    116: chain_id
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    66: pair
    124: total_voting_power
    80: update
    22: car
    103: signature
    61: nil
    21: balance
    97: big_map
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
    102: set
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    99: option
    123: voting_power
    98: nat
    18: add
    95: list
    75: sub
    6: none
    114: empty_big_map
    141: chest
    105: bytes
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    89: bool
    4: elt
    115: apply
    56: map
    128: bls12_381_g1
    25: compare
    20: and
    96: map
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    106: mutez
    148: tx_rollup_l2_address
    132: sapling_transaction_deprecated
    130: bls12_381_fr
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    150: sapling_transaction
    94: lambda
    54: lsr
    104: string
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    91: int
    59: neg
    100: or
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    109: operation
    93: key_hash
    47: if_none
    7: pair
    142: chest_key
    110: address
    90: contract
    13: unpack
    131: sapling_state
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  zk_rollup_publish__some__prim__no_args__no_annots__id_015__ptlimapt__michelson__v1__primitives:
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
    129: bls12_381_g2
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
    120: never
    108: unit
    140: get_and_update
    92: key
    65: or
    149: min_block_time
    127: pairing_check
    50: le
    154: ticket
    107: timestamp
    52: loop
    34: ediv
    135: ticket
    146: constant
    138: split_ticket
    5: left
    51: left
    125: keccak
    101: pair
    48: int
    58: mul
    35: empty_map
    76: swap
    116: chain_id
    121: never
    44: if
    152: lambda_rec
    8: right
    10: true
    84: address
    153: lambda_rec
    66: pair
    124: total_voting_power
    80: update
    22: car
    103: signature
    61: nil
    21: balance
    97: big_map
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
    102: set
    71: source
    126: sha3
    12: pack
    113: dug
    53: lsl
    27: cons
    45: if_cons
    42: gt
    23: cdr
    99: option
    123: voting_power
    98: nat
    18: add
    95: list
    75: sub
    6: none
    114: empty_big_map
    141: chest
    105: bytes
    0: parameter
    9: some
    78: set_delegate
    151: emit
    79: unit
    55: lt
    30: implicit_account
    63: not
    89: bool
    4: elt
    115: apply
    56: map
    128: bls12_381_g1
    25: compare
    20: and
    96: map
    31: dip
    73: self
    74: steps_to_quota
    24: check_signature
    106: mutez
    148: tx_rollup_l2_address
    132: sapling_transaction_deprecated
    130: bls12_381_fr
    118: level
    139: join_tickets
    15: sha256
    29: create_contract
    17: abs
    150: sapling_transaction
    94: lambda
    54: lsr
    104: string
    117: chain_id
    112: dig
    86: isnat
    119: self_address
    91: int
    59: neg
    100: or
    33: dup
    19: amount
    14: blake2b
    145: view
    122: unpair
    1: storage
    109: operation
    93: key_hash
    47: if_none
    7: pair
    142: chest_key
    110: address
    90: contract
    13: unpack
    131: sapling_state
    88: rename
    133: sapling_empty_state
    3: false
    134: sapling_verify_update
    69: size
    43: hash_key
    16: sha512
  micheline__015__ptlimapt__michelson_v1__expression_tag:
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
  reveal_proof_tag:
    0: raw__data__proof
  input_proof_tag:
    0: inbox__proof
    1: reveal__proof
  inode_tree_tag:
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
    16: case__16
    17: case__17
    18: case__18
    19: case__19
    20: case__20
    21: case__21
    22: case__22
    23: case__23
    24: case__24
    25: case__25
    26: case__26
    27: case__27
    28: case__28
    29: case__29
    30: case__30
    31: case__31
    32: case__32
    33: case__33
    34: case__34
    35: case__35
    36: case__36
    37: case__37
    38: case__38
    39: case__39
    40: case__40
    41: case__41
    42: case__42
    43: case__43
    44: case__44
    45: case__45
    46: case__46
    47: case__47
    48: case__48
    49: case__49
    50: case__50
    51: case__51
    52: case__52
    53: case__53
    54: case__54
    55: case__55
    56: case__56
    57: case__57
    58: case__58
    59: case__59
    60: case__60
    61: case__61
    62: case__62
    63: case__63
    64: case__64
    65: case__65
    66: case__66
    67: case__67
    128: case__128
    129: case__129
    130: case__130
    131: case__131
    132: case__132
    133: case__133
    134: case__134
    135: case__135
    136: case__136
    137: case__137
    138: case__138
    139: case__139
    140: case__140
    141: case__141
    142: case__142
    143: case__143
    144: case__144
    145: case__145
    146: case__146
    147: case__147
    148: case__148
    149: case__149
    150: case__150
    151: case__151
    152: case__152
    153: case__153
    154: case__154
    155: case__155
    156: case__156
    157: case__157
    158: case__158
    159: case__159
    160: case__160
    161: case__161
    162: case__162
    163: case__163
    164: case__164
    165: case__165
    166: case__166
    167: case__167
    168: case__168
    169: case__169
    170: case__170
    171: case__171
    172: case__172
    173: case__173
    174: case__174
    175: case__175
    176: case__176
    177: case__177
    178: case__178
    179: case__179
    180: case__180
    181: case__181
    182: case__182
    183: case__183
    184: case__184
    185: case__185
    186: case__186
    187: case__187
    188: case__188
    189: case__189
    190: case__190
    191: case__191
    192: case__192
    208: case__208
    209: case__209
    210: case__210
    211: case__211
    224: case__224
  tree_encoding_tag:
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
    16: case__16
    17: case__17
    18: case__18
    19: case__19
    20: case__20
    21: case__21
    22: case__22
    23: case__23
    24: case__24
    25: case__25
    26: case__26
    27: case__27
    28: case__28
    29: case__29
    30: case__30
    31: case__31
    32: case__32
    33: case__33
    34: case__34
    35: case__35
    36: case__36
    37: case__37
    38: case__38
    39: case__39
    40: case__40
    41: case__41
    42: case__42
    43: case__43
    44: case__44
    45: case__45
    46: case__46
    47: case__47
    48: case__48
    49: case__49
    50: case__50
    51: case__51
    52: case__52
    53: case__53
    54: case__54
    55: case__55
    56: case__56
    57: case__57
    58: case__58
    59: case__59
    60: case__60
    61: case__61
    62: case__62
    63: case__63
    64: case__64
    65: case__65
    66: case__66
    67: case__67
    128: case__128
    129: case__129
    130: case__130
    131: case__131
    132: case__132
    133: case__133
    134: case__134
    135: case__135
    136: case__136
    137: case__137
    138: case__138
    139: case__139
    140: case__140
    141: case__141
    142: case__142
    143: case__143
    144: case__144
    145: case__145
    146: case__146
    147: case__147
    148: case__148
    149: case__149
    150: case__150
    151: case__151
    152: case__152
    153: case__153
    154: case__154
    155: case__155
    156: case__156
    157: case__157
    158: case__158
    159: case__159
    160: case__160
    161: case__161
    162: case__162
    163: case__163
    164: case__164
    165: case__165
    166: case__166
    167: case__167
    168: case__168
    169: case__169
    170: case__170
    171: case__171
    172: case__172
    173: case__173
    174: case__174
    175: case__175
    176: case__176
    177: case__177
    178: case__178
    179: case__179
    180: case__180
    181: case__181
    182: case__182
    183: case__183
    184: case__184
    185: case__185
    186: case__186
    187: case__187
    188: case__188
    189: case__189
    190: case__190
    191: case__191
    192: case__192
    193: case__193
    195: case__195
    200: case__200
    208: case__208
    216: case__216
    217: case__217
    218: case__218
    219: case__219
    224: case__224
  proof_tag:
    0: case__0
    1: case__1
    2: case__2
    3: case__3
  pvm_step_tag:
    0: arithmetic__pvm__with__proof
    1: wasm__2__0__0__pvm__with__proof
    255: unencodable
  step_tag:
    0: dissection
    1: proof
  sc_rollup_originate__pvm_kind:
    0: arith_pvm_kind
    1: wasm_2_0_0_pvm_kind
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
  id_015__ptlimapt__contract_id__originated_tag:
    1: originated
  id_015__ptlimapt__entrypoint_tag:
    0: default
    1: root
    2: do
    3: set_delegate
    4: remove_delegate
    5: deposit
    255: named
  id_015__ptlimapt__contract_id_tag:
    0: implicit
    1: originated
  public_key_tag:
    0: ed25519
    1: secp256k1
    2: p256
  id_015__ptlimapt__inlined__preendorsement__contents_tag:
    20: preendorsement
  bool:
    0: false
    255: true
  id_015__ptlimapt__inlined__endorsement_mempool__contents_tag:
    21: endorsement
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
  id_015__ptlimapt__operation__alpha__contents_tag:
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
    22: dal_slot_availability
    107: reveal
    108: transaction
    109: origination
    110: delegation
    111: register_global_constant
    112: set_deposits_limit
    113: increase_paid_storage
    114: update_consensus_key
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
    250: zk_rollup_origination
    251: zk_rollup_publish
seq:
- id: operation__shell_header
  size: 32
  doc: An operation's shell header.
- id: id_015__ptlimapt__operation__alpha__contents_and_signature
  type: id_015__ptlimapt__operation__alpha__contents_and_signature
