(*****************************************************************************)
(*                                                                           *)
(* MIT License                                                               *)
(* Copyright (c) 2023 Nomadic Labs <contact@nomadic-labs.com>                *)
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

open Plonk.Bls
module PC = Plonk.Polynomial_commitment

let ( !! ) = Plonk_test.Cases.( !! )

let srs = fst Plonk_test.Helpers.srs

let generate_table n = Array.init n (fun _ -> Scalar.random ())

let table_size = 1 lsl 4

let wire_size = 1 lsl 2

let nb_wires = 3

let nb_proofs = 1

let table = List.init nb_wires (fun _ -> generate_table table_size)

let wires () =
  (* indexes of the table lines that will be put in wires *)
  let indexes = Array.init wire_size (fun _ -> Random.int table_size) in
  List.init nb_wires (fun i ->
      ( "w" ^ string_of_int i,
        Array.init wire_size (fun j -> (List.nth table i).(indexes.(j))) ))
  |> Plonk.SMap.of_list

let f_map = List.init nb_proofs (fun _ -> wires ())

let f_map_not_in_table =
  Plonk.SMap.map
    (fun _ -> Array.init wire_size (fun _ -> Scalar.random ()))
    (List.hd f_map)
  :: List.tl f_map

let test_correctness () =
  let prv, vrf = Plonk.Cq.setup ~srs ~wire_size ~table in
  let transcript = Bytes.empty in
  let proof, prv_transcript = Plonk.Cq.prove prv transcript f_map in
  let vrf, vrf_transcript = Plonk.Cq.verify vrf transcript proof in
  assert (Bytes.equal prv_transcript vrf_transcript) ;
  assert vrf

let test_not_in_table () =
  let prv, _ = Plonk.Cq.setup ~srs ~wire_size ~table in
  let transcript = Bytes.empty in
  try
    let _ = Plonk.Cq.prove prv transcript f_map_not_in_table in
    failwith
      "Test_cq.test_not_in_table : proof generation was supposed to fail."
  with Plonk.Cq.Entry_not_in_table -> ()

let test_wrong_proof () =
  let module Cq = Plonk.Cq.Make (PC) in
  let prv, vrf = Cq.setup ~srs ~wire_size ~table in
  let transcript = Bytes.empty in
  let proof_f, _ = Cq.prove prv transcript [List.hd f_map] in
  let wrong_proof =
    let cm_f, _ =
      PC.Commitment.commit
        Cq.(prv.pc)
        (Plonk.SMap.map
           (fun f ->
             Plonk.Bls.(
               Evaluations.(
                 interpolation_fft
                   (Domain.build wire_size)
                   (of_array (wire_size - 1, f)))))
           (List.hd f_map_not_in_table))
    in
    Cq.{proof_f with cm_f}
  in
  assert (not (fst @@ Cq.verify vrf transcript wrong_proof))

let tests =
  List.map
    (fun (name, f) -> Alcotest.test_case name `Quick f)
    [
      ("Correctness", test_correctness);
      ("Not in table", test_not_in_table);
      ("Fake proof", test_wrong_proof);
    ]
