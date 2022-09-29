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

let default_max_tick = 100000L

let initial_tree ?(max_tick = default_max_tick) ?(from_binary = false) code =
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
    let* tree = Wasm.compute_step_many ~max_steps tree in
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
  match info.input_request with
  | No_input_required ->
      let* tree = Wasm.compute_step_many ~max_steps tree in
      eval_until_input_requested tree
  | Input_required -> return tree

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

let pp_state fmt state =
  let pp_s s = Format.fprintf fmt "%s" s in
  match state with
  | Wasm_pvm.Decode _ -> pp_s "Decode"
  | Eval _ -> pp_s "Eval"
  | Stuck e ->
      Format.fprintf fmt "Stuck (%a)" Test_wasm_pvm_encodings.pp_error_state e
  | Init _ -> pp_s "Init"
  | Snapshot -> pp_s "Snapshot"
  | Link _ -> pp_s "Link"

(** [check_error kind reason error] checks a Wasm PVM error [error] is of a
    given [kind] with a possible [reason].

    - If [kind] is [None], returns true.

    - If [reason] is [None], it simply check the given kind, otherwise it
    actually check the reason in the error. *)
let check_error expected_kind expected_reason error =
  let check_reason actual_reason =
    match expected_reason with
    | None -> true
    | _ -> expected_reason = actual_reason
  in
  match (expected_kind, error) with
  | Some `Decode, Wasm_pvm_errors.Decode_error {explanation; _} ->
      check_reason explanation
  | Some `Init, Init_error {explanation; _} -> check_reason explanation
  | Some `Link, Link_error explanation -> check_reason (Some explanation)
  | Some `Eval, Eval_error {explanation; _} -> check_reason explanation
  | Some `Invalid_state, Invalid_state explanation ->
      check_reason (Some explanation)
  (* Unknown_error encapsulate a raw exception produced by `Printexc.to_string`.
     It depends on the backend, if there are registered printers or not, it is
     not safe to rely on its string representation. *)
  | Some `Unknown, Unknown_error _ -> true
  | Some `Too_many_ticks, Too_many_ticks -> true
  (* The expected step doesn't corresponds to the actual stuck step. *)
  | Some _, _ -> false
  (* No check to do, we simply assume the PVM is in a stuck state. *)
  | None, _ -> true

let is_stuck ?step ?reason = function
  | Wasm_pvm.Stuck err -> check_error step reason err
  | _ -> false

module Kernels = struct
  (* A kernel is read lazily, to prevent reading them all at once. *)
  type t = Kernel of string * string Lwt.t Lazy.t

  let read_kernel kernel =
    let open Lwt_syntax in
    let open Tezt.Base in
    (* Reading files using `Tezt_lib` can be fragile and not future-proof, see
       issue https://gitlab.com/tezos/tezos/-/issues/3746. *)
    let kernel_file =
      project_root // Filename.dirname __FILE__ // "wasm_kernels"
      // (kernel ^ ".wasm")
    in
    let read () =
      let* ic = Lwt_io.open_file ~mode:Lwt_io.Input kernel_file in
      let buffer = Buffer.create 512 in
      let bytes = Bytes.create 512 in
      let rec loop () =
        let* len = Lwt_io.read_into ic bytes 0 512 in
        if len > 0 then (
          Buffer.add_subbytes buffer bytes 0 len ;
          loop ())
        else Lwt.return_unit
      in
      let* () = loop () in
      let+ () = Lwt_io.close ic in
      Buffer.contents buffer
    in
    Kernel (kernel, lazy (read ()))

  (* Kernel failing at `kernel_next` invocation. *)
  let unreachable_kernel = read_kernel "unreachable"

  (* Kernel writing `"hello"` to debug output. *)
  let test_write_debug_kernel = read_kernel "test-write-debug"

  (* Kernel checking the return of the store_has host func.

     This kernel expects a collection of values to exist:
     - `/durable/hi/bye`
     - `/durable/hello`
     - `/durable/hello/universe`
     and asserts that `store_has` returns the correct type for each.
  *)
  let test_store_has_kernel = read_kernel "test-store-has"

  (* Kernel checking the return value of store_list_size host func.

     This kernel expects a collection of values to exist:
     - `/durable/one/two`
     - `/durable/one/three`
     - `/durable/one/four`
     and asserts that `store_list_size(/one) = 3`.
  *)
  let test_store_list_size_kernel = read_kernel "test-store-list-size"

  (* Kernel checking the behaviour value of store_delete host func.

     This kernel deletes the following paths:
     - `/durable/one`
     - `/durable/three/four`
  *)
  let test_store_delete_kernel = read_kernel "test-store-delete"
end

let test_with_kernel formatter speed (Kernels.Kernel (kernel_name, kernel))
    (test : string -> (unit, _) result Lwt.t) =
  let open Lwt_syntax in
  let test () =
    let (lazy forced_kernel) = kernel in
    let* kernel = forced_kernel in
    test kernel
  in
  Tztest.tztest (Format.sprintf formatter kernel_name) speed test
