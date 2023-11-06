(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

open Prometheus

let namespace = Tezos_version.Node_version.namespace

(** Registers a gauge in [sc_rollup_node_registry] *)
let v_gauge ~registry = Gauge.v ~registry ~namespace

let injected_operations_queue_size =
  v_gauge
    ~help:"Size of Injector's injected operations queue size"
    "injected_operations_queue_size"

let set_injected_operations_queue_size ~registry s =
  Prometheus.Gauge.set
    (injected_operations_queue_size ~registry)
    (Int.to_float s)

let included_operations_queue_size =
  v_gauge
    ~help:"Size of Injector's included operations queue size"
    "included_operations_queue_size"

let set_included_operations_queue_size ~registry s =
  Prometheus.Gauge.set
    (included_operations_queue_size ~registry)
    (Int.to_float s)

let worker_queue_size ~registry ~tag =
  v_gauge
    ~registry
    ~help:
      (Format.asprintf
         "Size of Injector's worker queue for operation tag %s"
         tag)
    (Format.asprintf "injector_worker_queue_size_%s" tag)

let set_worker_queue_size :
    registry:CollectorRegistry.t -> tag:string -> int -> unit =
 fun ~registry ~tag sz ->
  Prometheus.Gauge.set (worker_queue_size ~registry ~tag) (Int.to_float sz)
