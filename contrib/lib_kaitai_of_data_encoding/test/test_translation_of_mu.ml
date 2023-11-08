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
  [%expect.unreachable]
[@@expect.uncaught_exn {|
  (* CR expect_test_collector: This test expectation appears to contain a backtrace.
     This is strongly discouraged as backtraces are fragile.
     Please change this test to not include a backtrace. *)

  (Invalid_argument "Mappings.add: duplicate keys (ilist)")
  Raised at Kaitai_of_data_encoding__Helpers.add_uniq_assoc in file "contrib/lib_kaitai_of_data_encoding/helpers.ml", line 71, characters 11-80
  Called from Kaitai_of_data_encoding__Translate.add_type in file "contrib/lib_kaitai_of_data_encoding/translate.ml", line 58, characters 22-60
  Called from Kaitai_of_data_encoding__Translate.redirect in file "contrib/lib_kaitai_of_data_encoding/translate.ml", line 82, characters 14-34
  Called from Kaitai_of_data_encoding__Translate.seq_field_of_data_encoding in file "contrib/lib_kaitai_of_data_encoding/translate.ml", line 430, characters 16-164
  Called from Kaitai_of_data_encoding__Translate.from_data_encoding in file "contrib/lib_kaitai_of_data_encoding/translate.ml", line 827, characters 8-63
  Called from Kaitai_of_data_encoding_test__Test_translation_of_mu.(fun) in file "contrib/lib_kaitai_of_data_encoding/test/test_translation_of_mu.ml", line 11, characters 4-759
  Called from Expect_test_collector.Make.Instance_io.exec in file "collector/expect_test_collector.ml", line 262, characters 12-19 |}]

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
  [%expect.unreachable]
[@@expect.uncaught_exn {|
  (* CR expect_test_collector: This test expectation appears to contain a backtrace.
     This is strongly discouraged as backtraces are fragile.
     Please change this test to not include a backtrace. *)

  (Invalid_argument "Mappings.add: duplicate keys (mt)")
  Raised at Kaitai_of_data_encoding__Helpers.add_uniq_assoc in file "contrib/lib_kaitai_of_data_encoding/helpers.ml", line 71, characters 11-80
  Called from Kaitai_of_data_encoding__Translate.add_type in file "contrib/lib_kaitai_of_data_encoding/translate.ml", line 58, characters 22-60
  Called from Kaitai_of_data_encoding__Translate.redirect in file "contrib/lib_kaitai_of_data_encoding/translate.ml", line 82, characters 14-34
  Called from Kaitai_of_data_encoding__Translate.seq_field_of_union.(fun) in file "contrib/lib_kaitai_of_data_encoding/translate.ml", line 674, characters 14-923
  Called from Stdlib__List.fold_left in file "list.ml", line 121, characters 24-34
  Called from Kaitai_of_data_encoding__Translate.seq_field_of_union in file "contrib/lib_kaitai_of_data_encoding/translate.ml", line 642, characters 4-1023
  Called from Kaitai_of_data_encoding__Translate.seq_field_of_data_encoding in file "contrib/lib_kaitai_of_data_encoding/translate.ml", line 428, characters 33-76
  Called from Kaitai_of_data_encoding__Translate.from_data_encoding in file "contrib/lib_kaitai_of_data_encoding/translate.ml", line 827, characters 8-63
  Called from Kaitai_of_data_encoding_test__Test_translation_of_mu.(fun) in file "contrib/lib_kaitai_of_data_encoding/test/test_translation_of_mu.ml", line 72, characters 4-1023
  Called from Expect_test_collector.Make.Instance_io.exec in file "collector/expect_test_collector.ml", line 262, characters 12-19 |}]
