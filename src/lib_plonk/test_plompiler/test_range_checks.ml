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
module CS = Plonk.Circuit
module Helpers = Plonk_test.Helpers.Make (Plonk.Main_protocol)
open Plonk_test.Helpers.Plompiler_Helpers

module RangeChecks (L : LIB) = struct
  open L

  open Plonk_test.Helpers.Plompiler_Helpers.Utils (L)

  (* compute intermediary products of w 2 by 2 and perform a range check
     on the resulting product with the sum of the term’s bounds *)
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

  (* This circuit computes all 2 by 2 sums of w, performing a range check on each intermediary sum.
     It then compares the resulting sum to the [y] public input. This circuit
     performs several additions in order to test the optimizer
     (addition is one of the operations that are touched by the optimizer). *)
  let build_circuit bounds w y () =
    let* expected = input ~kind:`Public (Input.scalar y) in
    let* w = mapM input (List.map Input.scalar w) in
    let* sum = all_sums (w, bounds) in
    iter2M (fun nb_bits w -> Num.range_check ~nb_bits w) bounds w
    >* with_bool_check (equal sum expected)

  (* This function tests the range-checks implementation in Plompiler with the
     previous circuit. It performs 3 tests
     - Sat & PlonK with valid range-checks without the optimizer
     - Sat & PlonK with valid range-checks with the optimizer
     - Negative test : PlonK with invalid range-checks
  *)
  let tests =
    let n = 1 lsl (1 + Random.int 3) in
    let bounds = List.init (1 lsl n) (fun _ -> 1 + Random.int 5) in
    let w =
      List.map (fun bound -> S.of_int (Random.int (1 lsl bound))) bounds
    in
    let y = S.add_bulk w in
    (* Invalid range-check case *)
    let fst_invalid = List.(S.(hd w + S.of_int (1 lsl hd bounds))) in
    let snd_invalid = List.(S.(nth w 1 + S.of_int (1 lsl nth bounds 1))) in
    let invalid = fst_invalid :: snd_invalid :: List.(tl (tl w)) in
    let y_invalid = S.add_bulk invalid in
    [
      test ~valid:true ~name:"Range-checks" (build_circuit bounds w y);
      test
        ~valid:false
        ~name:"Range-checks.Invalid"
        (build_circuit bounds invalid y_invalid);
    ]
end

let tests =
  [
    Alcotest.test_case "Range-check" `Quick (to_test (module RangeChecks : Test));
    Alcotest.test_case
      "Range-check plonk"
      `Slow
      (to_test ~plonk:(module Plonk.Main_protocol) (module RangeChecks : Test));
  ]
