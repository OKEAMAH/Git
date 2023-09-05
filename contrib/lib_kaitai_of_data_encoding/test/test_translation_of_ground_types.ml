(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Marigold, <contact@marigold.dev>                       *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

(* This test suite is meant to test translation of ground encodings
   to [Kaitai.Types.ClassSpec.t] *)

let%expect_test "test uint8 translation" =
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~encoding_name:"ground_uint8"
      Data_encoding.uint8
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect
    {|
    meta:
      id: ground_uint8
    seq:
    - id: uint8
      type: u1
  |}]

let%expect_test "test bool translation" =
  let s =
    Kaitai_of_data_encoding.Translate.from_data_encoding
      ~encoding_name:"ground_bool"
      Data_encoding.bool
  in
  print_endline (Kaitai.Print.print s) ;
  [%expect
    {|
    meta:
      id: ground_bool
    enums:
      bool:
        0: false
        255: true
    seq:
    - id: bool
      type: u1
      enum: bool
  |}]