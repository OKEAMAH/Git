meta:
  id: id_015__ptlimapt__operation__unsigned
  endian: be
  imports:
  - block_header__shell
  - operation__shell_header
doc: ! 'Encoding id: 015-PtLimaPt.operation.unsigned'
types:
  id_015__ptlimapt__operation__alpha__unsigned_operation_:
    seq:
    - id: id_015__ptlimapt__operation__alpha__unsigned_operation
      type: operation__shell_header
    - id: contents
      type: contents_entries
      repeat: eos
  contents_entries:
    seq:
    - id: id_015__ptlimapt__operation__alpha__contents_
      type: id_015__ptlimapt__operation__alpha__contents_
  id_015__ptlimapt__operation__alpha__contents_:
    seq:
    - id: id_015__ptlimapt__operation__alpha__contents_tag
      type: u1
      enum: id_015__ptlimapt__operation__alpha__contents_tag
    - id: endorsement__id_015__ptlimapt__operation__alpha__contents
      type: endorsement__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::endorsement)
    - id: preendorsement__id_015__ptlimapt__operation__alpha__contents
      type: preendorsement__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::preendorsement)
    - id: dal_slot_availability__id_015__ptlimapt__operation__alpha__contents
      type: dal_slot_availability__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::dal_slot_availability)
    - id: seed_nonce_revelation__id_015__ptlimapt__operation__alpha__contents
      type: seed_nonce_revelation__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::seed_nonce_revelation)
    - id: vdf_revelation__id_015__ptlimapt__operation__alpha__contents
      type: vdf_revelation__solution
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::vdf_revelation)
    - id: double_endorsement_evidence__id_015__ptlimapt__operation__alpha__contents
      type: double_endorsement_evidence__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::double_endorsement_evidence)
    - id: double_preendorsement_evidence__id_015__ptlimapt__operation__alpha__contents
      type: double_preendorsement_evidence__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::double_preendorsement_evidence)
    - id: double_baking_evidence__id_015__ptlimapt__operation__alpha__contents
      type: double_baking_evidence__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::double_baking_evidence)
    - id: activate_account__id_015__ptlimapt__operation__alpha__contents
      type: activate_account__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::activate_account)
    - id: proposals__id_015__ptlimapt__operation__alpha__contents
      type: proposals__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::proposals)
    - id: ballot__id_015__ptlimapt__operation__alpha__contents
      type: ballot__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::ballot)
    - id: reveal__id_015__ptlimapt__operation__alpha__contents
      type: reveal__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::reveal)
    - id: transaction__id_015__ptlimapt__operation__alpha__contents
      type: transaction__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::transaction)
    - id: origination__id_015__ptlimapt__operation__alpha__contents
      type: origination__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::origination)
    - id: delegation__id_015__ptlimapt__operation__alpha__contents
      type: delegation__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::delegation)
    - id: set_deposits_limit__id_015__ptlimapt__operation__alpha__contents
      type: set_deposits_limit__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::set_deposits_limit)
    - id: increase_paid_storage__id_015__ptlimapt__operation__alpha__contents
      type: increase_paid_storage__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::increase_paid_storage)
    - id: update_consensus_key__id_015__ptlimapt__operation__alpha__contents
      type: update_consensus_key__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::update_consensus_key)
    - id: drain_delegate__id_015__ptlimapt__operation__alpha__contents
      type: drain_delegate__id_015__ptlimapt__operation__alpha__contents
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::drain_delegate)
    - id: failing_noop__id_015__ptlimapt__operation__alpha__contents
      type: bytes_dyn_uint30
      if: (id_015__ptlimapt__operation__alpha__contents_tag == id_015__ptlimapt__operation__alpha__contents_tag::failing_noop)
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
      type: zk_rollup_publish__public_key_hash_
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
    - id: len_zk_rollup_publish__op_dyn
      type: uint30
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
      type: zk_rollup_publish__some__micheline__015__ptlimapt__michelson_v1__expression
    - id: ty
      type: zk_rollup_publish__some__micheline__015__ptlimapt__michelson_v1__expression
    - id: ticketer
      type: zk_rollup_publish__some__id_015__ptlimapt__contract_id_
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
  zk_rollup_publish__some__id_015__ptlimapt__contract_id_:
    seq:
    - id: id_015__ptlimapt__contract_id_tag
      type: u1
      enum: id_015__ptlimapt__contract_id_tag
    - id: zk_rollup_publish__some__implicit__id_015__ptlimapt__contract_id
      type: zk_rollup_publish__some__implicit__public_key_hash_
      if: (id_015__ptlimapt__contract_id_tag == id_015__ptlimapt__contract_id_tag::implicit)
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
  zk_rollup_publish__some__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: micheline__015__ptlimapt__michelson_v1__expression_tag
      type: u1
      enum: micheline__015__ptlimapt__michelson_v1__expression_tag
    - id: zk_rollup_publish__some__int__micheline__015__ptlimapt__michelson_v1__expression
      type: z
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::int)
    - id: zk_rollup_publish__some__string__micheline__015__ptlimapt__michelson_v1__expression
      type: bytes_dyn_uint30
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::string)
    - id: zk_rollup_publish__some__sequence__micheline__015__ptlimapt__michelson_v1__expression
      type: zk_rollup_publish__some__sequence__micheline__015__ptlimapt__michelson_v1__expression
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::sequence)
    - id: zk_rollup_publish__some__prim__no_args__no_annots__micheline__015__ptlimapt__michelson_v1__expression
      type: u1
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::prim__no_args__no_annots)
      enum: zk_rollup_publish__some__prim__no_args__no_annots__id_015__ptlimapt__michelson__v1__primitives
    - id: zk_rollup_publish__some__prim__no_args__some_annots__micheline__015__ptlimapt__michelson_v1__expression
      type: zk_rollup_publish__some__prim__no_args__some_annots__micheline__015__ptlimapt__michelson_v1__expression
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::prim__no_args__some_annots)
    - id: zk_rollup_publish__some__prim__1_arg__no_annots__micheline__015__ptlimapt__michelson_v1__expression
      type: zk_rollup_publish__some__prim__1_arg__no_annots__micheline__015__ptlimapt__michelson_v1__expression
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::prim__1_arg__no_annots)
    - id: zk_rollup_publish__some__prim__1_arg__some_annots__micheline__015__ptlimapt__michelson_v1__expression
      type: zk_rollup_publish__some__prim__1_arg__some_annots__micheline__015__ptlimapt__michelson_v1__expression
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::prim__1_arg__some_annots)
    - id: zk_rollup_publish__some__prim__2_args__no_annots__micheline__015__ptlimapt__michelson_v1__expression
      type: zk_rollup_publish__some__prim__2_args__no_annots__micheline__015__ptlimapt__michelson_v1__expression
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::prim__2_args__no_annots)
    - id: zk_rollup_publish__some__prim__2_args__some_annots__micheline__015__ptlimapt__michelson_v1__expression
      type: zk_rollup_publish__some__prim__2_args__some_annots__micheline__015__ptlimapt__michelson_v1__expression
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::prim__2_args__some_annots)
    - id: zk_rollup_publish__some__prim__generic__micheline__015__ptlimapt__michelson_v1__expression
      type: zk_rollup_publish__some__prim__generic__micheline__015__ptlimapt__michelson_v1__expression
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::prim__generic)
    - id: zk_rollup_publish__some__bytes__micheline__015__ptlimapt__michelson_v1__expression
      type: bytes_dyn_uint30
      if: (micheline__015__ptlimapt__michelson_v1__expression_tag == micheline__015__ptlimapt__michelson_v1__expression_tag::bytes)
  zk_rollup_publish__some__prim__generic__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__generic__id_015__ptlimapt__michelson__v1__primitives
    - id: zk_rollup_publish__some__prim__generic__args
      type: zk_rollup_publish__some__prim__generic__args
    - id: annots
      type: bytes_dyn_uint30
  zk_rollup_publish__some__prim__generic__args:
    seq:
    - id: len_zk_rollup_publish__some__prim__generic__args_dyn
      type: uint30
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
      type: zk_rollup_publish__some__micheline__015__ptlimapt__michelson_v1__expression
  zk_rollup_publish__some__prim__2_args__some_annots__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__2_args__some_annots__id_015__ptlimapt__michelson__v1__primitives
    - id: arg1
      type: zk_rollup_publish__some__micheline__015__ptlimapt__michelson_v1__expression
    - id: arg2
      type: zk_rollup_publish__some__micheline__015__ptlimapt__michelson_v1__expression
    - id: annots
      type: bytes_dyn_uint30
  zk_rollup_publish__some__prim__2_args__no_annots__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__2_args__no_annots__id_015__ptlimapt__michelson__v1__primitives
    - id: arg1
      type: zk_rollup_publish__some__micheline__015__ptlimapt__michelson_v1__expression
    - id: arg2
      type: zk_rollup_publish__some__micheline__015__ptlimapt__michelson_v1__expression
  zk_rollup_publish__some__prim__1_arg__some_annots__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__1_arg__some_annots__id_015__ptlimapt__michelson__v1__primitives
    - id: arg
      type: zk_rollup_publish__some__micheline__015__ptlimapt__michelson_v1__expression
    - id: annots
      type: bytes_dyn_uint30
  zk_rollup_publish__some__prim__1_arg__no_annots__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__1_arg__no_annots__id_015__ptlimapt__michelson__v1__primitives
    - id: arg
      type: zk_rollup_publish__some__micheline__015__ptlimapt__michelson_v1__expression
  zk_rollup_publish__some__prim__no_args__some_annots__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: zk_rollup_publish__some__prim__no_args__some_annots__id_015__ptlimapt__michelson__v1__primitives
    - id: annots
      type: bytes_dyn_uint30
  zk_rollup_publish__some__sequence__micheline__015__ptlimapt__michelson_v1__expression:
    seq:
    - id: len_zk_rollup_publish__some__sequence__sequence_dyn
      type: uint30
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
      type: zk_rollup_publish__some__micheline__015__ptlimapt__michelson_v1__expression
  zk_rollup_publish__op_elt_field0:
    seq:
    - id: op_code
      type: int31
    - id: zk_rollup_publish__price
      type: zk_rollup_publish__price
    - id: l1_dst
      type: zk_rollup_publish__public_key_hash_
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: rollup_id
      size: 20
    - id: zk_rollup_publish__payload
      type: zk_rollup_publish__payload
  zk_rollup_publish__payload:
    seq:
    - id: len_zk_rollup_publish__payload_dyn
      type: uint30
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
  zk_rollup_origination__id_015__ptlimapt__operation__alpha__contents:
    seq:
    - id: source
      type: zk_rollup_origination__public_key_hash_
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
      type: int31
  zk_rollup_origination__init_state:
    seq:
    - id: len_zk_rollup_origination__init_state_dyn
      type: uint30
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
      type: uint30
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
    - id: circuits_info_elt_field0
      type: bytes_dyn_uint30
    - id: circuits_info_elt_field1
      type: u1
      enum: bool
  zk_rollup_origination__public_parameters:
    seq:
    - id: public_parameters_field0
      type: bytes_dyn_uint30
    - id: public_parameters_field1
      type: bytes_dyn_uint30
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
  sc_rollup_dal_slot_subscribe__id_015__ptlimapt__operation__alpha__contents:
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
  sc_rollup_recover_bond__id_015__ptlimapt__operation__alpha__contents:
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
  sc_rollup_execute_outbox_message__id_015__ptlimapt__operation__alpha__contents:
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
    - id: output_proof
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
  sc_rollup_timeout__id_015__ptlimapt__operation__alpha__contents:
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
  sc_rollup_refute__id_015__ptlimapt__operation__alpha__contents:
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
    - id: refutation_tag
      type: u1
      enum: bool
    - id: sc_rollup_refute__refutation_
      type: sc_rollup_refute__refutation_
      if: (refutation_tag == bool::true)
  sc_rollup_refute__refutation_:
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
    - id: sc_rollup_refute__proof__input_proof_
      type: sc_rollup_refute__proof__input_proof_
      if: (input_proof_tag == bool::true)
  sc_rollup_refute__proof__input_proof_:
    seq:
    - id: input_proof_tag
      type: u1
      enum: input_proof_tag
    - id: sc_rollup_refute__proof__inbox__proof__input_proof
      type: sc_rollup_refute__proof__inbox__proof__input_proof
      if: (input_proof_tag == input_proof_tag::inbox__proof)
    - id: sc_rollup_refute__proof__reveal__proof__input_proof
      type: sc_rollup_refute__proof__reveal__proof__reveal_proof
      if: (input_proof_tag == input_proof_tag::reveal__proof)
  sc_rollup_refute__proof__reveal__proof__reveal_proof:
    seq:
    - id: reveal_proof_tag
      type: u1
      enum: reveal_proof_tag
    - id: sc_rollup_refute__proof__reveal__proof__raw__data__proof__reveal_proof
      type: bytes_dyn_uint30
      if: (reveal_proof_tag == reveal_proof_tag::raw__data__proof)
  sc_rollup_refute__proof__inbox__proof__input_proof:
    seq:
    - id: level
      type: s4
    - id: message_counter
      type: n
    - id: serialized_proof
      type: bytes_dyn_uint30
  sc_rollup_refute__proof__pvm_step:
    seq:
    - id: pvm_step_tag
      type: u1
      enum: pvm_step_tag
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__pvm_step
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__proof
      if: (pvm_step_tag == pvm_step_tag::arithmetic__pvm__with__proof)
    - id: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__pvm_step
      type: sc_rollup_refute__proof__wasm__2__0__0__pvm__with__proof__proof
      if: (pvm_step_tag == pvm_step_tag::wasm__2__0__0__pvm__with__proof)
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
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
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__0__tree_encoding
      type: u1
      if: (tree_encoding_tag == tree_encoding_tag::case__0)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__4)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__8__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__8__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__8)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__12__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__12__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__12)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__16__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__16__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__16)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__20__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__20__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__20)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__24__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__24__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__24)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__28__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__28__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__28)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__32__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__32__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__32)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__36__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__36__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__36)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__40__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__40__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__40)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__44__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__44__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__44)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__48__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__48__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__48)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__52__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__52__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__52)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__56__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__56__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__56)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__60__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__60__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__60)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__64__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__64__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__64)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__1__tree_encoding
      type: u2
      if: (tree_encoding_tag == tree_encoding_tag::case__1)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__5__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__5__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__5)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__9__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__9__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__9)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__13__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__13__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__13)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__17__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__17__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__17)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__21__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__21__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__21)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__25__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__25__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__25)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__29__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__29__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__29)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__33__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__33__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__33)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__37__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__37__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__37)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__41__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__41__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__41)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__45__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__45__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__45)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__49__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__49__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__49)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__53__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__53__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__53)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__57__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__57__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__57)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__61__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__61__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__61)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__65__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__65__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__65)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__2__tree_encoding
      type: s4
      if: (tree_encoding_tag == tree_encoding_tag::case__2)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__6__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__6__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__6)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__10__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__10__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__10)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__14__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__14__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__14)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__18__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__18__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__18)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__22__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__22__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__22)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__26__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__26__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__26)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__30__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__30__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__30)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__34__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__34__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__34)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__38__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__38__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__38)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__42__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__42__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__42)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__46__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__46__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__46)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__50__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__50__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__50)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__54__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__54__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__54)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__58__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__58__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__58)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__62__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__62__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__62)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__66__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__66__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__66)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__3__tree_encoding
      type: s8
      if: (tree_encoding_tag == tree_encoding_tag::case__3)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__7__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__7__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__7)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__11__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__11__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__11)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__15__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__15__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__15)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__19__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__19__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__19)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__23__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__23__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__23)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__27__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__27__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__27)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__31__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__31__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__31)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__35__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__35__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__35)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__39__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__39__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__39)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__43__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__43__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__43)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__47__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__47__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__47)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__51__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__51__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__51)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__55__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__55__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__55)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__59__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__59__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__59)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__63__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__63__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__63)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__67__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__67__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__67)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__129__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__129__case__129_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__129)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__130__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__130__case__130_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__130)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__131__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__131__case__131_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__131)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__132__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__132__case__132_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__132)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__133__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__133__case__133_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__133)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__134__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__134__case__134_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__134)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__135__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__135__case__135_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__135)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__136__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__136__case__136_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__136)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__137__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__137__case__137_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__137)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__138__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__138__case__138_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__138)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__139__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__139__case__139_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__139)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__140__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__140__case__140_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__140)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__141__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__141__case__141_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__141)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__142__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__142__case__142_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__142)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__143__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__143__case__143_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__143)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__144__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__144__case__144_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__144)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__145__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__145__case__145_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__145)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__146__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__146__case__146_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__146)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__147__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__147__case__147_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__147)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__148__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__148__case__148_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__148)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__149__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__149__case__149_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__149)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__150__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__150__case__150_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__150)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__151__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__151__case__151_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__151)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__152__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__152__case__152_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__152)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__153__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__153__case__153_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__153)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__154__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__154__case__154_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__154)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__155__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__155__case__155_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__155)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__156__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__156__case__156_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__156)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__157__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__157__case__157_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__157)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__158__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__158__case__158_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__158)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__159__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__159__case__159_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__159)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__160__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__160__case__160_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__160)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__161__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__161__case__161_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__161)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__162__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__162__case__162_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__162)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__163__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__163__case__163_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__163)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__164__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__164__case__164_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__164)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__165__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__165__case__165_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__165)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__166__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__166__case__166_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__166)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__167__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__167__case__167_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__167)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__168__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__168__case__168_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__168)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__169__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__169__case__169_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__169)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__170__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__170__case__170_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__170)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__171__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__171__case__171_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__171)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__172__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__172__case__172_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__172)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__173__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__173__case__173_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__173)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__174__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__174__case__174_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__174)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__175__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__175__case__175_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__175)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__176__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__176__case__176_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__176)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__177__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__177__case__177_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__177)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__178__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__178__case__178_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__178)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__179__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__179__case__179_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__179)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__180__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__180__case__180_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__180)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__181__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__181__case__181_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__181)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__182__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__182__case__182_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__182)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__183__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__183__case__183_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__183)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__184__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__184__case__184_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__184)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__185__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__185__case__185_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__185)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__186__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__186__case__186_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__186)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__187__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__187__case__187_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__187)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__188__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__188__case__188_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__188)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__189__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__189__case__189_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__189)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__190__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__190__case__190_entries
      if: (tree_encoding_tag == tree_encoding_tag::case__190)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__191__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__191__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__191)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__192__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__192__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__192)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__193__tree_encoding
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__193__tree_encoding
      if: (tree_encoding_tag == tree_encoding_tag::case__193)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__195__tree_encoding
      type: bytes_dyn_uint30
      if: (tree_encoding_tag == tree_encoding_tag::case__195)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__200__tree_encoding
      size: 32
      if: (tree_encoding_tag == tree_encoding_tag::case__200)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__208__tree_encoding
      size: 32
      if: (tree_encoding_tag == tree_encoding_tag::case__208)
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__219__case__219_field1:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__219__case__219_field1_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__219__case__219_field1_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__219__case__219_field1_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__219__case__219_field1_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__219__case__219_field1_dyn:
    seq:
    - id: case__219_field1
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__218__tree_encoding:
    seq:
    - id: case__218_field0
      type: s4
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__218__case__218_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__218__case__218_field1
    - id: case__218_field2
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__218__case__218_field1:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__218__case__218_field1_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__218__case__218_field1_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__218__case__218_field1_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__218__case__218_field1_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__218__case__218_field1_dyn:
    seq:
    - id: case__218_field1
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__217__tree_encoding:
    seq:
    - id: case__217_field0
      type: u2
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__217__case__217_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__217__case__217_field1
    - id: case__217_field2
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__217__case__217_field1:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__217__case__217_field1_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__217__case__217_field1_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__217__case__217_field1_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__217__case__217_field1_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__217__case__217_field1_dyn:
    seq:
    - id: case__217_field1
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__216__tree_encoding:
    seq:
    - id: case__216_field0
      type: u1
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__216__case__216_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__216__case__216_field1
    - id: case__216_field2
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__216__case__216_field1:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__216__case__216_field1_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__216__case__216_field1_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__216__case__216_field1_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__216__case__216_field1_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__216__case__216_field1_dyn:
    seq:
    - id: case__216_field1
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__193__tree_encoding:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__193__case__193_dyn
      type: u2
      valid:
        max: 65535
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__193__case__193_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__193__case__193_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__193__case__193_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__193__case__193_dyn:
    seq:
    - id: case__193
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__192__tree_encoding:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__192__case__192_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__192__case__192_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__192__case__192_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__192__case__192_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__192__case__192_dyn:
    seq:
    - id: case__192
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__191__tree_encoding:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__191__case__191_dyn
      type: uint30
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__191__case__191_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__191__case__191_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__191__case__191_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__191__case__191_dyn:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__191__case__191_entries
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__191__case__191_entries
      repeat: eos
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__191__case__191_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__191__case__191_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__191__case__191_elt_field0
    - id: case__191_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__191__case__191_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__191__case__191_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__191__case__191_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__191__case__191_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__191__case__191_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__191__case__191_elt_field0_dyn:
    seq:
    - id: case__191_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__190__case__190_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__190__case__190_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__190__case__190_elt_field0
    - id: case__190_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__190__case__190_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__190__case__190_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__190__case__190_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__190__case__190_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__190__case__190_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__190__case__190_elt_field0_dyn:
    seq:
    - id: case__190_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__189__case__189_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__189__case__189_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__189__case__189_elt_field0
    - id: case__189_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__189__case__189_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__189__case__189_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__189__case__189_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__189__case__189_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__189__case__189_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__189__case__189_elt_field0_dyn:
    seq:
    - id: case__189_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__188__case__188_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__188__case__188_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__188__case__188_elt_field0
    - id: case__188_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__188__case__188_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__188__case__188_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__188__case__188_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__188__case__188_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__188__case__188_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__188__case__188_elt_field0_dyn:
    seq:
    - id: case__188_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__187__case__187_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__187__case__187_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__187__case__187_elt_field0
    - id: case__187_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__187__case__187_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__187__case__187_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__187__case__187_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__187__case__187_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__187__case__187_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__187__case__187_elt_field0_dyn:
    seq:
    - id: case__187_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__186__case__186_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__186__case__186_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__186__case__186_elt_field0
    - id: case__186_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__186__case__186_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__186__case__186_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__186__case__186_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__186__case__186_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__186__case__186_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__186__case__186_elt_field0_dyn:
    seq:
    - id: case__186_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__185__case__185_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__185__case__185_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__185__case__185_elt_field0
    - id: case__185_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__185__case__185_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__185__case__185_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__185__case__185_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__185__case__185_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__185__case__185_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__185__case__185_elt_field0_dyn:
    seq:
    - id: case__185_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__184__case__184_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__184__case__184_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__184__case__184_elt_field0
    - id: case__184_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__184__case__184_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__184__case__184_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__184__case__184_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__184__case__184_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__184__case__184_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__184__case__184_elt_field0_dyn:
    seq:
    - id: case__184_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__183__case__183_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__183__case__183_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__183__case__183_elt_field0
    - id: case__183_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__183__case__183_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__183__case__183_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__183__case__183_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__183__case__183_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__183__case__183_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__183__case__183_elt_field0_dyn:
    seq:
    - id: case__183_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__182__case__182_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__182__case__182_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__182__case__182_elt_field0
    - id: case__182_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__182__case__182_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__182__case__182_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__182__case__182_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__182__case__182_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__182__case__182_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__182__case__182_elt_field0_dyn:
    seq:
    - id: case__182_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__181__case__181_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__181__case__181_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__181__case__181_elt_field0
    - id: case__181_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__181__case__181_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__181__case__181_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__181__case__181_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__181__case__181_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__181__case__181_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__181__case__181_elt_field0_dyn:
    seq:
    - id: case__181_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__180__case__180_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__180__case__180_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__180__case__180_elt_field0
    - id: case__180_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__180__case__180_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__180__case__180_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__180__case__180_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__180__case__180_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__180__case__180_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__180__case__180_elt_field0_dyn:
    seq:
    - id: case__180_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__179__case__179_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__179__case__179_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__179__case__179_elt_field0
    - id: case__179_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__179__case__179_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__179__case__179_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__179__case__179_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__179__case__179_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__179__case__179_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__179__case__179_elt_field0_dyn:
    seq:
    - id: case__179_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__178__case__178_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__178__case__178_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__178__case__178_elt_field0
    - id: case__178_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__178__case__178_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__178__case__178_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__178__case__178_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__178__case__178_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__178__case__178_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__178__case__178_elt_field0_dyn:
    seq:
    - id: case__178_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__177__case__177_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__177__case__177_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__177__case__177_elt_field0
    - id: case__177_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__177__case__177_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__177__case__177_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__177__case__177_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__177__case__177_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__177__case__177_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__177__case__177_elt_field0_dyn:
    seq:
    - id: case__177_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__176__case__176_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__176__case__176_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__176__case__176_elt_field0
    - id: case__176_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__176__case__176_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__176__case__176_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__176__case__176_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__176__case__176_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__176__case__176_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__176__case__176_elt_field0_dyn:
    seq:
    - id: case__176_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__175__case__175_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__175__case__175_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__175__case__175_elt_field0
    - id: case__175_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__175__case__175_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__175__case__175_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__175__case__175_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__175__case__175_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__175__case__175_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__175__case__175_elt_field0_dyn:
    seq:
    - id: case__175_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__174__case__174_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__174__case__174_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__174__case__174_elt_field0
    - id: case__174_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__174__case__174_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__174__case__174_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__174__case__174_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__174__case__174_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__174__case__174_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__174__case__174_elt_field0_dyn:
    seq:
    - id: case__174_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__173__case__173_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__173__case__173_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__173__case__173_elt_field0
    - id: case__173_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__173__case__173_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__173__case__173_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__173__case__173_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__173__case__173_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__173__case__173_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__173__case__173_elt_field0_dyn:
    seq:
    - id: case__173_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__172__case__172_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__172__case__172_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__172__case__172_elt_field0
    - id: case__172_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__172__case__172_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__172__case__172_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__172__case__172_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__172__case__172_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__172__case__172_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__172__case__172_elt_field0_dyn:
    seq:
    - id: case__172_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__171__case__171_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__171__case__171_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__171__case__171_elt_field0
    - id: case__171_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__171__case__171_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__171__case__171_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__171__case__171_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__171__case__171_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__171__case__171_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__171__case__171_elt_field0_dyn:
    seq:
    - id: case__171_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__170__case__170_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__170__case__170_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__170__case__170_elt_field0
    - id: case__170_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__170__case__170_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__170__case__170_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__170__case__170_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__170__case__170_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__170__case__170_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__170__case__170_elt_field0_dyn:
    seq:
    - id: case__170_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__169__case__169_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__169__case__169_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__169__case__169_elt_field0
    - id: case__169_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__169__case__169_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__169__case__169_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__169__case__169_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__169__case__169_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__169__case__169_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__169__case__169_elt_field0_dyn:
    seq:
    - id: case__169_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__168__case__168_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__168__case__168_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__168__case__168_elt_field0
    - id: case__168_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__168__case__168_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__168__case__168_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__168__case__168_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__168__case__168_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__168__case__168_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__168__case__168_elt_field0_dyn:
    seq:
    - id: case__168_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__167__case__167_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__167__case__167_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__167__case__167_elt_field0
    - id: case__167_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__167__case__167_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__167__case__167_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__167__case__167_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__167__case__167_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__167__case__167_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__167__case__167_elt_field0_dyn:
    seq:
    - id: case__167_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__166__case__166_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__166__case__166_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__166__case__166_elt_field0
    - id: case__166_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__166__case__166_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__166__case__166_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__166__case__166_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__166__case__166_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__166__case__166_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__166__case__166_elt_field0_dyn:
    seq:
    - id: case__166_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__165__case__165_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__165__case__165_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__165__case__165_elt_field0
    - id: case__165_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__165__case__165_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__165__case__165_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__165__case__165_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__165__case__165_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__165__case__165_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__165__case__165_elt_field0_dyn:
    seq:
    - id: case__165_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__164__case__164_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__164__case__164_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__164__case__164_elt_field0
    - id: case__164_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__164__case__164_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__164__case__164_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__164__case__164_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__164__case__164_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__164__case__164_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__164__case__164_elt_field0_dyn:
    seq:
    - id: case__164_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__163__case__163_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__163__case__163_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__163__case__163_elt_field0
    - id: case__163_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__163__case__163_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__163__case__163_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__163__case__163_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__163__case__163_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__163__case__163_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__163__case__163_elt_field0_dyn:
    seq:
    - id: case__163_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__162__case__162_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__162__case__162_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__162__case__162_elt_field0
    - id: case__162_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__162__case__162_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__162__case__162_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__162__case__162_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__162__case__162_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__162__case__162_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__162__case__162_elt_field0_dyn:
    seq:
    - id: case__162_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__161__case__161_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__161__case__161_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__161__case__161_elt_field0
    - id: case__161_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__161__case__161_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__161__case__161_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__161__case__161_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__161__case__161_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__161__case__161_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__161__case__161_elt_field0_dyn:
    seq:
    - id: case__161_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__160__case__160_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__160__case__160_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__160__case__160_elt_field0
    - id: case__160_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__160__case__160_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__160__case__160_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__160__case__160_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__160__case__160_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__160__case__160_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__160__case__160_elt_field0_dyn:
    seq:
    - id: case__160_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__159__case__159_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__159__case__159_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__159__case__159_elt_field0
    - id: case__159_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__159__case__159_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__159__case__159_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__159__case__159_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__159__case__159_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__159__case__159_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__159__case__159_elt_field0_dyn:
    seq:
    - id: case__159_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__158__case__158_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__158__case__158_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__158__case__158_elt_field0
    - id: case__158_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__158__case__158_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__158__case__158_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__158__case__158_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__158__case__158_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__158__case__158_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__158__case__158_elt_field0_dyn:
    seq:
    - id: case__158_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__157__case__157_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__157__case__157_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__157__case__157_elt_field0
    - id: case__157_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__157__case__157_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__157__case__157_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__157__case__157_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__157__case__157_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__157__case__157_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__157__case__157_elt_field0_dyn:
    seq:
    - id: case__157_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__156__case__156_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__156__case__156_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__156__case__156_elt_field0
    - id: case__156_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__156__case__156_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__156__case__156_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__156__case__156_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__156__case__156_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__156__case__156_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__156__case__156_elt_field0_dyn:
    seq:
    - id: case__156_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__155__case__155_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__155__case__155_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__155__case__155_elt_field0
    - id: case__155_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__155__case__155_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__155__case__155_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__155__case__155_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__155__case__155_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__155__case__155_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__155__case__155_elt_field0_dyn:
    seq:
    - id: case__155_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__154__case__154_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__154__case__154_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__154__case__154_elt_field0
    - id: case__154_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__154__case__154_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__154__case__154_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__154__case__154_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__154__case__154_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__154__case__154_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__154__case__154_elt_field0_dyn:
    seq:
    - id: case__154_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__153__case__153_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__153__case__153_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__153__case__153_elt_field0
    - id: case__153_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__153__case__153_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__153__case__153_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__153__case__153_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__153__case__153_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__153__case__153_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__153__case__153_elt_field0_dyn:
    seq:
    - id: case__153_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__152__case__152_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__152__case__152_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__152__case__152_elt_field0
    - id: case__152_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__152__case__152_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__152__case__152_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__152__case__152_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__152__case__152_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__152__case__152_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__152__case__152_elt_field0_dyn:
    seq:
    - id: case__152_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__151__case__151_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__151__case__151_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__151__case__151_elt_field0
    - id: case__151_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__151__case__151_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__151__case__151_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__151__case__151_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__151__case__151_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__151__case__151_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__151__case__151_elt_field0_dyn:
    seq:
    - id: case__151_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__150__case__150_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__150__case__150_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__150__case__150_elt_field0
    - id: case__150_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__150__case__150_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__150__case__150_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__150__case__150_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__150__case__150_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__150__case__150_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__150__case__150_elt_field0_dyn:
    seq:
    - id: case__150_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__149__case__149_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__149__case__149_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__149__case__149_elt_field0
    - id: case__149_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__149__case__149_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__149__case__149_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__149__case__149_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__149__case__149_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__149__case__149_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__149__case__149_elt_field0_dyn:
    seq:
    - id: case__149_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__148__case__148_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__148__case__148_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__148__case__148_elt_field0
    - id: case__148_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__148__case__148_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__148__case__148_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__148__case__148_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__148__case__148_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__148__case__148_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__148__case__148_elt_field0_dyn:
    seq:
    - id: case__148_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__147__case__147_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__147__case__147_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__147__case__147_elt_field0
    - id: case__147_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__147__case__147_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__147__case__147_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__147__case__147_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__147__case__147_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__147__case__147_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__147__case__147_elt_field0_dyn:
    seq:
    - id: case__147_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__146__case__146_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__146__case__146_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__146__case__146_elt_field0
    - id: case__146_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__146__case__146_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__146__case__146_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__146__case__146_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__146__case__146_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__146__case__146_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__146__case__146_elt_field0_dyn:
    seq:
    - id: case__146_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__145__case__145_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__145__case__145_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__145__case__145_elt_field0
    - id: case__145_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__145__case__145_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__145__case__145_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__145__case__145_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__145__case__145_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__145__case__145_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__145__case__145_elt_field0_dyn:
    seq:
    - id: case__145_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__144__case__144_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__144__case__144_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__144__case__144_elt_field0
    - id: case__144_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__144__case__144_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__144__case__144_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__144__case__144_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__144__case__144_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__144__case__144_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__144__case__144_elt_field0_dyn:
    seq:
    - id: case__144_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__143__case__143_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__143__case__143_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__143__case__143_elt_field0
    - id: case__143_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__143__case__143_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__143__case__143_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__143__case__143_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__143__case__143_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__143__case__143_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__143__case__143_elt_field0_dyn:
    seq:
    - id: case__143_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__142__case__142_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__142__case__142_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__142__case__142_elt_field0
    - id: case__142_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__142__case__142_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__142__case__142_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__142__case__142_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__142__case__142_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__142__case__142_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__142__case__142_elt_field0_dyn:
    seq:
    - id: case__142_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__141__case__141_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__141__case__141_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__141__case__141_elt_field0
    - id: case__141_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__141__case__141_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__141__case__141_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__141__case__141_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__141__case__141_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__141__case__141_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__141__case__141_elt_field0_dyn:
    seq:
    - id: case__141_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__140__case__140_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__140__case__140_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__140__case__140_elt_field0
    - id: case__140_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__140__case__140_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__140__case__140_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__140__case__140_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__140__case__140_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__140__case__140_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__140__case__140_elt_field0_dyn:
    seq:
    - id: case__140_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__139__case__139_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__139__case__139_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__139__case__139_elt_field0
    - id: case__139_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__139__case__139_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__139__case__139_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__139__case__139_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__139__case__139_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__139__case__139_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__139__case__139_elt_field0_dyn:
    seq:
    - id: case__139_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__138__case__138_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__138__case__138_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__138__case__138_elt_field0
    - id: case__138_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__138__case__138_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__138__case__138_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__138__case__138_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__138__case__138_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__138__case__138_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__138__case__138_elt_field0_dyn:
    seq:
    - id: case__138_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__137__case__137_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__137__case__137_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__137__case__137_elt_field0
    - id: case__137_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__137__case__137_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__137__case__137_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__137__case__137_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__137__case__137_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__137__case__137_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__137__case__137_elt_field0_dyn:
    seq:
    - id: case__137_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__136__case__136_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__136__case__136_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__136__case__136_elt_field0
    - id: case__136_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__136__case__136_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__136__case__136_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__136__case__136_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__136__case__136_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__136__case__136_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__136__case__136_elt_field0_dyn:
    seq:
    - id: case__136_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__135__case__135_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__135__case__135_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__135__case__135_elt_field0
    - id: case__135_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__135__case__135_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__135__case__135_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__135__case__135_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__135__case__135_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__135__case__135_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__135__case__135_elt_field0_dyn:
    seq:
    - id: case__135_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__134__case__134_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__134__case__134_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__134__case__134_elt_field0
    - id: case__134_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__134__case__134_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__134__case__134_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__134__case__134_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__134__case__134_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__134__case__134_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__134__case__134_elt_field0_dyn:
    seq:
    - id: case__134_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__133__case__133_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__133__case__133_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__133__case__133_elt_field0
    - id: case__133_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__133__case__133_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__133__case__133_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__133__case__133_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__133__case__133_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__133__case__133_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__133__case__133_elt_field0_dyn:
    seq:
    - id: case__133_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__132__case__132_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__132__case__132_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__132__case__132_elt_field0
    - id: case__132_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__132__case__132_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__132__case__132_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__132__case__132_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__132__case__132_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__132__case__132_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__132__case__132_elt_field0_dyn:
    seq:
    - id: case__132_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__131__case__131_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__131__case__131_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__131__case__131_elt_field0
    - id: case__131_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__131__case__131_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__131__case__131_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__131__case__131_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__131__case__131_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__131__case__131_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__131__case__131_elt_field0_dyn:
    seq:
    - id: case__131_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__130__case__130_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__130__case__130_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__130__case__130_elt_field0
    - id: case__130_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__130__case__130_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__130__case__130_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__130__case__130_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__130__case__130_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__130__case__130_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__130__case__130_elt_field0_dyn:
    seq:
    - id: case__130_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__129__case__129_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__129__case__129_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__129__case__129_elt_field0
    - id: case__129_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__129__case__129_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__129__case__129_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__129__case__129_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__129__case__129_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__129__case__129_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__129__case__129_elt_field0_dyn:
    seq:
    - id: case__129_elt_field0
      size-eos: true
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__63__tree_encoding:
    seq:
    - id: case__63_field0
      type: s8
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__63__case__63_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__63__case__63_field1
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__63__case__63_field1:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__63__case__63_field1_dyn
      type: uint30
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__63__case__63_field1_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__63__case__63_field1_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__63__case__63_field1_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__63__case__63_field1_dyn:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__63__case__63_field1_entries
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__63__case__63_field1_entries
      repeat: eos
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__63__case__63_field1_entries:
    seq:
    - id: case__63_field1_elt_field0
      type: u1
    - id: case__63_field1_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__62__tree_encoding:
    seq:
    - id: case__62_field0
      type: s4
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__62__case__62_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__62__case__62_field1
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__62__case__62_field1:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__62__case__62_field1_dyn
      type: uint30
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__62__case__62_field1_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__62__case__62_field1_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__62__case__62_field1_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__62__case__62_field1_dyn:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__62__case__62_field1_entries
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__62__case__62_field1_entries
      repeat: eos
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__62__case__62_field1_entries:
    seq:
    - id: case__62_field1_elt_field0
      type: u1
    - id: case__62_field1_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__61__tree_encoding:
    seq:
    - id: case__61_field0
      type: u2
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__61__case__61_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__61__case__61_field1
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__61__case__61_field1:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__61__case__61_field1_dyn
      type: uint30
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__61__case__61_field1_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__61__case__61_field1_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__61__case__61_field1_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__61__case__61_field1_dyn:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__61__case__61_field1_entries
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__61__case__61_field1_entries
      repeat: eos
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__61__case__61_field1_entries:
    seq:
    - id: case__61_field1_elt_field0
      type: u1
    - id: case__61_field1_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__60__tree_encoding:
    seq:
    - id: case__60_field0
      type: u1
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__60__case__60_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__60__case__60_field1
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__60__case__60_field1:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__60__case__60_field1_dyn
      type: uint30
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__60__case__60_field1_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__60__case__60_field1_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__60__case__60_field1_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__60__case__60_field1_dyn:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__60__case__60_field1_entries
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__60__case__60_field1_entries
      repeat: eos
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__60__case__60_field1_entries:
    seq:
    - id: case__60_field1_elt_field0
      type: u1
    - id: case__60_field1_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__0__inode_tree
      type: u1
      if: (inode_tree_tag == inode_tree_tag::case__0)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__4__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__4__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__4)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__8__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__8__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__8)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__12__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__12__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__12)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__16__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__16__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__16)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__20__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__20__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__20)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__24__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__24__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__24)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__28__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__28__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__28)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__32__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__32__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__32)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__36__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__36__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__36)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__40__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__40__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__40)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__44__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__44__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__44)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__48__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__48__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__48)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__52__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__52__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__52)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__56__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__56__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__56)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__60__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__60__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__60)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__64__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__64__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__64)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__1__inode_tree
      type: u2
      if: (inode_tree_tag == inode_tree_tag::case__1)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__5__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__5__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__5)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__9__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__9__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__9)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__13__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__13__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__13)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__17__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__17__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__17)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__21__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__21__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__21)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__25__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__25__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__25)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__29__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__29__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__29)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__33__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__33__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__33)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__37__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__37__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__37)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__41__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__41__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__41)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__45__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__45__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__45)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__49__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__49__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__49)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__53__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__53__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__53)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__57__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__57__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__57)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__61__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__61__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__61)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__65__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__65__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__65)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__2__inode_tree
      type: s4
      if: (inode_tree_tag == inode_tree_tag::case__2)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__6__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__6__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__6)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__10__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__10__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__10)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__14__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__14__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__14)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__18__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__18__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__18)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__22__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__22__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__22)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__26__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__26__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__26)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__30__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__30__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__30)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__34__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__34__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__34)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__38__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__38__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__38)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__42__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__42__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__42)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__46__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__46__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__46)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__50__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__50__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__50)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__54__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__54__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__54)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__58__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__58__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__58)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__62__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__62__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__62)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__66__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__66__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__66)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__3__inode_tree
      type: s8
      if: (inode_tree_tag == inode_tree_tag::case__3)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__7__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__7__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__7)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__11__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__11__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__11)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__15__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__15__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__15)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__19__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__19__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__19)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__23__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__23__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__23)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__27__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__27__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__27)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__31__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__31__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__31)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__35__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__35__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__35)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__39__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__39__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__39)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__43__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__43__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__43)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__47__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__47__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__47)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__51__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__51__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__51)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__55__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__55__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__55)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__59__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__59__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__59)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__63__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__63__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__63)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__67__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__67__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__67)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__129__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__129__case__129_entries
      if: (inode_tree_tag == inode_tree_tag::case__129)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__130__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__130__case__130_entries
      if: (inode_tree_tag == inode_tree_tag::case__130)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__131__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__131__case__131_entries
      if: (inode_tree_tag == inode_tree_tag::case__131)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__132__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__132__case__132_entries
      if: (inode_tree_tag == inode_tree_tag::case__132)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__133__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__133__case__133_entries
      if: (inode_tree_tag == inode_tree_tag::case__133)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__134__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__134__case__134_entries
      if: (inode_tree_tag == inode_tree_tag::case__134)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__135__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__135__case__135_entries
      if: (inode_tree_tag == inode_tree_tag::case__135)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__136__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__136__case__136_entries
      if: (inode_tree_tag == inode_tree_tag::case__136)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__137__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__137__case__137_entries
      if: (inode_tree_tag == inode_tree_tag::case__137)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__138__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__138__case__138_entries
      if: (inode_tree_tag == inode_tree_tag::case__138)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__139__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__139__case__139_entries
      if: (inode_tree_tag == inode_tree_tag::case__139)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__140__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__140__case__140_entries
      if: (inode_tree_tag == inode_tree_tag::case__140)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__141__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__141__case__141_entries
      if: (inode_tree_tag == inode_tree_tag::case__141)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__142__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__142__case__142_entries
      if: (inode_tree_tag == inode_tree_tag::case__142)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__143__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__143__case__143_entries
      if: (inode_tree_tag == inode_tree_tag::case__143)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__144__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__144__case__144_entries
      if: (inode_tree_tag == inode_tree_tag::case__144)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__145__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__145__case__145_entries
      if: (inode_tree_tag == inode_tree_tag::case__145)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__146__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__146__case__146_entries
      if: (inode_tree_tag == inode_tree_tag::case__146)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__147__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__147__case__147_entries
      if: (inode_tree_tag == inode_tree_tag::case__147)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__148__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__148__case__148_entries
      if: (inode_tree_tag == inode_tree_tag::case__148)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__149__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__149__case__149_entries
      if: (inode_tree_tag == inode_tree_tag::case__149)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__150__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__150__case__150_entries
      if: (inode_tree_tag == inode_tree_tag::case__150)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__151__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__151__case__151_entries
      if: (inode_tree_tag == inode_tree_tag::case__151)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__152__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__152__case__152_entries
      if: (inode_tree_tag == inode_tree_tag::case__152)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__153__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__153__case__153_entries
      if: (inode_tree_tag == inode_tree_tag::case__153)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__154__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__154__case__154_entries
      if: (inode_tree_tag == inode_tree_tag::case__154)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__155__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__155__case__155_entries
      if: (inode_tree_tag == inode_tree_tag::case__155)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__156__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__156__case__156_entries
      if: (inode_tree_tag == inode_tree_tag::case__156)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__157__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__157__case__157_entries
      if: (inode_tree_tag == inode_tree_tag::case__157)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__158__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__158__case__158_entries
      if: (inode_tree_tag == inode_tree_tag::case__158)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__159__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__159__case__159_entries
      if: (inode_tree_tag == inode_tree_tag::case__159)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__160__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__160__case__160_entries
      if: (inode_tree_tag == inode_tree_tag::case__160)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__161__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__161__case__161_entries
      if: (inode_tree_tag == inode_tree_tag::case__161)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__162__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__162__case__162_entries
      if: (inode_tree_tag == inode_tree_tag::case__162)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__163__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__163__case__163_entries
      if: (inode_tree_tag == inode_tree_tag::case__163)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__164__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__164__case__164_entries
      if: (inode_tree_tag == inode_tree_tag::case__164)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__165__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__165__case__165_entries
      if: (inode_tree_tag == inode_tree_tag::case__165)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__166__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__166__case__166_entries
      if: (inode_tree_tag == inode_tree_tag::case__166)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__167__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__167__case__167_entries
      if: (inode_tree_tag == inode_tree_tag::case__167)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__168__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__168__case__168_entries
      if: (inode_tree_tag == inode_tree_tag::case__168)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__169__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__169__case__169_entries
      if: (inode_tree_tag == inode_tree_tag::case__169)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__170__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__170__case__170_entries
      if: (inode_tree_tag == inode_tree_tag::case__170)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__171__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__171__case__171_entries
      if: (inode_tree_tag == inode_tree_tag::case__171)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__172__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__172__case__172_entries
      if: (inode_tree_tag == inode_tree_tag::case__172)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__173__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__173__case__173_entries
      if: (inode_tree_tag == inode_tree_tag::case__173)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__174__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__174__case__174_entries
      if: (inode_tree_tag == inode_tree_tag::case__174)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__175__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__175__case__175_entries
      if: (inode_tree_tag == inode_tree_tag::case__175)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__176__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__176__case__176_entries
      if: (inode_tree_tag == inode_tree_tag::case__176)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__177__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__177__case__177_entries
      if: (inode_tree_tag == inode_tree_tag::case__177)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__178__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__178__case__178_entries
      if: (inode_tree_tag == inode_tree_tag::case__178)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__179__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__179__case__179_entries
      if: (inode_tree_tag == inode_tree_tag::case__179)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__180__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__180__case__180_entries
      if: (inode_tree_tag == inode_tree_tag::case__180)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__181__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__181__case__181_entries
      if: (inode_tree_tag == inode_tree_tag::case__181)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__182__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__182__case__182_entries
      if: (inode_tree_tag == inode_tree_tag::case__182)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__183__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__183__case__183_entries
      if: (inode_tree_tag == inode_tree_tag::case__183)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__184__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__184__case__184_entries
      if: (inode_tree_tag == inode_tree_tag::case__184)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__185__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__185__case__185_entries
      if: (inode_tree_tag == inode_tree_tag::case__185)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__186__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__186__case__186_entries
      if: (inode_tree_tag == inode_tree_tag::case__186)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__187__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__187__case__187_entries
      if: (inode_tree_tag == inode_tree_tag::case__187)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__188__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__188__case__188_entries
      if: (inode_tree_tag == inode_tree_tag::case__188)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__189__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__189__case__189_entries
      if: (inode_tree_tag == inode_tree_tag::case__189)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__190__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__190__case__190_entries
      if: (inode_tree_tag == inode_tree_tag::case__190)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__191__inode_tree
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__191__inode_tree
      if: (inode_tree_tag == inode_tree_tag::case__191)
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__192__inode_tree
      size: 32
      if: (inode_tree_tag == inode_tree_tag::case__192)
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__211__case__211_field1:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__211__case__211_field1_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__211__case__211_field1_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__211__case__211_field1_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__211__case__211_field1_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__211__case__211_field1_dyn:
    seq:
    - id: case__211_field1
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__210__inode_tree:
    seq:
    - id: case__210_field0
      type: s4
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__210__case__210_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__210__case__210_field1
    - id: case__210_field2
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__210__case__210_field1:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__210__case__210_field1_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__210__case__210_field1_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__210__case__210_field1_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__210__case__210_field1_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__210__case__210_field1_dyn:
    seq:
    - id: case__210_field1
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__209__inode_tree:
    seq:
    - id: case__209_field0
      type: u2
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__209__case__209_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__209__case__209_field1
    - id: case__209_field2
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__209__case__209_field1:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__209__case__209_field1_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__209__case__209_field1_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__209__case__209_field1_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__209__case__209_field1_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__209__case__209_field1_dyn:
    seq:
    - id: case__209_field1
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__208__inode_tree:
    seq:
    - id: case__208_field0
      type: u1
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__208__case__208_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__208__case__208_field1
    - id: case__208_field2
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__208__case__208_field1:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__208__case__208_field1_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__208__case__208_field1_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__208__case__208_field1_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__208__case__208_field1_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__208__case__208_field1_dyn:
    seq:
    - id: case__208_field1
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__191__inode_tree:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__191__case__191_dyn
      type: uint30
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__191__case__191_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__191__case__191_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__191__case__191_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__191__case__191_dyn:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__191__case__191_entries
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__191__case__191_entries
      repeat: eos
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__191__case__191_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__191__case__191_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__191__case__191_elt_field0
    - id: case__191_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__191__case__191_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__191__case__191_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__191__case__191_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__191__case__191_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__191__case__191_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__191__case__191_elt_field0_dyn:
    seq:
    - id: case__191_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__190__case__190_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__190__case__190_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__190__case__190_elt_field0
    - id: case__190_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__190__case__190_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__190__case__190_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__190__case__190_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__190__case__190_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__190__case__190_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__190__case__190_elt_field0_dyn:
    seq:
    - id: case__190_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__189__case__189_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__189__case__189_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__189__case__189_elt_field0
    - id: case__189_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__189__case__189_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__189__case__189_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__189__case__189_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__189__case__189_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__189__case__189_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__189__case__189_elt_field0_dyn:
    seq:
    - id: case__189_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__188__case__188_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__188__case__188_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__188__case__188_elt_field0
    - id: case__188_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__188__case__188_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__188__case__188_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__188__case__188_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__188__case__188_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__188__case__188_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__188__case__188_elt_field0_dyn:
    seq:
    - id: case__188_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__187__case__187_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__187__case__187_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__187__case__187_elt_field0
    - id: case__187_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__187__case__187_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__187__case__187_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__187__case__187_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__187__case__187_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__187__case__187_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__187__case__187_elt_field0_dyn:
    seq:
    - id: case__187_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__186__case__186_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__186__case__186_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__186__case__186_elt_field0
    - id: case__186_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__186__case__186_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__186__case__186_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__186__case__186_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__186__case__186_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__186__case__186_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__186__case__186_elt_field0_dyn:
    seq:
    - id: case__186_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__185__case__185_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__185__case__185_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__185__case__185_elt_field0
    - id: case__185_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__185__case__185_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__185__case__185_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__185__case__185_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__185__case__185_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__185__case__185_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__185__case__185_elt_field0_dyn:
    seq:
    - id: case__185_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__184__case__184_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__184__case__184_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__184__case__184_elt_field0
    - id: case__184_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__184__case__184_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__184__case__184_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__184__case__184_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__184__case__184_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__184__case__184_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__184__case__184_elt_field0_dyn:
    seq:
    - id: case__184_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__183__case__183_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__183__case__183_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__183__case__183_elt_field0
    - id: case__183_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__183__case__183_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__183__case__183_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__183__case__183_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__183__case__183_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__183__case__183_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__183__case__183_elt_field0_dyn:
    seq:
    - id: case__183_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__182__case__182_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__182__case__182_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__182__case__182_elt_field0
    - id: case__182_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__182__case__182_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__182__case__182_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__182__case__182_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__182__case__182_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__182__case__182_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__182__case__182_elt_field0_dyn:
    seq:
    - id: case__182_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__181__case__181_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__181__case__181_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__181__case__181_elt_field0
    - id: case__181_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__181__case__181_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__181__case__181_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__181__case__181_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__181__case__181_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__181__case__181_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__181__case__181_elt_field0_dyn:
    seq:
    - id: case__181_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__180__case__180_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__180__case__180_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__180__case__180_elt_field0
    - id: case__180_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__180__case__180_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__180__case__180_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__180__case__180_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__180__case__180_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__180__case__180_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__180__case__180_elt_field0_dyn:
    seq:
    - id: case__180_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__179__case__179_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__179__case__179_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__179__case__179_elt_field0
    - id: case__179_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__179__case__179_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__179__case__179_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__179__case__179_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__179__case__179_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__179__case__179_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__179__case__179_elt_field0_dyn:
    seq:
    - id: case__179_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__178__case__178_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__178__case__178_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__178__case__178_elt_field0
    - id: case__178_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__178__case__178_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__178__case__178_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__178__case__178_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__178__case__178_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__178__case__178_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__178__case__178_elt_field0_dyn:
    seq:
    - id: case__178_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__177__case__177_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__177__case__177_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__177__case__177_elt_field0
    - id: case__177_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__177__case__177_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__177__case__177_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__177__case__177_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__177__case__177_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__177__case__177_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__177__case__177_elt_field0_dyn:
    seq:
    - id: case__177_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__176__case__176_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__176__case__176_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__176__case__176_elt_field0
    - id: case__176_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__176__case__176_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__176__case__176_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__176__case__176_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__176__case__176_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__176__case__176_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__176__case__176_elt_field0_dyn:
    seq:
    - id: case__176_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__175__case__175_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__175__case__175_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__175__case__175_elt_field0
    - id: case__175_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__175__case__175_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__175__case__175_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__175__case__175_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__175__case__175_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__175__case__175_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__175__case__175_elt_field0_dyn:
    seq:
    - id: case__175_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__174__case__174_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__174__case__174_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__174__case__174_elt_field0
    - id: case__174_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__174__case__174_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__174__case__174_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__174__case__174_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__174__case__174_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__174__case__174_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__174__case__174_elt_field0_dyn:
    seq:
    - id: case__174_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__173__case__173_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__173__case__173_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__173__case__173_elt_field0
    - id: case__173_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__173__case__173_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__173__case__173_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__173__case__173_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__173__case__173_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__173__case__173_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__173__case__173_elt_field0_dyn:
    seq:
    - id: case__173_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__172__case__172_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__172__case__172_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__172__case__172_elt_field0
    - id: case__172_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__172__case__172_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__172__case__172_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__172__case__172_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__172__case__172_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__172__case__172_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__172__case__172_elt_field0_dyn:
    seq:
    - id: case__172_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__171__case__171_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__171__case__171_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__171__case__171_elt_field0
    - id: case__171_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__171__case__171_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__171__case__171_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__171__case__171_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__171__case__171_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__171__case__171_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__171__case__171_elt_field0_dyn:
    seq:
    - id: case__171_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__170__case__170_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__170__case__170_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__170__case__170_elt_field0
    - id: case__170_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__170__case__170_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__170__case__170_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__170__case__170_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__170__case__170_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__170__case__170_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__170__case__170_elt_field0_dyn:
    seq:
    - id: case__170_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__169__case__169_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__169__case__169_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__169__case__169_elt_field0
    - id: case__169_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__169__case__169_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__169__case__169_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__169__case__169_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__169__case__169_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__169__case__169_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__169__case__169_elt_field0_dyn:
    seq:
    - id: case__169_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__168__case__168_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__168__case__168_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__168__case__168_elt_field0
    - id: case__168_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__168__case__168_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__168__case__168_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__168__case__168_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__168__case__168_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__168__case__168_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__168__case__168_elt_field0_dyn:
    seq:
    - id: case__168_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__167__case__167_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__167__case__167_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__167__case__167_elt_field0
    - id: case__167_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__167__case__167_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__167__case__167_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__167__case__167_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__167__case__167_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__167__case__167_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__167__case__167_elt_field0_dyn:
    seq:
    - id: case__167_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__166__case__166_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__166__case__166_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__166__case__166_elt_field0
    - id: case__166_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__166__case__166_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__166__case__166_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__166__case__166_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__166__case__166_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__166__case__166_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__166__case__166_elt_field0_dyn:
    seq:
    - id: case__166_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__165__case__165_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__165__case__165_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__165__case__165_elt_field0
    - id: case__165_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__165__case__165_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__165__case__165_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__165__case__165_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__165__case__165_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__165__case__165_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__165__case__165_elt_field0_dyn:
    seq:
    - id: case__165_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__164__case__164_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__164__case__164_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__164__case__164_elt_field0
    - id: case__164_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__164__case__164_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__164__case__164_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__164__case__164_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__164__case__164_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__164__case__164_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__164__case__164_elt_field0_dyn:
    seq:
    - id: case__164_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__163__case__163_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__163__case__163_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__163__case__163_elt_field0
    - id: case__163_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__163__case__163_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__163__case__163_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__163__case__163_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__163__case__163_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__163__case__163_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__163__case__163_elt_field0_dyn:
    seq:
    - id: case__163_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__162__case__162_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__162__case__162_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__162__case__162_elt_field0
    - id: case__162_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__162__case__162_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__162__case__162_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__162__case__162_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__162__case__162_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__162__case__162_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__162__case__162_elt_field0_dyn:
    seq:
    - id: case__162_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__161__case__161_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__161__case__161_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__161__case__161_elt_field0
    - id: case__161_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__161__case__161_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__161__case__161_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__161__case__161_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__161__case__161_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__161__case__161_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__161__case__161_elt_field0_dyn:
    seq:
    - id: case__161_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__160__case__160_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__160__case__160_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__160__case__160_elt_field0
    - id: case__160_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__160__case__160_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__160__case__160_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__160__case__160_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__160__case__160_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__160__case__160_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__160__case__160_elt_field0_dyn:
    seq:
    - id: case__160_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__159__case__159_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__159__case__159_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__159__case__159_elt_field0
    - id: case__159_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__159__case__159_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__159__case__159_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__159__case__159_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__159__case__159_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__159__case__159_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__159__case__159_elt_field0_dyn:
    seq:
    - id: case__159_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__158__case__158_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__158__case__158_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__158__case__158_elt_field0
    - id: case__158_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__158__case__158_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__158__case__158_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__158__case__158_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__158__case__158_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__158__case__158_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__158__case__158_elt_field0_dyn:
    seq:
    - id: case__158_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__157__case__157_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__157__case__157_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__157__case__157_elt_field0
    - id: case__157_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__157__case__157_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__157__case__157_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__157__case__157_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__157__case__157_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__157__case__157_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__157__case__157_elt_field0_dyn:
    seq:
    - id: case__157_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__156__case__156_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__156__case__156_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__156__case__156_elt_field0
    - id: case__156_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__156__case__156_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__156__case__156_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__156__case__156_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__156__case__156_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__156__case__156_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__156__case__156_elt_field0_dyn:
    seq:
    - id: case__156_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__155__case__155_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__155__case__155_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__155__case__155_elt_field0
    - id: case__155_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__155__case__155_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__155__case__155_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__155__case__155_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__155__case__155_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__155__case__155_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__155__case__155_elt_field0_dyn:
    seq:
    - id: case__155_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__154__case__154_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__154__case__154_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__154__case__154_elt_field0
    - id: case__154_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__154__case__154_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__154__case__154_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__154__case__154_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__154__case__154_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__154__case__154_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__154__case__154_elt_field0_dyn:
    seq:
    - id: case__154_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__153__case__153_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__153__case__153_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__153__case__153_elt_field0
    - id: case__153_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__153__case__153_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__153__case__153_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__153__case__153_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__153__case__153_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__153__case__153_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__153__case__153_elt_field0_dyn:
    seq:
    - id: case__153_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__152__case__152_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__152__case__152_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__152__case__152_elt_field0
    - id: case__152_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__152__case__152_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__152__case__152_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__152__case__152_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__152__case__152_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__152__case__152_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__152__case__152_elt_field0_dyn:
    seq:
    - id: case__152_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__151__case__151_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__151__case__151_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__151__case__151_elt_field0
    - id: case__151_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__151__case__151_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__151__case__151_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__151__case__151_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__151__case__151_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__151__case__151_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__151__case__151_elt_field0_dyn:
    seq:
    - id: case__151_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__150__case__150_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__150__case__150_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__150__case__150_elt_field0
    - id: case__150_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__150__case__150_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__150__case__150_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__150__case__150_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__150__case__150_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__150__case__150_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__150__case__150_elt_field0_dyn:
    seq:
    - id: case__150_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__149__case__149_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__149__case__149_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__149__case__149_elt_field0
    - id: case__149_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__149__case__149_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__149__case__149_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__149__case__149_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__149__case__149_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__149__case__149_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__149__case__149_elt_field0_dyn:
    seq:
    - id: case__149_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__148__case__148_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__148__case__148_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__148__case__148_elt_field0
    - id: case__148_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__148__case__148_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__148__case__148_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__148__case__148_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__148__case__148_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__148__case__148_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__148__case__148_elt_field0_dyn:
    seq:
    - id: case__148_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__147__case__147_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__147__case__147_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__147__case__147_elt_field0
    - id: case__147_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__147__case__147_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__147__case__147_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__147__case__147_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__147__case__147_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__147__case__147_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__147__case__147_elt_field0_dyn:
    seq:
    - id: case__147_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__146__case__146_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__146__case__146_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__146__case__146_elt_field0
    - id: case__146_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__146__case__146_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__146__case__146_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__146__case__146_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__146__case__146_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__146__case__146_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__146__case__146_elt_field0_dyn:
    seq:
    - id: case__146_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__145__case__145_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__145__case__145_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__145__case__145_elt_field0
    - id: case__145_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__145__case__145_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__145__case__145_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__145__case__145_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__145__case__145_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__145__case__145_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__145__case__145_elt_field0_dyn:
    seq:
    - id: case__145_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__144__case__144_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__144__case__144_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__144__case__144_elt_field0
    - id: case__144_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__144__case__144_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__144__case__144_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__144__case__144_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__144__case__144_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__144__case__144_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__144__case__144_elt_field0_dyn:
    seq:
    - id: case__144_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__143__case__143_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__143__case__143_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__143__case__143_elt_field0
    - id: case__143_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__143__case__143_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__143__case__143_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__143__case__143_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__143__case__143_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__143__case__143_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__143__case__143_elt_field0_dyn:
    seq:
    - id: case__143_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__142__case__142_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__142__case__142_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__142__case__142_elt_field0
    - id: case__142_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__142__case__142_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__142__case__142_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__142__case__142_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__142__case__142_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__142__case__142_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__142__case__142_elt_field0_dyn:
    seq:
    - id: case__142_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__141__case__141_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__141__case__141_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__141__case__141_elt_field0
    - id: case__141_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__141__case__141_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__141__case__141_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__141__case__141_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__141__case__141_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__141__case__141_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__141__case__141_elt_field0_dyn:
    seq:
    - id: case__141_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__140__case__140_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__140__case__140_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__140__case__140_elt_field0
    - id: case__140_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__140__case__140_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__140__case__140_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__140__case__140_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__140__case__140_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__140__case__140_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__140__case__140_elt_field0_dyn:
    seq:
    - id: case__140_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__139__case__139_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__139__case__139_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__139__case__139_elt_field0
    - id: case__139_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__139__case__139_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__139__case__139_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__139__case__139_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__139__case__139_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__139__case__139_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__139__case__139_elt_field0_dyn:
    seq:
    - id: case__139_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__138__case__138_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__138__case__138_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__138__case__138_elt_field0
    - id: case__138_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__138__case__138_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__138__case__138_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__138__case__138_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__138__case__138_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__138__case__138_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__138__case__138_elt_field0_dyn:
    seq:
    - id: case__138_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__137__case__137_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__137__case__137_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__137__case__137_elt_field0
    - id: case__137_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__137__case__137_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__137__case__137_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__137__case__137_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__137__case__137_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__137__case__137_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__137__case__137_elt_field0_dyn:
    seq:
    - id: case__137_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__136__case__136_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__136__case__136_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__136__case__136_elt_field0
    - id: case__136_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__136__case__136_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__136__case__136_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__136__case__136_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__136__case__136_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__136__case__136_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__136__case__136_elt_field0_dyn:
    seq:
    - id: case__136_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__135__case__135_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__135__case__135_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__135__case__135_elt_field0
    - id: case__135_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__135__case__135_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__135__case__135_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__135__case__135_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__135__case__135_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__135__case__135_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__135__case__135_elt_field0_dyn:
    seq:
    - id: case__135_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__134__case__134_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__134__case__134_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__134__case__134_elt_field0
    - id: case__134_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__134__case__134_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__134__case__134_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__134__case__134_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__134__case__134_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__134__case__134_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__134__case__134_elt_field0_dyn:
    seq:
    - id: case__134_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__133__case__133_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__133__case__133_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__133__case__133_elt_field0
    - id: case__133_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__133__case__133_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__133__case__133_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__133__case__133_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__133__case__133_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__133__case__133_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__133__case__133_elt_field0_dyn:
    seq:
    - id: case__133_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__132__case__132_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__132__case__132_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__132__case__132_elt_field0
    - id: case__132_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__132__case__132_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__132__case__132_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__132__case__132_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__132__case__132_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__132__case__132_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__132__case__132_elt_field0_dyn:
    seq:
    - id: case__132_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__131__case__131_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__131__case__131_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__131__case__131_elt_field0
    - id: case__131_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__131__case__131_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__131__case__131_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__131__case__131_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__131__case__131_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__131__case__131_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__131__case__131_elt_field0_dyn:
    seq:
    - id: case__131_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__130__case__130_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__130__case__130_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__130__case__130_elt_field0
    - id: case__130_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__130__case__130_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__130__case__130_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__130__case__130_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__130__case__130_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__130__case__130_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__130__case__130_elt_field0_dyn:
    seq:
    - id: case__130_elt_field0
      size-eos: true
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__129__case__129_entries:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__129__case__129_elt_field0
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__129__case__129_elt_field0
    - id: case__129_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__tree_encoding
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__129__case__129_elt_field0:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__129__case__129_elt_field0_dyn
      type: u1
      valid:
        max: 255
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__129__case__129_elt_field0_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__129__case__129_elt_field0_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__129__case__129_elt_field0_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__129__case__129_elt_field0_dyn:
    seq:
    - id: case__129_elt_field0
      size-eos: true
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__63__inode_tree:
    seq:
    - id: case__63_field0
      type: s8
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__63__case__63_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__63__case__63_field1
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__63__case__63_field1:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__63__case__63_field1_dyn
      type: uint30
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__63__case__63_field1_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__63__case__63_field1_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__63__case__63_field1_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__63__case__63_field1_dyn:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__63__case__63_field1_entries
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__63__case__63_field1_entries
      repeat: eos
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__63__case__63_field1_entries:
    seq:
    - id: case__63_field1_elt_field0
      type: u1
    - id: case__63_field1_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__62__inode_tree:
    seq:
    - id: case__62_field0
      type: s4
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__62__case__62_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__62__case__62_field1
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__62__case__62_field1:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__62__case__62_field1_dyn
      type: uint30
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__62__case__62_field1_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__62__case__62_field1_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__62__case__62_field1_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__62__case__62_field1_dyn:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__62__case__62_field1_entries
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__62__case__62_field1_entries
      repeat: eos
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__62__case__62_field1_entries:
    seq:
    - id: case__62_field1_elt_field0
      type: u1
    - id: case__62_field1_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__61__inode_tree:
    seq:
    - id: case__61_field0
      type: u2
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__61__case__61_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__61__case__61_field1
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__61__case__61_field1:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__61__case__61_field1_dyn
      type: uint30
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__61__case__61_field1_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__61__case__61_field1_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__61__case__61_field1_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__61__case__61_field1_dyn:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__61__case__61_field1_entries
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__61__case__61_field1_entries
      repeat: eos
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__61__case__61_field1_entries:
    seq:
    - id: case__61_field1_elt_field0
      type: u1
    - id: case__61_field1_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__60__inode_tree:
    seq:
    - id: case__60_field0
      type: u1
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__60__case__60_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__60__case__60_field1
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__60__case__60_field1:
    seq:
    - id: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__60__case__60_field1_dyn
      type: uint30
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__60__case__60_field1_dyn
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__60__case__60_field1_dyn
      size: len_sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__60__case__60_field1_dyn
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__60__case__60_field1_dyn:
    seq:
    - id: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__60__case__60_field1_entries
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__60__case__60_field1_entries
      repeat: eos
  sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__case__60__case__60_field1_entries:
    seq:
    - id: case__60_field1_elt_field0
      type: u1
    - id: case__60_field1_elt_field1
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
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
      type: sc_rollup_refute__proof__arithmetic__pvm__with__proof__case__0__case__4__inode_tree
  sc_rollup_refute__dissection__step:
    seq:
    - id: len_sc_rollup_refute__dissection__dissection_dyn
      type: uint30
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
    - id: state_tag
      type: u1
      enum: bool
    - id: state
      size: 32
      if: (state_tag == bool::true)
    - id: tick
      type: n
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
  sc_rollup_publish__id_015__ptlimapt__operation__alpha__contents:
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
    - id: number_of_ticks
      type: s8
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
  sc_rollup_cement__id_015__ptlimapt__operation__alpha__contents:
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
  sc_rollup_add_messages__id_015__ptlimapt__operation__alpha__contents:
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
      type: uint30
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
  sc_rollup_originate__id_015__ptlimapt__operation__alpha__contents:
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
    - id: pvm_kind
      type: u1
      enum: sc_rollup_originate__pvm_kind
    - id: boot_sector
      type: bytes_dyn_uint30
    - id: origination_proof
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
  dal_publish_slot_header__id_015__ptlimapt__operation__alpha__contents:
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
  transfer_ticket__id_015__ptlimapt__operation__alpha__contents:
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
      type: transfer_ticket__id_015__ptlimapt__contract_id_
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: ticket_amount
      type: n
    - id: destination
      type: transfer_ticket__id_015__ptlimapt__contract_id_
      doc: ! >-
        A contract handle: A contract notation as given to an RPC or inside scripts.
        Can be a base58 implicit contract hash or a base58 originated contract hash.
    - id: entrypoint
      type: bytes_dyn_uint30
  transfer_ticket__id_015__ptlimapt__contract_id_:
    seq:
    - id: id_015__ptlimapt__contract_id_tag
      type: u1
      enum: id_015__ptlimapt__contract_id_tag
    - id: transfer_ticket__implicit__id_015__ptlimapt__contract_id
      type: transfer_ticket__implicit__public_key_hash_
      if: (id_015__ptlimapt__contract_id_tag == id_015__ptlimapt__contract_id_tag::implicit)
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
  tx_rollup_dispatch_tickets__id_015__ptlimapt__operation__alpha__contents:
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
      type: uint30
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
      type: tx_rollup_dispatch_tickets__id_015__ptlimapt__contract_id_
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
  tx_rollup_dispatch_tickets__id_015__ptlimapt__contract_id_:
    seq:
    - id: id_015__ptlimapt__contract_id_tag
      type: u1
      enum: id_015__ptlimapt__contract_id_tag
    - id: tx_rollup_dispatch_tickets__implicit__id_015__ptlimapt__contract_id
      type: tx_rollup_dispatch_tickets__implicit__public_key_hash_
      if: (id_015__ptlimapt__contract_id_tag == id_015__ptlimapt__contract_id_tag::implicit)
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
      type: uint30
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
  tx_rollup_rejection__id_015__ptlimapt__operation__alpha__contents:
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
    - id: proof
      type: bytes_dyn_uint30
  tx_rollup_rejection__previous_message_result_path:
    seq:
    - id: len_tx_rollup_rejection__previous_message_result_path_dyn
      type: uint30
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
      type: uint30
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
      type: uint30
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
  tx_rollup_remove_commitment__id_015__ptlimapt__operation__alpha__contents:
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
  tx_rollup_finalize_commitment__id_015__ptlimapt__operation__alpha__contents:
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
  tx_rollup_return_bond__id_015__ptlimapt__operation__alpha__contents:
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
  tx_rollup_commit__id_015__ptlimapt__operation__alpha__contents:
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
      type: uint30
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
  tx_rollup_submit_batch__id_015__ptlimapt__operation__alpha__contents:
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
  tx_rollup_origination__id_015__ptlimapt__operation__alpha__contents:
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
  register_global_constant__id_015__ptlimapt__operation__alpha__contents:
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
  drain_delegate__id_015__ptlimapt__operation__alpha__contents:
    seq:
    - id: consensus_key
      type: drain_delegate__public_key_hash_
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: delegate
      type: drain_delegate__public_key_hash_
      doc: A Ed25519, Secp256k1, or P256 public key hash
    - id: destination
      type: drain_delegate__public_key_hash_
      doc: A Ed25519, Secp256k1, or P256 public key hash
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
  update_consensus_key__id_015__ptlimapt__operation__alpha__contents:
    seq:
    - id: source
      type: update_consensus_key__public_key_hash_
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
  increase_paid_storage__id_015__ptlimapt__operation__alpha__contents:
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
      type: increase_paid_storage__id_015__ptlimapt__contract_id__originated_
      doc: ! >-
        A contract handle -- originated account: A contract notation as given to an
        RPC or inside scripts. Can be a base58 originated contract hash.
  increase_paid_storage__id_015__ptlimapt__contract_id__originated_:
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
  set_deposits_limit__id_015__ptlimapt__operation__alpha__contents:
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
  delegation__id_015__ptlimapt__operation__alpha__contents:
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
  origination__id_015__ptlimapt__operation__alpha__contents:
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
      type: origination__id_015__ptlimapt__scripted__contracts_
  origination__id_015__ptlimapt__scripted__contracts_:
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
  transaction__id_015__ptlimapt__operation__alpha__contents:
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
      type: transaction__id_015__ptlimapt__contract_id_
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
      type: transaction__id_015__ptlimapt__entrypoint_
      doc: ! 'entrypoint: Named entrypoint to a Michelson smart contract'
    - id: value
      type: bytes_dyn_uint30
  bytes_dyn_uint30:
    seq:
    - id: len_bytes_dyn_uint30
      type: uint30
    - id: bytes_dyn_uint30
      size: len_bytes_dyn_uint30
  transaction__id_015__ptlimapt__entrypoint_:
    seq:
    - id: id_015__ptlimapt__entrypoint_tag
      type: u1
      enum: id_015__ptlimapt__entrypoint_tag
    - id: transaction__named__id_015__ptlimapt__entrypoint
      type: transaction__named__id_015__ptlimapt__entrypoint
      if: (id_015__ptlimapt__entrypoint_tag == id_015__ptlimapt__entrypoint_tag::named)
  transaction__named__id_015__ptlimapt__entrypoint:
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
  transaction__id_015__ptlimapt__contract_id_:
    seq:
    - id: id_015__ptlimapt__contract_id_tag
      type: u1
      enum: id_015__ptlimapt__contract_id_tag
    - id: transaction__implicit__id_015__ptlimapt__contract_id
      type: transaction__implicit__public_key_hash_
      if: (id_015__ptlimapt__contract_id_tag == id_015__ptlimapt__contract_id_tag::implicit)
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
  reveal__id_015__ptlimapt__operation__alpha__contents:
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
  ballot__id_015__ptlimapt__operation__alpha__contents:
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
  proposals__id_015__ptlimapt__operation__alpha__contents:
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
      type: uint30
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
    - id: len_double_baking_evidence__bh2_dyn
      type: uint30
    - id: double_baking_evidence__bh2_dyn
      type: double_baking_evidence__bh2_dyn
      size: len_double_baking_evidence__bh2_dyn
  double_baking_evidence__bh2_dyn:
    seq:
    - id: double_baking_evidence__id_015__ptlimapt__block_header__alpha__full_header_
      type: double_baking_evidence__id_015__ptlimapt__block_header__alpha__full_header_
  double_baking_evidence__bh1:
    seq:
    - id: len_double_baking_evidence__bh1_dyn
      type: uint30
    - id: double_baking_evidence__bh1_dyn
      type: double_baking_evidence__bh1_dyn
      size: len_double_baking_evidence__bh1_dyn
  double_baking_evidence__bh1_dyn:
    seq:
    - id: double_baking_evidence__id_015__ptlimapt__block_header__alpha__full_header_
      type: double_baking_evidence__id_015__ptlimapt__block_header__alpha__full_header_
  double_baking_evidence__id_015__ptlimapt__block_header__alpha__full_header_:
    seq:
    - id: id_015__ptlimapt__block_header__alpha__full_header
      type: block_header__shell
    - id: double_baking_evidence__id_015__ptlimapt__block_header__alpha__signed_contents_
      type: double_baking_evidence__id_015__ptlimapt__block_header__alpha__signed_contents_
  double_baking_evidence__id_015__ptlimapt__block_header__alpha__signed_contents_:
    seq:
    - id: double_baking_evidence__id_015__ptlimapt__block_header__alpha__unsigned_contents_
      type: double_baking_evidence__id_015__ptlimapt__block_header__alpha__unsigned_contents_
    - id: signature
      size: 64
  double_baking_evidence__id_015__ptlimapt__block_header__alpha__unsigned_contents_:
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
  double_preendorsement_evidence__id_015__ptlimapt__operation__alpha__contents:
    seq:
    - id: double_preendorsement_evidence__op1
      type: double_preendorsement_evidence__op1
    - id: double_preendorsement_evidence__op2
      type: double_preendorsement_evidence__op2
  double_preendorsement_evidence__op2:
    seq:
    - id: len_double_preendorsement_evidence__op2_dyn
      type: uint30
    - id: double_preendorsement_evidence__op2_dyn
      type: double_preendorsement_evidence__op2_dyn
      size: len_double_preendorsement_evidence__op2_dyn
  double_preendorsement_evidence__op2_dyn:
    seq:
    - id: double_preendorsement_evidence__id_015__ptlimapt__inlined__preendorsement_
      type: double_preendorsement_evidence__id_015__ptlimapt__inlined__preendorsement_
  double_preendorsement_evidence__op1:
    seq:
    - id: len_double_preendorsement_evidence__op1_dyn
      type: uint30
    - id: double_preendorsement_evidence__op1_dyn
      type: double_preendorsement_evidence__op1_dyn
      size: len_double_preendorsement_evidence__op1_dyn
  double_preendorsement_evidence__op1_dyn:
    seq:
    - id: double_preendorsement_evidence__id_015__ptlimapt__inlined__preendorsement_
      type: double_preendorsement_evidence__id_015__ptlimapt__inlined__preendorsement_
  double_preendorsement_evidence__id_015__ptlimapt__inlined__preendorsement_:
    seq:
    - id: id_015__ptlimapt__inlined__preendorsement
      type: operation__shell_header
    - id: operations
      type: double_preendorsement_evidence__id_015__ptlimapt__inlined__preendorsement__contents_
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size: 64
      if: (signature_tag == bool::true)
  double_preendorsement_evidence__id_015__ptlimapt__inlined__preendorsement__contents_:
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
    - id: len_double_endorsement_evidence__op2_dyn
      type: uint30
    - id: double_endorsement_evidence__op2_dyn
      type: double_endorsement_evidence__op2_dyn
      size: len_double_endorsement_evidence__op2_dyn
  double_endorsement_evidence__op2_dyn:
    seq:
    - id: double_endorsement_evidence__id_015__ptlimapt__inlined__endorsement_
      type: double_endorsement_evidence__id_015__ptlimapt__inlined__endorsement_
  double_endorsement_evidence__op1:
    seq:
    - id: len_double_endorsement_evidence__op1_dyn
      type: uint30
    - id: double_endorsement_evidence__op1_dyn
      type: double_endorsement_evidence__op1_dyn
      size: len_double_endorsement_evidence__op1_dyn
  double_endorsement_evidence__op1_dyn:
    seq:
    - id: double_endorsement_evidence__id_015__ptlimapt__inlined__endorsement_
      type: double_endorsement_evidence__id_015__ptlimapt__inlined__endorsement_
  double_endorsement_evidence__id_015__ptlimapt__inlined__endorsement_:
    seq:
    - id: id_015__ptlimapt__inlined__endorsement
      type: operation__shell_header
    - id: operations
      type: double_endorsement_evidence__id_015__ptlimapt__inlined__endorsement_mempool__contents_
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size: 64
      if: (signature_tag == bool::true)
  double_endorsement_evidence__id_015__ptlimapt__inlined__endorsement_mempool__contents_:
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
  uint30:
    seq:
    - id: uint30
      type: u4
      valid:
        max: 1073741823
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
  zk_rollup_publish__some__prim__2_args__some_annots__id_015__ptlimapt__michelson__v1__primitives:
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
  zk_rollup_publish__some__prim__2_args__no_annots__id_015__ptlimapt__michelson__v1__primitives:
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
  zk_rollup_publish__some__prim__1_arg__some_annots__id_015__ptlimapt__michelson__v1__primitives:
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
  zk_rollup_publish__some__prim__1_arg__no_annots__id_015__ptlimapt__michelson__v1__primitives:
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
  zk_rollup_publish__some__prim__no_args__some_annots__id_015__ptlimapt__michelson__v1__primitives:
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
  zk_rollup_publish__some__prim__no_args__no_annots__id_015__ptlimapt__michelson__v1__primitives:
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
- id: id_015__ptlimapt__operation__alpha__unsigned_operation_
  type: id_015__ptlimapt__operation__alpha__unsigned_operation_
