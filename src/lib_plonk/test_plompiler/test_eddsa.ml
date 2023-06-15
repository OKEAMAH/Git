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

(* open Plompiler *)

(* open Plonk_test *)
module CS = Plonk.Circuit
(* open Helpers *)

module P = struct
  module Ed25519 = Plompiler.Ed25519
  module P = Ed25519.P
  module Curve = Ed25519.Curve

  let test_vanilla_ed25519 sk pk_expected msg sign_r_expected sign_s_expected =
    (*     let pk = Hacl_star.Hacl.Ed25519.secret_to_public ~sk in *)

    (*     (\*     Printf.printf "\n pk_computed = %s \n" (Hex.show (Hex.of_bytes pk)) ; *\) *)
    (*     (\*     Printf.printf "\n pk_expected = %s \n" (Hex.show (Hex.of_bytes pk_expected)) ; *\) *)
    (*     assert (Bytes.equal pk pk_expected) ; *)
    (*     let signature = Hacl_star.Hacl.Ed25519.sign ~sk ~msg in *)

    (*     (\*     Printf.printf "\n sign_computed = %s \n" (Hex.show (Hex.of_bytes signature)) ; *\) *)
    (*     (\*     Printf.printf *\) *)
    (*     (\*       "\n sign_expected = %s \n" *\) *)
    (*     (\*       (Hex.show (Hex.of_bytes signature_expected)) ; *\) *)
    (*     assert (Bytes.equal signature signature_expected) ; *)
    (*     assert (Hacl_star.Hacl.Ed25519.verify ~pk ~msg ~signature) ; *)
    let pk = P.neuterize sk in
    assert (Bytes.equal (Curve.to_bytes pk) pk_expected) ;
    assert (Curve.eq pk (Curve.of_bytes_exn pk_expected)) ;

    (*     Printf.printf "\n pk_expected = %s \n" (Hex.show (Hex.of_bytes pk_expected)) ; *)
    (*     Printf.printf *)
    (*       "\n pk_computed = %s \n" *)
    (*       (Hex.show (Hex.of_bytes (Curve.to_bytes pk))) *)

    (*     assert (Curve.eq pk pk_expected) ; *)
    let signature = P.sign ~compressed:true sk msg in
    assert (Bytes.equal (Curve.to_bytes signature.r) sign_r_expected) ;
    assert (Curve.eq signature.r (Curve.of_bytes_exn sign_r_expected)) ;

    let sign_s_expected =
      Curve.Scalar.of_bytes_exn sign_s_expected
      |> Curve.Scalar.to_z
      |> Plompiler.Utils.bool_list_of_z ~nb_bits:(Z.numbits Curve.Scalar.order)
    in

    assert (List.for_all2 Bool.equal signature.s sign_s_expected) ;

    assert (P.verify ~compressed:true ~msg ~pk ~signature ()) ;
    Bytes.set msg 0 '\x00' ;
    assert (not @@ P.verify ~msg ~pk ~signature ())

  (*     Printf.printf *)
  (*       "\n sign_computed = %s \n" *)
  (*       (Hex.show (Hex.of_bytes (Curve.to_bytes signature.r))) ; *)
  (*     Printf.printf *)
  (*       "\n sign_computed = %s \n" *)
  (*       (Hex.show (Hex.of_bytes sign_r_expected)) ; *)
  (*     Printf.printf *)
  (*       "\n sign_s_expected = %s \n" *)
  (*       (Hex.show (Hex.of_bytes sign_s_expected)) ; *)
  (*     let sign_s = *)
  (*       Plompiler.Utils.bool_list_to_z signature.s |> Z.to_bits |> Bytes.of_string *)
  (*     in *)
  (*     Printf.printf "\n sign_s_computed = %s \n" (Hex.show (Hex.of_bytes sign_s)) ; *)
  (* assert (1 = 0) *)

  (*     assert (Curve.eq signature.r signature_expected.r) ; *)
  (*     assert (List.for_all2 Bool.equal signature.s signature_expected.s) ; *)
  (*     assert (P.verify ~msg ~pk ~signature ()) ; *)
  (*     let msg = S.(to_bytes @@ random ()) in *)
  (*     assert (not @@ P.verify ~msg ~pk ~signature ()) *)

  (* sk, pk, (pk_u || pk_v), msg, sign, (sign_r_u || sign_r_v) sign_s *)
  (* p = 2^255-19 + 1 bit for sign -> (sign(x) || y) *)
  let test_vectors =
    [
      ( "\xc5\xaa\x8d\xf4\x3f\x9f\x83\x7b\xed\xb7\x44\x2f\x31\xdc\xb7\xb1\x66\xd3\x85\x35\x07\x6f\x09\x4b\x85\xce\x3a\x2e\x0b\x44\x58\xf7",
        "\xfc\x51\xcd\x8e\x62\x18\xa1\xa3\x8d\xa4\x7e\xd0\x02\x30\xf0\x58\x08\x16\xed\x13\xba\x33\x03\xac\x5d\xeb\x91\x15\x48\x90\x80\x25",
        "\x02\xbd\xcd\x86\x54\xff\xa9\x45\xb9\xe9\xe3\x34\x17\x6f\x23\x18\x98\x85\xcf\x8d\xb4\xd1\x65\x3f\x83\x68\x9d\xdc\xa2\x3a\x21\x61\xfc\x51\xcd\x8e\x62\x18\xa1\xa3\x8d\xa4\x7e\xd0\x02\x30\xf0\x58\x08\x16\xed\x13\xba\x33\x03\xac\x5d\xeb\x91\x15\x48\x90\x80\x25",
        "\xaf\x82",
        "\x62\x91\xd6\x57\xde\xec\x24\x02\x48\x27\xe6\x9c\x3a\xbe\x01\xa3\x0c\xe5\x48\xa2\x84\x74\x3a\x44\x5e\x36\x80\xd7\xdb\x5a\xc3\xac\x18\xff\x9b\x53\x8d\x16\xf2\x90\xae\x67\xf7\x60\x98\x4d\xc6\x59\x4a\x7c\x15\xe9\x71\x6e\xd2\x8d\xc0\x27\xbe\xce\xea\x1e\xc4\x0a",
        "\x4f\x44\x5b\xba\x8b\x44\x93\x32\x01\xed\xa1\x62\x79\x8f\x8f\x09\x1a\x79\xb6\x5f\x2c\x16\xdb\xf9\x66\x6e\xf5\x9f\xd0\x0e\xa5\x39\x62\x91\xd6\x57\xde\xec\x24\x02\x48\x27\xe6\x9c\x3a\xbe\x01\xa3\x0c\xe5\x48\xa2\x84\x74\x3a\x44\x5e\x36\x80\xd7\xdb\x5a\xc3\x2c",
        "\x18\xff\x9b\x53\x8d\x16\xf2\x90\xae\x67\xf7\x60\x98\x4d\xc6\x59\x4a\x7c\x15\xe9\x71\x6e\xd2\x8d\xc0\x27\xbe\xce\xea\x1e\xc4\x0a"
      );
    ]

  (*   let test_random = *)
  (*     let sk = Curve.Scalar.random () in *)
  (*     let msg = S.(to_bytes @@ random ()) in *)
  (*     let pk = P.neuterize sk in *)
  (*     let signature = P.sign sk msg in *)
  (*     test_vanilla_ed25519 sk pk msg signature *)

  let tests =
    List.iter
      (fun (sk, _pk, pk_u_v, msg, _sign, sign_r_u_v, sign_s) ->
        (*         let sk = Curve.Scalar.of_string @@ Z.(to_bits (of_string sk)) in *)
        (*         (\*         let pk = *\) *)
        (*         (\*           Curve.from_coordinates_exn *\) *)
        (*         (\*             ~u:(Curve.Base.of_string pk_u) *\) *)
        (*         (\*             ~v:(Curve.Base.of_string pk_v) *\) *)
        (*         (\*         in *\) *)
        (*         let pk = *)
        (*           let pk_bytes = *)
        (*             Bytes.concat *)
        (*               Bytes.empty *)
        (*               [ *)
        (*                 (Bytes.of_string @@ Z.(to_bits (of_string pk_u))); *)
        (*                 (Bytes.of_string @@ Z.(to_bits (of_string pk_v))); *)
        (*               ] *)
        (*           in *)
        (*           Curve.of_bytes_exn pk_bytes *)
        (*         in *)
        (*         (\*         let sign_r = *\) *)
        (*         (\*           Curve.from_coordinates_exn *\) *)
        (*         (\*             ~u:(Curve.Base.of_string sign_r_u) *\) *)
        (*         (\*             ~v:(Curve.Base.of_string sign_r_v) *\) *)
        (*         (\*         in *\) *)
        (*         let sign_r = *)
        (*           let sign_r_bytes = *)
        (*             Bytes.concat *)
        (*               Bytes.empty *)
        (*               [ *)
        (*                 (Bytes.of_string @@ Z.(to_bits (of_string sign_r_u))); *)
        (*                 (Bytes.of_string @@ Z.(to_bits (of_string sign_r_v))); *)
        (*               ] *)
        (*           in *)
        (*           Curve.of_bytes_exn sign_r_bytes *)
        (*         in *)

        (*         let sign_s = *)
        (*           Curve.Scalar.of_string sign_s *)
        (*           |> Curve.Scalar.to_z *)
        (*           |> Utils.bool_list_of_z ~nb_bits:(Z.numbits Curve.Scalar.order) *)
        (*         in *)
        (*         let sign : P.signature = {r = sign_r; s = sign_s} in *)
        let sk = Bytes.of_string sk in
        let msg = Bytes.of_string msg in
        let pk = Bytes.of_string pk_u_v in
        let sign_r = Bytes.of_string sign_r_u_v in
        let sign_s = Bytes.of_string sign_s in
        test_vanilla_ed25519 sk pk msg sign_r sign_s)
      test_vectors

  let test () = tests
