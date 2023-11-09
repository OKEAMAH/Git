meta:
  id: id_013__ptjakart__operation__contents
  endian: be
doc: ! 'Encoding id: 013-PtJakart.operation.contents'
types:
  activate_account:
    seq:
    - id: pkh
      size: 20
    - id: secret
      size: 20
  amount:
    seq:
    - id: amount_tag
      type: u1
      enum: amount_tag
    - id: case__0
      type: u1
      if: (amount_tag == amount_tag::case__0)
    - id: case__1
      type: u2
      if: (amount_tag == amount_tag::case__1)
    - id: case__2
      type: s4
      if: (amount_tag == amount_tag::case__2)
    - id: case__3
      type: s8
      if: (amount_tag == amount_tag::case__3)
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
    - id: period
      type: s4
    - id: proposal
      size: 32
    - id: ballot
      type: s1
  batch:
    seq:
    - id: len_batch
      type: s4
    - id: batch
      size: len_batch
  bh1:
    seq:
    - id: len_bh1
      type: s4
    - id: bh1
      type: id_013__ptjakart__block_header__alpha__full_header
      size: len_bh1
  bh2:
    seq:
    - id: len_bh2
      type: s4
    - id: bh2
      type: id_013__ptjakart__block_header__alpha__full_header
      size: len_bh2
  boot_sector:
    seq:
    - id: len_boot_sector
      type: s4
    - id: boot_sector
      size: len_boot_sector
  case__0:
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
      type: case__0_field3
  case__0_field3:
    seq:
    - id: len_case__0_field3
      type: s4
    - id: case__0_field3
      type: case__0_field3_entries
      size: len_case__0_field3
      repeat: eos
  case__0_field3_entries:
    seq:
    - id: case__0_field3_elt_tag
      type: u1
      enum: case__0_field3_elt_tag
    - id: case__0
      type: u1
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__0)
    - id: case__8
      type: case__8
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__8)
    - id: case__4
      type: case__4
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__4)
    - id: case__12
      type: case__12
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__12)
    - id: case__1
      type: u2
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__1)
    - id: case__9
      type: case__9
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__9)
    - id: case__5
      type: case__5
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__5)
    - id: case__13
      type: case__13
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__13)
    - id: case__2
      type: s4
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__2)
    - id: case__10
      type: case__10
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__10)
    - id: case__6
      type: case__6
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__6)
    - id: case__14
      type: case__14
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__14)
    - id: case__3
      type: s8
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__3)
    - id: case__11
      type: case__11
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__11)
    - id: case__7
      type: case__7
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__7)
    - id: case__15
      type: case__15
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__15)
    - id: case__129
      type: case__129_entries
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__129)
    - id: case__130
      type: case__130_entries
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__130)
    - id: case__131
      type: case__131
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__131)
    - id: case__192
      type: case__192
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__192)
    - id: case__193
      type: case__193
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__193)
    - id: case__195
      type: case__195
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__195)
    - id: case__224
      type: case__224
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__224)
    - id: case__225
      type: case__225
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__225)
    - id: case__226
      type: case__226
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__226)
    - id: case__227
      type: case__227
      if: (case__0_field3_elt_tag == case__0_field3_elt_tag::case__227)
  case__1:
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
      type: case__1_field3
  case__10:
    seq:
    - id: case__10_field0
      type: s4
    - id: case__10_field1
      size: 32
      doc: ! 'context_hash


        case__10_field1_field1'
  case__11:
    seq:
    - id: case__11_field0
      type: s8
    - id: case__11_field1
      size: 32
      doc: ! 'context_hash


        case__11_field1_field1'
  case__12:
    seq:
    - id: case__12_field0
      type: u1
    - id: case__12_field1
      type: case__12_field1
  case__129_elt_field0:
    seq:
    - id: len_case__129_elt_field0
      type: u1
    - id: case__129_elt_field0
      size: len_case__129_elt_field0
      size-eos: true
  case__129_elt_field1:
    seq:
    - id: case__129_elt_field1_tag
      type: u1
      enum: case__129_elt_field1_tag
    - id: case__0
      size: 32
      if: (case__129_elt_field1_tag == case__129_elt_field1_tag::case__0)
    - id: case__1
      size: 32
      if: (case__129_elt_field1_tag == case__129_elt_field1_tag::case__1)
  case__129_entries:
    seq:
    - id: case__129_elt_field0
      type: case__129_elt_field0
    - id: case__129_elt_field1
      type: case__129_elt_field1
  case__12_field1:
    seq:
    - id: case__12_field1_field0
      size: 32
      doc: context_hash
    - id: case__12_field1_field1
      size: 32
      doc: context_hash
  case__13:
    seq:
    - id: case__13_field0
      type: u2
    - id: case__13_field1
      type: case__13_field1
  case__130_elt_field0:
    seq:
    - id: len_case__130_elt_field0
      type: u1
    - id: case__130_elt_field0
      size: len_case__130_elt_field0
      size-eos: true
  case__130_elt_field1:
    seq:
    - id: case__130_elt_field1_tag
      type: u1
      enum: case__130_elt_field1_tag
    - id: case__0
      size: 32
      if: (case__130_elt_field1_tag == case__130_elt_field1_tag::case__0)
    - id: case__1
      size: 32
      if: (case__130_elt_field1_tag == case__130_elt_field1_tag::case__1)
  case__130_entries:
    seq:
    - id: case__130_elt_field0
      type: case__130_elt_field0
    - id: case__130_elt_field1
      type: case__130_elt_field1
  case__131:
    seq:
    - id: len_case__131
      type: s4
    - id: case__131
      type: case__131_entries
      size: len_case__131
      repeat: eos
  case__131_elt_field0:
    seq:
    - id: len_case__131_elt_field0
      type: u1
    - id: case__131_elt_field0
      size: len_case__131_elt_field0
      size-eos: true
  case__131_elt_field1:
    seq:
    - id: case__131_elt_field1_tag
      type: u1
      enum: case__131_elt_field1_tag
    - id: case__0
      size: 32
      if: (case__131_elt_field1_tag == case__131_elt_field1_tag::case__0)
    - id: case__1
      size: 32
      if: (case__131_elt_field1_tag == case__131_elt_field1_tag::case__1)
  case__131_entries:
    seq:
    - id: case__131_elt_field0
      type: case__131_elt_field0
    - id: case__131_elt_field1
      type: case__131_elt_field1
  case__13_field1:
    seq:
    - id: case__13_field1_field0
      size: 32
      doc: context_hash
    - id: case__13_field1_field1
      size: 32
      doc: context_hash
  case__14:
    seq:
    - id: case__14_field0
      type: s4
    - id: case__14_field1
      type: case__14_field1
  case__14_field1:
    seq:
    - id: case__14_field1_field0
      size: 32
      doc: context_hash
    - id: case__14_field1_field1
      size: 32
      doc: context_hash
  case__15:
    seq:
    - id: case__15_field0
      type: s8
    - id: case__15_field1
      type: case__15_field1
  case__15_field1:
    seq:
    - id: case__15_field1_field0
      size: 32
      doc: context_hash
    - id: case__15_field1_field1
      size: 32
      doc: context_hash
  case__192:
    seq:
    - id: len_case__192
      type: u1
    - id: case__192
      size: len_case__192
      size-eos: true
  case__193:
    seq:
    - id: len_case__193
      type: u2
    - id: case__193
      size: len_case__193
      size-eos: true
  case__195:
    seq:
    - id: len_case__195
      type: s4
    - id: case__195
      size: len_case__195
  case__1_field3:
    seq:
    - id: len_case__1_field3
      type: s4
    - id: case__1_field3
      type: case__1_field3_entries
      size: len_case__1_field3
      repeat: eos
  case__1_field3_entries:
    seq:
    - id: case__1_field3_elt_tag
      type: u1
      enum: case__1_field3_elt_tag
    - id: case__0
      type: u1
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__0)
    - id: case__8
      type: case__8
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__8)
    - id: case__4
      type: case__4
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__4)
    - id: case__12
      type: case__12
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__12)
    - id: case__1
      type: u2
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__1)
    - id: case__9
      type: case__9
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__9)
    - id: case__5
      type: case__5
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__5)
    - id: case__13
      type: case__13
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__13)
    - id: case__2
      type: s4
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__2)
    - id: case__10
      type: case__10
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__10)
    - id: case__6
      type: case__6
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__6)
    - id: case__14
      type: case__14
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__14)
    - id: case__3
      type: s8
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__3)
    - id: case__11
      type: case__11
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__11)
    - id: case__7
      type: case__7
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__7)
    - id: case__15
      type: case__15
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__15)
    - id: case__129
      type: case__129_entries
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__129)
    - id: case__130
      type: case__130_entries
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__130)
    - id: case__131
      type: case__131
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__131)
    - id: case__192
      type: case__192
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__192)
    - id: case__193
      type: case__193
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__193)
    - id: case__195
      type: case__195
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__195)
    - id: case__224
      type: case__224
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__224)
    - id: case__225
      type: case__225
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__225)
    - id: case__226
      type: case__226
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__226)
    - id: case__227
      type: case__227
      if: (case__1_field3_elt_tag == case__1_field3_elt_tag::case__227)
  case__2:
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
      type: case__2_field3
  case__224:
    seq:
    - id: case__224_field0
      type: u1
    - id: case__224_field1
      type: case__224_field1
    - id: case__224_field2
      size: 32
      doc: context_hash
  case__224_field1:
    seq:
    - id: len_case__224_field1
      type: u1
    - id: case__224_field1
      size: len_case__224_field1
      size-eos: true
  case__225:
    seq:
    - id: case__225_field0
      type: u2
    - id: case__225_field1
      type: case__225_field1
    - id: case__225_field2
      size: 32
      doc: context_hash
  case__225_field1:
    seq:
    - id: len_case__225_field1
      type: u1
    - id: case__225_field1
      size: len_case__225_field1
      size-eos: true
  case__226:
    seq:
    - id: case__226_field0
      type: s4
    - id: case__226_field1
      type: case__226_field1
    - id: case__226_field2
      size: 32
      doc: context_hash
  case__226_field1:
    seq:
    - id: len_case__226_field1
      type: u1
    - id: case__226_field1
      size: len_case__226_field1
      size-eos: true
  case__227:
    seq:
    - id: case__227_field0
      type: s8
    - id: case__227_field1
      type: case__227_field1
    - id: case__227_field2
      size: 32
      doc: context_hash
  case__227_field1:
    seq:
    - id: len_case__227_field1
      type: u1
    - id: case__227_field1
      size: len_case__227_field1
      size-eos: true
  case__2_field3:
    seq:
    - id: len_case__2_field3
      type: s4
    - id: case__2_field3
      type: case__2_field3_entries
      size: len_case__2_field3
      repeat: eos
  case__2_field3_entries:
    seq:
    - id: case__2_field3_elt_tag
      type: u1
      enum: case__2_field3_elt_tag
    - id: case__0
      type: u1
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__0)
    - id: case__8
      type: case__8
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__8)
    - id: case__4
      type: case__4
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__4)
    - id: case__12
      type: case__12
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__12)
    - id: case__1
      type: u2
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__1)
    - id: case__9
      type: case__9
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__9)
    - id: case__5
      type: case__5
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__5)
    - id: case__13
      type: case__13
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__13)
    - id: case__2
      type: s4
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__2)
    - id: case__10
      type: case__10
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__10)
    - id: case__6
      type: case__6
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__6)
    - id: case__14
      type: case__14
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__14)
    - id: case__3
      type: s8
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__3)
    - id: case__11
      type: case__11
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__11)
    - id: case__7
      type: case__7
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__7)
    - id: case__15
      type: case__15
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__15)
    - id: case__129
      type: case__129_entries
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__129)
    - id: case__130
      type: case__130_entries
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__130)
    - id: case__131
      type: case__131
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__131)
    - id: case__192
      type: case__192
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__192)
    - id: case__193
      type: case__193
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__193)
    - id: case__195
      type: case__195
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__195)
    - id: case__224
      type: case__224
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__224)
    - id: case__225
      type: case__225
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__225)
    - id: case__226
      type: case__226
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__226)
    - id: case__227
      type: case__227
      if: (case__2_field3_elt_tag == case__2_field3_elt_tag::case__227)
  case__3:
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
      type: case__3_field3
  case__3_field3:
    seq:
    - id: len_case__3_field3
      type: s4
    - id: case__3_field3
      type: case__3_field3_entries
      size: len_case__3_field3
      repeat: eos
  case__3_field3_entries:
    seq:
    - id: case__3_field3_elt_tag
      type: u1
      enum: case__3_field3_elt_tag
    - id: case__0
      type: u1
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__0)
    - id: case__8
      type: case__8
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__8)
    - id: case__4
      type: case__4
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__4)
    - id: case__12
      type: case__12
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__12)
    - id: case__1
      type: u2
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__1)
    - id: case__9
      type: case__9
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__9)
    - id: case__5
      type: case__5
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__5)
    - id: case__13
      type: case__13
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__13)
    - id: case__2
      type: s4
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__2)
    - id: case__10
      type: case__10
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__10)
    - id: case__6
      type: case__6
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__6)
    - id: case__14
      type: case__14
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__14)
    - id: case__3
      type: s8
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__3)
    - id: case__11
      type: case__11
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__11)
    - id: case__7
      type: case__7
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__7)
    - id: case__15
      type: case__15
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__15)
    - id: case__129
      type: case__129_entries
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__129)
    - id: case__130
      type: case__130_entries
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__130)
    - id: case__131
      type: case__131
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__131)
    - id: case__192
      type: case__192
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__192)
    - id: case__193
      type: case__193
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__193)
    - id: case__195
      type: case__195
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__195)
    - id: case__224
      type: case__224
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__224)
    - id: case__225
      type: case__225
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__225)
    - id: case__226
      type: case__226
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__226)
    - id: case__227
      type: case__227
      if: (case__3_field3_elt_tag == case__3_field3_elt_tag::case__227)
  case__4:
    seq:
    - id: case__4_field0
      type: u1
    - id: case__4_field1
      size: 32
      doc: ! 'context_hash


        case__4_field1_field0'
  case__5:
    seq:
    - id: case__5_field0
      type: u2
    - id: case__5_field1
      size: 32
      doc: ! 'context_hash


        case__5_field1_field0'
  case__6:
    seq:
    - id: case__6_field0
      type: s4
    - id: case__6_field1
      size: 32
      doc: ! 'context_hash


        case__6_field1_field0'
  case__7:
    seq:
    - id: case__7_field0
      type: s8
    - id: case__7_field1
      size: 32
      doc: ! 'context_hash


        case__7_field1_field0'
  case__8:
    seq:
    - id: case__8_field0
      type: u1
    - id: case__8_field1
      size: 32
      doc: ! 'context_hash


        case__8_field1_field1'
  case__9:
    seq:
    - id: case__9_field0
      type: u2
    - id: case__9_field1
      size: 32
      doc: ! 'context_hash


        case__9_field1_field1'
  code:
    seq:
    - id: len_code
      type: s4
    - id: code
      size: len_code
  commitment:
    seq:
    - id: level
      type: s4
    - id: messages
      type: messages
    - id: predecessor
      type: predecessor
    - id: inbox_merkle_root
      size: 32
  commitment_:
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
  content:
    seq:
    - id: len_content
      type: s4
    - id: content
      size: len_content
  contents:
    seq:
    - id: len_contents
      type: s4
    - id: contents
      size: len_contents
  delegation:
    seq:
    - id: source
      type: public_key_hash
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
  deposit:
    seq:
    - id: sender
      type: public_key_hash
    - id: destination
      size: 20
    - id: ticket_hash
      size: 32
    - id: amount
      type: amount
  double_baking_evidence:
    seq:
    - id: bh1
      type: bh1
    - id: bh2
      type: bh2
  double_endorsement_evidence:
    seq:
    - id: op1
      type: op1
    - id: op2
      type: op2
  double_preendorsement_evidence:
    seq:
    - id: op1
      type: op1_
    - id: op2
      type: op2_
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
  entrypoint:
    seq:
    - id: len_entrypoint
      type: s4
    - id: entrypoint
      size: len_entrypoint
  id_013__ptjakart__block_header__alpha__full_header:
    seq:
    - id: id_013__ptjakart__block_header__alpha__full_header
      type: block_header__shell
    - id: id_013__ptjakart__block_header__alpha__signed_contents
      type: id_013__ptjakart__block_header__alpha__signed_contents
  id_013__ptjakart__block_header__alpha__signed_contents:
    seq:
    - id: id_013__ptjakart__block_header__alpha__unsigned_contents
      type: id_013__ptjakart__block_header__alpha__unsigned_contents
    - id: signature
      size: 64
  id_013__ptjakart__block_header__alpha__unsigned_contents:
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
  id_013__ptjakart__contract_id:
    doc: ! >-
      A contract handle: A contract notation as given to an RPC or inside scripts.
      Can be a base58 implicit contract hash or a base58 originated contract hash.
    seq:
    - id: id_013__ptjakart__contract_id_tag
      type: u1
      enum: id_013__ptjakart__contract_id_tag
    - id: implicit
      type: public_key_hash
      if: (id_013__ptjakart__contract_id_tag == id_013__ptjakart__contract_id_tag::implicit)
    - id: originated
      type: originated
      if: (id_013__ptjakart__contract_id_tag == id_013__ptjakart__contract_id_tag::originated)
  id_013__ptjakart__entrypoint:
    doc: ! 'entrypoint: Named entrypoint to a Michelson smart contract'
    seq:
    - id: id_013__ptjakart__entrypoint_tag
      type: u1
      enum: id_013__ptjakart__entrypoint_tag
    - id: named
      type: named
      if: (id_013__ptjakart__entrypoint_tag == id_013__ptjakart__entrypoint_tag::named)
  id_013__ptjakart__inlined__endorsement:
    seq:
    - id: id_013__ptjakart__inlined__endorsement
      type: operation__shell_header
    - id: operations
      type: id_013__ptjakart__inlined__endorsement_mempool__contents
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size: 64
      if: (signature_tag == bool::true)
  id_013__ptjakart__inlined__endorsement_mempool__contents:
    seq:
    - id: id_013__ptjakart__inlined__endorsement_mempool__contents_tag
      type: u1
      enum: id_013__ptjakart__inlined__endorsement_mempool__contents_tag
    - id: endorsement
      type: endorsement
      if: (id_013__ptjakart__inlined__endorsement_mempool__contents_tag == id_013__ptjakart__inlined__endorsement_mempool__contents_tag::endorsement)
  id_013__ptjakart__inlined__preendorsement:
    seq:
    - id: id_013__ptjakart__inlined__preendorsement
      type: operation__shell_header
    - id: operations
      type: id_013__ptjakart__inlined__preendorsement__contents
    - id: signature_tag
      type: u1
      enum: bool
    - id: signature
      size: 64
      if: (signature_tag == bool::true)
  id_013__ptjakart__inlined__preendorsement__contents:
    seq:
    - id: id_013__ptjakart__inlined__preendorsement__contents_tag
      type: u1
      enum: id_013__ptjakart__inlined__preendorsement__contents_tag
    - id: preendorsement
      type: endorsement
      if: (id_013__ptjakart__inlined__preendorsement__contents_tag == id_013__ptjakart__inlined__preendorsement__contents_tag::preendorsement)
  id_013__ptjakart__operation__alpha__contents:
    seq:
    - id: id_013__ptjakart__operation__alpha__contents_tag
      type: u1
      enum: id_013__ptjakart__operation__alpha__contents_tag
    - id: endorsement
      type: endorsement
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::endorsement)
    - id: preendorsement
      type: endorsement
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::preendorsement)
    - id: seed_nonce_revelation
      type: seed_nonce_revelation
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::seed_nonce_revelation)
    - id: double_endorsement_evidence
      type: double_endorsement_evidence
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::double_endorsement_evidence)
    - id: double_preendorsement_evidence
      type: double_preendorsement_evidence
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::double_preendorsement_evidence)
    - id: double_baking_evidence
      type: double_baking_evidence
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::double_baking_evidence)
    - id: activate_account
      type: activate_account
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::activate_account)
    - id: proposals
      type: proposals_
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::proposals)
    - id: ballot
      type: ballot
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::ballot)
    - id: reveal
      type: reveal
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::reveal)
    - id: transaction
      type: transaction
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::transaction)
    - id: origination
      type: origination
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::origination)
    - id: delegation
      type: delegation
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::delegation)
    - id: set_deposits_limit
      type: set_deposits_limit
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::set_deposits_limit)
    - id: failing_noop
      type: arbitrary
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::failing_noop)
    - id: register_global_constant
      type: register_global_constant
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::register_global_constant)
    - id: tx_rollup_origination
      type: tx_rollup_origination
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::tx_rollup_origination)
    - id: tx_rollup_submit_batch
      type: tx_rollup_submit_batch
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::tx_rollup_submit_batch)
    - id: tx_rollup_commit
      type: tx_rollup_commit
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::tx_rollup_commit)
    - id: tx_rollup_return_bond
      type: tx_rollup_return_bond
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::tx_rollup_return_bond)
    - id: tx_rollup_finalize_commitment
      type: tx_rollup_return_bond
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::tx_rollup_finalize_commitment)
    - id: tx_rollup_remove_commitment
      type: tx_rollup_return_bond
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::tx_rollup_remove_commitment)
    - id: tx_rollup_rejection
      type: tx_rollup_rejection
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::tx_rollup_rejection)
    - id: tx_rollup_dispatch_tickets
      type: tx_rollup_dispatch_tickets
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::tx_rollup_dispatch_tickets)
    - id: transfer_ticket
      type: transfer_ticket
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::transfer_ticket)
    - id: sc_rollup_originate
      type: sc_rollup_originate
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::sc_rollup_originate)
    - id: sc_rollup_add_messages
      type: sc_rollup_add_messages
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::sc_rollup_add_messages)
    - id: sc_rollup_cement
      type: sc_rollup_cement
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::sc_rollup_cement)
    - id: sc_rollup_publish
      type: sc_rollup_publish
      if: (id_013__ptjakart__operation__alpha__contents_tag == id_013__ptjakart__operation__alpha__contents_tag::sc_rollup_publish)
  id_013__ptjakart__rollup_address:
    doc: ! >-
      A smart contract rollup address: A smart contract rollup is identified by a
      base58 address starting with scr1
    seq:
    - id: len_id_013__ptjakart__rollup_address
      type: s4
    - id: id_013__ptjakart__rollup_address
      size: len_id_013__ptjakart__rollup_address
  id_013__ptjakart__scripted__contracts:
    seq:
    - id: code
      type: code
    - id: storage
      type: storage
  id_013__ptjakart__transaction_destination:
    doc: ! >-
      A destination of a transaction: A destination notation compatible with the contract
      notation as given to an RPC or inside scripts. Can be a base58 implicit contract
      hash, a base58 originated contract hash, or a base58 originated transaction
      rollup.
    seq:
    - id: id_013__ptjakart__transaction_destination_tag
      type: u1
      enum: id_013__ptjakart__transaction_destination_tag
    - id: implicit
      type: public_key_hash
      if: (id_013__ptjakart__transaction_destination_tag == id_013__ptjakart__transaction_destination_tag::implicit)
    - id: originated
      type: originated
      if: (id_013__ptjakart__transaction_destination_tag == id_013__ptjakart__transaction_destination_tag::originated)
    - id: tx_rollup
      type: tx_rollup
      if: (id_013__ptjakart__transaction_destination_tag == id_013__ptjakart__transaction_destination_tag::tx_rollup)
  message:
    seq:
    - id: message_tag
      type: u1
      enum: message_tag
    - id: batch
      type: batch
      if: (message_tag == message_tag::batch)
    - id: deposit
      type: deposit
      if: (message_tag == message_tag::deposit)
  message_:
    seq:
    - id: len_message
      type: s4
    - id: message
      type: message_entries
      size: len_message
      repeat: eos
  message_entries:
    seq:
    - id: len_message_elt
      type: s4
    - id: message_elt
      size: len_message_elt
  message_path:
    seq:
    - id: len_message_path
      type: s4
    - id: message_path
      type: message_path_entries
      size: len_message_path
      repeat: eos
  message_path_entries:
    seq:
    - id: inbox_list_hash
      size: 32
  message_result_path:
    seq:
    - id: len_message_result_path
      type: s4
    - id: message_result_path
      type: message_result_path_entries
      size: len_message_result_path
      repeat: eos
  message_result_path_entries:
    seq:
    - id: message_result_list_hash
      size: 32
  messages:
    seq:
    - id: len_messages
      type: s4
    - id: messages
      type: messages_entries
      size: len_messages
      repeat: eos
  messages_entries:
    seq:
    - id: message_result_hash
      size: 32
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
    - id: len_named
      type: u1
    - id: named
      size: len_named
      size-eos: true
  op1:
    seq:
    - id: len_op1
      type: s4
    - id: op1
      type: id_013__ptjakart__inlined__endorsement
      size: len_op1
  op1_:
    seq:
    - id: len_op1
      type: s4
    - id: op1
      type: id_013__ptjakart__inlined__preendorsement
      size: len_op1
  op2:
    seq:
    - id: len_op2
      type: s4
    - id: op2
      type: id_013__ptjakart__inlined__endorsement
      size: len_op2
  op2_:
    seq:
    - id: len_op2
      type: s4
    - id: op2
      type: id_013__ptjakart__inlined__preendorsement
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
    - id: script
      type: id_013__ptjakart__scripted__contracts
  parameters:
    seq:
    - id: entrypoint
      type: id_013__ptjakart__entrypoint
    - id: value
      type: value
  predecessor:
    seq:
    - id: predecessor_tag
      type: u1
      enum: predecessor_tag
    - id: some
      size: 32
      if: (predecessor_tag == predecessor_tag::some)
  previous_message_result:
    seq:
    - id: context_hash
      size: 32
    - id: withdraw_list_hash
      size: 32
  previous_message_result_path:
    seq:
    - id: len_previous_message_result_path
      type: s4
    - id: previous_message_result_path
      type: message_result_path_entries
      size: len_previous_message_result_path
      repeat: eos
  proof:
    seq:
    - id: proof_tag
      type: u1
      enum: proof_tag
    - id: case__0
      type: case__0
      if: (proof_tag == proof_tag::case__0)
    - id: case__2
      type: case__2
      if: (proof_tag == proof_tag::case__2)
    - id: case__1
      type: case__1
      if: (proof_tag == proof_tag::case__1)
    - id: case__3
      type: case__3
      if: (proof_tag == proof_tag::case__3)
  proposals:
    seq:
    - id: len_proposals
      type: s4
    - id: proposals
      type: proposals_entries
      size: len_proposals
      repeat: eos
  proposals_:
    seq:
    - id: source
      type: public_key_hash
    - id: period
      type: s4
    - id: proposals
      type: proposals
  proposals_entries:
    seq:
    - id: protocol_hash
      size: 32
  public_key:
    doc: A Ed25519, Secp256k1, or P256 public key
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
    doc: A Ed25519, Secp256k1, or P256 public key hash
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
    - id: fee
      type: n
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
  sc_rollup_add_messages:
    seq:
    - id: source
      type: public_key_hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: rollup
      type: id_013__ptjakart__rollup_address
    - id: message
      type: message_
  sc_rollup_cement:
    seq:
    - id: source
      type: public_key_hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: rollup
      type: id_013__ptjakart__rollup_address
    - id: commitment
      size: 32
  sc_rollup_originate:
    seq:
    - id: source
      type: public_key_hash
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
      type: boot_sector
  sc_rollup_publish:
    seq:
    - id: source
      type: public_key_hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: rollup
      type: id_013__ptjakart__rollup_address
    - id: commitment
      type: commitment_
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
  storage:
    seq:
    - id: len_storage
      type: s4
    - id: storage
      size: len_storage
  ticket_contents:
    seq:
    - id: len_ticket_contents
      type: s4
    - id: ticket_contents
      size: len_ticket_contents
  ticket_ty:
    seq:
    - id: len_ticket_ty
      type: s4
    - id: ticket_ty
      size: len_ticket_ty
  tickets_info:
    seq:
    - id: len_tickets_info
      type: s4
    - id: tickets_info
      type: tickets_info_entries
      size: len_tickets_info
      repeat: eos
  tickets_info_entries:
    seq:
    - id: contents
      type: contents
    - id: ty
      type: ty
    - id: ticketer
      type: id_013__ptjakart__contract_id
    - id: amount
      type: amount
    - id: claimer
      type: public_key_hash
  transaction:
    seq:
    - id: source
      type: public_key_hash
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
      type: id_013__ptjakart__transaction_destination
    - id: parameters_tag
      type: u1
      enum: bool
    - id: parameters
      type: parameters
      if: (parameters_tag == bool::true)
  transfer_ticket:
    seq:
    - id: source
      type: public_key_hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
    - id: ticket_contents
      type: ticket_contents
    - id: ticket_ty
      type: ticket_ty
    - id: ticket_ticketer
      type: id_013__ptjakart__contract_id
    - id: ticket_amount
      type: n
    - id: destination
      type: id_013__ptjakart__contract_id
    - id: entrypoint
      type: entrypoint
  tx_rollup:
    seq:
    - id: rollup_hash
      size: 20
      doc: ! >-
        A tx rollup handle: A tx rollup notation as given to an RPC or inside scripts,
        is a base58 tx rollup hash
    - id: tx_rollup_padding
      size: 1
      doc: This field is for padding, ignore
  tx_rollup_commit:
    seq:
    - id: source
      type: public_key_hash
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
    - id: commitment
      type: commitment
  tx_rollup_dispatch_tickets:
    seq:
    - id: source
      type: public_key_hash
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
    - id: message_result_path
      type: message_result_path
    - id: tickets_info
      type: tickets_info
  tx_rollup_origination:
    seq:
    - id: source
      type: public_key_hash
    - id: fee
      type: n
    - id: counter
      type: n
    - id: gas_limit
      type: n
    - id: storage_limit
      type: n
  tx_rollup_rejection:
    seq:
    - id: source
      type: public_key_hash
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
    - id: message
      type: message
    - id: message_position
      type: n
    - id: message_path
      type: message_path
    - id: message_result_hash
      size: 32
    - id: message_result_path
      type: message_result_path
    - id: previous_message_result
      type: previous_message_result
    - id: previous_message_result_path
      type: previous_message_result_path
    - id: proof
      type: proof
  tx_rollup_return_bond:
    seq:
    - id: source
      type: public_key_hash
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
  tx_rollup_submit_batch:
    seq:
    - id: source
      type: public_key_hash
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
      type: content
    - id: burn_limit_tag
      type: u1
      enum: bool
    - id: burn_limit
      type: n
      if: (burn_limit_tag == bool::true)
  ty:
    seq:
    - id: len_ty
      type: s4
    - id: ty
      size: len_ty
  value:
    seq:
    - id: len_value
      type: s4
    - id: value
      size: len_value
