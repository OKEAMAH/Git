meta:
  id: id_013__ptjakart__fa1__2__token_transfer
  endian: be
types:
  fee:
    meta:
      id: fee
      endian: be
    seq:
    - id: len_fee
      type: s4
    - id: fee
      size: len_fee
  tez__amount:
    meta:
      id: tez__amount
      endian: be
    seq:
    - id: len_tez__amount
      type: s4
    - id: tez__amount
      size: len_tez__amount
  destination:
    meta:
      id: destination
      endian: be
    seq:
    - id: len_destination
      type: s4
    - id: destination
      size: len_destination
  token_contract:
    meta:
      id: token_contract
      endian: be
    seq:
    - id: len_token_contract
      type: s4
    - id: token_contract
      size: len_token_contract
  n:
    seq:
    - id: n
      type: n_chunk
      repeat: until
      repeat-until: not (_.has_more).as<bool>
  z:
    seq:
    - id: has_more
      type: b1be
    - id: sign
      type: b1be
    - id: payload
      type: b6be
    - id: tail
      type: n_chunk
      if: not (_.has_more).as<bool>
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
- id: tez__amount
  type: tez__amount
  if: (tez__amount_tag == bool::true)
- id: fee_tag
  type: u1
  enum: bool
- id: fee
  type: fee
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
