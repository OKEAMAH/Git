meta:
  id: id_008__ptedo2zk__lazy_storage_diff
  endian: be
doc: ! 'Encoding id: 008-PtEdo2Zk.lazy_storage_diff'
types:
  id_008__ptedo2zk__lazy_storage_diff_dyn:
    seq:
    - id: id_008__ptedo2zk__lazy_storage_diff_entries
      type: id_008__ptedo2zk__lazy_storage_diff_entries
      repeat: eos
  id_008__ptedo2zk__lazy_storage_diff_entries:
    seq:
    - id: id_008__ptedo2zk__lazy_storage_diff_elt_tag
      type: u1
      enum: id_008__ptedo2zk__lazy_storage_diff_elt_tag
    - id: big_map__id_008__ptedo2zk__lazy_storage_diff_elt
      type: big_map__id_008__ptedo2zk__lazy_storage_diff_elt
      if: (id_008__ptedo2zk__lazy_storage_diff_elt_tag == id_008__ptedo2zk__lazy_storage_diff_elt_tag::big_map)
    - id: sapling_state__id_008__ptedo2zk__lazy_storage_diff_elt
      type: sapling_state__id_008__ptedo2zk__lazy_storage_diff_elt
      if: (id_008__ptedo2zk__lazy_storage_diff_elt_tag == id_008__ptedo2zk__lazy_storage_diff_elt_tag::sapling_state)
  sapling_state__id_008__ptedo2zk__lazy_storage_diff_elt:
    seq:
    - id: id
      type: z
      doc: ! 'Sapling state identifier: A sapling state identifier'
    - id: sapling_state__diff
      type: sapling_state__diff
  sapling_state__diff:
    seq:
    - id: diff_tag
      type: u1
      enum: diff_tag
    - id: sapling_state__update__diff
      type: sapling_state__update__updates
      if: (diff_tag == diff_tag::update)
    - id: sapling_state__copy__diff
      type: sapling_state__copy__diff
      if: (diff_tag == diff_tag::copy)
    - id: sapling_state__alloc__diff
      type: sapling_state__alloc__diff
      if: (diff_tag == diff_tag::alloc)
  sapling_state__alloc__diff:
    seq:
    - id: sapling_state__alloc__updates
      type: sapling_state__alloc__updates
    - id: memo_size
      type: u2
  sapling_state__alloc__updates:
    seq:
    - id: sapling_state__alloc__commitments_and_ciphertexts
      type: sapling_state__alloc__commitments_and_ciphertexts
    - id: sapling_state__alloc__nullifiers
      type: sapling_state__alloc__nullifiers
  sapling_state__alloc__nullifiers:
    seq:
    - id: len_sapling_state__alloc__nullifiers_dyn
      type: u4
      valid:
        max: 1073741823
    - id: sapling_state__alloc__nullifiers_dyn
      type: sapling_state__alloc__nullifiers_dyn
      size: len_sapling_state__alloc__nullifiers_dyn
  sapling_state__alloc__nullifiers_dyn:
    seq:
    - id: sapling_state__alloc__nullifiers_entries
      type: sapling_state__alloc__nullifiers_entries
      repeat: eos
  sapling_state__alloc__nullifiers_entries:
    seq:
    - id: sapling__transaction__nullifier
      size: 32
  sapling_state__alloc__commitments_and_ciphertexts:
    seq:
    - id: len_sapling_state__alloc__commitments_and_ciphertexts_dyn
      type: u4
      valid:
        max: 1073741823
    - id: sapling_state__alloc__commitments_and_ciphertexts_dyn
      type: sapling_state__alloc__commitments_and_ciphertexts_dyn
      size: len_sapling_state__alloc__commitments_and_ciphertexts_dyn
  sapling_state__alloc__commitments_and_ciphertexts_dyn:
    seq:
    - id: sapling_state__alloc__commitments_and_ciphertexts_entries
      type: sapling_state__alloc__commitments_and_ciphertexts_entries
      repeat: eos
  sapling_state__alloc__commitments_and_ciphertexts_entries:
    seq:
    - id: commitments_and_ciphertexts_elt_field0
      size: 32
      doc: sapling__transaction__commitment
    - id: commitments_and_ciphertexts_elt_field1
      type: sapling_state__alloc__sapling__transaction__ciphertext_
      doc: sapling_state__alloc__sapling__transaction__ciphertext_
  sapling_state__alloc__sapling__transaction__ciphertext_:
    seq:
    - id: cv
      size: 32
    - id: epk
      size: 32
    - id: sapling_state__alloc__payload_enc
      type: sapling_state__alloc__payload_enc
    - id: nonce_enc
      size: 24
    - id: payload_out
      size: 80
    - id: nonce_out
      size: 24
  sapling_state__alloc__payload_enc:
    seq:
    - id: len_payload_enc
      type: u4
      valid:
        max: 1073741823
    - id: payload_enc
      size: len_payload_enc
  sapling_state__copy__diff:
    seq:
    - id: source
      type: z
      doc: ! 'Sapling state identifier: A sapling state identifier'
    - id: sapling_state__copy__updates
      type: sapling_state__copy__updates
  sapling_state__copy__updates:
    seq:
    - id: sapling_state__copy__commitments_and_ciphertexts
      type: sapling_state__copy__commitments_and_ciphertexts
    - id: sapling_state__copy__nullifiers
      type: sapling_state__copy__nullifiers
  sapling_state__copy__nullifiers:
    seq:
    - id: len_sapling_state__copy__nullifiers_dyn
      type: u4
      valid:
        max: 1073741823
    - id: sapling_state__copy__nullifiers_dyn
      type: sapling_state__copy__nullifiers_dyn
      size: len_sapling_state__copy__nullifiers_dyn
  sapling_state__copy__nullifiers_dyn:
    seq:
    - id: sapling_state__copy__nullifiers_entries
      type: sapling_state__copy__nullifiers_entries
      repeat: eos
  sapling_state__copy__nullifiers_entries:
    seq:
    - id: sapling__transaction__nullifier
      size: 32
  sapling_state__copy__commitments_and_ciphertexts:
    seq:
    - id: len_sapling_state__copy__commitments_and_ciphertexts_dyn
      type: u4
      valid:
        max: 1073741823
    - id: sapling_state__copy__commitments_and_ciphertexts_dyn
      type: sapling_state__copy__commitments_and_ciphertexts_dyn
      size: len_sapling_state__copy__commitments_and_ciphertexts_dyn
  sapling_state__copy__commitments_and_ciphertexts_dyn:
    seq:
    - id: sapling_state__copy__commitments_and_ciphertexts_entries
      type: sapling_state__copy__commitments_and_ciphertexts_entries
      repeat: eos
  sapling_state__copy__commitments_and_ciphertexts_entries:
    seq:
    - id: commitments_and_ciphertexts_elt_field0
      size: 32
      doc: sapling__transaction__commitment
    - id: commitments_and_ciphertexts_elt_field1
      type: sapling_state__copy__sapling__transaction__ciphertext_
      doc: sapling_state__copy__sapling__transaction__ciphertext_
  sapling_state__copy__sapling__transaction__ciphertext_:
    seq:
    - id: cv
      size: 32
    - id: epk
      size: 32
    - id: sapling_state__copy__payload_enc
      type: sapling_state__copy__payload_enc
    - id: nonce_enc
      size: 24
    - id: payload_out
      size: 80
    - id: nonce_out
      size: 24
  sapling_state__copy__payload_enc:
    seq:
    - id: len_payload_enc
      type: u4
      valid:
        max: 1073741823
    - id: payload_enc
      size: len_payload_enc
  sapling_state__update__updates:
    seq:
    - id: sapling_state__update__commitments_and_ciphertexts
      type: sapling_state__update__commitments_and_ciphertexts
    - id: sapling_state__update__nullifiers
      type: sapling_state__update__nullifiers
  sapling_state__update__nullifiers:
    seq:
    - id: len_sapling_state__update__nullifiers_dyn
      type: u4
      valid:
        max: 1073741823
    - id: sapling_state__update__nullifiers_dyn
      type: sapling_state__update__nullifiers_dyn
      size: len_sapling_state__update__nullifiers_dyn
  sapling_state__update__nullifiers_dyn:
    seq:
    - id: sapling_state__update__nullifiers_entries
      type: sapling_state__update__nullifiers_entries
      repeat: eos
  sapling_state__update__nullifiers_entries:
    seq:
    - id: sapling__transaction__nullifier
      size: 32
  sapling_state__update__commitments_and_ciphertexts:
    seq:
    - id: len_sapling_state__update__commitments_and_ciphertexts_dyn
      type: u4
      valid:
        max: 1073741823
    - id: sapling_state__update__commitments_and_ciphertexts_dyn
      type: sapling_state__update__commitments_and_ciphertexts_dyn
      size: len_sapling_state__update__commitments_and_ciphertexts_dyn
  sapling_state__update__commitments_and_ciphertexts_dyn:
    seq:
    - id: sapling_state__update__commitments_and_ciphertexts_entries
      type: sapling_state__update__commitments_and_ciphertexts_entries
      repeat: eos
  sapling_state__update__commitments_and_ciphertexts_entries:
    seq:
    - id: commitments_and_ciphertexts_elt_field0
      size: 32
      doc: sapling__transaction__commitment
    - id: commitments_and_ciphertexts_elt_field1
      type: sapling_state__update__sapling__transaction__ciphertext_
      doc: sapling_state__update__sapling__transaction__ciphertext_
  sapling_state__update__sapling__transaction__ciphertext_:
    seq:
    - id: cv
      size: 32
    - id: epk
      size: 32
    - id: sapling_state__update__payload_enc
      type: sapling_state__update__payload_enc
    - id: nonce_enc
      size: 24
    - id: payload_out
      size: 80
    - id: nonce_out
      size: 24
  sapling_state__update__payload_enc:
    seq:
    - id: len_payload_enc
      type: u4
      valid:
        max: 1073741823
    - id: payload_enc
      size: len_payload_enc
  big_map__id_008__ptedo2zk__lazy_storage_diff_elt:
    seq:
    - id: id
      type: z
      doc: ! 'Big map identifier: A big map identifier'
    - id: big_map__diff
      type: big_map__diff
  big_map__diff:
    seq:
    - id: diff_tag
      type: u1
      enum: diff_tag
    - id: big_map__update__diff
      type: big_map__update__updates
      if: (diff_tag == diff_tag::update)
    - id: big_map__copy__diff
      type: big_map__copy__diff
      if: (diff_tag == diff_tag::copy)
    - id: big_map__alloc__diff
      type: big_map__alloc__diff
      if: (diff_tag == diff_tag::alloc)
  big_map__alloc__diff:
    seq:
    - id: big_map__alloc__updates
      type: big_map__alloc__updates
    - id: key_type
      type: big_map__update__micheline__008__ptedo2zk__michelson_v1__expression
    - id: value_type
      type: big_map__update__micheline__008__ptedo2zk__michelson_v1__expression
  big_map__alloc__updates:
    seq:
    - id: len_big_map__alloc__updates_dyn
      type: u4
      valid:
        max: 1073741823
    - id: big_map__alloc__updates_dyn
      type: big_map__alloc__updates_dyn
      size: len_big_map__alloc__updates_dyn
  big_map__alloc__updates_dyn:
    seq:
    - id: big_map__alloc__updates_entries
      type: big_map__alloc__updates_entries
      repeat: eos
  big_map__alloc__updates_entries:
    seq:
    - id: key_hash
      size: 32
    - id: key
      type: big_map__update__micheline__008__ptedo2zk__michelson_v1__expression
    - id: value_tag
      type: u1
      enum: bool
    - id: value
      type: big_map__update__micheline__008__ptedo2zk__michelson_v1__expression
      if: (value_tag == bool::true)
  big_map__copy__diff:
    seq:
    - id: source
      type: z
      doc: ! 'Big map identifier: A big map identifier'
    - id: big_map__copy__updates
      type: big_map__copy__updates
  big_map__copy__updates:
    seq:
    - id: len_big_map__copy__updates_dyn
      type: u4
      valid:
        max: 1073741823
    - id: big_map__copy__updates_dyn
      type: big_map__copy__updates_dyn
      size: len_big_map__copy__updates_dyn
  big_map__copy__updates_dyn:
    seq:
    - id: big_map__copy__updates_entries
      type: big_map__copy__updates_entries
      repeat: eos
  big_map__copy__updates_entries:
    seq:
    - id: key_hash
      size: 32
    - id: key
      type: big_map__update__micheline__008__ptedo2zk__michelson_v1__expression
    - id: value_tag
      type: u1
      enum: bool
    - id: value
      type: big_map__update__micheline__008__ptedo2zk__michelson_v1__expression
      if: (value_tag == bool::true)
  big_map__update__updates:
    seq:
    - id: len_big_map__update__updates_dyn
      type: u4
      valid:
        max: 1073741823
    - id: big_map__update__updates_dyn
      type: big_map__update__updates_dyn
      size: len_big_map__update__updates_dyn
  big_map__update__updates_dyn:
    seq:
    - id: big_map__update__updates_entries
      type: big_map__update__updates_entries
      repeat: eos
  big_map__update__updates_entries:
    seq:
    - id: key_hash
      size: 32
    - id: key
      type: big_map__update__micheline__008__ptedo2zk__michelson_v1__expression
    - id: value_tag
      type: u1
      enum: bool
    - id: value
      type: big_map__update__micheline__008__ptedo2zk__michelson_v1__expression
      if: (value_tag == bool::true)
  big_map__update__micheline__008__ptedo2zk__michelson_v1__expression:
    seq:
    - id: micheline__008__ptedo2zk__michelson_v1__expression_tag
      type: u1
      enum: micheline__008__ptedo2zk__michelson_v1__expression_tag
    - id: big_map__update__int__micheline__008__ptedo2zk__michelson_v1__expression
      type: z
      if: (micheline__008__ptedo2zk__michelson_v1__expression_tag == micheline__008__ptedo2zk__michelson_v1__expression_tag::int)
    - id: big_map__update__string__micheline__008__ptedo2zk__michelson_v1__expression
      type: big_map__update__string__string
      if: (micheline__008__ptedo2zk__michelson_v1__expression_tag == micheline__008__ptedo2zk__michelson_v1__expression_tag::string)
    - id: big_map__update__sequence__micheline__008__ptedo2zk__michelson_v1__expression
      type: big_map__update__sequence__micheline__008__ptedo2zk__michelson_v1__expression
      if: (micheline__008__ptedo2zk__michelson_v1__expression_tag == micheline__008__ptedo2zk__michelson_v1__expression_tag::sequence)
    - id: big_map__update__prim__no_args__no_annots__micheline__008__ptedo2zk__michelson_v1__expression
      type: u1
      if: (micheline__008__ptedo2zk__michelson_v1__expression_tag == micheline__008__ptedo2zk__michelson_v1__expression_tag::prim__no_args__no_annots)
      enum: big_map__update__prim__no_args__no_annots__id_008__ptedo2zk__michelson__v1__primitives
    - id: big_map__update__prim__no_args__some_annots__micheline__008__ptedo2zk__michelson_v1__expression
      type: big_map__update__prim__no_args__some_annots__micheline__008__ptedo2zk__michelson_v1__expression
      if: (micheline__008__ptedo2zk__michelson_v1__expression_tag == micheline__008__ptedo2zk__michelson_v1__expression_tag::prim__no_args__some_annots)
    - id: big_map__update__prim__1_arg__no_annots__micheline__008__ptedo2zk__michelson_v1__expression
      type: big_map__update__prim__1_arg__no_annots__micheline__008__ptedo2zk__michelson_v1__expression
      if: (micheline__008__ptedo2zk__michelson_v1__expression_tag == micheline__008__ptedo2zk__michelson_v1__expression_tag::prim__1_arg__no_annots)
    - id: big_map__update__prim__1_arg__some_annots__micheline__008__ptedo2zk__michelson_v1__expression
      type: big_map__update__prim__1_arg__some_annots__micheline__008__ptedo2zk__michelson_v1__expression
      if: (micheline__008__ptedo2zk__michelson_v1__expression_tag == micheline__008__ptedo2zk__michelson_v1__expression_tag::prim__1_arg__some_annots)
    - id: big_map__update__prim__2_args__no_annots__micheline__008__ptedo2zk__michelson_v1__expression
      type: big_map__update__prim__2_args__no_annots__micheline__008__ptedo2zk__michelson_v1__expression
      if: (micheline__008__ptedo2zk__michelson_v1__expression_tag == micheline__008__ptedo2zk__michelson_v1__expression_tag::prim__2_args__no_annots)
    - id: big_map__update__prim__2_args__some_annots__micheline__008__ptedo2zk__michelson_v1__expression
      type: big_map__update__prim__2_args__some_annots__micheline__008__ptedo2zk__michelson_v1__expression
      if: (micheline__008__ptedo2zk__michelson_v1__expression_tag == micheline__008__ptedo2zk__michelson_v1__expression_tag::prim__2_args__some_annots)
    - id: big_map__update__prim__generic__micheline__008__ptedo2zk__michelson_v1__expression
      type: big_map__update__prim__generic__micheline__008__ptedo2zk__michelson_v1__expression
      if: (micheline__008__ptedo2zk__michelson_v1__expression_tag == micheline__008__ptedo2zk__michelson_v1__expression_tag::prim__generic)
    - id: big_map__update__bytes__micheline__008__ptedo2zk__michelson_v1__expression
      type: big_map__update__bytes__bytes
      if: (micheline__008__ptedo2zk__michelson_v1__expression_tag == micheline__008__ptedo2zk__michelson_v1__expression_tag::bytes)
  big_map__update__bytes__bytes:
    seq:
    - id: len_bytes
      type: u4
      valid:
        max: 1073741823
    - id: bytes
      size: len_bytes
  big_map__update__prim__generic__micheline__008__ptedo2zk__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: big_map__update__prim__generic__id_008__ptedo2zk__michelson__v1__primitives
    - id: big_map__update__prim__generic__args
      type: big_map__update__prim__generic__args
    - id: big_map__update__prim__generic__annots
      type: big_map__update__prim__generic__annots
  big_map__update__prim__generic__annots:
    seq:
    - id: len_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: len_annots
  big_map__update__prim__generic__args:
    seq:
    - id: len_big_map__update__prim__generic__args_dyn
      type: u4
      valid:
        max: 1073741823
    - id: big_map__update__prim__generic__args_dyn
      type: big_map__update__prim__generic__args_dyn
      size: len_big_map__update__prim__generic__args_dyn
  big_map__update__prim__generic__args_dyn:
    seq:
    - id: big_map__update__prim__generic__args_entries
      type: big_map__update__prim__generic__args_entries
      repeat: eos
  big_map__update__prim__generic__args_entries:
    seq:
    - id: args_elt
      type: big_map__update__micheline__008__ptedo2zk__michelson_v1__expression
  big_map__update__prim__2_args__some_annots__micheline__008__ptedo2zk__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: big_map__update__prim__2_args__some_annots__id_008__ptedo2zk__michelson__v1__primitives
    - id: arg1
      type: big_map__update__micheline__008__ptedo2zk__michelson_v1__expression
    - id: arg2
      type: big_map__update__micheline__008__ptedo2zk__michelson_v1__expression
    - id: big_map__update__prim__2_args__some_annots__annots
      type: big_map__update__prim__2_args__some_annots__annots
  big_map__update__prim__2_args__some_annots__annots:
    seq:
    - id: len_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: len_annots
  big_map__update__prim__2_args__no_annots__micheline__008__ptedo2zk__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: big_map__update__prim__2_args__no_annots__id_008__ptedo2zk__michelson__v1__primitives
    - id: arg1
      type: big_map__update__micheline__008__ptedo2zk__michelson_v1__expression
    - id: arg2
      type: big_map__update__micheline__008__ptedo2zk__michelson_v1__expression
  big_map__update__prim__1_arg__some_annots__micheline__008__ptedo2zk__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: big_map__update__prim__1_arg__some_annots__id_008__ptedo2zk__michelson__v1__primitives
    - id: arg
      type: big_map__update__micheline__008__ptedo2zk__michelson_v1__expression
    - id: big_map__update__prim__1_arg__some_annots__annots
      type: big_map__update__prim__1_arg__some_annots__annots
  big_map__update__prim__1_arg__some_annots__annots:
    seq:
    - id: len_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: len_annots
  big_map__update__prim__1_arg__no_annots__micheline__008__ptedo2zk__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: big_map__update__prim__1_arg__no_annots__id_008__ptedo2zk__michelson__v1__primitives
    - id: arg
      type: big_map__update__micheline__008__ptedo2zk__michelson_v1__expression
  big_map__update__prim__no_args__some_annots__micheline__008__ptedo2zk__michelson_v1__expression:
    seq:
    - id: prim
      type: u1
      enum: big_map__update__prim__no_args__some_annots__id_008__ptedo2zk__michelson__v1__primitives
    - id: big_map__update__prim__no_args__some_annots__annots
      type: big_map__update__prim__no_args__some_annots__annots
  big_map__update__prim__no_args__some_annots__annots:
    seq:
    - id: len_annots
      type: u4
      valid:
        max: 1073741823
    - id: annots
      size: len_annots
  big_map__update__sequence__micheline__008__ptedo2zk__michelson_v1__expression:
    seq:
    - id: len_big_map__update__sequence__sequence_dyn
      type: u4
      valid:
        max: 1073741823
    - id: big_map__update__sequence__sequence_dyn
      type: big_map__update__sequence__sequence_dyn
      size: len_big_map__update__sequence__sequence_dyn
  big_map__update__sequence__sequence_dyn:
    seq:
    - id: big_map__update__sequence__sequence_entries
      type: big_map__update__sequence__sequence_entries
      repeat: eos
  big_map__update__sequence__sequence_entries:
    seq:
    - id: sequence_elt
      type: big_map__update__micheline__008__ptedo2zk__michelson_v1__expression
  big_map__update__string__string:
    seq:
    - id: len_string
      type: u4
      valid:
        max: 1073741823
    - id: string
      size: len_string
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
enums:
  bool:
    0: false
    255: true
  big_map__update__prim__generic__id_008__ptedo2zk__michelson__v1__primitives:
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
      id: left_
      doc: Left
    6:
      id: none
      doc: None
    7:
      id: pair__
      doc: Pair
    8:
      id: right_
      doc: Right
    9:
      id: some
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
      id: left
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
      id: none_
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
      id: right
      doc: RIGHT
    69:
      id: size
      doc: SIZE
    70:
      id: some_
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
    132: sapling_transaction
    133:
      id: sapling_empty_state
      doc: SAPLING_EMPTY_STATE
    134:
      id: sapling_verify_update
      doc: SAPLING_VERIFY_UPDATE
    135: ticket
    136:
      id: ticket_
      doc: TICKET
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
  big_map__update__prim__2_args__some_annots__id_008__ptedo2zk__michelson__v1__primitives:
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
      id: left_
      doc: Left
    6:
      id: none
      doc: None
    7:
      id: pair__
      doc: Pair
    8:
      id: right_
      doc: Right
    9:
      id: some
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
      id: left
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
      id: none_
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
      id: right
      doc: RIGHT
    69:
      id: size
      doc: SIZE
    70:
      id: some_
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
    132: sapling_transaction
    133:
      id: sapling_empty_state
      doc: SAPLING_EMPTY_STATE
    134:
      id: sapling_verify_update
      doc: SAPLING_VERIFY_UPDATE
    135: ticket
    136:
      id: ticket_
      doc: TICKET
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
  big_map__update__prim__2_args__no_annots__id_008__ptedo2zk__michelson__v1__primitives:
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
      id: left_
      doc: Left
    6:
      id: none
      doc: None
    7:
      id: pair__
      doc: Pair
    8:
      id: right_
      doc: Right
    9:
      id: some
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
      id: left
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
      id: none_
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
      id: right
      doc: RIGHT
    69:
      id: size
      doc: SIZE
    70:
      id: some_
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
    132: sapling_transaction
    133:
      id: sapling_empty_state
      doc: SAPLING_EMPTY_STATE
    134:
      id: sapling_verify_update
      doc: SAPLING_VERIFY_UPDATE
    135: ticket
    136:
      id: ticket_
      doc: TICKET
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
  big_map__update__prim__1_arg__some_annots__id_008__ptedo2zk__michelson__v1__primitives:
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
      id: left_
      doc: Left
    6:
      id: none
      doc: None
    7:
      id: pair__
      doc: Pair
    8:
      id: right_
      doc: Right
    9:
      id: some
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
      id: left
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
      id: none_
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
      id: right
      doc: RIGHT
    69:
      id: size
      doc: SIZE
    70:
      id: some_
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
    132: sapling_transaction
    133:
      id: sapling_empty_state
      doc: SAPLING_EMPTY_STATE
    134:
      id: sapling_verify_update
      doc: SAPLING_VERIFY_UPDATE
    135: ticket
    136:
      id: ticket_
      doc: TICKET
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
  big_map__update__prim__1_arg__no_annots__id_008__ptedo2zk__michelson__v1__primitives:
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
      id: left_
      doc: Left
    6:
      id: none
      doc: None
    7:
      id: pair__
      doc: Pair
    8:
      id: right_
      doc: Right
    9:
      id: some
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
      id: left
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
      id: none_
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
      id: right
      doc: RIGHT
    69:
      id: size
      doc: SIZE
    70:
      id: some_
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
    132: sapling_transaction
    133:
      id: sapling_empty_state
      doc: SAPLING_EMPTY_STATE
    134:
      id: sapling_verify_update
      doc: SAPLING_VERIFY_UPDATE
    135: ticket
    136:
      id: ticket_
      doc: TICKET
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
  big_map__update__prim__no_args__some_annots__id_008__ptedo2zk__michelson__v1__primitives:
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
      id: left_
      doc: Left
    6:
      id: none
      doc: None
    7:
      id: pair__
      doc: Pair
    8:
      id: right_
      doc: Right
    9:
      id: some
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
      id: left
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
      id: none_
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
      id: right
      doc: RIGHT
    69:
      id: size
      doc: SIZE
    70:
      id: some_
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
    132: sapling_transaction
    133:
      id: sapling_empty_state
      doc: SAPLING_EMPTY_STATE
    134:
      id: sapling_verify_update
      doc: SAPLING_VERIFY_UPDATE
    135: ticket
    136:
      id: ticket_
      doc: TICKET
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
  big_map__update__prim__no_args__no_annots__id_008__ptedo2zk__michelson__v1__primitives:
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
      id: left_
      doc: Left
    6:
      id: none
      doc: None
    7:
      id: pair__
      doc: Pair
    8:
      id: right_
      doc: Right
    9:
      id: some
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
      id: left
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
      id: none_
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
      id: right
      doc: RIGHT
    69:
      id: size
      doc: SIZE
    70:
      id: some_
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
    132: sapling_transaction
    133:
      id: sapling_empty_state
      doc: SAPLING_EMPTY_STATE
    134:
      id: sapling_verify_update
      doc: SAPLING_VERIFY_UPDATE
    135: ticket
    136:
      id: ticket_
      doc: TICKET
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
  micheline__008__ptedo2zk__michelson_v1__expression_tag:
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
  diff_tag:
    0: update
    1: remove
    2: copy
    3: alloc
  id_008__ptedo2zk__lazy_storage_diff_elt_tag:
    0: big_map
    1: sapling_state
seq:
- id: len_id_008__ptedo2zk__lazy_storage_diff_dyn
  type: u4
  valid:
    max: 1073741823
- id: id_008__ptedo2zk__lazy_storage_diff_dyn
  type: id_008__ptedo2zk__lazy_storage_diff_dyn
  size: len_id_008__ptedo2zk__lazy_storage_diff_dyn