enums:
  amount_tag:
    0: case__0
    1: case__1
    2: case__2
    3: case__3
  bool:
    0: false
    255: true
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
  case__129_elt_field1_tag:
    0: case__0
    1: case__1
  case__130_elt_field1_tag:
    0: case__0
    1: case__1
  case__131_elt_field1_tag:
    0: case__0
    1: case__1
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
  id_013__ptjakart__contract_id_tag:
    0: implicit
    1: originated
  id_013__ptjakart__entrypoint_tag:
    0: default
    1: root
    2: do
    3: set_delegate
    4: remove_delegate
    255: named
  id_013__ptjakart__inlined__endorsement_mempool__contents_tag:
    21: endorsement
  id_013__ptjakart__inlined__preendorsement__contents_tag:
    20: preendorsement
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
  id_013__ptjakart__transaction_destination_tag:
    0: implicit
    1: originated
    2: tx_rollup
  kind_tag:
    0: example_arith__smart__contract__rollup__kind
  message_tag:
    0: batch
    1: deposit
  predecessor_tag:
    0: none
    1: some
  proof_tag:
    0: case__0
    1: case__1
    2: case__2
    3: case__3
  public_key_hash_tag:
    0: ed25519
    1: secp256k1
    2: p256
  public_key_tag:
    0: ed25519
    1: secp256k1
    2: p256
seq:
- id: id_013__ptjakart__operation__alpha__contents
  type: id_013__ptjakart__operation__alpha__contents
