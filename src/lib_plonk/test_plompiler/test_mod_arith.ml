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
module CS = Plonk.Circuit
module Helpers = Plonk_test.Helpers.Make (Plonk.Main_protocol)

open Plonk_test.Helpers.Utils (LibCircuit)

module AddMod (L : LIB) = struct
  module AddMod = AddMod25519 (L)
  open L

  let add xs ys =
    let x = Utils.z_of_limbs ~base:AddMod.base xs in
    let y = Utils.z_of_limbs ~base:AddMod.base ys in
    let z = Z.(rem (x + y) AddMod.modulus) in
    Utils.z_to_limbs ~base:AddMod.base z

  let random_limb ?(bound = AddMod.base) () =
    let x = S.random () |> S.to_z in
    Z.rem x bound

  let random_modint ?(bound = AddMod.base) () =
    List.init AddMod.nb_limbs (fun _ -> random_limb ~bound ())

  let add_circuit z_exp x y =
    let* z_exp = AddMod.input_mod_int ~kind:`Public (List.map S.of_z z_exp) in
    let* x = AddMod.input_mod_int (List.map S.of_z x) in
    let* y = AddMod.input_mod_int (List.map S.of_z y) in
    let* z = AddMod.add x y in
    (* Can we use assert_equal here ? *)
    assert_equal z z_exp

  (* Adding 2 integers that for sure won’t overflow *)
  let test_add_small () =
    let x = random_modint ~bound:Z.(AddMod.base - one - one) () in
    let y = random_modint ~bound:Z.(AddMod.base - one - one) () in
    (* TODO : I’m pretty sure this is how you’re supposed to get z ; I think the equation must give the output, not whether or not the identity is verified *)
    (* Anyway it seems we can’t access equations from here *)
    let z = add x y in
    add_circuit z x y

  (* Adding 0 doesn’t change the number *)
  let test_add_0 () =
    let x = random_modint () in
    let y = List.init AddMod.nb_limbs (Fun.const Z.zero) in
    let z = add x y in
    assert (List.equal Z.equal z x) ;
    add_circuit z x y

  (* Adding 2 integers that overflow & result in 0 *)
  let test_add_overflow () =
    let x = S.random () |> S.to_z in
    let neg_x = Z.(AddMod.modulus - x) in
    let x = Utils.z_to_limbs ~base:AddMod.base x in
    let neg_x = Utils.z_to_limbs ~base:AddMod.base neg_x in
    let z = add x neg_x in
    assert (List.for_all Z.(equal zero) z) ;
    add_circuit z x neg_x

  (* Having an integer between 2²⁵⁵ & 2²⁵⁵ - 19 & assert it fails at input *)
  let test_add_limit () =
    let x = Z.(AddMod.modulus - (Random.int 19 |> Z.of_int)) in
    let x = Utils.z_to_limbs ~base:AddMod.base x in
    let y = Z.zero |> Utils.z_to_limbs ~base:AddMod.base in
    let z = add x y in
    assert (List.equal Z.equal z x) ;
    add_circuit z x y

  let tests =
    [
      test ~valid:true ~name:"AddMod.test_add_small" test_add_small;
      (* test ~valid:true ~name:"AddMod.test_add_0" test_add_0;
      test ~valid:true ~name:"AddMod.test_add_overflow" test_add_overflow;
      test ~valid:false ~name:"AddMod.test_add_limit" test_add_small; *)
    ]
end

open Plonk_test.Helpers

let tests =
  [
    Alcotest.test_case "AddMod" `Quick (to_test (module AddMod : Test));
    Alcotest.test_case
      "AddMod plonk"
      `Slow
      (to_test ~plonk:(module Plonk.Main_protocol) (module AddMod : Test));
  ]
