(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(*                                                                           *)
(*****************************************************************************)

val set_injected_operations_queue_size :
  registry:Prometheus.CollectorRegistry.t -> int -> unit

val set_included_operations_queue_size :
  registry:Prometheus.CollectorRegistry.t -> int -> unit

val set_worker_queue_size :
  registry:Prometheus.CollectorRegistry.t -> tag:string -> int -> unit
