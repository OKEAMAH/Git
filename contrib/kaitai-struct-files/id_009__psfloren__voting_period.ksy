meta:
  id: id_009__psfloren__voting_period
  endian: be
enums:
  kind_tag:
    0: Proposal
    1: exploration
    2: Cooldown
    3: Promotion
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
