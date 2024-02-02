(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
(*                                                                           *)
(*****************************************************************************)

module type SimulationBackend = sig
  val simulate_and_read :
    input:Simulation.Encodings.simulate_input ->
    Simulation.Encodings.insights tzresult Lwt.t
end

module Make (SimulationBackend : SimulationBackend) = struct
  let simulate_call call =
    let open Lwt_result_syntax in
    let*? messages = Simulation.encode call in
    let insight_requests =
      [
        Simulation.Encodings.Durable_storage_key ["evm"; "simulation_gas"];
        Simulation.Encodings.Durable_storage_key ["evm"; "simulation_result"];
        Simulation.Encodings.Durable_storage_key ["evm"; "simulation_status"];
      ]
    in
    let* results =
      SimulationBackend.simulate_and_read
        ~input:
          {
            messages;
            reveal_pages = None;
            insight_requests;
            log_kernel_debug_file = Some "simulate_call";
          }
    in
    Simulation.call_result results

  let estimate_gas call =
    let open Lwt_result_syntax in
    let*? messages = Simulation.encode call in
    let insight_requests =
      [
        Simulation.Encodings.Durable_storage_key ["evm"; "simulation_gas"];
        Simulation.Encodings.Durable_storage_key ["evm"; "simulation_result"];
        Simulation.Encodings.Durable_storage_key ["evm"; "simulation_status"];
      ]
    in
    let* results =
      SimulationBackend.simulate_and_read
        ~input:
          {
            messages;
            reveal_pages = None;
            insight_requests;
            log_kernel_debug_file = Some "estimate_gas";
          }
    in
    Simulation.gas_estimation results

  let is_tx_valid tx_raw =
    let open Lwt_result_syntax in
    let*? messages = Simulation.encode_tx tx_raw in
    let insight_requests =
      [
        Simulation.Encodings.Durable_storage_key ["evm"; "simulation_gas"];
        Simulation.Encodings.Durable_storage_key ["evm"; "simulation_result"];
        Simulation.Encodings.Durable_storage_key ["evm"; "simulation_status"];
      ]
    in
    let* results =
      SimulationBackend.simulate_and_read
        ~input:
          {
            messages;
            reveal_pages = None;
            insight_requests;
            log_kernel_debug_file = Some "tx_validity";
          }
    in
    Simulation.is_tx_valid results
end
