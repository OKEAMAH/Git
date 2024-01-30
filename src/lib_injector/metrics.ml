open Prometheus

let registry = CollectorRegistry.create ()

let namespace = Tezos_version.Node_version.namespace

let subsystem = "injector"

(** Registers a labeled counter in [injector_registry] *)
let _v_labels_counter =
  Counter.v_labels ~registry ~namespace ~subsystem

(** Registers a gauge in [injector_registry] *)
let _v_gauge = Gauge.v ~registry ~namespace ~subsystem
