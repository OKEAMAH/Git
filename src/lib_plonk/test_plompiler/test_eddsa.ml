(*****************************************************************************)
(*                                                                           *)
(* MIT License                                                               *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
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

(* sk, pk, (pk_u || pk_v), msg, sign, (sign_r_u || sign_r_v), sign_s *)
let test_vectors =
  [
    ( "c5aa8df43f9f837bedb7442f31dcb7b166d38535076f094b85ce3a2e0b4458f7",
      "fc51cd8e6218a1a38da47ed00230f0580816ed13ba3303ac5deb911548908025",
      "02bdcd8654ffa945b9e9e334176f23189885cf8db4d1653f83689ddca23a2161fc51cd8e6218a1a38da47ed00230f0580816ed13ba3303ac5deb911548908025",
      "af82",
      "6291d657deec24024827e69c3abe01a30ce548a284743a445e3680d7db5ac3ac18ff9b538d16f290ae67f760984dc6594a7c15e9716ed28dc027beceea1ec40a",
      "4f445bba8b44933201eda162798f8f091a79b65f2c16dbf9666ef59fd00ea5396291d657deec24024827e69c3abe01a30ce548a284743a445e3680d7db5ac32c",
      "18ff9b538d16f290ae67f760984dc6594a7c15e9716ed28dc027beceea1ec40a" );
  ]

module P = struct
  module Ed25519 = Plompiler.Ed25519
  module P = Ed25519.P
  module Curve = Ed25519.Curve

  let bytes_of_hex = Plompiler.Utils.bytes_of_hex

  let random_bytes len =
    Bytes.init len (fun _i -> Char.chr @@ (Random.bits () mod 255))

  let scalar_to_bytes (s : bytes) : bool list =
    Curve.Scalar.of_bytes_exn s
    |> Curve.Scalar.to_z
    |> Plompiler.Utils.bool_list_of_z ~nb_bits:(Z.numbits Curve.Scalar.order)

  let test_vanilla_ed25519 sk pk_expected msg sign_expected =
    let P.{r = sign_r_expected; s = sign_s_expected} = sign_expected in
    let pk = P.neuterize sk in
    assert (Curve.eq pk pk_expected) ;

    let signature = P.sign sk msg in
    assert (Curve.eq signature.r sign_r_expected) ;
    assert (List.for_all2 Bool.equal signature.s sign_s_expected) ;

    assert (P.verify ~msg ~pk ~signature ()) ;
    Bytes.set msg 0 '\x00' ;
    assert (not @@ P.verify ~msg ~pk ~signature ())

  let test_random () =
    let sk = random_bytes 32 in
    let msg = random_bytes 64 in
    (* TODO: add of_compressed_bytes *)
    (*     let pk = *)
    (*       Hacl_star.Hacl.Ed25519.secret_to_public ~sk |> Curve.of_bytes_exn *)
    (*     in *)
    (*     let signature = *)
    (*       let sign_rs = Hacl_star.Hacl.Ed25519.sign ~sk ~msg in *)
    (*       let sign_r = Bytes.sub sign_rs 0 32 |> Curve.of_bytes_exn in *)
    (*       let sign_s = Bytes.sub sign_rs 32 32 |> scalar_to_bytes in *)
    (*       P.{r = sign_r; s = sign_s} *)
    (*     in *)
    let pk = P.neuterize sk in
    let signature = P.sign sk msg in
    test_vanilla_ed25519 sk pk msg signature

  let test_vectors_ed25519 () =
    List.iter
      (fun (sk, _pk, pk_u_v, msg, _sign, sign_r_u_v, sign_s) ->
        let sk = bytes_of_hex sk in
        let msg = bytes_of_hex msg in
        let pk = bytes_of_hex pk_u_v |> Curve.of_bytes_exn in
        let sign_r = bytes_of_hex sign_r_u_v |> Curve.of_bytes_exn in
        let sign_s = bytes_of_hex sign_s |> scalar_to_bytes in
        test_vanilla_ed25519 sk pk msg P.{r = sign_r; s = sign_s})
      test_vectors

  let test () =
    test_vectors_ed25519 () ;
    test_random ()
end

module Ed25519 (L : LIB) = struct
  open L

  open Utils (L)

  module Ed25519 = Plompiler.Ed25519
  module V = Ed25519.V (L)
  module Curve = Ed25519.Curve
  module Edwards25519 = Plompiler__.Gadget_edwards25519.MakeEdwards25519 (L)
  module ModArith = ArithMod25519 (L)

  let bytes_of_hex = Plompiler.Utils.bytes_of_hex

  let bytes_of_mod_int_circuit ~expected x () =
    let* z_exp = input ~kind:`Public expected in
    let* x = ModArith.input_mod_int x in
    let* z = ModArith.bytes_of_mod_int ~padded:true x in
    assert_equal z_exp z

  let tests_bytes_of_mod_int =
    List.map
      (fun (x, expected, valid) ->
        let name = "ModArith.test_bytes_of_mod_int" in
        let expected = Bytes.input_bytes ~le:true @@ bytes_of_hex expected in
        test ~valid ~name (bytes_of_mod_int_circuit ~expected x))
      [
        ( Z.of_string
            "16962727616734173323702303146057009569815335830970791807500022961899349823996",
          "fc51cd8e6218a1a38da47ed00230f0580816ed13ba3303ac5deb911548908025",
          true );
      ]

  let bytes_of_point_circuit ~expected p () =
    let* z_exp = input ~kind:`Public expected in
    let* p = input ~kind:`Public @@ V.Encoding.pk_encoding.input p in
    let* z = Edwards25519.bytes_of_point p in
    assert_equal z z_exp

  let tests_bytes_of_point =
    List.map
      (fun (x, expected, valid) ->
        let name = "Ed25519.bytes_of_point" in
        let expected = Bytes.input_bytes ~le:true @@ bytes_of_hex expected in
        let x = Curve.of_bytes_exn @@ bytes_of_hex x in
        test ~valid ~name (bytes_of_point_circuit ~expected x))
      [
        ( "02bdcd8654ffa945b9e9e334176f23189885cf8db4d1653f83689ddca23a2161fc51cd8e6218a1a38da47ed00230f0580816ed13ba3303ac5deb911548908025",
          "fc51cd8e6218a1a38da47ed00230f0580816ed13ba3303ac5deb911548908025",
          true );
        ( "4f445bba8b44933201eda162798f8f091a79b65f2c16dbf9666ef59fd00ea5396291d657deec24024827e69c3abe01a30ce548a284743a445e3680d7db5ac32c",
          "6291d657deec24024827e69c3abe01a30ce548a284743a445e3680d7db5ac3ac",
          true );
      ]

  (*   let nb_bits = Z.numbits Curve.Base.order *)

  (*   let test_circuit_verify pk msg signature () = *)
  (*     let msg = Bytes.input_bytes msg in *)
  (*     with_label ~label:"EdDSCurve.test" *)
  (*     @@ let* pk = input ~kind:`Public @@ V.Encoding.pk_encoding.input pk in *)
  (*        let* msg = input msg in *)
  (*        let* signature = *)
  (*          input @@ V.Encoding.signature_encoding.input signature *)
  (*        in *)
  (*        let signature = V.Encoding.signature_encoding.decode signature in *)
  (*        with_label ~label:"with_bool_check" *)
  (*        @@ with_bool_check (V.verify ~msg ~pk ~signature ()) *)

  (*   let tests_ed25519 = *)
  (*     List.map *)
  (*       (fun (sk, pk_expected, _pk_u_v, msg, _sign, _sign_r_u_v, _sign_s) -> *)
  (*         let msg = bytes_of_hex msg in *)
  (*         let sk = bytes_of_hex sk in *)
  (*         let pk_expected = bytes_of_hex pk_expected in *)
  (*         let pk = Ed25519.P.neuterize sk in *)
  (*         let _signature = Ed25519.P.sign sk msg in *)
  (*         test *)
  (*           ~valid:true *)
  (*           ~name:"Ed25519.test_circuit_verify" *)
  (*             (\* (test_circuit_verify pk msg signature) *\) *)
  (*           (test_bytes_of_point pk pk_expected)) *)
  (*       test_vectors *)

  let tests = tests_bytes_of_mod_int @ tests_bytes_of_point
end

let tests =
  [
    Alcotest.test_case "P" `Quick P.test;
    Alcotest.test_case "Ed25519" `Quick (to_test (module Ed25519 : Test));
    (*     Alcotest.test_case *)
    (*       "Ed25519 plonk" *)
    (*       `Slow *)
    (*       (to_test ~plonk:(module Plonk.Main_protocol) (module Ed25519 : Test)); *)
  ]
