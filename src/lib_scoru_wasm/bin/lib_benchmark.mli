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

(** How to collect and store data *)
module Data : sig
  type time = float

  (** container of the informations on a data point *)
  type datum

  (** [make_datum scenario_run scenario section label ticks time] *)
  val make_datum : int -> string -> string -> string -> Z.t -> time -> datum

  (** container of all data point informations collected during benchmark *)
  type benchmark

  (** initialize en empty benchmark with options
      - verbose: ouput info during execution (besides csv data in the end)
      - totals: add to csv data the total time / tick number for each steps *)
  val empty_benchmark :
    ?verbose:bool -> ?totals:bool -> ?irmin:bool -> unit -> benchmark

  (** [init_scenario scenario_run scenario_name benchmark] inits an empty benchmark
      for a given run of a scenario *)
  val init_scenario : int -> string -> benchmark -> benchmark

  (** [switch_section benchmark section_name] open a new section*)
  val switch_section : string -> benchmark -> benchmark

  (** [add_datum benchmark name ticks time] *)
  val add_datum : string -> Z.t -> time -> benchmark -> benchmark

  (** [add_tickless_datum label time] adds a point of data for an action consuming no tick *)
  val add_tickless_datum : string -> time -> benchmark -> benchmark

  (** adds final info as a data point in the benchmark *)
  val add_final_info : time -> Z.t -> benchmark -> benchmark

  module Csv : sig
    (** Output benchmark data in CSV format *)
    val print_benchmark : benchmark -> unit
  end
end
