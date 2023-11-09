meta:
  id: test_chain_status
  endian: be
  imports:
  - timestamp__protocol
doc: ! >-
  Encoding id: test_chain_status

  Description: The status of the test chain: not_running (there is no test chain at
  the moment), forking (the test chain is being setup), running (the test chain is
  running).
types:
  forking__test_chain_status:
    seq:
    - id: protocol
      size: 32
    - id: expiration
      type: timestamp__protocol
  running__test_chain_status:
    seq:
    - id: chain_id
      size: 4
    - id: genesis
      size: 32
    - id: protocol
      size: 32
    - id: expiration
      type: timestamp__protocol
enums:
  test_chain_status_tag:
    0: not_running
    1: forking
    2: running
seq:
- id: test_chain_status_tag
  type: u1
  enum: test_chain_status_tag
- id: forking__test_chain_status
  type: forking__test_chain_status
  if: (test_chain_status_tag == test_chain_status_tag::forking)
- id: running__test_chain_status
  type: running__test_chain_status
  if: (test_chain_status_tag == test_chain_status_tag::running)
