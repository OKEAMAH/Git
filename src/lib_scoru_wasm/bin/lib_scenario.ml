

open Tezos_scoru_wasm
open Pvm_instance
open Lib_exec
open Wasm_pvm_state


module Scenario = struct
  type action = Wasm.tree -> Wasm.tree Lwt.t

  let action_from_message step message tree =
    let open Lwt_syntax in
    let message = Exec.read_message message in
    let* tree = Exec.set_input_step step message tree in
    Exec.eval_until_input_requested tree

  type scenario_step = string * action

  type scenario = {kernel : string; actions : scenario_step list}

  let make_scenario kernel actions = {kernel; actions}

  let make_action (label : string) (action : action) : scenario_step =
    (label, action)

  let run_action name tree action =
    let open Lwt_syntax in
    let before = Unix.gettimeofday () in
    let* info = Wasm.get_info tree in
    let before_tick = info.current_tick in
    let* tick_state = Wasm.Internal_for_tests.get_tick_state tree in
    let _ =
      Printf.printf
        "=========\n%s \nStart at tick %s %s\n%!"
        name
        (Z.to_string info.current_tick)
        (PP.tick_label tick_state)
    in
    let* tree = action tree in
    let time = Unix.gettimeofday () -. before in
    let* info = Wasm.get_info tree in
    let tick = Z.(info.current_tick - before_tick) in
    let* tick_state = Wasm.Internal_for_tests.get_tick_state tree in
    let _ = Printf.printf "took %s ticks in %f s\n%!" (Z.to_string tick) time in
    let _ =
      Printf.printf
        "last tick: %s %s\n%!"
        (Z.to_string info.current_tick)
        (PP.tick_label tick_state)
    in
    return tree

  let run_scenario scenario =
    let open Lwt_syntax in
    let kernel = scenario.kernel in
    let aux kernel =
      let rec go tree = function
        | [] -> return tree
        | (label, action) :: q ->
            let* tree = run_action label tree action in
            go tree q
      in
      let* _, tree = Exec.initial_boot_sector_from_kernel kernel in
      let* _ = go tree scenario.actions in
      return ()
    in
    Exec.run kernel aux
end