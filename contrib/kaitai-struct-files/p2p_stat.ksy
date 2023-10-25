meta:
  id: p2p_stat
  endian: be
doc: ! 'Encoding id: p2p_stat

  Description: Statistics about the p2p network.'
seq:
- id: total_sent
  type: s8
- id: total_recv
  type: s8
- id: current_inflow
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
- id: current_outflow
  type: s4
  valid:
    min: -1073741824
    max: 1073741823
