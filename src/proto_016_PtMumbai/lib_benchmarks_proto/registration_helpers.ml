(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2021 Nomadic Labs, <contact@nomadic-labs.com>               *)
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

let ns = Namespace.make Namespace.root "proto"

let ns = Namespace.make ns Protocol.name

let register_for_codegen _name _model = ()

let adjust_tags tags = Protocol.name :: tags

let register ((module Bench) : Benchmark.t) =
  let module B : Benchmark.S = struct
    include Bench

    let tags = adjust_tags tags
  end in
  Registration.register (module B)

let register_simple (module Bench : Benchmark.Simple) =
  let module B = struct
    include Bench

    let tags = adjust_tags tags
  end in
  Registration.register_simple (module B)

let register_simple_with_num (module Bench : Benchmark.Simple_with_num) =
  let module B = struct
    include Bench

    let tags = adjust_tags tags
  end in
  Registration.register_simple_with_num (module B)

let register_as_simple_with_num (module B : Benchmark.S) =
  let modules =
    List.map
      (fun (model_name, model) : (module Benchmark.Simple_with_num) ->
        (module struct
          include B

          let name = Namespace.cons name model_name

          let group = Benchmark.Group model_name

          let model = model
        end))
      B.models
  in
  List.iter (fun x -> register_simple_with_num x) modules
