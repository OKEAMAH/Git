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

let s_of_int i = S.of_z (Z.of_int i)

let random_s bound = S.of_z (Z.of_int (Random.int (1 lsl bound)))

let hash array =
  let ctx = Poseidon128.P.init ~input_length:(Array.length array) () in
  let ctx = Poseidon128.P.digest ctx array in
  Poseidon128.P.get ctx

let bound1 = 1 + Random.int 28

let bound2 = 1 + Random.int 28

let bound3 = 1 + Random.int 28

let bound4 = 1 + Random.int 28

let build_circuit x1 x2 x3 x4 y () =
  let* expected = input ~kind:`Public (Input.scalar y) in
  let* x1 = input (Input.scalar x1) in
  let* x2 = input (Input.scalar x2) in
  let* x3 = input (Input.scalar x3) in
  let* x4 = input (Input.scalar x4) in
  Num.range_check ~nb_bits:bound1 x1
  >* Num.range_check ~nb_bits:bound2 x2
  >* Num.range_check ~nb_bits:bound3 x3
  >* Num.range_check ~nb_bits:bound4 x4
  >* let* out = Hash.digest ~input_length:4 (to_list [x1; x2; x3; x4]) in
     with_bool_check (equal out expected)

let test_range_checks () =
  let w1 = random_s bound1 in
  let w2 = random_s bound2 in
  let w3 = random_s bound3 in
  let w4 = random_s bound4 in
  let y = hash [|w1; w2; w3; w4|] in
  let circuit = build_circuit w1 w2 w3 w4 y () in
  (* TODO: make optimizer compatible with range checks *)
  let cs = get_cs ~optimize:true circuit in
  let plonk_circuit = Plonk.Circuit.to_plonk cs in
  let private_inputs = Solver.solve cs.solver [|y; w1; w2; w3; w4|] in
  assert (CS.sat cs.cs [] private_inputs) ;
  Helpers.test_circuit ~name:"" plonk_circuit private_inputs

let tests = [Alcotest.test_case "Range-check" `Quick test_range_checks]
