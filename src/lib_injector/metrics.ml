(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
(*                                                                           *)
(*****************************************************************************)

open Prometheus

let registry = CollectorRegistry.create ()

let namespace = Tezos_version.Node_version.namespace

let subsystem = "sc_rollup_node_injector"

(** Registers a gauge *)
let v_hist = Gauge.v ~registry ~namespace ~subsystem

let injector_queue_length =
  v_hist ~help:"The injector's queue length" "injector_queue_length"

let set_injector_queue_length l =
  Prometheus.Gauge.set injector_queue_length (float_of_int l)
