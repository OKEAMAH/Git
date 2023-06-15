(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2020 Nomadic Labs. <contact@nomadic-labs.com>               *)
(* Copyright (c) 2023 Marigold <contact@marigold.dev>                        *)
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

(** A [probe] implements an instrumented [apply] function.
    The implementation of [apply] is meant to record in a side-effecting way
    the result of a benchmark for the given closure. [get] allows to retrieve
    the results. *)
type 'aspect probe = {
  apply : 'a. 'aspect -> (unit -> 'a) -> 'a;
  aspects : unit -> 'aspect trace;
  get : 'aspect -> float trace;
}

(** The type of benchmarks. The piece of code being measured is [closure].
    Some benchmark requires to set-up/cleanup artifacts when being run,
    in that case use [With_context] with a proper implementation of the
    [with_context] function. *)
type 'workload benchmark =
  | Plain : {
      workload : 'workload;
      closure : unit -> unit;
    }
      -> 'workload benchmark
  | PlainWithAllocation : {
      workload : 'workload;
      closure : unit -> unit;
      measure_allocation : unit -> int option;
    }
      -> 'workload benchmark
  | With_context : {
      workload : 'workload;
      closure : 'context -> unit;
      with_context : 'a. ('context -> 'a) -> 'a;
    }
      -> 'workload benchmark
  | With_probe : {
      workload : 'aspect -> 'workload;
      probe : 'aspect probe;
      closure : 'aspect probe -> unit;
    }
      -> 'workload benchmark

module type S = sig
  type config

  (** Workload corresponding to a benchmark run *)
  type workload

  (** Creates a list of benchmarks, ready to be run. The [bench_num] option
            corresponds to the argument command-line specified by the user on command
            line, but it can be overriden by the [config]-specific settings.
            This is the case for instance when the benchmarks are performed on
            external artifacts.
            The benchmarks are thunked to prevent evaluating the workload until
            needed. *)
  val create_benchmarks :
    rng_state:Random.State.t ->
    bench_num:int ->
    config ->
    (unit -> workload benchmark) list
end

module V2 : sig
  type _ setup =
    | No_setup : unit setup
    | Load_data_list : (unit -> 'data list) -> 'data setup
    | Load_data : (unit -> 'data) -> 'data setup

  module DSL : sig
    type 'config params = {
      config : 'config;
      rng_state : Random.State.t;
      bench_num : int;
    }

    type ('a, 'b) step

    type 'a state
      constraint
        'a =
        < pre_hooks : 'pre_hook_status
        ; bench_status : 'bench_status
        ; setup_data : 'setup_data
        ; workload : 'workload >

    type ('config, 'workload) t

    type ('config, 'workload) builder

    type present

    type absent

    val get_params : ('a, 'a) builder

    val pre_hook :
      f:(unit -> unit) ->
      < bench_status : 'a
      ; pre_hooks : absent
      ; setup_data : 'b
      ; workload : 'd >
      state ->
      < bench_status : 'a
      ; pre_hooks : present
      ; setup_data : 'b
      ; workload : 'd >
      state

    val setup_data :
      data:'d setup ->
      < bench_status : absent
      ; pre_hooks : 'c
      ; setup_data : unit
      ; workload : 'e >
      state ->
      < bench_status : absent
      ; pre_hooks : 'c
      ; setup_data : 'd
      ; workload : 'e >
      state

    val benchmark :
      f:('a -> 'd benchmark option) ->
      < bench_status : absent
      ; pre_hooks : 'b
      ; setup_data : 'a
      ; workload : 'd >
      state ->
      < bench_status : present
      ; pre_hooks : 'b
      ; setup_data : 'a
      ; workload : 'd >
      state

    val describe :
      unit ->
      < bench_status : absent ; pre_hooks : absent ; setup_data : unit ; .. >
      state

    val complete : ('a, 'a) step

    val ( let$ ) :
      ('config params, 'b) builder ->
      ('b ->
      (unit, < bench_status : present ; workload : 'workload ; .. > state) step) ->
      ('config, 'workload) t

    val ( @> ) : ('a -> 'b) -> ('b, 'c) step -> ('a, 'c) step

    val return :
      (unit, < bench_status : present ; workload : 'workload ; .. > state) step ->
      ('config, 'workload) t

    val to_v1 :
      ('config, 'workload) t ->
      rng_state:Random.State.t ->
      bench_num:int ->
      'config ->
      (unit -> 'workload benchmark) list
  end
end
