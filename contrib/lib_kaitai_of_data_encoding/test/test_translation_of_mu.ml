(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Marigold, <contact@marigold.dev>                       *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

let%expect_test "test basic mu" =
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~id:"intlist"
      Data_encoding.(
        mu
          "ilist"
          ~title:"Simple integer list"
          ~description:"Using the mu combinator for lists just to test mu"
          (fun ilist ->
            union
              [
                case
                  ~title:"Nil"
                  (Tag 0)
                  unit
                  (function [] -> Some () | _ -> None)
                  (fun () -> []);
                case
                  ~title:"Cons"
                  (Tag 1)
                  (obj2 (req "hd" uint16) (req "tl" ilist))
                  (function hd :: tl -> Some (hd, tl) | _ -> None)
                  (fun (hd, tl) -> hd :: tl);
              ]))
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect
    {|
    meta:
      id: intlist
      endian: be
    doc: ! 'Encoding id: intlist'
    types:
      ilist:
        seq:
        - id: ilist_tag
          type: u1
          enum: ilist_tag
        - id: cons__ilist
          type: cons__ilist
          if: (ilist_tag == ilist_tag::cons)
      cons__ilist:
        seq:
        - id: hd
          type: u2
        - id: tl
          type: ilist
    enums:
      ilist_tag:
        0: nil
        1: cons
    seq:
    - id: ilist
      type: ilist
      doc: ! 'Simple integer list: Using the mu combinator for lists just to test mu'
  |}]

let%expect_test "test more mu" =
  let module M = struct
    type t = Empty | One of bool | Seq of bool * t | Branch of bool * t list
  end in
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~id:"t"
      Data_encoding.(
        mu "mt" (fun mt ->
            union
              [
                case
                  ~title:"Empty"
                  (Tag 0)
                  unit
                  (function M.Empty -> Some () | _ -> None)
                  (fun () -> M.Empty);
                case
                  ~title:"One"
                  (Tag 1)
                  bool
                  (function M.One b -> Some b | _ -> None)
                  (fun b -> M.One b);
                case
                  ~title:"Seq"
                  (Tag 2)
                  (obj2 (req "payload" bool) (req "seq" mt))
                  (function M.Seq (b, t) -> Some (b, t) | _ -> None)
                  (fun (b, t) -> M.Seq (b, t));
                case
                  ~title:"Branch"
                  (Tag 3)
                  (obj2 (req "payload" bool) (req "branches" (list mt)))
                  (function M.Branch (b, t) -> Some (b, t) | _ -> None)
                  (fun (b, t) -> M.Branch (b, t));
              ]))
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect
    {|
    meta:
      id: t
      endian: be
    doc: ! 'Encoding id: t'
    types:
      mt:
        seq:
        - id: mt_tag
          type: u1
          enum: mt_tag
        - id: one__mt
          type: u1
          if: (mt_tag == mt_tag::one)
          enum: bool
        - id: seq__mt
          type: seq__mt
          if: (mt_tag == mt_tag::seq)
        - id: branch__mt
          type: branch__mt
          if: (mt_tag == mt_tag::branch)
      branch__mt:
        seq:
        - id: payload
          type: u1
          enum: bool
        - id: branch__branches
          type: branch__branches
      branch__branches:
        seq:
        - id: len_branch__branches_dyn
          type: uint30
        - id: branch__branches_dyn
          type: branch__branches_dyn
          size: len_branch__branches_dyn
      branch__branches_dyn:
        seq:
        - id: branch__branches_entries
          type: branch__branches_entries
          repeat: eos
      branch__branches_entries:
        seq:
        - id: branches_elt
          type: mt
      uint30:
        seq:
        - id: uint30
          type: u4
          valid:
            max: 1073741823
      seq__mt:
        seq:
        - id: payload
          type: u1
          enum: bool
        - id: seq
          type: mt
    enums:
      bool:
        0: false
        255: true
      mt_tag:
        0: empty
        1: one
        2: seq
        3: branch
    seq:
    - id: mt
      type: mt
  |}]
