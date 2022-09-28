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
    totals : bool;
    irmin : bool;
    current_scenario : string;
    current_section : string;
    data : datum list;
    total_time : float;
    total_tick : Z.t;
  }

  let empty_benchmark ?(verbose = false) ?(totals = true) ?(irmin = true) () =
    {
      verbose;
      totals;
      irmin;
      current_scenario = "";
      current_section = "";
      data = [];
      total_time = 0.;
      total_tick = Z.zero;
    }

  let init_scenario benchmark scenario =
    {
      benchmark with
      current_scenario = scenario;
      current_section = "Booting " ^ scenario;
    }

  (* let switch_scenario benchmark current_scenario =
     {benchmark with current_scenario} *)

  let switch_section benchmark current_section =
    {benchmark with current_section}

  let add_datum benchmark name ticks time =
    if (not benchmark.totals) && benchmark.current_section = name then benchmark
    else
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
    if benchmark.totals then
      let datum =
        make_datum
          benchmark.current_scenario
          "all steps"
          "total"
          total_tick
          total_time
      in
      {benchmark with data = datum :: benchmark.data}
    else benchmark

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
  let should_continue_until_input_requested (pvm_state : Wasm.pvm_state) =
    match pvm_state.input_request with
    | No_input_required -> true
    | Input_required -> false

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

  let finish_top_level_call_on_state pvm_state =
    Wasm.Internal_for_tests.compute_step_many_until_pvm_state
      ~max_steps:Int64.max_int
      should_continue_until_input_requested
      pvm_state

  let execute_on_tree phase tree =
    Wasm.Internal_for_tests.compute_step_many_until
      ~max_steps:Int64.max_int
      (should_continue phase)
      tree

  let execute_on_state phase state =
    Wasm.Internal_for_tests.compute_step_many_until_pvm_state
      ~max_steps:Int64.max_int
      (should_continue phase)
      state

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

  let get_tick_from_tree tree =
    let open Lwt_syntax in
    let* info = Wasm.get_info tree in
    return info.current_tick

  let pp_header_section benchmark tree =
    let open Lwt_syntax in
    let* before_tick = get_tick_from_tree tree in
    if benchmark.verbose then
      Printf.printf
        "=========\n%s \nStart at tick %s\n-----\n%!"
        benchmark.current_section
        (Z.to_string before_tick) ;
    return (before_tick, Unix.gettimeofday ())

  let pp_footer_section benchmark tree before_tick before_time =
    let open Lwt_syntax in
    let time = Unix.gettimeofday () -. before_time in
    let* after_tick = get_tick_from_tree tree in
    let tick = Z.(after_tick - before_tick) in
    let* tick_state = Wasm.Internal_for_tests.get_tick_state tree in
    let _ = if benchmark.verbose then Printf.printf "-----\n" in
    let _ =
      if benchmark.verbose then
        Printf.printf
          "%s took %s ticks in %f s\n%!"
          benchmark.current_section
          (Z.to_string tick)
          time
    in
    let _ =
      if benchmark.verbose then
        Printf.printf
          "last tick: %s %s\n%!"
          (Z.to_string after_tick)
          (tick_label tick_state)
    in
    return_unit

  let run_action_ get_tick (benchmark : benchmark) name tree action =
    let open Lwt_syntax in
    (* Before *)
    let before = Unix.gettimeofday () in
    let* before_tick = get_tick tree in

    (* Act *)
    let* benchmark, tree = action benchmark tree in
    let _ = if benchmark.verbose then Printf.printf "" in

    (* Result *)
    let time = Unix.gettimeofday () -. before in
    let* after_tick = get_tick tree in
    let tick = Z.(after_tick - before_tick) in
    let _ =
      if benchmark.verbose && not (benchmark.current_section = name) then
        Printf.printf
          "%s finished in %s ticks %f s\n%!"
          name
          (Z.to_string tick)
          time
    in

    return (add_datum benchmark name tick time, tree)

  let run_action_on_tree = run_action_ get_tick_from_tree

  let get_tick_from_pvm_state (pvm_state : Wasm.pvm_state) =
    Lwt.return pvm_state.current_tick

  let run_action_on_pvm_state = run_action_ get_tick_from_pvm_state

  let run_action_with_headers benchmark name tree action =
    let open Lwt_syntax in
    let* before_tick, before_time = pp_header_section benchmark tree in
    let* benchmark, tree = run_action_on_tree benchmark name tree action in
    let* _ = pp_footer_section benchmark tree before_tick before_time in
    return (benchmark, tree)

  let raise action =
    let open Lwt_syntax in
    fun benchmark tree ->
      let* tree = action tree in
      return (benchmark, tree)

  let decode benchmark tree =
    let open Lwt_syntax in
    let before = Unix.gettimeofday () in
    let* pvm_state = Wasm.Internal_for_tests.decode tree in
    let time = Unix.gettimeofday () -. before in
    let tick = Z.zero in
    let _ =
      if benchmark.verbose then
        Printf.printf "Decode tree finished in %f s\n%!" time
    in
    if benchmark.irmin then
      return (add_datum benchmark "Decode tree" tick time, pvm_state)
    else return (benchmark, pvm_state)

  let encode benchmark pvm_state tree =
    let open Lwt_syntax in
    let before = Unix.gettimeofday () in
    let* tree = Wasm.Internal_for_tests.encode pvm_state tree in
    let time = Unix.gettimeofday () -. before in
    let tick = Z.zero in
    let _ =
      if benchmark.verbose then
        Printf.printf "Encode tree finished in %f s\n%!" time
    in
    if benchmark.irmin then
      return (add_datum benchmark "Decode tree" tick time, tree)
    else return (benchmark, tree)

  let exec_loop : action =
   fun benchmark tree ->
    let open Lwt_syntax in
    let* benchmark, pvm_state = decode benchmark tree in
    let* benchmark, pvm_state =
      run_action_on_pvm_state
        benchmark
        "Decoding"
        pvm_state
        (raise @@ Exec.execute_on_state `Decoding)
    in
    let* benchmark, pvm_state =
      run_action_on_pvm_state
        benchmark
        "Linking"
        pvm_state
        (raise @@ Exec.execute_on_state `Linking)
    in
    let* benchmark, pvm_state =
      run_action_on_pvm_state
        benchmark
        "Initialisation"
        pvm_state
        (raise @@ Exec.execute_on_state `Initialising)
    in
    let* benchmark, pvm_state =
      run_action_on_pvm_state
        benchmark
        "Evaluation"
        pvm_state
        (raise @@ Exec.execute_on_state `Evaluating)
    in
    let* benchmark, pvm_state =
      run_action_on_pvm_state
        benchmark
        "Finish"
        pvm_state
        (raise Exec.finish_top_level_call_on_state)
    in
    let* benchmark, tree = encode benchmark pvm_state tree in
    return (benchmark, tree)

  let exec_on_message step message : action =
   fun benchmark tree ->
    let open Lwt_syntax in
    let message = Exec.read_message message in
    let* tree = Exec.set_input_step step message tree in
    exec_loop benchmark tree

  let exec_on_messages step messages : action =
   fun benchmark tree ->
    let open Lwt_syntax in
    let rec go step benchmark tree = function
      | [] -> exec_loop benchmark tree
      | message :: q ->
          let message = Exec.read_message message in
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
      let* _, tree = Exec.initial_boot_sector_from_kernel kernel in
      let benchmark = init_scenario benchmark scenario.name in
      let* benchmark, tree =
        run_action_with_headers
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

  let run_scenarios ?(verbose = true) ?(totals = true) ?(irmin = true) scenarios
      =
    let open Lwt_syntax in
    let rec go benchmark = function
      | [] ->
          pp_benchmark benchmark ;
          return_unit
      | t :: q ->
          let* benchmark = run_scenario ~benchmark t in
          go benchmark q
    in
    go (empty_benchmark ~verbose ~totals ~irmin ()) scenarios
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
        (Scenario.exec_on_message
           1_001
           "tx_kernel/deposit_then_withdraw_to_same_address/deposit.out");
      Scenario.make_scenario_step
        "Withdraw"
        (Scenario.exec_on_message
           1_002
           "tx_kernel/deposit_then_withdraw_to_same_address/withdrawal.out");
      Scenario.make_scenario_step
        "Deposit+Withdraw"
        (Scenario.exec_on_messages
           1_003
           [
             "tx_kernel/deposit_then_withdraw_to_same_address/deposit.out";
             "tx_kernel/deposit_then_withdraw_to_same_address/withdrawal.out";
           ]);
    ]

