(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2023 Marigold, <contact@marigold.dev>                       *)
(*                                                                           *)
(*****************************************************************************)

let%expect_test "test fixed size list translation" =
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~encoding_name:"list_of_uint8"
      Data_encoding.(Fixed.list 5 uint8)
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect
    {|
  meta:
    id: list_of_uint8
    endian: be
  seq:
  - id: list_of_uint8_elt
    type: u1
    repeat: expr
    repeat-expr: 5
  |}]

let%expect_test "test variable size list translation" =
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~encoding_name:"list_of_uint8"
      Data_encoding.(Variable.list uint8)
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect
    {|
  meta:
    id: list_of_uint8
    endian: be
  seq:
  - id: list_of_uint8_elt
    type: u1
    repeat: eos
  |}]

let%expect_test "test dynamic size list translation" =
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~encoding_name:"list_of_uint8"
      Data_encoding.(list uint8)
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect
    {|
  meta:
    id: list_of_uint8
    endian: be
  types:
    list_of_uint8:
      seq:
      - id: list_of_uint8_elt
        type: u1
        repeat: eos
  seq:
  - id: len_list_of_uint8
    type: s4
  - id: list_of_uint8
    type: list_of_uint8
    size: len_list_of_uint8
  |}]
