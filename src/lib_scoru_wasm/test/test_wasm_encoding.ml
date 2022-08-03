(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Trili Tech  <contact@trili.tech>                       *)
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
    Component:    Tree_encoding
    Invocation:   dune exec  src/lib_scoru_wasm/test/test_scoru_wasm.exe \
                    -- test "WASM Encodings"
    Subject:      Encoding tests for the tezos-scoru-wasm library
*)

open Tztest
open Tezos_scoru_wasm
open Tezos_webassembly_interpreter

let qcheck ?count ?print gen f =
  let open Lwt_result_syntax in
  let test =
    QCheck2.Test.make ?count ?print gen (fun x ->
        Result.is_ok @@ Lwt_main.run (f x))
  in
  let res = QCheck_base_runner.run_tests ~verbose:true [test] in
  if res = 0 then return_unit else failwith "QCheck tests failed"

(* Use context-binary for testing. *)
module Context = Tezos_context_memory.Context_binary

module Tree = struct
  type t = Context.t

  type tree = Context.tree

  type key = Context.key

  type value = Context.value

  include Context.Tree
end

module Tree_encoding = Tree_encoding.Make (Tree)
module Wasm_encoding = Wasm_encoding.Make (Tree_encoding)

let empty_tree () =
  let open Lwt_syntax in
  let* index = Context.init "/tmp" in
  let empty_store = Context.empty index in
  return @@ Context.Tree.empty empty_store

let encode_decode enc value =
  let open Lwt_syntax in
  let* empty_tree = empty_tree () in
  let* tree = Tree_encoding.encode enc value empty_tree in
  Tree_encoding.decode enc tree

(** Test serialize/deserialize instructions. *)
let test_instr_roundtrip () =
  let open Lwt_result_syntax in
  qcheck Ast_generators.instr_gen (fun instr ->
      let*! instr' = encode_decode Wasm_encoding.instruction_encoding instr in
      assert (instr = instr') ;
      return_unit)

let assert_string_equal s1 s2 =
  let open Lwt_result_syntax in
  if String.equal s1 s2 then return_unit else failwith "Not equal"

(** Test serialize/deserialize modules. *)
let test_module_roundtrip () =
  let print = Format.asprintf "%a" Ast_printer.pp_module in
  let open Lwt_result_syntax in
  let dummy_module_reg =
    (* It is ok to use a dummy here, because the module lookup (dereferenceing)
       is not important when encoding or decoding. *)
    Instance.ModuleMap.create ()
  in
  let lazy_dummy_module_reg = Lazy.from_val dummy_module_reg in

  qcheck
    ~print
    (Ast_generators.module_gen ~module_reg:dummy_module_reg ())
    (fun module1 ->
      (* We need to print here in order to force lazy bindings to be evaluated. *)
      let module1_str = print module1 in
      let*! module2 =
        encode_decode
          (Wasm_encoding.module_instance_encoding
             ~module_reg:lazy_dummy_module_reg)
          module1
      in
      let module2_str = print module2 in
      let*! module3 =
        encode_decode
          (Wasm_encoding.module_instance_encoding
             ~module_reg:lazy_dummy_module_reg)
          module2
      in
      let module3_str = print module3 in
      (* Check that modules match. *)
      let* () = assert_string_equal module1_str module2_str in
      assert_string_equal module2_str module3_str)

let test_generic_tree ~pp ~gen ~encoding =
  let print = Format.asprintf "%a" pp in
  let open Lwt_result_syntax in
  let dummy_module_reg =
    (* It is ok to use a dummy here, because the module lookup (dereferenceing)
       is not important when encoding or decoding. *)
    Instance.ModuleMap.create ()
  in
  let lazy_dummy_module_reg = Lazy.from_val dummy_module_reg in
  let host_funcs = Host_funcs.empty () in
  qcheck ~print (gen ~host_funcs ~module_reg:dummy_module_reg) (fun config1 ->
      let*! empty_tree = empty_tree () in
      (* We need to print here in order to force lazy bindings to be evaluated. *)
      let _ = print config1 in
      let*! tree1 =
        Tree_encoding.encode
          (encoding ~host_funcs ~module_reg:lazy_dummy_module_reg)
          config1
          empty_tree
      in
      let*! config2 =
        Tree_encoding.decode
          (encoding ~host_funcs ~module_reg:lazy_dummy_module_reg)
          tree1
      in
      (* We need to print here in order to force lazy bindings to be evaluated. *)
      let _ = print config2 in
      let*! tree2 =
        Tree_encoding.encode
          (encoding ~host_funcs ~module_reg:lazy_dummy_module_reg)
          config2
          empty_tree
      in
      assert (Tree.equal tree1 tree2) ;
      return_unit)

(** Test serialize/deserialize modules and compare trees. *)
let test_module_tree () =
  test_generic_tree
    ~pp:Ast_printer.pp_module
    ~gen:(fun ~host_funcs:_ ~module_reg ->
      Ast_generators.module_gen ~module_reg ())
    ~encoding:(fun ~host_funcs:_ -> Wasm_encoding.module_instance_encoding)

(** Test serialize/deserialize frames and compare trees. *)
let test_frame_tree () =
  test_generic_tree
    ~pp:Ast_printer.pp_frame
    ~gen:(fun ~host_funcs:_ -> Ast_generators.frame_gen)
    ~encoding:(fun ~host_funcs:_ -> Wasm_encoding.frame_encoding)

(** Test serialize/deserialize input buffers and compare trees. *)
let test_input_buffer_tree () =
  test_generic_tree
    ~pp:Ast_printer.pp_input_buffer
    ~gen:(fun ~host_funcs:_ ~module_reg:_ -> Ast_generators.input_buffer_gen)
    ~encoding:(fun ~host_funcs:_ ~module_reg:_ ->
      Wasm_encoding.input_buffer_encoding)

(** Test serialize/deserialize values and compare trees. *)
let test_values_tree () =
  test_generic_tree
    ~pp:(Format.pp_print_list Ast_printer.pp_value)
    ~gen:(fun ~host_funcs:_ ~module_reg:_ ->
      QCheck2.Gen.list Ast_generators.value_gen)
    ~encoding:(fun ~host_funcs:_ ~module_reg ->
      Wasm_encoding.(values_encoding ~module_reg))

(** Test serialize/deserialize administrative instructions and compare trees. *)
let test_admin_instr_tree () =
  test_generic_tree
    ~pp:Ast_printer.pp_admin_instr
    ~gen:(fun ~host_funcs:_ ~module_reg ->
      Ast_generators.admin_instr_gen ~module_reg 3)
    ~encoding:(fun ~host_funcs:_ -> Wasm_encoding.admin_instr_encoding)

(** Test serialize/deserialize evaluation configuration and compare trees. *)
let test_config_tree () =
  test_generic_tree
    ~pp:Ast_printer.pp_config
    ~gen:Ast_generators.config_gen
    ~encoding:Wasm_encoding.config_encoding

let tests =
  [
    tztest "Instruction roundtrip" `Quick test_instr_roundtrip;
    tztest "Module roundtrip" `Quick test_module_roundtrip;
    tztest "Module trees" `Quick test_module_tree;
    tztest "Values trees" `Quick test_values_tree;
    tztest "Admin_instr trees" `Quick test_admin_instr_tree;
    tztest "Input_buffer trees" `Quick test_input_buffer_tree;
    tztest "Frame trees" `Quick test_frame_tree;
    tztest "Config trees" `Quick test_config_tree;
  ]
