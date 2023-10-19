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
    enums:
      simple_union_tag:
        0: some
        1: none
    seq:
    - id: simple_union_tag
      type: u1
      enum: simple_union_tag
    - id: simple_union_some
      type: u1
      if: (simple_union_tag == simple_union_tag::some)
  |}]

let%expect_test "test simple union" =
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
    enums:
      bool:
        0: false
        255: true
      more_union_tag:
        0: A
        1: B
        2: C
        255: D
    seq:
    - id: more_union_tag
      type: u1
      enum: more_union_tag
    - id: more_union_A
      type: u1
      if: (more_union_tag == more_union_tag::A)
    - id: more_union_B
      type: u2
      if: (more_union_tag == more_union_tag::B)
    - id: more_union_C
      type: u1
      if: (more_union_tag == more_union_tag::C)
      enum: bool
  |}]
