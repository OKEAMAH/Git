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

module P = struct
  (* https://github.com/dusk-network/jubjub/blob/052ac22bc69403171ad1e32c3332b7510891419a/src/lib.rs#L121 *)

  module Ed25519 = Plompiler.Ed25519 (Plompiler.Anemoi128)
  module P = Ed25519.P
  module A = Ed25519.Curve

  let test_vanilla_ed25519 () =
    let sk = A.Scalar.random () in
    let msg = S.random () in
    let pk = P.neuterize sk in
    let signature = P.sign sk msg in
    assert (P.verify ~msg ~pk ~signature ()) ;
    let msg = S.random () in
    assert (not @@ P.verify ~msg ~pk ~signature ())

  let test = test_vanilla_ed25519
end

module Ed25519 (L : LIB) = struct
  open L

  open Utils (L)

  (* open Plompiler *)
  (* module Ed25519 = Plompiler.Ed25519 (Plompiler.Anemoi128) *)
  (* Ça plante visiblement sur le is on curve de l’input générateur ; je suppose qu’on a un problème de modulo *)
  (* module Ed25519 = Plompiler.EdDSA_Jubjub (Plompiler.Poseidon128) *)
  module Ed25519 = Plompiler.EdDSA_Jubjub (Plompiler.Anemoi128)
  module Sc = Ed25519.V (L)
  module A = Ed25519.Curve

  let nb_bits = Z.numbits A.Base.order

  let wrong_s =
    Plompiler.Utils.bool_list_of_z ~nb_bits
    @@ A.Scalar.to_z @@ A.Scalar.random ()

  let test_circuit_verify g pk msg signature () =
    let msg = Input.scalar msg in
    with_label ~label:"EdDSA.test"
    @@ let* g = input ~kind:`Public g in
       let* pk = input ~kind:`Public @@ Sc.Encoding.pk_encoding.input pk in
       let* msg = input msg in
       let* signature =
         input @@ Sc.Encoding.signature_encoding.input signature
       in
       let signature = Sc.Encoding.signature_encoding.decode signature in

       with_label ~label:"with_bool_check"
       @@ with_bool_check (Sc.verify ~g ~msg ~pk ~signature ())
  (* let _ = Sc.verify ~g ~msg ~pk ~signature () in *)
  (* with_label ~label:"g"
       @@
     assert_equal g g *)

  (* let* t = (constant_bool true) in Bool.assert_true t *)

  let tests =
    let g = Sc.Encoding.pk_encoding.input A.one in
    let sk = A.Scalar.random () in
    let msg = S.random () in
    let pk = Ed25519.P.neuterize sk in
    let signature = Ed25519.P.sign sk msg in
    [
      test
        ~valid:true
        ~name:"Ed25519.test_circuit_verify"
        (test_circuit_verify g pk msg signature);
      test
        ~valid:false
        ~name:"Ed25519.test_circuit_verify"
        (test_circuit_verify g pk msg {signature with s = wrong_s});
    ]
end

let tests =
  [
    Alcotest.test_case "P" `Quick P.test;
    Alcotest.test_case "Ed25519" `Quick (to_test (module Ed25519 : Test));
    Alcotest.test_case
      "Ed25519 plonk"
      `Slow
      (to_test ~plonk:(module Plonk.Main_protocol) (module Ed25519 : Test));
  ]
