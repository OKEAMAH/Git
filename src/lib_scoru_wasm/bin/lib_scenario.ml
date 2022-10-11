open Tezos_scoru_wasm
open Pvm_instance
open Lib_benchmark
open Lib_exec
open Wasm_pvm_state

module Scenario = struct
  open Data
  open Wasm

  type action = benchmark -> tree -> (benchmark * tree) Lwt.t

  type scenario_step = string * action

  type scenario = {name : string; kernel : string; actions : scenario_step list}

  let make_scenario name kernel actions = {name; kernel; actions}

  let make_scenario_step (label : string) (action : action) : scenario_step =
    (label, action)

  let run_action_ get_tick (benchmark : benchmark) name tree action =
    let open Lwt_syntax in
    (* Before *)
    let before = Unix.gettimeofday () in
    let* before_tick = get_tick tree in

    (* Act *)
    let* benchmark, tree = action benchmark tree in

    (* Result *)
    let time = Unix.gettimeofday () -. before in
    let* after_tick = get_tick tree in
    let tick = Z.(after_tick - before_tick) in
    Data.Pp.footer_action benchmark name tick time ;
    return (add_datum benchmark name tick time, tree)

  let run_action_on_tree = run_action_ get_tick_from_tree

  let run_action_on_pvm_state = run_action_ get_tick_from_pvm_state

  let run_action_with_headers benchmark name tree action =
    let open Lwt_syntax in
    let* before_tick, before_time = Data.Pp.pp_header_section benchmark tree in
    let* benchmark, tree = run_action_on_tree benchmark name tree action in
    let* _ = Data.Pp.pp_footer_section benchmark tree before_tick before_time in
    return (benchmark, tree)

  let raise action =
    let open Lwt_syntax in
    fun benchmark tree ->
      let* tree = action tree in
      return (benchmark, tree)

  let decode benchmark tree =
    let open Lwt_syntax in
    let before = Unix.gettimeofday () in
    let* pvm_state = Wasm.Internal_for_benchmark.decode tree in
    let time = Unix.gettimeofday () -. before in
    let benchmark = Data.add_decode_datum benchmark time in
    return (benchmark, pvm_state)

  let encode benchmark pvm_state tree =
    let open Lwt_syntax in
    let before = Unix.gettimeofday () in
    let* tree = Wasm.Internal_for_benchmark.encode pvm_state tree in
    let time = Unix.gettimeofday () -. before in
    let benchmark = Data.add_encode_datum benchmark time in
    return (benchmark, tree)

  let exec_phase (benchmark, pvm_state) phase =
    run_action_on_pvm_state
      benchmark
      (Exec.pp_phase phase)
      pvm_state
      (raise @@ Exec.execute_on_state phase)

  let exec_loop benchmark tree =
    let open Lwt_syntax in
    let* benchmark, pvm_state = decode benchmark tree in
    let* benchmark, pvm_state =
      Exec.run_loop exec_phase (benchmark, pvm_state)
    in
    let* benchmark, tree = encode benchmark pvm_state tree in
    return (benchmark, tree)

  let exec_on_message ?(from_binary = true) step message : action =
   fun benchmark tree ->
    let open Lwt_syntax in
    let message = if from_binary then Exec.read_message message else message in
    let* tree = Exec.set_input_step step message tree in
    exec_loop benchmark tree

  let exec_on_messages ?(from_binary = true) step messages : action =
   fun benchmark tree ->
    let open Lwt_syntax in
    let rec go step benchmark tree = function
      | [] -> exec_loop benchmark tree
      | message :: q ->
          let message =
            if from_binary then Exec.read_message message else message
          in
          let* tree = Exec.set_input_step step message tree in
          go (step + 1) benchmark tree q
    in
    go step benchmark tree messages

  let run_scenario ~benchmark scenario =
    let open Lwt_syntax in
    let apply_scenario kernel =
      let rec go benchmark tree = function
        | [] -> return (benchmark, tree)
        | (label, action) :: q ->
            let benchmark = switch_section benchmark label in
            let* benchmark, tree =
              run_action_with_headers benchmark label tree action
            in
            go benchmark tree q
      in
      let start = Unix.gettimeofday () in
      let* tree = Exec.initial_boot_sector_from_kernel kernel in
      let benchmark = init_scenario benchmark scenario.name in
      let _ = Data.Pp.pp_scenario_header benchmark scenario.name in
      let* benchmark, tree = go benchmark tree scenario.actions in
      let finish = Unix.gettimeofday () in
      let* info = Wasm.get_info tree in
      let benchmark =
        add_final_info benchmark (finish -. start) info.current_tick
      in
      return benchmark
    in
    Exec.run scenario.kernel apply_scenario

  let run_scenarios ?(verbose = true) ?(totals = true) ?(irmin = true) scenarios
      =
    let open Lwt_syntax in
    let rec go benchmark = function
      | [] ->
          Data.Pp.pp_benchmark benchmark ;
          return_unit
      | t :: q ->
          let* benchmark = run_scenario ~benchmark t in
          go benchmark q
    in
    go (empty_benchmark ~verbose ~totals ~irmin ()) scenarios
end