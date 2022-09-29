(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs <contact@nomadic-labs.com>                *)
(* Copyright (c) 2022 TriliTech <contact@trili.tech>                         *)
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
open Wasm_utils

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

let should_boot_unreachable_kernel ~max_steps kernel =
  let open Lwt_syntax in
  let* tree = initial_tree ~from_binary:true kernel in
  (* Make the first ticks of the WASM PVM (parsing of origination
     message, parsing and init of the kernel), to switch it to
     “Input_requested” mode. *)
  let* tree = eval_until_input_requested ~max_steps tree in
  (* Feeding it with one input *)
  let* tree = set_input_step "test" 0 tree in
  (* running until waiting for input *)
  let* tree = eval_until_input_requested ~max_steps tree in
  let* info_after_first_message = Wasm.get_info tree in
  let* state_after_first_message =
    Wasm.Internal_for_tests.get_tick_state tree
  in
  (* The kernel is expected to fail, then ths PVM should be in stuck state, and
     have failed during the evaluation when evaluating a `Unreachable`
     instruction. *)
  assert (
    is_stuck
      ~step:`Eval
      ~reason:"unreachable executed"
      state_after_first_message) ;

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
  assert (
    is_stuck
      ~step:`Eval
      ~reason:"unreachable executed"
      state_after_second_message) ;
  return_ok_unit

let should_run_debug_kernel kernel =
  let open Lwt_syntax in
  let* tree = initial_tree ~from_binary:true kernel in
  (* Make the first ticks of the WASM PVM (parsing of origination
     message, parsing and init of the kernel), to switch it to
     “Input_requested” mode. *)
  let* tree = eval_until_input_requested tree in
  (* Feeding it with one input *)
  let* tree = set_input_step "test" 0 tree in
  (* running until waiting for input *)
  let* tree = eval_until_input_requested tree in
  let* state_after_first_message =
    Wasm.Internal_for_tests.get_tick_state tree
  in
  (* The kernel should not fail. *)
  assert (not @@ is_stuck state_after_first_message) ;
  return_ok_unit

let add_value tree key_steps =
  let open Lazy_containers in
  let open Test_encodings_util in
  let value = Chunked_byte_vector.of_string "a very long value" in
  Tree_encoding_runner.encode
    (Tree_encoding.scope
       ("durable" :: List.append key_steps ["_"])
       Tree_encoding.chunked_byte_vector)
    value
    tree

let should_run_store_has_kernel kernel =
  let open Lwt_syntax in
  let* tree = initial_tree ~from_binary:true kernel in
  let* tree = add_value tree ["hi"; "bye"] in
  let* tree = add_value tree ["hello"] in
  let* tree = add_value tree ["hello"; "universe"] in
  (* Make the first ticks of the WASM PVM (parsing of origination
     message, parsing and init of the kernel), to switch it to
     “Input_requested” mode. *)
  let* tree = eval_until_input_requested tree in
  let* state_before_first_message =
    Wasm.Internal_for_tests.get_tick_state tree
  in
  (* The kernel is not expected to fail, the PVM should not be in stuck state. *)
  assert (not @@ is_stuck state_before_first_message) ;
  (* We now delete the path ["hello"; "universe"] - this will cause the kernel
     assertion on this path to fail, and the PVM should become stuck. *)
  let* tree = set_input_step "test" 0 tree in
  let* tree =
    Test_encodings_util.Tree.remove tree ["durable"; "hello"; "universe"; "_"]
  in
  let* tree = eval_until_input_requested tree in
  let* state_after_first_message =
    Wasm.Internal_for_tests.get_tick_state tree
  in
  (* The kernel is now expected to fail, the PVM should be in stuck state. *)
  assert (is_stuck state_after_first_message) ;
  return_ok_unit

let should_run_store_list_size_kernel kernel =
  let open Lwt_syntax in
  let* tree = initial_tree ~from_binary:true kernel in
  let* tree = add_value tree ["one"; "two"] in
  let* tree = add_value tree ["one"; "three"] in
  let* tree = add_value tree ["one"; "four"] in
  (* Make the first ticks of the WASM PVM (parsing of origination
     message, parsing and init of the kernel), to switch it to
     “Input_requested” mode. *)
  let* tree = eval_until_input_requested tree in
  (* Feeding it with one input *)
  let* tree = set_input_step "test" 0 tree in
  (* Adding a value at ["one"] should not affect the count. *)
  let* tree = add_value tree ["one"] in
  (* running until waiting for input *)
  let* tree = eval_until_input_requested tree in
  let* state_after_first_message =
    Wasm.Internal_for_tests.get_tick_state tree
  in
  (* The kernel is not expected to fail, the PVM should not be in stuck state. *)
  assert (not @@ is_stuck state_after_first_message) ;
  (* We now add another value - this will cause the kernel
     assertion on this path to fail, as there are now four subtrees. *)
  let* tree = set_input_step "test" 1 tree in
  let* tree = add_value tree ["one"; "five"] in
  let* tree = eval_until_input_requested tree in
  let* state_after_second_message =
    Wasm.Internal_for_tests.get_tick_state tree
  in
  (* The kernel is now expected to fail, the PVM should be in stuck state. *)
  assert (is_stuck state_after_second_message) ;
  return_ok_unit