let scenario_tx_kernel_deposit_transfer_withdraw =
  Scenario.make_scenario
    "tx_kernel - deposit_transfer_withdraw"
    "src/lib_scoru_wasm/bin/kernels/tx_kernel/tx_kernal_deb95799cc.wasm"
    [
      Scenario.make_scenario_step
        "First Deposit"
        (Scenario.exec_on_message
           2_001
           "tx_kernel/deposit_transfer_withdraw/fst_deposit_message.out");
      Scenario.make_scenario_step
        "Second Deposit"
        (Scenario.exec_on_message
           2_002
           "tx_kernel/deposit_transfer_withdraw/snd_deposit_message.out");
      Scenario.make_scenario_step
        "Invalid Message"
        (Scenario.exec_on_message
           2_003
           "tx_kernel/deposit_transfer_withdraw/invalid_external_message.out");
      Scenario.make_scenario_step
        "Valid Message"
        (Scenario.exec_on_message
           2_004
           "tx_kernel/deposit_transfer_withdraw/valid_external_message.out");
    ]

let scenario_tx_kernel_deposit_transfer_withdraw_all_in_one =
  Scenario.make_scenario
    "tx_kernel - deposit_transfer_withdraw_all_in_one "
    "src/lib_scoru_wasm/bin/kernels/tx_kernel/tx_kernal_deb95799cc.wasm"
    [
      Scenario.make_scenario_step
        "all_in_one "
        (Scenario.exec_on_messages
           3_000
           [
             "tx_kernel/deposit_transfer_withdraw/fst_deposit_message.out";
             "tx_kernel/deposit_transfer_withdraw/snd_deposit_message.out";
             "tx_kernel/deposit_transfer_withdraw/invalid_external_message.out";
             "tx_kernel/deposit_transfer_withdraw/valid_external_message.out";
           ]);
    ]

