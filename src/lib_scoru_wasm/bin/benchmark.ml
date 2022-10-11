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

(** a simple scenario using a version of the tx_kernel from integration tests *)
let scenario_tx_kernel =
  let open Scenario in
  make_scenario
    "src/lib_scoru_wasm/bin/inputs/tx_kernel.wasm"
    [
      make_scenario_step
        "incorrect input"
        (exec_on_message ~from_binary:false "test");
      make_scenario_step "Deposit" (exec_on_message "deposit.out");
      make_scenario_step "Withdraw" (exec_on_message "withdrawal.out");
    ]

let () = Lwt_main.run @@ Scenario.run_scenario scenario_tx_kernel
