ground.uint8 test
  $ ./codec.exe dump kaitai for ground.uint8
  meta:
    id: ground__uint8
    endian: be
  doc: Unsigned 8 bit integers
  seq:
  - id: ground__uint8
    type: u1
ground.bool test
  $ ./codec.exe dump kaitai for ground.bool
  meta:
    id: ground__bool
    endian: be
  doc: Boolean values
  enums:
    bool:
      0: false
      255: true
  seq:
  - id: ground__bool
    type: u1
    enum: bool
ground.int8 test
  $ ./codec.exe dump kaitai for ground.int8
  meta:
    id: ground__int8
    endian: be
  doc: Signed 8 bit integers
  seq:
  - id: ground__int8
    type: s1
ground.uint16 test
  $ ./codec.exe dump kaitai for ground.uint16
  meta:
    id: ground__uint16
    endian: be
  doc: Unsigned 16 bit integers
  seq:
  - id: ground__uint16
    type: u2
ground.int16 test
  $ ./codec.exe dump kaitai for ground.int16
  meta:
    id: ground__int16
    endian: be
  doc: Signed 16 bit integers
  seq:
  - id: ground__int16
    type: s2
ground.int32 test
  $ ./codec.exe dump kaitai for ground.int32
  meta:
    id: ground__int32
    endian: be
  doc: Signed 32 bit integers
  seq:
  - id: ground__int32
    type: s4
ground.int64 test
  $ ./codec.exe dump kaitai for ground.int64
  meta:
    id: ground__int64
    endian: be
  doc: Signed 64 bit integers
  seq:
  - id: ground__int64
    type: s8
ground.int31 test
  $ ./codec.exe dump kaitai for ground.int31
  meta:
    id: ground__int31
    endian: be
  doc: Signed 31 bit integers
  seq:
  - id: ground__int31
    type: s4
ground.float test
  $ ./codec.exe dump kaitai for ground.float
  meta:
    id: ground__float
    endian: be
  doc: Floating point numbers
  seq:
  - id: ground__float
    type: f8
ground.bytes test
  $ ./codec.exe dump kaitai for ground.bytes
  meta:
    id: ground__bytes
    endian: be
  seq:
  - id: len_ground__bytes
    type: s4
  - id: ground__bytes
    size: len_ground__bytes
ground.string test
  $ ./codec.exe dump kaitai for ground.string
  meta:
    id: ground__string
    endian: be
  seq:
  - id: len_ground__string
    type: s4
  - id: ground__string
    size: len_ground__string
ground.N test
  $ ./codec.exe dump kaitai for ground.N
  meta:
    id: ground__n
    endian: be
  doc: Arbitrary precision natural numbers
  types:
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
  seq:
  - id: ground__n
    type: n
ground.Z test
  $ ./codec.exe dump kaitai for ground.Z
  meta:
    id: ground__z
    endian: be
  doc: Arbitrary precision integers
  types:
    z:
      seq:
      - id: has_more_than_single_byte
        type: b1be
      - id: sign
        type: b1be
      - id: payload
        type: b6be
      - id: tail
        type: n_chunk
        repeat: until
        repeat-until: not (_.has_more).as<bool>
        if: not (_.has_more_than_single_byte).as<bool>
    n_chunk:
      seq:
      - id: has_more
        type: b1be
      - id: payload
        type: b7be
  seq:
  - id: ground__z
    type: z
