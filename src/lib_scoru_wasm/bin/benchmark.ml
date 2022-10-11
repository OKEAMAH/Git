(** Benchmarking
    -------
    Component:    Wasm PVM
    Invocation:   dune exec src/lib_scoru_wasm/bin/benchmark.exe 
    Subject:      Measure nb of ticks
    
    Kernels: 
    - src/lib_scoru_wasm/test/wasm_kernels/
    - src/proto_alpha/lib_protocol/test/integration/wasm_kernel/


*)

open Lib_scenario
open Lib_exec

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

let scenario_computation_kernel =
  Scenario.make_scenario
    "computation kernel"
    "src/lib_scoru_wasm/bin/kernels/computation.wasm"
    [
      Scenario.make_scenario_step
        "Dummy Message"
        (Scenario.exec_on_message ~from_binary:false 2_004 "dummy");
    ]

let scenario_unreachable_kernel =
  Scenario.make_scenario
    "unreachable kernel"
    "src/lib_scoru_wasm/bin/kernels/unreachable.wasm"
    [
      Scenario.make_scenario_step
        "Dummy Message"
        (Scenario.exec_on_message ~from_binary:false 2_004 "dummy");
    ]

let () =
  Lwt_main.run
  @@ Scenario.run_scenarios
       ~verbose:true
       ~totals:false
       ~irmin:false
       [
         scenario_unreachable_kernel;
         scenario_computation_kernel;
         scenario_tx_kernel_deposit_then_withdraw_to_same_address;
         scenario_tx_kernel_deposit_transfer_withdraw;
         scenario_tx_kernel_deposit_transfer_withdraw_all_in_one;
       ]
