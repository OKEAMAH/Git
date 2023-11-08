(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Marigold, <contact@marigold.dev>                       *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

let%expect_test "test simple union" =
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~id:"simple_union"
      Data_encoding.(
        union
          [
            case ~title:"some" (Tag 0) uint8 Fun.id Option.some;
            case
              ~title:"none"
              ~description:"no data available"
              (Tag 1)
              unit
              (function None -> Some () | Some _ -> None)
              (fun () -> None);
          ])
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect
    {|
    meta:
      id: simple_union
      endian: be
    doc: ! 'Encoding id: simple_union'
    enums:
      simple_union_tag:
        0: some
        1:
          id: none
          doc: no data available
    seq:
    - id: simple_union_tag
      type: u1
      enum: simple_union_tag
    - id: simple_union
      type: u1
      if: (simple_union_tag == simple_union_tag::some)
  |}]

let%expect_test "test medium union" =
  let module M = struct
    type t = A of int | B of int | C of bool | D
  end in
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~id:"more_union"
      Data_encoding.(
        union
          [
            case
              ~title:"A"
              (Tag 0)
              uint8
              (function M.A i -> Some i | _ -> None)
              (fun i -> M.A i);
            case
              ~title:"B"
              (Tag 1)
              uint16
              (function M.B i -> Some i | _ -> None)
              (fun i -> M.B i);
            case
              ~title:"C"
              (Tag 2)
              bool
              (function M.C b -> Some b | _ -> None)
              (fun b -> M.C b);
            case
              ~title:"D"
              (Tag 255)
              unit
              (function M.D -> Some () | _ -> None)
              (fun () -> M.D);
          ])
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect
    {|
    meta:
      id: more_union
      endian: be
    doc: ! 'Encoding id: more_union'
    enums:
      bool:
        0: false
        255: true
      more_union_tag:
        0: a
        1: b
        2: c
        255: d
    seq:
    - id: more_union_tag
      type: u1
      enum: more_union_tag
    - id: more_union
      type: u1
      if: (more_union_tag == more_union_tag::a)
    - id: more_union
      type: u2
      if: (more_union_tag == more_union_tag::b)
    - id: more_union
      type: u1
      if: (more_union_tag == more_union_tag::c)
      enum: bool
  |}]

let%expect_test "test union with structures inside" =
  let module M = struct
    type t = A of int | B of (int * string) | C of (bool * bool) | D
  end in
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~id:"more_union"
      Data_encoding.(
        union
          [
            case
              ~title:"A"
              (Tag 0)
              uint8
              (function M.A i -> Some i | _ -> None)
              (fun i -> M.A i);
            case
              ~title:"B"
              (Tag 1)
              (tup2 uint16 string)
              (function M.B (i, s) -> Some (i, s) | _ -> None)
              (fun (i, s) -> M.B (i, s));
            case
              ~title:"C"
              (Tag 2)
              (obj2 (req "l" bool) (dft "r" bool false))
              (function M.C (r, l) -> Some (r, l) | _ -> None)
              (fun (r, l) -> M.C (r, l));
            case
              ~title:"D"
              (Tag 255)
              unit
              (function M.D -> Some () | _ -> None)
              (fun () -> M.D);
          ])
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect.unreachable]
[@@expect.uncaught_exn {|
  (* CR expect_test_collector: This test expectation appears to contain a backtrace.
     This is strongly discouraged as backtraces are fragile.
     Please change this test to not include a backtrace. *)

  (Invalid_argument "Mappings.add: duplicate keys (more_union)")
  Raised at Kaitai_of_data_encoding__Helpers.add_uniq_assoc in file "contrib/lib_kaitai_of_data_encoding/helpers.ml", line 71, characters 11-80
  Called from Kaitai_of_data_encoding__Translate.add_type in file "contrib/lib_kaitai_of_data_encoding/translate.ml", line 58, characters 22-60
  Called from Kaitai_of_data_encoding__Translate.redirect in file "contrib/lib_kaitai_of_data_encoding/translate.ml", line 82, characters 14-34
  Called from Kaitai_of_data_encoding__Translate.seq_field_of_union.(fun) in file "contrib/lib_kaitai_of_data_encoding/translate.ml", line 674, characters 14-923
  Called from Stdlib__List.fold_left in file "list.ml", line 121, characters 24-34
  Called from Kaitai_of_data_encoding__Translate.seq_field_of_union in file "contrib/lib_kaitai_of_data_encoding/translate.ml", line 642, characters 4-1023
  Called from Kaitai_of_data_encoding__Translate.from_data_encoding in file "contrib/lib_kaitai_of_data_encoding/translate.ml", line 827, characters 8-63
  Called from Kaitai_of_data_encoding_test__Test_translation_of_unions.(fun) in file "contrib/lib_kaitai_of_data_encoding/test/test_translation_of_unions.ml", line 121, characters 4-907
  Called from Expect_test_collector.Make.Instance_io.exec in file "collector/expect_test_collector.ml", line 262, characters 12-19 |}]
