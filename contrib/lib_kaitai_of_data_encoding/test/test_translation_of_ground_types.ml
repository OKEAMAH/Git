(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Marigold, <contact@marigold.dev>                       *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

(* This test suite is meant to test translation of ground encodings
   to [Kaitai.Types.ClassSpec.t] *)

let read_expected_ksy example_filename =
  let read_file file = In_channel.with_open_text file In_channel.input_all in
  read_file
  @@ "../../../../../../../contrib/lib_kaitai_of_data_encoding/test/expected/"
  ^ example_filename ^ ".ksy"

(** [assert_encoding_translation_to_valid_ksy_spec ~encoding_id encoding expect_test]
    asserts that translation of [encoding] using [lib_kaitai_of_data_encoding]
    library, produces a kaitai struct specification (.ksy file) that is equal to
    the one that can be found under `test/expected/encoding_id.ksy`.

    As from the `test/README.md` you can see, that prior to running this test
    suite, we assume that `.ksy` files located in `test/expected/*` were
    tested for the semantic correctness. Overall this means we are asserting
    translation against semantically valid kaitai spec file. *)
let assert_encoding_translation_to_valid_ksy_spec ~encoding_id encoding
    expect_test =
  let kaitai_spec =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~id:encoding_id
      encoding
  in
  let expected_ksy = read_expected_ksy encoding_id in
  expect_test (fun () -> print_endline (Kaitai.Print.print kaitai_spec)) ;
  expect_test (fun () -> print_endline expected_ksy)

let%expect_test "test uint8 translation" =
  let expect_test f =
    f () ;
    [%expect
      {|
      meta:
        id: ground_uint8
        endian: be
      seq:
      - id: ground_uint8
        type: u1
    |}]
  in
  assert_encoding_translation_to_valid_ksy_spec
    ~encoding_id:"ground_uint8"
    Data_encoding.uint8
    expect_test

let%expect_test "test int8 translation" =
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~id:"ground_int8"
      Data_encoding.int8
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect
    {|
    meta:
      id: ground_int8
      endian: be
    seq:
    - id: ground_int8
      type: s1
  |}]

let%expect_test "test uint16 translation" =
  let expect_test f =
    f () ;
    [%expect
      {|
      meta:
        id: ground_uint16
        endian: be
      seq:
      - id: ground_uint16
        type: u2
    |}]
  in
  assert_encoding_translation_to_valid_ksy_spec
    ~encoding_id:"ground_uint16"
    Data_encoding.uint16
    expect_test

let%expect_test "test int16 translation" =
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~id:"ground_int16"
      Data_encoding.int16
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect
    {|
    meta:
      id: ground_int16
      endian: be
    seq:
    - id: ground_int16
      type: s2
  |}]

let%expect_test "test int32 translation" =
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~id:"ground_int32"
      Data_encoding.int32
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect
    {|
    meta:
      id: ground_int32
      endian: be
    seq:
    - id: ground_int32
      type: s4
  |}]

let%expect_test "test int64 translation" =
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~id:"ground_int64"
      Data_encoding.int64
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect
    {|
    meta:
      id: ground_int64
      endian: be
    seq:
    - id: ground_int64
      type: s8
  |}]

let%expect_test "test int31 translation" =
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~id:"ground_int31"
      Data_encoding.int31
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect
    {|
    meta:
      id: ground_int31
      endian: be
    seq:
    - id: ground_int31
      type: s4
  |}]

let%expect_test "test float translation" =
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~id:"ground_float"
      Data_encoding.float
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect
    {|
    meta:
      id: ground_float
      endian: be
    seq:
    - id: ground_float
      type: f8
  |}]

let%expect_test "test bool translation" =
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~id:"ground_bool"
      Data_encoding.bool
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect
    {|
    meta:
      id: ground_bool
      endian: be
    enums:
      bool:
        0: false
        255: true
    seq:
    - id: ground_bool
      type: u1
      enum: bool
  |}]

let%expect_test "test dynamic size bytes translation" =
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~id:"ground_bytes"
      Data_encoding.bytes
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect
    {|
    meta:
      id: ground_bytes
      endian: be
    seq:
    - id: len_ground_bytes
      type: s4
    - id: ground_bytes
      size: len_ground_bytes |}]

let%expect_test "test fixed size bytes translation" =
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~id:"bytes_fixed_32"
      (Data_encoding.Fixed.bytes 32)
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect
    {|
    meta:
      id: bytes_fixed_32
      endian: be
    seq:
    - id: bytes_fixed_32
      size: 32 |}]

let%expect_test "test variable size bytes translation" =
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~id:"bytes_variable"
      Data_encoding.Variable.bytes
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect
    {|
    meta:
      id: bytes_variable
      endian: be
    seq:
    - id: bytes_variable
      size-eos: true |}]

let%expect_test "test dynamic size string translation" =
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~id:"ground_string"
      Data_encoding.string
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect
    {|
    meta:
      id: ground_string
      endian: be
    seq:
    - id: len_ground_string
      type: s4
    - id: ground_string
      size: len_ground_string |}]

let%expect_test "test big numbers translation" =
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~id:"ground_n"
      Data_encoding.n
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect
    {|
    meta:
      id: ground_n
      endian: be
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
    - id: ground_n
      type: n
  |}]

let%expect_test "test big numbers translation" =
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~id:"ground_z"
      Data_encoding.z
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect
    {|
    meta:
      id: ground_z
      endian: be
    types:
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
    seq:
    - id: ground_z
      type: z
  |}]
