(*****************************************************************************)
(*                                                                           *)
(* SPDX-License-Identifier: MIT                                              *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
(*                                                                           *)
(*****************************************************************************)

val registry : Prometheus.CollectorRegistry.t

val namespace : string

val subsystem : string

val v_gauge : help:string -> string -> Prometheus.Gauge.t

val injector_queue_length : Prometheus.Gauge.t

val set_injector_queue_length : int -> unit
