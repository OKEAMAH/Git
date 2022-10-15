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
open Lib_benchmark
open Lib_exec
open Lib_measure
open Wasm_pvm_state

module Verbose = struct
  let pp_header_section name before_tick =
    Printf.printf
      "=========\n%s \nStart at tick %s\n-----\n%!"
      name
      (Z.to_string before_tick)

  let pp_last_tick tree =
    let open Lwt_syntax in
    let* after_tick = get_tick_from_tree tree in
    let* tick_state = Wasm.Internal_for_tests.get_tick_state tree in
    let _ =
      Printf.printf
        "-----\nlast tick: %s %s\n%!"
        (Z.to_string after_tick)
        (PP.tick_label tick_state)
    in
    return_unit

  let pp_scenario_header name =
    Printf.printf
      "****************************************\n Scenario %s\n%!"
      name
end

module Scenario = struct
  open Wasm
  open Data

  type 'a run_state = {benchmark : benchmark; state : 'a; message_counter : int}

  let init_run_state benchmark state = {benchmark; state; message_counter = 1}

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

  let lift_add_datum add_datum run_state =
    let benchmark = add_datum run_state.benchmark in
    {run_state with benchmark}

  type 'a action = 'a run_state -> 'a run_state Lwt.t

  type scenario_step = {label : string; action : tree action}

  type scenario = {name : string; kernel : string; actions : scenario_step list}

  let make_scenario name kernel actions = {name; kernel; actions}

  let make_scenario_step (label : string) (action : tree action) =
    {label; action}

  let run_step ?(verbose = false) run_state {label; action} =
    let open Lwt_syntax in
    (* before *)
    let run_state = lift_add_datum (switch_section label) run_state in
    let* before_tick = lift_lookup get_tick_from_tree run_state in
    if verbose then Verbose.pp_header_section label before_tick ;

    (* Act *)
    let* time, tick, run_state_after =
      Measure.time_and_tick (lift_lookup get_tick_from_tree) action run_state
    in

    (* after *)
    let* _ =
      if verbose then lift_lookup Verbose.pp_last_tick run_state_after
      else return_unit
    in
    return @@ lift_add_datum (Data.add_datum label tick time) run_state_after

  let run_pvm_action name run_state action =
    let open Lwt_syntax in
    (* Act *)
    let* time, tick, run_state_after =
      Measure.time_and_tick
        (lift_lookup get_tick_from_pvm_state)
        (fun s -> action s)
        run_state
    in
    return @@ lift_add_datum (Data.add_datum name tick time) run_state_after

  let switch_state_type switch switch_label a_state =
    let open Lwt_syntax in
    let* time, b_state =
      Measure.time (fun () -> (lift_action switch) a_state)
    in
    return @@ lift_add_datum (Data.add_tickless_datum switch_label time) b_state

  let exec_phase run_state phase =
    run_pvm_action
      (Exec.show_phase phase)
      run_state
      (lift_action @@ Exec.execute_on_state phase)

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
          (* the encode function takes the _previous_ tree encoding as argument *)
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

  let run_scenario ?(verbose = false) ~benchmark scenario =
    let open Lwt_syntax in
    let apply_scenario kernel_bytes =
      (* init scenario run*)
      if verbose then Verbose.pp_scenario_header scenario.name ;
      let* state = Exec.initial_boot_sector_from_kernel kernel_bytes in
      let benchmark = init_scenario scenario.name benchmark in
      let run_state = init_run_state benchmark state in
      (* act*)
      let* time, run_state =
        Measure.time (fun () ->
            Lwt_list.fold_left_s (run_step ~verbose) run_state scenario.actions)
      in
      (* record *)
      let* info = lift_lookup Wasm.get_info run_state in
      return (add_final_info time info.current_tick run_state.benchmark)
    in
    Exec.run scenario.kernel apply_scenario

  let run_scenarios ?(verbose = true) ?(totals = true) ?(irmin = true) scenarios
      =
    let open Lwt_syntax in
    let rec go benchmark = function
      | [] ->
          Data.Csv.print_benchmark benchmark ;
          return_unit
      | t :: q ->
          let* benchmark = run_scenario ~verbose ~benchmark t in
          go benchmark q
    in
    go (empty_benchmark ~verbose ~totals ~irmin ()) scenarios
end
