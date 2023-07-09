(*****************************************************************************)
(*                                                                           *)
(* Open Source License                                                       *)
(* Copyright (c) 2023 Nomadic Labs. <contact@nomadic-labs.com>               *)
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

(* Testing
   -------
   Component:    Lib Bls12_381_hash
   Invocation:   dune exec src/lib_bls12_381_hash/test/main.exe \
                  -- --file test_jive.ml
   Subject:      Test Bls12_381_hash
*)

let test_fail_input_size_and_parameters_do_not_match () =
  (* TODO: add Poseidon state size 2 and Rescue state size 2 *)
  let args :
      ((module Bls12_381_hash.PERMUTATION with type parameters = 'p) * 'p) list
      =
    [
      ( (module Bls12_381_hash.Permutation.Anemoi : Bls12_381_hash.PERMUTATION
          with type parameters = 'p),
        Bls12_381_hash.Permutation.Anemoi.Parameters.security_128_state_size_2
      );
    ]
  in
  List.iter
    (fun ( (module P : Bls12_381_hash.PERMUTATION with type parameters = 'p),
           (security_param : 'p) ) ->
      let input_size = 3 + Random.int 10 in
      let input = Array.init input_size (fun _ -> Bls12_381.Fr.random ()) in
      let msg =
        Printf.sprintf
          "The given array contains %d elements but the expected state size is \
           %d"
          input_size
          2
      in
      Alcotest.check_raises msg (Failure msg) (fun () ->
          ignore
          @@ Bls12_381_hash.Mode.Jive.digest (module P) security_param input))
    args

let test_fail_b_does_not_divide_input_size () =
  let args :
      ((module Bls12_381_hash.PERMUTATION with type parameters = 'p) * 'p) list
      =
    [
      ( (module Bls12_381_hash.Permutation.Anemoi : Bls12_381_hash.PERMUTATION
          with type parameters = 'p),
        Bls12_381_hash.Permutation.Anemoi.Parameters.security_128_state_size_2
      );
      ( (module Bls12_381_hash.Permutation.Anemoi : Bls12_381_hash.PERMUTATION
          with type parameters = 'p),
        Bls12_381_hash.Permutation.Anemoi.Parameters.security_128_state_size_6
      );
    ]
  in
  List.iter
    (fun ( (module P : Bls12_381_hash.PERMUTATION with type parameters = 'p),
           (security_param : 'p) ) ->
      let input_size = 2 in
      let input = Array.init input_size (fun _ -> Bls12_381.Fr.random ()) in
      let msg = "b must divide the state size" in
      Alcotest.check_raises msg (Failure msg) (fun () ->
          ignore
          @@ Bls12_381_hash.Mode.Jive.digest_b (module P) security_param input 4))
    args

let test_anemoi_state_size_2 () =
  let module P = Bls12_381_hash.Permutation.Anemoi in
  let x = Bls12_381.Fr.random () in
  let y = Bls12_381.Fr.random () in
  let b = 2 in
  let output = P.jive128_1 x y in
  let digest x y =
    let exp_output_arr =
      Bls12_381_hash.Mode.Jive.digest_b
        (module P)
        P.Parameters.security_128_state_size_2
        [|x; y|]
        b
    in
    exp_output_arr.(0)
  in
  assert (Bls12_381.Fr.eq (digest x y) output)

let test_anemoi_state_size_4 () =
  let module P = Bls12_381_hash.Permutation.Anemoi in
  let inputs = Array.map Bls12_381.Fr.of_string [|"0"; "0"; "0"; "0"|] in
  let b = 2 in
  let exp_output =
    Array.map
      Bls12_381.Fr.of_string
      [|
        "48136361849153243738173322980436308194640949106271265019940984579279517354580";
        "49817329994699533652293260449422143653559101821826781651581903522052933662147";
      |]
  in
  let output =
    Bls12_381_hash.Mode.Jive.digest_b
      (module P)
      P.Parameters.security_128_state_size_4
      inputs
      b
  in
  assert (Array.for_all2 Bls12_381.Fr.eq exp_output output)

let test_anemoi_state_size_6 () =
  let module P = Bls12_381_hash.Permutation.Anemoi in
  let input =
    [|"0"; "0"; "0"; "0"; "0"; "0"|] |> Array.map Bls12_381.Fr.of_string
  in
  let exp_output =
    [|
      "47562158473615805738921152583275280970717930580327614809968757743777260164821";
      "32960030678211185871458615279534626057326113879132750158608140483850617647612";
      "21851348684662138819043255124690263876370590311953746550455392262832149651457";
    |]
    |> Array.map Bls12_381.Fr.of_string
  in
  let b = 2 in
  let output =
    Bls12_381_hash.Mode.Jive.digest_b
      (module P)
      P.Parameters.security_128_state_size_6
      input
      b
  in
  Array.iter (fun x -> print_endline @@ Bls12_381.Fr.to_string x) output ;
  assert (Array.for_all2 Bls12_381.Fr.eq exp_output output)

let () =
  let open Alcotest in
  run
    ~__FILE__
    "The mode of operation Jive"
    [
      ( "Exceptions",
        [
          test_case
            "input size does not correspond to parameters"
            `Quick
            test_fail_input_size_and_parameters_do_not_match;
          test_case
            "b does not divide the state size"
            `Quick
            test_fail_b_does_not_divide_input_size;
        ] );
      ( "Anemoi",
        [
          test_case "b = 2, state_size = 2" `Quick test_anemoi_state_size_2;
          test_case "b = 2, state_size = 4" `Quick test_anemoi_state_size_4;
          test_case "b = 2, state_size = 6" `Quick test_anemoi_state_size_6;
        ] );
    ]