let should_run_store_delete_kernel kernel =
  let open Lwt_syntax in
  let open Test_encodings_util in
  let* tree = initial_tree ~from_binary:true kernel in
  let* tree = add_value tree ["one"] in
  let* tree = add_value tree ["one"; "two"] in
  let* tree = add_value tree ["three"] in
  let* tree = add_value tree ["three"; "four"] in
  (* Make the first ticks of the WASM PVM (parsing of origination
     message, parsing and init of the kernel), to switch it to
     “Input_requested” mode. *)
  (* Check that we have all the paths in place. *)
  let* result = Tree.find_tree tree ["durable"; "one"] in
  assert (Option.is_some result) ;
  let* result = Tree.find_tree tree ["durable"; "three"; "four"] in
  assert (Option.is_some result) ;
  let* result = Tree.find_tree tree ["durable"; "three"] in
  assert (Option.is_some result) ;
  (* Eval until input requested *)
  let* tree = eval_until_input_requested tree in
  let* state = Wasm.Internal_for_tests.get_tick_state tree in
  (* The kernel is not expected to fail, the PVM should not be in stuck state. *)
  assert (not @@ is_stuck state) ;
  (* The paths /one & /three/four will have been deleted. *)
  let* result = Tree.find_tree tree ["durable"; "one"] in
  assert (Option.is_none result) ;
  let* result = Tree.find_tree tree ["durable"; "three"; "four"] in
  assert (Option.is_none result) ;
  let* result = Tree.find_tree tree ["durable"; "three"] in
  assert (Option.is_some result) ;
  return_ok_unit

(* This function can build snapshotable state out of a tree. It currently
   assumes it follows a tree resulting from `set_input_step`.*)
let build_snapshot_wasm_state_from_set_input
    ?(max_tick = Z.of_int64 default_max_tick) tree =
  let open Lwt_syntax in
  (* Only serves to encode the `Snapshot` state. *)
  let state_encoding =
    Tree_encoding.(
      tagged_union
        (value [] Data_encoding.string)
        [
          case
            "snapshot"
            (value [] Data_encoding.unit)
            (function Wasm_pvm.Snapshot -> Some () | _ -> None)
            (fun () -> Snapshot);
        ])
  in
  (* Serves to encode the `Input_requested` status. *)
  let input_request_encoding =
    Tree_encoding.value ~default:true [] Data_encoding.bool
  in
  let* tree =
    Test_encodings_util.Tree_encoding_runner.encode
      (Tree_encoding.scope ["wasm"] state_encoding)
      Wasm_pvm.Snapshot
      tree
  in
  (* Since we start directly after at an input_step, we need to offset the tick
     at the next max tick + the snapshot tick. *)
  let* current_tick =
    Test_encodings_util.Tree_encoding_runner.decode
      (Tree_encoding.value ["pvm"; "last_top_level_call"] Data_encoding.n)
      tree
  in
  let snapshot_tick =
    Z.(max_tick + current_tick + Z.one)
    (* Offsetted by one since the snapshot is a tick in itself. *)
  in
  let* tree =
    Test_encodings_util.Tree_encoding_runner.encode
      (Tree_encoding.value ["wasm"; "current_tick"] Data_encoding.n)
      snapshot_tick
      tree
  in
  let* tree =
    Test_encodings_util.Tree_encoding_runner.encode
      (Tree_encoding.value ["pvm"; "last_top_level_call"] Data_encoding.n)
      snapshot_tick
      tree
  in
  (* A snapshot should always be in input state *)
  Test_encodings_util.Tree_encoding_runner.encode
    (Tree_encoding.scope ["input"; "consuming"] input_request_encoding)
    true
    tree

