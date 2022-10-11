(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Marigold <contact@marigold.dev>                        *)
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

open Tezos_scoru_wasm
open Pvm_instance
open Lib_exec
open Lib_measure
open Wasm_pvm_state

module Scenario = struct
  open Wasm

  type 'a run_state = {state : 'a; message_counter : int}

  let lift_action action =
    let open Lwt_syntax in
    fun run_state ->
      let* state = action run_state.state in
      return {run_state with state}

  let lift_lookup lookup =
    let open Lwt_syntax in
    fun run_state ->
      let* res = lookup run_state.state in
      return res

  type 'a action = 'a run_state -> 'a run_state Lwt.t

  type scenario_step = string * tree action

  type scenario = {kernel : string; actions : scenario_step list}

  let make_scenario kernel actions = {kernel; actions}

  let make_scenario_step (label : string) (action : tree action) : scenario_step
      =
    (label, action)

  let run_action ?(inline = true) ?(last_tick = false) name run_state action =
    let open Lwt_syntax in
    (* Before *)
    let* info = lift_lookup Wasm.get_info run_state in
    let _ =
      if not inline then
        Printf.printf
          "=========\n%s \nStart at tick %s\n-----\n%!"
          name
          (Z.to_string info.current_tick)
    in
    let* time, tick, run_state =
      Measure.time_and_tick (lift_lookup get_tick_from_tree) action run_state
    in
    let* info = lift_lookup Wasm.get_info run_state in
    let* tick_state =
      lift_lookup Wasm.Internal_for_tests.get_tick_state run_state
    in
    let _ = if not inline then Printf.printf "-----\n" in
    let _ =
      Printf.printf "%s took %s ticks in %f s\n%!" name (Z.to_string tick) time
    in
    let _ =
      if last_tick then
        Printf.printf
          "last tick: %s %s\n%!"
          (Z.to_string info.current_tick)
          (PP.tick_label tick_state)
    in
    return run_state

  let switch_state_type switch switch_label a_state =
    let open Lwt_syntax in
    let* time, b_state =
      Measure.time (fun () -> (lift_action switch) a_state)
    in
    return b_state

  let exec_phase state phase = lift_action (Exec.execute_on_state phase) state

  let exec_loop tree_run_state =
    let open Lwt_syntax in
    let* pvm_run_state =
      switch_state_type
        Wasm.Internal_for_benchmark.decode
        "Decode tree"
        tree_run_state
    in
    let* pvm_run_state = Exec.run_loop exec_phase pvm_run_state in
    let* tree_run_state =
      switch_state_type
        (fun state ->
          (* the encode function takes the previous tree encoding as argument *)
          Wasm.Internal_for_benchmark.encode state tree_run_state.state)
        "Encode tree"
        pvm_run_state
    in
    return tree_run_state

  let exec_on_message ?(from_binary = true) message : tree action =
   fun run_state ->
    let open Lwt_syntax in
    let message = if from_binary then Exec.read_message message else message in
    let* run_state =
      lift_action
        (Exec.set_input_step run_state.message_counter message)
        run_state
    in
    exec_loop {run_state with message_counter = run_state.message_counter + 1}

  let run_scenario scenario =
    let open Lwt_syntax in
    let kernel = scenario.kernel in
    let apply_scenario kernel =
      let rec go run_state = function
        | [] -> return run_state
        | (label, action) :: q ->
            let* tree =
              run_action ~last_tick:true ~inline:false label run_state action
            in
            go tree q
      in
      let* tree = Exec.initial_boot_sector_from_kernel kernel in
      let run_state = {state = tree; message_counter = 1} in
      let* _ = go run_state scenario.actions in
      return ()
    in
    Exec.run kernel apply_scenario
end