end

(* module Ed25519 (L : LIB) = struct *)
(*   open L *)

(*   open Utils (L) *)

(*   (\* open Plompiler *\) *)
(*   (\* module Ed25519 = Plompiler.Ed25519 (Plompiler.Anemoi128) *\) *)
(*   (\* Ça plante visiblement sur le is on curve de l’input générateur ; je suppose qu’on a un problème de modulo *\) *)
(*   (\* module Ed25519 = Plompiler.EdDSA_Jubjub (Plompiler.Poseidon128) *\) *)
(*   module Ed25519 = Plompiler.EdDSA_Jubjub (Plompiler.Anemoi128) *)
(*   module Sc = Ed25519.V (L) *)
(*   module A = Ed25519.Curve *)

(*   let nb_bits = Z.numbits A.Base.order *)

(*   let wrong_s = *)
(*     Plompiler.Utils.bool_list_of_z ~nb_bits *)
(*     @@ A.Scalar.to_z @@ A.Scalar.random () *)

(*   let test_circuit_verify g pk msg signature () = *)
(*     let msg = Input.scalar msg in *)
(*     with_label ~label:"EdDSA.test" *)
(*     @@ let* g = input ~kind:`Public g in *)
(*        let* pk = input ~kind:`Public @@ Sc.Encoding.pk_encoding.input pk in *)
(*        let* msg = input msg in *)
(*        let* signature = *)
(*          input @@ Sc.Encoding.signature_encoding.input signature *)
(*        in *)
(*        let signature = Sc.Encoding.signature_encoding.decode signature in *)

