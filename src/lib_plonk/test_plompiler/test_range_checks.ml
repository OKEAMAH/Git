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

let hash array =
  let ctx = Poseidon128.P.init ~input_length:(Array.length array) () in
  let ctx = Poseidon128.P.digest ctx array in
  Poseidon128.P.get ctx

(* compute intermediary products of w to by to and perform a range check on the resulting product with the sum of the term’s bounds *)
let sums_2_by_2 (w, b) =
  let rec aux (acc, bacc) = function
    | a :: b :: tl, ba :: bb :: btl ->
        let* c = Num.add a b in
        let nb_bits = max ba bb + 1 in
        Num.range_check ~nb_bits c >* aux (c :: acc, nb_bits :: bacc) (tl, btl)
    | [], [] -> ret (List.rev acc, List.rev bacc)
    | _ -> assert false
  in
  aux ([], []) (w, b)

let rec all_sums wb =
  let* p = sums_2_by_2 wb in
  match p with [p], [_] -> ret p | _ -> all_sums p

(* This circuit computes all 2 by 2 sums of w, perfoming a range check on each intermediary sum ; it then compare the hash of the resulting sum & inputs to the [y] public input. the final hash is performed to have more room for range checks *)
let build_circuit bounds w y () =
  let* expected = input ~kind:`Public (Input.scalar y) in
  let* w = mapM input (List.map Input.scalar w) in
  let* product = all_sums (w, bounds) in
  let* out =
    Hash.digest ~input_length:(1 + List.length w) (to_list (product :: w))
  in
  with_bool_check (equal out expected)

let test_range_checks () =
  let n = 4 in
  let bounds = List.init (1 lsl n) (fun _ -> 1 + Random.int 5) in
  Printf.printf
    "\nbounds = [%s]"
    (String.concat ", " (List.map (Printf.sprintf "%d") bounds)) ;
  let w = List.map (fun bound -> s_of_int (Random.int (1 lsl bound))) bounds in
  let y = hash (Array.of_list (S.add_bulk w :: w)) in
  let circuit = build_circuit bounds w y () in
  (* TODO: make optimizer compatible with range checks *)
  let cs = get_cs ~optimize:false circuit in
  let plonk_circuit = Plonk.Circuit.to_plonk cs in
  let private_inputs = Solver.solve cs.solver (Array.of_list (y :: w)) in
  assert (CS.sat cs.cs [] private_inputs) ;
  Helpers.test_circuit ~name:"" plonk_circuit private_inputs ;
  (* TODO make optimized circuit provable *)
  (* let o_cs = get_cs ~optimize:true circuit in
     let o_circuit = Plonk.Circuit.to_plonk o_cs in
     let o_private_inputs = Solver.solve o_cs.solver (Array.of_list (y :: w)) in
     Helpers.test_circuit ~name:"" o_circuit o_private_inputs ; *)
  let fst_invalid = List.(S.(hd w + s_of_int (1 lsl hd bounds))) in
  let snd_invalid = List.(S.(nth w 1 + s_of_int (1 lsl nth bounds 1))) in
  let invalid = fst_invalid :: snd_invalid :: List.(tl (tl w)) in
  let y = hash (Array.of_list (S.mul_bulk invalid :: invalid)) in
  let private_inputs = Solver.solve cs.solver (Array.of_list (y :: invalid)) in
  (* assert (not (CS.sat cs.cs [] private_inputs)) ; *)
  Helpers.test_circuit
    ~outcome:Plonk_test.Cases.Proof_error
    ~name:""
    plonk_circuit
    private_inputs

let tests = [Alcotest.test_case "Range-check" `Quick test_range_checks]
