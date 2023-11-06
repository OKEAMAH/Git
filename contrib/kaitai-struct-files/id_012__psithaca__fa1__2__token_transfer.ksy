meta:
  id: id_012__psithaca__fa1__2__token_transfer
  endian: be
doc: ! 'Encoding id: 012-Psithaca.fa1.2.token_transfer'
types:
  n:
    seq:
    - id: n
      type: n_chunk
      repeat: until
      repeat-until: not (_.has_more).as<bool>
  fee_:
    seq:
    - id: len_fee
      type: u4
      valid:
        max: 1073741823
    - id: fee
      size: len_fee
  tez__amount_:
    seq:
    - id: len_tez__amount
      type: u4
      valid:
        max: 1073741823
    - id: tez__amount
      size: len_tez__amount
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
  destination:
    seq:
    - id: len_destination
      type: u4
      valid:
        max: 1073741823
    - id: destination
      size: len_destination
  token_contract:
    seq:
    - id: len_token_contract
      type: u4
      valid:
        max: 1073741823
    - id: token_contract
      size: len_token_contract
enums:
  bool:
    0: false
    255: true
seq:
- id: token_contract
  type: token_contract
- id: destination
  type: destination
- id: amount
  type: z
- id: tez__amount_tag
  type: u1
  enum: bool
- id: tez__amount_
  type: tez__amount_
  if: (tez__amount_tag == bool::true)
- id: fee_tag
  type: u1
  enum: bool
- id: fee_
  type: fee_
  if: (fee_tag == bool::true)
- id: gas__limit_tag
  type: u1
  enum: bool
- id: gas__limit
  type: n
  if: (gas__limit_tag == bool::true)
- id: storage__limit_tag
  type: u1
  enum: bool
- id: storage__limit
  type: z
  if: (storage__limit_tag == bool::true)