(*        with_label ~label:"with_bool_check" *)
(*        @@ with_bool_check (Sc.verify ~g ~msg ~pk ~signature ()) *)

(*   let tests = *)
(*     let g = Sc.Encoding.pk_encoding.input A.one in *)
(*     let sk = A.Scalar.random () in *)
(*     let msg = S.random () in *)
(*     let pk = Ed25519.P.neuterize sk in *)
(*     let signature = Ed25519.P.sign sk msg in *)
(*     [ *)
(*       test *)
(*         ~valid:true *)
(*         ~name:"Ed25519.test_circuit_verify" *)
(*         (test_circuit_verify g pk msg signature); *)
(*       test *)
(*         ~valid:false *)
(*         ~name:"Ed25519.test_circuit_verify" *)
(*         (test_circuit_verify g pk msg {signature with s = wrong_s}); *)
(*     ] *)
(* end *)

let tests =
  [
    Alcotest.test_case "P" `Quick P.test;
    (*     Alcotest.test_case "Ed25519" `Quick (to_test (module Ed25519 : Test)); *)
    (*     Alcotest.test_case *)
    (*       "Ed25519 plonk" *)
    (*       `Slow *)
    (*       (to_test ~plonk:(module Plonk.Main_protocol) (module Ed25519 : Test)); *)
  ]
