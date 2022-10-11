

open Tezos_scoru_wasm
open Pvm_instance
open Lib_exec
open Exec
open Wasm_pvm_state


module Scenario = struct
  


type action = Wasm.tree -> Wasm.tree Lwt.t

type scenario_step = string * action

type scenario = {kernel : string; actions : scenario_step list}

let make_scenario kernel actions = {kernel; actions}

let make_action (label : string) (action : action) : scenario_step =
  (label, action)

let run_action ?(inline = true) ?(last_tick = false) name tree action =
  let open Lwt_syntax in
  (* Before *)
  let before = Unix.gettimeofday () in
  let* info = Wasm.get_info tree in
  let before_tick = info.current_tick in
  let _ =
    if not inline then
      Printf.printf
        "=========\n%s \nStart at tick %s\n-----\n%!"
        name
        (Z.to_string info.current_tick)
  in

  (* Act *)
  let* tree = action tree in

  (* Result *)
  let time = Unix.gettimeofday () -. before in
  let* info = Wasm.get_info tree in
  let tick = Z.(info.current_tick - before_tick) in
  let* tick_state = Wasm.Internal_for_tests.get_tick_state tree in
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
  return tree

let exec_loop tree =
  let open Lwt_syntax in
  let* tree = run_action "Decoding" tree Exec.decode in
  let* tree = run_action "Linking" tree Exec.link in
  let* tree = run_action "Initialisation" tree Exec.init in
  let* tree = run_action "Evaluation" tree Exec.eval in
  let* tree = run_action "Finish" tree Exec.finish_top_level_call in
  return tree

let action_from_message step message tree =
  let open Lwt_syntax in
  let message = read_message message in
  let* tree = set_input_step step message tree in
  exec_loop tree

let run_scenario scenario =
  let open Lwt_syntax in
  let kernel = scenario.kernel in
  let apply_scenario kernel =
    let rec go tree = function
      | [] -> return tree
      | (label, action) :: q ->
          let* tree =
            run_action ~last_tick:true ~inline:false label tree action
          in
          go tree q
    in

    let* _, tree = initial_boot_sector_from_kernel kernel in
    let* _ = go tree scenario.actions in
    return ()
  in
  run kernel apply_scenario
end