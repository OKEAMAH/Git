(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
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

open Wasm_utils
module Context = Tezos_context_memory.Context_binary

(* Test that one N-ticks executions(^1) and N one-tick executions(^2)
   are equivalent.

   (^1): Executing in one decoding-encoding loop N ticks.
   (^2): Executing one decoding-encoding loop per ticks. *)
let test_execution_correspondance speed skip count =
  let open Lwt_result_syntax in
  let initial_formatter =
    Format.sprintf
      "Executions correspondence (ticks %Ld to %Ld)"
      skip
      (Int64.add skip count)
  in
  let formatter =
    Scanf.format_from_string initial_formatter "" ^^ " on %s kernel"
  in
  test_with_kernel formatter speed Kernels.unreachable_kernel (fun kernel ->
      let*! tree = initial_tree ~from_binary:true ~max_tick:40_000L kernel in
      let*! tree =
        if skip = 0L then Lwt.return tree
        else Wasm.compute_step_many ~max_steps:skip tree
      in
      let rec explore tree' n =
        let*! tree_ref = Wasm.compute_step_many ~max_steps:n tree in
        let*! tree' = Wasm.compute_step tree' in
        assert (
          Context_hash.(Context.Tree.hash tree_ref = Context.Tree.hash tree')) ;
        if n < count then explore tree' (Int64.succ n) else return_unit
      in
      explore tree 1L)

let tests =
  [
    (* Parsing is way slower, so we limit ourselves to 1,000 ticks. *)
    test_execution_correspondance `Quick 0L 1_000L;
    (* Parsing is way slower, so we limit ourselves to 1,000 ticks. *)
    test_execution_correspondance `Quick 10_000L 1_000L;
    test_execution_correspondance `Quick 20_000L 5_000L;
    test_execution_correspondance `Quick 30_000L 5_000L;
  ]
