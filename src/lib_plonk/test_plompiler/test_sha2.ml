(*****************************************************************************)
(*                                                                           *)
(* MIT License                                                               *)
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

open Plompiler
open Plonk_test
module CS = Plonk.Circuit
open Helpers

module Internal : Test =
functor
  (L : LIB)
  ->
  struct
    open L
    open L.Bytes

    open Utils (L)

    module H = Plompiler.Sha256 (L)

    let bytes_of_hex = Plompiler.Utils.bytes_of_hex

    let test_ch a b c z () =
      let* a = input ~kind:`Public a in
      let* b = input b in
      let* c = input c in
      let* z = input z in
      let* z' = H.ch a b c in
      assert_equal z z'

    let tests_ch =
      let i0 = input_bytes @@ bytes_of_hex "11" in
      let i1 = input_bytes @@ bytes_of_hex "13" in
      let i2 = input_bytes @@ bytes_of_hex "2A" in
      let o = input_bytes @@ bytes_of_hex "3B" in
      [
        test ~valid:true ~name:"SHA256.test_ch" @@ test_ch i0 i1 i2 o;
        test ~valid:false ~name:"SHA256.test_ch" @@ test_ch i0 i1 i2 i2;
      ]

    let test_maj a b c z () =
      let* a = input ~kind:`Public a in
      let* b = input b in
      let* c = input c in
      let* z = input z in
      let* z' = H.maj a b c in
      assert_equal z z'

    let tests_maj =
      let i0 = input_bytes @@ bytes_of_hex "11" in
      let i1 = input_bytes @@ bytes_of_hex "13" in
      let i2 = input_bytes @@ bytes_of_hex "2A" in
      let o = input_bytes @@ bytes_of_hex "13" in
      [
        test ~valid:true ~name:"SHA256.test_maj" @@ test_maj i0 i1 i2 o;
        test ~valid:false ~name:"SHA256.test_maj" @@ test_maj i0 i1 i2 i2;
      ]

    let test_sigma0 a z () =
      let* a = input ~kind:`Public a in
      let* z = input z in
      let* z' = H.sigma_0 a in
      assert_equal z z'

    let tests_sigma0 =
      let i = input_bytes @@ bytes_of_hex "0000002A" in
      let o = input_bytes @@ bytes_of_hex "540A8005" in
      [
        test ~valid:true ~name:"SHA256.test_sigma0" @@ test_sigma0 i o;
        test ~valid:false ~name:"SHA256.test_sigma0" @@ test_sigma0 i i;
      ]

    let test_sigma1 a z () =
      let* a = input ~kind:`Public a in
      let* z = input z in
      let* z' = H.sigma_1 a in
      assert_equal z z'

    let tests_sigma1 =
      let i = input_bytes @@ bytes_of_hex "0000002A" in
      let o = input_bytes @@ bytes_of_hex "00104000" in
      [
        test ~valid:true ~name:"SHA256.test_sigma1" @@ test_sigma1 i o;
        test ~valid:false ~name:"SHA256.test_sigma1" @@ test_sigma1 i i;
      ]

    let test_sum0 a z () =
      let* a = input ~kind:`Public a in
      let* z = input z in
      let* z' = H.sum_0 a in
      assert_equal z z'

    let tests_sum0 =
      let i = input_bytes @@ bytes_of_hex "00000001" in
      let o = input_bytes @@ bytes_of_hex "40080400" in
      [
        test ~valid:true ~name:"SHA256.test_sum0" @@ test_sum0 i o;
        test ~valid:false ~name:"SHA256.test_sum0" @@ test_sum0 i i;
      ]

    let test_sum1 a z () =
      let* a = input ~kind:`Public a in
      let* z = input z in
      let* z' = H.sum_1 a in
      assert_equal z z'

    let tests_sum1 =
      let i = input_bytes @@ bytes_of_hex "00000001" in
      let o = input_bytes @@ bytes_of_hex "04200080" in
      [
        test ~valid:true ~name:"SHA256.test_sum1" @@ test_sum1 i o;
        test ~valid:false ~name:"SHA256.test_sum1" @@ test_sum1 i i;
      ]

    let tests =
      tests_ch @ tests_maj @ tests_sigma0 @ tests_sigma1 @ tests_sum0
      @ tests_sum1
  end

module External : Test =
functor
  (L : LIB)
  ->
  struct
    (* open L *)

    open Utils (L)

    let tests = []
  end

let tests =
  let both =
    [
      ("Internal", (module Internal : Test));
      ("External", (module External : Test));
    ]
  in
  (* This test uses plonk and it is marked quick so that it
     is always run by the CI *)
  List.map (fun (name, m) -> Alcotest.test_case name `Quick (to_test m)) both
  @ List.map
      (fun (name, m) ->
        Alcotest.test_case
          (name ^ " plonk")
          `Slow
          (to_test ~plonk:(module Plonk.Main_protocol) m))
      both
