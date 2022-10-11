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

open Inputs

let scenario_tx_kernel_deposit_then_withdraw_to_same_address_ name kernel =
  Scenario.make_scenario
    name
    kernel
    [
      Scenario.make_scenario_step
        "incorrect input"
        (Scenario.exec_on_message ~from_binary:false 1_000 "incorrect");
      Scenario.make_scenario_step
        "Deposit"
        (Scenario.exec_on_message 1_001 Messages.Old.deposit);
      Scenario.make_scenario_step
        "Withdraw"
        (Scenario.exec_on_message 1_002 Messages.Old.withdrawal);
      Scenario.make_scenario_step
        "Deposit+Withdraw"
        (Scenario.exec_on_messages
           1_003
           [Messages.Old.deposit; Messages.Old.withdrawal]);
    ]

let scenario_tx_kernel_deposit_then_withdraw_to_same_address_no_sig =
  scenario_tx_kernel_deposit_then_withdraw_to_same_address_
    "tx_kernel - deposit_then_withdraw_to_same_address NOSIG"
    Kernels.tx_kernel_vRAM_nosig

let scenario_tx_kernel_deposit_then_withdraw_to_same_address_sig =
  scenario_tx_kernel_deposit_then_withdraw_to_same_address_
    "tx_kernel - deposit_then_withdraw_to_same_address SIG"
    Kernels.tx_kernal_vRam_latest

let scenario_tx_kernel_deposit_transfer_withdraw =
  Scenario.make_scenario
    "tx_kernel - deposit_transfer_withdraw"
    Kernels.tx_kernel_vRAM_nosig
    [
      Scenario.make_scenario_step
        "First Deposit"
        (Scenario.exec_on_message
           2_001
           Messages.Deposit_transfer_withdraw.fst_deposit);
      Scenario.make_scenario_step
        "Second Deposit"
        (Scenario.exec_on_message
           2_002
           Messages.Deposit_transfer_withdraw.snd_deposit);
      Scenario.make_scenario_step
        "Invalid Message"
        (Scenario.exec_on_message
           2_003
           Messages.Deposit_transfer_withdraw.invalid_message);
      Scenario.make_scenario_step
        "Valid Message"
        (Scenario.exec_on_message
           2_004
           Messages.Deposit_transfer_withdraw.valid_message);
    ]

let scenario_tx_kernel_deposit_transfer_withdraw_all_in_one =
  Scenario.make_scenario
    "tx_kernel - deposit_transfer_withdraw_all_in_one "
    Kernels.tx_kernel_vRAM_nosig
    [
      Scenario.make_scenario_step
        "all_in_one "
        (Scenario.exec_on_messages
           3_000
           [
             Messages.Deposit_transfer_withdraw.fst_deposit;
             Messages.Deposit_transfer_withdraw.snd_deposit;
             Messages.Deposit_transfer_withdraw.invalid_message;
             Messages.Deposit_transfer_withdraw.valid_message;
           ]);
    ]

let scenario_tx_kernel_deposit_transfer_withdraw_many_transfers =
  Scenario.make_scenario
    "tx_kernel - deposit_transfer_withdraw_all_in_one_sig "
    Kernels.tx_kernel_vRAM_nosig
    [
      Scenario.make_scenario_step
        "just deposits"
        (Scenario.exec_on_messages
           3_000
           [
             Messages.Deposit_transfer_withdraw.fst_deposit;
             Messages.Deposit_transfer_withdraw.snd_deposit;
           ]);
      Scenario.make_scenario_step
        "many transfers"
        (Scenario.exec_on_messages
           3_000
           [
             Messages.Deposit_transfer_withdraw.fst_deposit;
             Messages.Deposit_transfer_withdraw.snd_deposit;
             Messages.Large.transfer_two_actors;
           ]);
    ]

let scenario_computation_kernel =
  Scenario.make_scenario
    "computation kernel"
    Kernels.computation_kernel
    [
      Scenario.make_scenario_step
        "Dummy Message"
        (Scenario.exec_on_message ~from_binary:false 2_004 "dummy");
    ]

let scenario_unreachable_kernel =
  Scenario.make_scenario
    "unreachable kernel"
    Kernels.unreachable_kernel
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
         scenario_tx_kernel_deposit_then_withdraw_to_same_address_no_sig;
         scenario_tx_kernel_deposit_then_withdraw_to_same_address_sig;
         scenario_tx_kernel_deposit_transfer_withdraw;
         scenario_tx_kernel_deposit_transfer_withdraw_all_in_one;
         scenario_tx_kernel_deposit_transfer_withdraw_many_transfers;
       ]
