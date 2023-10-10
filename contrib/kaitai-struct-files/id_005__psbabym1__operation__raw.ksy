meta:
  id: id_005__psbabym1__operation__raw
  endian: be
types:
  operation:
    seq:
    - id: operation__shell_header
      size: 32
      doc: An operation's shell header.
    - id: data
      size-eos: true
seq:
- id: operation
  type: operation
  doc: ! >-
    An operation. The shell_header part indicates a block an operation is meant to
    apply on top of. The proto part is protocol-specific and appears as a binary blob.