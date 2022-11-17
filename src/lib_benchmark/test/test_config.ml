(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2022 Nomadic Labs. <contact@nomadic-labs.com>               *)
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

open Tezos_benchmark

(*

Representation of the namespace for the test benchmarks :

  B4
  |
  B3  B2
   \ /
    |  B1
     \/

*)

let ns = Namespace.(make root "test")

module Test_boilerplate = struct
  let info = "Test bench for config unit tests. Should not be registered"

  let tags = []

  type workload = unit

  let workload_encoding = Data_encoding.unit

  let workload_to_vector () = Sparse_vec.String.zero

  let models = []

  let create_benchmarks ~rng_state ~bench_num _c =
    ignore rng_state ;
    ignore bench_num ;
    []
end

module B1 : Benchmark.S = struct
  include Test_boilerplate

  let name = ns "B1"

  type config = {a : int; b : int; e1 : bool}

  let default_config = {a = 1; b = 0; e1 = true}

  let config_encoding =
    Data_encoding.(
      conv
        (fun {a; b; e1} -> (a, b, e1))
        (fun (a, b, e1) -> {a; b; e1})
        (tup3 int31 int31 bool))
end

let ns_left = Namespace.make ns "branch"

module B2 : Benchmark.S = struct
  include Test_boilerplate

  let name = ns_left "B2"

  type config = {a : int; b : string; c : int; e2 : bool}

  let default_config = {a = 2; b = "b2"; c = 0; e2 = true}

  let config_encoding =
    Data_encoding.(
      conv
        (fun {a; b; c; e2} -> (a, b, c, e2))
        (fun (a, b, c, e2) -> {a; b; c; e2})
        (tup4 int31 string int31 bool))
end

module B3 : Benchmark.S = struct
  include Test_boilerplate

  let name = ns_left "B3"

  type config = {a : int; b : string; c : string; d : int; e3 : bool}

  let default_config = {a = 3; b = "b3"; c = "c"; d = 0; e3 = true}

  let config_encoding =
    Data_encoding.(
      conv
        (fun {a; b; c; d; e3} -> (a, b, c, d, e3))
        (fun (a, b, c, d, e3) -> {a; b; c; d; e3})
        (tup5 int31 string string int31 bool))
end

let ns_left_b3 = Namespace.make ns_left "B3"

module B4 : Benchmark.S = struct
  include Test_boilerplate

  let name = ns_left_b3 "B4"

  type config = {a : int; b : string; c : string; d : string; e4 : bool}

  let default_config = {a = 4; b = "b4"; c = "d"; d = "end"; e4 = true}

  let config_encoding =
    Data_encoding.(
      conv
        (fun {a; b; c; d; e4} -> (a, b, c, d, e4))
        (fun (a, b, c, d, e4) -> {a; b; c; d; e4})
        (tup5 int31 string string string bool))
end
