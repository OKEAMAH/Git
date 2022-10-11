module Scenario : sig
  open Lib_benchmark.Data
  open Pvm_instance

  type action = benchmark -> Wasm.tree -> (benchmark * Wasm.tree) Lwt.t

  type scenario_step

  type scenario

  val make_scenario : string -> string -> scenario_step list -> scenario

  val make_scenario_step : string -> action -> scenario_step

  val exec_on_message : ?from_binary:bool -> int -> string -> action

  val exec_on_messages : ?from_binary:bool -> int -> string list -> action

  val run_scenario : benchmark:benchmark -> scenario -> benchmark Lwt.t

  val run_scenarios :
    ?verbose:bool -> ?totals:bool -> ?irmin:bool -> scenario list -> unit Lwt.t
end