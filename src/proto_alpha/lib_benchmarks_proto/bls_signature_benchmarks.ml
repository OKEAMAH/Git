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

module Bls_check_signature_bench : Benchmark.S = struct
  include Interpreter_benchmarks.Default_config

  let name = "BLS_CHECK_SIGNATURE"

  let info = "Benchmarking BLS_CHECK_SIGNATURE"

  let tags = ["tx_rollup"; "bls"]

  type workload = {input_size : int; input_bytes_size : int}

  let workload_encoding : workload Data_encoding.t =
    let open Data_encoding in
    conv
      (fun {input_size; input_bytes_size} -> (input_size, input_bytes_size))
      (fun (input_size, input_bytes_size) -> {input_size; input_bytes_size})
      (obj2
         (req "input_size" Size.encoding)
         (req "input_bytes_size" Size.encoding))

  let workload_to_vector {input_size; input_bytes_size} =
    let l =
      [
        ("input_size", float_of_int input_size);
        ("input_bytes_size", float_of_int input_bytes_size);
      ]
    in
    Sparse_vec.String.of_list l

  let model =
    Model.make
      ~conv:(fun {input_size; input_bytes_size} ->
        (input_size, (input_bytes_size, ())))
      ~model:
        (Model.bilinear_affine
           ~intercept:(Free_variable.of_string "bls_check_signature_const")
           ~coeff1:
             (Free_variable.of_string "bls_check_signature_input_size_coeff")
           ~coeff2:
             (Free_variable.of_string
                "bls_check_signature_input_bytes_size_coeff"))

  let models = [("bls_check_signature", model)]

  let create_benchmark rng_state () =
    (* typical value is likely to be under 100 *)
    let range : Base_samplers.range = {min = 0; max = 100} in
    let input_size = Base_samplers.sample_in_interval ~range rng_state in
    let range_int : Base_samplers.range = {min = 10; max = 1_000} in
    let average = Base_samplers.sample_in_interval ~range:range_int rng_state in
    let range : Base_samplers.range =
      {min = average / 2; max = 3 * average / 2}
    in

    let keys =
      Stdlib.List.init input_size (fun _ ->
          Tx_rollup_helpers.gen_l2_account ~rng:rng_state ())
    in

    let aux =
      List.map
        (fun (sk, pk) ->
          let bytes = Base_samplers.bytes ~size:range rng_state in
          let signature = Bls12_381.Signature.Aug.sign sk bytes in

          ((pk, bytes), signature))
        keys
    in

    let (manifest, signatures) = Stdlib.List.split aux in

    let input_bytes_size =
      List.fold_left (fun acc (_, input) -> acc + Bytes.length input) 0 manifest
    in

    let signature =
      match Bls12_381.Signature.aggregate_signature_opt signatures with
      | Some x -> x
      | _ -> assert false
    in

    let closure () =
      ignore (Tx_rollup_helpers.Map_context.bls_verify manifest signature)
    in

    Generator.Plain {workload = {input_size; input_bytes_size}; closure}

  let create_benchmarks ~rng_state ~bench_num _config =
    List.repeat bench_num (create_benchmark rng_state)
end

let () = Registration_helpers.register (module Bls_check_signature_bench)
