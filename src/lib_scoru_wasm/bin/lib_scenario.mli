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

(** Defines a type [scenario] and its constructors, how to run it on the PVM *)
module Scenario : sig
  open Pvm_instance

  type 'a run_state

  type 'a action = 'a run_state -> 'a run_state Lwt.t

  (** step in a scenario, associates an action to a label *)
  type scenario_step

  (** container for informations needed to run a benchmark scenario *)
  type scenario

  (** [make_scenario_step step_name action] creates a scenario_step (one action) *)
  val make_scenario_step : string -> Wasm.tree action -> scenario_step

  (** [make_scenario scenario_name kernel_path actions] creates a scenario with
      - a [scenario_name]
      - the kernel stored at [kernel_path]
      - a list of [actions] *)
  val make_scenario : string -> string -> scenario_step list -> scenario

  (** action corresponding to one top level call of PVM *)
  val exec_loop : Wasm.tree action

  (** [exec_on_message message tree] returns the action corresponding to:
      - reading [message] (from binary or filename)
      - adding the message in the inbox
      - reading the input using state [tree] *)
  val exec_on_message : ?from_binary:bool -> string -> Wasm.tree action

  (** Execute a list of scenario with options:
      - verbose: print info during execution
      - totals: adds summary data point for each step
      - irmin: adds data point for decoding / encoding the state from / to a tree *)
  val run_scenarios :
    ?verbose:bool ->
    ?totals:bool ->
    ?irmin:bool ->
    ?nb_of_run:int ->
    string ->
    scenario list ->
    unit Lwt.t
end
