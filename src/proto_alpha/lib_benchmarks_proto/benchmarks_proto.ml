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

module Registration = struct
  let ns = Namespace.root

  let adjust_tags tags = Tags.common :: tags

  type benchmark_type = Time | Alloc

  let register_s ?(benchmark_type = Time) ((module Bench) : Benchmark.t) =
    let module B : Benchmark.S = struct
      include Bench

      let tags = adjust_tags tags
    end in
    Registration.register ~add_timer:(benchmark_type = Time) (module B)

  let register ?(benchmark_type = Time) (module Bench : Benchmark.Simple) =
    let module B = struct
      include Bench

      let tags = adjust_tags tags
    end in
    Registration.register_simple ~add_timer:(benchmark_type = Time) (module B)

  let register_simple_with_num ?(benchmark_type = Time)
      (module Bench : Benchmark.Simple_with_num) =
    let module B = struct
      include Bench

      let tags = adjust_tags tags
    end in
    Registration.register_simple_with_num
      ~add_timer:(benchmark_type = Time)
      (module B)

  let register_as_simple_with_num ~group (module B : Benchmark.S) =
    let modules =
      List.map
        (fun (model_name, model) : (module Benchmark.Simple_with_num) ->
          (module struct
            include B

            let name = Namespace.cons name model_name

            let group = group

            let model = model
          end))
        B.models
    in
    List.iter (fun x -> register_simple_with_num x) modules
end

module Model = struct
  include Model

  type 'workload t = 'workload Model.t

  let make ?takes_saturation_reprs ~name ~conv model =
    make ?takes_saturation_reprs ~conv (model name)

  let unknown_const1 ?const name =
    let ns s = Free_variable.of_namespace (Namespace.cons name s) in
    let const = Option.value ~default:(ns "const") const in
    unknown_const1 ~name ~const

  let affine ?intercept ?coeff name =
    let ns s = Free_variable.of_namespace (Namespace.cons name s) in
    let intercept = Option.value ~default:(ns "intercept") intercept in
    let coeff = Option.value ~default:(ns "coeff") coeff in
    affine ~name ~intercept ~coeff

  let logn ?coeff name =
    let ns s = Free_variable.of_namespace (Namespace.cons name s) in
    let coeff = Option.value ~default:(ns "coeff") coeff in
    logn ~name ~coeff

  let nlogn ?intercept ?coeff name =
    let ns s = Free_variable.of_namespace (Namespace.cons name s) in
    let coeff = Option.value ~default:(ns "coeff") coeff in
    let intercept = Option.value ~default:(ns "intercept") intercept in
    nlogn ~name ~intercept ~coeff

  let linear ?coeff name =
    let ns s = Free_variable.of_namespace (Namespace.cons name s) in
    let coeff = Option.value ~default:(ns "coeff") coeff in
    linear ~name ~coeff
end
