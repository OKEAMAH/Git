(** Benchmarking
    -------
    Component:    Wasm PVM
    Invocation:   dune exec src/lib_scoru_wasm/bin/benchmark.exe --profile release
    Subject:      Measure nb of ticks

    Kernels: 
    - src/lib_scoru_wasm/test/wasm_kernels/
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

module Benchmark = struct
  type datum = {
    scenario : string;
    section : string;
    label : string;
    ticks : Z.t;
    time : float;
  }

  let make_datum scenario section label ticks time =
    {scenario; section; label; ticks; time}

  let pp_csv_line scenario section label ticks time =
    Printf.printf
      "\"%s\" , \"%s\" , \"%s\" ,  %s ,  %f \n%!"
      scenario
      section
      label
      (Z.to_string ticks)
      time

  let pp_datum {scenario; section; label; ticks; time} =
    if section != label then pp_csv_line scenario section label ticks time
    else pp_csv_line scenario section "all phases" ticks time

  type benchmark = {
    verbose : bool;
    current_scenario : string;
    current_section : string;
    data : datum list;
    total_time : float;
    total_tick : Z.t;
  }

  let empty_benchmark =
    {
      verbose = false;
      current_scenario = "";
      current_section = "";
      data = [];
      total_time = 0.;
      total_tick = Z.zero;
    }

  let init_scenario benchmark verbose scenario =
    {
      benchmark with
      verbose;
      current_scenario = scenario;
      current_section = "Booting " ^ scenario;
    }

  (* let switch_scenario benchmark current_scenario =
     {benchmark with current_scenario} *)

  let switch_section benchmark current_section =
    {benchmark with current_section}

  let add_datum benchmark name ticks time =
    let datum =
      make_datum
        benchmark.current_scenario
        benchmark.current_section
        name
        ticks
        time
    in
    {benchmark with data = datum :: benchmark.data}

  let add_final_info benchmark total_time total_tick =
    let datum =
      make_datum
        benchmark.current_scenario
        "all steps"
        "total"
        total_tick
        total_time
    in
    {benchmark with data = datum :: benchmark.data}

  let pp_benchmark benchmark =
    let rec go = function
      | [] -> ()
      | datum :: q ->
          pp_datum datum ;
          go q
    in
    go (List.rev benchmark.data)
end

module Exec = struct
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

  let run kernel k =
    let open Lwt_syntax in
    let* res =
      Lwt_io.with_file ~mode:Lwt_io.Input kernel (fun channel ->
          let* kernel = Lwt_io.read channel in
          k kernel)
    in
    return res

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

  let read_message_from_tests name =
    let open Tezt.Base in
    let kernel_file =
      project_root // Filename.dirname __FILE__ // "../test/wasm_kernels"
      // (name ^ ".out")
    in
    read_file kernel_file

  let read_message name =
    let open Tezt.Base in
    let kernel_file =
      project_root // Filename.dirname __FILE__ // "messages" // name
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
end

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

module Scenario = struct
  open Benchmark

  type action = benchmark -> Wasm.tree -> (benchmark * Wasm.tree) Lwt.t

  type scenario_step = string * action

  type scenario = {name : string; kernel : string; actions : scenario_step list}

  let make_scenario name kernel actions = {name; kernel; actions}

  let make_scenario_step (label : string) (action : action) : scenario_step =
    (label, action)

  let run_action ?(inline = true) ?(last_tick = false) benchmark name tree
      (action : action) =
    let open Lwt_syntax in
    (* Before *)
    let before = Unix.gettimeofday () in
    let* info = Wasm.get_info tree in
    let before_tick = info.current_tick in
    let _ =
      if (not inline) && benchmark.verbose then
        Printf.printf
          "=========\n%s \nStart at tick %s\n-----\n%!"
          name
          (Z.to_string info.current_tick)
    in

    (* Act *)
    let* benchmark, tree = action benchmark tree in

    (* Result *)
    let time = Unix.gettimeofday () -. before in
    let* info = Wasm.get_info tree in
    let tick = Z.(info.current_tick - before_tick) in
    let* tick_state = Wasm.Internal_for_tests.get_tick_state tree in
    let _ = if (not inline) && benchmark.verbose then Printf.printf "-----\n" in
    let _ =
      if benchmark.verbose then
        Printf.printf
          "%s took %s ticks in %f s\n%!"
          name
          (Z.to_string tick)
          time
    in
    let _ =
      if last_tick && benchmark.verbose then
        Printf.printf
          "last tick: %s %s\n%!"
          (Z.to_string info.current_tick)
          (tick_label tick_state)
    in
    return (add_datum benchmark name tick time, tree)

  let raise action =
    let open Lwt_syntax in
    fun benchmark tree ->
      let* tree = action tree in
      return (benchmark, tree)

  let exec_loop : action =
   fun benchmark tree ->
    let open Lwt_syntax in
    let* benchmark, tree =
      run_action benchmark "Decoding" tree (raise Exec.decode)
    in
    let* benchmark, tree =
      run_action benchmark "Linking" tree (raise Exec.link)
    in
    let* benchmark, tree =
      run_action benchmark "Initialisation" tree (raise Exec.init)
    in
    let* benchmark, tree =
      run_action benchmark "Evaluation" tree (raise Exec.eval)
    in
    let* benchmark, tree =
      run_action benchmark "Finish" tree (raise Exec.finish_top_level_call)
    in
    return (benchmark, tree)

  let action_from_message step message : action =
   fun benchmark tree ->
    let open Lwt_syntax in
    let message = Exec.read_message message in
    let* tree = Exec.set_input_step step message tree in
    exec_loop benchmark tree

  let run_scenario ?(verbose = true) ?(benchmark = None) scenario =
    let open Lwt_syntax in
    let apply_scenario kernel =
      let rec go benchmark tree = function
        | [] -> return (benchmark, tree)
        | (label, action) :: q ->
            let benchmark = switch_section benchmark label in
            let* benchmark, tree =
              run_action
                ~last_tick:true
                ~inline:false
                benchmark
                label
                tree
                action
            in
            go benchmark tree q
      in
      let start = Unix.gettimeofday () in
      let* _, tree = Exec.initial_boot_sector_from_kernel kernel in
      let old_benchmark =
        match benchmark with None -> empty_benchmark | Some b -> b
      in
      let benchmark = init_scenario old_benchmark verbose scenario.name in
      let* benchmark, tree =
        run_action
          ~last_tick:true
          ~inline:false
          benchmark
          benchmark.current_section
          tree
          exec_loop
      in
      let* benchmark, tree = go benchmark tree scenario.actions in
      let finish = Unix.gettimeofday () in
      let* info = Wasm.get_info tree in
      let benchmark =
        add_final_info benchmark (finish -. start) info.current_tick
      in
      return benchmark
    in
    Exec.run scenario.kernel apply_scenario

  let run_scenarios ?(verbose = true) scenarios =
    let open Lwt_syntax in
    let rec go benchmark_opt = function
      | [] ->
          pp_benchmark (Option.value benchmark_opt ~default:empty_benchmark) ;
          return_unit
      | t :: q ->
          let* benchmark = run_scenario ~verbose ~benchmark:benchmark_opt t in
          go (Some benchmark) q
    in
    go None scenarios
end

let scenario_tx_kernel_deposit_then_withdraw_to_same_address =
  Scenario.make_scenario
    "tx_kernel - deposit_then_withdraw_to_same_address"
    "src/lib_scoru_wasm/bin/kernels/tx_kernel/tx_kernal_deb95799cc.wasm"
    [
      Scenario.make_scenario_step "incorrect input" (fun benchmark tree ->
          let open Lwt_syntax in
          let message = "test" in
          let* tree = Exec.set_input_step 1_000 message tree in
          Scenario.exec_loop benchmark tree);
      Scenario.make_scenario_step
        "Deposit"
        (Scenario.action_from_message
           1_001
           "tx_kernel/deposit_then_withdraw_to_same_address/deposit.out");
      Scenario.make_scenario_step
        "Withdraw"
        (Scenario.action_from_message
           1_002
           "tx_kernel/deposit_then_withdraw_to_same_address/withdrawal.out");
      Scenario.make_scenario_step "Deposit+Withdrawal" (fun benchmark tree ->
          let open Lwt_syntax in
          let message =
            Exec.read_message
              "tx_kernel/deposit_then_withdraw_to_same_address/deposit.out"
          in
          let* tree = Exec.set_input_step 1_003 message tree in
          let message =
            Exec.read_message
              "tx_kernel/deposit_then_withdraw_to_same_address/withdrawal.out"
          in
          let* tree = Exec.set_input_step 1_004 message tree in
          Scenario.exec_loop benchmark tree);
    ]

let scenario_tx_kernel_deposit_transfer_withdraw =
  Scenario.make_scenario
    "tx_kernel - deposit_transfer_withdraw"
    "src/lib_scoru_wasm/bin/kernels/tx_kernel/tx_kernal_deb95799cc.wasm"
    [
      Scenario.make_scenario_step
        "First Deposit"
        (Scenario.action_from_message
           2_001
           "tx_kernel/deposit_transfer_withdraw/fst_deposit_message.out");
      Scenario.make_scenario_step
        "Second Deposit"
        (Scenario.action_from_message
           2_002
           "tx_kernel/deposit_transfer_withdraw/snd_deposit_message.out");
      Scenario.make_scenario_step
        "Invalid Message"
        (Scenario.action_from_message
           2_003
           "tx_kernel/deposit_transfer_withdraw/invalid_external_message.out");
      Scenario.make_scenario_step
        "Valid Message"
        (Scenario.action_from_message
           2_004
           "tx_kernel/deposit_transfer_withdraw/valid_external_message.out");
    ]

let scenario_computation_kernel =
  Scenario.make_scenario
    "computation kernel"
    "src/proto_alpha/lib_protocol/test/integration/wasm_kernel/computation.wasm"
    []

let () =
  Lwt_main.run
  @@ Scenario.run_scenarios
       ~verbose:false
       [
         scenario_tx_kernel_deposit_then_withdraw_to_same_address;
         scenario_tx_kernel_deposit_transfer_withdraw;
         scenario_computation_kernel;
       ]
