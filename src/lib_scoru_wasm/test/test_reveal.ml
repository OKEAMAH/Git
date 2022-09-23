(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 TriliTech  <contact@trili.tech>                       *)
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
    Component:    Lib_scoru_wasm reveal
    Invocation:   dune exec  src/lib_scoru_wasm/test/test_scoru_wasm.exe \
                    -- test "Reveal"
    Subject:      Reveal tests for the tezos-scoru-wasm library
*)

open Tztest
open Tezos_webassembly_interpreter
open Tezos_scoru_wasm
open Wasm_utils

let dummy_instance memory =
  let module_key = Instance.Module_key "dummy" in
  let module_reg = Instance.ModuleMap.create () in
  let inst =
    Instance.{empty_module_inst with memories = Vector.singleton memory}
  in
  Instance.ModuleMap.set "dummy" inst module_reg ;
  (module_key, module_reg)

let module_ hash_addr preimage_addr max_bytes =
  Format.sprintf
    {|
      (module
        (import "rollup_safe_core" "reveal_preimage"
          (func $reveal_preimage (param i32 i32 i32) (result i32))
        )
        (memory 1)
        (export "mem" (memory 0))
        (func (export "kernel_next")
          (call $reveal_preimage (i32.const %ld) (i32.const %ld) (i32.const %ld))
        )
      )
    |}
    hash_addr
    preimage_addr
    max_bytes

let test_init_module () =
  let open Lwt_result_syntax in
  let _hash = "azertyuiopqsdfghjklmwxcvbn123456" in
  let _preimage =
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse \
     elementum nec ex sed porttitor."
    (* 100 bytes *)
  in
  let hash_addr = 120l in
  let preimage_addr = 200l in
  let max_bytes = 200l in
  let modl = module_ hash_addr preimage_addr max_bytes in
  let*! state = initial_tree modl in
  let*! state = eval_until_input_requested ~max_steps:1L state in
  let*! tick_state = Wasm.Internal_for_tests.get_tick_state state in
  let () =
    match tick_state with
    | Decode _ -> Format.printf "Decode\n%!"
    | Link _ -> Format.printf "Link\n%!"
    | Init _ -> Format.printf "Init\n%!"
    | Eval _ -> Format.printf "Eval\n%!"
    | Stuck e ->
        Format.printf "Stuck: %a\n%!" Test_wasm_pvm_encodings.pp_error_state e
  in
  let*! info = Wasm.get_info state in
  let* () =
    match info.Wasm_pvm_sig.input_request with
    | Wasm_pvm_sig.No_input_required -> assert false
    | Input_required -> return_unit (* ??? *)
    | Reveal_required _ -> failwith "Input first?"
  in
  let*! state = eval_until_input_requested state in
  let*! tick_state = Wasm.Internal_for_tests.get_tick_state state in
  let () =
    match tick_state with
    | Decode _ -> Format.printf "Decode\n%!"
    | Link _ -> Format.printf "Link\n%!"
    | Init _ -> Format.printf "Init\n%!"
    | Eval _ -> Format.printf "Eval\n%!"
    | Stuck e ->
        Format.printf "Stuck: %a\n%!" Test_wasm_pvm_encodings.pp_error_state e
  in
  let*! info = Wasm.get_info state in
  let* () =
    match info.Wasm_pvm_sig.input_request with
    | Wasm_pvm_sig.No_input_required -> assert false
    | Input_required -> failwith "oh no"
    | Reveal_required _ -> failwith "OK"
  in
  return_unit

(* Use Eval.invoke, does not work *)
let read_preimage_generic hash preimage max_bytes =
  let open Lwt.Syntax in
  let lim = Types.(MemoryType {min = 100l; max = Some 1000l}) in
  let memory = Memory.alloc lim in
  let module_key, module_reg = dummy_instance memory in
  let host_funcs = Tezos_webassembly_interpreter.Host_funcs.empty () in
  Host_funcs.register_host_funcs host_funcs ;
  let hash_addr = 120l in
  let preimage_addr = 200l in
  let* () = Memory.store_bytes memory hash_addr hash in

  let values =
    Values.[Num (I32 hash_addr); Num (I32 preimage_addr); Num (I32 max_bytes)]
  in
  let* _, res =
    Eval.invoke
      ~module_reg
      ~caller:module_key
      host_funcs
      Host_funcs.Internal_for_tests.reveal_preimage
      values
  in
  let expected_length = min (String.length preimage) (Int32.to_int max_bytes) in
  let* hash_in_memory = Memory.load_bytes memory hash_addr 32 in
  let+ preimage_in_memory =
    Memory.load_bytes memory preimage_addr expected_length
  in
  assert (hash = hash_in_memory) ;
  assert (preimage = preimage_in_memory) ;
  match res with
  | Values.[Num (I32 length)] -> assert (length = Int32.of_int expected_length)
  | _ -> assert false

let _test_read_preimage_basic () =
  let open Lwt_result_syntax in
  let hash = "azertyuiopqsdfghjklmwxcvbn123456" in
  let preimage =
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse \
     elementum nec ex sed porttitor."
    (* 100 bytes *)
  in
  let*! () = read_preimage_generic hash preimage 120l in
  return_unit

let tests =
  [tztest "Test read_preimage predefined value" `Quick test_init_module]
