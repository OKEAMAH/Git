meta:
  id: id_016__ptmumbai__fa1__2__token_transfer
  endian: be
types:
  n:
    seq:
    - id: n
      type: n_chunk
      repeat: until
      repeat-until: not (_.has_more).as<bool>
  fee:
    seq:
    - id: size_of_fee
      type: s4
    - id: fee
      size: size_of_fee
  tez__amount:
    seq:
    - id: size_of_tez__amount
      type: s4
    - id: tez__amount
      size: size_of_tez__amount
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
    - id: size_of_destination
      type: s4
    - id: destination
      size: size_of_destination
  token_contract:
    seq:
    - id: size_of_token_contract
      type: s4
    - id: token_contract
      size: size_of_token_contract
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