let scenario_tx_kernel_deposit_transfer_withdraw_many_transfers =
  Scenario.make_scenario
    "tx_kernel - deposit_transfer_withdraw_all_in_one "
    "src/lib_scoru_wasm/bin/kernels/tx_kernel/tx_kernal_deb95799cc.wasm"
    [
      Scenario.make_scenario_step
        "just deposits"
        (Scenario.exec_on_messages
           3_000
           [
             "tx_kernel/deposit_transfer_withdraw/fst_deposit_message.out";
             "tx_kernel/deposit_transfer_withdraw/snd_deposit_message.out";
           ]);
      Scenario.make_scenario_step
        "many transfers"
        (Scenario.exec_on_messages
           3_000
           [
             "tx_kernel/deposit_transfer_withdraw/fst_deposit_message.out";
             "tx_kernel/deposit_transfer_withdraw/snd_deposit_message.out";
             "tx_kernel/deposit_transfer_withdraw/big_external_message.out";
           ]);
    ]

let scenario_computation_kernel =
  Scenario.make_scenario
    "computation kernel"
    "src/proto_alpha/lib_protocol/test/integration/wasm_kernel/computation.wasm"
    []

let () =
  Lwt_main.run
  @@ Scenario.run_scenarios
       ~verbose:true
       ~totals:false
       ~irmin:false
       [
         (* scenario_tx_kernel_deposit_then_withdraw_to_same_address;
            scenario_tx_kernel_deposit_transfer_withdraw;
            scenario_tx_kernel_deposit_transfer_withdraw_all_in_one; *)
         scenario_tx_kernel_deposit_transfer_withdraw_many_transfers
         (* scenario_computation_kernel; *);
       ]
