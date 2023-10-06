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
  types:
    list_of_uint8_entries:
      seq:
      - id: list_of_uint8
        type: u1
  seq:
  - id: list_of_uint8
    type: list_of_uint8_entries
    repeat: expr
    repeat-expr: 5
  |}]
