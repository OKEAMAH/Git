(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

open Prometheus

let sc_rollup_node_registry = CollectorRegistry.create ()

let namespace = Tezos_version.Node_version.namespace

let subsystem = "sc_rollup_node"

(** Registers a gauge in [sc_rollup_node_registry] *)
let v_gauge = Gauge.v ~registry:sc_rollup_node_registry ~namespace ~subsystem

let injected_operations_queue_size =
  v_gauge
    ~help:"Size of Injector's injected operations queue size"
    "injected_operations_queue_size"

let set_injected_operations_queue_size s =
  Prometheus.Gauge.set injected_operations_queue_size (Int.to_float s)

let included_operations_queue_size =
  v_gauge
    ~help:"Size of Injector's included operations queue size"
    "included_operations_queue_size"

let set_included_operations_queue_size s =
  Prometheus.Gauge.set included_operations_queue_size (Int.to_float s)

(*let last_batch_level = v_gauge ~help:"Level of last batch" "last_batch_level"

  let set_last_batch_level l =
    Prometheus.Gauge.set last_batch_level (Int32.to_float l)

  let last_batch_time = v_gauge ~help:"Time of last batch" "last_batch_time"

  let set_last_batch_time pt =
    Prometheus.Gauge.set last_batch_time (Ptime.to_float_s pt)
*)
