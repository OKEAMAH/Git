(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2020 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

(* Private module for internal benchmarks *)

(* A "benchmark" for the timer itself. *)

let ns = Builtin_models.ns

module Timer_latency_bench : Benchmark.Simple = struct
  type config = unit

  let default_config = ()

  let config_encoding = Data_encoding.unit

  let name = ns "TIMER_LATENCY"

  let info = "Measuring timer latency"

  let module_filename = __FILE__

  let purpose =
    Benchmark.Other_purpose
      "Measuring the time spent to query the system for the current time. \
       Indeed, it needs to be deducted from the total benchmark time of a \
       function."

  let tags = ["misc"; "builtin"]

  let group = Benchmark.Generic

  let model = Model.(make ~conv:(fun () -> ()) Model.zero)

  let workload_to_vector () = Sparse_vec.String.of_list [("timer_latency", 1.)]

  type workload = unit

  let workload_encoding = Data_encoding.unit

  let create_benchmark ~rng_state:_ () =
    let closure () = () in
    let workload = () in
    Generator.Plain {workload; closure}
end

let () = Registration.register_simple (module Timer_latency_bench)
