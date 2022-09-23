(** Benchmarking
    -------
    Component:    Wasm PVM
    Invocation:   dune exec src/lib_scoru_wasm/bin/csv.exe src/lib_scoru_wasm/test/wasm_kernels/unreachable.wasm
    Subject:      Measure nb of ticks

    Kernels: 
    -  src/lib_scoru_wasm/test/wasm_kernels/
    - src/proto_alpha/lib_protocol/test/integration/wasm_kernel/
*)

open Tezos_scoru_wasm
open Tezos_webassembly_interpreter
module Context = Tezos_context_memory.Context_binary

type Lazy_containers.Lazy_map.tree += Tree of Context.tree

module Tree = struct
  type tree = Context.tree

  include Context.Tree

  let select = function
    | Tree t -> t
    | _ -> raise Tree_encoding.Incorrect_tree_type

  let wrap t = Tree t
end

module Tree_encoding_runner = Tree_encoding.Runner.Make (Tree)
module Wasm = Wasm_pvm.Make (Tree)

module Exec = struct
  (* let rec eval_until_input_requested tree =
     let open Lwt_syntax in
     let* info = Wasm.get_info tree in
     match info.input_request with
     | No_input_required ->
         let* tree =
           Wasm.Internal_for_tests.compute_step_many
             ~max_steps:Int64.max_int
             tree
         in
         eval_until_input_requested tree
     | Input_required -> return tree *)

  let eval_until_input_requested tree =
    let should_continue (pvm_state : Wasm.pvm_state) =
      match pvm_state.input_request with
      | No_input_required -> true
      | Input_required -> false
    in
    Wasm.Internal_for_tests.compute_step_many_until
      ~max_steps:Int64.max_int
      should_continue
      tree

  (** FIXME: very fragile, when the PVM implementation changes, the predicates produced could be way off*)
  let should_continue phase (pvm_state : Wasm.pvm_state) =
    match (phase, pvm_state.tick_state) with
    | `Initialising, Init _ -> true
    | `Linking, Link _ -> true
    | `Decoding, Decode _ -> true
    | ( `Evaluating,
        Eval {step_kont = Tezos_webassembly_interpreter.Eval.(SK_Result _); _} )
      ->
        false
    | `Evaluating, Eval _ -> true
    | _, _ -> false

  let finish_top_level_call tree = eval_until_input_requested tree

  let decode tree =
    Wasm.Internal_for_tests.compute_step_many_until
      ~max_steps:Int64.max_int
      (should_continue `Decoding)
      tree

  let link tree =
    Wasm.Internal_for_tests.compute_step_many_until
      ~max_steps:Int64.max_int
      (should_continue `Linking)
      tree

  let init tree =
    Wasm.Internal_for_tests.compute_step_many_until
      ~max_steps:Int64.max_int
      (should_continue `Initialising)
      tree

  let eval tree =
    Wasm.Internal_for_tests.compute_step_many_until
      ~max_steps:Int64.max_int
      (should_continue `Evaluating)
      tree
end

let read_message name =
  let open Tezt.Base in
  let kernel_file =
    project_root // Filename.dirname __FILE__ // "../test/wasm_kernels"
    // (name ^ ".out")
  in
  read_file kernel_file

let initial_boot_sector_from_kernel ?(max_tick = 2_500_000_000) kernel =
  let open Lwt_syntax in
  let* index = Context.init "/tmp" in
  let context = Context.empty index in
  let tree = Context.Tree.empty context in
  let origination_message =
    Data_encoding.Binary.to_string_exn
      Gather_floppies.origination_message_encoding
    @@ Gather_floppies.Complete_kernel (String.to_bytes kernel)
  in
  let* tree =
    Wasm.Internal_for_tests.initial_tree_from_boot_sector
      ~empty_tree:tree
      origination_message
  in
  let+ tree =
    Wasm.Internal_for_tests.set_max_nb_ticks (Z.of_int max_tick) tree
  in
  (context, tree)

let label_step_kont = function
  | Eval.LS_Start _ -> "ls_start"
  | LS_Craft_frame (_, _) -> "ls_craft_frame"
  | LS_Push_frame (_, _) -> "ls_push_frame"
  | LS_Consolidate_top (_, _, _, _) -> "ls_consolidate_top"
  | LS_Modify_top _ -> "ls_modify_top"

let step_kont_label = function
  | Eval.SK_Start (_, _) -> "sk_start"
  | SK_Next (_, _, kont) -> "sk_next:" ^ label_step_kont kont
  | SK_Consolidate_label_result (_, _, _, _, _, _) ->
      "sk_consolidate_label_result"
  | SK_Result _ -> "sk_result"
  | SK_Trapped _ -> "sk_trapped"

let init_kont_label = function
  | Eval.IK_Start _ -> "ik_start"
  | IK_Add_import _ -> "ik_add_import"
  | IK_Type (_, _) -> "ik_type"
  | IK_Aggregate (_, Func, _) -> "ik_aggregate_func"
  | IK_Aggregate (_, Global, _) -> "ik_aggregate_global"
  | IK_Aggregate (_, Table, _) -> "ik_aggregate_table"
  | IK_Aggregate (_, Memory, _) -> "ik_aggregate_memory"
  | IK_Aggregate_concat (_, Func, _) -> "ik_aggregate_func"
  | IK_Aggregate_concat (_, Global, _) -> "ik_aggregate_global"
  | IK_Aggregate_concat (_, Table, _) -> "ik_aggregate_concat_table"
  | IK_Aggregate_concat (_, Memory, _) -> "ik_aggregate_concat_memory"
  | IK_Exports (_, _) -> "ik_exports"
  | IK_Elems (_, _) -> "ik_elems"
  | IK_Datas (_, _) -> "ik_datas"
  | IK_Es_elems (_, _) -> "ik_es_elems"
  | IK_Es_datas (_, _, _) -> "ik_es_datas"
  | IK_Join_admin (_, _) -> "ik_join_admin"
  | IK_Eval _ -> "ik_eval:"
  | IK_Stop -> "ik_stop"

let tick_label = function
  | Wasm_pvm.Decode _ -> "decode"
  | Init {init_kont; _} -> "init:" ^ init_kont_label init_kont
  | Eval {step_kont; _} -> "eval:" ^ step_kont_label step_kont
  | Stuck _ -> "stuck"
  | Link _ -> "link"

let run kernel k =
  let open Lwt_syntax in
  let* () =
    Lwt_io.with_file ~mode:Lwt_io.Input kernel (fun channel ->
        let* kernel = Lwt_io.read channel in
        k kernel)
  in
  return_unit

let set_input_step message_counter message tree =
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
        (tick_label tick_state)
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
    let* tree =
      run_action ~last_tick:true ~inline:false "Booting" tree exec_loop
    in
    let* _ = go tree scenario.actions in
    return ()
  in
  run kernel apply_scenario

let scenario_tx_kernel =
  make_scenario
    "src/lib_scoru_wasm/test/wasm_kernels/tx_kernel.wasm"
    [
      make_action "incorrect input" (fun tree ->
          let open Lwt_syntax in
          let message = "test" in
          let* tree = set_input_step 1_000 message tree in
          exec_loop tree);
      make_action "Deposit" (action_from_message 1_001 "deposit");
      make_action "Withdraw" (action_from_message 1_002 "withdrawal");
    ]

let () = Lwt_main.run @@ run_scenario scenario_tx_kernel
