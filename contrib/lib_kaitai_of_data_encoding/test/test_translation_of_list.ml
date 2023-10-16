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
      ~id:"list_of_uint8"
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
      - id: list_of_uint8_elt
        type: u1
  seq:
  - id: list_of_uint8
    type: list_of_uint8_entries
    repeat: expr
    repeat-expr: 5
  |}]

let%expect_test "test variable size list translation" =
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~id:"list_of_uint8"
      Data_encoding.(Variable.list uint8)
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
      - id: list_of_uint8_elt
        type: u1
  seq:
  - id: list_of_uint8
    type: list_of_uint8_entries
    repeat: eos
  |}]

let%expect_test "test dynamic size list translation" =
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~id:"list_of_uint8"
      Data_encoding.(list uint8)
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
      - id: list_of_uint8_elt
        type: u1
  seq:
  - id: len_list_of_uint8
    type: s4
  - id: list_of_uint8
    type: list_of_uint8_entries
    size: len_list_of_uint8
    repeat: eos
  |}]

(* TODO: ?max_length guard is missing. *)
let%expect_test "test dynamic size list with max length" =
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~id:"list_with_length"
      Data_encoding.(list ?max_length:(Some 5) uint8)
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect
    {|
  meta:
    id: list_with_length
    endian: be
  types:
    list_with_length:
      seq:
      - id: list_with_length
        type: list_with_length_entries
        repeat: eos
    list_with_length_entries:
      seq:
      - id: list_with_length_elt
        type: u1
  seq:
  - id: len_list_with_length
    type: s4
  - id: list_with_length
    type: list_with_length
    size: len_list_with_length
  |}]

(* TODO: ?max_length guard is missing. *)
let%expect_test "test variable size list with max length" =
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~id:"list_with_length"
      Data_encoding.(Variable.list ?max_length:(Some 5) int32)
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect
    {|
  meta:
    id: list_with_length
    endian: be
  types:
    list_with_length:
      seq:
      - id: list_with_length
        type: list_with_length_entries
        repeat: eos
    list_with_length_entries:
      seq:
      - id: list_with_length_elt
        type: s4
  seq:
  - id: list_with_length_with_checked_size
    type: list_with_length
    size: 20
  |}]

(* TODO: ?max_length guard is missing. *)
let%expect_test "test list with length" =
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~id:"list_with_length"
      Data_encoding.(list_with_length `Uint30 uint8)
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect
    {|
  meta:
    id: list_with_length
    endian: be
  types:
    list_with_length_entries:
      seq:
      - id: list_with_length_elt
        type: u1
  seq:
  - id: number_of_elements_in_list_with_length
    type: s4
  - id: list_with_length
    type: list_with_length_entries
    repeat: expr
    repeat-expr: number_of_elements_in_list_with_length
  |}]

(* TODO: ?max_length guard is missing. *)
let%expect_test "test list with length" =
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~id:"list_with_length"
      Data_encoding.(list_with_length `Uint8 uint8)
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect
    {|
  meta:
    id: list_with_length
    endian: be
  types:
    list_with_length_entries:
      seq:
      - id: list_with_length_elt
        type: u1
  seq:
  - id: number_of_elements_in_list_with_length
    type: u1
  - id: list_with_length
    type: list_with_length_entries
    repeat: expr
    repeat-expr: number_of_elements_in_list_with_length
  |}]

(* TODO: ?max_length guard is missing. *)
let%expect_test "test list with length" =
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~id:"list_with_length"
      Data_encoding.(list_with_length `Uint16 uint8)
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect
    {|
  meta:
    id: list_with_length
    endian: be
  types:
    list_with_length_entries:
      seq:
      - id: list_with_length_elt
        type: u1
  seq:
  - id: number_of_elements_in_list_with_length
    type: u2
  - id: list_with_length
    type: list_with_length_entries
    repeat: expr
    repeat-expr: number_of_elements_in_list_with_length
  |}]
