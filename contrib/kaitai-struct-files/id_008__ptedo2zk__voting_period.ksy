meta:
  id: id_008__ptedo2zk__voting_period
  endian: be
enums:
  kind_tag:
    0: Proposal
    1: Testing_vote
    2: Testing
    3: Promotion_vote
    4: Adoption
seq:
- id: index
  type: s4
  doc: The voting period's index. Starts at 0 with the first block of protocol alpha.
- id: kind
  type: u1
  enum: kind_tag
- id: start_position
  type: s4
