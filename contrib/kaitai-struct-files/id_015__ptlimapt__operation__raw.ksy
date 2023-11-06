meta:
  id: id_015__ptlimapt__operation__raw
  endian: be
doc: ! 'Encoding id: 015-PtLimaPt.operation.raw'
types:
  operation_:
    seq:
    - id: operation__shell_header
      size: 32
      doc: An operation's shell header.
    - id: data
      size-eos: true
seq:
- id: operation_
  type: operation_
  doc: ! >-
    An operation. The shell_header part indicates a block an operation is meant to
    apply on top of. The proto part is protocol-specific and appears as a binary blob.
