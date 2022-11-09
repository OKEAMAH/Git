(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2018 Dynamic Ledger Solutions, Inc. <contact@tezos.com>     *)
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

(** Testing
    -------
    Component:  Protocol (origination)
    Invocation:
              dune exec \
                src/proto_alpha/lib_protocol/test/integration/operations/main.exe \
                -- test "^global shared counter$"
    Subject:    On incrementing shared global counter.
*)

let bake_next_block_with_single_counter_increment ~loc:_ ~mgr prev_block =
  let open Lwt_result_syntax in
  let* incr = Incremental.begin_construction prev_block in
  let* op = Op.increment_global_counter (I incr) mgr in
  let* incr1 = Incremental.add_operation incr op in
  Incremental.finalize_block incr1

let test_increment_global_counter_by_different_mgrs ~loc:_ ~n_times () =
  let open Lwt_result_syntax in
  let* (genesis_b, mgrs) = Context.init_n ~consensus_threshold:0 n_times () in
  let* b =
    List.fold_left_es
      (fun pb mgr -> bake_next_block_with_single_counter_increment ~loc:__LOC__ ~mgr pb)
      genesis_b
      mgrs
  in
  (* check that after the block has been baked the global counter incremented *)
  let* global_counter = Context.get_shared_global_counter (B b) in
  Assert.equal
    ~loc:__LOC__
    Z.Compare.(=)
    (Format.sprintf "Global counter expected to be equal to %d" n_times)
    Z.pp_print
    (Z.of_int n_times)
    global_counter

(******************************************************)
(* Tests *)
(******************************************************)

let test_increment_global_counter_once () = test_increment_global_counter_by_different_mgrs ~loc:__LOC__ ~n_times:1 ()
let test_increment_global_counter_thrice () = test_increment_global_counter_by_different_mgrs ~loc:__LOC__ ~n_times:3 ()

let tests =
  [
    Tztest.tztest "Increment global counter once" `Quick test_increment_global_counter_once;
    Tztest.tztest "Increment global counter thrice: an operation per block" `Quick test_increment_global_counter_thrice;
  ]