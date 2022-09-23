(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
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

open Tezos_webassembly_interpreter
open Tezos_scoru_wasm
open Test_encodings_util
module Wasm = Wasm_pvm.Make (Tree)

let parse_module code =
  let def = Parse.string_to_module code in
  match def.it with
  | Script.Textual m -> m
  | _ -> Stdlib.failwith "Failed to parse WebAssembly module"

let wat2wasm code =
  let modul = parse_module code in
  Encode.encode modul

let initial_tree ?(max_tick = 100000L) ?(from_binary = false) code =
  let open Lwt.Syntax in
  let max_tick_Z = Z.of_int64 max_tick in
  let* empty_tree = empty_tree () in
  let* code = if from_binary then Lwt.return code else wat2wasm code in
  let boot_sector =
    Data_encoding.Binary.to_string_exn
      Gather_floppies.origination_message_encoding
      (Gather_floppies.Complete_kernel (String.to_bytes code))
  in
  let* tree =
    Wasm.Internal_for_tests.initial_tree_from_boot_sector
      ~empty_tree
      boot_sector
  in
  Wasm.Internal_for_tests.set_max_nb_ticks max_tick_Z tree

let eval_until_stuck ?(max_steps = 20000L) tree =
  let open Lwt.Syntax in
  let rec go counter tree =
    let* tree = Wasm.Internal_for_tests.compute_step_many ~max_steps tree in
    let* stuck = Wasm.Internal_for_tests.is_stuck tree in
    match stuck with
    | Some stuck -> Lwt_result.return (stuck, tree)
    | _ ->
        if counter > 0L then go (Int64.pred counter) tree
        else failwith "Failed to get stuck in time"
  in
  go max_steps tree

let rec eval_until_input_requested ?(max_steps = Int64.max_int) tree =
  let open Lwt_syntax in
  let* info = Wasm.get_info tree in
  let _ = max_steps in
  match info.input_request with
  | No_input_required ->
      let* tree = Wasm.compute_step tree in
      let* tick_state = Wasm.Internal_for_tests.get_tick_state tree in
      let () =
        match tick_state with
        | Decode _ -> Format.printf "Decode\n%!"
        | Link _ -> Format.printf "Link\n%!"
        | Init _ -> Format.printf "Init\n%!"
        | Eval _ -> Format.printf "Eval\n%!"
        | Stuck e ->
            Format.printf
              "Stuck: %a\n%!"
              Test_wasm_pvm_encodings.pp_error_state
              e
      in
      eval_until_input_requested tree
  | Input_required -> return tree
  | Reveal_required _ -> return tree

let rec eval_until_init tree =
  let open Lwt_syntax in
  let* state_after_first_message =
    Wasm.Internal_for_tests.get_tick_state tree
  in
  match state_after_first_message with
  | Stuck _ | Init _ -> return tree
  | _ ->
      let* tree = Wasm.compute_step tree in
      eval_until_init tree

let current_tick_encoding =
  Tree_encoding.value ["wasm"; "current_tick"] Data_encoding.n

(* Replicates the encoder in [Wasm_pvm]. Used here for artificially encode
   input info in the tree. *)
let input_requested_encoding =
  Tree_encoding.value ~default:false ["input"; "consuming"] Data_encoding.bool

(* Replicates the encoding of buffers from [Wasm_pvm] as part of the pvm_state. *)
let buffers_encoding =
  Tree_encoding.scope ["pvm"; "buffers"] Wasm_encoding.buffers_encoding

let floppy_encoding =
  Tree_encoding.value
    ["gather-floppies"; "status"]
    Gather_floppies.internal_status_encoding

(** Artificial initialization. Under normal circumstances the changes in
    [current_tick], [gather_floppies] and [status] will be done by the other
    PVM operations. for example the [origination_kernel_loading_step] in
    Gather_floppies will initialize both the [current_tick] and the
    [gather_floppies] *)
let initialise_tree () =
  let open Lwt_syntax in
  let* empty_tree = empty_tree () in
  let boot_sector =
    Data_encoding.Binary.to_string_exn
      Gather_floppies.origination_message_encoding
      (Complete_kernel (Bytes.of_string "some boot sector"))
  in
  let* tree =
    Wasm.Internal_for_tests.initial_tree_from_boot_sector
      ~empty_tree
      boot_sector
  in

  let* tree = Tree_encoding_runner.encode current_tick_encoding Z.zero tree in
  let* tree =
    Tree_encoding_runner.encode
      floppy_encoding
      Gather_floppies.Not_gathering_floppies
      tree
  in
  let* tree = Tree_encoding_runner.encode input_requested_encoding true tree in
  Tree_encoding_runner.encode
    buffers_encoding
    (Tezos_webassembly_interpreter.Eval.buffers ())
    tree
