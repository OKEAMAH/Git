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
open LibCircuit
module CS = Plonk.Circuit
module Hash = Poseidon128.V (LibCircuit)
module Helpers = Plonk_test.Helpers.Make (Plonk.Main_protocol)

open Plonk_test.Helpers.Utils (LibCircuit)

module ArithMod = ArithMod25519

let random_limb bound =
  Random.nativeint (Z.to_nativeint bound) |> Z.of_nativeint

(* Adding 2 integers that won’t overflow *)
let test_add_small () =
  let x = List.init ArithMod.nb_limbs (fun _ -> random_limb Z.(ArithMod.base - one - one)) in
  let y = List.init ArithMod.nb_limbs (fun _ -> random_limb Z.(ArithMod.base - one - one)) in
  let _ = ArithMod.add x y in ()

  

(* Adding 2 integers that overflow & result in 0 *)

(* Having an integer between 2²⁵⁵ & 2²⁵⁵ - 19 & assert it fails *)


let tests = [Alcotest.test_case "Add small" `Quick test_add_small]