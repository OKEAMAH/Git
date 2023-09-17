(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs, <contact@nomadic-labs.com>               *)
(* Copyright (c) 2023  Marigold <contact@marigold.dev>                       *)
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

module Registration : sig
  val ns : Namespace.cons

  type benchmark_type = Time | Alloc

  val register_s : ?benchmark_type:benchmark_type -> Benchmark.t -> unit

  (** Register a [Benchmark.Simple]. Recursively registers any relevant model and parameter
        included in it. *)
  val register : ?benchmark_type:benchmark_type -> Benchmark.simple -> unit

  (** Register a [Benchmark.Simple_with_num]. Recursively registers any relevant model and parameter
        included in it. *)
  val register_simple_with_num :
    ?benchmark_type:benchmark_type -> Benchmark.simple_with_num -> unit

  val register_as_simple_with_num : group:Benchmark.group -> Benchmark.t -> unit
end

module Model : sig
  open Model

  type 'workload t = 'workload Model.t

  val make :
    ?takes_saturation_reprs:bool ->
    name:Namespace.t ->
    conv:('a -> 'b) ->
    (Namespace.t -> 'b model) ->
    'a t

  val unknown_const1 : ?const:Free_variable.t -> Namespace.t -> unit model

  val affine :
    ?intercept:Free_variable.t ->
    ?coeff:Free_variable.t ->
    Namespace.t ->
    (int * unit) model

  val logn : ?coeff:Free_variable.t -> Namespace.t -> (int * unit) model

  val nlogn :
    ?intercept:Free_variable.t ->
    ?coeff:Free_variable.t ->
    Namespace.t ->
    (int * unit) model

  val linear : ?coeff:Free_variable.t -> Namespace.t -> (int * unit) model
end
