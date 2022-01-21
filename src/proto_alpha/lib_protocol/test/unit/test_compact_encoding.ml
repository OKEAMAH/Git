(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
(*                                                                           *)
(* Permission is hereby granted, free of charge, to any person obtaining a   *)
(* copy of this software and associated documentation files (the "Software"),*)
(* to deal in the Software without restriction, including without limitation *)
(* the rights to use, copy, modify, merge, publish, distribute, sublicense,  *)
(* and/or sell copies of the Software, and to permit persons to whom the     *)
(* Software is furnished to do so, subject to the following conditions:      *)
(*                                                                           *)
(* The above copyright notice and this permission notice shall be included   *)
(* in all copies or substantial portions of the Software.                    *)
(*                                                                           *)
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR*)
(* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  *)
(* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL   *)
(* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER*)
(* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING   *)
(* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER       *)
(* DEALINGS IN THE SOFTWARE.                                                 *)
(*                                                                           *)
(*****************************************************************************)

(** Testing
    -------
    Component:  Protocol (compact_encoding)
    Invocation: dune exec src/proto_alpha/lib_protocol/test/unit/main.exe \
                -- test "compact encoding"
    Subject:    Test compact encodings.
*)

open Tztest
open Protocol.Compact_encoding

let check_payload equ encoding input expected_binary_size =
  let open Data_encoding.Binary in
  let buffer = to_bytes_exn encoding input in
  let computed = Bytes.length buffer in
  let output = of_bytes_exn encoding buffer in

  Alcotest.(check equ "round-trip" input output) ;

  (* We remove one to the buffer length because we are interested in
     the payload size. *)
  Alcotest.(check int "binary output size" expected_binary_size (computed - 1))

let test_encoding_payload_size () =
  let check_int32 : int32 * int -> unit =
   fun (input, size) -> check_payload Alcotest.int32 compact_int32 input size
  in

  let check_int64 : int64 * int -> unit =
   fun (input, size) -> check_payload Alcotest.int64 compact_int64 input size
  in

  (* Check upper bounds of [compact_int32]. *)
  List.iter check_int32 [(255l, 1); (65535l, 2); (Int32.max_int, 4); (-200l, 4)] ;

  (* Check upper bounds of [compact_int64]. *)
  List.iter
    check_int64
    [(255L, 1); (65535L, 2); (4294967295L, 4); (Int64.max_int, 8); (-200L, 8)] ;

  (* Check [bool] do not use any payload *)
  check_payload
    Alcotest.(pair bool bool)
    (make @@ tup2 bool bool)
    (true, false)
    0 ;

  (* Check [list n] do not prefix the payload by the size for small lists. *)
  check_payload
    Alcotest.(list int)
    (make @@ list 4 Data_encoding.int31)
    [1; 2; 3]
    12 ;

  (* Check [list n] compose well with other compact encoding. *)
  check_payload
    Alcotest.(list int32)
    (make @@ list 4 compact_int32)
    [1l; 300l; 70000l]
    (3 (*inner tags*) + 1 + 2 + 4) ;

  return_unit

let tests =
  [
    tztest
      "check the size of the compact data encoding payloads"
      `Quick
      test_encoding_payload_size;
  ]
