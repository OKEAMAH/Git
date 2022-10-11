(** Benchmarking
    -------
    Component:    Wasm PVM
    Invocation:   dune exec src/lib_scoru_wasm/bin/benchmark.exe 
    Subject:      Measure nb of ticks
    
    Kernels: 
    -  src/lib_scoru_wasm/test/wasm_kernels/
    - src/proto_alpha/lib_protocol/test/integration/wasm_kernel/
*)

open Lib_scenario
open Lib_exec
open Exec

let scenario_tx_kernel =
  let open Scenario in
  make_scenario
    "src/lib_scoru_wasm/bin/inputs/tx_kernel.wasm"
    [
      make_action "incorrect input" (fun tree ->
          let open Lwt_syntax in
          let message = "test" in
          let* tree = set_input_step 1_000 message tree in
          exec_loop tree);
      make_action "Deposit" (action_from_message 1_001 "deposit");
      make_action "Withdraw" (action_from_message 1_002 "withdrawal");
    ]

let () = Lwt_main.run @@ Scenario.run_scenario scenario_tx_kernel