let test_snapshotable_state () =
  let open Lwt_result_syntax in
  let module_ =
    {|
      (module
        (memory 1)
        (export "mem"(memory 0))
        (func (export "kernel_next")
          (nop)
        )
      )
    |}
  in
  let*! tree = initial_tree ~from_binary:false module_ in
  (* First evaluate until the snapshotable state. *)
  let*! tree = eval_until_input_requested tree in
  let*! state = Wasm.Internal_for_tests.get_tick_state tree in
  let* () =
    match state with
    | Snapshot -> return_unit
    | _ ->
        failwith
          "Unexpected state at input requested: %a"
          Wasm_utils.pp_state
          state
  in
  (* The "wasm"/"modules" key should not exist after the snapshot, since it
     contains the instance of the module after its evaluation. *)
  let*! wasm_tree_exists =
    Test_encodings_util.Tree.mem_tree tree ["wasm"; "modules"]
  in
  let*! wasm_value_exists =
    Test_encodings_util.Tree.mem tree ["wasm"; "modules"]
  in
  assert (not (wasm_tree_exists || wasm_value_exists)) ;
  (* Set a new input should go back to decoding *)
  let*! tree = set_input_step "test" 1 tree in
  let*! state = Wasm.Internal_for_tests.get_tick_state tree in
  match state with
  | Decode _ -> return_unit
  | _ ->
      failwith
        "Unexpected state after set_input_step: %a"
        Wasm_utils.pp_state
        state

let test_rebuild_snapshotable_state () =
  let open Lwt_result_syntax in
  let module_ =
    {|
      (module
        (memory 1)
        (export "mem"(memory 0))
        (func (export "kernel_next")
          (nop)
        )
      )
    |}
  in
  let*! tree = initial_tree ~from_binary:false module_ in
  let*! tree = eval_until_input_requested tree in
  let*! tree = set_input_step "test" 0 tree in
  (* First evaluate until the snapshotable state. *)
  let*! tree_after_eval = eval_until_input_requested tree in
  (* From out initial tree, let's rebuild the expected snapshotable state as the
     Fast Node would do. This works because the kernel doesn't change anything. *)
  let*! rebuilded_tree = build_snapshot_wasm_state_from_set_input tree in

  (* Remove the "wasm" key from the tree after evaluation, and try to rebuild it
     as a snapshot. This would take into account any change in the input and
     output buffers and the durable storage. *)
  let*! tree_without_wasm = Test_encodings_util.Tree.remove tree ["wasm"] in
  let*! rebuilded_tree_without_wasm =
    build_snapshot_wasm_state_from_set_input tree_without_wasm
  in

  (* Both hash should be exactly the same. *)
  let hash_tree_after_eval = Test_encodings_util.Tree.hash tree_after_eval in
  let hash_rebuilded_tree = Test_encodings_util.Tree.hash rebuilded_tree in
  assert (Context_hash.equal hash_tree_after_eval hash_rebuilded_tree) ;

  (* The hash of the tree rebuilded from the evaluated one without the "wasm"
     part should also be exactly the same. *)
  let hash_rebuilded_tree_without_wasm =
    Test_encodings_util.Tree.hash rebuilded_tree_without_wasm
  in
  assert (
    Context_hash.equal hash_tree_after_eval hash_rebuilded_tree_without_wasm) ;

  (* To be sure, let's try to evaluate a new input from these two, either by the
     regular tree or the snapshoted one. *)
  let*! input_step_from_eval = set_input_step "test" 1 tree_after_eval in
  let*! input_step_from_snapshot = set_input_step "test" 1 rebuilded_tree in

  (* Their hash should still be the same, but the first test should have caught
     that. *)
  let hash_input_tree_after_eval =
    Test_encodings_util.Tree.hash input_step_from_eval
  in
  let hash_input_rebuilded_tree =
    Test_encodings_util.Tree.hash input_step_from_snapshot
  in

  assert (
    Context_hash.equal hash_input_tree_after_eval hash_input_rebuilded_tree) ;
  return_unit

let tests =
  [
    test_with_kernel
      "Test %s kernel (tick per tick)"
      `Quick
      Kernels.unreachable_kernel
      (should_boot_unreachable_kernel ~max_steps:1L);
    test_with_kernel
      "Test %s kernel (10 ticks at a time)"
      `Quick
      Kernels.unreachable_kernel
      (should_boot_unreachable_kernel ~max_steps:10L);
    test_with_kernel
      "Test %s kernel (in one go)"
      `Quick
      Kernels.unreachable_kernel
      (should_boot_unreachable_kernel ~max_steps:Int64.max_int);
    test_with_kernel
      "Test %s kernel"
      `Quick
      Kernels.test_write_debug_kernel
      should_run_debug_kernel;
    test_with_kernel
      "Test %s kernel"
      `Quick
      Kernels.test_store_has_kernel
      should_run_store_has_kernel;
    test_with_kernel
      "Test %s kernel"
      `Quick
      Kernels.test_store_list_size_kernel
      should_run_store_list_size_kernel;
    test_with_kernel
      "Test %s kernel"
      `Quick
      Kernels.test_store_delete_kernel
      should_run_store_delete_kernel;
    tztest "Test snapshotable state" `Quick test_snapshotable_state;
    tztest
      "Test rebuild snapshotable state"
      `Quick
      test_rebuild_snapshotable_state;
  ]
