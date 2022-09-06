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

(** Testing
    -------
    Component:    Tree_encoding_decoding
    Invocation:   dune exec  src/lib_scoru_wasm/test/test_scoru_wasm.exe \
                    -- test "^WASM PVM$"
    Subject:      WASM PVM evaluation tests for the tezos-scoru-wasm library
*)

open Tztest
open Tezos_scoru_wasm
module Wasm = Wasm_pvm.Make (Test_encodings_util.Tree)

(* Kernel failing at `kernel_next` invocation. *)
let unreachable_kernel = "unreachable"

let is_stuck = function Wasm_pvm.Stuck _ -> true | _ -> false

let initial_boot_sector_from_kernel kernel =
  let open Lwt_syntax in
  let* empty_tree = Test_encodings_util.empty_tree () in
  let origination_message =
    Data_encoding.Binary.to_string_exn
      Gather_floppies.origination_message_encoding
    @@ Gather_floppies.Complete_kernel (String.to_bytes kernel)
  in
  Wasm.Internal_for_tests.initial_tree_from_boot_sector
    ~empty_tree
    origination_message

let rec eval_until_input_requested tree =
  let open Lwt_syntax in
  let* info = Wasm.get_info tree in
  match info.input_request with
  | No_input_required ->
      let* tree = Wasm.compute_step tree in
      eval_until_input_requested tree
  | Input_required -> return tree

let set_input_step message message_counter tree =
  let input_info =
    Wasm_pvm_sig.
      {
        inbox_level =
          Option.value_f ~default:(fun () -> assert false)
          @@ Tezos_base.Bounded.Non_negative_int32.of_value 0l;
        message_counter = Z.of_int message_counter;
      }
  in
  Wasm.set_input_step input_info message tree

let should_boot_unreachable_kernel () =
  let open Lwt_syntax in
  let kernel = Tezos_wasm_kernels.Kernels.(read_kernel Test.unreachable) in
  let* tree = initial_boot_sector_from_kernel kernel in
  (* Make the first ticks of the WASM PVM (parsing of origination
     message, parsing and init of the kernel), to switch it to
     “Input_requested” mode. *)
  let* tree = eval_until_input_requested tree in
  (* Feeding it with one input *)
  let* tree = set_input_step "test" 0 tree in
  (* running until waiting for input *)
  let* tree = eval_until_input_requested tree in
  let* info_after_first_message = Wasm.get_info tree in
  let* state_after_first_message =
    Wasm.Internal_for_tests.get_tick_state tree
  in
  (* The kernel is expected to fail, then ths PVM should be in stuck state. *)
  assert (is_stuck state_after_first_message) ;

  (* Feeding it with one input *)
  let* tree = set_input_step "test" 1 tree in
  (* running until waiting for input *)
  let* tree = eval_until_input_requested tree in
  let* info_after_second_message = Wasm.get_info tree in
  let* state_after_second_message =
    Wasm.Internal_for_tests.get_tick_state tree
  in
  (* The PVM should still be in `Stuck` state, but can still receive inputs and
     go forward, hence the tick after the second message should be greater. *)
  assert (
    Z.lt
      info_after_first_message.current_tick
      info_after_second_message.current_tick) ;
  assert (is_stuck state_after_second_message) ;
  return_ok ()

let tests =
  [tztest "Test unreachable kernel" `Quick should_boot_unreachable_kernel]
